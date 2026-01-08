import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/invoice_model.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';

// ===================== AUTH PROVIDERS =====================

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref),
);

class AuthState {
  final bool isLoading;
  final User? user;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    User? user,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error ?? this.error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;

  AuthNotifier(this.ref) : super(const AuthState());

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.login(
        LoginRequest(
          email: email,
          password: password,
          deviceId: 'device-001',
          deviceName: 'Mobile',
          deviceType: 'Android',
          appVersion: '1.1.0',
        ),
      );

      if (response.success && response.user != null) {
        state = state.copyWith(
          isLoading: false,
          user: response.user,
          isAuthenticated: true,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.logout();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> register(RegisterRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.register(request);

      if (response.success) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: response.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

// ===================== INVOICE PROVIDERS =====================

final invoicesProvider = FutureProvider.autoDispose<List<Invoice>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getInvoices();
});

final invoiceByIdProvider = FutureProvider.autoDispose.family<Invoice, int>(
  (ref, id) async {
    final apiService = ref.watch(apiServiceProvider);
    return apiService.getInvoice(id);
  },
);

final invoiceFormProvider = StateNotifierProvider.autoDispose<InvoiceFormNotifier, InvoiceFormState>(
  (ref) => InvoiceFormNotifier(ref),
);

class InvoiceFormState {
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final Map<String, dynamic> formData;

  const InvoiceFormState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.formData = const {},
  });

  InvoiceFormState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    Map<String, dynamic>? formData,
  }) {
    return InvoiceFormState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      successMessage: successMessage ?? this.successMessage,
      formData: formData ?? this.formData,
    );
  }
}

class InvoiceFormNotifier extends StateNotifier<InvoiceFormState> {
  final Ref ref;

  InvoiceFormNotifier(this.ref) : super(const InvoiceFormState());

  void updateFormData(String key, dynamic value) {
    final newData = {...state.formData};
    newData[key] = value;
    state = state.copyWith(formData: newData);
  }

  Future<bool> createInvoice() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiService = ref.read(apiServiceProvider);
      final invoice = await apiService.createInvoice(
        customerId: state.formData['customer_id'] ?? 0,
        invoiceDate: state.formData['invoice_date'] ?? DateTime.now(),
        items: state.formData['items'] ?? [],
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'تم إنشاء الفاتورة بنجاح',
      );

      // Refresh invoices
      ref.refresh(invoicesProvider);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  void clearForm() {
    state = const InvoiceFormState();
  }
}

// ===================== PRODUCT PROVIDERS =====================

final productsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getProducts();
});

final productSearchProvider = FutureProvider.autoDispose.family<List<Product>, String>(
  (ref, keyword) async {
    final apiService = ref.watch(apiServiceProvider);
    return apiService.searchProducts(keyword);
  },
);

// ===================== CUSTOMER PROVIDERS =====================

final customersProvider = FutureProvider.autoDispose<dynamic>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getCustomers();
});

final customerSearchProvider = FutureProvider.autoDispose.family<dynamic, String>(
  (ref, keyword) async {
    final apiService = ref.watch(apiServiceProvider);
    return apiService.searchCustomers(keyword);
  },
);

// ===================== REPORT PROVIDERS =====================

final dailyReportProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) async {
    final apiService = ref.watch(apiServiceProvider);
    return apiService.getDailySalesReport(DateTime.now());
  },
);

final monthlyReportProvider = FutureProvider.autoDispose<dynamic>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final now = DateTime.now();
  final startDate = DateTime(now.year, now.month, 1);
  final endDate = DateTime(now.year, now.month + 1, 0);
  return apiService.getPaymentsSummary(
    fromDate: startDate,
    toDate: endDate,
  );
});

// ===================== SYNC PROVIDERS =====================

final isSyncingProvider = StateProvider<bool>((ref) => false);

final lastSyncTimeProvider = StateProvider<DateTime?>((ref) => null);

final syncErrorProvider = StateProvider<String?>((ref) => null);

// ===================== UI PROVIDERS =====================

final themeProvider = StateProvider<String>((ref) => 'light');

final languageProvider = StateProvider<String>((ref) => 'ar');

final isOfflineProvider = StateProvider<bool>((ref) => false);

final searchQueryProvider = StateProvider<String>((ref) => '');

// ===================== LOADING PROVIDERS =====================

final loadingProvider = StateProvider<bool>((ref) => false);

final errorProvider = StateProvider<String?>((ref) => null);

final successMessageProvider = StateProvider<String?>((ref) => null);

// ===================== NOTIFICATION PROVIDERS =====================

final notificationProvider = StateProvider<String?>((ref) => null);

// ===================== CACHE PROVIDERS =====================

final cachedInvoicesProvider = StateProvider<List<Invoice>>((ref) => []);

final cachedProductsProvider = StateProvider<List<Product>>((ref) => []);

final cachedCustomersProvider = StateProvider<List<dynamic>>((ref) => []);
