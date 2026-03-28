import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart' hide FormData;
import 'package:mandena/modules/branch/branch_controller.dart';

import 'env.dart';

class ApiService {
  ApiService()
    : _dio =
          Dio(
              BaseOptions(
                baseUrl: _fixBaseUrl(Env.baseUrl),
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 20),
                headers: const {
                  'Accept': 'application/json',
                  'Cache-Control':
                      'no-store, no-cache, must-revalidate, max-age=0',
                  'Pragma': 'no-cache',
                },
              ),
            )
            ..interceptors.add(
              LogInterceptor(requestBody: true, responseBody: true),
            );

  final Dio _dio;

  static String _fixBaseUrl(String s) => s.endsWith('/') ? s : '$s/';
  static String _norm(String path) =>
      (path.startsWith('http://') || path.startsWith('https://'))
      ? path
      : (path.startsWith('/') ? path : '/$path');

  Future<void> _checkConnection() async {
    final dynamic result = await Connectivity().checkConnectivity();
    if (result is ConnectivityResult) {
      if (result == ConnectivityResult.none) {
        throw Exception('لا يوجد اتصال بالإنترنت');
      }
      return;
    }
    if (result is List<ConnectivityResult>) {
      final hasAny = result.any((e) => e != ConnectivityResult.none);
      if (!hasAny) {
        throw Exception('لا يوجد اتصال بالإنترنت');
      }
    }
  }

  int _branchId() {
    try {
      if (Get.isRegistered<BranchController>()) {
        return Get.find<BranchController>().selectedBranchId.value;
      }
    } catch (_) {}
    return 0;
  }

  Map<String, dynamic> _injectBranchToParams(Map<String, dynamic>? params) {
    final branchId = _branchId();
    return {
      if (params != null) ...params,
      if (branchId > 0) 'branch_id': '$branchId',
    };
  }

  Map<String, dynamic> _injectBranchToBody(Map<String, dynamic>? body) {
    final branchId = _branchId();
    return {
      if (body != null) ...body,
      if (branchId > 0) 'branch_id': '$branchId',
    };
  }

  Map<String, dynamic> _branchHeaders([Map<String, dynamic>? headers]) {
    final branchId = _branchId();
    return {
      if (headers != null) ...headers,
      if (branchId > 0) 'X-Branch-Id': '$branchId',
    };
  }

  Map<String, dynamic> _decodeAny(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      final s = data.trim();
      if (s.isEmpty) return {'ok': false, 'message': 'EMPTY_RESPONSE'};
      try {
        final decoded = jsonDecode(s);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        return {'ok': false, 'message': s};
      }
    }
    return {'ok': false, 'message': 'INVALID_RESPONSE'};
  }

  Future<dynamic> get(String path, {Map<String, String>? params}) async {
    await _checkConnection();
    try {
      final qp = _injectBranchToParams({
        if (params != null) ...params,
        '_ts': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      final r = await _dio.get(
        _norm(path),
        queryParameters: qp,
        options: Options(headers: _branchHeaders()),
      );
      if (kDebugMode) {
        debugPrint('[GET] ${r.requestOptions.uri} -> ${r.statusCode}');
      }
      return r.data;
    } on DioException catch (e) {
      final res = _decodeAny(e.response?.data);
      final msg = (res['message'] ?? e.message ?? 'NETWORK_ERROR').toString();
      throw Exception(msg);
    }
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    await _checkConnection();
    try {
      final requestBody = _injectBranchToBody(body);
      final r = await _dio.post(
        _norm(path),
        data: requestBody,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: _branchHeaders(),
        ),
      );
      if (kDebugMode) {
        debugPrint('[POST] ${r.requestOptions.uri} -> ${r.statusCode}');
      }
      return r.data;
    } on DioException catch (e) {
      final res = _decodeAny(e.response?.data);
      final msg = (res['message'] ?? e.message ?? 'NETWORK_ERROR').toString();
      throw Exception(msg);
    }
  }

  Future<Map<String, dynamic>> postForm(
    String path,
    Map<String, dynamic> data,
  ) async {
    await _checkConnection();
    try {
      final payload = _injectBranchToBody(data);

      final r = await _dio.post(
        _norm(path),
        data: payload,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: _branchHeaders(),
        ),
      );
      return _decodeAny(r.data);
    } on DioException catch (e) {
      final res = _decodeAny(e.response?.data);
      final msg = (res['message'] ?? e.message ?? 'NETWORK_ERROR').toString();
      throw Exception(msg);
    }
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, Object?> data,
  ) async {
    await _checkConnection();
    try {
      final payload = _injectBranchToBody(Map<String, dynamic>.from(data));
      final r = await _dio.post(
        _norm(path),
        data: jsonEncode(payload),
        options: Options(
          headers: _branchHeaders(const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          }),
        ),
      );
      return _decodeAny(r.data);
    } on DioException catch (e) {
      final res = _decodeAny(e.response?.data);
      final msg = (res['message'] ?? e.message ?? 'NETWORK_ERROR').toString();
      throw Exception(msg);
    }
  }
}
