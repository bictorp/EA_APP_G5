import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Explorar', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: const Center(
        child: Text('Próximamente: Buscador de usuarios', style: TextStyle(color: Colors.white70)),
      ),
    );
  }
}
