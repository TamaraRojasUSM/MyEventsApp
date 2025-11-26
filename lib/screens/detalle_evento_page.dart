import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/evento.dart';
import '../models/categoria.dart';

class DetalleEventoPage extends StatelessWidget {
  final String eventoId;

  const DetalleEventoPage({super.key, required this.eventoId});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final formatoFecha = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('DETALLE DEL EVENTO'),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('eventos').doc(eventoId).snapshots(),
        builder: (context, snapEvento) {
          if (snapEvento.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapEvento.hasData || snapEvento.data == null) {
            return const Center(child: Text('Evento no encontrado'));
          }

          final rawData = snapEvento.data!.data();
          final data = rawData is Map<String, dynamic> ? rawData : null;
          if (data == null) {
            return const Center(child: Text('Evento no encontrado'));
          }

          DateTime fecha;
          final rawFecha = data['fechaHora'];
          if (rawFecha is Timestamp) {
            fecha = rawFecha.toDate();
          } else if (rawFecha is String) {
            fecha = DateTime.tryParse(rawFecha) ?? DateTime.now();
          } else {
            fecha = DateTime.now();
          }

          final evento = Evento(
            id: snapEvento.data!.id,
            titulo: data['titulo'] ?? '',
            lugar: data['lugar'] ?? '',
            fechaHora: fecha,
            categoriaId: data['categoriaId'] ?? '',
            autor: data['autor'] ?? '',
          );

          final userEmail = (currentUser?.email ?? '').trim().toLowerCase();
          final esAutor = evento.autor.trim().toLowerCase() == userEmail;

          if (evento.categoriaId.isEmpty) {
            return _DetalleSinCategoria(evento: evento, formatoFecha: formatoFecha);
          }

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('categorias').doc(evento.categoriaId).snapshots(),
            builder: (context, snapCategoria) {
              if (snapCategoria.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapCategoria.hasData || snapCategoria.data == null) {
                return _DetalleSinCategoria(evento: evento, formatoFecha: formatoFecha);
              }

              final catRaw = snapCategoria.data!.data();
              final catData = catRaw is Map<String, dynamic> ? catRaw : null;
              if (catData == null) {
                return _DetalleSinCategoria(evento: evento, formatoFecha: formatoFecha);
              }

              final categoria = Categoria.fromMap(snapCategoria.data!.id, catData);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/${categoria.foto}',
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: double.infinity,
                          height: 220,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image_not_supported, size: 48),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(evento.titulo, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Lugar: ${evento.lugar}', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 6),
                    Text('Categoría: ${categoria.nombre}', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 6),
                    Text('Fecha: ${formatoFecha.format(evento.fechaHora)}', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 6),
                    Text('Autor: ${evento.autor}', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 24),
                    if (esAutor)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Puedes eliminar este evento deslizando hacia la izquierda desde la lista de eventos.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DetalleSinCategoria extends StatelessWidget {
  final Evento evento;
  final DateFormat formatoFecha;

  const _DetalleSinCategoria({required this.evento, required this.formatoFecha});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.category, size: 48),
          ),
          const SizedBox(height: 16),
          Text(evento.titulo, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Lugar: ${evento.lugar}', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 6),
          Text('Fecha: ${formatoFecha.format(evento.fechaHora)}', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 6),
          Text('Autor: ${evento.autor}', style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
