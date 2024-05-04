import 'dart:typed_data';

import 'package:meta/meta.dart';

/// {@template command}
/// Command sent from a client to a server.
///
/// Server will
/// only take the first non-null request out of these and may return an error
/// if client passed more than one request.
/// {@category Command}
/// {@endtemplate}
@immutable
sealed class SpinifyCommand implements Comparable<SpinifyCommand> {
  /// {@macro command}
  const SpinifyCommand({
    required this.id,
    required this.timestamp,
  });

  /// ID of command to let client match replies to commands.
  final int id;

  /// Command type.
  abstract final String type;

  /// Timestamp of command.
  final DateTime timestamp;

  @override
  int compareTo(SpinifyCommand other) =>
      switch (timestamp.compareTo(other.timestamp)) {
        0 => id.compareTo(other.id),
        int result => result,
      };
  @override
  int get hashCode => id ^ type.hashCode ^ timestamp.microsecondsSinceEpoch;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpinifyCommand &&
          id == other.id &&
          type == other.type &&
          timestamp == other.timestamp;

  @override
  String toString() => '$type{id: $id}';
}

/// {@macro command}
final class SpinifyConnectRequest extends SpinifyCommand {
  /// {@macro command}
  const SpinifyConnectRequest({
    required super.id,
    required super.timestamp,
    required this.token,
    required this.data,
    required this.subs,
    required this.name,
    required this.version,
  });

  @override
  String get type => 'ConnectRequest';

  /// Token to authenticate.
  final String? token;

  /// Data to send.
  final List<int>? data;

  /// Subscriptions to subscribe.
  final Map<String, SpinifySubscribeRequest>? subs;

  /// Name of client.
  final String name;

  /// Version of client.
  final String version;
}

/// {@macro command}
final class SpinifySubscribeRequest extends SpinifyCommand {
  /// {@macro command}
  const SpinifySubscribeRequest({
    required super.id,
    required super.timestamp,
    required this.channel,
    required this.token,
    required this.recover,
    required this.epoch,
    required this.offset,
    required this.data,
    required this.positioned,
    required this.recoverable,
    required this.joinLeave,
  });

  @override
  String get type => 'SubscribeRequest';

  /// Channel to subscribe.
  final String channel;

  /// Subscription token and callback to get
  /// subscription token upon expiration
  final String? token;

  /// Option to ask server to make subscription recoverable
  final bool? recover;

  /// Epoch to start subscription from
  final String? epoch;

  /// Offset to start subscription from
  final int? offset;

  /// Subscription data
  /// (attached to every subscribe/resubscribe request)
  final Uint8List? data;

  /// Option to ask server to make subscription positioned
  /// (if not forced by a server)
  final bool? positioned;

  /// Option to ask server to make subscription recoverable
  /// (if not forced by a server)
  final bool? recoverable;

  /// Option to ask server to push Join/Leave messages
  /// (if not forced by a server)
  final bool? joinLeave;
}

/// {@macro command}
final class SpinifyUnsubscribeRequest extends SpinifyCommand {
  /// {@macro command}
  const SpinifyUnsubscribeRequest({
    required super.id,
    required super.timestamp,
  });

  @override
  String get type => 'UnsubscribeRequest';
}

/// {@macro command}
final class SpinifyPublishRequest extends SpinifyCommand {
  /// {@macro command}
  const SpinifyPublishRequest({
    required super.id,
    required super.timestamp,
  });

  @override
  String get type => 'PublishRequest';
}

/// {@macro command}
final class SpinifyPresenceRequest extends SpinifyCommand {
  /// {@macro command}
  const SpinifyPresenceRequest({
    required super.id,
    required super.timestamp,
  });

  @override
  String get type => 'PresenceRequest';
}

/// {@macro command}
final class SpinifyPresenceStatsRequest extends SpinifyCommand {
  /// {@macro command}
  const SpinifyPresenceStatsRequest({
    required super.id,
    required super.timestamp,
  });

  @override
  String get type => 'PresenceStatsRequest';
}

/// {@macro command}
final class SpinifyHistoryRequest extends SpinifyCommand {
  /// {@macro command}
  const SpinifyHistoryRequest({
    required super.id,
    required super.timestamp,
  });

  @override
  String get type => 'HistoryRequest';
}

/// {@macro command}
final class SpinifyPingRequest extends SpinifyCommand {
  /// {@macro command}
  const SpinifyPingRequest({
    required super.id,
    required super.timestamp,
  });

  @override
  String get type => 'PingRequest';
}

/// {@macro command}
final class SpinifySendRequest extends SpinifyCommand {
  /// {@macro command}
  const SpinifySendRequest({
    required super.id,
    required super.timestamp,
  });

  @override
  String get type => 'SendRequest';
}

/// {@macro command}
final class SpinifyRPCRequest extends SpinifyCommand {
  /// {@macro command}
  const SpinifyRPCRequest({
    required super.id,
    required super.timestamp,
  });

  @override
  String get type => 'RPCRequest';
}

/// {@macro command}
final class SpinifyRefreshRequest extends SpinifyCommand {
  /// {@macro command}
  const SpinifyRefreshRequest({
    required super.id,
    required super.timestamp,
  });

  @override
  String get type => 'RefreshRequest';
}

/// {@macro command}
final class SpinifySubRefreshRequest extends SpinifyCommand {
  /// {@macro command}
  const SpinifySubRefreshRequest({
    required super.id,
    required super.timestamp,
  });

  @override
  String get type => 'SubRefreshRequest';
}
