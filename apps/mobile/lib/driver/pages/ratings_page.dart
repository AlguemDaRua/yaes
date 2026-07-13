import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class _RatingEntry {
  const _RatingEntry({
    required this.value,
    required this.comment,
    required this.createdAt,
  });

  final double value;
  final String? comment;
  final DateTime? createdAt;

  factory _RatingEntry.fromMap(Map<dynamic, dynamic> map) {
    return _RatingEntry(
      value: (map['value'] as num?)?.toDouble() ?? 0,
      comment: (map['comment'] as String?)?.trim().isNotEmpty == true
          ? map['comment'] as String
          : null,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? ''),
    );
  }
}

class RatingsPage extends StatefulWidget {
  const RatingsPage({super.key});

  @override
  State<RatingsPage> createState() => _RatingsPageState();
}

class _RatingsPageState extends State<RatingsPage> {
  final Color _mainColor = const Color(0xffe5a400);

  // Média e contagem REAIS do motorista (users/{uid}/rating, ratingCount).
  double _avgRating = 0;
  int _ratingCount = 0;
  List<_RatingEntry> _entries = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final profileSnap =
          await FirebaseDatabase.instance.ref('users/$uid').get();
      final profile = profileSnap.value;

      final ratingsSnap =
          await FirebaseDatabase.instance.ref('ratings/$uid').get();
      final raw = ratingsSnap.value;
      final entries = <_RatingEntry>[
        if (raw is Map)
          for (final v in raw.values)
            if (v is Map) _RatingEntry.fromMap(v),
      ]..sort((a, b) {
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });

      if (!mounted) return;
      setState(() {
        if (profile is Map) {
          _avgRating = (profile['rating'] as num?)?.toDouble() ?? 0;
          _ratingCount = (profile['ratingCount'] as num?)?.toInt() ?? 0;
        }
        _entries = entries;
        _loading = false;
      });
    } catch (_) {
      // Sem rede/permissão: mantém estado honesto (0 / lista vazia).
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(
          'Avaliações',
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
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.sp),
          child: Column(
            children: [
              SizedBox(height: 10.sp),
              _buildRatingSummaryCard(),
              SizedBox(height: 24.sp),
              if (_loading)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.sp),
                  child: const CircularProgressIndicator(),
                )
              else if (_entries.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.sp),
                  child: Column(
                    children: [
                      Icon(Icons.star_border_rounded,
                          size: 64.sp, color: Colors.grey.shade300),
                      SizedBox(height: 12.sp),
                      Text(
                        'Ainda sem avaliações',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            fontSize: 14.sp, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              else
                ...[for (final e in _entries) _buildRatingItem(e)],
              SizedBox(height: 30.sp),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingItem(_RatingEntry entry) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.sp),
      padding: EdgeInsets.all(20.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RatingBarIndicator(
                rating: entry.value,
                itemBuilder: (context, index) => Icon(Icons.star, color: _mainColor),
                itemSize: 16.sp,
              ),
              if (entry.createdAt != null)
                Text(
                  DateFormat('dd MMM yyyy', 'pt_PT').format(entry.createdAt!),
                  style: GoogleFonts.poppins(fontSize: 11.sp, color: Colors.grey.shade400),
                ),
            ],
          ),
          if (entry.comment != null) ...[
            SizedBox(height: 10.sp),
            Text(
              entry.comment!,
              style: GoogleFonts.poppins(fontSize: 13.sp, color: Colors.grey.shade700, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingSummaryCard() {
    return Container(
      padding: EdgeInsets.all(24.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _ratingCount == 0 ? '—' : _avgRating.toStringAsFixed(1),
                    style: GoogleFonts.poppins(fontSize: 48.sp, fontWeight: FontWeight.w800, color: Colors.black87),
                  ),
                  RatingBarIndicator(
                    rating: _avgRating,
                    itemBuilder: (context, index) => Icon(Icons.star, color: _mainColor),
                    itemSize: 20.sp,
                  ),
                  SizedBox(height: 8.sp),
                  Text(
                    _ratingCount == 1
                        ? '1 avaliação'
                        : 'Total de $_ratingCount avaliações',
                    style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
