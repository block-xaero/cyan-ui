import 'zk_proof.dart';

class XaeroID {
  final String did;
  final String publicKey;
  final List<ZKProof> zkProofs;
  final DateTime createdAt;

  XaeroID({
    required this.did,
    required this.publicKey,
    required this.zkProofs,
    required this.createdAt,
  });
}
