class Categoria {
  final String id;
  final String nombre;
  final String foto;

  Categoria({
    required this.id,
    required this.nombre,
    required this.foto,
  });

  factory Categoria.fromMap(String id, Map<String, dynamic> data) {
    return Categoria(
      id: id,
      nombre: data['nombre'] ?? '',
      foto: data['foto'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'foto': foto,
    };
  }

  Categoria copyWith({
    String? nombre,
    String? foto,
  }) {
    return Categoria(
      id: id,
      nombre: nombre ?? this.nombre,
      foto: foto ?? this.foto,
    );
  }

  @override
  String toString() => 'Categoria($nombre)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Categoria &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
