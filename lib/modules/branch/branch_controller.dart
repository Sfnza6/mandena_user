import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mandena/core/api_service.dart';
import 'package:mandena/core/env.dart';
import 'package:mandena/data/models/branch_model.dart';
import 'package:mandena/home/home_controller.dart';
import 'package:mandena/modules/cart/cart_controller.dart';
import 'package:mandena/modules/favorites/favorites_controller.dart';

class BranchController extends GetxController {
  static const String _selectedBranchKey = 'selected_branch_id';

  final ApiService _api = ApiService();
  final GetStorage _box = GetStorage();

  final loading = false.obs;
  final changing = false.obs;
  final branches = <BranchModel>[].obs;
  final selectedBranchId = 0.obs;

  BranchModel? get selectedBranch {
    final id = selectedBranchId.value;
    if (id <= 0) return null;
    try {
      return branches.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  String get selectedBranchName {
    final b = selectedBranch;
    if (b == null) return 'اختر الفرع';
    return b.name.trim().isEmpty ? 'الفرع #${b.id}' : b.name;
  }

  @override
  void onInit() {
    super.onInit();
    selectedBranchId.value = _box.read(_selectedBranchKey) ?? 0;
  }

  Future<void> initBranching() async {
    await fetchBranches();
    if (branches.isEmpty) return;

    final current = selectedBranchId.value;
    if (current > 0 && branches.any((e) => e.id == current)) return;

    final fallback = branches.cast<BranchModel?>().firstWhere(
      (e) => e?.isDefault == true,
      orElse: () => branches.first,
    );

    if (fallback != null) {
      selectedBranchId.value = fallback.id;
      await _box.write(_selectedBranchKey, fallback.id);
    }
  }

  Future<void> fetchBranches() async {
    try {
      loading(true);
      final res = await _api.get(Env.branchesList);
      List rawList = const [];

      if (res is List) {
        rawList = res;
      } else if (res is Map && res['data'] is List) {
        rawList = res['data'] as List;
      } else if (res is Map && res['branches'] is List) {
        rawList = res['branches'] as List;
      }

      final parsed = rawList
          .map((e) => BranchModel.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.isActive)
          .toList();

      branches.assignAll(parsed);
    } finally {
      loading(false);
    }
  }

  Future<void> changeBranch(int branchId) async {
    if (branchId <= 0 || branchId == selectedBranchId.value || changing.value) {
      return;
    }

    try {
      changing(true);
      selectedBranchId.value = branchId;
      await _box.write(_selectedBranchKey, branchId);

      if (Get.isRegistered<CartController>()) {
        await Get.find<CartController>().clearForBranchChange();
      }
      if (Get.isRegistered<FavoritesController>()) {
        await Get.find<FavoritesController>().clearForBranchChange();
      }
      if (Get.isRegistered<HomeController>()) {
        await Get.find<HomeController>().handleBranchChanged();
      }

      Get.back();
      Get.rawSnackbar(
        messageText: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            'تم التبديل إلى $selectedBranchName',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        backgroundColor: const Color(0xFF065F46),
        snackStyle: SnackStyle.FLOATING,
        margin: const EdgeInsets.all(12),
        borderRadius: 14,
        duration: const Duration(seconds: 3),
      );
    } finally {
      changing(false);
    }
  }
}
