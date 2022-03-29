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

import 'basic_event.dart';

class BasicRoomEvent extends BasicEvent {
  String? roomId;

  BasicRoomEvent({
    this.roomId,
    required Map<String, dynamic> content,
    required String type,
  }) : super(
          content: content,
          type: type,
        );

  BasicRoomEvent.fromJson(Map<String, dynamic> json)
      : roomId = json['room_id'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    final data = super.toJson();
    if (roomId != null) data['room_id'] = roomId;
    return data;
  }
}
