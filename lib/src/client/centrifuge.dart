import 'dart:async';

import 'package:centrifuge_dart/src/client/centrifuge_interface.dart';
import 'package:centrifuge_dart/src/model/config.dart';
import 'package:centrifuge_dart/src/model/exception.dart';
import 'package:centrifuge_dart/src/model/state.dart';
import 'package:centrifuge_dart/src/transport/transport_interface.dart';
import 'package:centrifuge_dart/src/transport/ws_protobuf_transport.dart';
import 'package:centrifuge_dart/src/util/logger.dart' as logger;
import 'package:meta/meta.dart';

/// {@template centrifuge}
/// Centrifuge client.
/// {@endtemplate}
final class Centrifuge extends CentrifugeBase with CentrifugeConnectionMixin {
  /// {@macro centrifuge}
  Centrifuge([CentrifugeConfig? config])
      : super(config ?? CentrifugeConfig.defaultConfig());

  /// Create client and connect.
  ///
  /// {@macro centrifuge}
  factory Centrifuge.connect(String url, [CentrifugeConfig? config]) =>
      Centrifuge(config)..connect(url);
}

/// {@nodoc}
@internal
abstract base class CentrifugeBase implements ICentrifuge {
  /// {@nodoc}
  CentrifugeBase(CentrifugeConfig config)
      : _transport = CentrifugeWebSocketProtobufTransport(config),
        _config = config {
    _initCentrifuge();
  }

  /// Internal transport responsible
  /// for sending, receiving, encoding and decoding data from the server.
  /// {@nodoc}
  @nonVirtual
  final ICentrifugeTransport _transport;

  @override
  @nonVirtual
  CentrifugeState get state => _transport.state;

  @override
  Stream<CentrifugeState> get states => _transport.states;

  /// Centrifuge config.
  /// {@nodoc}
  @nonVirtual
  final CentrifugeConfig _config;

  /// Init centrifuge client, override this method to add custom logic.
  /// This method is called in constructor.
  /// {@nodoc}
  @protected
  @mustCallSuper
  void _initCentrifuge() {}

  @override
  @mustCallSuper
  Future<void> close() async {}
}

/// Mixin responsible for connection.
/// {@nodoc}
@internal
base mixin CentrifugeConnectionMixin on CentrifugeBase {
  @override
  Future<void> connect(String url) async {
    logger.fine('Interactively connecting to $url');
    try {
      await _transport.connect(url);
    } on CentrifugeException {
      rethrow;
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(
        CentrifugeConnectionException(error),
        stackTrace,
      );
    }
  }

  @override
  Future<void> disconnect() async {
    logger.fine('Interactively disconnecting');
    try {
      await _transport.disconnect(0, 'Disconnect called');
    } on CentrifugeException {
      rethrow;
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(
        CentrifugeDisconnectionException(error),
        stackTrace,
      );
    }
  }

  @override
  Future<void> close() async {
    logger.fine('Interactively closing');
    await super.close();
    await _transport.close();
  }
}
