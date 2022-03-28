/* MIT License
* 
* Copyright (C) 2019, 2020, 2021 Famedly GmbH
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import '../utils/map_copy_extension.dart';
import 'stripped_state_event.dart';

class MatrixEvent extends StrippedStateEvent {
  String eventId;
  String? roomId;
  DateTime originServerTs;
  Map<String, dynamic>? unsigned;
  Map<String, dynamic>? prevContent;
  String? redacts;

  MatrixEvent({
    required String type,
    required Map<String, dynamic> content,
    required String senderId,
    String? stateKey,
    required this.eventId,
    this.roomId,
    required this.originServerTs,
    this.unsigned,
    this.prevContent,
    this.redacts,
  }) : super(
            type: type,
            content: content,
            senderId: senderId,
            stateKey: stateKey);

  MatrixEvent.fromJson(Map<String, dynamic> json)
      : eventId = json['event_id'],
        roomId = json['room_id'],
        originServerTs =
            DateTime.fromMillisecondsSinceEpoch(json['origin_server_ts']),
        unsigned = (json['unsigned'] as Map<String, dynamic>?)?.copy(),
        prevContent = (json['prev_content'] as Map<String, dynamic>?)?.copy(),
        redacts = json['redacts'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    final data = super.toJson();
    data['event_id'] = eventId;
    data['origin_server_ts'] = originServerTs.millisecondsSinceEpoch;
    if (unsigned != null) {
      data['unsigned'] = unsigned;
    }
    if (prevContent != null) {
      data['prev_content'] = prevContent;
    }
    if (roomId != null) {
      data['room_id'] = roomId;
    }
    if (data['state_key'] == null) {
      data.remove('state_key');
    }
    if (redacts != null) {
      data['redacts'] = redacts;
    }
    return data;
  }
}
