import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'order_tracking_controller.dart';

// OSM
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';

class OrderTrackingView extends StatelessWidget {
  const OrderTrackingView({super.key});

  // 🎨 نفس جو "طلباتي"
  static const Color kPrimary = Color(0xFF6F3F17); // البني الثقيل
  static const Color kBg = Color(0xFFF7F4EF);      // خلفية كريمية
  static const Color kCard = Colors.white;         // كروت بيضاء ناعمة;
  static const Color kTimelineBg = Color(0xFFF0E4D7);
  static const Color kDriverAccent = Color(0xFFFFA726); // لون خفيف للشاحنة

  @override
  Widget build(BuildContext context) {
    final c = Get.put(OrderTrackingController());

    // NEW: MapController لتحريك الخريطة تلقائيًا
    final mapCtrl = fm.MapController();

    // 🌓 ثيم
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const brown = Color(0xFF6F3F17);
    final Color primaryIconColor = isDark ? brown : kPrimary;
    final Color bgColor = isDark ? theme.scaffoldBackgroundColor : kBg;
    final Color cardColor = isDark ? theme.cardColor : kCard;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Obx(() {
        final current = c.stepIndex.value.clamp(0, 3);
        final st = c.status.value;

        // لو فيه موقع سائق .. حرّك الخريطة فورًا عليه
        final LatLng? dpos = c.driverPos.value;
        if (dpos != null) {
          // تحريك خفيف بدون أي حذف أو تغيير في البنية
          Future.microtask(() {
            mapCtrl.move(dpos, 15);
          });
        }

        final LatLng fallbackCenter = const LatLng(31.206518, 16.588744);
        final LatLng center = dpos ??
            c.destPos.value ??
            c.pickupPos.value ??
            fallbackCenter;

        // markers بإصدار flutter_map 7.x يستخدم child بدل builder
        final List<fm.Marker> markers = <fm.Marker>[];

        if (c.pickupPos.value != null) {
          markers.add(
            fm.Marker(
              point: c.pickupPos.value!,
              width: 36,
              height: 36,
              child: const Icon(
                Icons.store_mall_directory,
                color: brown,
                size: 28,
              ),
            ),
          );
        }

        if (c.destPos.value != null) {
          markers.add(
            fm.Marker(
              point: c.destPos.value!,
              width: 36,
              height: 36,
              child: const Icon(
                Icons.home_filled,
                color: Colors.greenAccent,
                size: 28,
              ),
            ),
          );
        }

        if (dpos != null) {
          markers.add(
            fm.Marker(
              point: dpos,
              width: 42,
              height: 42,
              child: const Icon(
                Icons.local_shipping_rounded,
                color: kDriverAccent,
                size: 34,
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            centerTitle: true,
            title: Text(
              'تتبّع الطلب',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: primaryIconColor,
              ),
            ),
            iconTheme: IconThemeData(color: primaryIconColor),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: _TrackingTimeline(
                  currentStep: current,
                  activeColor: primaryIconColor,
                  inactiveColor: brown.withOpacity(.25),
                  labels: const [
                    'تم تقديم\nالطلب',
                    'تم تأكيد\nالطلب',
                    'تحضير\nالسّلعة',
                    'التسليم\nفي الطريق',
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // كرت رقم الطلب + الحالة (بنفس روح "طلباتي")
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.4 : 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long, color: primaryIconColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'رقم الطلب: ${c.orderId.value ?? "-"}',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              c.arabicStatus,
                              style: TextStyle(
                                color:
                                    isDark ? Colors.white70 : Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => c.onReady(), // تحديث سريع
                        child: CircleAvatar(
                          backgroundColor:
                              isDark ? Colors.black54 : kBg,
                          child: Icon(
                            Icons.refresh,
                            color: primaryIconColor,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // الخريطة (OSM) داخل كرت ناعم
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      children: [
                        fm.FlutterMap(
                          mapController: mapCtrl, // NEW
                          key: ValueKey(
                            '${center.latitude},${center.longitude},${markers.length}',
                          ),
                          options: fm.MapOptions(
                            initialCenter: center,
                            initialZoom: 13,
                          ),
                          children: [
                            fm.TileLayer(
                              urlTemplate:
                                  'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                              subdomains: const ['a', 'b', 'c'],
                              userAgentPackageName: 'com.evoranta.app',
                            ),
                            fm.MarkerLayer(markers: markers),
                          ],
                        ),

                        if (st == 'rejected' || st == 'cancelled')
                          _statusBanner('تم إلغاء الطلب', Colors.red),
                        if (st == 'delivered')
                          _statusBanner('تم التسليم بنجاح', Colors.green),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: primaryIconColor,
            onPressed: () => c.onReady(),
            child: const Icon(Icons.refresh, color: Colors.white),
          ),
        );
      }),
    );
  }

  Widget _statusBanner(String text, Color color) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(.95),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class _TrackingTimeline extends StatelessWidget {
  final int currentStep; // 0..3
  final List<String> labels;
  final Color activeColor;
  final Color inactiveColor;

  const _TrackingTimeline({
    required this.currentStep,
    required this.labels,
    required this.activeColor,
    required this.inactiveColor,
  }) : assert(labels.length == 4);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color bg =
        isDark ? theme.cardColor.withOpacity(0.25) : OrderTrackingView.kTimelineBg;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(labels.length * 2 - 1, (i) {
          if (i.isOdd) {
            final leftIndex = (i - 1) ~/ 2;
            final done = currentStep > leftIndex;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 11),
                height: 2,
                decoration: BoxDecoration(
                  color: done ? activeColor : inactiveColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          } else {
            final idx = i ~/ 2;
            final isActive = currentStep >= idx;
            return _StepNode(
              label: labels[idx],
              active: isActive,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
            );
          }
        }),
      ),
    );
  }
}

class _StepNode extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final Color inactiveColor;

  const _StepNode({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const brown = Color(0xFF6F3F17);

    final circleColor = active ? activeColor : inactiveColor;
    final textColor = isDark
        ? brown
        : (active ? OrderTrackingView.kPrimary : Colors.brown[300]);

    return Column(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
          ),
          child: active
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 70,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              height: 1.2,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
