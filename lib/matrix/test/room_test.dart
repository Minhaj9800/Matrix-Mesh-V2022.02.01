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

import 'dart:convert';
import 'dart:typed_data';

import '../lib/matrix.dart';

import 'package:test/test.dart';

import 'fake_client.dart';
import 'fake_matrix_api.dart';

void main() {
  late Client matrix;
  late Room room;

  /// All Tests related to the Event
  group('Room', () {
    Logs().level = Level.error;
    test('Login', () async {
      matrix = await getClient();
    });

    test('Create from json', () async {
      final id = '!localpart:server.abc';
      final membership = Membership.join;
      final notificationCount = 2;
      final highlightCount = 1;
      final heroes = [
        '@alice:matrix.org',
        '@bob:example.com',
        '@charley:example.org'
      ];

      room = Room(
        client: matrix,
        id: id,
        membership: membership,
        highlightCount: highlightCount,
        notificationCount: notificationCount,
        prev_batch: '',
        newestSortOrder: 0.0,
        oldestSortOrder: 0.0,
        summary: RoomSummary.fromJson({
          'm.joined_member_count': 2,
          'm.invited_member_count': 2,
          'm.heroes': heroes,
        }),
        roomAccountData: {
          'com.test.foo': BasicRoomEvent(
            type: 'com.test.foo',
            content: {'foo': 'bar'},
          ),
        },
      );
      room.setState(Event(
        room: room,
        eventId: '143273582443PhrSn:example.org',
        originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
        senderId: '@example:example.org',
        type: 'm.room.join_rules',
        unsigned: {'age': 1234},
        content: {'join_rule': 'public'},
        stateKey: '',
      ));

      expect(room.id, id);
      expect(room.membership, membership);
      expect(room.notificationCount, notificationCount);
      expect(room.highlightCount, highlightCount);
      expect(room.summary.mJoinedMemberCount, notificationCount);
      expect(room.summary.mInvitedMemberCount, notificationCount);
      expect(room.summary.mHeroes, heroes);
      expect(room.displayname, 'Alice, Bob, Charley');
      expect(
          room.getState('m.room.join_rules')?.content['join_rule'], 'public');
      expect(room.roomAccountData['com.test.foo']?.content['foo'], 'bar');

      room.setState(
        Event(
            senderId: '@test:example.com',
            type: 'm.room.canonical_alias',
            room: room,
            eventId: '123',
            content: {'alias': '#testalias:example.com'},
            originServerTs: DateTime.now(),
            stateKey: ''),
      );
      expect(room.displayname, 'testalias');
      expect(room.canonicalAlias, '#testalias:example.com');

      room.setState(
        Event(
            senderId: '@test:example.com',
            type: 'm.room.name',
            room: room,
            eventId: '123',
            content: {'name': 'testname'},
            originServerTs: DateTime.now(),
            stateKey: ''),
      );
      expect(room.displayname, 'testname');

      expect(room.topic, '');
      room.setState(
        Event(
            senderId: '@test:example.com',
            type: 'm.room.topic',
            room: room,
            eventId: '123',
            content: {'topic': 'testtopic'},
            originServerTs: DateTime.now(),
            stateKey: ''),
      );
      expect(room.topic, 'testtopic');

      expect(room.avatar, null);
      room.setState(
        Event(
            senderId: '@test:example.com',
            type: 'm.room.avatar',
            room: room,
            eventId: '123',
            content: {'url': 'mxc://testurl'},
            originServerTs: DateTime.now(),
            stateKey: ''),
      );
      expect(room.avatar.toString(), 'mxc://testurl');

      expect(room.pinnedEventIds, <String>[]);
      room.setState(
        Event(
            senderId: '@test:example.com',
            type: 'm.room.pinned_events',
            room: room,
            eventId: '123',
            content: {
              'pinned': ['1234']
            },
            originServerTs: DateTime.now(),
            stateKey: ''),
      );
      expect(room.pinnedEventIds.first, '1234');
      room.setState(
        Event(
          senderId: '@test:example.com',
          type: 'm.room.message',
          room: room,
          eventId: '12345',
          originServerTs: DateTime.now(),
          content: {'msgtype': 'm.text', 'body': 'abc'},
          stateKey: '',
        ),
      );
      expect(room.lastEvent?.eventId, '12345');
      expect(room.lastEvent?.body, 'abc');
      expect(room.timeCreated, room.lastEvent?.originServerTs);
    });

    test('lastEvent is set properly', () {
      room.setState(
        Event(
          senderId: '@test:example.com',
          type: 'm.room.encrypted',
          room: room,
          eventId: '1',
          originServerTs: DateTime.now(),
          content: {'msgtype': 'm.text', 'body': 'cd'},
          stateKey: '',
        ),
      );
      expect(room.lastEvent?.body, 'cd');
      room.setState(
        Event(
          senderId: '@test:example.com',
          type: 'm.room.encrypted',
          room: room,
          eventId: '2',
          originServerTs: DateTime.now(),
          content: {'msgtype': 'm.text', 'body': 'cdc'},
          stateKey: '',
        ),
      );
      expect(room.lastEvent?.body, 'cdc');
      room.setState(
        Event(
          senderId: '@test:example.com',
          type: 'm.room.encrypted',
          room: room,
          eventId: '3',
          originServerTs: DateTime.now(),
          content: {
            'm.new_content': {'msgtype': 'm.text', 'body': 'test ok'},
            'm.relates_to': {'rel_type': 'm.replace', 'event_id': '1'},
            'msgtype': 'm.text',
            'body': '* test ok',
          },
          stateKey: '',
        ),
      );
      expect(room.lastEvent?.body, 'cdc'); // because we edited the "cd" message
      room.setState(
        Event(
          senderId: '@test:example.com',
          type: 'm.room.encrypted',
          room: room,
          eventId: '4',
          originServerTs: DateTime.now(),
          content: {
            'msgtype': 'm.text',
            'body': 'edited cdc',
            'm.new_content': {'msgtype': 'm.text', 'body': 'edited cdc'},
            'm.relates_to': {'rel_type': 'm.replace', 'event_id': '2'},
          },
          stateKey: '',
          status: EventStatus.sending,
        ),
      );
      expect(room.lastEvent?.body, 'edited cdc');
      expect(room.lastEvent?.status, EventStatus.sending);
      expect(room.lastEvent?.eventId, '4');

      // Status update on edits working?
      room.setState(
        Event(
          senderId: '@test:example.com',
          type: 'm.room.encrypted',
          room: room,
          eventId: '5',
          unsigned: {'transaction_id': '4'},
          originServerTs: DateTime.now(),
          content: {
            'msgtype': 'm.text',
            'body': 'edited cdc',
            'm.new_content': {'msgtype': 'm.text', 'body': 'edited cdc'},
            'm.relates_to': {'rel_type': 'm.replace', 'event_id': '2'},
          },
          stateKey: '',
          status: EventStatus.sent,
        ),
      );
      expect(room.lastEvent?.eventId, '5');
      expect(room.lastEvent?.body, 'edited cdc');
      expect(room.lastEvent?.status, EventStatus.sent);
    });
    test('lastEvent when reply parent edited', () async {
      room.setState(
        Event(
          senderId: '@test:example.com',
          type: 'm.room.encrypted',
          room: room,
          eventId: '5',
          originServerTs: DateTime.now(),
          content: {'msgtype': 'm.text', 'body': 'A'},
          stateKey: '',
        ),
      );
      expect(room.lastEvent?.body, 'A');

      room.setState(
        Event(
          senderId: '@test:example.com',
          type: 'm.room.encrypted',
          room: room,
          eventId: '6',
          originServerTs: DateTime.now(),
          content: {
            'msgtype': 'm.text',
            'body': 'B',
            'm.relates_to': {'rel_type': 'm.in_reply_to', 'event_id': '5'}
          },
          stateKey: '',
        ),
      );
      expect(room.lastEvent?.body, 'B');
      room.setState(
        Event(
          senderId: '@test:example.com',
          type: 'm.room.encrypted',
          room: room,
          eventId: '7',
          originServerTs: DateTime.now(),
          content: {
            'msgtype': 'm.text',
            'body': 'edited A',
            'm.new_content': {'msgtype': 'm.text', 'body': 'edited A'},
            'm.relates_to': {'rel_type': 'm.replace', 'event_id': '5'},
          },
          stateKey: '',
        ),
      );
      expect(room.lastEvent?.body, 'B');
    });
    test('sendReadMarker', () async {
      await room.setReadMarker('§1234:fakeServer.notExisting');
    });

    test('requestParticipants', () async {
      final participants = await room.requestParticipants();
      expect(participants.length, 1);
      final user = participants[0];
      expect(user.id, '@alice:example.org');
      expect(user.displayName, 'Alice Margatroid');
      expect(user.membership, Membership.join);
      expect(user.avatarUrl.toString(), 'mxc://example.org/SEsfnsuifSDFSSEF');
      expect(user.room.id, '!localpart:server.abc');
    });

    test('getEventByID', () async {
      final event = await room.getEventById('1234');
      expect(event?.eventId, '143273582443PhrSn:example.org');
    });

    test('setName', () async {
      final eventId = await room.setName('Testname');
      expect(eventId, '42');
    });

    test('setDescription', () async {
      final eventId = await room.setDescription('Testname');
      expect(eventId, '42');
    });

    test('kick', () async {
      await room.kick('Testname');
    });

    test('ban', () async {
      await room.ban('Testname');
    });

    test('unban', () async {
      await room.unban('Testname');
    });

    test('PowerLevels', () async {
      room.setState(
        Event(
            senderId: '@test:example.com',
            type: 'm.room.power_levels',
            room: room,
            eventId: '123',
            content: {
              'ban': 50,
              'events': {'m.room.name': 100, 'm.room.power_levels': 100},
              'events_default': 0,
              'invite': 50,
              'kick': 50,
              'notifications': {'room': 20},
              'redact': 50,
              'state_default': 50,
              'users': {'@test:fakeServer.notExisting': 100},
              'users_default': 10
            },
            originServerTs: DateTime.now(),
            stateKey: ''),
      );
      expect(room.ownPowerLevel, 100);
      expect(room.getPowerLevelByUserId(matrix.userID!), room.ownPowerLevel);
      expect(room.getPowerLevelByUserId('@nouser:example.com'), 10);
      expect(room.ownPowerLevel, 100);
      expect(room.canBan, true);
      expect(room.canInvite, true);
      expect(room.canKick, true);
      expect(room.canRedact, true);
      expect(room.canSendDefaultMessages, true);
      expect(room.canSendDefaultStates, true);
      expect(room.canChangePowerLevel, true);
      expect(room.canSendEvent('m.room.name'), true);
      expect(room.canSendEvent('m.room.power_levels'), true);
      expect(room.canSendEvent('m.room.member'), true);
      expect(room.powerLevels,
          room.getState('m.room.power_levels')?.content['users']);

      room.setState(
        Event(
          senderId: '@test:example.com',
          type: 'm.room.power_levels',
          room: room,
          eventId: '123abc',
          content: {
            'ban': 50,
            'events': {'m.room.name': 0, 'm.room.power_levels': 100},
            'events_default': 0,
            'invite': 50,
            'kick': 50,
            'notifications': {'room': 20},
            'redact': 50,
            'state_default': 50,
            'users': {},
            'users_default': 0
          },
          originServerTs: DateTime.now(),
          stateKey: '',
        ),
      );
      expect(room.ownPowerLevel, 0);
      expect(room.canBan, false);
      expect(room.canInvite, false);
      expect(room.canKick, false);
      expect(room.canRedact, false);
      expect(room.canSendDefaultMessages, true);
      expect(room.canSendDefaultStates, false);
      expect(room.canChangePowerLevel, false);
      expect(room.canSendEvent('m.room.name'), true);
      expect(room.canSendEvent('m.room.power_levels'), false);
      expect(room.canSendEvent('m.room.member'), false);
      expect(room.canSendEvent('m.room.message'), true);
      final resp = await room.setPower('@test:fakeServer.notExisting', 90);
      expect(resp, '42');
    });

    test('invite', () async {
      await room.invite('Testname');
    });

    test('getParticipants', () async {
      var userList = room.getParticipants();
      expect(userList.length, 4);
      // add new user
      room.setState(Event(
          senderId: '@alice:test.abc',
          type: 'm.room.member',
          room: room,
          eventId: '12345',
          originServerTs: DateTime.now(),
          content: {'displayname': 'alice'},
          stateKey: '@alice:test.abc'));
      userList = room.getParticipants();
      expect(userList.length, 5);
      expect(userList[4].displayName, 'alice');
    });

    test('addToDirectChat', () async {
      await room.addToDirectChat('Testname');
    });

    test('getTimeline', () async {
      final timeline = await room.getTimeline();
      expect(timeline.events.length, 0);
    });

    test('getUserByMXID', () async {
      User? user;
      try {
        user = await room.requestUser('@getme:example.com');
      } catch (_) {}
      expect(user?.stateKey, '@getme:example.com');
      expect(user?.calcDisplayname(), 'Getme');
    });

    test('setAvatar', () async {
      final testFile = MatrixFile(bytes: Uint8List(0), name: 'file.jpeg');
      final dynamic resp = await room.setAvatar(testFile);
      expect(resp, 'YUwRidLecu:example.com');
    });

    test('sendEvent', () async {
      final dynamic resp = await room.sendEvent(
          {'msgtype': 'm.text', 'body': 'hello world'},
          txid: 'testtxid');
      expect(resp?.startsWith('\$event'), true);
    });

    test('sendEvent', () async {
      FakeMatrixApi.calledEndpoints.clear();
      final dynamic resp =
          await room.sendTextEvent('Hello world', txid: 'testtxid');
      expect(resp?.startsWith('\$event'), true);
      final entry = FakeMatrixApi.calledEndpoints.entries
          .firstWhere((p) => p.key.contains('/send/m.room.message/'));
      final content = json.decode(entry.value.first);
      expect(content, {
        'body': 'Hello world',
        'msgtype': 'm.text',
      });
    });

    test('send edit', () async {
      FakeMatrixApi.calledEndpoints.clear();
      final dynamic resp = await room.sendTextEvent('Hello world',
          txid: 'testtxid', editEventId: '\$otherEvent');
      expect(resp?.startsWith('\$event'), true);
      final entry = FakeMatrixApi.calledEndpoints.entries
          .firstWhere((p) => p.key.contains('/send/m.room.message/'));
      final content = json.decode(entry.value.first);
      expect(content, {
        'body': '* Hello world',
        'msgtype': 'm.text',
        'm.new_content': {
          'body': 'Hello world',
          'msgtype': 'm.text',
        },
        'm.relates_to': {
          'event_id': '\$otherEvent',
          'rel_type': 'm.replace',
        },
      });
    });

    test('send reply', () async {
      var event = Event.fromJson({
        'event_id': '\$replyEvent',
        'content': {
          'body': 'Blah',
          'msgtype': 'm.text',
        },
        'type': 'm.room.message',
        'sender': '@alice:example.org',
      }, room);
      FakeMatrixApi.calledEndpoints.clear();
      var resp = await room.sendTextEvent('Hello world',
          txid: 'testtxid', inReplyTo: event);
      expect(resp?.startsWith('\$event'), true);
      var entry = FakeMatrixApi.calledEndpoints.entries
          .firstWhere((p) => p.key.contains('/send/m.room.message/'));
      var content = json.decode(entry.value.first);
      expect(content, {
        'body': '> <@alice:example.org> Blah\n\nHello world',
        'msgtype': 'm.text',
        'format': 'org.matrix.custom.html',
        'formatted_body':
            '<mx-reply><blockquote><a href="https://matrix.to/#/!localpart:server.abc/\$replyEvent">In reply to</a> <a href="https://matrix.to/#/@alice:example.org">@alice:example.org</a><br>Blah</blockquote></mx-reply>Hello world',
        'm.relates_to': {
          'm.in_reply_to': {
            'event_id': '\$replyEvent',
          },
        },
      });

      event = Event.fromJson({
        'event_id': '\$replyEvent',
        'content': {
          'body': '<b>Blah</b>\nbeep',
          'msgtype': 'm.text',
        },
        'type': 'm.room.message',
        'sender': '@alice:example.org',
      }, room);
      FakeMatrixApi.calledEndpoints.clear();
      resp = await room.sendTextEvent('Hello world\nfox',
          txid: 'testtxid', inReplyTo: event);
      expect(resp?.startsWith('\$event'), true);
      entry = FakeMatrixApi.calledEndpoints.entries
          .firstWhere((p) => p.key.contains('/send/m.room.message/'));
      content = json.decode(entry.value.first);
      expect(content, {
        'body':
            '> <@alice:example.org> <b>Blah</b>\n> beep\n\nHello world\nfox',
        'msgtype': 'm.text',
        'format': 'org.matrix.custom.html',
        'formatted_body':
            '<mx-reply><blockquote><a href="https://matrix.to/#/!localpart:server.abc/\$replyEvent">In reply to</a> <a href="https://matrix.to/#/@alice:example.org">@alice:example.org</a><br>&lt;b&gt;Blah&lt;&#47;b&gt;<br>beep</blockquote></mx-reply>Hello world<br>fox',
        'm.relates_to': {
          'm.in_reply_to': {
            'event_id': '\$replyEvent',
          },
        },
      });

      event = Event.fromJson({
        'event_id': '\$replyEvent',
        'content': {
          'format': 'org.matrix.custom.html',
          'formatted_body': '<mx-reply>heya</mx-reply>meow',
          'body': 'plaintext meow',
          'msgtype': 'm.text',
        },
        'type': 'm.room.message',
        'sender': '@alice:example.org',
      }, room);
      FakeMatrixApi.calledEndpoints.clear();
      resp = await room.sendTextEvent('Hello world',
          txid: 'testtxid', inReplyTo: event);
      expect(resp?.startsWith('\$event'), true);
      entry = FakeMatrixApi.calledEndpoints.entries
          .firstWhere((p) => p.key.contains('/send/m.room.message/'));
      content = json.decode(entry.value.first);
      expect(content, {
        'body': '> <@alice:example.org> plaintext meow\n\nHello world',
        'msgtype': 'm.text',
        'format': 'org.matrix.custom.html',
        'formatted_body':
            '<mx-reply><blockquote><a href="https://matrix.to/#/!localpart:server.abc/\$replyEvent">In reply to</a> <a href="https://matrix.to/#/@alice:example.org">@alice:example.org</a><br>meow</blockquote></mx-reply>Hello world',
        'm.relates_to': {
          'm.in_reply_to': {
            'event_id': '\$replyEvent',
          },
        },
      });

      event = Event.fromJson({
        'event_id': '\$replyEvent',
        'content': {
          'body': 'Hey @room',
          'msgtype': 'm.text',
        },
        'type': 'm.room.message',
        'sender': '@alice:example.org',
      }, room);
      FakeMatrixApi.calledEndpoints.clear();
      resp = await room.sendTextEvent('Hello world',
          txid: 'testtxid', inReplyTo: event);
      expect(resp?.startsWith('\$event'), true);
      entry = FakeMatrixApi.calledEndpoints.entries
          .firstWhere((p) => p.key.contains('/send/m.room.message/'));
      content = json.decode(entry.value.first);
      expect(content, {
        'body': '> <@alice:example.org> Hey @\u{200b}room\n\nHello world',
        'msgtype': 'm.text',
        'format': 'org.matrix.custom.html',
        'formatted_body':
            '<mx-reply><blockquote><a href="https://matrix.to/#/!localpart:server.abc/\$replyEvent">In reply to</a> <a href="https://matrix.to/#/@alice:example.org">@alice:example.org</a><br>Hey @room</blockquote></mx-reply>Hello world',
        'm.relates_to': {
          'm.in_reply_to': {
            'event_id': '\$replyEvent',
          },
        },
      });

      // Reply to a reply
      event = Event.fromJson({
        'event_id': '\$replyEvent',
        'content': {
          'body': '> <@alice:example.org> Hey\n\nHello world',
          'msgtype': 'm.text',
          'format': 'org.matrix.custom.html',
          'formatted_body':
              '<mx-reply><blockquote><a href="https://matrix.to/#/!localpart:server.abc/\$replyEvent">In reply to</a> <a href="https://matrix.to/#/@alice:example.org">@alice:example.org</a><br>Hey</blockquote></mx-reply>Hello world',
          'm.relates_to': {
            'm.in_reply_to': {
              'event_id': '\$replyEvent',
            },
          },
        },
        'type': 'm.room.message',
        'sender': '@alice:example.org',
      }, room);
      FakeMatrixApi.calledEndpoints.clear();
      resp =
          await room.sendTextEvent('Fox', txid: 'testtxid', inReplyTo: event);
      expect(resp?.startsWith('\$event'), true);
      entry = FakeMatrixApi.calledEndpoints.entries
          .firstWhere((p) => p.key.contains('/send/m.room.message/'));
      content = json.decode(entry.value.first);
      expect(content, {
        'body': '> <@alice:example.org> Hello world\n\nFox',
        'msgtype': 'm.text',
        'format': 'org.matrix.custom.html',
        'formatted_body':
            '<mx-reply><blockquote><a href="https://matrix.to/#/!localpart:server.abc/\$replyEvent">In reply to</a> <a href="https://matrix.to/#/@alice:example.org">@alice:example.org</a><br>Hello world</blockquote></mx-reply>Fox',
        'm.relates_to': {
          'm.in_reply_to': {
            'event_id': '\$replyEvent',
          },
        },
      });
    });

    test('send reaction', () async {
      FakeMatrixApi.calledEndpoints.clear();
      final dynamic resp =
          await room.sendReaction('\$otherEvent', '🦊', txid: 'testtxid');
      expect(resp?.startsWith('\$event'), true);
      final entry = FakeMatrixApi.calledEndpoints.entries
          .firstWhere((p) => p.key.contains('/send/m.reaction/'));
      final content = json.decode(entry.value.first);
      expect(content, {
        'm.relates_to': {
          'event_id': '\$otherEvent',
          'rel_type': 'm.annotation',
          'key': '🦊',
        },
      });
    });

    test('send location', () async {
      FakeMatrixApi.calledEndpoints.clear();

      final body = 'Middle of the ocean';
      final geoUri = 'geo:0.0,0.0';
      final dynamic resp =
          await room.sendLocation(body, geoUri, txid: 'testtxid');
      expect(resp?.startsWith('\$event'), true);

      final entry = FakeMatrixApi.calledEndpoints.entries
          .firstWhere((p) => p.key.contains('/send/m.room.message/'));
      final content = json.decode(entry.value.first);
      expect(content, {
        'msgtype': 'm.location',
        'body': body,
        'geo_uri': geoUri,
      });
    });

    // Not working because there is no real file to test it...
    /*test('sendImageEvent', () async {
      final File testFile = File.fromUri(Uri.parse("fake/path/file.jpeg"));
      final dynamic resp =
          await room.sendImageEvent(testFile, txid: "testtxid");
      expect(resp, "42");
    });*/

    test('sendFileEvent', () async {
      final testFile = MatrixFile(bytes: Uint8List(0), name: 'file.jpeg');
      final dynamic resp = await room.sendFileEvent(testFile, txid: 'testtxid');
      expect(resp.toString(), 'mxc://example.com/AQwafuaFswefuhsfAFAgsw');
    });

    test('pushRuleState', () async {
      expect(room.pushRuleState, PushRuleState.mentionsOnly);
      matrix.accountData['m.push_rules']?.content['global']['override'].add(
          matrix.accountData['m.push_rules']?.content['global']['room'][0]);
      expect(room.pushRuleState, PushRuleState.dontNotify);
    });

    test('Test call methods', () async {
      await room.inviteToCall('1234', 1234, '4567', '7890', 'sdp',
          txid: '1234');
      await room.answerCall('1234', 'sdp', '4567', txid: '1234');
      await room.sendCallCandidates('1234', '4567', [], txid: '1234');
      await room.selectCallAnswer('1234', 1234, '4567', '6789', txid: '1234');
      await room.sendCallReject('1234', 1234, '4567', txid: '1234');
      await room.sendCallNegotiate('1234', 1234, '4567', 'sdp', txid: '1234');
      await room.hangupCall('1234', '4567', 'user_hangup', txid: '1234');
      await room.sendAssertedIdentity(
          '1234',
          '4567',
          AssertedIdentity()
            ..displayName = 'name'
            ..id = 'some_id',
          txid: '1234');
      await room.sendCallReplaces('1234', '4567', CallReplaces(), txid: '1234');
      await room.sendSDPStreamMetadataChanged(
          '1234', '4567', SDPStreamMetadata({}),
          txid: '1234');
    });

    test('enableEncryption', () async {
      await room.enableEncryption();
    });

    test('Enable encryption', () async {
      room.setState(
        Event(
            senderId: '@alice:test.abc',
            type: 'm.room.encryption',
            room: room,
            eventId: '12345',
            originServerTs: DateTime.now(),
            content: {
              'algorithm': AlgorithmTypes.megolmV1AesSha2,
              'rotation_period_ms': 604800000,
              'rotation_period_msgs': 100
            },
            stateKey: ''),
      );
      expect(room.encrypted, true);
      expect(room.encryptionAlgorithm, AlgorithmTypes.megolmV1AesSha2);
    });

    test('setPushRuleState', () async {
      await room.setPushRuleState(PushRuleState.notify);
      await room.setPushRuleState(PushRuleState.dontNotify);
      await room.setPushRuleState(PushRuleState.mentionsOnly);
      await room.setPushRuleState(PushRuleState.notify);
    });

    test('Test tag methods', () async {
      await room.addTag(TagType.favourite, order: 0.1);
      await room.removeTag(TagType.favourite);
      expect(room.isFavourite, false);
      room.roomAccountData['m.tag'] = BasicRoomEvent.fromJson({
        'content': {
          'tags': {
            'm.favourite': {'order': 0.1},
            'm.wrong': {'order': 0.2},
          }
        },
        'type': 'm.tag'
      });
      expect(room.tags.length, 1);
      expect(room.tags[TagType.favourite]?.order, 0.1);
      expect(room.isFavourite, true);
      await room.setFavourite(false);
    });

    test('Test marked unread room', () async {
      await room.markUnread(true);
      await room.markUnread(false);
      expect(room.markedUnread, false);
      room.roomAccountData['com.famedly.marked_unread'] =
          BasicRoomEvent.fromJson({
        'content': {'unread': true},
        'type': 'com.famedly.marked_unread'
      });
      expect(room.markedUnread, true);
    });

    test('joinRules', () async {
      expect(room.canChangeJoinRules, false);
      expect(room.joinRules, JoinRules.public);
      room.setState(Event.fromJson(
        {
          'content': {'join_rule': 'invite'},
          'event_id': '\$143273582443PhrSn:example.org',
          'origin_server_ts': 1432735824653,
          'room_id': '!jEsUZKDJdhlrceRyVU:example.org',
          'sender': '@example:example.org',
          'state_key': '',
          'type': 'm.room.join_rules',
          'unsigned': {'age': 1234}
        },
        room,
      ));
      expect(room.joinRules, JoinRules.invite);
      await room.setJoinRules(JoinRules.invite);
    });

    test('guestAccess', () async {
      expect(room.canChangeGuestAccess, false);
      expect(room.guestAccess, GuestAccess.forbidden);
      room.setState(Event.fromJson(
        {
          'content': {'guest_access': 'can_join'},
          'event_id': '\$143273582443PhrSn:example.org',
          'origin_server_ts': 1432735824653,
          'room_id': '!jEsUZKDJdhlrceRyVU:example.org',
          'sender': '@example:example.org',
          'state_key': '',
          'type': 'm.room.guest_access',
          'unsigned': {'age': 1234}
        },
        room,
      ));
      expect(room.guestAccess, GuestAccess.canJoin);
      await room.setGuestAccess(GuestAccess.canJoin);
    });

    test('historyVisibility', () async {
      expect(room.canChangeHistoryVisibility, false);
      expect(room.historyVisibility, null);
      room.setState(Event.fromJson(
        {
          'content': {'history_visibility': 'shared'},
          'event_id': '\$143273582443PhrSn:example.org',
          'origin_server_ts': 1432735824653,
          'room_id': '!jEsUZKDJdhlrceRyVU:example.org',
          'sender': '@example:example.org',
          'state_key': '',
          'type': 'm.room.history_visibility',
          'unsigned': {'age': 1234}
        },
        room,
      ));
      expect(room.historyVisibility, HistoryVisibility.shared);
      await room.setHistoryVisibility(HistoryVisibility.joined);
    });

    test('setState', () async {
      // not set non-state-events
      room.setState(Event.fromJson(
        {
          'content': {'history_visibility': 'shared'},
          'event_id': '\$143273582443PhrSn:example.org',
          'origin_server_ts': 1432735824653,
          'room_id': '!jEsUZKDJdhlrceRyVU:example.org',
          'sender': '@example:example.org',
          'type': 'm.custom',
          'unsigned': {'age': 1234}
        },
        room,
      ));
      expect(room.getState('m.custom') != null, false);

      // set state events
      room.setState(Event.fromJson(
        {
          'content': {'history_visibility': 'shared'},
          'event_id': '\$143273582443PhrSn:example.org',
          'origin_server_ts': 1432735824653,
          'room_id': '!jEsUZKDJdhlrceRyVU:example.org',
          'sender': '@example:example.org',
          'state_key': '',
          'type': 'm.custom',
          'unsigned': {'age': 1234}
        },
        room,
      ));
      expect(room.getState('m.custom') != null, true);

      // sets messages as state events
      room.setState(Event.fromJson(
        {
          'content': {'history_visibility': 'shared'},
          'event_id': '\$143273582443PhrSn:example.org',
          'origin_server_ts': 1432735824653,
          'room_id': '!jEsUZKDJdhlrceRyVU:example.org',
          'sender': '@example:example.org',
          'type': 'm.room.message',
          'unsigned': {'age': 1234}
        },
        room,
      ));
      expect(room.getState('m.room.message') != null, true);
    });

    test('Widgets', () {
      expect(room.widgets.isEmpty, true);
    });

    test('Spaces', () async {
      expect(room.isSpace, false);
      room.states['m.room.create'] = {
        '': Event.fromJson(
          {
            'content': {'type': 'm.space'},
            'event_id': '\$143273582443PhrSn:example.org',
            'origin_server_ts': 1432735824653,
            'room_id': '!jEsUZKDJdhlrceRyVU:example.org',
            'sender': '@example:example.org',
            'type': 'm.room.create',
            'unsigned': {'age': 1234},
            'state_key': '',
          },
          room,
        ),
      };
      expect(room.isSpace, true);

      expect(room.spaceParents.isEmpty, true);
      room.states[EventTypes.spaceParent] = {
        '!1234:example.invalid': Event.fromJson(
          {
            'content': {
              'via': ['example.invalid']
            },
            'event_id': '\$143273582443PhrSn:example.org',
            'origin_server_ts': 1432735824653,
            'room_id': '!jEsUZKDJdhlrceRyVU:example.org',
            'sender': '@example:example.org',
            'type': EventTypes.spaceParent,
            'unsigned': {'age': 1234},
            'state_key': '!1234:example.invalid',
          },
          room,
        ),
      };
      expect(room.spaceParents.length, 1);

      expect(room.spaceChildren.isEmpty, true);
      room.states[EventTypes.spaceChild] = {
        '!b:example.invalid': Event.fromJson(
          {
            'content': {
              'via': ['example.invalid'],
              'order': 'b',
            },
            'event_id': '\$143273582443PhrSn:example.org',
            'origin_server_ts': 1432735824653,
            'room_id': '!jEsUZKDJdhlrceRyVU:example.org',
            'sender': '@example:example.org',
            'type': EventTypes.spaceChild,
            'unsigned': {'age': 1234},
            'state_key': '!b:example.invalid',
          },
          room,
        ),
        '!c:example.invalid': Event.fromJson(
          {
            'content': {
              'via': ['example.invalid'],
              'order': 'c',
            },
            'event_id': '\$143273582443PhrSn:example.org',
            'origin_server_ts': 1432735824653,
            'room_id': '!jEsUZKDJdhlrceRyVU:example.org',
            'sender': '@example:example.org',
            'type': EventTypes.spaceChild,
            'unsigned': {'age': 1234},
            'state_key': '!c:example.invalid',
          },
          room,
        ),
        '!noorder:example.invalid': Event.fromJson(
          {
            'content': {
              'via': ['example.invalid'],
            },
            'event_id': '\$143273582443PhrSn:example.org',
            'origin_server_ts': 1432735824653,
            'room_id': '!jEsUZKDJdhlrceRyVU:example.org',
            'sender': '@example:example.org',
            'type': EventTypes.spaceChild,
            'unsigned': {'age': 1234},
            'state_key': '!noorder:example.invalid',
          },
          room,
        ),
        '!a:example.invalid': Event.fromJson(
          {
            'content': {
              'via': ['example.invalid'],
              'order': 'a',
            },
            'event_id': '\$143273582443PhrSn:example.org',
            'origin_server_ts': 1432735824653,
            'room_id': '!jEsUZKDJdhlrceRyVU:example.org',
            'sender': '@example:example.org',
            'type': EventTypes.spaceChild,
            'unsigned': {'age': 1234},
            'state_key': '!a:example.invalid',
          },
          room,
        ),
      };
      expect(room.spaceChildren.length, 4);

      expect(room.spaceChildren[0].roomId, '!a:example.invalid');
      expect(room.spaceChildren[1].roomId, '!b:example.invalid');
      expect(room.spaceChildren[2].roomId, '!c:example.invalid');
      expect(room.spaceChildren[3].roomId, '!noorder:example.invalid');

      // TODO: Implement a more generic fake api
      /*await room.setSpaceChild(
        '!jEsUZKDJdhlrceRyVU:example.org',
        via: ['example.invalid'],
        order: '5',
        suggested: true,
      );
      await room.removeSpaceChild('!1234:example.invalid');*/
    });

    test('getMention', () async {
      expect(room.getMention('@invalid'), null);
      expect(room.getMention('@[Alice Margatroid]'), '@alice:example.org');
      expect(room.getMention('@[Alice Margatroid]#1754'), '@alice:example.org');
    });

    test('logout', () async {
      await matrix.logout();
    });
  });
}
