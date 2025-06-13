// lib/inventario.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Pantalla principal para gestionar el inventario de productos.
class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  // Colores usados en la UI
  static const Color textColor = Color(0xFF141414);
  static const Color secondaryColor = Color(0xFF3E4D5B);
  static const Color backgroundColor = Colors.white;
  static const Color borderColor = Color(0xFFDBE1E6);
  static const Color buttonBackground = Color(0xFFF0F2F5);

  // Referencia a la colección 'inventario' en Firestore
  final CollectionReference inventoryCollection =
  FirebaseFirestore.instance.collection('inventario');

  /// Muestra un diálogo para ver y modificar la cantidad de un producto,
  /// o eliminarlo del inventario.
  void _showItemDetailsDialog(InventoryItem item, String docId) {
    int cantidad = item.cantidad;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(
                '${item.marca} ${item.modelo}'.trim(),
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Cantidad:',
                    style: GoogleFonts.plusJakartaSans(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Botón para disminuir cantidad
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.red, size: 32),
                        onPressed: () {
                          if (cantidad > 0) {
                            setStateDialog(() {
                              cantidad--;
                            });
                          }
                        },
                      ),
                      // Muestra la cantidad actual
                      Container(
                        width: 60,
                        alignment: Alignment.center,
                        child: Text(
                          '$cantidad',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      // Botón para aumentar cantidad
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline,
                            color: Colors.green, size: 32),
                        onPressed: () {
                          setStateDialog(() {
                            cantidad++;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                // Botón para eliminar producto
                TextButton.icon(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                  onPressed: () async {
                    Navigator.pop(context);
                    await inventoryCollection.doc(docId).delete();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Producto eliminado')),
                    );
                  },
                ),
                // Botón para guardar cambios en cantidad
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await inventoryCollection.doc(docId).update({'cantidad': cantidad});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Cantidad actualizada a $cantidad')),
                    );
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Muestra un diálogo para agregar un nuevo producto al inventario.
  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AddProductDialog(
          onSave: (newItem) async {
            await inventoryCollection.add(newItem.toMap());
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                  Text('Producto agregado: ${newItem.marca} ${newItem.modelo}')),
            );
          },
        );
      },
    );
  }

  /// Convierte un documento Firestore en un objeto InventoryItem.
  InventoryItem _itemFromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InventoryItem(
      marca: data['marca'] ?? '',
      modelo: data['modelo'] ?? '',
      pieza: data['pieza'] ?? '',
      cantidad: data['cantidad'] ?? 0,
      observaciones: data['observaciones'] ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header con botón de regreso y título
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: textColor, size: 24),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  Center(
                    child: Text(
                      'Inventario',
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
            // Subtítulo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Vista de tu Inventario',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: -0.015,
                  ),
                ),
              ),
            ),
            // Lista de productos en inventario con actualización en tiempo real
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: inventoryCollection.orderBy('marca').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text('No hay productos en inventario'));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final item = _itemFromDoc(doc);
                      return InkWell(
                        onTap: () => _showItemDetailsDialog(item, doc.id),
                        child: Container(
                          color: backgroundColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  // Placeholder para imagen o icono
                                  Container(
                                    width: 56,
                                    height: 75,
                                    decoration: BoxDecoration(
                                      color: buttonBackground,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: borderColor),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Información del producto: marca, modelo y cantidad
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${item.marca} ${item.modelo}'.trim(),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                      ),
                                      Text(
                                        'Cantidad: ${item.cantidad}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.normal,
                                          color: secondaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // Botón para agregar nuevo producto
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: backgroundColor,
              child: ElevatedButton(
                onPressed: _showAddProductDialog,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Agregar nuevo producto',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Diálogo para agregar un nuevo producto al inventario.
class AddProductDialog extends StatefulWidget {
  final void Function(InventoryItem newItem) onSave;

  const AddProductDialog({super.key, required this.onSave});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();

  // Listas de opciones para marca y pieza
  final List<String> marcas = ['Apple', 'Samsung', 'Motorola', 'Genérico'];

  final List<String> piezas = [
    'Display',
    'Batería',
    'Centro de carga',
    'Cámaras',
    'Marco',
    'Mica',
    'Funda',
    'Otro',
  ];

  String? selectedMarca;
  String? selectedPieza;
  String? otroPieza;
  String modelo = '';
  int cantidad = 1;
  String observaciones = '';

  @override
  void initState() {
    super.initState();
    selectedMarca = marcas.first;
    selectedPieza = piezas.first;
  }

  /// Maneja el cambio en la selección de pieza,
  /// resetea el campo de "otro" si no es seleccionado.
  void _onPiezaChanged(String? value) {
    if (value == null) return;
    setState(() {
      selectedPieza = value;
      if (selectedPieza != 'Otro') {
        otroPieza = null;
      }
    });
  }

  /// Valida y guarda el formulario, luego llama al callback onSave.
  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final item = InventoryItem(
        marca: selectedMarca ?? '',
        modelo: modelo,
        pieza: selectedPieza == 'Otro' ? (otroPieza ?? '') : (selectedPieza ?? ''),
        cantidad: cantidad,
        observaciones: observaciones,
      );

      widget.onSave(item);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Agregar nuevo producto',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Selector de marca
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Marca'),
                value: selectedMarca,
                items: marcas.map((marca) {
                  return DropdownMenuItem(value: marca, child: Text(marca));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedMarca = value;
                  });
                },
                validator: (value) =>
                value == null || value.isEmpty ? 'Seleccione una marca' : null,
              ),
              const SizedBox(height: 12),
              // Campo para modelo
              TextFormField(
                decoration: const InputDecoration(labelText: 'Modelo'),
                onChanged: (value) => modelo = value,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingrese un modelo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // Selector de pieza
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Pieza'),
                value: selectedPieza,
                items: piezas.map((pieza) {
                  return DropdownMenuItem(value: pieza, child: Text(pieza));
                }).toList(),
                onChanged: _onPiezaChanged,
                validator: (value) =>
                value == null || value.isEmpty ? 'Seleccione una pieza' : null,
              ),
              // Campo para especificar pieza si es "Otro"
              if (selectedPieza == 'Otro') ...[
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Especifique la pieza'),
                  onChanged: (value) => otroPieza = value,
                  validator: (value) {
                    if (selectedPieza == 'Otro' &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Por favor especifique la pieza';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 12),
              // Selector de cantidad con botones + y -
              Text(
                'Cantidad:',
                style: GoogleFonts.plusJakartaSans(fontSize: 16),
              ),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (context, setStateCantidad) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.red, size: 32),
                        onPressed: () {
                          if (cantidad > 1) {
                            setStateCantidad(() {
                              cantidad--;
                            });
                          }
                        },
                      ),
                      Container(
                        width: 60,
                        alignment: Alignment.center,
                        child: Text(
                          '$cantidad',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline,
                            color: Colors.green, size: 32),
                        onPressed: () {
                          setStateCantidad(() {
                            cantidad++;
                          });
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              // Campo para observaciones adicionales
              TextFormField(
                decoration: const InputDecoration(labelText: 'Observaciones'),
                maxLines: 3,
                onSaved: (value) {
                  observaciones = value ?? '';
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Botón cancelar
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        // Botón guardar
        ElevatedButton(
          onPressed: _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

/// Modelo que representa un producto en inventario.
class InventoryItem {
  final String marca;
  final String modelo;
  final String pieza;
  int cantidad;
  final String observaciones;

  InventoryItem({
    required this.marca,
    required this.modelo,
    required this.pieza,
    required this.cantidad,
    required this.observaciones,
  });

  /// Normaliza texto para comparaciones y búsquedas:
  /// convierte a minúsculas, elimina espacios y quita acentos.
  String _normalizar(String texto) {
    String sinAcentos = texto.toLowerCase().trim();
    const withAccents = 'áéíóúüñÁÉÍÓÚÜÑ';
    const withoutAccents = 'aeiouunAEIOUUN';

    for (int i = 0; i < withAccents.length; i++) {
      sinAcentos = sinAcentos.replaceAll(withAccents[i], withoutAccents[i]);
    }
    return sinAcentos;
  }

  /// Convierte el objeto a un mapa para guardar en Firestore,
  /// incluyendo campos normalizados para facilitar búsquedas.
  Map<String, dynamic> toMap() {
    return {
      'marca': marca,
      'modelo': modelo,
      'pieza': pieza,
      'cantidad': cantidad,
      'observaciones': observaciones,
      'marca_normalizada': _normalizar(marca),
      'modelo_normalizado': _normalizar(modelo),
      'pieza_normalizada': _normalizar(pieza),
    };
  }
}