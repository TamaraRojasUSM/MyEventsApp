import 'package:cloud_firestore/cloud_firestore.dart';

class Evento {
  final String id;
  final String titulo;
  final String lugar;
  final DateTime fechaHora;
  final String categoriaId;
  final String autor;

  Evento({
    required this.id,
    required this.titulo,
    required this.lugar,
    required this.fechaHora,
    required this.categoriaId,
    required this.autor,
  });

  factory Evento.fromMap(String id, Map<String, dynamic> data) {
    final rawFecha = data['fechaHora'];
    DateTime fecha;

    if (rawFecha is Timestamp) {
      fecha = rawFecha.toDate();
    } else if (rawFecha is String) {
      fecha = DateTime.tryParse(rawFecha) ?? DateTime.now();
    } else {
      fecha = DateTime.now();
    }

    return Evento(
      id: id,
      titulo: data['titulo'] ?? '',
      lugar: data['lugar'] ?? '',
      fechaHora: fecha,
      categoriaId: data['categoriaId'] ?? '',
      autor: data['autor'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'lugar': lugar,
      'fechaHora': Timestamp.fromDate(fechaHora),
      'categoriaId': categoriaId,
      'autor': autor,
    };
  }
}
