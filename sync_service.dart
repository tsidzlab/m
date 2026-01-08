import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:logger/logger.dart';
import 'api_service.dart';
import 'database_service.dart';

final syncServiceProvider = Provider((ref) {
  return SyncService(
    apiService: ref.read(apiServiceProvider),
    databaseService: ref.read(databaseServiceProvider),
  );
});

class SyncService {
  final APIService apiService;
  final DatabaseService databaseService;
  final logger = Logger();
  
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  Timer? _periodicSyncTimer;
  bool _isOnline = false;

  SyncService({
    required this.apiService,
    required this.databaseService,
  }) {
    _initializeConnectivityListener();
  }

  void _initializeConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (result) {
        _isOnline = result.contains(ConnectivityResult.mobile) ||
                   result.contains(ConnectivityResult.wifi);
        
        logger.i('Connectivity changed: $_isOnline');
        
        if (_isOnline) {
          _performSync();
        }
      },
    );
  }

  void startPeriodicSync({Duration interval = const Duration(minutes: 5)}) {
    _periodicSyncTimer?.cancel();
    
    _periodicSyncTimer = Timer.periodic(interval, (_) {
      if (_isOnline) {
        _performSync();
      }
    });

    logger.i('Periodic sync started every ${interval.inMinutes} minutes');
  }

  void stopPeriodicSync() {
    _periodicSyncTimer?.cancel();
    logger.i('Periodic sync stopped');
  }

  Future<void> _performSync() async {
    try {
      logger.i('Starting sync...');
      
      // Get pending invoices from local database
      final pendingInvoices = await databaseService.getPendingSyncInvoices();
      
      if (pendingInvoices.isNotEmpty) {
        final startTime = DateTime.now();
        int successCount = 0;
        int failureCount = 0;

        for (final invoice in pendingInvoices) {
          try {
            // Push invoice to server
            await apiService.pushData({
              'invoice': invoice.toJson(),
            });

            await databaseService.updateInvoiceSyncStatus(invoice.id, 'synced');
            successCount++;
          } catch (e) {
            logger.e('Failed to sync invoice ${invoice.invoiceNumber}: $e');
            failureCount++;
          }
        }

        final duration = DateTime.now().difference(startTime);
        
        // Log sync result
        await databaseService.insertSyncLog(
          syncType: 'invoices',
          status: failureCount == 0 ? 'success' : 'partial',
          recordsCount: pendingInvoices.length,
          syncedCount: successCount,
          failedCount: failureCount,
          durationSeconds: duration.inSeconds,
        );

        logger.i('Sync completed: $successCount synced, $failureCount failed');
      }

      // Pull new data from server
      await _pullNewData();

    } catch (e) {
      logger.e('Sync error: $e');
      
      await databaseService.insertSyncLog(
        syncType: 'all',
        status: 'failed',
        recordsCount: 0,
        syncedCount: 0,
        failedCount: 1,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> _pullNewData() async {
    try {
      final response = await apiService.pullData();
      
      // Handle products
      if (response['data']['products'] != null) {
        final products = response['data']['products'];
        // Update local database
      }

      // Handle invoices
      if (response['data']['invoices'] != null) {
        final invoices = response['data']['invoices'];
        // Update local database
      }

      logger.i('Data pulled successfully from server');
    } catch (e) {
      logger.e('Pull data error: $e');
    }
  }

  Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result.contains(ConnectivityResult.mobile) ||
           result.contains(ConnectivityResult.wifi);
  }

  void dispose() {
    _connectivitySubscription.cancel();
    _periodicSyncTimer?.cancel();
  }
}

// Riverpod providers for sync state
final isSyncingProvider = StateProvider<bool>((ref) => false);

final lastSyncTimeProvider = StateProvider<DateTime?>((ref) => null);

final syncErrorProvider = StateProvider<String?>((ref) => null);
