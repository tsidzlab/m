import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/invoice_model.dart';

final apiServiceProvider = Provider((ref) {
  return APIService();
});

class APIService {
  late Dio _dio;
  static const String _baseUrl = 'http://localhost:8080/api';
  String? _token;

  APIService() {
    _initializeDio();
    _loadToken();
  }

  void _initializeDio() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      contentType: 'application/json',
      headers: {
        'Accept': 'application/json',
        'Accept-Language': 'ar',
      },
    ));

    // Add interceptor for token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            // Handle token expiration
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // ===================== AUTH ENDPOINTS =====================

  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: request.toJson(),
      );

      final authResponse = AuthResponse.fromJson(response.data);
      
      if (authResponse.token != null) {
        await setToken(authResponse.token!);
      }

      return authResponse;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: request.toJson(),
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
      await clearToken();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ===================== INVOICES ENDPOINTS =====================

  Future<List<Invoice>> getInvoices({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/invoices',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final invoices = (data['data'] as List)
          .map((item) => Invoice.fromJson(item))
          .toList();

      return invoices;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Invoice> getInvoice(int id) async {
    try {
      final response = await _dio.get('/invoices/$id');
      return Invoice.fromJson(response.data['data']['invoice']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Invoice> createInvoice({
    required int customerId,
    required DateTime invoiceDate,
    DateTime? dueDate,
    String invoiceType = 'مبيعات',
    double discountValue = 0,
    String discountType = 'نسبة',
    double taxRate = 0,
    String? notes,
    String? paymentTerms,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await _dio.post(
        '/invoices',
        data: {
          'customer_id': customerId,
          'invoice_date': invoiceDate.toIso8601String().split('T')[0],
          'due_date': dueDate?.toIso8601String().split('T')[0],
          'invoice_type': invoiceType,
          'discount_type': discountType,
          'discount_value': discountValue,
          'tax_rate': taxRate,
          'notes': notes,
          'payment_terms': paymentTerms,
          'items': items,
        },
      );

      return Invoice.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Invoice> updateInvoice(
    int id, {
    double? discountValue,
    String? discountType,
    double? taxRate,
    String? notes,
    String? paymentTerms,
  }) async {
    try {
      final response = await _dio.put(
        '/invoices/$id',
        data: {
          if (discountValue != null) 'discount_value': discountValue,
          if (discountType != null) 'discount_type': discountType,
          if (taxRate != null) 'tax_rate': taxRate,
          if (notes != null) 'notes': notes,
          if (paymentTerms != null) 'payment_terms': paymentTerms,
        },
      );

      return Invoice.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Invoice> finalizeInvoice(int id) async {
    try {
      final response = await _dio.post('/invoices/$id/finalize');
      return Invoice.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ===================== PRODUCTS ENDPOINTS =====================

  Future<List<Product>> getProducts({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _dio.get(
        '/products',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final products = (data['data'] as List)
          .map((item) => Product.fromJson(item))
          .toList();

      return products;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Product>> searchProducts(String keyword) async {
    try {
      final response = await _dio.post(
        '/products/search',
        data: {'keyword': keyword},
      );

      final products = (response.data['data'] as List)
          .map((item) => Product.fromJson(item))
          .toList();

      return products;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Product> getProduct(int id) async {
    try {
      final response = await _dio.get('/products/$id');
      return Product.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ===================== CUSTOMERS ENDPOINTS =====================

  Future<dynamic> getCustomers({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _dio.get(
        '/customers',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> searchCustomers(String keyword) async {
    try {
      final response = await _dio.post(
        '/customers/search',
        data: {'keyword': keyword},
      );

      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> createCustomer({
    required String name,
    required String phone,
    String? email,
    String? address,
    String? wilaya,
    String? municipality,
    String customerType = 'عادي',
    String? notes,
  }) async {
    try {
      final response = await _dio.post(
        '/customers',
        data: {
          'name': name,
          'phone': phone,
          'email': email,
          'address': address,
          'wilaya': wilaya,
          'municipality': municipality,
          'customer_type': customerType,
          'notes': notes,
        },
      );

      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ===================== REPORTS ENDPOINTS =====================

  Future<dynamic> getDailySalesReport(DateTime date) async {
    try {
      final response = await _dio.get(
        '/invoices/summary/daily',
        queryParameters: {
          'date': date.toIso8601String().split('T')[0],
        },
      );

      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> getPaymentsSummary({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final response = await _dio.get(
        '/payments/methods-summary',
        queryParameters: {
          'from_date': fromDate.toIso8601String().split('T')[0],
          'to_date': toDate.toIso8601String().split('T')[0],
        },
      );

      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ===================== SYNC ENDPOINTS =====================

  Future<dynamic> pushData(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/sync/push', data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> pullData() async {
    try {
      final response = await _dio.post('/sync/pull');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ===================== ERROR HANDLING =====================

  String _handleError(DioException error) {
    if (error.response != null) {
      final message = error.response!.data is Map
          ? error.response!.data['message'] ?? 'حدث خطأ'
          : 'حدث خطأ';
      return message;
    } else if (error.type == DioExceptionType.connectionTimeout) {
      return 'انقطع الاتصال بالإنترنت';
    } else if (error.type == DioExceptionType.receiveTimeout) {
      return 'انتهت مهلة الانتظار';
    } else {
      return error.message ?? 'حدث خطأ غير متوقع';
    }
  }
}
