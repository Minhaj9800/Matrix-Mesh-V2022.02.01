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

import '../../utils/try_get_map_extension.dart';
import '../basic_event.dart';

extension RoomEncryptionContentBasicEventExtension on BasicEvent {
  RoomEncryptionContent get parsedRoomEncryptionContent =>
      RoomEncryptionContent.fromJson(content);
}

class RoomEncryptionContent {
  String algorithm;
  int? rotationPeriodMs;
  int? rotationPeriodMsgs;

  RoomEncryptionContent.fromJson(Map<String, dynamic> json)
      : algorithm = json.tryGet('algorithm', TryGet.required) ?? '',
        rotationPeriodMs = json.tryGet('rotation_period_ms'),
        rotationPeriodMsgs = json.tryGet('rotation_period_msgs');

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['algorithm'] = algorithm;
    if (rotationPeriodMs != null) {
      data['rotation_period_ms'] = rotationPeriodMs;
    }
    if (rotationPeriodMsgs != null) {
      data['rotation_period_msgs'] = rotationPeriodMsgs;
    }
    return data;
  }
}
