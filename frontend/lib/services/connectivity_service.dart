import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides a stream of online/offline connectivity status.
final connectivityServiceProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();

  // Emit initial state
  final initialResults = await connectivity.checkConnectivity();
  yield _isConnected(initialResults);

  // Emit subsequent changes
  await for (final results in connectivity.onConnectivityChanged) {
    yield _isConnected(results);
  }
});

bool _isConnected(List<ConnectivityResult> results) {
  return results.any(
    (r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet,
  );
}
