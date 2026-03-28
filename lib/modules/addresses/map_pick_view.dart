import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'map_pick_controller.dart';

class MapPickView extends StatelessWidget {
  const MapPickView({super.key});

  static const Color _brown = Color(0xFF6F3F17);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(MapPickController());
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor:
              theme.appBarTheme.backgroundColor ??
              theme.scaffoldBackgroundColor,
          elevation: 0.5,
          centerTitle: true,
          title: Text(
            'اختر الموقع على الخريطة',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: theme.brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
          iconTheme: const IconThemeData(
            color: Color.fromARGB(255, 233, 85, 0),
          ),
          actions: [
            Obx(
              () => IconButton(
                onPressed: c.isBusy.value ? null : c.myLocation,
                icon: c.isBusy.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _brown,
                        ),
                      )
                    : const Icon(
                        Icons.my_location_outlined,
                        color: Color(0xFFFF5A00),
                      ),
              ),
            ),
          ],
        ),
        body: Obx(
          () => FlutterMap(
            options: MapOptions(
              initialCenter: c.center.value,
              initialZoom: 14,
              onTap: (_, p) => c.onTap(p),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'evoranta.ly',
              ),
              if (c.marker.value != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: c.marker.value!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        size: 40,
                        color: Color(0xFFFF5A00),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              onPressed: c.confirm,
              icon: const Icon(
                Icons.check_circle_outline,
                color: Color(0xFFFF5A00),
              ),
              label: const Text('تأكيد هذا الموقع'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF5A00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
