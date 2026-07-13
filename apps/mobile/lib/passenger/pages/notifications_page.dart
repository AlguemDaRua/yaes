import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class _NotificationEntry {
  const _NotificationEntry({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final bool read;
  final DateTime? createdAt;

  factory _NotificationEntry.fromMap(String id, Map<dynamic, dynamic> map) {
    return _NotificationEntry(
      id: id,
      title: (map['title'] as String?) ?? '',
      body: (map['body'] as String?) ?? '',
      type: (map['type'] as String?) ?? '',
      read: map['read'] == true,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? ''),
    );
  }

  ({IconData icon, Color color}) get style {
    switch (type) {
      case 'new_trip':
        return (icon: Icons.local_taxi_rounded, color: const Color(0xffe5a400));
      case 'trip_accepted':
      case 'trip_started':
        return (icon: Icons.directions_car_rounded, color: Colors.blue);
      case 'trip_completed':
        return (icon: Icons.check_circle_rounded, color: Colors.green);
      case 'trip_cancelled':
        return (icon: Icons.cancel_rounded, color: Colors.red);
      case 'chat_message':
        return (icon: Icons.chat_bubble_rounded, color: Colors.purple);
      case 'schedule_created':
      case 'schedule_time_changed':
        return (icon: Icons.event_rounded, color: Colors.teal);
      case 'broadcast':
        return (icon: Icons.campaign_rounded, color: Colors.deepOrange);
      default:
        return (icon: Icons.notifications_rounded, color: Colors.grey);
    }
  }
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<_NotificationEntry> _entries = const [];
  bool _loading = true;

  DatabaseReference? get _ref {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    return uid == null ? null : FirebaseDatabase.instance.ref('notifications/$uid');
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final DatabaseReference? ref = _ref;
    if (ref == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final DataSnapshot snap = await ref.get();
      final Object? raw = snap.value;
      final List<_NotificationEntry> entries = <_NotificationEntry>[
        if (raw is Map)
          for (final MapEntry<dynamic, dynamic> e in raw.entries)
            if (e.value is Map)
              _NotificationEntry.fromMap(e.key.toString(), e.value as Map),
      ]..sort((a, b) {
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAsRead(_NotificationEntry entry) async {
    if (entry.read) return;
    final DatabaseReference? ref = _ref;
    if (ref == null) return;
    setState(() {
      _entries = <_NotificationEntry>[
        for (final _NotificationEntry e in _entries)
          if (e.id == entry.id)
            _NotificationEntry(
              id: e.id, title: e.title, body: e.body, type: e.type,
              read: true, createdAt: e.createdAt,
            )
          else
            e,
      ];
    });
    await ref.child('${entry.id}/read').set(true).catchError((_) {});
  }

  Future<void> _markAllAsRead() async {
    final DatabaseReference? ref = _ref;
    if (ref == null || _entries.every((e) => e.read)) return;
    setState(() {
      _entries = <_NotificationEntry>[
        for (final _NotificationEntry e in _entries)
          _NotificationEntry(
            id: e.id, title: e.title, body: e.body, type: e.type,
            read: true, createdAt: e.createdAt,
          ),
      ];
    });
    await Future.wait(
      _entries.map((e) => ref.child('${e.id}/read').set(true).catchError((_) {})),
    );
  }

  String _relativeTime(DateTime? date) {
    if (date == null) return '';
    final Duration diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('dd/MM', 'pt_PT').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(
          'Notificações',
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
        actions: [
          IconButton(
            icon: Icon(Icons.done_all, color: const Color(0xffe5a400), size: 24.sp),
            onPressed: _markAllAsRead,
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _entries.isEmpty
                ? LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_off_outlined,
                                  size: 80.sp, color: Colors.grey.shade300),
                              SizedBox(height: 16.sp),
                              Text(
                                'Sem Notificações',
                                style: GoogleFonts.poppins(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 20.sp, vertical: 10.sp),
                    itemCount: _entries.length,
                    itemBuilder: (context, index) {
                      final _NotificationEntry notif = _entries[index];
                      final style = notif.style;
                      return GestureDetector(
                        onTap: () => _markAsRead(notif),
                        child: Container(
                          margin: EdgeInsets.only(bottom: 16.sp),
                          padding: EdgeInsets.all(16.sp),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: notif.read
                                ? null
                                : Border.all(color: style.color.withAlpha(60), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(5),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: EdgeInsets.all(12.sp),
                                decoration: BoxDecoration(
                                  color: style.color.withAlpha(20),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(style.icon, color: style.color, size: 24.sp),
                              ),
                              SizedBox(width: 16.sp),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            notif.title,
                                            style: GoogleFonts.poppins(
                                              fontSize: 15.sp,
                                              fontWeight: notif.read
                                                  ? FontWeight.w600
                                                  : FontWeight.w700,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _relativeTime(notif.createdAt),
                                          style: GoogleFonts.poppins(
                                            fontSize: 11.sp,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 6.sp),
                                    Text(
                                      notif.body,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13.sp,
                                        color: Colors.grey.shade600,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
