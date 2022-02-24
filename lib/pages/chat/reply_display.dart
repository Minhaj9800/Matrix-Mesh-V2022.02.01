import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/utils/matrix_sdk_extensions.dart/matrix_locals.dart';
import 'chat.dart';
import 'events/reply_content.dart';

class ReplyDisplay extends StatelessWidget {
  final ChatController controller;
  const ReplyDisplay(this.controller, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: controller.editEvent != null || controller.replyEvent != null
          ? 56
          : 0,
      child: Material(
        color: Theme.of(context).secondaryHeaderColor,
        child: Row(
          children: <Widget>[
            IconButton(
              tooltip: L10n.of(context)!.close,
              icon: const Icon(Icons.close),
              onPressed: controller.cancelReplyEventAction,
            ),
            Expanded(
              child: controller.replyEvent != null
                  ? ReplyContent(controller.replyEvent!,
                      timeline: controller.timeline!)
                  : _EditContent(controller.editEvent
                      ?.getDisplayEvent(controller.timeline!)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditContent extends StatelessWidget {
  final Event? event;

  const _EditContent(this.event);

  @override
  Widget build(BuildContext context) {
    if (event == null) {
      return Container();
    }
    return Row(
      children: <Widget>[
        Icon(
          Icons.edit,
          color: Theme.of(context).primaryColor,
        ),
        Container(width: 15.0),
        Text(
          event?.getLocalizedBody(
                MatrixLocals(L10n.of(context)!),
                withSenderNamePrefix: false,
                hideReply: true,
              ) ??
              '',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyText2!.color,
          ),
        ),
      ],
    );
  }
}
