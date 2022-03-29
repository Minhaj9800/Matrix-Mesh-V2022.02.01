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

import '../../utils/logs.dart';

import '../../utils/filter_map_extension.dart';
import '../../utils/try_get_map_extension.dart';
import '../basic_event.dart';

extension RoomEncryptedContentBasicEventExtension on BasicEvent {
  RoomEncryptedContent get parsedRoomEncryptedContent =>
      RoomEncryptedContent.fromJson(content);
}

class RoomEncryptedContent {
  String algorithm;
  String senderKey;
  String? deviceId;
  String? sessionId;
  String? ciphertextMegolm;
  Map<String, CiphertextInfo>? ciphertextOlm;

  RoomEncryptedContent.fromJson(Map<String, dynamic> json)
      : algorithm = json.tryGet('algorithm', TryGet.required) ?? '',
        senderKey = json.tryGet('sender_key', TryGet.required) ?? '',
        deviceId = json.tryGet('device_id'),
        sessionId = json.tryGet('session_id'),
        ciphertextMegolm = json.tryGet('ciphertext', TryGet.silent),
        // filter out invalid/incomplete CiphertextInfos
        ciphertextOlm = json
            .tryGet<Map<String, dynamic>>('ciphertext', TryGet.silent)
            ?.catchMap((k, v) => MapEntry(k, CiphertextInfo.fromJson(v)));

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['algorithm'] = algorithm;
    data['sender_key'] = senderKey;
    if (deviceId != null) {
      data['device_id'] = deviceId;
    }
    if (sessionId != null) {
      data['session_id'] = sessionId;
    }
    if (ciphertextMegolm != null) {
      data['ciphertext'] = ciphertextMegolm;
    }
    if (ciphertextOlm != null) {
      data['ciphertext'] =
          ciphertextOlm!.map((k, v) => MapEntry(k, v.toJson()));
      if (ciphertextMegolm != null) {
        Logs().wtf(
            'ciphertextOlm and ciphertextMegolm are both set, which should never happen!');
      }
    }
    return data;
  }
}

class CiphertextInfo {
  String body;
  int type;

  CiphertextInfo.fromJson(Map<String, dynamic> json)
      : body = json['body'],
        type = json['type'];

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['body'] = body;
    data['type'] = type;
    return data;
  }
}
