import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/evento.dart';

class EventosService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Evento>> obtenerEventos() {
    return _db
        .collection('eventos')
        .orderBy('fechaHora')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Evento.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> agregarEvento(Evento evento) async {
    final data = {
      ...evento.toMap(),
      'fechaHora': Timestamp.fromDate(evento.fechaHora),
    };
    await _db.collection('eventos').add(data);
  }

  Future<void> actualizarEvento(String id, Evento evento) async {
    final data = {
      ...evento.toMap(),
      'fechaHora': Timestamp.fromDate(evento.fechaHora),
    };
    await _db.collection('eventos').doc(id).update(data);
  }

  Future<Evento?> obtenerEventoPorId(String id) async {
    final doc = await _db.collection('eventos').doc(id).get();
    if (!doc.exists) return null;
    return Evento.fromMap(doc.id, doc.data()!);
  }

  Future<void> eliminarEvento(String id) async {
    await _db.collection('eventos').doc(id).delete();
  }

  Stream<List<Evento>> obtenerEventosDelUsuario(String email) {
    return _db
        .collection('eventos')
        .where('autor', isEqualTo: email)
        .orderBy('fechaHora') 
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Evento.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Stream<List<Evento>> obtenerEventosVigentes() {
    final ahoraTs = Timestamp.fromDate(DateTime.now());
    return _db
        .collection('eventos')
        .where('fechaHora', isGreaterThanOrEqualTo: ahoraTs)
        .orderBy('fechaHora')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Evento.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Stream<List<Evento>> obtenerEventosVencidos(String email) {
    final ahoraTs = Timestamp.fromDate(DateTime.now());
    return _db
        .collection('eventos')
        .where('autor', isEqualTo: email)
        .where('fechaHora', isLessThan: ahoraTs)
        .orderBy('fechaHora', descending: true) 
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Evento.fromMap(doc.id, doc.data()))
          .toList();
    });
  }
}
