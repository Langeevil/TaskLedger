class UsuarioModel {
  const UsuarioModel({
    required this.uid,
    required this.nome,
    required this.email,
    required this.telefone,
    this.dataCriacao,
  });

  final String uid;
  final String nome;
  final String email;
  final String telefone;
  final DateTime? dataCriacao;

  factory UsuarioModel.fromMap(
    Map<String, dynamic> map, {
    String? fallbackUid,
    String? fallbackEmail,
  }) {
    final email = map['email']?.toString().trim().isNotEmpty == true
        ? map['email'].toString().trim()
        : (fallbackEmail ?? 'Nao informado');
    final nome = map['nome']?.toString().trim().isNotEmpty == true
        ? map['nome'].toString().trim()
        : _generateFallbackName(email);
    final telefone = map['telefone']?.toString().trim().isNotEmpty == true
        ? map['telefone'].toString().trim()
        : 'Nao informado';

    return UsuarioModel(
      uid: map['uid']?.toString() ?? fallbackUid ?? '',
      nome: nome,
      email: email,
      telefone: telefone,
      dataCriacao: map['dataCriacao'] is DateTime
          ? map['dataCriacao'] as DateTime
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'dataCriacao': dataCriacao,
    };
  }

  UsuarioModel copyWith({
    String? uid,
    String? nome,
    String? email,
    String? telefone,
    DateTime? dataCriacao,
  }) {
    return UsuarioModel(
      uid: uid ?? this.uid,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      dataCriacao: dataCriacao ?? this.dataCriacao,
    );
  }

  static String firstName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) {
      return 'Usuario';
    }

    return fullName.trim().split(RegExp(r'\s+')).first;
  }

  static String _generateFallbackName(String email) {
    final localPart = email.split('@').first.trim();
    if (localPart.isEmpty) {
      return 'Usuario';
    }

    final name = localPart.replaceAll('.', ' ');
    return name[0].toUpperCase() + name.substring(1);
  }
}
