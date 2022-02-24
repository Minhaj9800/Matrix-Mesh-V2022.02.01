import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/utils/matrix_sdk_extensions.dart/matrix_locals.dart';
import '../../../config/app_config.dart';
import 'html_message.dart';

class ReplyContent extends StatelessWidget {
  final Event replyEvent;
  final bool lightText;
  final Timeline? timeline;

  const ReplyContent(
    this.replyEvent, {
    this.lightText = false,
    Key? key,
    this.timeline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget replyBody;
    final timeline = this.timeline;
    final displayEvent =
        timeline != null ? replyEvent.getDisplayEvent(timeline) : replyEvent;
    final fontSize = AppConfig.messageFontSize * AppConfig.fontSizeFactor;
    if (AppConfig.renderHtml &&
        [EventTypes.Message, EventTypes.Encrypted]
            .contains(displayEvent.type) &&
        [MessageTypes.Text, MessageTypes.Notice, MessageTypes.Emote]
            .contains(displayEvent.messageType) &&
        !displayEvent.redacted &&
        displayEvent.content['format'] == 'org.matrix.custom.html' &&
        displayEvent.content['formatted_body'] is String) {
      String? html = displayEvent.content['formatted_body'];
      if (displayEvent.messageType == MessageTypes.Emote) {
        html = '* $html';
      }
      replyBody = HtmlMessage(
        html: html!,
        defaultTextStyle: TextStyle(
          color: lightText
              ? Colors.white
              : Theme.of(context).textTheme.bodyText2!.color,
          fontSize: fontSize,
        ),
        maxLines: 1,
        room: displayEvent.room,
        emoteSize: fontSize * 1.5,
      );
    } else {
      replyBody = Text(
        displayEvent.getLocalizedBody(
          MatrixLocals(L10n.of(context)!),
          withSenderNamePrefix: false,
          hideReply: true,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: TextStyle(
          color: lightText
              ? Colors.white
              : Theme.of(context).textTheme.bodyText2!.color,
          fontSize: fontSize,
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 3,
          height: fontSize * 2 + 6,
          color: lightText ? Colors.white : Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                displayEvent.sender.calcDisplayname() + ':',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color:
                      lightText ? Colors.white : Theme.of(context).primaryColor,
                  fontSize: fontSize,
                ),
              ),
              replyBody,
            ],
          ),
        ),
      ],
    );
  }
}
