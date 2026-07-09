/// Usuario autenticado (proprietario, profissional ou cliente).
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.tenantId,
    this.phone,
    this.tenantName,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final tenant = json['tenant'] as Map<String, dynamic>?;

    return AppUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      tenantId: json['tenant_id'] as int?,
      phone: json['phone'] as String?,
      tenantName: tenant?['name'] as String?,
    );
  }

  final int id;
  final String name;
  final String email;
  final String role;

  /// Nulo para administradores da plataforma, que nao pertencem a nenhum
  /// estabelecimento (diferente de owner/professional/customer, sempre
  /// vinculados a um tenant).
  final int? tenantId;
  final String? phone;
  final String? tenantName;
}
