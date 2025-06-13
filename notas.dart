// lib/notas.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotasScreen extends StatefulWidget {
  const NotasScreen({super.key});

  @override
  State<NotasScreen> createState() => _NotasScreenState();
}

class _NotasScreenState extends State<NotasScreen> {
  // Controladores para los campos de texto
  final TextEditingController nombreClienteController = TextEditingController();
  final TextEditingController numeroContactoController = TextEditingController();
  final TextEditingController fechaController = TextEditingController();
  final TextEditingController folioController = TextEditingController();

  final TextEditingController marcaController = TextEditingController();
  final TextEditingController modeloController = TextEditingController();
  final TextEditingController colorController = TextEditingController();
  final TextEditingController fallaController = TextEditingController();
  final TextEditingController observacionesController = TextEditingController();
  final TextEditingController memoriaController = TextEditingController();
  final TextEditingController chipController = TextEditingController();
  final TextEditingController fundaController = TextEditingController();
  final TextEditingController pinController = TextEditingController();

  final TextEditingController totalController = TextEditingController();
  final TextEditingController aCuentaController = TextEditingController();
  final TextEditingController restaController = TextEditingController();

  final CollectionReference _notasCollection = FirebaseFirestore.instance.collection('notas');

  @override
  void initState() {
    super.initState();
    _initForm();
  }

  /// Inicializa el formulario, estableciendo la fecha actual y el folio siguiente.
  Future<void> _initForm() async {
    final now = DateTime.now();
    fechaController.text = "${now.day.toString().padLeft(2,'0')}/${now.month.toString().padLeft(2,'0')}/${now.year}";

    try {
      // Obtener el último folio guardado en Firestore
      final querySnapshot = await _notasCollection
          .orderBy('folio', descending: true)
          .limit(1)
          .get();

      int lastFolio = 0;
      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data() as Map<String, dynamic>;
        if (data['folio'] is int) {
          lastFolio = data['folio'] as int;
        } else if (data['folio'] is String) {
          lastFolio = int.tryParse(data['folio']) ?? 0;
        }
      }

      folioController.text = (lastFolio + 1).toString();

      // Guardar en SharedPreferences para acceso rápido (opcional)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_folio', lastFolio);
    } catch (e) {
      // En caso de error, usar SharedPreferences o 0
      final prefs = await SharedPreferences.getInstance();
      final lastFolio = prefs.getInt('last_folio') ?? 0;
      folioController.text = (lastFolio + 1).toString();
    }
  }

  @override
  void dispose() {
    // Liberar controladores
    nombreClienteController.dispose();
    numeroContactoController.dispose();
    fechaController.dispose();
    folioController.dispose();

    marcaController.dispose();
    modeloController.dispose();
    colorController.dispose();
    fallaController.dispose();
    observacionesController.dispose();
    memoriaController.dispose();
    chipController.dispose();
    fundaController.dispose();
    pinController.dispose();

    totalController.dispose();
    aCuentaController.dispose();
    restaController.dispose();

    super.dispose();
  }

  /// Limpia todos los campos del formulario.
  void _limpiarCampos() {
    nombreClienteController.clear();
    numeroContactoController.clear();
    marcaController.clear();
    modeloController.clear();
    colorController.clear();
    fallaController.clear();
    observacionesController.clear();
    memoriaController.clear();
    chipController.clear();
    fundaController.clear();
    pinController.clear();
    totalController.clear();
    aCuentaController.clear();
    restaController.clear();
  }

  /// Guarda la nota en Firestore, validando campos y reemplazando vacíos con "N/A".
  Future<void> _saveNota() async {
    // Validar campos obligatorios
    if (nombreClienteController.text.isEmpty || numeroContactoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa los campos obligatorios')),
      );
      return;
    }

    final int folioNum = int.tryParse(folioController.text.trim()) ?? 0;

    // Reemplazar campos vacíos con "N/A"
    final data = <String, dynamic>{
      'nombreCliente': nombreClienteController.text.trim().isEmpty ? 'N/A' : nombreClienteController.text.trim(),
      'numeroContacto': numeroContactoController.text.trim().isEmpty ? 'N/A' : numeroContactoController.text.trim(),
      'folio': folioNum,  // Guardar como número
      'marca': marcaController.text.trim().isEmpty ? 'N/A' : marcaController.text.trim(),
      'modelo': modeloController.text.trim().isEmpty ? 'N/A' : modeloController.text.trim(),
      'color': colorController.text.trim().isEmpty ? 'N/A' : colorController.text.trim(),
      'falla': fallaController.text.trim().isEmpty ? 'N/A' : fallaController.text.trim(),
      'observaciones': observacionesController.text.trim().isEmpty ? 'N/A' : observacionesController.text.trim(),
      'memoria': memoriaController.text.trim().isEmpty ? 'N/A' : memoriaController.text.trim(),
      'chip': chipController.text.trim().isEmpty ? 'N/A' : chipController.text.trim(),
      'funda': fundaController.text.trim().isEmpty ? 'N/A' : fundaController.text.trim(),
      'pin': pinController.text.trim().isEmpty ? 'N/A' : pinController.text.trim(),
      'total': totalController.text.trim().isEmpty ? 'N/A' : totalController.text.trim(),
      'aCuenta': aCuentaController.text.trim().isEmpty ? 'N/A' : aCuentaController.text.trim(),
      'resta': restaController.text.trim().isEmpty ? 'N/A' : restaController.text.trim(),
      'fecha': fechaController.text,
      'timestamp': FieldValue.serverTimestamp(),
      'estatus': 'Pendiente',  // Campo estatus con valor por defecto
    };

    try {
      // Guardar en Firestore
      await _notasCollection.add(data);

      // Actualizar folio en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_folio', folioNum);

      // Limpiar campos y recargar folio
      _limpiarCampos();
      await _initForm();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nota guardada correctamente')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFFF8FAFB);
    const Color textColor = Color(0xFF0E141B);
    const Color placeholderColor = Color(0xFF4F7296);
    const Color inputBackground = Color(0xFFE8EDF3);
    const Color buttonBlue = Color(0xFF338AE6);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Barra superior con flecha y título
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: textColor, size: 24),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  Center(
                    child: Text(
                      'Repara tu Equipo',
                      style: GoogleFonts.manrope(
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
                  'Describe tu Dispositivo',
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: -0.015,
                  ),
                ),
              ),
            ),

            // Formulario con scroll
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sección: Info del Cliente
                    Text(
                      'Información del Cliente',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField('Nombre del Cliente', nombreClienteController, placeholderColor, inputBackground),
                    _buildTextField('Número de Contacto', numeroContactoController, placeholderColor, inputBackground, keyboardType: TextInputType.phone),
                    _buildTextField('Fecha (dd/mm/aaaa)', fechaController, placeholderColor, inputBackground, readOnly: true),
                    _buildTextField('Folio', folioController, placeholderColor, inputBackground, readOnly: true),

                    const SizedBox(height: 16),

                    // Sección: Información del Teléfono
                    Text(
                      'Información del Teléfono',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField('Marca', marcaController, placeholderColor, inputBackground),
                    _buildTextField('Modelo', modeloController, placeholderColor, inputBackground),
                    _buildTextField('Color', colorController, placeholderColor, inputBackground),
                    _buildTextField('Falla que presenta', fallaController, placeholderColor, inputBackground),
                    _buildTextField('Observaciones', observacionesController, placeholderColor, inputBackground),
                    _buildTextField('¿Se queda sin memoria?', memoriaController, placeholderColor, inputBackground),
                    _buildTextField('Chip', chipController, placeholderColor, inputBackground),
                    _buildTextField('Funda', fundaController, placeholderColor, inputBackground),
                    _buildTextField('Pin', pinController, placeholderColor, inputBackground),

                    const SizedBox(height: 16),

                    // Sección: Costo
                    Text(
                      'Costo',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField('Total', totalController, placeholderColor, inputBackground, keyboardType: TextInputType.number),
                    _buildTextField('A cuenta', aCuentaController, placeholderColor, inputBackground, keyboardType: TextInputType.number),
                    _buildTextField('Resta', restaController, placeholderColor, inputBackground, keyboardType: TextInputType.number),

                    const SizedBox(height: 24),

                    // Botón Enviar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _saveNota,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Guardar Nota',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye un campo de texto con estilo personalizado.
  Widget _buildTextField(
      String label,
      TextEditingController controller,
      Color placeholderColor,
      Color backgroundColor, {
        TextInputType keyboardType = TextInputType.text,
        bool readOnly = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: placeholderColor),
          filled: true,
          fillColor: backgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: const TextStyle(color: Colors.black87),
      ),
    );
  }
}