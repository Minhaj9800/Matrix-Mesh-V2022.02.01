import '../model/auth/authentication_data.dart';
import '../model/auth/authentication_types.dart';
import '../model/auth/authentication_identifier.dart';
import '../model/matrix_keys.dart';
import '../model/sync_update.dart';
import '../model/matrix_event.dart';

import 'internal.dart';

class _NameSource {
  final String source;
  const _NameSource(this.source);
}

@_NameSource('spec')
class HomeserverInformation {
  HomeserverInformation({
    required this.baseUrl,
  });

  HomeserverInformation.fromJson(Map<String, dynamic> json)
      : baseUrl = Uri.parse(json['base_url']);
  Map<String, dynamic> toJson() => {
        'base_url': baseUrl.toString(),
      };

  /// The base URL for the homeserver for client-server connections.
  Uri baseUrl;
}

@_NameSource('spec')
class IdentityServerInformation {
  IdentityServerInformation({
    required this.baseUrl,
  });

  IdentityServerInformation.fromJson(Map<String, dynamic> json)
      : baseUrl = Uri.parse(json['base_url']);
  Map<String, dynamic> toJson() => {
        'base_url': baseUrl.toString(),
      };

  /// The base URL for the identity server for client-server connections.
  Uri baseUrl;
}

/// Used by clients to determine the homeserver, identity server, and other
/// optional components they should be interacting with.
@_NameSource('spec')
class DiscoveryInformation {
  DiscoveryInformation({
    required this.mHomeserver,
    this.mIdentityServer,
    this.additionalProperties = const {},
  });

  DiscoveryInformation.fromJson(Map<String, dynamic> json)
      : mHomeserver = HomeserverInformation.fromJson(json['m.homeserver']),
        mIdentityServer = ((v) => v != null
            ? IdentityServerInformation.fromJson(v)
            : null)(json['m.identity_server']),
        additionalProperties = Map.fromEntries(json.entries
            .where(
                (e) => !['m.homeserver', 'm.identity_server'].contains(e.key))
            .map((e) => MapEntry(e.key, e.value as Map<String, dynamic>)));
  Map<String, dynamic> toJson() {
    final mIdentityServer = this.mIdentityServer;
    return {
      ...additionalProperties,
      'm.homeserver': mHomeserver.toJson(),
      if (mIdentityServer != null)
        'm.identity_server': mIdentityServer.toJson(),
    };
  }

  /// Used by clients to discover homeserver information.
  HomeserverInformation mHomeserver;

  /// Used by clients to discover identity server information.
  IdentityServerInformation? mIdentityServer;

  Map<String, Map<String, dynamic>> additionalProperties;
}

@_NameSource('rule override generated')
enum ThirdPartyIdentifierMedium { email, msisdn }

@_NameSource('spec')
class ThirdPartyIdentifier {
  ThirdPartyIdentifier({
    required this.addedAt,
    required this.address,
    required this.medium,
    required this.validatedAt,
  });

  ThirdPartyIdentifier.fromJson(Map<String, dynamic> json)
      : addedAt = json['added_at'] as int,
        address = json['address'] as String,
        medium = {
          'email': ThirdPartyIdentifierMedium.email,
          'msisdn': ThirdPartyIdentifierMedium.msisdn
        }[json['medium']]!,
        validatedAt = json['validated_at'] as int;
  Map<String, dynamic> toJson() => {
        'added_at': addedAt,
        'address': address,
        'medium': {
          ThirdPartyIdentifierMedium.email: 'email',
          ThirdPartyIdentifierMedium.msisdn: 'msisdn'
        }[medium]!,
        'validated_at': validatedAt,
      };

  /// The timestamp, in milliseconds, when the homeserver associated the third party identifier with the user.
  int addedAt;

  /// The third party identifier address.
  String address;

  /// The medium of the third party identifier.
  ThirdPartyIdentifierMedium medium;

  /// The timestamp, in milliseconds, when the identifier was
  /// validated by the identity server.
  int validatedAt;
}

@_NameSource('spec')
class ThreePidCredentials {
  ThreePidCredentials({
    required this.clientSecret,
    required this.idAccessToken,
    required this.idServer,
    required this.sid,
  });

  ThreePidCredentials.fromJson(Map<String, dynamic> json)
      : clientSecret = json['client_secret'] as String,
        idAccessToken = json['id_access_token'] as String,
        idServer = json['id_server'] as String,
        sid = json['sid'] as String;
  Map<String, dynamic> toJson() => {
        'client_secret': clientSecret,
        'id_access_token': idAccessToken,
        'id_server': idServer,
        'sid': sid,
      };

  /// The client secret used in the session with the identity server.
  String clientSecret;

  /// An access token previously registered with the identity server. Servers
  /// can treat this as optional to distinguish between r0.5-compatible clients
  /// and this specification version.
  String idAccessToken;

  /// The identity server to use.
  String idServer;

  /// The session identifier given by the identity server.
  String sid;
}

@_NameSource('generated')
enum IdServerUnbindResult { noSupport, success }

@_NameSource('spec')
class RequestTokenResponse {
  RequestTokenResponse({
    required this.sid,
    this.submitUrl,
  });

  RequestTokenResponse.fromJson(Map<String, dynamic> json)
      : sid = json['sid'] as String,
        submitUrl =
            ((v) => v != null ? Uri.parse(v) : null)(json['submit_url']);
  Map<String, dynamic> toJson() {
    final submitUrl = this.submitUrl;
    return {
      'sid': sid,
      if (submitUrl != null) 'submit_url': submitUrl.toString(),
    };
  }

  /// The session ID. Session IDs are opaque strings that must consist entirely
  /// of the characters `[0-9a-zA-Z.=_-]`. Their length must not exceed 255
  /// characters and they must not be empty.
  String sid;

  /// An optional field containing a URL where the client must submit the
  /// validation token to, with identical parameters to the Identity Service
  /// API's `POST /validate/email/submitToken` endpoint (without the requirement
  /// for an access token). The homeserver must send this token to the user (if
  /// applicable), who should then be prompted to provide it to the client.
  ///
  /// If this field is not present, the client can assume that verification
  /// will happen without the client's involvement provided the homeserver
  /// advertises this specification version in the `/versions` response
  /// (ie: r0.5.0).
  Uri? submitUrl;
}

@_NameSource('rule override generated')
class TokenOwnerInfo {
  TokenOwnerInfo({
    this.deviceId,
    required this.userId,
  });

  TokenOwnerInfo.fromJson(Map<String, dynamic> json)
      : deviceId = ((v) => v != null ? v as String : null)(json['device_id']),
        userId = json['user_id'] as String;
  Map<String, dynamic> toJson() {
    final deviceId = this.deviceId;
    return {
      if (deviceId != null) 'device_id': deviceId,
      'user_id': userId,
    };
  }

  /// Device ID associated with the access token. If no device
  /// is associated with the access token (such as in the case
  /// of application services) then this field can be omitted.
  /// Otherwise this is required.
  String? deviceId;

  /// The user ID that owns the access token.
  String userId;
}

@_NameSource('spec')
class ConnectionInfo {
  ConnectionInfo({
    this.ip,
    this.lastSeen,
    this.userAgent,
  });

  ConnectionInfo.fromJson(Map<String, dynamic> json)
      : ip = ((v) => v != null ? v as String : null)(json['ip']),
        lastSeen = ((v) => v != null ? v as int : null)(json['last_seen']),
        userAgent = ((v) => v != null ? v as String : null)(json['user_agent']);
  Map<String, dynamic> toJson() {
    final ip = this.ip;
    final lastSeen = this.lastSeen;
    final userAgent = this.userAgent;
    return {
      if (ip != null) 'ip': ip,
      if (lastSeen != null) 'last_seen': lastSeen,
      if (userAgent != null) 'user_agent': userAgent,
    };
  }

  /// Most recently seen IP address of the session.
  String? ip;

  /// Unix timestamp that the session was last active.
  int? lastSeen;

  /// User agent string last seen in the session.
  String? userAgent;
}

@_NameSource('spec')
class SessionInfo {
  SessionInfo({
    this.connections,
  });

  SessionInfo.fromJson(Map<String, dynamic> json)
      : connections = ((v) => v != null
            ? (v as List).map((v) => ConnectionInfo.fromJson(v)).toList()
            : null)(json['connections']);
  Map<String, dynamic> toJson() {
    final connections = this.connections;
    return {
      if (connections != null)
        'connections': connections.map((v) => v.toJson()).toList(),
    };
  }

  /// Information particular connections in the session.
  List<ConnectionInfo>? connections;
}

@_NameSource('spec')
class DeviceInfo {
  DeviceInfo({
    this.sessions,
  });

  DeviceInfo.fromJson(Map<String, dynamic> json)
      : sessions = ((v) => v != null
            ? (v as List).map((v) => SessionInfo.fromJson(v)).toList()
            : null)(json['sessions']);
  Map<String, dynamic> toJson() {
    final sessions = this.sessions;
    return {
      if (sessions != null)
        'sessions': sessions.map((v) => v.toJson()).toList(),
    };
  }

  /// A user's sessions (i.e. what they did with an access token from one login).
  List<SessionInfo>? sessions;
}

@_NameSource('rule override generated')
class WhoIsInfo {
  WhoIsInfo({
    this.devices,
    this.userId,
  });

  WhoIsInfo.fromJson(Map<String, dynamic> json)
      : devices = ((v) => v != null
            ? (v as Map<String, dynamic>)
                .map((k, v) => MapEntry(k, DeviceInfo.fromJson(v)))
            : null)(json['devices']),
        userId = ((v) => v != null ? v as String : null)(json['user_id']);
  Map<String, dynamic> toJson() {
    final devices = this.devices;
    final userId = this.userId;
    return {
      if (devices != null)
        'devices': devices.map((k, v) => MapEntry(k, v.toJson())),
      if (userId != null) 'user_id': userId,
    };
  }

  /// Each key is an identifier for one of the user's devices.
  Map<String, DeviceInfo>? devices;

  /// The Matrix user ID of the user.
  String? userId;
}

@_NameSource('spec')
class ChangePasswordCapability {
  ChangePasswordCapability({
    required this.enabled,
  });

  ChangePasswordCapability.fromJson(Map<String, dynamic> json)
      : enabled = json['enabled'] as bool;
  Map<String, dynamic> toJson() => {
        'enabled': enabled,
      };

  /// True if the user can change their password, false otherwise.
  bool enabled;
}

/// The stability of the room version.
@_NameSource('rule override generated')
enum RoomVersionAvailable { stable, unstable }

@_NameSource('spec')
class RoomVersionsCapability {
  RoomVersionsCapability({
    required this.available,
    required this.default$,
  });

  RoomVersionsCapability.fromJson(Map<String, dynamic> json)
      : available = (json['available'] as Map<String, dynamic>).map((k, v) =>
            MapEntry(
                k,
                {
                  'stable': RoomVersionAvailable.stable,
                  'unstable': RoomVersionAvailable.unstable
                }[v]!)),
        default$ = json['default'] as String;
  Map<String, dynamic> toJson() => {
        'available': available.map((k, v) => MapEntry(
            k,
            {
              RoomVersionAvailable.stable: 'stable',
              RoomVersionAvailable.unstable: 'unstable'
            }[v]!)),
        'default': default$,
      };

  /// A detailed description of the room versions the server supports.
  Map<String, RoomVersionAvailable> available;

  /// The default room version the server is using for new rooms.
  String default$;
}

@_NameSource('spec')
class Capabilities {
  Capabilities({
    this.mChangePassword,
    this.mRoomVersions,
    this.additionalProperties = const {},
  });

  Capabilities.fromJson(Map<String, dynamic> json)
      : mChangePassword = ((v) => v != null
            ? ChangePasswordCapability.fromJson(v)
            : null)(json['m.change_password']),
        mRoomVersions = ((v) => v != null
            ? RoomVersionsCapability.fromJson(v)
            : null)(json['m.room_versions']),
        additionalProperties = Map.fromEntries(json.entries
            .where((e) =>
                !['m.change_password', 'm.room_versions'].contains(e.key))
            .map((e) => MapEntry(e.key, e.value as Map<String, dynamic>)));
  Map<String, dynamic> toJson() {
    final mChangePassword = this.mChangePassword;
    final mRoomVersions = this.mRoomVersions;
    return {
      ...additionalProperties,
      if (mChangePassword != null)
        'm.change_password': mChangePassword.toJson(),
      if (mRoomVersions != null) 'm.room_versions': mRoomVersions.toJson(),
    };
  }

  /// Capability to indicate if the user can change their password.
  ChangePasswordCapability? mChangePassword;

  /// The room versions the server supports.
  RoomVersionsCapability? mRoomVersions;

  Map<String, Map<String, dynamic>> additionalProperties;
}

@_NameSource('spec')
class StateEvent {
  StateEvent({
    required this.content,
    this.stateKey,
    required this.type,
  });

  StateEvent.fromJson(Map<String, dynamic> json)
      : content = json['content'] as Map<String, dynamic>,
        stateKey = ((v) => v != null ? v as String : null)(json['state_key']),
        type = json['type'] as String;
  Map<String, dynamic> toJson() {
    final stateKey = this.stateKey;
    return {
      'content': content,
      if (stateKey != null) 'state_key': stateKey,
      'type': type,
    };
  }

  /// The content of the event.
  Map<String, dynamic> content;

  /// The state_key of the state event. Defaults to an empty string.
  String? stateKey;

  /// The type of event to send.
  String type;
}

@_NameSource('spec')
class Invite3pid {
  Invite3pid({
    required this.address,
    required this.idAccessToken,
    required this.idServer,
    required this.medium,
  });

  Invite3pid.fromJson(Map<String, dynamic> json)
      : address = json['address'] as String,
        idAccessToken = json['id_access_token'] as String,
        idServer = json['id_server'] as String,
        medium = json['medium'] as String;
  Map<String, dynamic> toJson() => {
        'address': address,
        'id_access_token': idAccessToken,
        'id_server': idServer,
        'medium': medium,
      };

  /// The invitee's third party identifier.
  String address;

  /// An access token previously registered with the identity server. Servers
  /// can treat this as optional to distinguish between r0.5-compatible clients
  /// and this specification version.
  String idAccessToken;

  /// The hostname+port of the identity server which should be used for third party identifier lookups.
  String idServer;

  /// The kind of address being passed in the address field, for example `email`.
  String medium;
}

@_NameSource('rule override generated')
enum CreateRoomPreset { privateChat, publicChat, trustedPrivateChat }

@_NameSource('generated')
enum Visibility { private, public }

/// A client device
@_NameSource('spec')
class Device {
  Device({
    required this.deviceId,
    this.displayName,
    this.lastSeenIp,
    this.lastSeenTs,
  });

  Device.fromJson(Map<String, dynamic> json)
      : deviceId = json['device_id'] as String,
        displayName =
            ((v) => v != null ? v as String : null)(json['display_name']),
        lastSeenIp =
            ((v) => v != null ? v as String : null)(json['last_seen_ip']),
        lastSeenTs = ((v) => v != null ? v as int : null)(json['last_seen_ts']);
  Map<String, dynamic> toJson() {
    final displayName = this.displayName;
    final lastSeenIp = this.lastSeenIp;
    final lastSeenTs = this.lastSeenTs;
    return {
      'device_id': deviceId,
      if (displayName != null) 'display_name': displayName,
      if (lastSeenIp != null) 'last_seen_ip': lastSeenIp,
      if (lastSeenTs != null) 'last_seen_ts': lastSeenTs,
    };
  }

  /// Identifier of this device.
  String deviceId;

  /// Display name set by the user for this device. Absent if no name has been
  /// set.
  String? displayName;

  /// The IP address where this device was last seen. (May be a few minutes out
  /// of date, for efficiency reasons).
  String? lastSeenIp;

  /// The timestamp (in milliseconds since the unix epoch) when this devices
  /// was last seen. (May be a few minutes out of date, for efficiency
  /// reasons).
  int? lastSeenTs;
}

@_NameSource('generated')
class GetRoomIdByAliasResponse {
  GetRoomIdByAliasResponse({
    this.roomId,
    this.servers,
  });

  GetRoomIdByAliasResponse.fromJson(Map<String, dynamic> json)
      : roomId = ((v) => v != null ? v as String : null)(json['room_id']),
        servers = ((v) => v != null
            ? (v as List).map((v) => v as String).toList()
            : null)(json['servers']);
  Map<String, dynamic> toJson() {
    final roomId = this.roomId;
    final servers = this.servers;
    return {
      if (roomId != null) 'room_id': roomId,
      if (servers != null) 'servers': servers.map((v) => v).toList(),
    };
  }

  /// The room ID for this room alias.
  String? roomId;

  /// A list of servers that are aware of this room alias.
  List<String>? servers;
}

@_NameSource('rule override generated')
class EventsSyncUpdate {
  EventsSyncUpdate({
    this.chunk,
    this.end,
    this.start,
  });

  EventsSyncUpdate.fromJson(Map<String, dynamic> json)
      : chunk = ((v) => v != null
            ? (v as List).map((v) => MatrixEvent.fromJson(v)).toList()
            : null)(json['chunk']),
        end = ((v) => v != null ? v as String : null)(json['end']),
        start = ((v) => v != null ? v as String : null)(json['start']);
  Map<String, dynamic> toJson() {
    final chunk = this.chunk;
    final end = this.end;
    final start = this.start;
    return {
      if (chunk != null) 'chunk': chunk.map((v) => v.toJson()).toList(),
      if (end != null) 'end': end,
      if (start != null) 'start': start,
    };
  }

  /// An array of events.
  List<MatrixEvent>? chunk;

  /// A token which correlates to the last value in `chunk`. This
  /// token should be used in the next request to `/events`.
  String? end;

  /// A token which correlates to the first value in `chunk`. This
  /// is usually the same token supplied to `from=`.
  String? start;
}

/// A signature of an `m.third_party_invite` token to prove that this user
/// owns a third party identity which has been invited to the room.
@_NameSource('spec')
class ThirdPartySigned {
  ThirdPartySigned({
    required this.mxid,
    required this.sender,
    required this.signatures,
    required this.token,
  });

  ThirdPartySigned.fromJson(Map<String, dynamic> json)
      : mxid = json['mxid'] as String,
        sender = json['sender'] as String,
        signatures = (json['signatures'] as Map<String, dynamic>).map((k, v) =>
            MapEntry(
                k,
                (v as Map<String, dynamic>)
                    .map((k, v) => MapEntry(k, v as String)))),
        token = json['token'] as String;
  Map<String, dynamic> toJson() => {
        'mxid': mxid,
        'sender': sender,
        'signatures': signatures
            .map((k, v) => MapEntry(k, v.map((k, v) => MapEntry(k, v)))),
        'token': token,
      };

  /// The Matrix ID of the invitee.
  String mxid;

  /// The Matrix ID of the user who issued the invite.
  String sender;

  /// A signatures object containing a signature of the entire signed object.
  Map<String, Map<String, String>> signatures;

  /// The state key of the m.third_party_invite event.
  String token;
}

@_NameSource('generated')
class GetKeysChangesResponse {
  GetKeysChangesResponse({
    this.changed,
    this.left,
  });

  GetKeysChangesResponse.fromJson(Map<String, dynamic> json)
      : changed = ((v) => v != null
            ? (v as List).map((v) => v as String).toList()
            : null)(json['changed']),
        left = ((v) => v != null
            ? (v as List).map((v) => v as String).toList()
            : null)(json['left']);
  Map<String, dynamic> toJson() {
    final changed = this.changed;
    final left = this.left;
    return {
      if (changed != null) 'changed': changed.map((v) => v).toList(),
      if (left != null) 'left': left.map((v) => v).toList(),
    };
  }

  /// The Matrix User IDs of all users who updated their device
  /// identity keys.
  List<String>? changed;

  /// The Matrix User IDs of all users who may have left all
  /// the end-to-end encrypted rooms they previously shared
  /// with the user.
  List<String>? left;
}

@_NameSource('generated')
class ClaimKeysResponse {
  ClaimKeysResponse({
    this.failures,
    required this.oneTimeKeys,
  });

  ClaimKeysResponse.fromJson(Map<String, dynamic> json)
      : failures = ((v) => v != null
            ? (v as Map<String, dynamic>)
                .map((k, v) => MapEntry(k, v as Map<String, dynamic>))
            : null)(json['failures']),
        oneTimeKeys = (json['one_time_keys'] as Map<String, dynamic>).map(
            (k, v) => MapEntry(
                k,
                (v as Map<String, dynamic>)
                    .map((k, v) => MapEntry(k, v as dynamic))));
  Map<String, dynamic> toJson() {
    final failures = this.failures;
    return {
      if (failures != null) 'failures': failures.map((k, v) => MapEntry(k, v)),
      'one_time_keys': oneTimeKeys
          .map((k, v) => MapEntry(k, v.map((k, v) => MapEntry(k, v)))),
    };
  }

  /// If any remote homeservers could not be reached, they are
  /// recorded here. The names of the properties are the names of
  /// the unreachable servers.
  ///
  /// If the homeserver could be reached, but the user or device
  /// was unknown, no failure is recorded. Instead, the corresponding
  /// user or device is missing from the `one_time_keys` result.
  Map<String, Map<String, dynamic>>? failures;

  /// One-time keys for the queried devices. A map from user ID, to a
  /// map from devices to a map from `<algorithm>:<key_id>` to the key object.
  ///
  /// See the [key algorithms](https://spec.matrix.org/unstable/client-server-api/#key-algorithms) section for information
  /// on the Key Object format.
  Map<String, Map<String, dynamic>> oneTimeKeys;
}

@_NameSource('generated')
class QueryKeysResponse {
  QueryKeysResponse({
    this.deviceKeys,
    this.failures,
    this.masterKeys,
    this.selfSigningKeys,
    this.userSigningKeys,
  });

  QueryKeysResponse.fromJson(Map<String, dynamic> json)
      : deviceKeys = ((v) => v != null
            ? (v as Map<String, dynamic>).map((k, v) => MapEntry(
                k,
                (v as Map<String, dynamic>)
                    .map((k, v) => MapEntry(k, MatrixDeviceKeys.fromJson(v)))))
            : null)(json['device_keys']),
        failures = ((v) => v != null
            ? (v as Map<String, dynamic>)
                .map((k, v) => MapEntry(k, v as Map<String, dynamic>))
            : null)(json['failures']),
        masterKeys = ((v) => v != null
            ? (v as Map<String, dynamic>)
                .map((k, v) => MapEntry(k, MatrixCrossSigningKey.fromJson(v)))
            : null)(json['master_keys']),
        selfSigningKeys = ((v) => v != null
            ? (v as Map<String, dynamic>)
                .map((k, v) => MapEntry(k, MatrixCrossSigningKey.fromJson(v)))
            : null)(json['self_signing_keys']),
        userSigningKeys = ((v) => v != null
            ? (v as Map<String, dynamic>)
                .map((k, v) => MapEntry(k, MatrixCrossSigningKey.fromJson(v)))
            : null)(json['user_signing_keys']);
  Map<String, dynamic> toJson() {
    final deviceKeys = this.deviceKeys;
    final failures = this.failures;
    final masterKeys = this.masterKeys;
    final selfSigningKeys = this.selfSigningKeys;
    final userSigningKeys = this.userSigningKeys;
    return {
      if (deviceKeys != null)
        'device_keys': deviceKeys.map(
            (k, v) => MapEntry(k, v.map((k, v) => MapEntry(k, v.toJson())))),
      if (failures != null) 'failures': failures.map((k, v) => MapEntry(k, v)),
      if (masterKeys != null)
        'master_keys': masterKeys.map((k, v) => MapEntry(k, v.toJson())),
      if (selfSigningKeys != null)
        'self_signing_keys':
            selfSigningKeys.map((k, v) => MapEntry(k, v.toJson())),
      if (userSigningKeys != null)
        'user_signing_keys':
            userSigningKeys.map((k, v) => MapEntry(k, v.toJson())),
    };
  }

  /// Information on the queried devices. A map from user ID, to a
  /// map from device ID to device information.  For each device,
  /// the information returned will be the same as uploaded via
  /// `/keys/upload`, with the addition of an `unsigned`
  /// property.
  Map<String, Map<String, MatrixDeviceKeys>>? deviceKeys;

  /// If any remote homeservers could not be reached, they are
  /// recorded here. The names of the properties are the names of
  /// the unreachable servers.
  ///
  /// If the homeserver could be reached, but the user or device
  /// was unknown, no failure is recorded. Instead, the corresponding
  /// user or device is missing from the `device_keys` result.
  Map<String, Map<String, dynamic>>? failures;

  /// Information on the master cross-signing keys of the queried users.
  /// A map from user ID, to master key information.  For each key, the
  /// information returned will be the same as uploaded via
  /// `/keys/device_signing/upload`, along with the signatures
  /// uploaded via `/keys/signatures/upload` that the requesting user
  /// is allowed to see.
  Map<String, MatrixCrossSigningKey>? masterKeys;

  /// Information on the self-signing keys of the queried users. A map
  /// from user ID, to self-signing key information.  For each key, the
  /// information returned will be the same as uploaded via
  /// `/keys/device_signing/upload`.
  Map<String, MatrixCrossSigningKey>? selfSigningKeys;

  /// Information on the user-signing key of the user making the
  /// request, if they queried their own device information. A map
  /// from user ID, to user-signing key information.  The
  /// information returned will be the same as uploaded via
  /// `/keys/device_signing/upload`.
  Map<String, MatrixCrossSigningKey>? userSigningKeys;
}

@_NameSource('spec')
class LoginFlow {
  LoginFlow({
    this.type,
  });

  LoginFlow.fromJson(Map<String, dynamic> json)
      : type = ((v) => v != null ? v as String : null)(json['type']);
  Map<String, dynamic> toJson() {
    final type = this.type;
    return {
      if (type != null) 'type': type,
    };
  }

  /// The login type. This is supplied as the `type` when
  /// logging in.
  String? type;
}

@_NameSource('rule override generated')
enum LoginType { mLoginPassword, mLoginToken }

@_NameSource('generated')
class LoginResponse {
  LoginResponse({
    this.accessToken,
    this.deviceId,
    this.homeServer,
    this.userId,
    this.wellKnown,
  });

  LoginResponse.fromJson(Map<String, dynamic> json)
      : accessToken =
            ((v) => v != null ? v as String : null)(json['access_token']),
        deviceId = ((v) => v != null ? v as String : null)(json['device_id']),
        homeServer =
            ((v) => v != null ? v as String : null)(json['home_server']),
        userId = ((v) => v != null ? v as String : null)(json['user_id']),
        wellKnown = ((v) => v != null
            ? DiscoveryInformation.fromJson(v)
            : null)(json['well_known']);
  Map<String, dynamic> toJson() {
    final accessToken = this.accessToken;
    final deviceId = this.deviceId;
    final homeServer = this.homeServer;
    final userId = this.userId;
    final wellKnown = this.wellKnown;
    return {
      if (accessToken != null) 'access_token': accessToken,
      if (deviceId != null) 'device_id': deviceId,
      if (homeServer != null) 'home_server': homeServer,
      if (userId != null) 'user_id': userId,
      if (wellKnown != null) 'well_known': wellKnown.toJson(),
    };
  }

  /// An access token for the account.
  /// This access token can then be used to authorize other requests.
  String? accessToken;

  /// ID of the logged-in device. Will be the same as the
  /// corresponding parameter in the request, if one was specified.
  String? deviceId;

  /// The server_name of the homeserver on which the account has
  /// been registered.
  ///
  /// **Deprecated**. Clients should extract the server_name from
  /// `user_id` (by splitting at the first colon) if they require
  /// it. Note also that `homeserver` is not spelt this way.
  String? homeServer;

  /// The fully-qualified Matrix ID for the account.
  String? userId;

  /// Optional client configuration provided by the server. If present,
  /// clients SHOULD use the provided object to reconfigure themselves,
  /// optionally validating the URLs within. This object takes the same
  /// form as the one returned from .well-known autodiscovery.
  DiscoveryInformation? wellKnown;
}

@_NameSource('spec')
class Notification {
  Notification({
    required this.actions,
    required this.event,
    this.profileTag,
    required this.read,
    required this.roomId,
    required this.ts,
  });

  Notification.fromJson(Map<String, dynamic> json)
      : actions = (json['actions'] as List).map((v) => v as dynamic).toList(),
        event = MatrixEvent.fromJson(json['event']),
        profileTag =
            ((v) => v != null ? v as String : null)(json['profile_tag']),
        read = json['read'] as bool,
        roomId = json['room_id'] as String,
        ts = json['ts'] as int;
  Map<String, dynamic> toJson() {
    final profileTag = this.profileTag;
    return {
      'actions': actions.map((v) => v).toList(),
      'event': event.toJson(),
      if (profileTag != null) 'profile_tag': profileTag,
      'read': read,
      'room_id': roomId,
      'ts': ts,
    };
  }

  /// The action(s) to perform when the conditions for this rule are met.
  /// See [Push Rules: API](https://spec.matrix.org/unstable/client-server-api/#push-rules-api).
  List<dynamic> actions;

  /// The Event object for the event that triggered the notification.
  MatrixEvent event;

  /// The profile tag of the rule that matched this event.
  String? profileTag;

  /// Indicates whether the user has sent a read receipt indicating
  /// that they have read this message.
  bool read;

  /// The ID of the room in which the event was posted.
  String roomId;

  /// The unix timestamp at which the event notification was sent,
  /// in milliseconds.
  int ts;
}

@_NameSource('generated')
class GetNotificationsResponse {
  GetNotificationsResponse({
    this.nextToken,
    required this.notifications,
  });

  GetNotificationsResponse.fromJson(Map<String, dynamic> json)
      : nextToken = ((v) => v != null ? v as String : null)(json['next_token']),
        notifications = (json['notifications'] as List)
            .map((v) => Notification.fromJson(v))
            .toList();
  Map<String, dynamic> toJson() {
    final nextToken = this.nextToken;
    return {
      if (nextToken != null) 'next_token': nextToken,
      'notifications': notifications.map((v) => v.toJson()).toList(),
    };
  }

  /// The token to supply in the `from` param of the next
  /// `/notifications` request in order to request more
  /// events. If this is absent, there are no more results.
  String? nextToken;

  /// The list of events that triggered notifications.
  List<Notification> notifications;
}

@_NameSource('rule override generated')
enum PresenceType { offline, online, unavailable }

@_NameSource('generated')
class GetPresenceResponse {
  GetPresenceResponse({
    this.currentlyActive,
    this.lastActiveAgo,
    required this.presence,
    this.statusMsg,
  });

  GetPresenceResponse.fromJson(Map<String, dynamic> json)
      : currentlyActive =
            ((v) => v != null ? v as bool : null)(json['currently_active']),
        lastActiveAgo =
            ((v) => v != null ? v as int : null)(json['last_active_ago']),
        presence = {
          'online': PresenceType.online,
          'offline': PresenceType.offline,
          'unavailable': PresenceType.unavailable
        }[json['presence']]!,
        statusMsg = ((v) => v != null ? v as String : null)(json['status_msg']);
  Map<String, dynamic> toJson() {
    final currentlyActive = this.currentlyActive;
    final lastActiveAgo = this.lastActiveAgo;
    final statusMsg = this.statusMsg;
    return {
      if (currentlyActive != null) 'currently_active': currentlyActive,
      if (lastActiveAgo != null) 'last_active_ago': lastActiveAgo,
      'presence': {
        PresenceType.online: 'online',
        PresenceType.offline: 'offline',
        PresenceType.unavailable: 'unavailable'
      }[presence]!,
      if (statusMsg != null) 'status_msg': statusMsg,
    };
  }

  /// Whether the user is currently active
  bool? currentlyActive;

  /// The length of time in milliseconds since an action was performed
  /// by this user.
  int? lastActiveAgo;

  /// This user's presence.
  PresenceType presence;

  /// The state message for this user if one was set.
  String? statusMsg;
}

@_NameSource('rule override generated')
class ProfileInformation {
  ProfileInformation({
    this.avatarUrl,
    this.displayname,
  });

  ProfileInformation.fromJson(Map<String, dynamic> json)
      : avatarUrl =
            ((v) => v != null ? Uri.parse(v) : null)(json['avatar_url']),
        displayname =
            ((v) => v != null ? v as String : null)(json['displayname']);
  Map<String, dynamic> toJson() {
    final avatarUrl = this.avatarUrl;
    final displayname = this.displayname;
    return {
      if (avatarUrl != null) 'avatar_url': avatarUrl.toString(),
      if (displayname != null) 'displayname': displayname,
    };
  }

  /// The user's avatar URL if they have set one, otherwise not present.
  Uri? avatarUrl;

  /// The user's display name if they have set one, otherwise not present.
  String? displayname;
}

@_NameSource('spec')
class PublicRoomsChunk {
  PublicRoomsChunk({
    this.aliases,
    this.avatarUrl,
    this.canonicalAlias,
    required this.guestCanJoin,
    this.joinRule,
    this.name,
    required this.numJoinedMembers,
    required this.roomId,
    this.topic,
    required this.worldReadable,
  });

  PublicRoomsChunk.fromJson(Map<String, dynamic> json)
      : aliases = ((v) => v != null
            ? (v as List).map((v) => v as String).toList()
            : null)(json['aliases']),
        avatarUrl =
            ((v) => v != null ? Uri.parse(v) : null)(json['avatar_url']),
        canonicalAlias =
            ((v) => v != null ? v as String : null)(json['canonical_alias']),
        guestCanJoin = json['guest_can_join'] as bool,
        joinRule = ((v) => v != null ? v as String : null)(json['join_rule']),
        name = ((v) => v != null ? v as String : null)(json['name']),
        numJoinedMembers = json['num_joined_members'] as int,
        roomId = json['room_id'] as String,
        topic = ((v) => v != null ? v as String : null)(json['topic']),
        worldReadable = json['world_readable'] as bool;
  Map<String, dynamic> toJson() {
    final aliases = this.aliases;
    final avatarUrl = this.avatarUrl;
    final canonicalAlias = this.canonicalAlias;
    final joinRule = this.joinRule;
    final name = this.name;
    final topic = this.topic;
    return {
      if (aliases != null) 'aliases': aliases.map((v) => v).toList(),
      if (avatarUrl != null) 'avatar_url': avatarUrl.toString(),
      if (canonicalAlias != null) 'canonical_alias': canonicalAlias,
      'guest_can_join': guestCanJoin,
      if (joinRule != null) 'join_rule': joinRule,
      if (name != null) 'name': name,
      'num_joined_members': numJoinedMembers,
      'room_id': roomId,
      if (topic != null) 'topic': topic,
      'world_readable': worldReadable,
    };
  }

  /// Aliases of the room. May be empty.
  List<String>? aliases;

  /// The URL for the room's avatar, if one is set.
  Uri? avatarUrl;

  /// The canonical alias of the room, if any.
  String? canonicalAlias;

  /// Whether guest users may join the room and participate in it.
  /// If they can, they will be subject to ordinary power level
  /// rules like any other user.
  bool guestCanJoin;

  /// The room's join rule. When not present, the room is assumed to
  /// be `public`. Note that rooms with `invite` join rules are not
  /// expected here, but rooms with `knock` rules are given their
  /// near-public nature.
  String? joinRule;

  /// The name of the room, if any.
  String? name;

  /// The number of members joined to the room.
  int numJoinedMembers;

  /// The ID of the room.
  String roomId;

  /// The topic of the room, if any.
  String? topic;

  /// Whether the room may be viewed by guest users without joining.
  bool worldReadable;
}

/// A list of the rooms on the server.
@_NameSource('generated')
class GetPublicRoomsResponse {
  GetPublicRoomsResponse({
    required this.chunk,
    this.nextBatch,
    this.prevBatch,
    this.totalRoomCountEstimate,
  });

  GetPublicRoomsResponse.fromJson(Map<String, dynamic> json)
      : chunk = (json['chunk'] as List)
            .map((v) => PublicRoomsChunk.fromJson(v))
            .toList(),
        nextBatch = ((v) => v != null ? v as String : null)(json['next_batch']),
        prevBatch = ((v) => v != null ? v as String : null)(json['prev_batch']),
        totalRoomCountEstimate = ((v) =>
            v != null ? v as int : null)(json['total_room_count_estimate']);
  Map<String, dynamic> toJson() {
    final nextBatch = this.nextBatch;
    final prevBatch = this.prevBatch;
    final totalRoomCountEstimate = this.totalRoomCountEstimate;
    return {
      'chunk': chunk.map((v) => v.toJson()).toList(),
      if (nextBatch != null) 'next_batch': nextBatch,
      if (prevBatch != null) 'prev_batch': prevBatch,
      if (totalRoomCountEstimate != null)
        'total_room_count_estimate': totalRoomCountEstimate,
    };
  }

  /// A paginated chunk of public rooms.
  List<PublicRoomsChunk> chunk;

  /// A pagination token for the response. The absence of this token
  /// means there are no more results to fetch and the client should
  /// stop paginating.
  String? nextBatch;

  /// A pagination token that allows fetching previous results. The
  /// absence of this token means there are no results before this
  /// batch, i.e. this is the first batch.
  String? prevBatch;

  /// An estimate on the total number of public rooms, if the
  /// server has an estimate.
  int? totalRoomCountEstimate;
}

@_NameSource('rule override spec')
class PublicRoomQueryFilter {
  PublicRoomQueryFilter({
    this.genericSearchTerm,
  });

  PublicRoomQueryFilter.fromJson(Map<String, dynamic> json)
      : genericSearchTerm = ((v) =>
            v != null ? v as String : null)(json['generic_search_term']);
  Map<String, dynamic> toJson() {
    final genericSearchTerm = this.genericSearchTerm;
    return {
      if (genericSearchTerm != null) 'generic_search_term': genericSearchTerm,
    };
  }

  /// A string to search for in the room metadata, e.g. name,
  /// topic, canonical alias etc. (Optional).
  String? genericSearchTerm;
}

/// A list of the rooms on the server.
@_NameSource('generated')
class QueryPublicRoomsResponse {
  QueryPublicRoomsResponse({
    required this.chunk,
    this.nextBatch,
    this.prevBatch,
    this.totalRoomCountEstimate,
  });

  QueryPublicRoomsResponse.fromJson(Map<String, dynamic> json)
      : chunk = (json['chunk'] as List)
            .map((v) => PublicRoomsChunk.fromJson(v))
            .toList(),
        nextBatch = ((v) => v != null ? v as String : null)(json['next_batch']),
        prevBatch = ((v) => v != null ? v as String : null)(json['prev_batch']),
        totalRoomCountEstimate = ((v) =>
            v != null ? v as int : null)(json['total_room_count_estimate']);
  Map<String, dynamic> toJson() {
    final nextBatch = this.nextBatch;
    final prevBatch = this.prevBatch;
    final totalRoomCountEstimate = this.totalRoomCountEstimate;
    return {
      'chunk': chunk.map((v) => v.toJson()).toList(),
      if (nextBatch != null) 'next_batch': nextBatch,
      if (prevBatch != null) 'prev_batch': prevBatch,
      if (totalRoomCountEstimate != null)
        'total_room_count_estimate': totalRoomCountEstimate,
    };
  }

  /// A paginated chunk of public rooms.
  List<PublicRoomsChunk> chunk;

  /// A pagination token for the response. The absence of this token
  /// means there are no more results to fetch and the client should
  /// stop paginating.
  String? nextBatch;

  /// A pagination token that allows fetching previous results. The
  /// absence of this token means there are no results before this
  /// batch, i.e. this is the first batch.
  String? prevBatch;

  /// An estimate on the total number of public rooms, if the
  /// server has an estimate.
  int? totalRoomCountEstimate;
}

@_NameSource('spec')
class PusherData {
  PusherData({
    this.format,
    this.url,
    this.additionalProperties = const {},
  });

  PusherData.fromJson(Map<String, dynamic> json)
      : format = ((v) => v != null ? v as String : null)(json['format']),
        url = ((v) => v != null ? Uri.parse(v) : null)(json['url']),
        additionalProperties = Map.fromEntries(json.entries
            .where((e) => !['format', 'url'].contains(e.key))
            .map((e) => MapEntry(e.key, e.value as dynamic)));
  Map<String, dynamic> toJson() {
    final format = this.format;
    final url = this.url;
    return {
      ...additionalProperties,
      if (format != null) 'format': format,
      if (url != null) 'url': url.toString(),
    };
  }

  /// The format to use when sending notifications to the Push
  /// Gateway.
  String? format;

  /// Required if `kind` is `http`. The URL to use to send
  /// notifications to.
  Uri? url;

  Map<String, dynamic> additionalProperties;
}

@_NameSource('spec')
class PusherId {
  PusherId({
    required this.appId,
    required this.pushkey,
  });

  PusherId.fromJson(Map<String, dynamic> json)
      : appId = json['app_id'] as String,
        pushkey = json['pushkey'] as String;
  Map<String, dynamic> toJson() => {
        'app_id': appId,
        'pushkey': pushkey,
      };

  /// This is a reverse-DNS style identifier for the application.
  /// Max length, 64 chars.
  String appId;

  /// This is a unique identifier for this pusher. See `/set` for
  /// more detail.
  /// Max length, 512 bytes.
  String pushkey;
}

@_NameSource('spec')
class Pusher implements PusherId {
  Pusher({
    required this.appId,
    required this.pushkey,
    required this.appDisplayName,
    required this.data,
    required this.deviceDisplayName,
    required this.kind,
    required this.lang,
    this.profileTag,
  });

  Pusher.fromJson(Map<String, dynamic> json)
      : appId = json['app_id'] as String,
        pushkey = json['pushkey'] as String,
        appDisplayName = json['app_display_name'] as String,
        data = PusherData.fromJson(json['data']),
        deviceDisplayName = json['device_display_name'] as String,
        kind = json['kind'] as String,
        lang = json['lang'] as String,
        profileTag =
            ((v) => v != null ? v as String : null)(json['profile_tag']);
  Map<String, dynamic> toJson() {
    final profileTag = this.profileTag;
    return {
      'app_id': appId,
      'pushkey': pushkey,
      'app_display_name': appDisplayName,
      'data': data.toJson(),
      'device_display_name': deviceDisplayName,
      'kind': kind,
      'lang': lang,
      if (profileTag != null) 'profile_tag': profileTag,
    };
  }

  /// This is a reverse-DNS style identifier for the application.
  /// Max length, 64 chars.
  String appId;

  /// This is a unique identifier for this pusher. See `/set` for
  /// more detail.
  /// Max length, 512 bytes.
  String pushkey;

  /// A string that will allow the user to identify what application
  /// owns this pusher.
  String appDisplayName;

  /// A dictionary of information for the pusher implementation
  /// itself.
  PusherData data;

  /// A string that will allow the user to identify what device owns
  /// this pusher.
  String deviceDisplayName;

  /// The kind of pusher. `"http"` is a pusher that
  /// sends HTTP pokes.
  String kind;

  /// The preferred language for receiving notifications (e.g. 'en'
  /// or 'en-US')
  String lang;

  /// This string determines which set of device specific rules this
  /// pusher executes.
  String? profileTag;
}

@_NameSource('spec')
class PushCondition {
  PushCondition({
    this.is$,
    this.key,
    required this.kind,
    this.pattern,
  });

  PushCondition.fromJson(Map<String, dynamic> json)
      : is$ = ((v) => v != null ? v as String : null)(json['is']),
        key = ((v) => v != null ? v as String : null)(json['key']),
        kind = json['kind'] as String,
        pattern = ((v) => v != null ? v as String : null)(json['pattern']);
  Map<String, dynamic> toJson() {
    final is$ = this.is$;
    final key = this.key;
    final pattern = this.pattern;
    return {
      if (is$ != null) 'is': is$,
      if (key != null) 'key': key,
      'kind': kind,
      if (pattern != null) 'pattern': pattern,
    };
  }

  /// Required for `room_member_count` conditions. A decimal integer
  /// optionally prefixed by one of, ==, <, >, >= or <=. A prefix of < matches
  /// rooms where the member count is strictly less than the given number and
  /// so forth. If no prefix is present, this parameter defaults to ==.
  String? is$;

  /// Required for `event_match` conditions. The dot-separated field of the
  /// event to match.
  ///
  /// Required for `sender_notification_permission` conditions. The field in
  /// the power level event the user needs a minimum power level for. Fields
  /// must be specified under the `notifications` property in the power level
  /// event's `content`.
  String? key;

  /// The kind of condition to apply. See [conditions](https://spec.matrix.org/unstable/client-server-api/#conditions) for
  /// more information on the allowed kinds and how they work.
  String kind;

  /// Required for `event_match` conditions. The glob-style pattern to
  /// match against. Patterns with no special glob characters should be
  /// treated as having asterisks prepended and appended when testing the
  /// condition.
  String? pattern;
}

@_NameSource('spec')
class PushRule {
  PushRule({
    required this.actions,
    this.conditions,
    required this.default$,
    required this.enabled,
    this.pattern,
    required this.ruleId,
  });

  PushRule.fromJson(Map<String, dynamic> json)
      : actions = (json['actions'] as List).map((v) => v as dynamic).toList(),
        conditions = ((v) => v != null
            ? (v as List).map((v) => PushCondition.fromJson(v)).toList()
            : null)(json['conditions']),
        default$ = json['default'] as bool,
        enabled = json['enabled'] as bool,
        pattern = ((v) => v != null ? v as String : null)(json['pattern']),
        ruleId = json['rule_id'] as String;
  Map<String, dynamic> toJson() {
    final conditions = this.conditions;
    final pattern = this.pattern;
    return {
      'actions': actions.map((v) => v).toList(),
      if (conditions != null)
        'conditions': conditions.map((v) => v.toJson()).toList(),
      'default': default$,
      'enabled': enabled,
      if (pattern != null) 'pattern': pattern,
      'rule_id': ruleId,
    };
  }

  /// The actions to perform when this rule is matched.
  List<dynamic> actions;

  /// The conditions that must hold true for an event in order for a rule to be
  /// applied to an event. A rule with no conditions always matches. Only
  /// applicable to `underride` and `override` rules.
  List<PushCondition>? conditions;

  /// Whether this is a default rule, or has been set explicitly.
  bool default$;

  /// Whether the push rule is enabled or not.
  bool enabled;

  /// The glob-style pattern to match against.  Only applicable to `content`
  /// rules.
  String? pattern;

  /// The ID of this rule.
  String ruleId;
}

@_NameSource('rule override generated')
class PushRuleSet {
  PushRuleSet({
    this.content,
    this.override,
    this.room,
    this.sender,
    this.underride,
  });

  PushRuleSet.fromJson(Map<String, dynamic> json)
      : content = ((v) => v != null
            ? (v as List).map((v) => PushRule.fromJson(v)).toList()
            : null)(json['content']),
        override = ((v) => v != null
            ? (v as List).map((v) => PushRule.fromJson(v)).toList()
            : null)(json['override']),
        room = ((v) => v != null
            ? (v as List).map((v) => PushRule.fromJson(v)).toList()
            : null)(json['room']),
        sender = ((v) => v != null
            ? (v as List).map((v) => PushRule.fromJson(v)).toList()
            : null)(json['sender']),
        underride = ((v) => v != null
            ? (v as List).map((v) => PushRule.fromJson(v)).toList()
            : null)(json['underride']);
  Map<String, dynamic> toJson() {
    final content = this.content;
    final override = this.override;
    final room = this.room;
    final sender = this.sender;
    final underride = this.underride;
    return {
      if (content != null) 'content': content.map((v) => v.toJson()).toList(),
      if (override != null)
        'override': override.map((v) => v.toJson()).toList(),
      if (room != null) 'room': room.map((v) => v.toJson()).toList(),
      if (sender != null) 'sender': sender.map((v) => v.toJson()).toList(),
      if (underride != null)
        'underride': underride.map((v) => v.toJson()).toList(),
    };
  }

  List<PushRule>? content;

  List<PushRule>? override;

  List<PushRule>? room;

  List<PushRule>? sender;

  List<PushRule>? underride;
}

@_NameSource('rule override generated')
enum PushRuleKind { content, override, room, sender, underride }

@_NameSource('rule override generated')
enum AccountKind { guest, user }

@_NameSource('generated')
class RegisterResponse {
  RegisterResponse({
    this.accessToken,
    this.deviceId,
    this.homeServer,
    required this.userId,
  });

  RegisterResponse.fromJson(Map<String, dynamic> json)
      : accessToken =
            ((v) => v != null ? v as String : null)(json['access_token']),
        deviceId = ((v) => v != null ? v as String : null)(json['device_id']),
        homeServer =
            ((v) => v != null ? v as String : null)(json['home_server']),
        userId = json['user_id'] as String;
  Map<String, dynamic> toJson() {
    final accessToken = this.accessToken;
    final deviceId = this.deviceId;
    final homeServer = this.homeServer;
    return {
      if (accessToken != null) 'access_token': accessToken,
      if (deviceId != null) 'device_id': deviceId,
      if (homeServer != null) 'home_server': homeServer,
      'user_id': userId,
    };
  }

  /// An access token for the account.
  /// This access token can then be used to authorize other requests.
  /// Required if the `inhibit_login` option is false.
  String? accessToken;

  /// ID of the registered device. Will be the same as the
  /// corresponding parameter in the request, if one was specified.
  /// Required if the `inhibit_login` option is false.
  String? deviceId;

  /// The server_name of the homeserver on which the account has
  /// been registered.
  ///
  /// **Deprecated**. Clients should extract the server_name from
  /// `user_id` (by splitting at the first colon) if they require
  /// it. Note also that `homeserver` is not spelt this way.
  String? homeServer;

  /// The fully-qualified Matrix user ID (MXID) that has been registered.
  ///
  /// Any user ID returned by this API must conform to the grammar given in the
  /// [Matrix specification](https://spec.matrix.org/unstable/appendices/#user-identifiers).
  String userId;
}

@_NameSource('spec')
class RoomKeysUpdateResponse {
  RoomKeysUpdateResponse({
    required this.count,
    required this.etag,
  });

  RoomKeysUpdateResponse.fromJson(Map<String, dynamic> json)
      : count = json['count'] as int,
        etag = json['etag'] as String;
  Map<String, dynamic> toJson() => {
        'count': count,
        'etag': etag,
      };

  /// The number of keys stored in the backup
  int count;

  /// The new etag value representing stored keys in the backup.
  /// See `GET /room_keys/version/{version}` for more details.
  String etag;
}

/// The key data
@_NameSource('spec')
class KeyBackupData {
  KeyBackupData({
    required this.firstMessageIndex,
    required this.forwardedCount,
    required this.isVerified,
    required this.sessionData,
  });

  KeyBackupData.fromJson(Map<String, dynamic> json)
      : firstMessageIndex = json['first_message_index'] as int,
        forwardedCount = json['forwarded_count'] as int,
        isVerified = json['is_verified'] as bool,
        sessionData = json['session_data'] as Map<String, dynamic>;
  Map<String, dynamic> toJson() => {
        'first_message_index': firstMessageIndex,
        'forwarded_count': forwardedCount,
        'is_verified': isVerified,
        'session_data': sessionData,
      };

  /// The index of the first message in the session that the key can decrypt.
  int firstMessageIndex;

  /// The number of times this key has been forwarded via key-sharing between devices.
  int forwardedCount;

  /// Whether the device backing up the key verified the device that the key
  /// is from.
  bool isVerified;

  /// Algorithm-dependent data.  See the documentation for the backup
  /// algorithms in [Server-side key backups](https://spec.matrix.org/unstable/client-server-api/#server-side-key-backups) for more information on the
  /// expected format of the data.
  Map<String, dynamic> sessionData;
}

/// The backed up keys for a room.
@_NameSource('spec')
class RoomKeyBackup {
  RoomKeyBackup({
    required this.sessions,
  });

  RoomKeyBackup.fromJson(Map<String, dynamic> json)
      : sessions = (json['sessions'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, KeyBackupData.fromJson(v)));
  Map<String, dynamic> toJson() => {
        'sessions': sessions.map((k, v) => MapEntry(k, v.toJson())),
      };

  /// A map of session IDs to key data.
  Map<String, KeyBackupData> sessions;
}

@_NameSource('rule override generated')
class RoomKeys {
  RoomKeys({
    required this.rooms,
  });

  RoomKeys.fromJson(Map<String, dynamic> json)
      : rooms = (json['rooms'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, RoomKeyBackup.fromJson(v)));
  Map<String, dynamic> toJson() => {
        'rooms': rooms.map((k, v) => MapEntry(k, v.toJson())),
      };

  /// A map of room IDs to room key backup data.
  Map<String, RoomKeyBackup> rooms;
}

@_NameSource('rule override generated')
enum BackupAlgorithm { mMegolmBackupV1Curve25519AesSha2 }

@_NameSource('generated')
class GetRoomKeysVersionCurrentResponse {
  GetRoomKeysVersionCurrentResponse({
    required this.algorithm,
    required this.authData,
    required this.count,
    required this.etag,
    required this.version,
  });

  GetRoomKeysVersionCurrentResponse.fromJson(Map<String, dynamic> json)
      : algorithm = {
          'm.megolm_backup.v1.curve25519-aes-sha2':
              BackupAlgorithm.mMegolmBackupV1Curve25519AesSha2
        }[json['algorithm']]!,
        authData = json['auth_data'] as Map<String, dynamic>,
        count = json['count'] as int,
        etag = json['etag'] as String,
        version = json['version'] as String;
  Map<String, dynamic> toJson() => {
        'algorithm': {
          BackupAlgorithm.mMegolmBackupV1Curve25519AesSha2:
              'm.megolm_backup.v1.curve25519-aes-sha2'
        }[algorithm]!,
        'auth_data': authData,
        'count': count,
        'etag': etag,
        'version': version,
      };

  /// The algorithm used for storing backups.
  BackupAlgorithm algorithm;

  /// Algorithm-dependent data. See the documentation for the backup
  /// algorithms in [Server-side key backups](https://spec.matrix.org/unstable/client-server-api/#server-side-key-backups) for more information on the
  /// expected format of the data.
  Map<String, dynamic> authData;

  /// The number of keys stored in the backup.
  int count;

  /// An opaque string representing stored keys in the backup.
  /// Clients can compare it with the `etag` value they received
  /// in the request of their last key storage request.  If not
  /// equal, another client has modified the backup.
  String etag;

  /// The backup version.
  String version;
}

@_NameSource('generated')
class GetRoomKeysVersionResponse {
  GetRoomKeysVersionResponse({
    required this.algorithm,
    required this.authData,
    required this.count,
    required this.etag,
    required this.version,
  });

  GetRoomKeysVersionResponse.fromJson(Map<String, dynamic> json)
      : algorithm = {
          'm.megolm_backup.v1.curve25519-aes-sha2':
              BackupAlgorithm.mMegolmBackupV1Curve25519AesSha2
        }[json['algorithm']]!,
        authData = json['auth_data'] as Map<String, dynamic>,
        count = json['count'] as int,
        etag = json['etag'] as String,
        version = json['version'] as String;
  Map<String, dynamic> toJson() => {
        'algorithm': {
          BackupAlgorithm.mMegolmBackupV1Curve25519AesSha2:
              'm.megolm_backup.v1.curve25519-aes-sha2'
        }[algorithm]!,
        'auth_data': authData,
        'count': count,
        'etag': etag,
        'version': version,
      };

  /// The algorithm used for storing backups.
  BackupAlgorithm algorithm;

  /// Algorithm-dependent data. See the documentation for the backup
  /// algorithms in [Server-side key backups](https://spec.matrix.org/unstable/client-server-api/#server-side-key-backups) for more information on the
  /// expected format of the data.
  Map<String, dynamic> authData;

  /// The number of keys stored in the backup.
  int count;

  /// An opaque string representing stored keys in the backup.
  /// Clients can compare it with the `etag` value they received
  /// in the request of their last key storage request.  If not
  /// equal, another client has modified the backup.
  String etag;

  /// The backup version.
  String version;
}

/// The events and state surrounding the requested event.
@_NameSource('rule override generated')
class EventContext {
  EventContext({
    this.end,
    this.event,
    this.eventsAfter,
    this.eventsBefore,
    this.start,
    this.state,
  });

  EventContext.fromJson(Map<String, dynamic> json)
      : end = ((v) => v != null ? v as String : null)(json['end']),
        event =
            ((v) => v != null ? MatrixEvent.fromJson(v) : null)(json['event']),
        eventsAfter = ((v) => v != null
            ? (v as List).map((v) => MatrixEvent.fromJson(v)).toList()
            : null)(json['events_after']),
        eventsBefore = ((v) => v != null
            ? (v as List).map((v) => MatrixEvent.fromJson(v)).toList()
            : null)(json['events_before']),
        start = ((v) => v != null ? v as String : null)(json['start']),
        state = ((v) => v != null
            ? (v as List).map((v) => MatrixEvent.fromJson(v)).toList()
            : null)(json['state']);
  Map<String, dynamic> toJson() {
    final end = this.end;
    final event = this.event;
    final eventsAfter = this.eventsAfter;
    final eventsBefore = this.eventsBefore;
    final start = this.start;
    final state = this.state;
    return {
      if (end != null) 'end': end,
      if (event != null) 'event': event.toJson(),
      if (eventsAfter != null)
        'events_after': eventsAfter.map((v) => v.toJson()).toList(),
      if (eventsBefore != null)
        'events_before': eventsBefore.map((v) => v.toJson()).toList(),
      if (start != null) 'start': start,
      if (state != null) 'state': state.map((v) => v.toJson()).toList(),
    };
  }

  /// A token that can be used to paginate forwards with.
  String? end;

  /// Details of the requested event.
  MatrixEvent? event;

  /// A list of room events that happened just after the
  /// requested event, in chronological order.
  List<MatrixEvent>? eventsAfter;

  /// A list of room events that happened just before the
  /// requested event, in reverse-chronological order.
  List<MatrixEvent>? eventsBefore;

  /// A token that can be used to paginate backwards with.
  String? start;

  /// The state of the room at the last event returned.
  List<MatrixEvent>? state;
}

@_NameSource('spec')
class RoomMember {
  RoomMember({
    this.avatarUrl,
    this.displayName,
  });

  RoomMember.fromJson(Map<String, dynamic> json)
      : avatarUrl =
            ((v) => v != null ? Uri.parse(v) : null)(json['avatar_url']),
        displayName =
            ((v) => v != null ? v as String : null)(json['display_name']);
  Map<String, dynamic> toJson() {
    final avatarUrl = this.avatarUrl;
    final displayName = this.displayName;
    return {
      if (avatarUrl != null) 'avatar_url': avatarUrl.toString(),
      if (displayName != null) 'display_name': displayName,
    };
  }

  /// The mxc avatar url of the user this object is representing.
  Uri? avatarUrl;

  /// The display name of the user this object is representing.
  String? displayName;
}

@_NameSource('(generated, rule override generated)')
enum Membership { ban, invite, join, knock, leave }

@_NameSource('rule override generated')
enum Direction { b, f }

/// A list of messages with a new token to request more.
@_NameSource('generated')
class GetRoomEventsResponse {
  GetRoomEventsResponse({
    this.chunk,
    this.end,
    this.start,
    this.state,
  });

  GetRoomEventsResponse.fromJson(Map<String, dynamic> json)
      : chunk = ((v) => v != null
            ? (v as List).map((v) => MatrixEvent.fromJson(v)).toList()
            : null)(json['chunk']),
        end = ((v) => v != null ? v as String : null)(json['end']),
        start = ((v) => v != null ? v as String : null)(json['start']),
        state = ((v) => v != null
            ? (v as List).map((v) => MatrixEvent.fromJson(v)).toList()
            : null)(json['state']);
  Map<String, dynamic> toJson() {
    final chunk = this.chunk;
    final end = this.end;
    final start = this.start;
    final state = this.state;
    return {
      if (chunk != null) 'chunk': chunk.map((v) => v.toJson()).toList(),
      if (end != null) 'end': end,
      if (start != null) 'start': start,
      if (state != null) 'state': state.map((v) => v.toJson()).toList(),
    };
  }

  /// A list of room events. The order depends on the `dir` parameter.
  /// For `dir=b` events will be in reverse-chronological order,
  /// for `dir=f` in chronological order, so that events start
  /// at the `from` point.
  List<MatrixEvent>? chunk;

  /// The token the pagination ends at. If `dir=b` this token should
  /// be used again to request even earlier events.
  String? end;

  /// The token the pagination starts from. If `dir=b` this will be
  /// the token supplied in `from`.
  String? start;

  /// A list of state events relevant to showing the `chunk`. For example, if
  /// `lazy_load_members` is enabled in the filter then this may contain
  /// the membership events for the senders of events in the `chunk`.
  ///
  /// Unless `include_redundant_members` is `true`, the server
  /// may remove membership events which would have already been
  /// sent to the client in prior calls to this endpoint, assuming
  /// the membership of those members has not changed.
  List<MatrixEvent>? state;
}

@_NameSource('generated')
enum ReceiptType { mRead }

@_NameSource('spec')
class IncludeEventContext {
  IncludeEventContext({
    this.afterLimit,
    this.beforeLimit,
    this.includeProfile,
  });

  IncludeEventContext.fromJson(Map<String, dynamic> json)
      : afterLimit = ((v) => v != null ? v as int : null)(json['after_limit']),
        beforeLimit =
            ((v) => v != null ? v as int : null)(json['before_limit']),
        includeProfile =
            ((v) => v != null ? v as bool : null)(json['include_profile']);
  Map<String, dynamic> toJson() {
    final afterLimit = this.afterLimit;
    final beforeLimit = this.beforeLimit;
    final includeProfile = this.includeProfile;
    return {
      if (afterLimit != null) 'after_limit': afterLimit,
      if (beforeLimit != null) 'before_limit': beforeLimit,
      if (includeProfile != null) 'include_profile': includeProfile,
    };
  }

  /// How many events after the result are
  /// returned. By default, this is `5`.
  int? afterLimit;

  /// How many events before the result are
  /// returned. By default, this is `5`.
  int? beforeLimit;

  /// Requests that the server returns the
  /// historic profile information for the users
  /// that sent the events that were returned.
  /// By default, this is `false`.
  bool? includeProfile;
}

@_NameSource('spec')
class EventFilter {
  EventFilter({
    this.limit,
    this.notSenders,
    this.notTypes,
    this.senders,
    this.types,
  });

  EventFilter.fromJson(Map<String, dynamic> json)
      : limit = ((v) => v != null ? v as int : null)(json['limit']),
        notSenders = ((v) => v != null
            ? (v as List).map((v) => v as String).toList()
            : null)(json['not_senders']),
        notTypes = ((v) => v != null
            ? (v as List).map((v) => v as String).toList()
            : null)(json['not_types']),
        senders = ((v) => v != null
            ? (v as List).map((v) => v as String).toList()
            : null)(json['senders']),
        types = ((v) => v != null
            ? (v as List).map((v) => v as String).toList()
            : null)(json['types']);
  Map<String, dynamic> toJson() {
    final limit = this.limit;
    final notSenders = this.notSenders;
    final notTypes = this.notTypes;
    final senders = this.senders;
    final types = this.types;
    return {
      if (limit != null) 'limit': limit,
      if (notSenders != null) 'not_senders': notSenders.map((v) => v).toList(),
      if (notTypes != null) 'not_types': notTypes.map((v) => v).toList(),
      if (senders != null) 'senders': senders.map((v) => v).toList(),
      if (types != null) 'types': types.map((v) => v).toList(),
    };
  }

  /// The maximum number of events to return.
  int? limit;

  /// A list of sender IDs to exclude. If this list is absent then no senders are excluded. A matching sender will be excluded even if it is listed in the `'senders'` filter.
  List<String>? notSenders;

  /// A list of event types to exclude. If this list is absent then no event types are excluded. A matching type will be excluded even if it is listed in the `'types'` filter. A '*' can be used as a wildcard to match any sequence of characters.
  List<String>? notTypes;

  /// A list of senders IDs to include. If this list is absent then all senders are included.
  List<String>? senders;

  /// A list of event types to include. If this list is absent then all event types are included. A `'*'` can be used as a wildcard to match any sequence of characters.
  List<String>? types;
}

@_NameSource('spec')
class RoomEventFilter {
  RoomEventFilter({
    this.containsUrl,
    this.includeRedundantMembers,
    this.lazyLoadMembers,
    this.notRooms,
    this.rooms,
  });

  RoomEventFilter.fromJson(Map<String, dynamic> json)
      : containsUrl =
            ((v) => v != null ? v as bool : null)(json['contains_url']),
        includeRedundantMembers = ((v) =>
            v != null ? v as bool : null)(json['include_redundant_members']),
        lazyLoadMembers =
            ((v) => v != null ? v as bool : null)(json['lazy_load_members']),
        notRooms = ((v) => v != null
            ? (v as List).map((v) => v as String).toList()
            : null)(json['not_rooms']),
        rooms = ((v) => v != null
            ? (v as List).map((v) => v as String).toList()
            : null)(json['rooms']);
  Map<String, dynamic> toJson() {
    final containsUrl = this.containsUrl;
    final includeRedundantMembers = this.includeRedundantMembers;
    final lazyLoadMembers = this.lazyLoadMembers;
    final notRooms = this.notRooms;
    final rooms = this.rooms;
    return {
      if (containsUrl != null) 'contains_url': containsUrl,
      if (includeRedundantMembers != null)
        'include_redundant_members': includeRedundantMembers,
      if (lazyLoadMembers != null) 'lazy_load_members': lazyLoadMembers,
      if (notRooms != null) 'not_rooms': notRooms.map((v) => v).toList(),
      if (rooms != null) 'rooms': rooms.map((v) => v).toList(),
    };
  }

  /// If `true`, includes only events with a `url` key in their content. If `false`, excludes those events. If omitted, `url` key is not considered for filtering.
  bool? containsUrl;

  /// If `true`, sends all membership events for all events, even if they have already
  /// been sent to the client. Does not
  /// apply unless `lazy_load_members` is `true`. See
  /// [Lazy-loading room members](https://spec.matrix.org/unstable/client-server-api/#lazy-loading-room-members)
  /// for more information. Defaults to `false`.
  bool? includeRedundantMembers;

  /// If `true`, enables lazy-loading of membership events. See
  /// [Lazy-loading room members](https://spec.matrix.org/unstable/client-server-api/#lazy-loading-room-members)
  /// for more information. Defaults to `false`.
  bool? lazyLoadMembers;

  /// A list of room IDs to exclude. If this list is absent then no rooms are excluded. A matching room will be excluded even if it is listed in the `'rooms'` filter.
  List<String>? notRooms;

  /// A list of room IDs to include. If this list is absent then all rooms are included.
  List<String>? rooms;
}

@_NameSource('rule override generated')
class SearchFilter implements EventFilter, RoomEventFilter {
  SearchFilter({
    this.limit,
    this.notSenders,
    this.notTypes,
    this.senders,
    this.types,
    this.containsUrl,
    this.includeRedundantMembers,
    this.lazyLoadMembers,
    this.notRooms,
    this.rooms,
  });

  SearchFilter.fromJson(Map<String, dynamic> json)
      : limit = ((v) => v != null ? v as int : null)(json['limit']),
        notSenders = ((v) => v != null
            ? (v as List).map((v) => v as String).toList()
            : null)(json['not_senders']),
        notTypes = ((v) => v != null
            ? (v as List).map((v) => v as String).toList()
            : null)(json['not_types']),
        senders = ((v) => v != null
            ? (v as List).map((v) => v as String).toList()
            : null)(json['senders']),
        types = ((v) => v != null
            ? (v as List).map((v) => v as String).toList()
            : null)(json['types']),
        containsUrl =
            ((v) => v != null ? v as bool : null)(json['contains_url']),
        includeRedundantMembers = ((v) =>
            v != null ? v as bool : null)(json['include_redundant_members']),
        lazyLoadMembers =
            ((v) => v != null ? v as bool : null)(json['lazy_load_members']),
        notRooms = ((v) => v != null
            ? (v as List).map((v) => v as String).toList()
            : null)(json['not_rooms']),
        rooms = ((v) => v != null
            ? (v as List).map((v) => v as String).toList()
            : null)(json['rooms']);
  Map<String, dynamic> toJson() {
    final limit = this.limit;
    final notSenders = this.notSenders;
    final notTypes = this.notTypes;
    final senders = this.senders;
    final types = this.types;
    final containsUrl = this.containsUrl;
    final includeRedundantMembers = this.includeRedundantMembers;
    final lazyLoadMembers = this.lazyLoadMembers;
    final notRooms = this.notRooms;
    final rooms = this.rooms;
    return {
      if (limit != null) 'limit': limit,
      if (notSenders != null) 'not_senders': notSenders.map((v) => v).toList(),
      if (notTypes != null) 'not_types': notTypes.map((v) => v).toList(),
      if (senders != null) 'senders': senders.map((v) => v).toList(),
      if (types != null) 'types': types.map((v) => v).toList(),
      if (containsUrl != null) 'contains_url': containsUrl,
      if (includeRedundantMembers != null)
        'include_redundant_members': includeRedundantMembers,
      if (lazyLoadMembers != null) 'lazy_load_members': lazyLoadMembers,
      if (notRooms != null) 'not_rooms': notRooms.map((v) => v).toList(),
      if (rooms != null) 'rooms': rooms.map((v) => v).toList(),
    };
  }

  /// The maximum number of events to return.
  int? limit;

  /// A list of sender IDs to exclude. If this list is absent then no senders are excluded. A matching sender will be excluded even if it is listed in the `'senders'` filter.
  List<String>? notSenders;

  /// A list of event types to exclude. If this list is absent then no event types are excluded. A matching type will be excluded even if it is listed in the `'types'` filter. A '*' can be used as a wildcard to match any sequence of characters.
  List<String>? notTypes;

  /// A list of senders IDs to include. If this list is absent then all senders are included.
  List<String>? senders;

  /// A list of event types to include. If this list is absent then all event types are included. A `'*'` can be used as a wildcard to match any sequence of characters.
  List<String>? types;

  /// If `true`, includes only events with a `url` key in their content. If `false`, excludes those events. If omitted, `url` key is not considered for filtering.
  bool? containsUrl;

  /// If `true`, sends all membership events for all events, even if they have already
  /// been sent to the client. Does not
  /// apply unless `lazy_load_members` is `true`. See
  /// [Lazy-loading room members](https://spec.matrix.org/unstable/client-server-api/#lazy-loading-room-members)
  /// for more information. Defaults to `false`.
  bool? includeRedundantMembers;

  /// If `true`, enables lazy-loading of membership events. See
  /// [Lazy-loading room members](https://spec.matrix.org/unstable/client-server-api/#lazy-loading-room-members)
  /// for more information. Defaults to `false`.
  bool? lazyLoadMembers;

  /// A list of room IDs to exclude. If this list is absent then no rooms are excluded. A matching room will be excluded even if it is listed in the `'rooms'` filter.
  List<String>? notRooms;

  /// A list of room IDs to include. If this list is absent then all rooms are included.
  List<String>? rooms;
}

@_NameSource('rule override generated')
enum GroupKey { roomId, sender }

/// Configuration for group.
@_NameSource('spec')
class Group {
  Group({
    this.key,
  });

  Group.fromJson(Map<String, dynamic> json)
      : key = ((v) => v != null
            ? {'room_id': GroupKey.roomId, 'sender': GroupKey.sender}[v]!
            : null)(json['key']);
  Map<String, dynamic> toJson() {
    final key = this.key;
    return {
      if (key != null)
        'key': {GroupKey.roomId: 'room_id', GroupKey.sender: 'sender'}[key]!,
    };
  }

  /// Key that defines the group.
  GroupKey? key;
}

@_NameSource('spec')
class Groupings {
  Groupings({
    this.groupBy,
  });

  Groupings.fromJson(Map<String, dynamic> json)
      : groupBy = ((v) => v != null
            ? (v as List).map((v) => Group.fromJson(v)).toList()
            : null)(json['group_by']);
  Map<String, dynamic> toJson() {
    final groupBy = this.groupBy;
    return {
      if (groupBy != null) 'group_by': groupBy.map((v) => v.toJson()).toList(),
    };
  }

  /// List of groups to request.
  List<Group>? groupBy;
}

@_NameSource('rule override generated')
enum KeyKind { contentBody, contentName, contentTopic }

@_NameSource('rule override generated')
enum SearchOrder { rank, recent }

@_NameSource('spec')
class RoomEventsCriteria {
  RoomEventsCriteria({
    this.eventContext,
    this.filter,
    this.groupings,
    this.includeState,
    this.keys,
    this.orderBy,
    required this.searchTerm,
  });

  RoomEventsCriteria.fromJson(Map<String, dynamic> json)
      : eventContext = ((v) => v != null
            ? IncludeEventContext.fromJson(v)
            : null)(json['event_context']),
        filter = ((v) =>
            v != null ? SearchFilter.fromJson(v) : null)(json['filter']),
        groupings = ((v) =>
            v != null ? Groupings.fromJson(v) : null)(json['groupings']),
        includeState =
            ((v) => v != null ? v as bool : null)(json['include_state']),
        keys = ((v) => v != null
            ? (v as List)
                .map((v) => {
                      'content.body': KeyKind.contentBody,
                      'content.name': KeyKind.contentName,
                      'content.topic': KeyKind.contentTopic
                    }[v]!)
                .toList()
            : null)(json['keys']),
        orderBy = ((v) => v != null
            ? {'recent': SearchOrder.recent, 'rank': SearchOrder.rank}[v]!
            : null)(json['order_by']),
        searchTerm = json['search_term'] as String;
  Map<String, dynamic> toJson() {
    final eventContext = this.eventContext;
    final filter = this.filter;
    final groupings = this.groupings;
    final includeState = this.includeState;
    final keys = this.keys;
    final orderBy = this.orderBy;
    return {
      if (eventContext != null) 'event_context': eventContext.toJson(),
      if (filter != null) 'filter': filter.toJson(),
      if (groupings != null) 'groupings': groupings.toJson(),
      if (includeState != null) 'include_state': includeState,
      if (keys != null)
        'keys': keys
            .map((v) => {
                  KeyKind.contentBody: 'content.body',
                  KeyKind.contentName: 'content.name',
                  KeyKind.contentTopic: 'content.topic'
                }[v]!)
            .toList(),
      if (orderBy != null)
        'order_by': {
          SearchOrder.recent: 'recent',
          SearchOrder.rank: 'rank'
        }[orderBy]!,
      'search_term': searchTerm,
    };
  }

  /// Configures whether any context for the events
  /// returned are included in the response.
  IncludeEventContext? eventContext;

  /// This takes a [filter](https://spec.matrix.org/unstable/client-server-api/#filtering).
  SearchFilter? filter;

  /// Requests that the server partitions the result set
  /// based on the provided list of keys.
  Groupings? groupings;

  /// Requests the server return the current state for
  /// each room returned.
  bool? includeState;

  /// The keys to search. Defaults to all.
  List<KeyKind>? keys;

  /// The order in which to search for results.
  /// By default, this is `"rank"`.
  SearchOrder? orderBy;

  /// The string to search events for
  String searchTerm;
}

@_NameSource('spec')
class Categories {
  Categories({
    this.roomEvents,
  });

  Categories.fromJson(Map<String, dynamic> json)
      : roomEvents = ((v) => v != null ? RoomEventsCriteria.fromJson(v) : null)(
            json['room_events']);
  Map<String, dynamic> toJson() {
    final roomEvents = this.roomEvents;
    return {
      if (roomEvents != null) 'room_events': roomEvents.toJson(),
    };
  }

  /// Mapping of category name to search criteria.
  RoomEventsCriteria? roomEvents;
}

/// The results for a particular group value.
@_NameSource('spec')
class GroupValue {
  GroupValue({
    this.nextBatch,
    this.order,
    this.results,
  });

  GroupValue.fromJson(Map<String, dynamic> json)
      : nextBatch = ((v) => v != null ? v as String : null)(json['next_batch']),
        order = ((v) => v != null ? v as int : null)(json['order']),
        results = ((v) => v != null
            ? (v as List).map((v) => v as String).toList()
            : null)(json['results']);
  Map<String, dynamic> toJson() {
    final nextBatch = this.nextBatch;
    final order = this.order;
    final results = this.results;
    return {
      if (nextBatch != null) 'next_batch': nextBatch,
      if (order != null) 'order': order,
      if (results != null) 'results': results.map((v) => v).toList(),
    };
  }

  /// Token that can be used to get the next batch
  /// of results in the group, by passing as the
  /// `next_batch` parameter to the next call. If
  /// this field is absent, there are no more
  /// results in this group.
  String? nextBatch;

  /// Key that can be used to order different
  /// groups.
  int? order;

  /// Which results are in this group.
  List<String>? results;
}

@_NameSource('spec')
class UserProfile {
  UserProfile({
    this.avatarUrl,
    this.displayname,
  });

  UserProfile.fromJson(Map<String, dynamic> json)
      : avatarUrl =
            ((v) => v != null ? Uri.parse(v) : null)(json['avatar_url']),
        displayname =
            ((v) => v != null ? v as String : null)(json['displayname']);
  Map<String, dynamic> toJson() {
    final avatarUrl = this.avatarUrl;
    final displayname = this.displayname;
    return {
      if (avatarUrl != null) 'avatar_url': avatarUrl.toString(),
      if (displayname != null) 'displayname': displayname,
    };
  }

  Uri? avatarUrl;

  String? displayname;
}

@_NameSource('rule override spec')
class SearchResultsEventContext {
  SearchResultsEventContext({
    this.end,
    this.eventsAfter,
    this.eventsBefore,
    this.profileInfo,
    this.start,
  });

  SearchResultsEventContext.fromJson(Map<String, dynamic> json)
      : end = ((v) => v != null ? v as String : null)(json['end']),
        eventsAfter = ((v) => v != null
            ? (v as List).map((v) => MatrixEvent.fromJson(v)).toList()
            : null)(json['events_after']),
        eventsBefore = ((v) => v != null
            ? (v as List).map((v) => MatrixEvent.fromJson(v)).toList()
            : null)(json['events_before']),
        profileInfo = ((v) => v != null
            ? (v as Map<String, dynamic>)
                .map((k, v) => MapEntry(k, UserProfile.fromJson(v)))
            : null)(json['profile_info']),
        start = ((v) => v != null ? v as String : null)(json['start']);
  Map<String, dynamic> toJson() {
    final end = this.end;
    final eventsAfter = this.eventsAfter;
    final eventsBefore = this.eventsBefore;
    final profileInfo = this.profileInfo;
    final start = this.start;
    return {
      if (end != null) 'end': end,
      if (eventsAfter != null)
        'events_after': eventsAfter.map((v) => v.toJson()).toList(),
      if (eventsBefore != null)
        'events_before': eventsBefore.map((v) => v.toJson()).toList(),
      if (profileInfo != null)
        'profile_info': profileInfo.map((k, v) => MapEntry(k, v.toJson())),
      if (start != null) 'start': start,
    };
  }

  /// Pagination token for the end of the chunk
  String? end;

  /// Events just after the result.
  List<MatrixEvent>? eventsAfter;

  /// Events just before the result.
  List<MatrixEvent>? eventsBefore;

  /// The historic profile information of the
  /// users that sent the events returned.
  ///
  /// The `string` key is the user ID for which
  /// the profile belongs to.
  Map<String, UserProfile>? profileInfo;

  /// Pagination token for the start of the chunk
  String? start;
}

/// The result object.
@_NameSource('spec')
class Result {
  Result({
    this.context,
    this.rank,
    this.result,
  });

  Result.fromJson(Map<String, dynamic> json)
      : context = ((v) => v != null
            ? SearchResultsEventContext.fromJson(v)
            : null)(json['context']),
        rank = ((v) => v != null ? (v as num).toDouble() : null)(json['rank']),
        result =
            ((v) => v != null ? MatrixEvent.fromJson(v) : null)(json['result']);
  Map<String, dynamic> toJson() {
    final context = this.context;
    final rank = this.rank;
    final result = this.result;
    return {
      if (context != null) 'context': context.toJson(),
      if (rank != null) 'rank': rank,
      if (result != null) 'result': result.toJson(),
    };
  }

  /// Context for result, if requested.
  SearchResultsEventContext? context;

  /// A number that describes how closely this result matches the search. Higher is closer.
  double? rank;

  /// The event that matched.
  MatrixEvent? result;
}

@_NameSource('spec')
class ResultRoomEvents {
  ResultRoomEvents({
    this.count,
    this.groups,
    this.highlights,
    this.nextBatch,
    this.results,
    this.state,
  });

  ResultRoomEvents.fromJson(Map<String, dynamic> json)
      : count = ((v) => v != null ? v as int : null)(json['count']),
        groups = ((v) => v != null
            ? (v as Map<String, dynamic>).map((k, v) => MapEntry(
                k,
                (v as Map<String, dynamic>)
                    .map((k, v) => MapEntry(k, GroupValue.fromJson(v)))))
            : null)(json['groups']),
        highlights = ((v) => v != null
            ? (v as List).map((v) => v as String).toList()
            : null)(json['highlights']),
        nextBatch = ((v) => v != null ? v as String : null)(json['next_batch']),
        results = ((v) => v != null
            ? (v as List).map((v) => Result.fromJson(v)).toList()
            : null)(json['results']),
        state = ((v) => v != null
            ? (v as Map<String, dynamic>).map((k, v) => MapEntry(
                k, (v as List).map((v) => MatrixEvent.fromJson(v)).toList()))
            : null)(json['state']);
  Map<String, dynamic> toJson() {
    final count = this.count;
    final groups = this.groups;
    final highlights = this.highlights;
    final nextBatch = this.nextBatch;
    final results = this.results;
    final state = this.state;
    return {
      if (count != null) 'count': count,
      if (groups != null)
        'groups': groups.map(
            (k, v) => MapEntry(k, v.map((k, v) => MapEntry(k, v.toJson())))),
      if (highlights != null) 'highlights': highlights.map((v) => v).toList(),
      if (nextBatch != null) 'next_batch': nextBatch,
      if (results != null) 'results': results.map((v) => v.toJson()).toList(),
      if (state != null)
        'state':
            state.map((k, v) => MapEntry(k, v.map((v) => v.toJson()).toList())),
    };
  }

  /// An approximate count of the total number of results found.
  int? count;

  /// Any groups that were requested.
  ///
  /// The outer `string` key is the group key requested (eg: `room_id`
  /// or `sender`). The inner `string` key is the grouped value (eg:
  /// a room's ID or a user's ID).
  Map<String, Map<String, GroupValue>>? groups;

  /// List of words which should be highlighted, useful for stemming which may change the query terms.
  List<String>? highlights;

  /// Token that can be used to get the next batch of
  /// results, by passing as the `next_batch` parameter to
  /// the next call. If this field is absent, there are no
  /// more results.
  String? nextBatch;

  /// List of results in the requested order.
  List<Result>? results;

  /// The current state for every room in the results.
  /// This is included if the request had the
  /// `include_state` key set with a value of `true`.
  ///
  /// The `string` key is the room ID for which the `State
  /// Event` array belongs to.
  Map<String, List<MatrixEvent>>? state;
}

@_NameSource('spec')
class ResultCategories {
  ResultCategories({
    this.roomEvents,
  });

  ResultCategories.fromJson(Map<String, dynamic> json)
      : roomEvents = ((v) => v != null ? ResultRoomEvents.fromJson(v) : null)(
            json['room_events']);
  Map<String, dynamic> toJson() {
    final roomEvents = this.roomEvents;
    return {
      if (roomEvents != null) 'room_events': roomEvents.toJson(),
    };
  }

  /// Mapping of category name to search criteria.
  ResultRoomEvents? roomEvents;
}

@_NameSource('rule override spec')
class SearchResults {
  SearchResults({
    required this.searchCategories,
  });

  SearchResults.fromJson(Map<String, dynamic> json)
      : searchCategories = ResultCategories.fromJson(json['search_categories']);
  Map<String, dynamic> toJson() => {
        'search_categories': searchCategories.toJson(),
      };

  /// Describes which categories to search in and their criteria.
  ResultCategories searchCategories;
}

@_NameSource('spec')
class Location {
  Location({
    required this.alias,
    required this.fields,
    required this.protocol,
  });

  Location.fromJson(Map<String, dynamic> json)
      : alias = json['alias'] as String,
        fields = json['fields'] as Map<String, dynamic>,
        protocol = json['protocol'] as String;
  Map<String, dynamic> toJson() => {
        'alias': alias,
        'fields': fields,
        'protocol': protocol,
      };

  /// An alias for a matrix room.
  String alias;

  /// Information used to identify this third party location.
  Map<String, dynamic> fields;

  /// The protocol ID that the third party location is a part of.
  String protocol;
}

/// Definition of valid values for a field.
@_NameSource('spec')
class FieldType {
  FieldType({
    required this.placeholder,
    required this.regexp,
  });

  FieldType.fromJson(Map<String, dynamic> json)
      : placeholder = json['placeholder'] as String,
        regexp = json['regexp'] as String;
  Map<String, dynamic> toJson() => {
        'placeholder': placeholder,
        'regexp': regexp,
      };

  /// An placeholder serving as a valid example of the field value.
  String placeholder;

  /// A regular expression for validation of a field's value. This may be relatively
  /// coarse to verify the value as the application service providing this protocol
  /// may apply additional validation or filtering.
  String regexp;
}

@_NameSource('spec')
class ProtocolInstance {
  ProtocolInstance({
    required this.desc,
    required this.fields,
    this.icon,
    required this.networkId,
  });

  ProtocolInstance.fromJson(Map<String, dynamic> json)
      : desc = json['desc'] as String,
        fields = json['fields'] as Map<String, dynamic>,
        icon = ((v) => v != null ? v as String : null)(json['icon']),
        networkId = json['network_id'] as String;
  Map<String, dynamic> toJson() {
    final icon = this.icon;
    return {
      'desc': desc,
      'fields': fields,
      if (icon != null) 'icon': icon,
      'network_id': networkId,
    };
  }

  /// A human-readable description for the protocol, such as the name.
  String desc;

  /// Preset values for `fields` the client may use to search by.
  Map<String, dynamic> fields;

  /// An optional content URI representing the protocol. Overrides the one provided
  /// at the higher level Protocol object.
  String? icon;

  /// A unique identifier across all instances.
  String networkId;
}

@_NameSource('spec')
class Protocol {
  Protocol({
    required this.fieldTypes,
    required this.icon,
    required this.instances,
    required this.locationFields,
    required this.userFields,
  });

  Protocol.fromJson(Map<String, dynamic> json)
      : fieldTypes = (json['field_types'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, FieldType.fromJson(v))),
        icon = json['icon'] as String,
        instances = (json['instances'] as List)
            .map((v) => ProtocolInstance.fromJson(v))
            .toList(),
        locationFields =
            (json['location_fields'] as List).map((v) => v as String).toList(),
        userFields =
            (json['user_fields'] as List).map((v) => v as String).toList();
  Map<String, dynamic> toJson() => {
        'field_types': fieldTypes.map((k, v) => MapEntry(k, v.toJson())),
        'icon': icon,
        'instances': instances.map((v) => v.toJson()).toList(),
        'location_fields': locationFields.map((v) => v).toList(),
        'user_fields': userFields.map((v) => v).toList(),
      };

  /// The type definitions for the fields defined in the `user_fields` and
  /// `location_fields`. Each entry in those arrays MUST have an entry here. The
  /// `string` key for this object is field name itself.
  ///
  /// May be an empty object if no fields are defined.
  Map<String, FieldType> fieldTypes;

  /// A content URI representing an icon for the third party protocol.
  String icon;

  /// A list of objects representing independent instances of configuration.
  /// For example, multiple networks on IRC if multiple are provided by the
  /// same application service.
  List<ProtocolInstance> instances;

  /// Fields which may be used to identify a third party location. These should be
  /// ordered to suggest the way that entities may be grouped, where higher
  /// groupings are ordered first. For example, the name of a network should be
  /// searched before the name of a channel.
  List<String> locationFields;

  /// Fields which may be used to identify a third party user. These should be
  /// ordered to suggest the way that entities may be grouped, where higher
  /// groupings are ordered first. For example, the name of a network should be
  /// searched before the nickname of a user.
  List<String> userFields;
}

@_NameSource('rule override spec')
class ThirdPartyUser {
  ThirdPartyUser({
    required this.fields,
    required this.protocol,
    required this.userid,
  });

  ThirdPartyUser.fromJson(Map<String, dynamic> json)
      : fields = json['fields'] as Map<String, dynamic>,
        protocol = json['protocol'] as String,
        userid = json['userid'] as String;
  Map<String, dynamic> toJson() => {
        'fields': fields,
        'protocol': protocol,
        'userid': userid,
      };

  /// Information used to identify this third party location.
  Map<String, dynamic> fields;

  /// The protocol ID that the third party location is a part of.
  String protocol;

  /// A Matrix User ID represting a third party user.
  String userid;
}

@_NameSource('generated')
enum EventFormat { client, federation }

@_NameSource('rule override generated')
class StateFilter implements EventFilter, RoomEventFilter {
  StateFilter({
    this.limit,
    this.notSenders,
    this.notTypes,
    this.senders,
    this.types,
    this.containsUrl,
    this.includeRedundantMembers,
    this.lazyLoadMembers,
    this.notRooms,
    this.rooms,
  });

  StateFilter.fromJson(Map<String, dynamic> json)
      : limit = ((v) => v != null ? v as int : null)(json['limit']),
        notSenders = ((v) => v != null
            ? (v as List).map((v) => v as String).toList()
            : null)(json['not_senders']),
        notTypes = ((v) => v != null
            ? (v as List).map((v) => v as String).toList()
            : null)(json['not_types']),
        senders = ((v) => v != null
            ? (v as List).map((v) => v as String).toList()
            : null)(json['senders']),
        types = ((v) => v != null
            ? (v as List).map((v) => v as String).toList()
            : null)(json['types']),
        containsUrl =
            ((v) => v != null ? v as bool : null)(json['contains_url']),
        includeRedundantMembers = ((v) =>
            v != null ? v as bool : null)(json['include_redundant_members']),
        lazyLoadMembers =
            ((v) => v != null ? v as bool : null)(json['lazy_load_members']),
        notRooms = ((v) => v != null
            ? (v as List).map((v) => v as String).toList()
            : null)(json['not_rooms']),
        rooms = ((v) => v != null
            ? (v as List).map((v) => v as String).toList()
            : null)(json['rooms']);
  Map<String, dynamic> toJson() {
    final limit = this.limit;
    final notSenders = this.notSenders;
    final notTypes = this.notTypes;
    final senders = this.senders;
    final types = this.types;
    final containsUrl = this.containsUrl;
    final includeRedundantMembers = this.includeRedundantMembers;
    final lazyLoadMembers = this.lazyLoadMembers;
    final notRooms = this.notRooms;
    final rooms = this.rooms;
    return {
      if (limit != null) 'limit': limit,
      if (notSenders != null) 'not_senders': notSenders.map((v) => v).toList(),
      if (notTypes != null) 'not_types': notTypes.map((v) => v).toList(),
      if (senders != null) 'senders': senders.map((v) => v).toList(),
      if (types != null) 'types': types.map((v) => v).toList(),
      if (containsUrl != null) 'contains_url': containsUrl,
      if (includeRedundantMembers != null)
        'include_redundant_members': includeRedundantMembers,
      if (lazyLoadMembers != null) 'lazy_load_members': lazyLoadMembers,
      if (notRooms != null) 'not_rooms': notRooms.map((v) => v).toList(),
      if (rooms != null) 'rooms': rooms.map((v) => v).toList(),
    };
  }

  /// The maximum number of events to return.
  int? limit;

  /// A list of sender IDs to exclude. If this list is absent then no senders are excluded. A matching sender will be excluded even if it is listed in the `'senders'` filter.
  List<String>? notSenders;

  /// A list of event types to exclude. If this list is absent then no event types are excluded. A matching type will be excluded even if it is listed in the `'types'` filter. A '*' can be used as a wildcard to match any sequence of characters.
  List<String>? notTypes;

  /// A list of senders IDs to include. If this list is absent then all senders are included.
  List<String>? senders;

  /// A list of event types to include. If this list is absent then all event types are included. A `'*'` can be used as a wildcard to match any sequence of characters.
  List<String>? types;

  /// If `true`, includes only events with a `url` key in their content. If `false`, excludes those events. If omitted, `url` key is not considered for filtering.
  bool? containsUrl;

  /// If `true`, sends all membership events for all events, even if they have already
  /// been sent to the client. Does not
  /// apply unless `lazy_load_members` is `true`. See
  /// [Lazy-loading room members](https://spec.matrix.org/unstable/client-server-api/#lazy-loading-room-members)
  /// for more information. Defaults to `false`.
  bool? includeRedundantMembers;

  /// If `true`, enables lazy-loading of membership events. See
  /// [Lazy-loading room members](https://spec.matrix.org/unstable/client-server-api/#lazy-loading-room-members)
  /// for more information. Defaults to `false`.
  bool? lazyLoadMembers;

  /// A list of room IDs to exclude. If this list is absent then no rooms are excluded. A matching room will be excluded even if it is listed in the `'rooms'` filter.
  List<String>? notRooms;

  /// A list of room IDs to include. If this list is absent then all rooms are included.
  List<String>? rooms;
}

@_NameSource('spec')
class RoomFilter {
  RoomFilter({
    this.accountData,
    this.ephemeral,
    this.includeLeave,
    this.notRooms,
    this.rooms,
    this.state,
    this.timeline,
  });

  RoomFilter.fromJson(Map<String, dynamic> json)
      : accountData = ((v) =>
            v != null ? StateFilter.fromJson(v) : null)(json['account_data']),
        ephemeral = ((v) =>
            v != null ? StateFilter.fromJson(v) : null)(json['ephemeral']),
        includeLeave =
            ((v) => v != null ? v as bool : null)(json['include_leave']),
        notRooms = ((v) => v != null
            ? (v as List).map((v) => v as String).toList()
            : null)(json['not_rooms']),
        rooms = ((v) => v != null
            ? (v as List).map((v) => v as String).toList()
            : null)(json['rooms']),
        state =
            ((v) => v != null ? StateFilter.fromJson(v) : null)(json['state']),
        timeline = ((v) =>
            v != null ? StateFilter.fromJson(v) : null)(json['timeline']);
  Map<String, dynamic> toJson() {
    final accountData = this.accountData;
    final ephemeral = this.ephemeral;
    final includeLeave = this.includeLeave;
    final notRooms = this.notRooms;
    final rooms = this.rooms;
    final state = this.state;
    final timeline = this.timeline;
    return {
      if (accountData != null) 'account_data': accountData.toJson(),
      if (ephemeral != null) 'ephemeral': ephemeral.toJson(),
      if (includeLeave != null) 'include_leave': includeLeave,
      if (notRooms != null) 'not_rooms': notRooms.map((v) => v).toList(),
      if (rooms != null) 'rooms': rooms.map((v) => v).toList(),
      if (state != null) 'state': state.toJson(),
      if (timeline != null) 'timeline': timeline.toJson(),
    };
  }

  /// The per user account data to include for rooms.
  StateFilter? accountData;

  /// The events that aren't recorded in the room history, e.g. typing and receipts, to include for rooms.
  StateFilter? ephemeral;

  /// Include rooms that the user has left in the sync, default false
  bool? includeLeave;

  /// A list of room IDs to exclude. If this list is absent then no rooms are excluded. A matching room will be excluded even if it is listed in the `'rooms'` filter. This filter is applied before the filters in `ephemeral`, `state`, `timeline` or `account_data`
  List<String>? notRooms;

  /// A list of room IDs to include. If this list is absent then all rooms are included. This filter is applied before the filters in `ephemeral`, `state`, `timeline` or `account_data`
  List<String>? rooms;

  /// The state events to include for rooms.
  StateFilter? state;

  /// The message and state update events to include for rooms.
  StateFilter? timeline;
}

@_NameSource('spec')
class Filter {
  Filter({
    this.accountData,
    this.eventFields,
    this.eventFormat,
    this.presence,
    this.room,
  });

  Filter.fromJson(Map<String, dynamic> json)
      : accountData = ((v) =>
            v != null ? EventFilter.fromJson(v) : null)(json['account_data']),
        eventFields = ((v) => v != null
            ? (v as List).map((v) => v as String).toList()
            : null)(json['event_fields']),
        eventFormat = ((v) => v != null
            ? {
                'client': EventFormat.client,
                'federation': EventFormat.federation
              }[v]!
            : null)(json['event_format']),
        presence = ((v) =>
            v != null ? EventFilter.fromJson(v) : null)(json['presence']),
        room = ((v) => v != null ? RoomFilter.fromJson(v) : null)(json['room']);
  Map<String, dynamic> toJson() {
    final accountData = this.accountData;
    final eventFields = this.eventFields;
    final eventFormat = this.eventFormat;
    final presence = this.presence;
    final room = this.room;
    return {
      if (accountData != null) 'account_data': accountData.toJson(),
      if (eventFields != null)
        'event_fields': eventFields.map((v) => v).toList(),
      if (eventFormat != null)
        'event_format': {
          EventFormat.client: 'client',
          EventFormat.federation: 'federation'
        }[eventFormat]!,
      if (presence != null) 'presence': presence.toJson(),
      if (room != null) 'room': room.toJson(),
    };
  }

  /// The user account data that isn't associated with rooms to include.
  EventFilter? accountData;

  /// List of event fields to include. If this list is absent then all fields are included. The entries may include '.' characters to indicate sub-fields. So ['content.body'] will include the 'body' field of the 'content' object. A literal '.' character in a field name may be escaped using a '\\'. A server may include more fields than were requested.
  List<String>? eventFields;

  /// The format to use for events. 'client' will return the events in a format suitable for clients. 'federation' will return the raw event as received over federation. The default is 'client'.
  EventFormat? eventFormat;

  /// The presence updates to include.
  EventFilter? presence;

  /// Filters to be applied to room data.
  RoomFilter? room;
}

@_NameSource('spec')
class OpenIdCredentials {
  OpenIdCredentials({
    required this.accessToken,
    required this.expiresIn,
    required this.matrixServerName,
    required this.tokenType,
  });

  OpenIdCredentials.fromJson(Map<String, dynamic> json)
      : accessToken = json['access_token'] as String,
        expiresIn = json['expires_in'] as int,
        matrixServerName = json['matrix_server_name'] as String,
        tokenType = json['token_type'] as String;
  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'expires_in': expiresIn,
        'matrix_server_name': matrixServerName,
        'token_type': tokenType,
      };

  /// An access token the consumer may use to verify the identity of
  /// the person who generated the token. This is given to the federation
  /// API `GET /openid/userinfo` to verify the user's identity.
  String accessToken;

  /// The number of seconds before this token expires and a new one must
  /// be generated.
  int expiresIn;

  /// The homeserver domain the consumer should use when attempting to
  /// verify the user's identity.
  String matrixServerName;

  /// The string `Bearer`.
  String tokenType;
}

@_NameSource('spec')
class Tag {
  Tag({
    this.order,
    this.additionalProperties = const {},
  });

  Tag.fromJson(Map<String, dynamic> json)
      : order =
            ((v) => v != null ? (v as num).toDouble() : null)(json['order']),
        additionalProperties = Map.fromEntries(json.entries
            .where((e) => !['order'].contains(e.key))
            .map((e) => MapEntry(e.key, e.value as dynamic)));
  Map<String, dynamic> toJson() {
    final order = this.order;
    return {
      ...additionalProperties,
      if (order != null) 'order': order,
    };
  }

  /// A number in a range `[0,1]` describing a relative
  /// position of the room under the given tag.
  double? order;

  Map<String, dynamic> additionalProperties;
}

@_NameSource('rule override spec')
class Profile {
  Profile({
    this.avatarUrl,
    this.displayName,
    required this.userId,
  });

  Profile.fromJson(Map<String, dynamic> json)
      : avatarUrl =
            ((v) => v != null ? Uri.parse(v) : null)(json['avatar_url']),
        displayName =
            ((v) => v != null ? v as String : null)(json['display_name']),
        userId = json['user_id'] as String;
  Map<String, dynamic> toJson() {
    final avatarUrl = this.avatarUrl;
    final displayName = this.displayName;
    return {
      if (avatarUrl != null) 'avatar_url': avatarUrl.toString(),
      if (displayName != null) 'display_name': displayName,
      'user_id': userId,
    };
  }

  /// The avatar url, as an MXC, if one exists.
  Uri? avatarUrl;

  /// The display name of the user, if one exists.
  String? displayName;

  /// The user's matrix user ID.
  String userId;
}

@_NameSource('generated')
class SearchUserDirectoryResponse {
  SearchUserDirectoryResponse({
    required this.limited,
    required this.results,
  });

  SearchUserDirectoryResponse.fromJson(Map<String, dynamic> json)
      : limited = json['limited'] as bool,
        results =
            (json['results'] as List).map((v) => Profile.fromJson(v)).toList();
  Map<String, dynamic> toJson() => {
        'limited': limited,
        'results': results.map((v) => v.toJson()).toList(),
      };

  /// Indicates if the result list has been truncated by the limit.
  bool limited;

  /// Ordered by rank and then whether or not profile info is available.
  List<Profile> results;
}

@_NameSource('rule override generated')
class TurnServerCredentials {
  TurnServerCredentials({
    required this.password,
    required this.ttl,
    required this.uris,
    required this.username,
  });

  TurnServerCredentials.fromJson(Map<String, dynamic> json)
      : password = json['password'] as String,
        ttl = json['ttl'] as int,
        uris = (json['uris'] as List).map((v) => v as String).toList(),
        username = json['username'] as String;
  Map<String, dynamic> toJson() => {
        'password': password,
        'ttl': ttl,
        'uris': uris.map((v) => v).toList(),
        'username': username,
      };

  /// The password to use.
  String password;

  /// The time-to-live in seconds
  int ttl;

  /// A list of TURN URIs
  List<String> uris;

  /// The username to use.
  String username;
}

@_NameSource('generated')
class GetVersionsResponse {
  GetVersionsResponse({
    this.unstableFeatures,
    required this.versions,
  });

  GetVersionsResponse.fromJson(Map<String, dynamic> json)
      : unstableFeatures = ((v) => v != null
            ? (v as Map<String, dynamic>).map((k, v) => MapEntry(k, v as bool))
            : null)(json['unstable_features']),
        versions = (json['versions'] as List).map((v) => v as String).toList();
  Map<String, dynamic> toJson() {
    final unstableFeatures = this.unstableFeatures;
    return {
      if (unstableFeatures != null)
        'unstable_features': unstableFeatures.map((k, v) => MapEntry(k, v)),
      'versions': versions.map((v) => v).toList(),
    };
  }

  /// Experimental features the server supports. Features not listed here,
  /// or the lack of this property all together, indicate that a feature is
  /// not supported.
  Map<String, bool>? unstableFeatures;

  /// The supported versions.
  List<String> versions;
}

@_NameSource('rule override generated')
class ServerConfig {
  ServerConfig({
    this.mUploadSize,
  });

  ServerConfig.fromJson(Map<String, dynamic> json)
      : mUploadSize =
            ((v) => v != null ? v as int : null)(json['m.upload.size']);
  Map<String, dynamic> toJson() {
    final mUploadSize = this.mUploadSize;
    return {
      if (mUploadSize != null) 'm.upload.size': mUploadSize,
    };
  }

  /// The maximum size an upload can be in bytes.
  /// Clients SHOULD use this as a guide when uploading content.
  /// If not listed or null, the size limit should be treated as unknown.
  int? mUploadSize;
}

@_NameSource('generated')
class GetUrlPreviewResponse {
  GetUrlPreviewResponse({
    this.matrixImageSize,
    this.ogImage,
  });

  GetUrlPreviewResponse.fromJson(Map<String, dynamic> json)
      : matrixImageSize =
            ((v) => v != null ? v as int : null)(json['matrix:image:size']),
        ogImage = ((v) => v != null ? Uri.parse(v) : null)(json['og:image']);
  Map<String, dynamic> toJson() {
    final matrixImageSize = this.matrixImageSize;
    final ogImage = this.ogImage;
    return {
      if (matrixImageSize != null) 'matrix:image:size': matrixImageSize,
      if (ogImage != null) 'og:image': ogImage.toString(),
    };
  }

  /// The byte-size of the image. Omitted if there is no image attached.
  int? matrixImageSize;

  /// An [MXC URI](https://spec.matrix.org/unstable/client-server-api/#matrix-content-mxc-uris) to the image. Omitted if there is no image.
  Uri? ogImage;
}

@_NameSource('generated')
enum Method { crop, scale }
