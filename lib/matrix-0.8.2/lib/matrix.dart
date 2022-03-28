/*
 *   Famedly Matrix SDK
 *   Copyright (C) 2019, 2020, 2021 Famedly GmbH
 *
 *   This program is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as
 *   published by the Free Software Foundation, either version 3 of the
 *   License, or (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

/// Matrix SDK written in pure Dart.
library matrix;

export 'package:matrix_api_lite/matrix_api_lite.dart';

export 'src/client.dart';
export 'src/database/database_api.dart';
export 'src/database/hive_database.dart';
export 'src/database/fluffybox_database.dart';
export 'src/event.dart';
export 'src/event_status.dart';
export 'src/voip.dart';
export 'src/voip_content.dart';
export 'src/room.dart';
export 'src/timeline.dart';
export 'src/user.dart';
export 'src/utils/commands_extension.dart';
export 'src/utils/crypto/encrypted_file.dart';
export 'src/utils/device_keys_list.dart';
export 'src/utils/event_update.dart';
export 'src/utils/http_timeout.dart';
export 'src/utils/image_pack_extension.dart';
export 'src/utils/matrix_file.dart';
export 'src/utils/matrix_id_string_extension.dart';
export 'src/utils/matrix_localizations.dart';
export 'src/utils/receipt.dart';
export 'src/utils/sync_update_extension.dart';
export 'src/utils/to_device_event.dart';
export 'src/utils/uia_request.dart';
export 'src/utils/uri_extension.dart';
export 'src/voip_content.dart';
