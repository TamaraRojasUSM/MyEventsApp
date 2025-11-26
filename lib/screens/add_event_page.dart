import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/evento.dart';
import '../models/categoria.dart';

class AddEventPage extends StatefulWidget {
  const AddEventPage({super.key});

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  String? titulo;
  String? lugar;
  DateTime? fechaHora;
  Categoria? categoriaSeleccionada;

  Future<void> agregarEvento() async {
    if (!_formKey.currentState!.validate()) return;
    if (fechaHora == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleccione fecha y hora')),
        );
      });
      return;
    }

    final ahora = DateTime.now();
    if (fechaHora!.isBefore(ahora)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La fecha y hora no pueden ser anteriores a ahora')),
        );
      });
      return;
    }

    if (categoriaSeleccionada == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleccione una categoría')),
        );
      });
      return;
    }

    _formKey.currentState!.save();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final nuevoEvento = Evento(
        id: '',
        titulo: titulo!,
        lugar: lugar ?? '',
        fechaHora: fechaHora!, 
        categoriaId: categoriaSeleccionada!.id,
        autor: (user.email ?? 'Desconocido').trim().toLowerCase(),
      );


      final docRef = await FirebaseFirestore.instance.collection('eventos').add({
        ...nuevoEvento.toMap(),
        'fechaHora': Timestamp.fromDate(nuevoEvento.fechaHora.toUtc()),
        'autor': nuevoEvento.autor,
      });

      await docRef.update({'id': docRef.id});

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pop(context);
      });
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> seleccionarFechaHora() async {
    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (fechaSeleccionada == null) return;

    if (!mounted) return;

    final horaSeleccionada = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (horaSeleccionada == null) return;

    if (!mounted) return;

    setState(() {
      final seleccion = DateTime(
        fechaSeleccionada.year,
        fechaSeleccionada.month,
        fechaSeleccionada.day,
        horaSeleccionada.hour,
        horaSeleccionada.minute,
      );
      if (seleccion.isBefore(DateTime.now())) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No puedes seleccionar una fecha/hora pasada')),
          );
        });
        return;
      }
      fechaHora = seleccion;
    });
  }

  @override
  Widget build(BuildContext context) {
    final formatoFecha = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text("Agregar evento")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: "Título"),
                validator: (v) =>
                    (v == null || v.isEmpty) ? "Ingrese un título" : null,
                onSaved: (v) => titulo = v,
              ),
              const SizedBox(height: 16),

              TextFormField(
                decoration: const InputDecoration(labelText: "Lugar"),
                validator: (v) =>
                    (v == null || v.isEmpty) ? "Ingrese un lugar" : null,
                onSaved: (v) => lugar = v,
              ),
              const SizedBox(height: 16),

              ListTile(
                title: Text(
                  fechaHora == null
                      ? "Seleccione fecha y hora"
                      : "Fecha: ${formatoFecha.format(fechaHora!)}",
                ),
                trailing: const Icon(Icons.calendar_month),
                onTap: seleccionarFechaHora,
              ),

              const SizedBox(height: 16),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('categorias')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final categorias = snapshot.data!.docs.map((doc) {
                    return Categoria.fromMap(
                      doc.id,
                      doc.data() as Map<String, dynamic>,
                    );
                  }).toList();

                  return DropdownButtonFormField<Categoria>(
                    decoration: const InputDecoration(labelText: "Categoría"),
                    initialValue: categoriaSeleccionada,
                    items: categorias.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat.nombre),
                      );
                    }).toList(),
                    onChanged: (valor) {
                      setState(() => categoriaSeleccionada = valor);
                    },
                    validator: (v) => v == null ? "Seleccione una categoría" : null,
                  );
                },
              ),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : agregarEvento,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Agregar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
