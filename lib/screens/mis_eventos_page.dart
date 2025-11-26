import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/evento.dart';
import '../services/eventos_service.dart';
import 'detalle_evento_page.dart';

class MisEventosVigentesPage extends StatefulWidget {
  const MisEventosVigentesPage({super.key});

  @override
  State<MisEventosVigentesPage> createState() => _MisEventosVigentesPageState();
}

class _MisEventosVigentesPageState extends State<MisEventosVigentesPage> {
  bool _desc = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final email = currentUser.email!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis eventos vigentes"),
        actions: [
          IconButton(
            tooltip: _desc ? 'Orden ascendente' : 'Orden descendente',
            icon: Icon(_desc ? Icons.south : Icons.north),
            onPressed: () => setState(() => _desc = !_desc),
          ),
        ],
      ),
      body: StreamBuilder<List<Evento>>(
        stream: EventosService().obtenerEventosDelUsuario(email).map((eventos) {
          final ahora = DateTime.now();
          final vigentes = eventos.where((e) => e.fechaHora.isAfter(ahora)).toList();
          if (_desc) {
            vigentes.sort((a, b) => b.fechaHora.compareTo(a.fechaHora));
          } else {
            vigentes.sort((a, b) => a.fechaHora.compareTo(b.fechaHora));
          }

          return vigentes;
        }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("No tienes eventos vigentes"));

          final eventos = snapshot.data!;
          return ListView.builder(
            itemCount: eventos.length,
            itemBuilder: (context, index) {
              final evento = eventos[index];
              final fechaFormateada = DateFormat('dd/MM/yyyy HH:mm').format(evento.fechaHora.toLocal());

              return Dismissible(
                key: Key(evento.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirmar eliminación'),
                      content: Text('¿Eliminar el evento "${evento.titulo}"? Esta acción no se puede deshacer.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
                        TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar')),
                      ],
                    ),
                  );

                  if (confirm != true) return false;

                  try {
                    await EventosService().eliminarEvento(evento.id);
                    if (!context.mounted) return false;

                    await showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Evento eliminado'),
                        content: Text('El evento "${evento.titulo}" fue eliminado correctamente.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
                        ],
                      ),
                    );

                    return true;
                  } catch (e) {
                    if (!context.mounted) return false;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red),
                    );
                    return false;
                  }
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  color: const Color(0xFFFFF8E1),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: const Icon(Icons.event_available, color: Color(0xFF212121)),
                    title: Text(evento.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${evento.lugar} • $fechaFormateada'),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => DetalleEventoPage(eventoId: evento.id)));
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
