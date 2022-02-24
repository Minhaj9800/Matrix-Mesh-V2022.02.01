import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import '../config/app_config.dart';
import 'matrix.dart';

class UnreadBadgeBackButton extends StatelessWidget {
  final String roomId;

  const UnreadBadgeBackButton({
    Key? key,
    required this.roomId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Center(child: BackButton()),
        StreamBuilder(
            stream: Matrix.of(context).client.onSync.stream,
            builder: (context, _) {
              final unreadCount = Matrix.of(context)
                  .client
                  .rooms
                  .where((r) =>
                      r.id != roomId &&
                      (r.isUnread || r.membership == Membership.invite))
                  .length;
              return unreadCount > 0
                  ? Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        margin: const EdgeInsets.only(bottom: 4, right: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius:
                              BorderRadius.circular(AppConfig.borderRadius),
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : Container();
            }),
      ],
    );
  }
}
