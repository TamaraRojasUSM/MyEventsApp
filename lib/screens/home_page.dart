import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/evento.dart';
import '../models/categoria.dart';
import '../services/eventos_service.dart';
import '../services/categorias_service.dart';
import '../services/auth_service.dart';
import 'detalle_evento_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _listController = ScrollController();
  String _filtro = 'vigentes';

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  Future<void> _showTopPanel(BuildContext context) async {
    HapticFeedback.lightImpact();
    final altoPantalla = MediaQuery.of(context).size.height;
    final altoPanel = altoPantalla * 0.72;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Panel',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, anim1, anim2) {
        return Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: SafeArea(
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  if (details.delta.dy < -12) {
                    if (Navigator.of(dialogContext).canPop()) Navigator.of(dialogContext).pop();
                  }
                },
                child: Container(
                  height: altoPanel,
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12)],
                  ),
                  child: _buildTopPanelContent(dialogContext),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim, secAnim, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
    );
  }

  Widget _buildTopPanelContent(BuildContext dialogContext) {
    final usuarioAutenticado = FirebaseAuth.instance.currentUser;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: ClipOval(
                  child: CircleAvatar(
                    radius: 28,
                    backgroundImage: usuarioAutenticado?.photoURL != null ? NetworkImage(usuarioAutenticado!.photoURL!) : null,
                    backgroundColor: Colors.grey.shade300,
                    child: usuarioAutenticado?.photoURL == null ? const Icon(Icons.person, color: Colors.white) : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usuarioAutenticado?.displayName ?? 'Usuario',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(usuarioAutenticado?.email ?? '', style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  if (Navigator.of(dialogContext).canPop()) Navigator.of(dialogContext).pop();
                },
              ),
            ],
          ),
        ),

        Container(
          width: 48,
          height: 6,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(3)),
        ),
        const Divider(height: 1),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              ListTile(
                leading: const Icon(Icons.filter_alt, color: Colors.black87),
                title: const Text("Ver todos vigentes", style: TextStyle(color: Colors.black87)),
                onTap: () {
                  setState(() => _filtro = 'vigentes');
                  if (Navigator.of(dialogContext).canPop()) Navigator.of(dialogContext).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.event_available, color: Colors.black87),
                title: const Text("Ver mis vigentes", style: TextStyle(color: Colors.black87)),
                onTap: () {
                  setState(() => _filtro = 'mis_vigentes');
                  if (Navigator.of(dialogContext).canPop()) Navigator.of(dialogContext).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.people, color: Colors.black87),
                title: const Text("Ver vigentes de otros", style: TextStyle(color: Colors.black87)),
                onTap: () {
                  setState(() => _filtro = 'vigentes_otros');
                  if (Navigator.of(dialogContext).canPop()) Navigator.of(dialogContext).pop();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.history, color: Colors.black87),
                title: const Text("Ver todos vencidos", style: TextStyle(color: Colors.black87)),
                onTap: () {
                  setState(() => _filtro = 'vencidos_todos');
                  if (Navigator.of(dialogContext).canPop()) Navigator.of(dialogContext).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.black87),
                title: const Text("Ver mis vencidos", style: TextStyle(color: Colors.black87)),
                onTap: () {
                  setState(() => _filtro = 'vencidos_mios');
                  if (Navigator.of(dialogContext).canPop()) Navigator.of(dialogContext).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.group, color: Colors.black87),
                title: const Text("Ver vencidos de otros", style: TextStyle(color: Colors.black87)),
                onTap: () {
                  setState(() => _filtro = 'vencidos_otros');
                  if (Navigator.of(dialogContext).canPop()) Navigator.of(dialogContext).pop();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.black87),
                title: const Text("Cerrar sesión", style: TextStyle(color: Colors.black87)),
                onTap: () async {

                  if (Navigator.of(dialogContext).canPop()) Navigator.of(dialogContext).pop();

                  try {
                    await AuthService().signOutAll();

                    if (!mounted) return;

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      Navigator.pushReplacementNamed(context, '/login');
                    });
                  } catch (e) {
                    if (!mounted) return;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al cerrar sesión: $e'), behavior: SnackBarBehavior.floating),
                      );
                    });
                  }
                },
              ),

            ],
          ),
        ),
      ],
    );
  }

  Stream<List<Evento>> _getStream(String email) {
    final service = EventosService();
    final ahora = DateTime.now();

    switch (_filtro) {
      case 'vigentes':
        return service.obtenerEventosVigentes();
      case 'mis_vigentes':
        return service.obtenerEventosDelUsuario(email).map((eventos) {
          return eventos.where((e) => e.fechaHora.isAfter(ahora)).toList();
        });
      case 'vigentes_otros':
        return service.obtenerEventos().map((eventos) {
          return eventos.where((e) => e.fechaHora.isAfter(ahora) && e.autor.trim().toLowerCase() != email).toList();
        });
      case 'vencidos_todos':
        return service.obtenerEventos().map((eventos) {
          return eventos.where((e) => e.fechaHora.isBefore(ahora)).toList();
        });
      case 'vencidos_mios':
        return service.obtenerEventosDelUsuario(email).map((eventos) {
          return eventos.where((e) => e.fechaHora.isBefore(ahora)).toList();
        });
      case 'vencidos_otros':
        return service.obtenerEventos().map((eventos) {
          return eventos.where((e) => e.fechaHora.isBefore(ahora) && e.autor.trim().toLowerCase() != email).toList();
        });
      default:
        return service.obtenerEventosVigentes();
    }
  }

  Widget _buildEventoCard(Evento evento, Categoria? categoria, String fechaFormateada, bool esAutor) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: esAutor ? 4 : 1,
      shadowColor: esAutor ? Colors.amberAccent : Colors.black26,
      color: esAutor ? const Color(0xFFFFF8E1) : Colors.white,
      child: InkWell(
        onTap: () async {
          final navigator = Navigator.of(context);
          final messenger = ScaffoldMessenger.of(context);

          final result = await navigator.push<bool>(
            MaterialPageRoute(builder: (_) => DetalleEventoPage(eventoId: evento.id)),
          );

          if (result == true && mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Evento eliminado correctamente'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            });
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (categoria != null && categoria.foto.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                child: Image.asset(
                  'assets/${categoria.foto}',
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: double.infinity,
                    height: 160,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.broken_image, size: 50),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                ),
                child: const Icon(Icons.category, size: 50),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(evento.titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${evento.lugar} • $fechaFormateada'),
                  const SizedBox(height: 4),
                  Text('Categoría: ${categoria?.nombre ?? "Desconocida"}'),
                  const SizedBox(height: 4),
                  Text('Autor: ${evento.autor}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuarioAutenticado = FirebaseAuth.instance.currentUser;
    if (usuarioAutenticado == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final email = usuarioAutenticado.email!.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () {
            setState(() => _filtro = 'vigentes');
            if (_listController.hasClients) {
              _listController.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final nav = Navigator.of(context);
              if (nav.canPop()) nav.pop();
            });
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              'MyEventsApp',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () => _showTopPanel(context),
              onVerticalDragUpdate: (details) {
                if (details.delta.dy > 8) _showTopPanel(context);
              },
              child: Container(
                width: 44,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.keyboard_arrow_down, size: 26, color: Colors.black87),
              ),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Evento>>(
              stream: _getStream(email),
              builder: (context, eventosSnapshot) {
                if (eventosSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (eventosSnapshot.hasError) {
                  return Center(child: Text('Error: ${eventosSnapshot.error}'));
                }
                if (!eventosSnapshot.hasData || eventosSnapshot.data!.isEmpty) {
                  if (_filtro == 'vigentes' || _filtro == 'mis_vigentes') {
                    return Column(
                      children: const [
                        ProximoAVencerWidget(),
                        Expanded(child: Center(child: Text("No hay eventos vigentes"))),
                      ],
                    );
                  }
                  return const Center(child: Text("No hay eventos"));
                }

                final eventos = eventosSnapshot.data!;
                final mostrarProximo = _filtro == 'vigentes' || _filtro == 'mis_vigentes';

                return StreamBuilder<List<Categoria>>(
                  stream: CategoriasService().obtenerCategorias(),
                  builder: (context, catSnapshot) {
                    if (catSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (catSnapshot.hasError) {
                      return Center(child: Text('Error: ${catSnapshot.error}'));
                    }

                    final categoriasMap = {for (final c in (catSnapshot.data ?? <Categoria>[])) c.id: c};
                    final List<Widget> children = [];
                    if (mostrarProximo) children.add(const ProximoAVencerWidget());

                    for (final evento in eventos) {
                      final esAutor = evento.autor.trim().toLowerCase() == email;
                      final categoria = categoriasMap[evento.categoriaId];
                      final fechaFormateada = DateFormat('dd/MM/yyyy HH:mm').format(evento.fechaHora.toLocal());

                      if (esAutor) {
                        children.add(
                          Dismissible(
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
                                if (!mounted) return false;

                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Evento "${evento.titulo}" eliminado'), behavior: SnackBarBehavior.floating),
                                  );
                                });

                                return true;
                              } catch (e) {
                                if (!mounted) return false;
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red),
                                  );
                                });
                                return false;
                              }
                            },
                            child: _buildEventoCard(evento, categoria, fechaFormateada, esAutor),
                          ),
                        );
                      } else {
                        children.add(
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onHorizontalDragStart: (_) {
                              if (!mounted) return;
                              HapticFeedback.selectionClick();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Solo el autor puede eliminar este evento'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: _buildEventoCard(evento, categoria, fechaFormateada, esAutor),
                          ),
                        );
                      }
                    }

                    return ListView(
                      controller: _listController,
                      children: children,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.pushNamed(context, '/agregar_evento');
        },
      ),
    );
  }
}

class ProximoAVencerWidget extends StatelessWidget {
  const ProximoAVencerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ahoraTs = Timestamp.fromDate(DateTime.now().toUtc());

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('eventos')
          .where('fechaHora', isGreaterThanOrEqualTo: ahoraTs)
          .orderBy('fechaHora')
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox.shrink();
        if (snapshot.hasError) return const SizedBox.shrink();
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();

        final doc = snapshot.data!.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        final evento = Evento.fromMap(doc.id, data);

        final fecha = data['fechaHora'] is Timestamp
            ? DateFormat('dd/MM/yyyy HH:mm').format((data['fechaHora'] as Timestamp).toDate().toLocal())
            : 'Fecha no disponible';

        return Card(
          color: Colors.red.shade50,
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: ListTile(
            leading: const Icon(Icons.schedule, color: Colors.red),
            title: Text('Próximo a vencer: ${evento.titulo}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${evento.lugar} • $fecha'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => DetalleEventoPage(eventoId: evento.id)));
            },
          ),
        );
      },
    );
  }
}
