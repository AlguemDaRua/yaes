import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:limousineexecutive/passenger/models/passenger_state.dart';
import 'package:limousineexecutive/passenger/pages/pick_location_on_map.dart';
import 'package:limousineexecutive/services/location_service.dart';
import 'package:provider/provider.dart';

class SearchModal extends StatefulWidget {
  const SearchModal({super.key});
  @override
  State<SearchModal> createState() => _SearchModalState();
}

class _SearchModalState extends State<SearchModal> {
  Map<String, dynamic> _stop = {};
  bool isAddSelected = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      // Column needs a minimum size for the modal to calculate height
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Handle bar ──
        SizedBox(height: 12.sp),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(40),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        SizedBox(height: 18.sp),

        // ── Title row with icon badge ──
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.sp),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.sp),
                decoration: BoxDecoration(
                  color: const Color(0xffe5a400).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.pin_drop_rounded,
                  color: const Color(0xffe5a400),
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.sp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paragens',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 18.sp,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'Adicione ou gerencie suas paragens',
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.sp),

        if (isAddSelected == true)
          // ── Search field ──
          Container(
            margin: EdgeInsets.symmetric(horizontal: 18.sp),
            padding: EdgeInsets.symmetric(horizontal: 4.sp),
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xffe5a400).withAlpha(40),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 8,
                  child: TextField(
                    autofocus: true, // Auto-focus when the modal opens
                    textInputAction: TextInputAction
                        .search, // force search button on keyboard
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: "Introduza uma paragem",
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 13.sp,
                        color: Colors.grey.shade400,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: const Color(0xffe5a400),
                        size: 20.sp,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: EdgeInsets.symmetric(vertical: 15.sp),
                    ),
                    onChanged: (value) {
                      // to update the results list below
                      EasyDebounce.debounce(
                        'search-debounce',
                        const Duration(milliseconds: 700),
                        () => _onSearchChanged(value),
                      );
                    },
                  ),
                ),

                // Escolher no mapa
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PickLocationOnMap(text: 'Stop'),
                        ),
                      );
                      if (!context.mounted) return;
                      // Remove focus from all inputs
                      FocusScope.of(context).unfocus();
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: 6.sp),
                      height: 34.sp,
                      decoration: BoxDecoration(
                        color: const Color(0xffe5a400),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xffe5a400).withAlpha(50),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Mapa',
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // SPACE FOR RESULTS LIST
        Expanded(
          child: isAddSelected == true
              ? _listViewSuggestions()
              : _listViewCurrentStops(),
        ),
      ],
    );
  }

  ListView _listViewSuggestions() {
    final appState = Provider.of<PassengerState>(context);
    return ListView(
      // shrinkWrap: true; // importante se estiver dentro de outro scroll
      scrollDirection: Axis.vertical,
      padding: EdgeInsets.symmetric(horizontal: 4.sp, vertical: 6.sp),
      children: List.generate(appState.address.length, (index) {
        final addr = appState.address[index];
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 14.sp, vertical: 4.sp),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xffe5a400).withAlpha(40),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(5),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.sp,
              vertical: 4.sp,
            ),
            leading: Container(
              width: 40.sp,
              height: 40.sp,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                LocationService.iconForPlace(addr["type"]),
                color: const Color(0xffe5a400),
                size: 18.sp,
              ),
            ),
            title: Text(
              addr["name"] as String,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
                color: Colors.black87,
              ),
            ),
            subtitle: Text(
              addr["fullName"] as String,
              style: GoogleFonts.poppins(
                fontSize: 11.sp,
                color: Colors.grey.shade500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              setState(() {
                _stop = addr;
                Navigator.pop(context, _stop);
              });
            },
          ),
        );
      }),
    );
  }

  ListView _listViewCurrentStops() {
    // General state for stops
    final appState = Provider.of<PassengerState>(context);
    return ListView(
      scrollDirection: Axis.vertical,
      padding: EdgeInsets.symmetric(horizontal: 4.sp, vertical: 4.sp),
      children: [
        // ── Add stop button ──
        GestureDetector(
          onTap: () {
            setState(() {
              isAddSelected = true;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            margin: EdgeInsets.symmetric(horizontal: 18.sp, vertical: 5.sp),
            padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 14.sp),
            decoration: BoxDecoration(
              color: const Color(0xffe5a400).withAlpha(15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xffe5a400).withAlpha(60),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48.sp,
                  height: 48.sp,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: const Color(0xffe5a400),
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 14.sp),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Adicionar Paragem',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15.sp,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 2.sp),
                      Text(
                        'Pesquisar ou escolher no mapa',
                        style: GoogleFonts.poppins(
                          fontSize: 11.sp,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: const Color(0xffe5a400),
                  size: 16.sp,
                ),
              ],
            ),
          ),
        ),

        // ── Stops section header ──
        if (appState.stops.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: 22.sp, top: 16.sp, bottom: 8.sp),
            child: Text(
              'Suas Paragens',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 14.sp,
                color: Colors.black54,
              ),
            ),
          ),

        // ── Reorderable list view ──
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorderItem: (oldIndex, newIndex) {
            setState(() {
              final item = appState.removeStopAt(oldIndex);
              if (item != null) appState.insertStop(newIndex, item);
            });
          },
          children: [
            for (int i = 0; i < appState.stops.length; i++)
              Container(
                key: ValueKey(appState.stops[i]['name']),
                margin: EdgeInsets.symmetric(horizontal: 18.sp, vertical: 4.sp),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xffe5a400).withAlpha(40),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.sp,
                    vertical: 2.sp,
                  ),
                  leading: Container(
                    width: 36.sp,
                    height: 36.sp,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(8),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.sp,
                          color: const Color(0xffe5a400),
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    appState.stops[i]['name'],
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 14.sp,
                      color: Colors.black87,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            appState.removeStopAt(i);
                          });
                        },
                        child: Container(
                          width: 32.sp,
                          height: 32.sp,
                          decoration: BoxDecoration(
                            color: Colors.red.withAlpha(15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.red.shade400,
                            size: 16.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.sp),
                      ReorderableDragStartListener(
                        index: i,
                        child: Container(
                          width: 32.sp,
                          height: 32.sp,
                          decoration: BoxDecoration(
                            color: Colors.grey.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.drag_handle_rounded,
                            color: Colors.grey.shade400,
                            size: 18.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _onSearchChanged(String query) async {
    final appState = Provider.of<PassengerState>(context, listen: false);
    try {
      final results = await LocationService.searchPlacesOSM(query);
      setState(() {
        appState.address = results;
      });
    } catch (e) {
      // Falha de rede ou geocoder: mantém a lista de resultados anterior.
    }
  }
}

Future<Map<String, dynamic>?> showSearchStopModal(BuildContext context) {
  // Calculate 70% of the total screen height
  final double screenHeight = MediaQuery.of(context).size.height;
  final double modalHeight = screenHeight * 0.7;

  final stop = showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled:
        true, // Allows the modal to occupy more than half the screen
    backgroundColor: Colors.transparent, // Required for rounded border
    builder: (context) {
      return Container(
        height: modalHeight, // Apply the calculated height
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        // Widget that contains the drag handle and search field
        child: const SearchModal(),
      );
    },
  );

  return stop;
}
