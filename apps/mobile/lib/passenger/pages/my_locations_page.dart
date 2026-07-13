import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:limousineexecutive/passenger/pages/pick_location_on_map.dart';
import 'package:limousineexecutive/repositories/auth_repository.dart';
import 'package:limousineexecutive/repositories/trip_repository.dart';
import 'package:provider/provider.dart';

/// Moradas guardadas reais em /users/{uid}/savedLocations. "Casa" e
/// "Trabalho" são chaves fixas; "Outros locais" é uma lista livre.
class LocationsPage extends StatefulWidget {
  const LocationsPage({super.key});

  @override
  State<LocationsPage> createState() => _LocationsPageState();
}

class _LocationsPageState extends State<LocationsPage> {
  late final IAuthRepository _authRepo;
  late final ITripRepository _tripRepo;
  late final String _uid;

  @override
  void initState() {
    super.initState();
    _authRepo = Provider.of<IAuthRepository>(context, listen: false);
    _tripRepo = Provider.of<ITripRepository>(context, listen: false);
    _uid = _authRepo.currentUser?.uid ?? '';
  }

  Future<void> _pickAndSave(String label, {String? otherKey}) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => PickLocationOnMap(text: label, returnResult: true),
      ),
    );
    if (result == null || _uid.isEmpty) return;
    final key = otherKey ?? DateTime.now().millisecondsSinceEpoch.toString();
    await _tripRepo.updateProfile(_uid, {'savedLocations/$key': result});
  }

  Future<void> _removeOther(String key) async {
    await _tripRepo.updateProfile(_uid, {'savedLocations/$key': null});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(
          'Moradas Guardadas',
          style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 18.sp),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _tripRepo.watchProfile(_uid),
        builder: (context, snapshot) {
          final Map saved = (snapshot.data?['savedLocations'] as Map?) ?? {};
          final home = saved['home'] as Map?;
          final work = saved['work'] as Map?;
          final others = saved.entries.where((e) => e.key != 'home' && e.key != 'work').toList();

          return SingleChildScrollView(
            padding: EdgeInsets.all(20.sp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('As tuas moradas', style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.w600, color: Colors.black87)),
                SizedBox(height: 12.sp),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    children: [
                      _buildLocationItem(
                        icon: Icons.home_rounded,
                        title: 'Casa',
                        subtitle: home?['name']?.toString() ?? 'Adicionar morada de casa',
                        color: Colors.blue,
                        onTap: () => _pickAndSave('Casa', otherKey: 'home'),
                      ),
                      _buildDivider(),
                      _buildLocationItem(
                        icon: Icons.work_rounded,
                        title: 'Trabalho',
                        subtitle: work?['name']?.toString() ?? 'Adicionar morada do trabalho',
                        color: Colors.deepPurple,
                        onTap: () => _pickAndSave('Trabalho', otherKey: 'work'),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30.sp),
                Text('Outros locais', style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.w600, color: Colors.black87)),
                SizedBox(height: 12.sp),
                if (others.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < others.length; i++) ...[
                          if (i > 0) _buildDivider(),
                          _buildLocationItem(
                            icon: Icons.place_outlined,
                            title: (others[i].value as Map)['name']?.toString() ?? 'Local',
                            subtitle: (others[i].value as Map)['fullName']?.toString() ?? '',
                            color: Colors.teal,
                            trailing: IconButton(
                              icon: Icon(Icons.close, size: 18.sp, color: Colors.grey.shade400),
                              onPressed: () => _removeOther(others[i].key.toString()),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                SizedBox(height: 12.sp),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _pickAndSave('Novo local'),
                  child: Container(
                    padding: EdgeInsets.all(20.sp),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xffe5a400).withAlpha(50), width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_location_alt_outlined, color: const Color(0xffe5a400), size: 24.sp),
                        SizedBox(width: 12.sp),
                        Text(
                          'Adicionar novo local',
                          style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.w600, color: const Color(0xffe5a400)),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24.sp),
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40.sp),
                    child: Text(
                      'Guardar locais frequentes ajuda-te a pedir viagens mais rapidamente.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey.shade500),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(20.sp),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.sp),
                decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 22.sp),
              ),
              SizedBox(width: 16.sp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.w600, color: Colors.black87)),
                    SizedBox(height: 2.sp),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              trailing ?? Icon(Icons.add_circle_outline, color: Colors.grey.shade300, size: 20.sp),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.only(left: 68.sp, right: 20.sp),
      child: Divider(color: Colors.grey.shade100, height: 1),
    );
  }
}
