import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:meta/meta.dart';
import 'package:protobuf/protobuf.dart' as pb;

import '../spinify.dart';
import 'protobuf/client.pb.dart' as pb;
import 'protobuf/protobuf_codec.dart';

/// Create a WebSocket Protocol Buffers transport.
@internal
Future<ISpinifyTransport> $create$WS$PB$Transport({
  /// URL for the connection
  required String url,

  /// Spinify client configuration
  required SpinifyConfig config,

  /// Metrics
  required SpinifyMetrics$Mutable metrics,

  /// Callback for reply messages
  required void Function(SpinifyReply reply) onReply,

  /// Callback for disconnect event
  required void Function() onDisconnect,
}) async {
  // ignore: close_sinks
  final socket = await io.WebSocket.connect(
    url,
    headers: config.headers,
    protocols: <String>{'centrifuge-protobuf'},
  );
  final transport = SpinifyTransport$WS$PB$VM(
    socket,
    config,
    metrics,
    onReply,
    onDisconnect,
  );
  // 0	CONNECTING	Socket has been created. The connection is not yet open.
  // 1	OPEN	The connection is open and ready to communicate.
  // 2	CLOSING	The connection is in the process of closing.
  // 3	CLOSED	The connection is closed or couldn't be opened.
  assert(socket.readyState == io.WebSocket.open, 'Socket is not open');
  return transport;
}

/// Create a WebSocket Protocol Buffers transport.
@internal
final class SpinifyTransport$WS$PB$VM implements ISpinifyTransport {
  SpinifyTransport$WS$PB$VM(
    this._socket,
    SpinifyConfig config,
    this._metrics,
    this._onReply,
    this._onDisconnect,
  )   : _logger = config.logger,
        _encoder = switch (config.logger) {
          null => const ProtobufCommandEncoder(),
          _ => ProtobufCommandEncoder(config.logger),
        },
        _decoder = switch (config.logger) {
          null => const ProtobufReplyDecoder(),
          _ => ProtobufReplyDecoder(config.logger),
        } {
    _subscription = _socket.listen(
      _onData,
      cancelOnError: false,
      onDone: _onDone,
    );
  }

  final io.WebSocket _socket;
  final Converter<SpinifyCommand, pb.Command> _encoder;
  final Converter<pb.Reply, SpinifyReply> _decoder;
  final SpinifyLogger? _logger;
  late final StreamSubscription<dynamic> _subscription;

  /// Metrics
  final SpinifyMetrics$Mutable _metrics;

  /// Callback for reply messages
  final void Function(SpinifyReply reply) _onReply;

  /// Callback for disconnect event
  final void Function() _onDisconnect;

  void _onData(Object? bytes) {
    if (bytes is! List<int> || bytes.isEmpty) {
      assert(false, 'Data is not byte array');
      return;
    }
    _metrics
      ..bytesReceived += BigInt.from(bytes.length)
      ..messagesReceived += BigInt.one;
    final reader = pb.CodedBufferReader(bytes);
    while (!reader.isAtEnd()) {
      try {
        final message = pb.Reply();
        reader.readMessage(message, pb.ExtensionRegistry.EMPTY);
        final reply = _decoder.convert(message);
        _onReply.call(reply);
        _logger?.call(
          const SpinifyLogLevel.transport(),
          'transport_on_reply',
          'Reply ${reply.type}{id: ${reply.id}} received',
          <String, Object?>{
            'protocol': 'protobuf',
            'transport': 'websocket',
            'bytes': bytes,
            'length': bytes.length,
            'reply': reply,
            'protobuf': message,
          },
        );
      } on Object catch (error, stackTrace) {
        _logger?.call(
          const SpinifyLogLevel.error(),
          'transport_on_reply_error',
          'Error reading reply message',
          <String, Object?>{
            'protocol': 'protobuf',
            'transport': 'websocket',
            'bytes': bytes,
            'error': error,
            'stackTrace': stackTrace,
          },
        );
        assert(false, 'Error reading message: $error');
        continue;
      }
    }
  }

  @override
  Future<void> send(SpinifyCommand command) async {
    try {
      final message = _encoder.convert(command);
      final commandData = message.writeToBuffer();
      final length = commandData.lengthInBytes;
      final writer = pb.CodedBufferWriter()
        ..writeInt32NoTag(length); //..writeRawBytes(commandData);
      final bytes = writer.toBuffer() + commandData;
      _socket.add(bytes);
      _metrics
        ..bytesSent += BigInt.from(bytes.length)
        ..messagesSent += BigInt.one;
      _logger?.call(
        const SpinifyLogLevel.transport(),
        'transport_send',
        'Command ${command.type}{id: ${command.id}} sent',
        <String, Object?>{
          'protocol': 'protobuf',
          'transport': 'websocket',
          'command': command,
          'protobuf': message,
          'length': bytes.length,
          'bytes': bytes,
        },
      );
    } on Object catch (error, stackTrace) {
      _logger?.call(
        const SpinifyLogLevel.error(),
        'transport_send_error',
        'Error sending command ${command.type}{id: ${command.id}}',
        <String, Object?>{
          'protocol': 'protobuf',
          'transport': 'websocket',
          'command': command,
          'error': error,
          'stackTrace': stackTrace,
        },
      );
      rethrow;
    }
  }

  void _onDone() {
    final timestamp = DateTime.now();
    int? code;
    String? reason;
    var reconnect = true;
    if (_socket
        case io.WebSocket(
          :int closeCode,
          :String? closeReason,
        ) when closeCode > 0) {
      switch (closeCode) {
        case 1009:
          // reconnect is true by default
          code = 3; // disconnectCodeMessageSizeLimit;
          reason = 'message size limit exceeded';
          reconnect = true;
        case < 3000:
          // We expose codes defined by Centrifuge protocol,
          // hiding details about transport-specific error codes.
          // We may have extra optional transportCode field in the future.
          // reconnect is true by default
          code = 1; // connectingCodeTransportClosed;
          reason = closeReason;
          reconnect = true;
        case >= 3000 && <= 3499:
          // reconnect is true by default
          code = closeCode;
          reason = closeReason;
          reconnect = true;
        case >= 3500 && <= 3999:
          // application terminal codes
          code = closeCode;
          reason = closeReason ?? 'application terminal code';
          reconnect = false;
        case >= 4000 && <= 4499:
          // custom disconnect codes
          // reconnect is true by default
          code = closeCode;
          reason = closeReason;
          reconnect = true;
        case >= 4500 && <= 4999:
          // custom disconnect codes
          // application terminal codes
          code = closeCode;
          reason = closeReason ?? 'application terminal code';
          reconnect = false;
        case >= 5000:
          // reconnect is true by default
          code = closeCode;
          reason = closeReason;
          reconnect = true;
        default:
          code = closeCode;
          reason = closeReason;
          reconnect = false;
      }
    }
    code ??= 1; // connectingCodeTransportClosed
    reason ??= 'transport closed';
    _onReply.call(
      SpinifyPush(
        timestamp: timestamp,
        event: SpinifyDisconnect(
          channel: '',
          timestamp: timestamp,
          code: code,
          reason: reason,
          reconnect: reconnect,
        ),
      ),
    );
    _onDisconnect.call();
    _logger?.call(
      const SpinifyLogLevel.transport(),
      'transport_disconnect',
      'Transport disconnected '
          '${reconnect ? 'temporarily' : 'permanently'} '
          'with reason: $reason',
      <String, Object?>{
        'code': code,
        'reason': reason,
        'reconnect': reconnect,
      },
    );
  }

  @override
  Future<void> disconnect([int? code, String? reason]) async {
    await _subscription.cancel();
    await _socket.close(code, reason);
    //assert(_socket.readyState == io.WebSocket.closed, 'Socket is not closed');
  }
}
