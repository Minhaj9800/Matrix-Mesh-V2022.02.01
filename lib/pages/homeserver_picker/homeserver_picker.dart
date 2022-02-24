import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:matrix/matrix.dart';
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vrouter/vrouter.dart';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/config/setting_keys.dart';
import 'package:fluffychat/pages/homeserver_picker/homeserver_picker_view.dart';
import 'package:fluffychat/utils/famedlysdk_store.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/matrix.dart';
import '../../main.dart';
import '../../utils/localized_exception_extension.dart';

class HomeserverPicker extends StatefulWidget {
  const HomeserverPicker({Key? key}) : super(key: key);

  @override
  HomeserverPickerController createState() => HomeserverPickerController();
}

class HomeserverPickerController extends State<HomeserverPicker> {
  bool isLoading = false;
  String domain = AppConfig.defaultHomeserver;
  final TextEditingController homeserverController =
      TextEditingController(text: AppConfig.defaultHomeserver);
  StreamSubscription? _intentDataStreamSubscription;
  String? error;
  Timer? _coolDown;

  void setDomain(String domain) {
    this.domain = domain;
    _coolDown?.cancel();
    if (domain.isNotEmpty) {
      _coolDown =
          Timer(const Duration(milliseconds: 500), checkHomeserverAction);
    }
  }

  void _loginWithToken(String token) {
    if (token.isEmpty) return;

    showFutureLoadingDialog(
      context: context,
      future: () async {
        if (Matrix.of(context).getLoginClient().homeserver == null) {
          await Matrix.of(context).getLoginClient().checkHomeserver(
                await Store()
                    .getItem(HomeserverPickerController.ssoHomeserverKey),
              );
        }
        await Matrix.of(context).getLoginClient().login(
              LoginType.mLoginToken,
              token: token,
              initialDeviceDisplayName: PlatformInfos.clientName,
            );
      },
    );
  }

  void _processIncomingUris(String? text) async {
    if (text == null || !text.startsWith(AppConfig.appOpenUrlScheme)) return;
    await browser?.close();
    VRouter.of(context).to('/home');
    final token = Uri.parse(text).queryParameters['loginToken'];
    if (token != null) _loginWithToken(token);
  }

  void _initReceiveUri() {
    if (!PlatformInfos.isMobile) return;
    // For receiving shared Uris
    _intentDataStreamSubscription = linkStream.listen(_processIncomingUris);
    if (FluffyChatApp.gotInitialLink == false) {
      FluffyChatApp.gotInitialLink = true;
      getInitialLink().then(_processIncomingUris);
    }
  }

  @override
  void initState() {
    super.initState();
    _initReceiveUri();
    if (kIsWeb) {
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        final token = Matrix.of(context).widget.queryParameters!['loginToken'];
        if (token != null) _loginWithToken(token);
      });
    }
    checkHomeserverAction();
  }

  @override
  void dispose() {
    super.dispose();
    _intentDataStreamSubscription?.cancel();
  }

  String? _lastCheckedHomeserver;

  /// Starts an analysis of the given homeserver. It uses the current domain and
  /// makes sure that it is prefixed with https. Then it searches for the
  /// well-known information and forwards to the login page depending on the
  /// login type.
  Future<void> checkHomeserverAction() async {
    _coolDown?.cancel();
    if (_lastCheckedHomeserver == domain) return;
    if (domain.isEmpty) throw L10n.of(context)!.changeTheHomeserver;
    var homeserver = domain;

    if (!homeserver.startsWith('https://')) {
      homeserver = 'https://$homeserver';
    }

    setState(() {
      error = _rawLoginTypes = registrationSupported = null;
      isLoading = true;
    });

    try {
      final wellKnown =
          await Matrix.of(context).getLoginClient().checkHomeserver(homeserver);

      var jitsi = wellKnown?.additionalProperties
          .tryGet<Map<String, dynamic>>('im.vector.riot.jitsi')
          ?.tryGet<String>('preferredDomain');
      if (jitsi != null) {
        if (!jitsi.endsWith('/')) {
          jitsi += '/';
        }
        Logs().v('Found custom jitsi instance $jitsi');
        await Matrix.of(context)
            .store
            .setItem(SettingKeys.jitsiInstance, jitsi);
        AppConfig.jitsiInstance = jitsi;
      }

      _rawLoginTypes = await Matrix.of(context).getLoginClient().request(
            RequestType.GET,
            '/client/r0/login',
          );
      try {
        await Matrix.of(context).getLoginClient().register();
        registrationSupported = true;
      } on MatrixException catch (e) {
        registrationSupported = e.requireAdditionalAuthentication;
      }
    } catch (e) {
      setState(() => error = (e).toLocalizedString(context));
    } finally {
      _lastCheckedHomeserver = domain;
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Map<String, dynamic>? _rawLoginTypes;
  bool? registrationSupported;

  List<IdentityProvider> get identityProviders {
    if (!ssoLoginSupported) return [];
    final rawProviders = _rawLoginTypes!.tryGetList('flows')!.singleWhere(
        (flow) =>
            flow['type'] == AuthenticationTypes.sso)['identity_providers'];
    final list = (rawProviders as List)
        .map((json) => IdentityProvider.fromJson(json))
        .toList();
    if (PlatformInfos.isCupertinoStyle) {
      list.sort((a, b) => a.brand == 'apple' ? -1 : 1);
    }
    return list;
  }

  bool get passwordLoginSupported =>
      Matrix.of(context)
          .client
          .supportedLoginTypes
          .contains(AuthenticationTypes.password) &&
      _rawLoginTypes!
          .tryGetList('flows')!
          .any((flow) => flow['type'] == AuthenticationTypes.password);

  bool get ssoLoginSupported =>
      Matrix.of(context)
          .client
          .supportedLoginTypes
          .contains(AuthenticationTypes.sso) &&
      _rawLoginTypes!
          .tryGetList('flows')!
          .any((flow) => flow['type'] == AuthenticationTypes.sso);

  ChromeSafariBrowser? browser;

  static const String ssoHomeserverKey = 'sso-homeserver';

  void ssoLoginAction(String id) {
    if (kIsWeb) {
      // We store the homserver in the local storage instead of a redirect
      // parameter because of possible CSRF attacks.
      Store().setItem(ssoHomeserverKey,
          Matrix.of(context).getLoginClient().homeserver.toString());
    }
    final redirectUrl = kIsWeb
        ? AppConfig.webBaseUrl + '/#/'
        : AppConfig.appOpenUrlScheme.toLowerCase() + '://login';
    final url =
        '${Matrix.of(context).getLoginClient().homeserver?.toString()}/_matrix/client/r0/login/sso/redirect/${Uri.encodeComponent(id)}?redirectUrl=${Uri.encodeQueryComponent(redirectUrl)}';
    if (PlatformInfos.isMobile) {
      browser ??= ChromeSafariBrowser();
      browser!.open(url: Uri.parse(url));
    } else {
      launch(redirectUrl);
    }
  }

  void signUpAction() => VRouter.of(context).to(
        'signup',
        queryParameters: {'domain': domain},
      );

  @override
  Widget build(BuildContext context) {
    Matrix.of(context).navigatorContext = context;
    return HomeserverPickerView(this);
  }
}

class IdentityProvider {
  final String? id;
  final String? name;
  final String? icon;
  final String? brand;

  IdentityProvider({this.id, this.name, this.icon, this.brand});

  factory IdentityProvider.fromJson(Map<String, dynamic> json) =>
      IdentityProvider(
        id: json['id'],
        name: json['name'],
        icon: json['icon'],
        brand: json['brand'],
      );
}
