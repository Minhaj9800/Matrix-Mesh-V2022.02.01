# Matrix SDK

Matrix (matrix.org) SDK written in dart.

## Native libraries

For E2EE, libolm must be provided.

Additionally, OpenSSL (libcrypto) must be provided on native platforms for E2EE.

For flutter apps you can easily import it with the [flutter_olm](https://pub.dev/packages/flutter_olm) and the [flutter_openssl_crypto](https://pub.dev/packages/flutter_openssl_crypto) packages.

## How to use this

1. Import the sdk

```yaml
  matrix: <latest-version>
  # Optional:
  flutter_olm: <latest-version>
  flutter_openssl_crypto: <latest-version>
```

```dart
import 'package:matrix/matrix.dart';
```

2. Create a new client:

```dart
final client = Client("HappyChat");
```

The SDK works better with a database. Otherwise it has no persistence. For this you need to provide a databaseBuilder like this:

```dart
final client = Client(
  "HappyChat",
  databaseBuilder: (Client client) async {
    await Hive.init('/path/to/your/storage');
    final db = FamedlySdkHiveDatabase(client.clientName);
    await db.open();
    return db;
  },
);
```

3. Connect to a Matrix Homeserver and listen to the streams:

```dart
client.onLoginStateChanged.stream.listen((bool loginState){ 
  print("LoginState: ${loginState.toString()}");
});

client.onEvent.stream.listen((EventUpdate eventUpdate){ 
  print("New event update!");
});

client.onRoomUpdate.stream.listen((RoomUpdate eventUpdate){ 
  print("New room update!");
});

await client.checkHomeserver("https://yourhomeserver.abc");
await client.login(
  identifier: AuthenticationUserIdentifier(user: 'alice'),
  password: '123456',
);
```

4. Send a message to a Room:

```dart
await client.getRoomById('your_room_id').sendTextEvent('Hello world');
```
