import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

enum NetworkStatus { online, offline }

class ConnectivityService {
  ConnectivityService._internal() {
    _subscription = _connectivity.onConnectivityChanged.listen(_update);
    _connectivity.checkConnectivity().then(_update);
  }

  static final instance = ConnectivityService._internal();
  final _connectivity = Connectivity();
  late final StreamSubscription<List<ConnectivityResult>> _subscription;
  final _controller = StreamController<NetworkStatus>.broadcast();
  Stream<NetworkStatus> get status$ => _controller.stream;

  NetworkStatus? _lastStatus;

  void dispose() => _subscription.cancel();

  void _update(List<ConnectivityResult> results) {
    final offline = results.length == 1 && results.first == ConnectivityResult.none;
    final status = offline ? NetworkStatus.offline : NetworkStatus.online;
    if (status != _lastStatus) {
      _lastStatus = status;
      _controller.add(status);
    }
  }
}