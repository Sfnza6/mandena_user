import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'order_tracking_controller.dart';

import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';

class OrderTrackingView extends StatelessWidget {
  const OrderTrackingView({super.key});

  static const Color kPrimary = Color(0xFFFF5A00);
  static const Color kPrimaryDark = Color(0xFFFF2E00);
  static const Color kBg = Color(0xFFF5F5F7);
  static const Color kText = Color(0xFF111827);
  static const Color kMuted = Color(0xFF8B95A7);
  static const Color kSoftOrange = Color(0xFFFFF1E9);
  static const Color kDriverAccent = Color(0xFFFFA726);

  static const List<String> _steps = [
    'استلام\nالطلب',
    'جاري\nالتحضير',
    'اختيار\nالسائق',
    'في\nالطريق',
    'تم\nالتسليم',
  ];

  @override
  Widget build(BuildContext context) {
    final c = Get.put(OrderTrackingController());
    final mapCtrl = fm.MapController();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pageBg = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? kText;
    final mutedColor =
        theme.textTheme.bodySmall?.color?.withOpacity(.8) ?? kMuted;
    final softFill = isDark ? const Color(0xFF1F2937) : kSoftOrange;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Obx(() {
        final current = c.stepIndex.value.clamp(0, _steps.length - 1);
        final LatLng? dpos = c.driverPos.value;

        if (dpos != null) {
          Future.microtask(() => mapCtrl.move(dpos, 15));
        }

        final LatLng fallbackCenter = const LatLng(31.206518, 16.588744);
        final LatLng center =
            dpos ?? c.destPos.value ?? c.pickupPos.value ?? fallbackCenter;

        final List<fm.Marker> markers = <fm.Marker>[];

        if (c.pickupPos.value != null) {
          markers.add(
            fm.Marker(
              point: c.pickupPos.value!,
              width: 42,
              height: 42,
              child: _MapPin(
                color: kPrimary,
                icon: Icons.store_mall_directory_rounded,
              ),
            ),
          );
        }

        if (c.destPos.value != null) {
          markers.add(
            fm.Marker(
              point: c.destPos.value!,
              width: 42,
              height: 42,
              child: const _MapPin(
                color: Color(0xFF16A34A),
                icon: Icons.home_rounded,
              ),
            ),
          );
        }

        if (dpos != null) {
          markers.add(
            fm.Marker(
              point: dpos,
              width: 48,
              height: 48,
              child: const _MapPin(
                color: kDriverAccent,
                icon: Icons.delivery_dining_rounded,
                size: 30,
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: pageBg,
          appBar: AppBar(
            backgroundColor: pageBg,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'تتبع الطلب',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: kPrimary,
              ),
            ),
            iconTheme: const IconThemeData(color: kPrimary),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: _TrackingTimeline(
                  currentStep: current,
                  activeColor: kPrimary,
                  inactiveColor: const Color(0xFFFFD8C2),
                  labels: _steps,
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: _StatusCard(
                  cardColor: cardColor,
                  softFill: softFill,
                  textColor: textColor,
                  mutedColor: mutedColor,
                  orderId: c.orderId.value,
                  status: c.arabicStatus,
                  hint: c.statusHint,
                  isCancelled: c.isCancelledStatus,
                  isDelivered: c.isDeliveredStatus,
                  onRefresh: c.refreshNow,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.04),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: fm.FlutterMap(
                            mapController: mapCtrl,
                            key: ValueKey(
                              '${center.latitude},${center.longitude},${markers.length}',
                            ),
                            options: fm.MapOptions(
                              initialCenter: center,
                              initialZoom: dpos == null ? 13 : 15,
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
                        ),
                        Positioned(
                          right: 12,
                          top: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: cardColor.withOpacity(.95),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              textDirection: TextDirection.rtl,
                              children: [
                                Icon(
                                  dpos == null
                                      ? Icons.location_searching_rounded
                                      : Icons.delivery_dining_rounded,
                                  color: kPrimary,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  c.arabicStatus,
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (c.isCancelledStatus)
                          _statusBanner(c.arabicStatus, Colors.red),
                        if (c.isDeliveredStatus)
                          _statusBanner('تم التسليم بنجاح', Colors.green),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: kPrimary,
            onPressed: c.refreshNow,
            child: const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
        );
      }),
    );
  }

  Widget _statusBanner(String text, Color color) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: color.withOpacity(.95),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.cardColor,
    required this.softFill,
    required this.textColor,
    required this.mutedColor,
    required this.orderId,
    required this.status,
    required this.hint,
    required this.isCancelled,
    required this.isDelivered,
    required this.onRefresh,
  });

  final Color cardColor;
  final Color softFill;
  final Color textColor;
  final Color mutedColor;
  final int? orderId;
  final String status;
  final String hint;
  final bool isCancelled;
  final bool isDelivered;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final Color statusColor = isCancelled
        ? const Color(0xFFE53935)
        : isDelivered
        ? const Color(0xFF16A34A)
        : OrderTrackingView.kPrimary;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: softFill, shape: BoxShape.circle),
            child: IconButton(
              onPressed: onRefresh,
              icon: Icon(Icons.refresh_rounded, color: statusColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'رقم الطلب: ${orderId ?? "-"}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  status,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  hint,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 12.4,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: softFill,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isDelivered
                  ? Icons.check_circle_rounded
                  : isCancelled
                  ? Icons.cancel_rounded
                  : Icons.receipt_long_rounded,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.color, required this.icon, this.size = 24});

  final Color color;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: size),
    );
  }
}

class _TrackingTimeline extends StatelessWidget {
  final int currentStep;
  final List<String> labels;
  final Color activeColor;
  final Color inactiveColor;

  const _TrackingTimeline({
    required this.currentStep,
    required this.labels,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? .18 : .035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.rtl,
        children: List.generate(labels.length * 2 - 1, (i) {
          if (i.isOdd) {
            final leftIndex = (i - 1) ~/ 2;
            final done = currentStep > leftIndex;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 11),
                height: 3,
                decoration: BoxDecoration(
                  color: done ? activeColor : inactiveColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }

          final idx = i ~/ 2;
          final isActive = currentStep >= idx;
          return _StepNode(
            label: labels[idx],
            active: isActive,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
          );
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
    final mutedColor =
        Theme.of(context).textTheme.bodySmall?.color?.withOpacity(.8) ??
        OrderTrackingView.kMuted;

    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: active ? activeColor : inactiveColor,
            shape: BoxShape.circle,
            boxShadow: active
                ? [
                    BoxShadow(
                      color: activeColor.withOpacity(.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: active
              ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 52,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? OrderTrackingView.kPrimary : mutedColor,
              fontSize: 10.2,
              height: 1.25,
              fontWeight: active ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
