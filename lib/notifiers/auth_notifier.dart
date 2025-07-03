import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_ui_state.dart';
import '../models/xaero_id.dart';
import '../models/zk_proof.dart';
import '../services/cyan_event_bus.dart';
import '../events/cyan_event.dart';

class AuthUINotifier extends StateNotifier<AuthUIState> {
  final CyanEventBus _eventBus = CyanEventBus();

  AuthUINotifier() : super(AuthUIState()) {
    _eventBus
        .eventsOfType(CyanEventType.authSignIn)
        .listen(_handleAuthResponse);
  }

  void _handleAuthResponse(CyanEvent event) {
    state = AuthUIState(
        user: XaeroID(
      did: 'did:peer:1zQmYj8K9XwLWZ3VxN4qP7RdS2',
      publicKey: 'falcon512_02a1b2c3d4e5f6...',
      zkProofs: [
        ZKProof(
          id: 'admin_proof_1',
          type: 'GroupAdmin',
          issuer: 'did:peer:genesis',
          claims: {'role': 'admin', 'groupId': 'group_1'},
          proof: 'zkp_a1b2c3d4e5f6...',
          issuedAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        ZKProof(
          id: 'member_proof_1',
          type: 'GroupMember',
          issuer: 'did:peer:1zQmYj8K9XwLWZ3VxN4qP7RdS2',
          claims: {'role': 'member', 'groupId': 'group_2'},
          proof: 'zkp_b2c3d4e5f6a1...',
          issuedAt: DateTime.now().subtract(const Duration(days: 15)),
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ));
  }

  void createDid() {
    state = AuthUIState(isLoading: true);
    _eventBus.dispatch(CyanEvent(
      type: CyanEventType.authCreateDid,
      id: 'create_did_${DateTime.now().millisecondsSinceEpoch}',
      payload: Uint8List.fromList([]),
    ));

    Future.delayed(const Duration(seconds: 1), () {
      state = AuthUIState(
          user: XaeroID(
        did: 'did:peer:1zQmNew7X9wLWZ3VxN4qP7RdS2',
        publicKey: 'falcon512_new_02a1b2c3d4e5f6...',
        zkProofs: [],
        createdAt: DateTime.now(),
      ));
    });
  }

  void signIn() {
    state = AuthUIState(isLoading: true);
    _eventBus.dispatch(CyanEvent(
      type: CyanEventType.authSignIn,
      id: 'sign_in_${DateTime.now().millisecondsSinceEpoch}',
      payload: Uint8List.fromList([]),
    ));

    Future.delayed(const Duration(seconds: 1), () {
      state = AuthUIState(
          user: XaeroID(
        did: 'did:peer:1zQmExisting8K9XwLWZ3VxN4qP7',
        publicKey: 'falcon512_existing_02a1b2c3d4e5f6...',
        zkProofs: [
          ZKProof(
            id: 'member_proof_2',
            type: 'GroupMember',
            issuer: 'did:peer:admin',
            claims: {'role': 'member', 'groupId': 'group_1'},
            proof: 'zkp_existing_member...',
            issuedAt: DateTime.now().subtract(const Duration(days: 10)),
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ));
    });
  }
}

final authUIProvider =
    StateNotifierProvider<AuthUINotifier, AuthUIState>((ref) {
  return AuthUINotifier();
});
