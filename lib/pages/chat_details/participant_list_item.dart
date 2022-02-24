import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

import '../../widgets/avatar.dart';
import '../user_bottom_sheet/user_bottom_sheet.dart';

class ParticipantListItem extends StatelessWidget {
  final User user;

  const ParticipantListItem(this.user, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final membershipBatch = <Membership, String>{
      Membership.join: '',
      Membership.ban: L10n.of(context)!.banned,
      Membership.invite: L10n.of(context)!.invited,
      Membership.leave: L10n.of(context)!.leftTheChat,
    };
    final permissionBatch = user.powerLevel == 100
        ? L10n.of(context)!.admin
        : user.powerLevel >= 50
            ? L10n.of(context)!.moderator
            : '';

    return Opacity(
      opacity: user.membership == Membership.join ? 1 : 0.5,
      child: ListTile(
        onTap: () => showModalBottomSheet(
          context: context,
          builder: (c) => UserBottomSheet(
            user: user,
            outerContext: context,
          ),
        ),
        title: Row(
          children: <Widget>[
            Text(user.calcDisplayname()),
            permissionBatch.isEmpty
                ? Container()
                : Container(
                    padding: const EdgeInsets.all(4),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).secondaryHeaderColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: Text(permissionBatch)),
                  ),
            membershipBatch[user.membership]!.isEmpty
                ? Container()
                : Container(
                    padding: const EdgeInsets.all(4),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).secondaryHeaderColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        Center(child: Text(membershipBatch[user.membership]!)),
                  ),
          ],
        ),
        subtitle: Text(user.id),
        leading:
            Avatar(mxContent: user.avatarUrl, name: user.calcDisplayname()),
      ),
    );
  }
}
