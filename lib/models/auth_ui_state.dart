import 'xaero_id.dart';

class AuthUIState {
  final bool isLoading;
  final XaeroID? user;
  final String? error;

  AuthUIState({this.isLoading = false, this.user, this.error});

  bool get isAuthenticated => user != null;
}
