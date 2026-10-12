import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:limousineexecutive/passenger/pages/pick_location_on_map.dart';
import 'package:limousineexecutive/passenger/widgets/place_search_view.dart';

/// Escolher o local de uma morada guardada: pesquisar por texto ou marcar no
/// mapa. Devolve `{name, fullName, lat, lng}` (o formato de
/// `PickLocationOnMap(returnResult: true)`) ou nada se o utilizador voltar.
class PlaceSearchPage extends StatelessWidget {
  const PlaceSearchPage({super.key, required this.title});

  /// "Casa", "Trabalho" ou "Novo local".
  final String title;

  Future<void> _pickOnMap(BuildContext context) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => PickLocationOnMap(text: title, returnResult: true),
      ),
    );
    if (result == null || !context.mounted) return;
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18.sp,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: PlaceSearchView(
        onSelected: (place) => Navigator.pop(context, place),
        onPickOnMap: () => _pickOnMap(context),
      ),
    );
  }
}
