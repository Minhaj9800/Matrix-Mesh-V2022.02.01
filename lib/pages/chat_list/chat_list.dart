import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:matrix/matrix.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:uni_links/uni_links.dart';
import 'package:vrouter/vrouter.dart';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/chat_list/chat_list_view.dart';
import 'package:fluffychat/utils/fluffy_share.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions.dart/client_stories_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import '../../../utils/account_bundles.dart';
import '../../main.dart';
import '../../utils/matrix_sdk_extensions.dart/matrix_file_extension.dart';
import '../../utils/url_launcher.dart';
import '../../widgets/matrix.dart';
import '../bootstrap/bootstrap_dialog.dart';

enum SelectMode { normal, share, select }
enum PopupMenuAction {
  settings,
  invite,
  newGroup,
  newSpace,
  setStatus,
  archive,
}

class ChatList extends StatefulWidget {
  const ChatList({Key? key}) : super(key: key);

  @override
  ChatListController createState() => ChatListController();
}

class ChatListController extends State<ChatList> {
  StreamSubscription? _intentDataStreamSubscription;

  StreamSubscription? _intentFileStreamSubscription;

  StreamSubscription? _intentUriStreamSubscription;

  String? _activeSpaceId;

  String? get activeSpaceId {
    final id = _activeSpaceId;
    return id != null && Matrix.of(context).client.getRoomById(id) == null
        ? null
        : _activeSpaceId;
  }

  final ScrollController scrollController = ScrollController();
  bool scrolledToTop = true;

  final StreamController<Client> _clientStream = StreamController.broadcast();

  Stream<Client> get clientStream => _clientStream.stream;

  void _onScroll() {
    final newScrolledToTop = scrollController.position.pixels <= 0;
    if (newScrolledToTop != scrolledToTop) {
      setState(() {
        scrolledToTop = newScrolledToTop;
      });
    }
  }

  void setActiveSpaceId(BuildContext context, String? spaceId) {
    setState(() => _activeSpaceId = spaceId);
  }

  void editSpace(BuildContext context, String spaceId) async {
    await Matrix.of(context).client.getRoomById(spaceId)!.postLoad();
    VRouter.of(context).toSegments(['spaces', spaceId]);
  }

  List<Room> get spaces =>
      Matrix.of(context).client.rooms.where((r) => r.isSpace).toList();

  final selectedRoomIds = <String>{};
  bool? crossSigningCached;
  bool showChatBackupBanner = false;

  void firstRunBootstrapAction() async {
    setState(() {
      showChatBackupBanner = false;
    });

    await BootstrapDialog(
      client: Matrix.of(context).client,
    ).show(context);
    VRouter.of(context).to('/rooms');
  }

  String? get activeChat => VRouter.of(context).pathParameters['roomid'];

  SelectMode get selectMode => Matrix.of(context).shareContent != null
      ? SelectMode.share
      : selectedRoomIds.isEmpty
          ? SelectMode.normal
          : SelectMode.select;

  void _processIncomingSharedFiles(List<SharedMediaFile> files) {
    if (files.isEmpty) return;
    VRouter.of(context).to('/rooms');
    final file = File(files.first.path);

    Matrix.of(context).shareContent = {
      'msgtype': 'chat.fluffy.shared_file',
      'file': MatrixFile(
        bytes: file.readAsBytesSync(),
        name: file.path,
      ).detectFileType,
    };
  }

  void _processIncomingSharedText(String? text) {
    if (text == null) return;
    VRouter.of(context).to('/rooms');
    if (text.toLowerCase().startsWith(AppConfig.deepLinkPrefix) ||
        text.toLowerCase().startsWith(AppConfig.inviteLinkPrefix) ||
        (text.toLowerCase().startsWith(AppConfig.schemePrefix) &&
            !RegExp(r'\s').hasMatch(text))) {
      return _processIncomingUris(text);
    }
    Matrix.of(context).shareContent = {
      'msgtype': 'm.text',
      'body': text,
    };
  }

  void _processIncomingUris(String? text) async {
    if (text == null) return;
    VRouter.of(context).to('/rooms');
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      UrlLauncher(context, text).openMatrixToUrl();
    });
  }

  void _initReceiveSharingIntent() {
    if (!PlatformInfos.isMobile) return;

    // For sharing images coming from outside the app while the app is in the memory
    _intentFileStreamSubscription = ReceiveSharingIntent.getMediaStream()
        .listen(_processIncomingSharedFiles, onError: print);

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialMedia().then(_processIncomingSharedFiles);

    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    _intentDataStreamSubscription = ReceiveSharingIntent.getTextStream()
        .listen(_processIncomingSharedText, onError: print);

    // For sharing or opening urls/text coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialText().then(_processIncomingSharedText);

    // For receiving shared Uris
    _intentUriStreamSubscription = linkStream.listen(_processIncomingUris);
    if (FluffyChatApp.gotInitialLink == false) {
      FluffyChatApp.gotInitialLink = true;
      getInitialLink().then(_processIncomingUris);
    }
  }

  @override
  void initState() {
    _initReceiveSharingIntent();

    scrollController.addListener(_onScroll);
    _waitForFirstSync();
    super.initState();
  }

  void checkBootstrap() async {
    if (!Matrix.of(context).client.encryptionEnabled) return;
    await Matrix.of(context).client.accountDataLoading;
    await Matrix.of(context).client.userDeviceKeysLoading;
    final crossSigning =
        await Matrix.of(context).client.encryption?.crossSigning.isCached() ??
            false;
    final needsBootstrap =
        Matrix.of(context).client.encryption?.crossSigning.enabled == false ||
            crossSigning == false;
    final isUnknownSession = Matrix.of(context).client.isUnknownSession;
    if (needsBootstrap || isUnknownSession) {
      setState(() {
        showChatBackupBanner = true;
      });
    }
  }

  @override
  void dispose() {
    _intentDataStreamSubscription?.cancel();
    _intentFileStreamSubscription?.cancel();
    _intentUriStreamSubscription?.cancel();
    scrollController.removeListener(_onScroll);
    super.dispose();
  }

  bool roomCheck(Room room) {
    if (room.isSpace && room.membership == Membership.join && !room.isUnread) {
      return false;
    }
    if (room.getState(EventTypes.RoomCreate)?.content.tryGet<String>('type') ==
        ClientStoriesExtension.storiesRoomType) {
      return false;
    }
    if (activeSpaceId != null) {
      final space = Matrix.of(context).client.getRoomById(activeSpaceId!)!;
      if (space.spaceChildren.any((child) => child.roomId == room.id)) {
        return true;
      }
      if (room.spaceParents.any((parent) => parent.roomId == activeSpaceId)) {
        return true;
      }
      if (room.isDirectChat &&
          room.summary.mHeroes != null &&
          room.summary.mHeroes!.any((userId) {
            final user = space.getState(EventTypes.RoomMember, userId)?.asUser;
            return user != null && user.membership == Membership.join;
          })) {
        return true;
      }
      return false;
    }
    return true;
  }

  void toggleSelection(String roomId) {
    setState(() => selectedRoomIds.contains(roomId)
        ? selectedRoomIds.remove(roomId)
        : selectedRoomIds.add(roomId));
  }

  Future<void> toggleUnread() async {
    await showFutureLoadingDialog(
      context: context,
      future: () async {
        final markUnread = anySelectedRoomNotMarkedUnread;
        final client = Matrix.of(context).client;
        for (final roomId in selectedRoomIds) {
          final room = client.getRoomById(roomId)!;
          if (room.markedUnread == markUnread) continue;
          await client.getRoomById(roomId)!.markUnread(markUnread);
        }
      },
    );
    cancelAction();
  }

  Future<void> toggleFavouriteRoom() async {
    await showFutureLoadingDialog(
      context: context,
      future: () async {
        final makeFavorite = anySelectedRoomNotFavorite;
        final client = Matrix.of(context).client;
        for (final roomId in selectedRoomIds) {
          final room = client.getRoomById(roomId)!;
          if (room.isFavourite == makeFavorite) continue;
          await client.getRoomById(roomId)!.setFavourite(makeFavorite);
        }
      },
    );
    cancelAction();
  }

  Future<void> toggleMuted() async {
    await showFutureLoadingDialog(
      context: context,
      future: () async {
        final newState = anySelectedRoomNotMuted
            ? PushRuleState.mentionsOnly
            : PushRuleState.notify;
        final client = Matrix.of(context).client;
        for (final roomId in selectedRoomIds) {
          final room = client.getRoomById(roomId)!;
          if (room.pushRuleState == newState) continue;
          await client.getRoomById(roomId)!.setPushRuleState(newState);
        }
      },
    );
    cancelAction();
  }

  Future<void> archiveAction() async {
    final confirmed = await showOkCancelAlertDialog(
          useRootNavigator: false,
          context: context,
          title: L10n.of(context)!.areYouSure,
          okLabel: L10n.of(context)!.yes,
          cancelLabel: L10n.of(context)!.cancel,
        ) ==
        OkCancelResult.ok;
    if (!confirmed) return;
    await showFutureLoadingDialog(
      context: context,
      future: () => _archiveSelectedRooms(),
    );
    setState(() {});
  }

  void setStatus() async {
    final input = await showTextInputDialog(
        useRootNavigator: false,
        context: context,
        title: L10n.of(context)!.setStatus,
        okLabel: L10n.of(context)!.ok,
        cancelLabel: L10n.of(context)!.cancel,
        textFields: [
          DialogTextField(
            hintText: L10n.of(context)!.statusExampleMessage,
          ),
        ]);
    if (input == null) return;
    await showFutureLoadingDialog(
      context: context,
      future: () => Matrix.of(context).client.setPresence(
            Matrix.of(context).client.userID!,
            PresenceType.online,
            statusMsg: input.single,
          ),
    );
  }

  void onPopupMenuSelect(action) {
    switch (action) {
      case PopupMenuAction.setStatus:
        setStatus();
        break;
      case PopupMenuAction.settings:
        VRouter.of(context).to('/settings');
        break;
      case PopupMenuAction.invite:
        FluffyShare.share(
            L10n.of(context)!.inviteText(Matrix.of(context).client.userID!,
                'https://matrix.to/#/${Matrix.of(context).client.userID}?client=im.fluffychat'),
            context);
        break;
      case PopupMenuAction.newGroup:
        VRouter.of(context).to('/newgroup');
        break;
      case PopupMenuAction.newSpace:
        VRouter.of(context).to('/newspace');
        break;
      case PopupMenuAction.archive:
        VRouter.of(context).to('/archive');
        break;
    }
  }

  Future<void> _archiveSelectedRooms() async {
    final client = Matrix.of(context).client;
    while (selectedRoomIds.isNotEmpty) {
      final roomId = selectedRoomIds.first;
      try {
        await client.getRoomById(roomId)!.leave();
      } finally {
        toggleSelection(roomId);
      }
    }
  }

  Future<void> addOrRemoveToSpace() async {
    if (activeSpaceId != null) {
      final consent = await showOkCancelAlertDialog(
        context: context,
        title: L10n.of(context)!.removeFromSpace,
        message: L10n.of(context)!.removeFromSpaceDescription,
        okLabel: L10n.of(context)!.remove,
        cancelLabel: L10n.of(context)!.cancel,
        isDestructiveAction: true,
        fullyCapitalizedForMaterial: false,
      );
      if (consent != OkCancelResult.ok) return;

      final space = Matrix.of(context).client.getRoomById(activeSpaceId!);
      final result = await showFutureLoadingDialog(
        context: context,
        future: () async {
          for (final roomId in selectedRoomIds) {
            await space!.removeSpaceChild(roomId);
          }
        },
      );
      if (result.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L10n.of(context)!.chatHasBeenRemovedFromThisSpace),
          ),
        );
      }
    } else {
      final selectedSpace = await showConfirmationDialog<String>(
          context: context,
          title: L10n.of(context)!.addToSpace,
          message: L10n.of(context)!.addToSpaceDescription,
          fullyCapitalizedForMaterial: false,
          actions: Matrix.of(context)
              .client
              .rooms
              .where((r) => r.isSpace)
              .map(
                (space) => AlertDialogAction(
                  key: space.id,
                  label: space.displayname,
                ),
              )
              .toList());
      if (selectedSpace == null) return;
      final result = await showFutureLoadingDialog(
        context: context,
        future: () async {
          final space = Matrix.of(context).client.getRoomById(selectedSpace)!;
          if (space.canSendDefaultStates) {
            for (final roomId in selectedRoomIds) {
              await space.setSpaceChild(roomId);
            }
          }
        },
      );
      if (result.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L10n.of(context)!.chatHasBeenAddedToThisSpace),
          ),
        );
      }
    }
    setState(() => selectedRoomIds.clear());
  }

  bool get anySelectedRoomNotMarkedUnread => selectedRoomIds.any(
      (roomId) => !Matrix.of(context).client.getRoomById(roomId)!.markedUnread);

  bool get anySelectedRoomNotFavorite => selectedRoomIds.any(
      (roomId) => !Matrix.of(context).client.getRoomById(roomId)!.isFavourite);

  bool get anySelectedRoomNotMuted => selectedRoomIds.any((roomId) =>
      Matrix.of(context).client.getRoomById(roomId)!.pushRuleState ==
      PushRuleState.notify);

  bool waitForFirstSync = false;

  Future<void> _waitForFirstSync() async {
    final client = Matrix.of(context).client;
    await client.roomsLoading;
    await client.accountDataLoading;
    if (client.prevBatch?.isEmpty ?? true) {
      await client.onFirstSync.stream.first;
    }
    // Load space members to display DM rooms
    if (activeSpaceId != null) {
      final space = client.getRoomById(activeSpaceId!)!;
      final localMembers = space.getParticipants().length;
      final actualMembersCount = (space.summary.mInvitedMemberCount ?? 0) +
          (space.summary.mJoinedMemberCount ?? 0);
      if (localMembers < actualMembersCount) {
        await space.requestParticipants();
      }
    }
    setState(() {
      waitForFirstSync = true;
    });
    WidgetsBinding.instance!.addPostFrameCallback((_) => checkBootstrap());
    return;
  }

  void cancelAction() {
    if (selectMode == SelectMode.share) {
      setState(() => Matrix.of(context).shareContent = null);
    } else {
      setState(() => selectedRoomIds.clear());
    }
  }

  void setActiveClient(Client client) {
    VRouter.of(context).to('/rooms');
    setState(() {
      _activeSpaceId = null;
      selectedRoomIds.clear();
      Matrix.of(context).setActiveClient(client);
    });
    _clientStream.add(client);
  }

  void setActiveBundle(String bundle) {
    VRouter.of(context).to('/rooms');
    setState(() {
      _activeSpaceId = null;
      selectedRoomIds.clear();
      Matrix.of(context).activeBundle = bundle;
      if (!Matrix.of(context)
          .currentBundle!
          .any((client) => client == Matrix.of(context).client)) {
        Matrix.of(context)
            .setActiveClient(Matrix.of(context).currentBundle!.first);
      }
    });
  }

  void editBundlesForAccount(String? userId, String? activeBundle) async {
    final client = Matrix.of(context)
        .widget
        .clients[Matrix.of(context).getClientIndexByMatrixId(userId!)];
    final action = await showConfirmationDialog<EditBundleAction>(
      context: context,
      title: L10n.of(context)!.editBundlesForAccount,
      actions: [
        AlertDialogAction(
          key: EditBundleAction.addToBundle,
          label: L10n.of(context)!.addToBundle,
        ),
        if (activeBundle != client.userID)
          AlertDialogAction(
            key: EditBundleAction.removeFromBundle,
            label: L10n.of(context)!.removeFromBundle,
          ),
      ],
    );
    if (action == null) return;
    switch (action) {
      case EditBundleAction.addToBundle:
        final bundle = await showTextInputDialog(
            context: context,
            title: L10n.of(context)!.bundleName,
            textFields: [
              DialogTextField(hintText: L10n.of(context)!.bundleName)
            ]);
        if (bundle == null || bundle.isEmpty || bundle.single.isEmpty) return;
        await showFutureLoadingDialog(
          context: context,
          future: () => client.setAccountBundle(bundle.single),
        );
        break;
      case EditBundleAction.removeFromBundle:
        await showFutureLoadingDialog(
          context: context,
          future: () => client.removeFromAccountBundle(activeBundle!),
        );
    }
  }

  bool get displayBundles =>
      Matrix.of(context).hasComplexBundles &&
      Matrix.of(context).accountBundles.keys.length > 1;

  String? get secureActiveBundle {
    if (Matrix.of(context).activeBundle == null ||
        !Matrix.of(context)
            .accountBundles
            .keys
            .contains(Matrix.of(context).activeBundle)) {
      return Matrix.of(context).accountBundles.keys.first;
    }
    return Matrix.of(context).activeBundle;
  }

  void resetActiveBundle() {
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      setState(() {
        Matrix.of(context).activeBundle = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Matrix.of(context).navigatorContext = context;
    return ChatListView(this);
  }
}

enum EditBundleAction { addToBundle, removeFromBundle }
