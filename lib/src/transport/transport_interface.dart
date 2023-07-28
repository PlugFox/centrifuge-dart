import 'dart:async';

import 'package:centrifuge_dart/src/client/state.dart';
import 'package:centrifuge_dart/src/model/stream_position.dart';
import 'package:centrifuge_dart/src/subscription/subcibed_on_channel.dart';
import 'package:centrifuge_dart/src/subscription/subscription_config.dart';
import 'package:meta/meta.dart';

/// Class responsible for sending and receiving data from the server.
/// {@nodoc}
@internal
abstract interface class ICentrifugeTransport {
  /// State of client.
  /// {@nodoc}
  CentrifugeState get state;

  /// Stream of client states.
  /// {@nodoc}
  abstract final Stream<CentrifugeState> states;

  /// Connect to the server.
  /// [url] is a URL of endpoint.
  /// {@nodoc}
  Future<void> connect(String url);

  /// Send asynchronous message to a server. This method makes sense
  /// only when using Centrifuge library for Go on a server side. In Centrifuge
  /// asynchronous message handler does not exist.
  Future<void> sendAsyncMessage(List<int> data);

  /// Subscribe on channel with optional [since] position.
  Future<SubcibedOnChannel> subscribe(
    String channel,
    CentrifugeSubscriptionConfig config,
    CentrifugeStreamPosition? since,
  );

  /// Disconnect from the server.
  /// e.g. code: 0, reason: 'disconnect called'
  /// {@nodoc}
  Future<void> disconnect(int code, String reason);

  /// Permanent close connection to the server and
  /// free all allocated resources.
  /// {@nodoc}
  Future<void> close();
}
