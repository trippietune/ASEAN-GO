import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import '../api/api_client.dart';
import '../api/providers.dart';

/// Thin wrapper around the Socket.IO client: connects once a JWT is
/// available, authenticates via the handshake `auth` payload (matching the
/// backend's `initSocketServer`), and re-connects automatically if dropped.
/// Consumers subscribe to specific event names via [on] rather than reaching
/// into the raw socket, so call sites don't need to know about connection
/// lifecycle.
class SocketService {
  SocketService(this._apiClient);

  final ApiClient _apiClient;
  socket_io.Socket? _socket;

  Future<void> connect() async {
    if (_socket != null) return;
    final token = await _apiClient.readToken();
    if (token == null) return;

    _socket = socket_io.io(
      apiBaseUrl,
      socket_io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );
    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void on(String event, void Function(dynamic data) handler) {
    _socket?.on(event, handler);
  }

  void off(String event) {
    _socket?.off(event);
  }
}

final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService(ref.watch(apiClientProvider));
  ref.onDispose(service.disconnect);
  return service;
});
