import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'orders.dart';
import 'control_pedidos.dart';
import 'notas.dart';
import 'inventario.dart';

/// Pantalla principal de login que funciona como menú de navegación
/// hacia las diferentes secciones de la aplicación.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Definición de colores usados en la pantalla
    const Color textColor = Color(0xFF141414);
    const Color buttonBlue = Color(0xFF359EFF);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nombre del local centrado y con estilo personalizado
              Text(
                'Cell On The Move',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: 0.5,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 8),

              // Eslogan del local, texto más pequeño y ligero
              Text(
                'Tu Hospital Tecnológico de Confianza',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: textColor,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 64),

              // Botón para navegar a la pantalla de Órdenes
              ElevatedButton(
                onPressed: () {
                  // Navega a OrdersScreen al presionar
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OrdersScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: Text(
                  'Órdenes',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Botón para navegar a la pantalla de Notas
              ElevatedButton(
                onPressed: () {
                  // Navega a NotasScreen al presionar
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotasScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: Text(
                  'Notas',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Botón para navegar a la pantalla de Inventario
              ElevatedButton(
                onPressed: () {
                  // Navega a InventarioScreen al presionar
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const InventarioScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: Text(
                  'Inventario',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Botón para navegar a la pantalla de Control de Pedidos
              ElevatedButton(
                onPressed: () {
                  // Navega a SalidasScreen al presionar
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SalidasScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: Text(
                  'Control de Pedidos',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}