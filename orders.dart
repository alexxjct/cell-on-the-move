// lib/orders.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Pantalla para mostrar y gestionar las órdenes activas.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  // Referencia a la colección 'notas' en Firestore (ajustar si es necesario)
  final CollectionReference ordersCollection =
  FirebaseFirestore.instance.collection('notas');

  /// Muestra un diálogo con los detalles completos de una orden,
  /// y opciones para modificar, eliminar o marcar como completada.
  void _showOrderDetailsDialog(Order order, String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Detalles de la Orden',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Folio: ${order.folio}', style: GoogleFonts.plusJakartaSans()),
                Text('Teléfono: ${order.telefono}', style: GoogleFonts.plusJakartaSans()),
                Text('Nombre Cliente: ${order.nombreCliente}',
                    style: GoogleFonts.plusJakartaSans()),
                Text('Fecha: ${order.fecha}', style: GoogleFonts.plusJakartaSans()),
                const SizedBox(height: 8),
                Text('Marca: ${order.marca}', style: GoogleFonts.plusJakartaSans()),
                Text('Modelo: ${order.modelo}', style: GoogleFonts.plusJakartaSans()),
                Text('Color: ${order.color}', style: GoogleFonts.plusJakartaSans()),
                Text('Falla: ${order.falla}', style: GoogleFonts.plusJakartaSans()),
                Text('Observaciones: ${order.observaciones}',
                    style: GoogleFonts.plusJakartaSans()),
                Text('Memoria: ${order.memoria}', style: GoogleFonts.plusJakartaSans()),
                Text('Chip: ${order.chip}', style: GoogleFonts.plusJakartaSans()),
                Text('Funda: ${order.funda}', style: GoogleFonts.plusJakartaSans()),
                Text('Pin: ${order.pin}', style: GoogleFonts.plusJakartaSans()),
                const SizedBox(height: 8),
                Text('Total: ${order.total}', style: GoogleFonts.plusJakartaSans()),
                Text('A cuenta: ${order.aCuenta}', style: GoogleFonts.plusJakartaSans()),
                Text('Resta: ${order.resta}', style: GoogleFonts.plusJakartaSans()),
              ],
            ),
          ),
          actions: [
            // Botón para modificar la orden
            TextButton.icon(
              icon: const Icon(Icons.edit, color: Colors.blue),
              label: const Text('Modificar', style: TextStyle(color: Colors.blue)),
              onPressed: () {
                Navigator.pop(context);
                _openEditOrderDialog(order, docId);
              },
            ),
            // Botón para eliminar la orden
            TextButton.icon(
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await ordersCollection.doc(docId).delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Orden eliminada')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al eliminar: $e')),
                  );
                }
              },
            ),
            // Botón para marcar la orden como completada
            TextButton.icon(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              label: const Text('Completado', style: TextStyle(color: Colors.green)),
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await ordersCollection.doc(docId).update({'status': 'completada'});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Orden marcada como completada')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al actualizar: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  /// Abre un diálogo para editar los campos de una orden.
  void _openEditOrderDialog(Order order, String docId) {
    final nombreController = TextEditingController(text: order.nombreCliente);
    final telefonoController = TextEditingController(text: order.telefono);
    final marcaController = TextEditingController(text: order.marca);
    final modeloController = TextEditingController(text: order.modelo);
    final colorController = TextEditingController(text: order.color);
    final fallaController = TextEditingController(text: order.falla);
    final observacionesController = TextEditingController(text: order.observaciones);
    final memoriaController = TextEditingController(text: order.memoria);
    final chipController = TextEditingController(text: order.chip);
    final fundaController = TextEditingController(text: order.funda);
    final pinController = TextEditingController(text: order.pin);
    final totalController = TextEditingController(text: order.total);
    final aCuentaController = TextEditingController(text: order.aCuenta);
    final restaController = TextEditingController(text: order.resta);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modificar Orden'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField('Nombre Cliente', nombreController),
                _buildTextField('Teléfono', telefonoController,
                    keyboardType: TextInputType.phone),
                _buildTextField('Marca', marcaController),
                _buildTextField('Modelo', modeloController),
                _buildTextField('Color', colorController),
                _buildTextField('Falla', fallaController),
                _buildTextField('Observaciones', observacionesController),
                _buildTextField('Memoria', memoriaController),
                _buildTextField('Chip', chipController),
                _buildTextField('Funda', fundaController),
                _buildTextField('Pin', pinController),
                _buildTextField('Total', totalController,
                    keyboardType: TextInputType.number),
                _buildTextField('A cuenta', aCuentaController,
                    keyboardType: TextInputType.number),
                _buildTextField('Resta', restaController,
                    keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ordersCollection.doc(docId).update({
                    'nombreCliente': nombreController.text.trim(),
                    'numeroContacto': telefonoController.text.trim(),
                    'marca': marcaController.text.trim(),
                    'modelo': modeloController.text.trim(),
                    'color': colorController.text.trim(),
                    'falla': fallaController.text.trim(),
                    'observaciones': observacionesController.text.trim(),
                    'memoria': memoriaController.text.trim(),
                    'chip': chipController.text.trim(),
                    'funda': fundaController.text.trim(),
                    'pin': pinController.text.trim(),
                    'total': totalController.text.trim(),
                    'aCuenta': aCuentaController.text.trim(),
                    'resta': restaController.text.trim(),
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Orden modificada correctamente')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al modificar: $e')),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  /// Convierte un documento Firestore en un objeto Order.
  Order _orderFromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Order(
      folio: data['folio']?.toString() ?? '',
      telefono: data['numeroContacto'] ?? '',
      nombreCliente: data['nombreCliente'] ?? '',
      fecha: data['fecha'] ?? '',
      marca: data['marca'] ?? '',
      modelo: data['modelo'] ?? '',
      color: data['color'] ?? '',
      falla: data['falla'] ?? '',
      observaciones: data['observaciones'] ?? '',
      memoria: data['memoria'] ?? '',
      chip: data['chip'] ?? '',
      funda: data['funda'] ?? '',
      pin: data['pin'] ?? '',
      total: data['total'] ?? '',
      aCuenta: data['aCuenta'] ?? '',
      resta: data['resta'] ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color textColor = Color(0xFF141414);
    const Color textSecondaryColor = Color(0xFF3E4D5B);
    const Color buttonGray = Color(0xFFF0F2F5);
    const Color borderColor = Color(0xFFF0F2F5);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header con botón de regreso y título
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: borderColor, width: 1),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: textColor),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Órdenes Activas',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        letterSpacing: -0.015,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Lista de órdenes con actualización en tiempo real
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: ordersCollection.orderBy('folio').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text('No hay órdenes'));
                  }

                  final ordersFromFirestore = docs.map(_orderFromDoc).toList();

                  return ListView.separated(
                    itemCount: ordersFromFirestore.length,
                    separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: borderColor),
                    itemBuilder: (context, index) {
                      final order = ordersFromFirestore[index];
                      final docId = docs[index].id;
                      return Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Información básica de la orden
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Folio: ${order.folio}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Teléfono: ${order.telefono}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.normal,
                                      color: textSecondaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${order.marca} ${order.modelo}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Botón para ver detalles
                            TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: buttonGray,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                minimumSize: const Size(84, 32),
                              ),
                              onPressed: () => _showOrderDetailsDialog(order, docId),
                              child: Text(
                                'Ver Detalles',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget auxiliar para construir campos de texto en el diálogo de edición.
  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

/// Modelo que representa una orden.
class Order {
  final String folio;
  final String telefono;
  final String nombreCliente;
  final String fecha;
  final String marca;
  final String modelo;
  final String color;
  final String falla;
  final String observaciones;
  final String memoria;
  final String chip;
  final String funda;
  final String pin;
  final String total;
  final String aCuenta;
  final String resta;

  Order({
    required this.folio,
    required this.telefono,
    required this.nombreCliente,
    required this.fecha,
    required this.marca,
    required this.modelo,
    required this.color,
    required this.falla,
    required this.observaciones,
    required this.memoria,
    required this.chip,
    required this.funda,
    required this.pin,
    required this.total,
    required this.aCuenta,
    required this.resta,
  });
}