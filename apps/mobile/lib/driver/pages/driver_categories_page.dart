import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class DriverCategoriesPage extends StatelessWidget {
  const DriverCategoriesPage({super.key});

  static const _categories = <(String, String, IconData, String)>[
    (
      'economico',
      'Económico',
      Icons.directions_car_rounded,
      'Viagens práticas para o dia a dia',
    ),
    (
      'confort',
      'Confort',
      Icons.airline_seat_recline_extra_rounded,
      'Mais espaço e conforto',
    ),
    (
      'txopela',
      'Txopela',
      Icons.electric_rickshaw_rounded,
      'Transporte de três rodas',
    ),
    ('moto', 'Moto', Icons.two_wheeler_rounded, 'Deslocações rápidas'),
  ];

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Sessão não disponível.')),
      );
    }
    final driverRef = FirebaseDatabase.instance.ref('drivers/$uid');

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F2),
      appBar: AppBar(
        title: Text(
          'Categorias de transporte',
          style: GoogleFonts.poppins(
            fontSize: 17.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFFF6F6F2),
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: driverRef.onValue,
        builder: (context, snapshot) {
          final value = snapshot.data?.snapshot.value;
          final driver = value is Map ? value : const <dynamic, dynamic>{};
          final rawCategories = driver['categories'];
          final categories = <String, bool>{};
          if (rawCategories is Map) {
            for (final entry in rawCategories.entries) {
              categories[entry.key.toString()] = entry.value == true;
            }
          } else {
            final legacy = driver['category']?.toString();
            if (legacy != null && legacy.isNotEmpty) {
              categories[legacy] = true;
            } else {
              categories['economico'] = true;
            }
          }
          final enabledCount = categories.values
              .where((enabled) => enabled)
              .length;

          return ListView(
            padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 28.h),
            children: [
              Container(
                padding: EdgeInsets.all(18.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1D1A),
                  borderRadius: BorderRadius.circular(22.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      color: Colors.amberAccent,
                      size: 26.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Ative os tipos de viatura que pode atender. Só receberá pedidos compatíveis com as categorias ligadas.',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12.5.sp,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18.h),
              for (final (id, label, icon, subtitle) in _categories)
                Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: _CategoryPreferenceCard(
                    label: label,
                    subtitle: subtitle,
                    icon: icon,
                    enabled: categories[id] == true,
                    enabledCount: enabledCount,
                    onChanged: (enabled) async {
                      if (!enabled && enabledCount <= 1) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Mantenha pelo menos uma categoria ativa.',
                            ),
                          ),
                        );
                        return;
                      }
                      try {
                        await driverRef.child('categories/$id').set(enabled);
                      } catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Não foi possível guardar: $error'),
                          ),
                        );
                      }
                    },
                  ),
                ),
              if (snapshot.hasError)
                Text(
                  'Não foi possível carregar as categorias. Verifique a ligação e tente novamente.',
                  style: GoogleFonts.poppins(color: Colors.red.shade700),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryPreferenceCard extends StatelessWidget {
  const _CategoryPreferenceCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    required this.enabledCount,
    required this.onChanged,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final bool enabled;
  final int enabledCount;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19.r),
        border: Border.all(
          color: enabled ? const Color(0xFFE5A400) : const Color(0xFFE7E7E1),
          width: enabled ? 1.4 : 1,
        ),
      ),
      child: SwitchListTile.adaptive(
        value: enabled,
        onChanged: (value) => onChanged(value),
        activeTrackColor: const Color(0xFFE5A400),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
        secondary: Container(
          width: 46.w,
          height: 46.w,
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFFFFF3D4) : const Color(0xFFF2F2EE),
            borderRadius: BorderRadius.circular(15.r),
          ),
          child: Icon(
            icon,
            color: enabled ? const Color(0xFF9B6B00) : const Color(0xFF85867D),
            size: 24.sp,
          ),
        ),
        title: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF252720),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 10.5.sp,
            color: const Color(0xFF77786F),
          ),
        ),
      ),
    );
  }
}
