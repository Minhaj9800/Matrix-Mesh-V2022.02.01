import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:path_provider/path_provider.dart';

import '../platform_infos.dart';

class FlutterMatrixHiveStore extends FamedlySdkHiveDatabase {
  FlutterMatrixHiveStore(String name, {HiveCipher? encryptionCipher})
      : super(
          name,
          encryptionCipher: encryptionCipher,
        );

  static bool _hiveInitialized = false;
  static const String _hiveCipherStorageKey = 'hive_encryption_key';

  static Future<FamedlySdkHiveDatabase> hiveDatabaseBuilder(
      Client client) async {
    if (!kIsWeb && !_hiveInitialized) {
      _hiveInitialized = true;
    }
    HiveCipher? hiverCipher;
    try {
      // Workaround for secure storage is calling Platform.operatingSystem on web
      if (kIsWeb || Platform.isLinux) throw MissingPluginException();

      const secureStorage = FlutterSecureStorage();
      final containsEncryptionKey =
          await secureStorage.containsKey(key: _hiveCipherStorageKey);
      if (!containsEncryptionKey) {
        final key = Hive.generateSecureKey();
        await secureStorage.write(
          key: _hiveCipherStorageKey,
          value: base64UrlEncode(key),
        );
      }

      // workaround for if we just wrote to the key and it still doesn't exist
      final rawEncryptionKey =
          await secureStorage.read(key: _hiveCipherStorageKey);
      if (rawEncryptionKey == null) throw MissingPluginException();

      final encryptionKey = base64Url.decode(rawEncryptionKey);
      hiverCipher = HiveAesCipher(encryptionKey);
    } on MissingPluginException catch (_) {
      Logs().i('Hive encryption is not supported on this platform');
    }
    final db = FlutterMatrixHiveStore(
      client.clientName,
      encryptionCipher: hiverCipher,
    );
    try {
      await db.open();
    } catch (e, s) {
      Logs().e('Unable to open Hive. Delete and try again...', e, s);
      await db.clear();
      await db.open();
    }
    return db;
  }

  @override
  int get maxFileSize => supportsFileStoring ? 100 * 1024 * 1024 : 0;
  @override
  bool get supportsFileStoring => (PlatformInfos.isIOS ||
      PlatformInfos.isAndroid ||
      PlatformInfos.isDesktop);

  Future<String> _getFileStoreDirectory() async {
    try {
      try {
        return (await getApplicationSupportDirectory()).path;
      } catch (_) {
        return (await getApplicationDocumentsDirectory()).path;
      }
    } catch (_) {
      return (await getDownloadsDirectory())!.path;
    }
  }

  @override
  Future<Uint8List?> getFile(Uri mxcUri) async {
    if (!supportsFileStoring) return null;
    final tempDirectory = await _getFileStoreDirectory();
    final file =
        File('$tempDirectory/${Uri.encodeComponent(mxcUri.toString())}');
    if (await file.exists() == false) return null;
    final bytes = await file.readAsBytes();
    return bytes;
  }

  @override
  Future storeFile(Uri mxcUri, Uint8List bytes, int time) async {
    if (!supportsFileStoring) return null;
    final tempDirectory = await _getFileStoreDirectory();
    final file =
        File('$tempDirectory/${Uri.encodeComponent(mxcUri.toString())}');
    if (await file.exists()) return;
    await file.writeAsBytes(bytes);
    return;
  }
}
