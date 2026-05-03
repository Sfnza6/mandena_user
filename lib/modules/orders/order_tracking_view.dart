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

  // ignore: unused_field
  static const List<String> _steps = <String>[
    'بانتظار\\nالقبول',
    'جاري التحضير\\nوالبحث',
    'تم تعيين\\nسائق',
    'جاري\\nالتوصيل',
    'مكتملة',
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
        final labels = c.trackingSteps;
        final current = c.stepIndex.value.clamp(0, labels.length - 1);
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
              child: const _MapPin(
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
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
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
                const SizedBox(height: 4),
                Expanded(
                  flex: 10,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(24),
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
                          Positioned(
                            left: 14,
                            bottom: 14,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: c.refreshNow,
                                borderRadius: BorderRadius.circular(18),
                                child: Ink(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    color: kPrimary,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: kPrimary.withOpacity(.28),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.refresh_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (c.isCancelledStatus)
                            _statusBanner(c.arabicStatus, Colors.red),
                          if (c.isDeliveredStatus)
                            _statusBanner('مكتملة', Colors.green),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                  child: _BottomStepsCard(
                    currentStep: current,
                    labels: labels,
                    times: List<String>.generate(
                      labels.length,
                      (i) => c.stepTimeLabel(i),
                    ),
                    activeColor: kPrimary,
                    inactiveColor: const Color(0xFFFFD8C2),
                    isCancelled: c.isCancelledStatus,
                    isDelivered: c.isDeliveredStatus,
                  ),
                ),
              ],
            ),
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

class _BottomStepsCard extends StatelessWidget {
  const _BottomStepsCard({
    required this.currentStep,
    required this.labels,
    required this.times,
    required this.activeColor,
    required this.inactiveColor,
    required this.isCancelled,
    required this.isDelivered,
  });

  final int currentStep;
  final List<String> labels;
  final List<String> times;
  final Color activeColor;
  final Color inactiveColor;
  final bool isCancelled;
  final bool isDelivered;

  static const List<IconData> _icons = [
    Icons.hourglass_top_rounded,
    Icons.restaurant_rounded,
    Icons.assignment_ind_rounded,
    Icons.delivery_dining_rounded,
    Icons.check_circle_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted =
        theme.textTheme.bodySmall?.color?.withOpacity(.8) ??
        OrderTrackingView.kMuted;
    final cardColor = theme.cardColor;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'مراحل الطلب',
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isCancelled
                          ? 'تم إيقاف تقدم الطلب، ويمكنك العودة للطلبات لعمل طلب جديد.'
                          : isDelivered
                          ? 'تم الوصول إلى آخر مرحلة بنجاح.'
                          : 'يعرض وقت كل إجراء تم في الطلب: القبول، تعيين السائق، بدء التوصيل، والاكتمال.',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: muted,
                        fontSize: 10.5,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: OrderTrackingView.kSoftOrange,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isDelivered
                      ? Icons.flag_circle_rounded
                      : isCancelled
                      ? Icons.error_outline_rounded
                      : Icons.timeline_rounded,
                  color: isCancelled
                      ? Colors.red
                      : isDelivered
                      ? Colors.green
                      : activeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 124,
            child: ListView.separated(
              padding: EdgeInsets.zero,
              scrollDirection: Axis.horizontal,
              itemCount: labels.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                return _StepProgressItem(
                  label: labels[i],
                  eta: i < times.length ? times[i] : '—',
                  icon: _icons[i],
                  state: _stateForStep(i),
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  _StepVisualState _stateForStep(int index) {
    if (isCancelled) {
      return index == 0 ? _StepVisualState.active : _StepVisualState.upcoming;
    }
    if (index < currentStep) return _StepVisualState.done;
    if (index == currentStep) return _StepVisualState.active;
    return _StepVisualState.upcoming;
  }

  // ignore: unused_element
  String _etaForStep(int index) {
    if (isCancelled) {
      return index == 0 ? 'توقف الطلب' : '—';
    }
    if (index < currentStep) return 'تم الوصول';
    if (index == currentStep) return isDelivered ? 'تمت الآن' : 'الآن';

    switch (index) {
      case 1:
        return '5 - 10 د';
      case 2:
        return '10 - 20 د';
      case 3:
        return '20 - 35 د';
      case 4:
        return 'عند التسليم';
      default:
        return 'قريباً';
    }
  }
}

enum _StepVisualState { done, active, upcoming }

class _StepProgressItem extends StatelessWidget {
  const _StepProgressItem({
    required this.label,
    required this.eta,
    required this.icon,
    required this.state,
    required this.activeColor,
    required this.inactiveColor,
  });

  final String label;
  final String eta;
  final IconData icon;
  final _StepVisualState state;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    final bool isDone = state == _StepVisualState.done;
    final bool isActive = state == _StepVisualState.active;
    final theme = Theme.of(context);
    final mutedColor =
        theme.textTheme.bodySmall?.color?.withOpacity(.8) ??
        OrderTrackingView.kMuted;

    final Color ringColor = isDone || isActive ? activeColor : inactiveColor;
    final Color fillColor = isDone
        ? activeColor.withOpacity(.12)
        : isActive
        ? OrderTrackingView.kSoftOrange
        : Colors.transparent;
    final Color iconColor = isDone || isActive ? activeColor : mutedColor;
    final Color etaBg = isDone
        ? activeColor.withOpacity(.10)
        : isActive
        ? OrderTrackingView.kSoftOrange
        : const Color(0xFFF4F4F5);

    return Container(
      width: 96,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? activeColor.withOpacity(.26) : Colors.black12,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 42,
            height: 42,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 42,
                  height: 42,
                  child: CircularProgressIndicator(
                    value: isDone
                        ? 1
                        : isActive
                        ? null
                        : 1,
                    strokeWidth: isActive ? 3.6 : 2.6,
                    backgroundColor: inactiveColor.withOpacity(.55),
                    valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                  ),
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: fillColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDone ? Icons.check_rounded : icon,
                    color: iconColor,
                    size: 17,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 38,
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isActive || isDone
                      ? OrderTrackingView.kText
                      : mutedColor,
                  fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                  fontSize: 9.8,
                  height: 1.2,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: etaBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              eta,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDone || isActive ? activeColor : mutedColor,
                fontWeight: FontWeight.w800,
                fontSize: 9.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
