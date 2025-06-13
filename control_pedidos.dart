import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa un pedido.
class Pedido {
  final String id;
  final int folio; // Cambiado a int para facilitar búsquedas y ordenamientos
  final String marca;
  final String modelo;
  final String falla; // Daño reportado
  final String pieza; // Pieza a cambiar, ahora igual a falla
  String estatus;

  Pedido({
    required this.id,
    required this.folio,
    required this.marca,
    required this.modelo,
    required this.falla,
    required this.pieza,
    this.estatus = 'Pendiente',
  });

  /// Crea un objeto Pedido a partir de un documento Firestore.
  factory Pedido.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    int folioNum = 0;
    if (data['folio'] is int) {
      folioNum = data['folio'] as int;
    } else if (data['folio'] is String) {
      folioNum = int.tryParse(data['folio']) ?? 0;
    }
    // Aquí se asigna pieza igual a falla si pieza está vacía o no existe
    final fallaValue = data['falla'] ?? '';
    final piezaValue = (data['pieza'] == null || (data['pieza'] as String).isEmpty)
        ? fallaValue
        : data['pieza'];

    return Pedido(
      id: doc.id,
      folio: folioNum,
      marca: data['marca'] ?? '',
      modelo: data['modelo'] ?? '',
      falla: fallaValue,
      pieza: piezaValue,
      estatus: data['estatus'] ?? 'Pendiente',
    );
  }
}

/// Pantalla principal para controlar los pedidos.
class SalidasScreen extends StatefulWidget {
  const SalidasScreen({super.key});

  @override
  State<SalidasScreen> createState() => _SalidasScreenState();
}

class _SalidasScreenState extends State<SalidasScreen> {
  static const Color textColor = Color(0xFF141414);
  static const Color secondaryColor = Color(0xFF3E4D5B);
  static const Color inputBackground = Color(0xFFF0F2F5);
  static const Color borderColor = Color(0xFFDBE1E6);
  static const Color buttonBlue = Color(0xFF359EFF);

  final CollectionReference notasCollection =
  FirebaseFirestore.instance.collection('notas');

  final TextEditingController _searchController = TextEditingController();

  List<Pedido> filteredPedidos = [];
  List<String> refaccionesPendientes = [];

  /// Normaliza texto: convierte a minúsculas, elimina espacios y quita acentos.
  String normalizar(String texto) {
    String sinAcentos = texto.toLowerCase().trim();
    const withAccents = 'áéíóúüñÁÉÍÓÚÜÑ';
    const withoutAccents = 'aeiouunAEIOUUN';

    for (int i = 0; i < withAccents.length; i++) {
      sinAcentos = sinAcentos.replaceAll(withAccents[i], withoutAccents[i]);
    }
    return sinAcentos;
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterPedidos);
  }

  /// Filtra la lista de pedidos según el texto de búsqueda (folio).
  void _filterPedidos() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      filteredPedidos = filteredPedidos.where((p) {
        return p.folio.toString().contains(query);
      }).toList();
    });
  }

  /// Cambia el estatus del pedido en ciclo: Pendiente -> En revisión -> Listo -> Pendiente
  Future<void> _cambiarEstatus(Pedido pedido) async {
    String nuevoEstatus;
    if (pedido.estatus == 'Pendiente') {
      nuevoEstatus = 'En revisión';
    } else if (pedido.estatus == 'En revisión') {
      nuevoEstatus = 'Listo';
    } else {
      nuevoEstatus = 'Pendiente';
    }
    await notasCollection.doc(pedido.id).update({'estatus': nuevoEstatus});
    setState(() {
      pedido.estatus = nuevoEstatus;
    });
  }

  /// Verifica si la pieza está disponible en inventario comparando marca, modelo y pieza normalizados.
  Future<bool> _verificarDisponibilidad(
      String marcaNota, String modeloNota, String piezaNota) async {
    final query = await FirebaseFirestore.instance
        .collection('inventario')
        .where('marca_normalizada', isEqualTo: normalizar(marcaNota))
        .where('modelo_normalizado', isEqualTo: normalizar(modeloNota))
        .where('pieza_normalizada', isEqualTo: normalizar(piezaNota))
        .limit(1)
        .get();

    if (query.docs.isEmpty) return false;

    final data = query.docs.first.data();
    final cantidad = data['cantidad'] ?? 0;
    return cantidad > 0;
  }

  /// Muestra el detalle completo de un pedido con opciones para cambiar estatus y agregar refacciones pendientes.
  void _mostrarDetallePedido(Pedido pedido) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          Color statusColor;
          switch (pedido.estatus) {
            case 'Pendiente':
              statusColor = Colors.orange;
              break;
            case 'En revisión':
              statusColor = Colors.blue;
              break;
            case 'Listo':
              statusColor = Colors.green;
              break;
            default:
              statusColor = Colors.grey;
          }

          return AlertDialog(
            title: Text('Detalle Pedido ${pedido.folio}',
                style:
                GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Folio: ${pedido.folio}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 16)),
                  Text('Marca: ${pedido.marca}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 16)),
                  Text('Modelo: ${pedido.modelo}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 16)),
                  Text('Daño: ${pedido.falla}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 16)),
                  Text('Pieza a cambiar: ${pedido.pieza}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 16)),
                  const SizedBox(height: 12),
                  FutureBuilder<bool>(
                    future: _verificarDisponibilidad(
                        pedido.marca, pedido.modelo, pedido.pieza),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final disponible = snapshot.data!;
                      if (disponible) {
                        return Text('Pieza disponible en inventario',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 16, color: Colors.green));
                      } else {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Pieza NO disponible en inventario',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16, color: Colors.red)),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Agregar a refacciones pendientes'),
                              onPressed: () {
                                if (!refaccionesPendientes
                                    .contains(pedido.pieza)) {
                                  setState(() {
                                    refaccionesPendientes.add(pedido.pieza);
                                  });
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Pieza "${pedido.pieza}" agregada a refacciones pendientes')),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'La pieza ya está en refacciones pendientes')),
                                  );
                                }
                              },
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: statusColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () async {
                        await _cambiarEstatus(pedido);
                        setStateDialog(() {});
                      },
                      child: Text(
                        pedido.estatus,
                        style: GoogleFonts.plusJakartaSans(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          );
        });
      },
    );
  }

  /// Muestra la lista de refacciones pendientes con opción a eliminar.
  void _mostrarRefaccionesPendientes() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Refacciones Pendientes',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: refaccionesPendientes.isEmpty
                ? Text('No hay refacciones pendientes',
                style: GoogleFonts.plusJakartaSans(fontSize: 16))
                : ListView.builder(
              shrinkWrap: true,
              itemCount: refaccionesPendientes.length,
              itemBuilder: (context, index) {
                final pieza = refaccionesPendientes[index];
                return ListTile(
                  title: Text(pieza, style: GoogleFonts.plusJakartaSans()),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        refaccionesPendientes.removeAt(index);
                      });
                      Navigator.pop(context);
                      _mostrarRefaccionesPendientes();
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  /// Muestra los pedidos con estatus 'Listo' y permite marcarlos como entregados.
  void _mostrarPedidosListos() {
    showDialog(
      context: context,
      builder: (context) {
        return StreamBuilder<QuerySnapshot>(
          stream: notasCollection.where('estatus', isEqualTo: 'Listo').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return AlertDialog(
                title: const Text('Pedidos Listos'),
                content: Text('Error: ${snapshot.error}'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar')),
                ],
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return AlertDialog(
                title: const Text('Pedidos Listos'),
                content: const Text('No hay pedidos listos'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar')),
                ],
              );
            }
            final pedidosListos = docs.map((doc) => Pedido.fromDoc(doc)).toList();

            return AlertDialog(
              title: Text('Pedidos Listos',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: pedidosListos.length,
                  itemBuilder: (context, index) {
                    final pedido = pedidosListos[index];
                    return ListTile(
                      title: Text('Folio: ${pedido.folio}',
                          style: GoogleFonts.plusJakartaSans()),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          try {
                            final docSnapshot =
                            await notasCollection.doc(pedido.id).get();
                            final pedidoData =
                            docSnapshot.data() as Map<String, dynamic>?;

                            if (pedidoData != null) {
                              await FirebaseFirestore.instance
                                  .collection('historial_pedidos')
                                  .add(pedidoData);

                              await notasCollection.doc(pedido.id).delete();

                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Pedido ${pedido.folio} marcado como entregado y movido al historial')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Error: No se encontró el pedido')),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error al mover pedido: $e')),
                            );
                          }
                        },
                        child: const Text('Entregado'),
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Muestra el historial de pedidos entregados.
  void _mostrarHistorialPedidos() {
    showDialog(
      context: context,
      builder: (context) {
        return StreamBuilder<QuerySnapshot>(
          stream:
          FirebaseFirestore.instance.collection('historial_pedidos').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return AlertDialog(
                title: const Text('Historial de Pedidos'),
                content: Text('Error: ${snapshot.error}'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar')),
                ],
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return AlertDialog(
                title: const Text('Historial de Pedidos'),
                content: const Text('No hay pedidos en el historial'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar')),
                ],
              );
            }
            final pedidosHistorial = docs.map((doc) => Pedido.fromDoc(doc)).toList();

            return AlertDialog(
              title: Text('Historial de Pedidos',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: pedidosHistorial.length,
                  itemBuilder: (context, index) {
                    final pedido = pedidosHistorial[index];
                    return ListTile(
                      title: Text('Folio: ${pedido.folio}',
                          style: GoogleFonts.plusJakartaSans()),
                      onTap: () {
                        Navigator.pop(context);
                        _mostrarDetalleHistorial(pedido);
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Muestra el detalle de un pedido entregado (historial).
  void _mostrarDetalleHistorial(Pedido pedido) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Detalle Pedido Entregado ${pedido.folio}',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Folio: ${pedido.folio}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 16)),
                Text('Marca: ${pedido.marca}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 16)),
                Text('Modelo: ${pedido.modelo}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 16)),
                Text('Daño: ${pedido.falla}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 16)),
                Text('Pieza a cambiar: ${pedido.pieza}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 16)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Control de Pedidos',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Barra de búsqueda por folio
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: inputBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    alignment: Alignment.center,
                    child: const Icon(Icons.search, color: secondaryColor),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar por folio',
                        border: InputBorder.none,
                        contentPadding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        hintStyle: const TextStyle(color: secondaryColor),
                      ),
                      keyboardType: TextInputType.text,
                      onChanged: (value) {
                        _filterPedidos();
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Lista de pedidos filtrados
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: notasCollection.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;
                  List<Pedido> pedidos =
                  docs.map((doc) => Pedido.fromDoc(doc)).toList();

                  // Aplicar filtro de búsqueda
                  final query = _searchController.text.trim().toLowerCase();
                  if (query.isNotEmpty) {
                    pedidos = pedidos
                        .where((p) => p.folio.toString().contains(query))
                        .toList();
                  }

                  filteredPedidos = pedidos;

                  if (pedidos.isEmpty) {
                    return Center(
                      child: Text(
                        'No se encontraron pedidos',
                        style: GoogleFonts.plusJakartaSans(fontSize: 16),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: pedidos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final pedido = pedidos[index];
                      return GestureDetector(
                        onTap: () => _mostrarDetallePedido(pedido),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: inputBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: Text(
                            'Folio: ${pedido.folio}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
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
      // Barra inferior con botones para refacciones pendientes, pedidos listos e historial
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _mostrarRefaccionesPendientes,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text(
                  'Lista de refacciones pendientes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _mostrarPedidosListos,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text(
                  'Listo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _mostrarHistorialPedidos,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text(
                  'Historial de pedidos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}