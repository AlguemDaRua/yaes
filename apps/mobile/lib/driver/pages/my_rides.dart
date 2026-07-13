import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:limousineexecutive/repositories/auth_repository.dart';
import 'package:limousineexecutive/repositories/trip_repository.dart';
import 'package:provider/provider.dart';
import 'package:limousineexecutive/shared/widgets/skeletons.dart';

class MyRidesPage extends StatefulWidget {
  const MyRidesPage({super.key});

  @override
  State<MyRidesPage> createState() => _MyRidesPageState();
}

class _MyRidesPageState extends State<MyRidesPage> {
  int _selectedRideStatusIndex = 0;
  final Color _mainColor = const Color(0xffe5a400);

  final List<Map<String, dynamic>> _listStatus = [
    {'status': 'Em andamento', "index": 0},
    {'status': 'Completas', "index": 1},
    {'status': 'Canceladas', "index": 2},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(
          'Minhas Corridas',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18.sp,
          ),
        ),
        backgroundColor: const Color(0xFFF7F8FA),
        surfaceTintColor: const Color(0xFFF7F8FA),
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list_rounded, color: _mainColor),
            onPressed: () {},
          )
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 10.sp),
          // Status Selector Chips
          SizedBox(
            height: 45.sp,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 20.sp),
              itemCount: _listStatus.length,
              itemBuilder: (context, index) => _buildStatusChip(_listStatus[index]),
            ),
          ),
          SizedBox(height: 20.sp),
          // Rides List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: Provider.of<ITripRepository>(context, listen: false)
                  .readTripsByDriver(
                    Provider.of<IAuthRepository>(context, listen: false).currentUser!.uid,
                  ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const RideHistorySkeleton();
                }
                final trips = snapshot.data ?? [];
                
                // Filter by selected status (simplified)
                final filteredTrips = trips.where((trip) {
                  final status = trip['status']?.toString() ?? '';
                  if (_selectedRideStatusIndex == 0) return status == 'started' || status == 'accepted';
                  if (_selectedRideStatusIndex == 1) return status == 'completed';
                  if (_selectedRideStatusIndex == 2) return status == 'cancelled';
                  return true;
                }).toList();

                if (filteredTrips.isEmpty) {
                  return Center(child: Text("Nenhuma corrida encontrada", style: GoogleFonts.poppins()));
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 20.sp),
                  itemCount: filteredTrips.length,
                  itemBuilder: (context, index) => _buildRideCard(filteredTrips[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(Map<String, dynamic> status) {
    bool isSelected = _selectedRideStatusIndex == status["index"];
    return GestureDetector(
      onTap: () => setState(() => _selectedRideStatusIndex = status["index"]),
      child: Container(
        margin: EdgeInsets.only(right: 12.sp),
        padding: EdgeInsets.symmetric(horizontal: 20.sp, vertical: 8.sp),
        decoration: BoxDecoration(
          color: isSelected ? _mainColor : Colors.white,
          borderRadius: BorderRadius.circular(30.r),
          boxShadow: isSelected
              ? [BoxShadow(color: _mainColor.withAlpha(60), blurRadius: 10, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Center(
          child: Text(
            status['status'],
            style: GoogleFonts.poppins(
              fontSize: 13.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRideCard(Map<String, dynamic> trip) {
    final passengerName = trip['passengerName'] ?? 'Passageiro';
    final price = trip['estimatedPrice']?.toString() ?? '---';
    final origin = trip['origin']?['name'] ?? 'Local de recolha';
    final dest = trip['destination']?['name'] ?? 'Destino';
    
    return Container(
      margin: EdgeInsets.only(bottom: 16.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {},
          child: Padding(
            padding: EdgeInsets.all(16.sp),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _mainColor.withAlpha(50), width: 2),
                      ),
                      child: ClipOval(
                        child: Icon(Icons.person, size: 45.sp, color: Colors.grey),
                      ),
                    ),
                    SizedBox(width: 12.sp),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            passengerName,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15.sp),
                          ),
                          Text(
                            trip['status']?.toString().toUpperCase() ?? '',
                            style: GoogleFonts.poppins(fontSize: 10.sp, color: _mainColor, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$price MT',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 16.sp,
                        color: _mainColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.sp),
                _buildRoutePoint(Icons.location_on, origin, Colors.green),
                Padding(
                  padding: EdgeInsets.only(left: 10.sp),
                  child: Container(width: 1.5, height: 15.sp, color: Colors.grey.shade200),
                ),
                _buildRoutePoint(Icons.flag_rounded, dest, Colors.red),
                SizedBox(height: 12.sp),
                const Divider(height: 1),
                SizedBox(height: 12.sp),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMiniBadge(Icons.timer_outlined, trip['tipo'] ?? 'Executiva'),
                    Text(
                      'Ver detalhes',
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoutePoint(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20.sp),
        SizedBox(width: 12.sp),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(fontSize: 13.sp, color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniBadge(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade400, size: 16.sp),
        SizedBox(width: 4.sp),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

