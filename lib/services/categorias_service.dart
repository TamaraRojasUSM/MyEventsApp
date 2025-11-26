import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/categoria.dart';

class CategoriasService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Categoria>> obtenerCategorias() {
    return _db.collection('categorias').snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return Categoria.fromMap(doc.id, doc.data());
        }).toList();
      },
    );
  }
}
