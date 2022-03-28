/*
 *   Famedly Matrix SDK
 *   Copyright (C) 2019, 2020 Famedly GmbH
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

import 'package:matrix/matrix.dart';

import 'package:test/test.dart';
import 'package:olm/olm.dart' as olm;
import 'fake_client.dart';

void main() {
  group('Timeline', () {
    Logs().level = Level.error;
    final roomID = '!1234:example.com';
    final testTimeStamp = DateTime.now().millisecondsSinceEpoch;
    var updateCount = 0;
    final insertList = <int>[];
    final changeList = <int>[];
    final removeList = <int>[];
    final historyRequestList = <int>[];
    var olmEnabled = true;

    late Client client;
    late Room room;
    late Timeline timeline;
    test('create stuff', () async {
      try {
        await olm.init();
        olm.get_library_version();
      } catch (e) {
        olmEnabled = false;
        Logs().w('[LibOlm] Failed to load LibOlm', e);
      }
      Logs().i('[LibOlm] Enabled: $olmEnabled');
      client = await getClient();
      client.sendMessageTimeoutSeconds = 5;

      room = Room(
          id: roomID, client: client, prev_batch: '1234', roomAccountData: {});
      timeline = Timeline(
        room: room,
        events: [],
        onUpdate: () {
          updateCount++;
        },
        onInsert: insertList.add,
        onChange: changeList.add,
        onRemove: removeList.add,
        onHistoryReceived: historyRequestList.add,
      );
    });

    test('Create', () async {
      await client.checkHomeserver('https://fakeserver.notexisting',
          checkWellKnown: false);

      client.onEvent.add(EventUpdate(
        type: EventUpdateType.timeline,
        roomID: roomID,
        content: {
          'type': 'm.room.message',
          'content': {'msgtype': 'm.text', 'body': 'Testcase'},
          'sender': '@alice:example.com',
          'status': EventStatus.synced.intValue,
          'event_id': '2',
          'origin_server_ts': testTimeStamp - 1000
        },
      ));
      client.onEvent.add(EventUpdate(
        type: EventUpdateType.timeline,
        roomID: roomID,
        content: {
          'type': 'm.room.message',
          'content': {'msgtype': 'm.text', 'body': 'Testcase'},
          'sender': '@alice:example.com',
          'status': EventStatus.synced.intValue,
          'event_id': '1',
          'origin_server_ts': testTimeStamp
        },
      ));

      expect(timeline.sub != null, true);

      await Future.delayed(Duration(milliseconds: 50));

      expect(updateCount, 2);
      expect(insertList, [0, 0]);
      expect(insertList.length, timeline.events.length);
      expect(changeList, []);
      expect(removeList, []);
      expect(timeline.events.length, 2);
      expect(timeline.events[0].eventId, '1');
      expect(timeline.events[0].sender.id, '@alice:example.com');
      expect(timeline.events[0].originServerTs.millisecondsSinceEpoch,
          testTimeStamp);
      expect(timeline.events[0].body, 'Testcase');
      expect(
          timeline.events[0].originServerTs.millisecondsSinceEpoch >
              timeline.events[1].originServerTs.millisecondsSinceEpoch,
          true);
      expect(timeline.events[0].receipts, []);

      room.roomAccountData['m.receipt'] = BasicRoomEvent.fromJson({
        'type': 'm.receipt',
        'content': {
          '@alice:example.com': {
            'event_id': '1',
            'ts': 1436451550453,
          }
        },
        'room_id': roomID,
      });

      await Future.delayed(Duration(milliseconds: 50));

      expect(timeline.events[0].receipts.length, 1);
      expect(timeline.events[0].receipts[0].user.id, '@alice:example.com');

      client.onEvent.add(EventUpdate(
        type: EventUpdateType.timeline,
        roomID: roomID,
        content: {
          'type': 'm.room.redaction',
          'content': {'reason': 'spamming'},
          'sender': '@alice:example.com',
          'redacts': '2',
          'event_id': '3',
          'origin_server_ts': testTimeStamp + 1000
        },
      ));

      await Future.delayed(Duration(milliseconds: 50));

      expect(updateCount, 3);
      expect(insertList, [0, 0, 0]);
      expect(insertList.length, timeline.events.length);
      expect(changeList, [1]);
      expect(removeList, []);
      expect(timeline.events.length, 3);
      expect(timeline.events[2].redacted, true);
    });

    test('Send message', () async {
      await room.sendTextEvent('test', txid: '1234');

      await Future.delayed(Duration(milliseconds: 50));

      expect(updateCount, 5);
      expect(insertList, [0, 0, 0, 0]);
      expect(insertList.length, timeline.events.length);
      final eventId = timeline.events[0].eventId;
      expect(eventId.startsWith('\$event'), true);
      expect(timeline.events[0].status, EventStatus.sent);

      client.onEvent.add(EventUpdate(
        type: EventUpdateType.timeline,
        roomID: roomID,
        content: {
          'type': 'm.room.message',
          'content': {'msgtype': 'm.text', 'body': 'test'},
          'sender': '@alice:example.com',
          'status': EventStatus.synced.intValue,
          'event_id': eventId,
          'unsigned': {'transaction_id': '1234'},
          'origin_server_ts': DateTime.now().millisecondsSinceEpoch
        },
      ));

      await Future.delayed(Duration(milliseconds: 50));

      expect(updateCount, 6);
      expect(insertList, [0, 0, 0, 0]);
      expect(insertList.length, timeline.events.length);
      expect(timeline.events[0].eventId, eventId);
      expect(timeline.events[0].status, EventStatus.synced);
    });

    test('Send message with error', () async {
      client.onEvent.add(EventUpdate(
        type: EventUpdateType.timeline,
        roomID: roomID,
        content: {
          'type': 'm.room.message',
          'content': {'msgtype': 'm.text', 'body': 'Testcase'},
          'sender': '@alice:example.com',
          'status': EventStatus.sending.intValue,
          'event_id': 'abc',
          'origin_server_ts': testTimeStamp
        },
      ));
      await Future.delayed(Duration(milliseconds: 50));

      expect(updateCount, 7);
      await room.sendTextEvent('test', txid: 'errortxid');
      await Future.delayed(Duration(milliseconds: 50));

      expect(updateCount, 9);
      await room.sendTextEvent('test', txid: 'errortxid2');
      await Future.delayed(Duration(milliseconds: 50));
      await room.sendTextEvent('test', txid: 'errortxid3');
      await Future.delayed(Duration(milliseconds: 50));

      expect(updateCount, 13);
      expect(insertList, [0, 0, 0, 0, 0, 0, 1, 2]);
      expect(insertList.length, timeline.events.length);
      expect(changeList, [1, 0, 0, 0, 1, 2]);
      expect(removeList, []);
      expect(timeline.events[0].status, EventStatus.error);
      expect(timeline.events[1].status, EventStatus.error);
      expect(timeline.events[2].status, EventStatus.error);
    });

    test('Remove message', () async {
      await timeline.events[0].remove();

      await Future.delayed(Duration(milliseconds: 50));

      expect(updateCount, 14);

      expect(insertList, [0, 0, 0, 0, 0, 0, 1, 2]);
      expect(changeList, [1, 0, 0, 0, 1, 2]);
      expect(removeList, [0]);
      expect(timeline.events.length, 7);
      expect(timeline.events[0].status, EventStatus.error);
    });

    test('getEventById', () async {
      var event = await timeline.getEventById('abc');
      expect(event?.content, {'msgtype': 'm.text', 'body': 'Testcase'});

      event = await timeline.getEventById('not_found');
      expect(event, null);

      event = await timeline.getEventById('unencrypted_event');
      expect(event?.body, 'This is an example text message');

      if (olmEnabled) {
        event = await timeline.getEventById('encrypted_event');
        // the event is invalid but should have traces of attempting to decrypt
        expect(event?.messageType, MessageTypes.BadEncrypted);
      }
    });

    test('Resend message', () async {
      timeline.events.clear();
      client.onEvent.add(EventUpdate(
        type: EventUpdateType.timeline,
        roomID: roomID,
        content: {
          'type': 'm.room.message',
          'content': {'msgtype': 'm.text', 'body': 'Testcase'},
          'sender': '@alice:example.com',
          'status': EventStatus.error.intValue,
          'event_id': 'new-test-event',
          'origin_server_ts': testTimeStamp,
          'unsigned': {'transaction_id': 'newresend'},
        },
      ));
      await Future.delayed(Duration(milliseconds: 50));
      expect(timeline.events[0].status, EventStatus.error);
      await timeline.events[0].sendAgain();

      await Future.delayed(Duration(milliseconds: 50));

      expect(updateCount, 17);

      expect(insertList, [0, 0, 0, 0, 0, 0, 1, 2, 0]);
      expect(changeList, [1, 0, 0, 0, 1, 2, 0, 0]);
      expect(removeList, [0]);
      expect(timeline.events.length, 1);
      expect(timeline.events[0].status, EventStatus.sent);
    });

    test('Request history', () async {
      timeline.events.clear();
      expect(timeline.canRequestHistory, true);
      await room.requestHistory();

      await Future.delayed(Duration(milliseconds: 50));

      expect(updateCount, 20);
      expect(insertList, [0, 0, 0, 0, 0, 0, 1, 2, 0]);
      expect(historyRequestList, []);
      expect(timeline.events.length, 3);
      expect(timeline.events[0].eventId, '3143273582443PhrSn:example.org');
      expect(timeline.events[1].eventId, '2143273582443PhrSn:example.org');
      expect(timeline.events[2].eventId, '1143273582443PhrSn:example.org');
      expect(room.prev_batch, 't47409-4357353_219380_26003_2265');
      await timeline.events[2].redactEvent(reason: 'test', txid: '1234');
    });

    test('Clear cache on limited timeline', () async {
      client.onSync.add(
        SyncUpdate(
          nextBatch: '1234',
          rooms: RoomsUpdate(
            join: {
              roomID: JoinedRoomUpdate(
                timeline: TimelineUpdate(
                  limited: true,
                  prevBatch: 'blah',
                ),
                unreadNotifications: UnreadNotificationCounts(
                  highlightCount: 0,
                  notificationCount: 0,
                ),
              ),
            },
          ),
        ),
      );
      await Future.delayed(Duration(milliseconds: 50));
      expect(timeline.events.isEmpty, true);
    });

    test('sort errors on top', () async {
      timeline.events.clear();
      client.onEvent.add(EventUpdate(
        type: EventUpdateType.timeline,
        roomID: roomID,
        content: {
          'type': 'm.room.message',
          'content': {'msgtype': 'm.text', 'body': 'Testcase'},
          'sender': '@alice:example.com',
          'status': EventStatus.error.intValue,
          'event_id': 'abc',
          'origin_server_ts': testTimeStamp
        },
      ));
      client.onEvent.add(EventUpdate(
        type: EventUpdateType.timeline,
        roomID: roomID,
        content: {
          'type': 'm.room.message',
          'content': {'msgtype': 'm.text', 'body': 'Testcase'},
          'sender': '@alice:example.com',
          'status': EventStatus.synced.intValue,
          'event_id': 'def',
          'origin_server_ts': testTimeStamp + 5
        },
      ));
      await Future.delayed(Duration(milliseconds: 50));
      expect(timeline.events[0].status, EventStatus.error);
      expect(timeline.events[1].status, EventStatus.synced);
    });

    test('sending event to failed update', () async {
      timeline.events.clear();
      client.onEvent.add(EventUpdate(
        type: EventUpdateType.timeline,
        roomID: roomID,
        content: {
          'type': 'm.room.message',
          'content': {'msgtype': 'm.text', 'body': 'Testcase'},
          'sender': '@alice:example.com',
          'status': EventStatus.sending.intValue,
          'event_id': 'will-fail',
          'origin_server_ts': DateTime.now().millisecondsSinceEpoch,
        },
      ));
      await Future.delayed(Duration(milliseconds: 50));
      expect(timeline.events[0].status, EventStatus.sending);
      expect(timeline.events.length, 1);
      client.onEvent.add(EventUpdate(
        type: EventUpdateType.timeline,
        roomID: roomID,
        content: {
          'type': 'm.room.message',
          'content': {'msgtype': 'm.text', 'body': 'Testcase'},
          'sender': '@alice:example.com',
          'status': EventStatus.error.intValue,
          'event_id': 'will-fail',
          'origin_server_ts': testTimeStamp
        },
      ));
      await Future.delayed(Duration(milliseconds: 50));
      expect(timeline.events[0].status, EventStatus.error);
      expect(timeline.events.length, 1);
    });
    test('setReadMarker', () async {
      client.onEvent.add(EventUpdate(
        type: EventUpdateType.timeline,
        roomID: roomID,
        content: {
          'type': 'm.room.message',
          'content': {'msgtype': 'm.text', 'body': 'Testcase'},
          'sender': '@alice:example.com',
          'status': EventStatus.synced.intValue,
          'event_id': 'will-work',
          'origin_server_ts': DateTime.now().millisecondsSinceEpoch,
        },
      ));
      await Future.delayed(Duration(milliseconds: 50));
      room.notificationCount = 1;
      await timeline.setReadMarker();
      expect(room.notificationCount, 0);
    });
    test('sending an event and the http request finishes first, 0 -> 1 -> 2',
        () async {
      timeline.events.clear();
      client.onEvent.add(EventUpdate(
        type: EventUpdateType.timeline,
        roomID: roomID,
        content: {
          'type': 'm.room.message',
          'content': {'msgtype': 'm.text', 'body': 'Testcase'},
          'sender': '@alice:example.com',
          'status': EventStatus.sending.intValue,
          'event_id': 'transaction',
          'origin_server_ts': DateTime.now().millisecondsSinceEpoch,
        },
      ));
      await Future.delayed(Duration(milliseconds: 50));
      expect(timeline.events[0].status, EventStatus.sending);
      expect(timeline.events.length, 1);
      client.onEvent.add(EventUpdate(
        type: EventUpdateType.timeline,
        roomID: roomID,
        content: {
          'type': 'm.room.message',
          'content': {'msgtype': 'm.text', 'body': 'Testcase'},
          'sender': '@alice:example.com',
          'status': EventStatus.sent.intValue,
          'event_id': '\$event',
          'origin_server_ts': testTimeStamp,
          'unsigned': {'transaction_id': 'transaction'}
        },
      ));
      await Future.delayed(Duration(milliseconds: 50));
      expect(timeline.events[0].status, EventStatus.sent);
      expect(timeline.events.length, 1);
      client.onEvent.add(EventUpdate(
        type: EventUpdateType.timeline,
        roomID: roomID,
        content: {
          'type': 'm.room.message',
          'content': {'msgtype': 'm.text', 'body': 'Testcase'},
          'sender': '@alice:example.com',
          'status': EventStatus.synced.intValue,
          'event_id': '\$event',
          'origin_server_ts': testTimeStamp,
          'unsigned': {'transaction_id': 'transaction'}
        },
      ));
      await Future.delayed(Duration(milliseconds: 50));
      expect(timeline.events[0].status, EventStatus.synced);
      expect(timeline.events.length, 1);
    });
    test('sending an event where the sync reply arrives first, 0 -> 2 -> 1',
        () async {
      timeline.events.clear();
      client.onEvent.add(EventUpdate(
        type: EventUpdateType.timeline,
        roomID: roomID,
        content: {
          'type': 'm.room.message',
          'content': {'msgtype': 'm.text', 'body': 'Testcase'},
          'sender': '@alice:example.com',
          'event_id': 'transaction',
          'origin_server_ts': DateTime.now().millisecondsSinceEpoch,
          'unsigned': {
            messageSendingStatusKey: EventStatus.sending.intValue,
            'transaction_id': 'transaction',
          },
        },
      ));
      await Future.delayed(Duration(milliseconds: 50));
      expect(timeline.events[0].status, EventStatus.sending);
      expect(timeline.events.length, 1);
      client.onEvent.add(EventUpdate(
        type: EventUpdateType.timeline,
        roomID: roomID,
        content: {
          'type': 'm.room.message',
          'content': {'msgtype': 'm.text', 'body': 'Testcase'},
          'sender': '@alice:example.com',
          'event_id': '\$event',
          'origin_server_ts': testTimeStamp,
          'unsigned': {
            'transaction_id': 'transaction',
            messageSendingStatusKey: EventStatus.synced.intValue,
          },
        },
      ));
      await Future.delayed(Duration(milliseconds: 50));
      expect(timeline.events[0].status, EventStatus.synced);
      expect(timeline.events.length, 1);
      client.onEvent.add(EventUpdate(
        type: EventUpdateType.timeline,
        roomID: roomID,
        content: {
          'type': 'm.room.message',
          'content': {'msgtype': 'm.text', 'body': 'Testcase'},
          'sender': '@alice:example.com',
          'event_id': '\$event',
          'origin_server_ts': testTimeStamp,
          'unsigned': {
            'transaction_id': 'transaction',
            messageSendingStatusKey: EventStatus.sent.intValue,
          },
        },
      ));
      await Future.delayed(Duration(milliseconds: 50));
      expect(timeline.events[0].status, EventStatus.synced);
      expect(timeline.events.length, 1);
    });
    test('sending an event 0 -> -1 -> 2', () async {
      timeline.events.clear();
      client.onEvent.add(EventUpdate(
        type: EventUpdateType.timeline,
        roomID: roomID,
        content: {
          'type': 'm.room.message',
          'content': {'msgtype': 'm.text', 'body': 'Testcase'},
          'sender': '@alice:example.com',
          'status': EventStatus.sending.intValue,
          'event_id': 'transaction',
          'origin_server_ts': DateTime.now().millisecondsSinceEpoch,
        },
      ));
      await Future.delayed(Duration(milliseconds: 50));
      expect(timeline.events[0].status, EventStatus.sending);
      expect(timeline.events.length, 1);
      client.onEvent.add(EventUpdate(
        type: EventUpdateType.timeline,
        roomID: roomID,
        content: {
          'type': 'm.room.message',
          'content': {'msgtype': 'm.text', 'body': 'Testcase'},
          'sender': '@alice:example.com',
          'status': EventStatus.error.intValue,
          'origin_server_ts': testTimeStamp,
          'unsigned': {'transaction_id': 'transaction'},
        },
      ));
      await Future.delayed(Duration(milliseconds: 50));
      expect(timeline.events[0].status, EventStatus.error);
      expect(timeline.events.length, 1);
      client.onEvent.add(EventUpdate(
        type: EventUpdateType.timeline,
        roomID: roomID,
        content: {
          'type': 'm.room.message',
          'content': {'msgtype': 'm.text', 'body': 'Testcase'},
          'sender': '@alice:example.com',
          'status': EventStatus.synced.intValue,
          'event_id': '\$event',
          'origin_server_ts': testTimeStamp,
          'unsigned': {'transaction_id': 'transaction'},
        },
      ));
      await Future.delayed(Duration(milliseconds: 50));
      expect(timeline.events[0].status, EventStatus.synced);
      expect(timeline.events.length, 1);
    });
    test('sending an event 0 -> 2 -> -1', () async {
      timeline.events.clear();
      client.onEvent.add(EventUpdate(
        type: EventUpdateType.timeline,
        roomID: roomID,
        content: {
          'type': 'm.room.message',
          'content': {'msgtype': 'm.text', 'body': 'Testcase'},
          'sender': '@alice:example.com',
          'status': EventStatus.sending.intValue,
          'event_id': 'transaction',
          'origin_server_ts': DateTime.now().millisecondsSinceEpoch,
        },
      ));
      await Future.delayed(Duration(milliseconds: 50));
      expect(timeline.events[0].status, EventStatus.sending);
      expect(timeline.events.length, 1);
      client.onEvent.add(EventUpdate(
        type: EventUpdateType.timeline,
        roomID: roomID,
        content: {
          'type': 'm.room.message',
          'content': {'msgtype': 'm.text', 'body': 'Testcase'},
          'sender': '@alice:example.com',
          'status': EventStatus.synced.intValue,
          'event_id': '\$event',
          'origin_server_ts': testTimeStamp,
          'unsigned': {'transaction_id': 'transaction'},
        },
      ));
      await Future.delayed(Duration(milliseconds: 50));
      expect(timeline.events[0].status, EventStatus.synced);
      expect(timeline.events.length, 1);
      client.onEvent.add(EventUpdate(
        type: EventUpdateType.timeline,
        roomID: roomID,
        content: {
          'type': 'm.room.message',
          'content': {'msgtype': 'm.text', 'body': 'Testcase'},
          'sender': '@alice:example.com',
          'status': EventStatus.error.intValue,
          'origin_server_ts': testTimeStamp,
          'unsigned': {'transaction_id': 'transaction'},
        },
      ));
      await Future.delayed(Duration(milliseconds: 50));
      expect(timeline.events[0].status, EventStatus.synced);
      expect(timeline.events.length, 1);
    });
    test('logout', () async {
      await client.logout();
    });
  });
}
