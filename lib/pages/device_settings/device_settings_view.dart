import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';

import 'package:fluffychat/pages/device_settings/device_settings.dart';
import 'package:fluffychat/widgets/layouts/max_width_body.dart';
import 'user_device_list_item.dart';

class DevicesSettingsView extends StatelessWidget {
  final DevicesSettingsController controller;

  const DevicesSettingsView(this.controller, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(L10n.of(context)!.devices),
      ),
      body: MaxWidthBody(
        child: FutureBuilder<bool>(
          future: controller.loadUserDevices(context),
          builder: (BuildContext context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.error_outlined),
                    Text(snapshot.error.toString()),
                  ],
                ),
              );
            }
            if (!snapshot.hasData || controller.devices == null) {
              return const Center(
                  child: CircularProgressIndicator.adaptive(strokeWidth: 2));
            }
            return Column(
              children: <Widget>[
                if (controller.thisDevice != null)
                  UserDeviceListItem(
                    controller.thisDevice!,
                    rename: controller.renameDeviceAction,
                    remove: (d) => controller.removeDevicesAction([d]),
                    verify: controller.verifyDeviceAction,
                    block: controller.blockDeviceAction,
                    unblock: controller.unblockDeviceAction,
                  ),
                const Divider(height: 1),
                if (controller.notThisDevice.isNotEmpty)
                  ListTile(
                    title: Text(
                      controller.errorDeletingDevices ??
                          L10n.of(context)!.removeAllOtherDevices,
                      style: const TextStyle(color: Colors.red),
                    ),
                    trailing: controller.loadingDeletingDevices
                        ? const CircularProgressIndicator.adaptive(
                            strokeWidth: 2)
                        : const Icon(Icons.delete_outline),
                    onTap: controller.loadingDeletingDevices
                        ? null
                        : () => controller
                            .removeDevicesAction(controller.notThisDevice),
                  ),
                const Divider(height: 1),
                Expanded(
                  child: controller.notThisDevice.isEmpty
                      ? Center(
                          child: Icon(
                            Icons.devices_other,
                            size: 60,
                            color: Theme.of(context).secondaryHeaderColor,
                          ),
                        )
                      : ListView.separated(
                          separatorBuilder: (BuildContext context, int i) =>
                              const Divider(height: 1),
                          itemCount: controller.notThisDevice.length,
                          itemBuilder: (BuildContext context, int i) =>
                              UserDeviceListItem(
                            controller.notThisDevice[i],
                            rename: controller.renameDeviceAction,
                            remove: (d) => controller.removeDevicesAction([d]),
                            verify: controller.verifyDeviceAction,
                            block: controller.blockDeviceAction,
                            unblock: controller.unblockDeviceAction,
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
