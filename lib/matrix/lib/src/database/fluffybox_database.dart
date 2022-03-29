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

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:fluffybox/fluffybox.dart';
import 'package:fluffybox/hive.dart' show HiveCipher;
import '../../encryption/utils/olm_session.dart';
import '../../encryption/utils/outbound_group_session.dart';
import '../../encryption/utils/ssss_cache.dart';
import '../../encryption/utils/stored_inbound_group_session.dart';
import '../../matrix.dart';
import '../../src/utils/queued_to_device_event.dart';
import '../../src/utils/run_benchmarked.dart';

/// This database does not support file caching!
class FluffyBoxDatabase extends DatabaseApi {
  static const int version = 6;
  final String name;
  final String path;
  final HiveCipher? key;
  late final BoxCollection _collection;
  late Box<String> _clientBox;
  late Box<Map> _accountDataBox;
  late Box<Map> _roomsBox;
  late Box<Map> _toDeviceQueueBox;

  /// Key is a tuple as TupleKey(roomId, type) where stateKey can be
  /// an empty string.
  late Box<Map> _roomStateBox;

  /// Key is a tuple as TupleKey(roomId, userId)
  late Box<Map> _roomMembersBox;

  /// Key is a tuple as TupleKey(roomId, type)
  late Box<Map> _roomAccountDataBox;
  late Box<Map> _inboundGroupSessionsBox;
  late Box<Map> _outboundGroupSessionsBox;
  late Box<Map> _olmSessionsBox;

  /// Key is a tuple as TupleKey(userId, deviceId)
  late Box<Map> _userDeviceKeysBox;

  /// Key is the user ID as a String
  late Box<bool> _userDeviceKeysOutdatedBox;

  /// Key is a tuple as TupleKey(userId, publicKey)
  late Box<Map> _userCrossSigningKeysBox;
  late Box<Map> _ssssCacheBox;
  late Box<Map> _presencesBox;

  /// Key is a tuple as Multikey(roomId, fragmentId) while the default
  /// fragmentId is an empty String
  late Box<List> _timelineFragmentsBox;

  /// Key is a tuple as TupleKey(roomId, eventId)
  late Box<Map> _eventsBox;

  /// Key is a tuple as TupleKey(userId, deviceId)
  late Box<String> _seenDeviceIdsBox;

  late Box<String> _seenDeviceKeysBox;

  String get _clientBoxName => 'box_client';

  String get _accountDataBoxName => 'box_account_data';

  String get _roomsBoxName => 'box_rooms';

  String get _toDeviceQueueBoxName => 'box_to_device_queue';

  String get _roomStateBoxName => 'box_room_states';

  String get _roomMembersBoxName => 'box_room_members';

  String get _roomAccountDataBoxName => 'box_room_account_data';

  String get _inboundGroupSessionsBoxName => 'box_inbound_group_session';

  String get _outboundGroupSessionsBoxName => 'box_outbound_group_session';

  String get _olmSessionsBoxName => 'box_olm_session';

  String get _userDeviceKeysBoxName => 'box_user_device_keys';

  String get _userDeviceKeysOutdatedBoxName => 'box_user_device_keys_outdated';

  String get _userCrossSigningKeysBoxName => 'box_cross_signing_keys';

  String get _ssssCacheBoxName => 'box_ssss_cache';

  String get _presencesBoxName => 'box_presences';

  String get _timelineFragmentsBoxName => 'box_timeline_fragments';

  String get _eventsBoxName => 'box_events';

  String get _seenDeviceIdsBoxName => 'box_seen_device_ids';

  String get _seenDeviceKeysBoxName => 'box_seen_device_keys';

  FluffyBoxDatabase(this.name, this.path, {this.key});

  @override
  int get maxFileSize => 0;

  Future<void> open() async {
    _collection = await BoxCollection.open(
      name,
      {
        _clientBoxName,
        _accountDataBoxName,
        _roomsBoxName,
        _toDeviceQueueBoxName,
        _roomStateBoxName,
        _roomMembersBoxName,
        _roomAccountDataBoxName,
        _inboundGroupSessionsBoxName,
        _outboundGroupSessionsBoxName,
        _olmSessionsBoxName,
        _userDeviceKeysBoxName,
        _userDeviceKeysOutdatedBoxName,
        _userCrossSigningKeysBoxName,
        _ssssCacheBoxName,
        _presencesBoxName,
        _timelineFragmentsBoxName,
        _eventsBoxName,
        _seenDeviceIdsBoxName,
        _seenDeviceKeysBoxName,
      },
      key: key,
      path: path,
    );
    _clientBox = await _collection.openBox(
      _clientBoxName,
      preload: true,
    );
    _accountDataBox = await _collection.openBox(
      _accountDataBoxName,
      preload: true,
    );
    _roomsBox = await _collection.openBox(
      _roomsBoxName,
      preload: true,
    );
    _roomStateBox = await _collection.openBox(
      _roomStateBoxName,
    );
    _roomMembersBox = await _collection.openBox(
      _roomMembersBoxName,
    );
    _toDeviceQueueBox = await _collection.openBox(
      _toDeviceQueueBoxName,
      preload: true,
    );
    _roomAccountDataBox = await _collection.openBox(
      _roomAccountDataBoxName,
      preload: true,
    );
    _inboundGroupSessionsBox = await _collection.openBox(
      _inboundGroupSessionsBoxName,
    );
    _outboundGroupSessionsBox = await _collection.openBox(
      _outboundGroupSessionsBoxName,
    );
    _olmSessionsBox = await _collection.openBox(
      _olmSessionsBoxName,
    );
    _userDeviceKeysBox = await _collection.openBox(
      _userDeviceKeysBoxName,
    );
    _userDeviceKeysOutdatedBox = await _collection.openBox(
      _userDeviceKeysOutdatedBoxName,
    );
    _userCrossSigningKeysBox = await _collection.openBox(
      _userCrossSigningKeysBoxName,
    );
    _ssssCacheBox = await _collection.openBox(
      _ssssCacheBoxName,
    );
    _presencesBox = await _collection.openBox(
      _presencesBoxName,
    );
    _timelineFragmentsBox = await _collection.openBox(
      _timelineFragmentsBoxName,
    );
    _eventsBox = await _collection.openBox(
      _eventsBoxName,
    );
    _seenDeviceIdsBox = await _collection.openBox(
      _seenDeviceIdsBoxName,
    );
    _seenDeviceKeysBox = await _collection.openBox(
      _seenDeviceKeysBoxName,
    );

    // Check version and check if we need a migration
    final currentVersion = int.tryParse(await _clientBox.get('version') ?? '');
    if (currentVersion == null) {
      await _clientBox.put('version', version.toString());
    } else if (currentVersion != version) {
      await _migrateFromVersion(currentVersion);
    }

    return;
  }

  Future<void> _migrateFromVersion(int currentVersion) async {
    Logs().i('Migrate store database from version $currentVersion to $version');
    await clearCache();
    await _clientBox.put('version', version.toString());
  }

  @override
  Future<void> clear() => _collection.deleteFromDisk();

  @override
  Future<void> clearCache() => transaction(() async {
        await _roomsBox.clear();
        await _accountDataBox.clear();
        await _roomStateBox.clear();
        await _roomMembersBox.clear();
        await _eventsBox.clear();
        await _timelineFragmentsBox.clear();
        await _outboundGroupSessionsBox.clear();
        await _presencesBox.clear();
        await _clientBox.delete('prev_batch');
      });

  @override
  Future<void> clearSSSSCache() => _ssssCacheBox.clear();

  @override
  Future<void> close() async => _collection.close();

  @override
  Future<void> deleteFromToDeviceQueue(int id) async {
    await _toDeviceQueueBox.delete(id.toString());
    return;
  }

  @override
  Future<void> deleteOldFiles(int savedAt) async {
    return;
  }

  @override
  Future<void> forgetRoom(String roomId) => transaction(() async {
        await _timelineFragmentsBox.delete(TupleKey(roomId, '').toString());
        final eventsBoxKeys = await _eventsBox.getAllKeys();
        for (final key in eventsBoxKeys) {
          final multiKey = TupleKey.fromString(key);
          if (multiKey.parts.first != roomId) continue;
          await _eventsBox.delete(key);
        }
        final roomStateBoxKeys = await _roomStateBox.getAllKeys();
        for (final key in roomStateBoxKeys) {
          final multiKey = TupleKey.fromString(key);
          if (multiKey.parts.first != roomId) continue;
          await _roomStateBox.delete(key);
        }
        final roomMembersBoxKeys = await _roomMembersBox.getAllKeys();
        for (final key in roomMembersBoxKeys) {
          final multiKey = TupleKey.fromString(key);
          if (multiKey.parts.first != roomId) continue;
          await _roomMembersBox.delete(key);
        }
        final roomAccountDataBoxKeys = await _roomAccountDataBox.getAllKeys();
        for (final key in roomAccountDataBoxKeys) {
          final multiKey = TupleKey.fromString(key);
          if (multiKey.parts.first != roomId) continue;
          await _roomAccountDataBox.delete(key);
        }
        await _roomsBox.delete(roomId);
      });

  @override
  Future<Map<String, BasicEvent>> getAccountData() =>
      runBenchmarked<Map<String, BasicEvent>>('Get all account data from store',
          () async {
        final accountData = <String, BasicEvent>{};
        final raws = await _accountDataBox.getAllValues();
        for (final entry in raws.entries) {
          accountData[entry.key] = BasicEvent(
            type: entry.key,
            content: copyMap(entry.value),
          );
        }
        return accountData;
      });

  @override
  Future<Map<String, dynamic>?> getClient(String name) =>
      runBenchmarked('Get Client from store', () async {
        final map = <String, dynamic>{};
        final keys = await _clientBox.getAllKeys();
        for (final key in keys) {
          if (key == 'version') continue;
          final value = await _clientBox.get(key);
          if (value != null) map[key] = value;
        }
        if (map.isEmpty) return null;
        return map;
      });

  @override
  Future<Event?> getEventById(String eventId, Room room) async {
    final raw = await _eventsBox.get(TupleKey(room.id, eventId).toString());
    if (raw == null) return null;
    return Event.fromJson(copyMap(raw), room);
  }

  /// Loads a whole list of events at once from the store for a specific room
  Future<List<Event>> _getEventsByIds(List<String> eventIds, Room room) async {
    final keys = eventIds
        .map(
          (eventId) => TupleKey(room.id, eventId).toString(),
        )
        .toList();
    final rawEvents = await _eventsBox.getAll(keys);
    return rawEvents
        .map((rawEvent) => Event.fromJson(copyMap(rawEvent!), room))
        .toList();
  }

  @override
  Future<List<Event>> getEventList(
    Room room, {
    int start = 0,
    int? limit,
  }) =>
      runBenchmarked<List<Event>>('Get event list', () async {
        // Get the synced event IDs from the store
        final timelineKey = TupleKey(room.id, '').toString();
        final timelineEventIds =
            (await _timelineFragmentsBox.get(timelineKey) ?? []);

        // Get the local stored SENDING events from the store
        late final List sendingEventIds;
        if (start != 0) {
          sendingEventIds = [];
        } else {
          final sendingTimelineKey = TupleKey(room.id, 'SENDING').toString();
          sendingEventIds =
              (await _timelineFragmentsBox.get(sendingTimelineKey) ?? []);
        }

        // Combine those two lists while respecting the start and limit parameters.
        final end = min(timelineEventIds.length,
            start + (limit ?? timelineEventIds.length));
        final eventIds = sendingEventIds +
            (start < timelineEventIds.length
                ? timelineEventIds.getRange(start, end).toList()
                : []);

        return await _getEventsByIds(eventIds.cast<String>(), room);
      });

  @override
  Future<Uint8List?> getFile(Uri mxcUri) async {
    return null;
  }

  @override
  Future<StoredInboundGroupSession?> getInboundGroupSession(
    String roomId,
    String sessionId,
  ) async {
    final raw = await _inboundGroupSessionsBox.get(sessionId);
    if (raw == null) return null;
    return StoredInboundGroupSession.fromJson(copyMap(raw));
  }

  @override
  Future<List<StoredInboundGroupSession>>
      getInboundGroupSessionsToUpload() async {
    final sessions = (await _inboundGroupSessionsBox.getAllValues())
        .values
        .where((rawSession) => rawSession['uploaded'] == false)
        .take(50)
        .map(
          (json) => StoredInboundGroupSession.fromJson(
            copyMap(json),
          ),
        )
        .toList();
    return sessions;
  }

  @override
  Future<List<String>> getLastSentMessageUserDeviceKey(
      String userId, String deviceId) async {
    final raw =
        await _userDeviceKeysBox.get(TupleKey(userId, deviceId).toString());
    if (raw == null) return <String>[];
    return <String>[raw['last_sent_message']];
  }

  @override
  Future<void> storeOlmSession(String identityKey, String sessionId,
      String pickle, int lastReceived) async {
    final rawSessions = (await _olmSessionsBox.get(identityKey)) ?? {};
    rawSessions[sessionId] = <String, dynamic>{
      'identity_key': identityKey,
      'pickle': pickle,
      'session_id': sessionId,
      'last_received': lastReceived,
    };
    await _olmSessionsBox.put(identityKey, rawSessions);
    return;
  }

  @override
  Future<List<OlmSession>> getOlmSessions(
      String identityKey, String userId) async {
    final rawSessions = await _olmSessionsBox.get(identityKey);
    if (rawSessions == null || rawSessions.isEmpty) return <OlmSession>[];
    return rawSessions.values
        .map((json) => OlmSession.fromJson(copyMap(json), userId))
        .toList();
  }

  @override
  Future<Map<String, Map>> getAllOlmSessions() =>
      _olmSessionsBox.getAllValues();

  @override
  Future<List<OlmSession>> getOlmSessionsForDevices(
      List<String> identityKey, String userId) async {
    final sessions = await Future.wait(
        identityKey.map((identityKey) => getOlmSessions(identityKey, userId)));
    return <OlmSession>[for (final sublist in sessions) ...sublist];
  }

  @override
  Future<OutboundGroupSession?> getOutboundGroupSession(
      String roomId, String userId) async {
    final raw = await _outboundGroupSessionsBox.get(roomId);
    if (raw == null) return null;
    return OutboundGroupSession.fromJson(copyMap(raw), userId);
  }

  @override
  Future<List<Room>> getRoomList(Client client) =>
      runBenchmarked<List<Room>>('Get room list from store', () async {
        final rooms = <String, Room>{};
        final userID = client.userID;

        final rawRooms = await _roomsBox.getAllValues();

        final getRoomStateRequests = <String, Future<List>>{};
        final getRoomMembersRequests = <String, Future<List>>{};
        for (final raw in rawRooms.values) {
          // Get the room
          final room = Room.fromJson(copyMap(raw), client);

          final membersToPostload = <String>{if (userID != null) userID};

          // If the room is a direct chat, those IDs should be there too
          if (room.isDirectChat) {
            membersToPostload
                .add(TupleKey(room.id, room.directChatMatrixID!).toString());
          }
          // the lastEvent message preview might have an author we need to fetch, if it is a group chat
          final lastEvent = room.getState(EventTypes.Message);
          if (lastEvent != null && !room.isDirectChat) {
            membersToPostload
                .add(TupleKey(room.id, lastEvent.senderId).toString());
          }
          // if the room has no name and no canonical alias, its name is calculated
          // based on the heroes of the room
          if (room.getState(EventTypes.RoomName) == null &&
              room.getState(EventTypes.RoomCanonicalAlias) == null) {
            // we don't have a name and no canonical alias, so we'll need to
            // post-load the heroes
            final heroes = room.summary.mHeroes;
            if (heroes != null) {
              heroes.forEach((hero) => membersToPostload.add(hero));
            }
          }

          // Get the "important" room states. All other states will be loaded once
          // `getUnimportantRoomStates()` is called.
          final dbKeys = client.importantStateEvents
              .map((state) => TupleKey(room.id, state).toString())
              .toList();
          getRoomStateRequests[room.id] = _roomStateBox.getAll(
            dbKeys,
          );

          // Load members
          final membersDbKeys = membersToPostload
              .map((member) => TupleKey(room.id, member).toString())
              .toList();
          getRoomMembersRequests[room.id] = _roomMembersBox.getAll(
            membersDbKeys,
          );

          // Add to the list and continue.
          rooms[room.id] = room;
        }

        for (final room in rooms.values) {
          // Add states to the room
          final statesList = await getRoomStateRequests[room.id];
          if (statesList != null) {
            for (final states in statesList) {
              if (states == null) continue;
              final stateEvents = states.values
                  .map((raw) => Event.fromJson(copyMap(raw), room))
                  .toList();
              for (final state in stateEvents) {
                room.setState(state);
              }
            }
          }

          // Add members to the room
          final members = await getRoomMembersRequests[room.id];
          if (members != null) {
            for (final member in members) {
              if (member == null) continue;
              room.setState(Event.fromJson(copyMap(member), room));
            }
          }
        }

        // Get the room account data
        final roomAccountDataRaws = await _roomAccountDataBox.getAllValues();
        for (final entry in roomAccountDataRaws.entries) {
          final keys = TupleKey.fromString(entry.key);
          final basicRoomEvent = BasicRoomEvent.fromJson(
            copyMap(entry.value),
          );
          final roomId = keys.parts.first;
          if (rooms.containsKey(roomId)) {
            rooms[roomId]!.roomAccountData[basicRoomEvent.type] =
                basicRoomEvent;
          } else {
            Logs().w(
                'Found account data for unknown room $roomId. Delete now...');
            await _roomAccountDataBox
                .delete(TupleKey(roomId, basicRoomEvent.type).toString());
          }
        }

        return rooms.values.toList();
      });

  @override
  Future<SSSSCache?> getSSSSCache(String type) async {
    final raw = await _ssssCacheBox.get(type);
    if (raw == null) return null;
    return SSSSCache.fromJson(copyMap(raw));
  }

  @override
  Future<List<QueuedToDeviceEvent>> getToDeviceEventQueue() async {
    final raws = await _toDeviceQueueBox.getAllValues();
    final copiedRaws = raws.entries.map((entry) {
      final copiedRaw = copyMap(entry.value);
      copiedRaw['id'] = int.parse(entry.key);
      copiedRaw['content'] = jsonDecode(copiedRaw['content']);
      return copiedRaw;
    }).toList();
    return copiedRaws.map((raw) => QueuedToDeviceEvent.fromJson(raw)).toList();
  }

  @override
  Future<List<Event>> getUnimportantRoomEventStatesForRoom(
      List<String> events, Room room) async {
    final keys = (await _roomStateBox.getAllKeys()).where((key) {
      final tuple = TupleKey.fromString(key);
      return tuple.parts.first == room.id && !events.contains(tuple.parts[1]);
    });

    final unimportantEvents = <Event>[];
    for (final key in keys) {
      final states = await _roomStateBox.get(key);
      if (states == null) continue;
      unimportantEvents.addAll(
          states.values.map((raw) => Event.fromJson(copyMap(raw), room)));
    }
    return unimportantEvents;
  }

  @override
  Future<User?> getUser(String userId, Room room) async {
    final state =
        await _roomMembersBox.get(TupleKey(room.id, userId).toString());
    if (state == null) return null;
    return Event.fromJson(copyMap(state), room).asUser;
  }

  @override
  Future<Map<String, DeviceKeysList>> getUserDeviceKeys(Client client) =>
      runBenchmarked<Map<String, DeviceKeysList>>(
          'Get all user device keys from store', () async {
        final deviceKeysOutdated =
            await _userDeviceKeysOutdatedBox.getAllKeys();
        if (deviceKeysOutdated.isEmpty) {
          return {};
        }
        final res = <String, DeviceKeysList>{};
        final userDeviceKeysBoxKeys = await _userDeviceKeysBox.getAllKeys();
        final userCrossSigningKeysBoxKeys =
            await _userCrossSigningKeysBox.getAllKeys();
        for (final userId in deviceKeysOutdated) {
          final deviceKeysBoxKeys = userDeviceKeysBoxKeys.where((tuple) {
            final tupleKey = TupleKey.fromString(tuple);
            return tupleKey.parts.first == userId;
          });
          final crossSigningKeysBoxKeys =
              userCrossSigningKeysBoxKeys.where((tuple) {
            final tupleKey = TupleKey.fromString(tuple);
            return tupleKey.parts.first == userId;
          });
          final childEntries = await Future.wait(
            deviceKeysBoxKeys.map(
              (key) async {
                final userDeviceKey = await _userDeviceKeysBox.get(key);
                if (userDeviceKey == null) return null;
                return copyMap(userDeviceKey);
              },
            ),
          );
          final crossSigningEntries = await Future.wait(
            crossSigningKeysBoxKeys.map(
              (key) async {
                final crossSigningKey = await _userCrossSigningKeysBox.get(key);
                if (crossSigningKey == null) return null;
                return copyMap(crossSigningKey);
              },
            ),
          );
          res[userId] = DeviceKeysList.fromDbJson(
              {
                'client_id': client.id,
                'user_id': userId,
                'outdated': await _userDeviceKeysOutdatedBox.get(userId),
              },
              childEntries
                  .where((c) => c != null)
                  .toList()
                  .cast<Map<String, dynamic>>(),
              crossSigningEntries
                  .where((c) => c != null)
                  .toList()
                  .cast<Map<String, dynamic>>(),
              client);
        }
        return res;
      });

  @override
  Future<List<User>> getUsers(Room room) async {
    final users = <User>[];
    final keys = (await _roomMembersBox.getAllKeys())
        .where((key) => TupleKey.fromString(key).parts.first == room.id)
        .toList();
    final states = await _roomMembersBox.getAll(keys);
    states.removeWhere((state) => state == null);
    states.forEach(
      (state) => users.add(Event.fromJson(copyMap(state!), room).asUser),
    );

    return users;
  }

  @override
  Future<int> insertClient(
      String name,
      String homeserverUrl,
      String token,
      String userId,
      String? deviceId,
      String? deviceName,
      String? prevBatch,
      String? olmAccount) async {
    await transaction(() async {
      await _clientBox.put('homeserver_url', homeserverUrl);
      await _clientBox.put('token', token);
      await _clientBox.put('user_id', userId);
      if (deviceId == null) {
        await _clientBox.delete('device_id');
      } else {
        await _clientBox.put('device_id', deviceId);
      }
      if (deviceName == null) {
        await _clientBox.delete('device_name');
      } else {
        await _clientBox.put('device_name', deviceName);
      }
      if (prevBatch == null) {
        await _clientBox.delete('prev_batch');
      } else {
        await _clientBox.put('prev_batch', prevBatch);
      }
      if (olmAccount == null) {
        await _clientBox.delete('olm_account');
      } else {
        await _clientBox.put('olm_account', olmAccount);
      }
      await _clientBox.delete('sync_filter_id');
    });
    return 0;
  }

  @override
  Future<int> insertIntoToDeviceQueue(
      String type, String txnId, String content) async {
    final id = DateTime.now().millisecondsSinceEpoch;
    await _toDeviceQueueBox.put(id.toString(), {
      'type': type,
      'txn_id': txnId,
      'content': content,
    });
    return id;
  }

  @override
  Future<void> markInboundGroupSessionAsUploaded(
      String roomId, String sessionId) async {
    final raw = await _inboundGroupSessionsBox.get(sessionId);
    if (raw == null) {
      Logs().w(
          'Tried to mark inbound group session as uploaded which was not found in the database!');
      return;
    }
    raw['uploaded'] = true;
    await _inboundGroupSessionsBox.put(sessionId, raw);
    return;
  }

  @override
  Future<void> markInboundGroupSessionsAsNeedingUpload() async {
    final keys = await _inboundGroupSessionsBox.getAllKeys();
    for (final sessionId in keys) {
      final raw = await _inboundGroupSessionsBox.get(sessionId);
      if (raw == null) continue;
      raw['uploaded'] = false;
      await _inboundGroupSessionsBox.put(sessionId, raw);
    }
    return;
  }

  @override
  Future<void> removeEvent(String eventId, String roomId) async {
    await _eventsBox.delete(TupleKey(roomId, eventId).toString());
    final keys = await _timelineFragmentsBox.getAllKeys();
    for (final key in keys) {
      final multiKey = TupleKey.fromString(key);
      if (multiKey.parts.first != roomId) continue;
      final eventIds = await _timelineFragmentsBox.get(key) ?? [];
      final prevLength = eventIds.length;
      eventIds.removeWhere((id) => id == eventId);
      if (eventIds.length < prevLength) {
        await _timelineFragmentsBox.put(key, eventIds);
      }
    }
    return;
  }

  @override
  Future<void> removeOutboundGroupSession(String roomId) async {
    await _outboundGroupSessionsBox.delete(roomId);
    return;
  }

  @override
  Future<void> removeUserCrossSigningKey(
      String userId, String publicKey) async {
    await _userCrossSigningKeysBox
        .delete(TupleKey(userId, publicKey).toString());
    return;
  }

  @override
  Future<void> removeUserDeviceKey(String userId, String deviceId) async {
    await _userDeviceKeysBox.delete(TupleKey(userId, deviceId).toString());
    return;
  }

  @override
  Future<void> resetNotificationCount(String roomId) async {
    final raw = await _roomsBox.get(roomId);
    if (raw == null) return;
    raw['notification_count'] = raw['highlight_count'] = 0;
    await _roomsBox.put(roomId, raw);
    return;
  }

  @override
  Future<void> setBlockedUserCrossSigningKey(
      bool blocked, String userId, String publicKey) async {
    final raw = await _userCrossSigningKeysBox
        .get(TupleKey(userId, publicKey).toString());
    raw!['blocked'] = blocked;
    await _userCrossSigningKeysBox.put(
      TupleKey(userId, publicKey).toString(),
      raw,
    );
    return;
  }

  @override
  Future<void> setBlockedUserDeviceKey(
      bool blocked, String userId, String deviceId) async {
    final raw =
        await _userDeviceKeysBox.get(TupleKey(userId, deviceId).toString());
    raw!['blocked'] = blocked;
    await _userDeviceKeysBox.put(
      TupleKey(userId, deviceId).toString(),
      raw,
    );
    return;
  }

  @override
  Future<void> setLastActiveUserDeviceKey(
      int lastActive, String userId, String deviceId) async {
    final raw =
        await _userDeviceKeysBox.get(TupleKey(userId, deviceId).toString());
    raw!['last_active'] = lastActive;
    await _userDeviceKeysBox.put(
      TupleKey(userId, deviceId).toString(),
      raw,
    );
  }

  @override
  Future<void> setLastSentMessageUserDeviceKey(
      String lastSentMessage, String userId, String deviceId) async {
    final raw =
        await _userDeviceKeysBox.get(TupleKey(userId, deviceId).toString());
    raw!['last_sent_message'] = lastSentMessage;
    await _userDeviceKeysBox.put(
      TupleKey(userId, deviceId).toString(),
      raw,
    );
  }

  @override
  Future<void> setRoomPrevBatch(
      String prevBatch, String roomId, Client client) async {
    final raw = await _roomsBox.get(roomId);
    if (raw == null) return;
    final room = Room.fromJson(copyMap(raw), client);
    room.prev_batch = prevBatch;
    await _roomsBox.put(roomId, room.toJson());
    return;
  }

  @override
  Future<void> setVerifiedUserCrossSigningKey(
      bool verified, String userId, String publicKey) async {
    final raw = (await _userCrossSigningKeysBox
            .get(TupleKey(userId, publicKey).toString())) ??
        {};
    raw['verified'] = verified;
    await _userCrossSigningKeysBox.put(
      TupleKey(userId, publicKey).toString(),
      raw,
    );
    return;
  }

  @override
  Future<void> setVerifiedUserDeviceKey(
      bool verified, String userId, String deviceId) async {
    final raw =
        await _userDeviceKeysBox.get(TupleKey(userId, deviceId).toString());
    raw!['verified'] = verified;
    await _userDeviceKeysBox.put(
      TupleKey(userId, deviceId).toString(),
      raw,
    );
    return;
  }

  @override
  Future<void> storeAccountData(String type, String content) async {
    await _accountDataBox.put(type, copyMap(jsonDecode(content)));
    return;
  }

  @override
  Future<void> storeEventUpdate(EventUpdate eventUpdate, Client client) async {
    // Ephemerals should not be stored
    if (eventUpdate.type == EventUpdateType.ephemeral) return;
    final tmpRoom = Room(id: eventUpdate.roomID, client: client);

    // In case of this is a redaction event
    if (eventUpdate.content['type'] == EventTypes.Redaction) {
      final event = await getEventById(eventUpdate.content['redacts'], tmpRoom);
      if (event != null) {
        event.setRedactionEvent(Event.fromJson(eventUpdate.content, tmpRoom));
        await _eventsBox.put(
            TupleKey(eventUpdate.roomID, event.eventId).toString(),
            event.toJson());
      }
    }

    // Store a common message event
    if ({EventUpdateType.timeline, EventUpdateType.history}
        .contains(eventUpdate.type)) {
      final eventId = eventUpdate.content['event_id'];
      // Is this ID already in the store?
      final prevEvent = await _eventsBox
          .get(TupleKey(eventUpdate.roomID, eventId).toString());
      final prevStatus = prevEvent == null
          ? null
          : () {
              final json = copyMap(prevEvent);
              final statusInt = json.tryGet<int>('status') ??
                  json
                      .tryGetMap<String, dynamic>('unsigned')
                      ?.tryGet<int>(messageSendingStatusKey);
              return statusInt == null ? null : eventStatusFromInt(statusInt);
            }();

      // calculate the status
      final newStatus = eventStatusFromInt(
        eventUpdate.content.tryGet<int>('status') ??
            eventUpdate.content
                .tryGetMap<String, dynamic>('unsigned')
                ?.tryGet<int>(messageSendingStatusKey) ??
            EventStatus.synced.intValue,
      );

      // Is this the response to a sending event which is already synced? Then
      // there is nothing to do here.
      if (!newStatus.isSynced && prevStatus != null && prevStatus.isSynced) {
        return;
      }

      final status = newStatus.isError || prevStatus == null
          ? newStatus
          : latestEventStatus(
              prevStatus,
              newStatus,
            );

      // Add the status and the sort order to the content so it get stored
      eventUpdate.content['unsigned'] ??= <String, dynamic>{};
      eventUpdate.content['unsigned'][messageSendingStatusKey] =
          eventUpdate.content['status'] = status.intValue;

      // In case this event has sent from this account we have a transaction ID
      final transactionId = eventUpdate.content
          .tryGetMap<String, dynamic>('unsigned')
          ?.tryGet<String>('transaction_id');
      await _eventsBox.put(TupleKey(eventUpdate.roomID, eventId).toString(),
          eventUpdate.content);

      // Update timeline fragments
      final key = TupleKey(eventUpdate.roomID, status.isSent ? '' : 'SENDING')
          .toString();

      final eventIds =
          List<String>.from(await _timelineFragmentsBox.get(key) ?? []);

      if (!eventIds.contains(eventId)) {
        if (eventUpdate.type == EventUpdateType.history) {
          eventIds.add(eventId);
        } else {
          eventIds.insert(0, eventId);
        }
        await _timelineFragmentsBox.put(key, eventIds);
      } else if (status.isSynced &&
          prevStatus != null &&
          prevStatus.isSent &&
          eventUpdate.type != EventUpdateType.history) {
        // Status changes from 1 -> 2? Make sure event is correctly sorted.
        eventIds.remove(eventId);
        eventIds.insert(0, eventId);
      }

      // If event comes from server timeline, remove sending events with this ID
      if (status.isSent) {
        final key = TupleKey(eventUpdate.roomID, 'SENDING').toString();
        final eventIds =
            List<String>.from(await _timelineFragmentsBox.get(key) ?? []);
        final i = eventIds.indexWhere((id) => id == eventId);
        if (i != -1) {
          await _timelineFragmentsBox.put(key, eventIds..removeAt(i));
        }
      }

      // Is there a transaction id? Then delete the event with this id.
      if (!status.isError && !status.isSending && transactionId != null) {
        await removeEvent(transactionId, eventUpdate.roomID);
      }
    }

    // Store a common state event
    if ({
      EventUpdateType.timeline,
      EventUpdateType.state,
      EventUpdateType.inviteState
    }.contains(eventUpdate.type)) {
      if (eventUpdate.content['type'] == EventTypes.RoomMember) {
        await _roomMembersBox.put(
            TupleKey(
              eventUpdate.roomID,
              eventUpdate.content['state_key'],
            ).toString(),
            eventUpdate.content);
      } else {
        final key = TupleKey(
          eventUpdate.roomID,
          eventUpdate.content['type'],
        ).toString();
        final stateMap = copyMap(await _roomStateBox.get(key) ?? {});
        // store state events and new messages, that either are not an edit or an edit of the lastest message
        // An edit is an event, that has an edit relation to the latest event. In some cases for the second edit, we need to compare if both have an edit relation to the same event instead.
        if (eventUpdate.content
                .tryGetMap<String, dynamic>('content')
                ?.tryGetMap<String, dynamic>('m.relates_to') ==
            null) {
          stateMap[eventUpdate.content['state_key'] ?? ''] =
              eventUpdate.content;
          await _roomStateBox.put(key, stateMap);
        } else {
          final editedEventRelationshipEventId = eventUpdate.content
              .tryGetMap<String, dynamic>('content')
              ?.tryGetMap<String, dynamic>('m.relates_to')
              ?.tryGet<String>('event_id');
          final state = stateMap[''] == null
              ? null
              : Event.fromJson(stateMap[''] as Map<String, dynamic>, tmpRoom);
          if (eventUpdate.content['type'] != EventTypes.Message ||
              eventUpdate.content
                      .tryGetMap<String, dynamic>('content')
                      ?.tryGetMap<String, dynamic>('m.relates_to')
                      ?.tryGet<String>('rel_type') !=
                  RelationshipTypes.edit ||
              editedEventRelationshipEventId == state?.eventId ||
              ((state?.relationshipType == RelationshipTypes.edit &&
                  editedEventRelationshipEventId ==
                      state?.relationshipEventId))) {
            stateMap[eventUpdate.content['state_key'] ?? ''] =
                eventUpdate.content;
            await _roomStateBox.put(key, stateMap);
          }
        }
      }
    }

    // Store a room account data event
    if (eventUpdate.type == EventUpdateType.accountData) {
      await _roomAccountDataBox.put(
        TupleKey(
          eventUpdate.roomID,
          eventUpdate.content['type'],
        ).toString(),
        eventUpdate.content,
      );
    }
  }

  @override
  Future<void> storeFile(Uri mxcUri, Uint8List bytes, int time) async {
    return;
  }

  @override
  Future<void> storeInboundGroupSession(
      String roomId,
      String sessionId,
      String pickle,
      String content,
      String indexes,
      String allowedAtIndex,
      String senderKey,
      String senderClaimedKey) async {
    await _inboundGroupSessionsBox.put(
        sessionId,
        StoredInboundGroupSession(
          roomId: roomId,
          sessionId: sessionId,
          pickle: pickle,
          content: content,
          indexes: indexes,
          allowedAtIndex: allowedAtIndex,
          senderKey: senderKey,
          senderClaimedKeys: senderClaimedKey,
          uploaded: false,
        ).toJson());
    return;
  }

  @override
  Future<void> storeOutboundGroupSession(
      String roomId, String pickle, String deviceIds, int creationTime) async {
    await _outboundGroupSessionsBox.put(roomId, <String, dynamic>{
      'room_id': roomId,
      'pickle': pickle,
      'device_ids': deviceIds,
      'creation_time': creationTime,
    });
    return;
  }

  @override
  Future<void> storePrevBatch(
    String prevBatch,
  ) async {
    if ((await _clientBox.getAllKeys()).isEmpty) return;
    await _clientBox.put('prev_batch', prevBatch);
    return;
  }

  @override
  Future<void> storeRoomUpdate(
      String roomId, SyncRoomUpdate roomUpdate, Client client) async {
    // Leave room if membership is leave
    if (roomUpdate is LeftRoomUpdate) {
      await forgetRoom(roomId);
      return;
    }
    final membership = roomUpdate is LeftRoomUpdate
        ? Membership.leave
        : roomUpdate is InvitedRoomUpdate
            ? Membership.invite
            : Membership.join;
    // Make sure room exists
    final currentRawRoom = await _roomsBox.get(roomId);
    if (currentRawRoom == null) {
      await _roomsBox.put(
          roomId,
          roomUpdate is JoinedRoomUpdate
              ? Room(
                  client: client,
                  id: roomId,
                  membership: membership,
                  highlightCount:
                      roomUpdate.unreadNotifications?.highlightCount?.toInt() ??
                          0,
                  notificationCount: roomUpdate
                          .unreadNotifications?.notificationCount
                          ?.toInt() ??
                      0,
                  prev_batch: roomUpdate.timeline?.prevBatch,
                  summary: roomUpdate.summary,
                ).toJson()
              : Room(
                  client: client,
                  id: roomId,
                  membership: membership,
                ).toJson());
    } else if (roomUpdate is JoinedRoomUpdate) {
      final currentRoom = Room.fromJson(copyMap(currentRawRoom), client);
      await _roomsBox.put(
          roomId,
          Room(
            client: client,
            id: roomId,
            membership: membership,
            highlightCount:
                roomUpdate.unreadNotifications?.highlightCount?.toInt() ??
                    currentRoom.highlightCount,
            notificationCount:
                roomUpdate.unreadNotifications?.notificationCount?.toInt() ??
                    currentRoom.notificationCount,
            prev_batch:
                roomUpdate.timeline?.prevBatch ?? currentRoom.prev_batch,
            summary: RoomSummary.fromJson(currentRoom.summary.toJson()
              ..addAll(roomUpdate.summary?.toJson() ?? {})),
          ).toJson());
    }

    // Is the timeline limited? Then all previous messages should be
    // removed from the database!
    if (roomUpdate is JoinedRoomUpdate &&
        roomUpdate.timeline?.limited == true) {
      await _timelineFragmentsBox.delete(TupleKey(roomId, '').toString());
    }
  }

  @override
  Future<void> storeSSSSCache(
      String type, String keyId, String ciphertext, String content) async {
    await _ssssCacheBox.put(
        type,
        SSSSCache(
          type: type,
          keyId: keyId,
          ciphertext: ciphertext,
          content: content,
        ).toJson());
  }

  @override
  Future<void> storeSyncFilterId(
    String syncFilterId,
  ) async {
    await _clientBox.put('sync_filter_id', syncFilterId);
  }

  @override
  Future<void> storeUserCrossSigningKey(String userId, String publicKey,
      String content, bool verified, bool blocked) async {
    await _userCrossSigningKeysBox.put(
      TupleKey(userId, publicKey).toString(),
      {
        'user_id': userId,
        'public_key': publicKey,
        'content': content,
        'verified': verified,
        'blocked': blocked,
      },
    );
  }

  @override
  Future<void> storeUserDeviceKey(String userId, String deviceId,
      String content, bool verified, bool blocked, int lastActive) async {
    await _userDeviceKeysBox.put(TupleKey(userId, deviceId).toString(), {
      'user_id': userId,
      'device_id': deviceId,
      'content': content,
      'verified': verified,
      'blocked': blocked,
      'last_active': lastActive,
      'last_sent_message': '',
    });
    return;
  }

  @override
  Future<void> storeUserDeviceKeysInfo(String userId, bool outdated) async {
    await _userDeviceKeysOutdatedBox.put(userId, outdated);
    return;
  }

  Completer<void>? _transactionLock;
  final _transactionZones = <Zone>{};

  @override
  Future<T> transaction<T>(Future<T> Function() action) async {
    // we want transactions to lock, however NOT if transactoins are run inside of each other.
    // to be able to do this, we use dart zones (https://dart.dev/articles/archive/zones).
    // _transactionZones holds a set of all zones which are currently running a transaction.
    // _transactionLock holds the lock.

    // first we try to determine if we are inside of a transaction currently
    var isInTransaction = false;
    Zone? zone = Zone.current;
    // for that we keep on iterating to the parent zone until there is either no zone anymore
    // or we have found a zone inside of _transactionZones.
    while (zone != null) {
      if (_transactionZones.contains(zone)) {
        isInTransaction = true;
        break;
      }
      zone = zone.parent;
    }
    // if we are inside a transaction....just run the action
    if (isInTransaction) {
      return await action();
    }
    // if we are *not* in a transaction, time to wait for the lock!
    while (_transactionLock != null) {
      await _transactionLock!.future;
    }
    // claim the lock
    final lock = Completer<void>();
    _transactionLock = lock;
    try {
      // run the action inside of a new zone
      return await runZoned(() async {
        try {
          // don't forget to add the new zone to _transactionZones!
          _transactionZones.add(Zone.current);
          late final T result;
          await _collection.transaction(() async {
            result = await action();
          });
          return result;
        } finally {
          // aaaand remove the zone from _transactionZones again
          _transactionZones.remove(Zone.current);
        }
      });
    } finally {
      // aaaand finally release the lock
      _transactionLock = null;
      lock.complete();
    }
  }

  @override
  Future<void> updateClient(
    String homeserverUrl,
    String token,
    String userId,
    String? deviceId,
    String? deviceName,
    String? prevBatch,
    String? olmAccount,
  ) async {
    await transaction(() async {
      await _clientBox.put('homeserver_url', homeserverUrl);
      await _clientBox.put('token', token);
      await _clientBox.put('user_id', userId);
      if (deviceId == null) {
        await _clientBox.delete('device_id');
      } else {
        await _clientBox.put('device_id', deviceId);
      }
      if (deviceName == null) {
        await _clientBox.delete('device_name');
      } else {
        await _clientBox.put('device_name', deviceName);
      }
      if (prevBatch == null) {
        await _clientBox.delete('prev_batch');
      } else {
        await _clientBox.put('prev_batch', prevBatch);
      }
      if (olmAccount == null) {
        await _clientBox.delete('olm_account');
      } else {
        await _clientBox.put('olm_account', olmAccount);
      }
    });
    return;
  }

  @override
  Future<void> updateClientKeys(
    String olmAccount,
  ) async {
    await _clientBox.put('olm_account', olmAccount);
    return;
  }

  @override
  Future<void> updateInboundGroupSessionAllowedAtIndex(
      String allowedAtIndex, String roomId, String sessionId) async {
    final raw = await _inboundGroupSessionsBox.get(sessionId);
    if (raw == null) {
      Logs().w(
          'Tried to update inbound group session as uploaded which wasnt found in the database!');
      return;
    }
    raw['allowed_at_index'] = allowedAtIndex;
    await _inboundGroupSessionsBox.put(sessionId, raw);
    return;
  }

  @override
  Future<void> updateInboundGroupSessionIndexes(
      String indexes, String roomId, String sessionId) async {
    final raw = await _inboundGroupSessionsBox.get(sessionId);
    if (raw == null) {
      Logs().w(
          'Tried to update inbound group session indexes of a session which was not found in the database!');
      return;
    }
    final json = copyMap(raw);
    json['indexes'] = indexes;
    await _inboundGroupSessionsBox.put(sessionId, json);
    return;
  }

  @override
  Future<void> updateRoomSortOrder(
      double oldestSortOrder, double newestSortOrder, String roomId) async {
    final raw = await _roomsBox.get(roomId);
    if (raw == null) throw ('Room not found');
    raw['oldest_sort_order'] = oldestSortOrder;
    raw['newest_sort_order'] = newestSortOrder;
    await _roomsBox.put(roomId, raw);
    return;
  }

  @override
  Future<List<StoredInboundGroupSession>> getAllInboundGroupSessions() async {
    final rawSessions = await _inboundGroupSessionsBox.getAllValues();
    return rawSessions.values
        .map((raw) => StoredInboundGroupSession.fromJson(copyMap(raw)))
        .toList();
  }

  @override
  Future<void> addSeenDeviceId(
    String userId,
    String deviceId,
    String publicKeysHash,
  ) =>
      _seenDeviceIdsBox.put(
          TupleKey(userId, deviceId).toString(), publicKeysHash);

  @override
  Future<void> addSeenPublicKey(
    String publicKey,
    String deviceId,
  ) =>
      _seenDeviceKeysBox.put(publicKey, deviceId);

  @override
  Future<String?> deviceIdSeen(userId, deviceId) async {
    final raw =
        await _seenDeviceIdsBox.get(TupleKey(userId, deviceId).toString());
    if (raw == null) return null;
    return raw;
  }

  @override
  Future<String?> publicKeySeen(String publicKey) async {
    final raw = await _seenDeviceKeysBox.get(publicKey);
    if (raw == null) return null;
    return raw;
  }
}

class TupleKey {
  final List<String> parts;

  TupleKey(String key1, [String? key2, String? key3])
      : parts = [
          key1,
          if (key2 != null) key2,
          if (key3 != null) key3,
        ];

  const TupleKey.byParts(this.parts);

  TupleKey.fromString(String multiKeyString)
      : parts = multiKeyString.split('|').toList();

  @override
  String toString() => parts.join('|');

  @override
  bool operator ==(other) => parts.toString() == other.toString();
}

dynamic _castValue(dynamic value) {
  if (value is Map) {
    return copyMap(value);
  }
  if (value is List) {
    return value.map(_castValue).toList();
  }
  return value;
}

/// The store always gives back an `_InternalLinkedHasMap<dynamic, dynamic>`. This
/// creates a deep copy of the json and makes sure that the format is always
/// `Map<String, dynamic>`.
Map<String, dynamic> copyMap(Map map) {
  final copy = Map<String, dynamic>.from(map);
  for (final entry in copy.entries) {
    copy[entry.key] = _castValue(entry.value);
  }
  return copy;
}
