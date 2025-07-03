class ZKProof {
  final String id;
  final String type;
  final String issuer;
  final Map<String, dynamic> claims;
  final String proof;
  final DateTime issuedAt;
  final DateTime? expiresAt;

  ZKProof({
    required this.id,
    required this.type,
    required this.issuer,
    required this.claims,
    required this.proof,
    required this.issuedAt,
    this.expiresAt,
  });
}
