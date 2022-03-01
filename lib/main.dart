import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter_app_lock/flutter_app_lock.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:matrix/matrix.dart';
import 'package:universal_html/html.dart' as html;
import 'package:vrouter/vrouter.dart';

import 'package:fluffychat/config/routes.dart';
import 'package:fluffychat/utils/client_manager.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/sentry_controller.dart';
import 'config/app_config.dart';
import 'config/themes.dart';
import 'utils/background_push.dart';
import 'utils/custom_scroll_behaviour.dart';
import 'utils/localized_exception_extension.dart';
import 'utils/platform_infos.dart';
import 'widgets/lock_screen.dart';
import 'widgets/matrix.dart';

import 'package:flutter_blue/flutter_blue.dart';

void main() async {
  // Our background push shared isolate accesses flutter-internal things very early in the startup proccess
  // To make sure that the parts of flutter needed are started up already, we need to ensure that the
  // widget bindings are initialized already.
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError =
      (FlutterErrorDetails details) => Zone.current.handleUncaughtError(
            details.exception,
            details.stack ?? StackTrace.current,
          );

  final clients = await ClientManager.getClients();
  Logs().level = kReleaseMode ? Level.warning : Level.verbose;

  if (PlatformInfos.isMobile) {
    BackgroundPush.clientOnly(clients.first);
  }

  final queryParameters = <String, String>{};
  if (kIsWeb) {
    queryParameters
        .addAll(Uri.parse(html.window.location.href).queryParameters);
  }

  runZonedGuarded(
    () => runApp(PlatformInfos.isMobile
        ? AppLock(
            builder: (args) => FluffyChatApp(
              clients: clients,
              queryParameters: queryParameters,
            ),
            lockScreen: const LockScreen(),
            enabled: false,
          )
        : FluffyChatApp(clients: clients, queryParameters: queryParameters)),
    SentryController.captureException,
  );
}

class FluffyChatApp extends StatefulWidget {
  final Widget? testWidget;
  final List<Client> clients;
  final Map<String, String>? queryParameters;

  FluffyChatApp({
    Key? key,
    this.testWidget,
    required this.clients,
    this.queryParameters,
  }) : super(key: key);

  /// getInitialLink may rereturn the value multiple times if this view is
  /// opened multiple times for example if the user logs out after they logged
  /// in with qr code or magic link.
  static bool gotInitialLink = false;

  //##### Bluetooth additions
  //final String title; // Commented out as possibly unnecessary, comment back in if this causes an error
  // Flutter Blue Instance to access the flutter_blue plug in from library
  final FlutterBlue flutterBlue = FlutterBlue.instance;

  // Scanning Bluetooth Device
  // Initilaizing a list containing the Devices
  final List<BluetoothDevice> devicesList = [];
  //##### Bluetooth ends

  @override
  _FluffyChatAppState createState() => _FluffyChatAppState();
}

class _FluffyChatAppState extends State<FluffyChatApp> {
  GlobalKey<VRouterState>? _router;
  bool? columnMode;
  String? _initialUrl;

  @override
  void initState() {
    super.initState();
    _initialUrl =
        widget.clients.any((client) => client.isLogged()) ? '/rooms' : '/home';
		
	//##### Bluetooth additions
    widget.flutterBlue.connectedDevices
        .asStream()
        .listen((List<BluetoothDevice> devices) {
      for (BluetoothDevice device in devices) {
        _addDeviceTolist(device);
      }
    });
    widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        _addDeviceTolist(result.device);
      }
    });
    widget.flutterBlue.startScan();
	//##### Bluetooth ends
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
	  // This Bluetooth code needs to run when this is built
	  // *******************
      //body: _buildListViewOfDevices(),
	  // *******************
	  // The body part likely is flexible (as in other parameters/names may work)
	  // The objects below may accept the body parameter, or they may ignore it, or it may throw an error
	  // You should check the api/documentation to see
	  //    what the 'body:' parameter means/does in the Scaffold class that this code came from
	  //    What parameters are available in this class and the classes below
	  //      AdaptiveTheme, LayoutBuilder, VRouter
	  //      It may even make sense to try to move it to Matrix once you are sure it is working
	  
	  

      light: FluffyThemes.light,
      dark: FluffyThemes.dark,
      initial: AdaptiveThemeMode.system,
      builder: (theme, darkTheme) => LayoutBuilder(
        builder: (context, constraints) {
          const maxColumns = 3;
          var newColumns =
              (constraints.maxWidth / FluffyThemes.columnWidth).floor();
          if (newColumns > maxColumns) newColumns = maxColumns;
          columnMode ??= newColumns > 1;
          _router ??= GlobalKey<VRouterState>();
          if (columnMode != newColumns > 1) {
            Logs().v('Set Column Mode = $columnMode');
            WidgetsBinding.instance?.addPostFrameCallback((_) {
              setState(() {
                _initialUrl = _router?.currentState?.url;
                columnMode = newColumns > 1;
                _router = GlobalKey<VRouterState>();
              });
            });
          }
          return VRouter(
            key: _router,
            title: AppConfig.applicationName,
            theme: theme,
            scrollBehavior: CustomScrollBehavior(),
            logs: kReleaseMode ? VLogs.none : VLogs.info,
            darkTheme: darkTheme,
            localizationsDelegates: L10n.localizationsDelegates,
            supportedLocales: L10n.supportedLocales,
            initialUrl: _initialUrl ?? '/',
            routes: AppRoutes(columnMode ?? false).routes,
            builder: (context, child) {
              LoadingDialog.defaultTitle = L10n.of(context)!.loadingPleaseWait;
              LoadingDialog.defaultBackLabel = L10n.of(context)!.close;
              LoadingDialog.defaultOnError =
                  (e) => (e as Object?)!.toLocalizedString(context);
              WidgetsBinding.instance?.addPostFrameCallback((_) {
                SystemChrome.setSystemUIOverlayStyle(
                  SystemUiOverlayStyle(
                    statusBarColor: Colors.transparent,
                    systemNavigationBarColor:
                        Theme.of(context).appBarTheme.backgroundColor,
                    systemNavigationBarIconBrightness:
                        Theme.of(context).brightness == Brightness.light
                            ? Brightness.dark
                            : Brightness.light,
                  ),
                );
              });
              return Matrix(
                context: context,
                router: _router,
                clients: widget.clients,
                child: child,
              );
            },
          );
        },
      ),
    );
  }
  
  //##### Bluetooth additions
  /*
   * Helper method to fill the scanning bluetooth device lis
   **/
  _addDeviceTolist(final BluetoothDevice device) {
    if (!widget.devicesList.contains(device)) {
      setState(() {
        widget.devicesList.add(device);
      });
    }
  }

  /// Building ListView with the deviceList as Content.
  ListView _buildListViewOfDevices() {
    List<Container> containers = [];
    for (BluetoothDevice device in widget.devicesList) {
      containers.add(
        Container(
          height: 50,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text(device.name == '' ? '(unknown device)' : device.name),
                    Text(device.id.toString()),
                  ],
                ),
              ),
              FlatButton(
                color: Colors.blue,
                child: Text(
                  'Connect',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }
  //##### Bluetooth ends
  
}
