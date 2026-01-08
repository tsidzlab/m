import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/invoice_model.dart';
import '../models/user_model.dart';

final databaseServiceProvider = Provider((ref) {
  return DatabaseService._();
});

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'mobiletrade.db';
  static const int _databaseVersion = 1;

  DatabaseService._();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Products table
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        sku TEXT NOT NULL UNIQUE,
        barcode TEXT UNIQUE,
        category_id INTEGER,
        purchase_price REAL DEFAULT 0,
        wholesale_price REAL DEFAULT 0,
        retail_price REAL DEFAULT 0,
        quantity_in_stock INTEGER DEFAULT 0,
        low_stock_alert INTEGER DEFAULT 10,
        unit TEXT DEFAULT 'قطعة',
        image_url TEXT,
        tax_rate REAL DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        sync_status TEXT DEFAULT 'pending',
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT
      )
    ''');

    // Customers table
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL UNIQUE,
        alternative_phone TEXT,
        email TEXT UNIQUE,
        address TEXT,
        wilaya TEXT,
        municipality TEXT,
        customer_type TEXT DEFAULT 'عادي',
        credit_limit REAL DEFAULT 0,
        credit_used REAL DEFAULT 0,
        loyalty_points INTEGER DEFAULT 0,
        total_purchases REAL DEFAULT 0,
        total_paid REAL DEFAULT 0,
        outstanding_amount REAL DEFAULT 0,
        last_purchase_date TEXT,
        notes TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT
      )
    ''');

    // Invoices table
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY,
        customer_id INTEGER NOT NULL,
        invoice_number TEXT NOT NULL UNIQUE,
        invoice_date TEXT NOT NULL,
        due_date TEXT,
        invoice_type TEXT DEFAULT 'مبيعات',
        payment_status TEXT DEFAULT 'معلقة',
        invoice_status TEXT DEFAULT '草案',
        subtotal REAL DEFAULT 0,
        discount_type TEXT DEFAULT 'نسبة',
        discount_value REAL DEFAULT 0,
        discount_amount REAL DEFAULT 0,
        tax_rate REAL DEFAULT 0,
        tax_amount REAL DEFAULT 0,
        total_amount REAL DEFAULT 0,
        paid_amount REAL DEFAULT 0,
        remaining_amount REAL DEFAULT 0,
        notes TEXT,
        payment_terms TEXT,
        sync_status TEXT DEFAULT 'pending',
        sync_error TEXT,
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT
      )
    ''');

    // Invoice items table
    await db.execute('''
      CREATE TABLE invoice_items (
        id INTEGER PRIMARY KEY,
        invoice_id INTEGER NOT NULL,
        product_id INTEGER,
        product_name TEXT NOT NULL,
        product_sku TEXT,
        unit_price REAL NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT DEFAULT 'قطعة',
        discount_type TEXT DEFAULT 'نسبة',
        discount_value REAL DEFAULT 0,
        line_total REAL NOT NULL,
        tax_rate REAL DEFAULT 0,
        notes TEXT,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL
      )
    ''');

    // Payments table
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY,
        invoice_id INTEGER,
        customer_id INTEGER NOT NULL,
        payment_number TEXT NOT NULL UNIQUE,
        payment_date TEXT NOT NULL,
        payment_method TEXT DEFAULT 'نقد',
        payment_amount REAL NOT NULL,
        reference_number TEXT,
        check_number TEXT,
        check_date TEXT,
        bank_name TEXT,
        notes TEXT,
        approval_status TEXT DEFAULT 'معلق',
        sync_status TEXT DEFAULT 'pending',
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT
      )
    ''');

    // Sync logs table
    await db.execute('''
      CREATE TABLE sync_logs (
        id INTEGER PRIMARY KEY,
        sync_type TEXT NOT NULL,
        status TEXT NOT NULL,
        records_count INTEGER DEFAULT 0,
        synced_count INTEGER DEFAULT 0,
        failed_count INTEGER DEFAULT 0,
        error_message TEXT,
        details TEXT,
        device_info TEXT,
        duration_seconds INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_products_sku ON products(sku)');
    await db.execute('CREATE INDEX idx_products_barcode ON products(barcode)');
    await db.execute('CREATE INDEX idx_customers_phone ON customers(phone)');
    await db.execute('CREATE INDEX idx_invoices_number ON invoices(invoice_number)');
    await db.execute('CREATE INDEX idx_invoices_customer ON invoices(customer_id)');
    await db.execute('CREATE INDEX idx_invoices_date ON invoices(invoice_date)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
  }

  // ===================== PRODUCTS =====================

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final maps = await db.query('products', where: 'deleted_at IS NULL');
    return List.generate(maps.length, (i) {
      return Product(
        id: maps[i]['id'] as int,
        name: maps[i]['name'] as String,
        description: maps[i]['description'] as String?,
        sku: maps[i]['sku'] as String,
        barcode: maps[i]['barcode'] as String?,
        categoryId: maps[i]['category_id'] as int?,
        purchasePrice: maps[i]['purchase_price'] as double,
        wholesalePrice: maps[i]['wholesale_price'] as double,
        retailPrice: maps[i]['retail_price'] as double,
        quantityInStock: maps[i]['quantity_in_stock'] as int,
        lowStockAlert: maps[i]['low_stock_alert'] as int,
        unit: maps[i]['unit'] as String,
        imageUrl: maps[i]['image_url'] as String?,
        taxRate: maps[i]['tax_rate'] as double,
        isActive: (maps[i]['is_active'] as int) == 1,
        syncStatus: maps[i]['sync_status'] as String,
        createdAt: DateTime.parse(maps[i]['created_at'] as String),
        updatedAt: maps[i]['updated_at'] != null 
          ? DateTime.parse(maps[i]['updated_at'] as String)
          : null,
      );
    });
  }

  Future<Product?> getProductBySku(String sku) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'sku = ? AND deleted_at IS NULL',
      whereArgs: [sku],
    );

    if (maps.isEmpty) return null;

    return Product(
      id: maps[0]['id'] as int,
      name: maps[0]['name'] as String,
      sku: maps[0]['sku'] as String,
      retailPrice: maps[0]['retail_price'] as double,
      quantityInStock: maps[0]['quantity_in_stock'] as int,
      createdAt: DateTime.parse(maps[0]['created_at'] as String),
    );
  }

  Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert('products', {
      'id': product.id,
      'name': product.name,
      'description': product.description,
      'sku': product.sku,
      'barcode': product.barcode,
      'category_id': product.categoryId,
      'purchase_price': product.purchasePrice,
      'wholesale_price': product.wholesalePrice,
      'retail_price': product.retailPrice,
      'quantity_in_stock': product.quantityInStock,
      'low_stock_alert': product.lowStockAlert,
      'unit': product.unit,
      'image_url': product.imageUrl,
      'tax_rate': product.taxRate,
      'is_active': product.isActive ? 1 : 0,
      'sync_status': product.syncStatus,
      'created_at': product.createdAt.toIso8601String(),
      'updated_at': product.updatedAt?.toIso8601String(),
    });
  }

  Future<void> insertProducts(List<Product> products) async {
    final db = await database;
    final batch = db.batch();

    for (final product in products) {
      batch.insert(
        'products',
        {
          'id': product.id,
          'name': product.name,
          'description': product.description,
          'sku': product.sku,
          'barcode': product.barcode,
          'retail_price': product.retailPrice,
          'quantity_in_stock': product.quantityInStock,
          'created_at': product.createdAt.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit();
  }

  // ===================== INVOICES =====================

  Future<List<Invoice>> getPendingSyncInvoices() async {
    final db = await database;
    final maps = await db.query(
      'invoices',
      where: 'sync_status = ? AND deleted_at IS NULL',
      whereArgs: ['pending'],
    );

    return List.generate(maps.length, (i) {
      return Invoice(
        id: maps[i]['id'] as int,
        customerId: maps[i]['customer_id'] as int,
        invoiceNumber: maps[i]['invoice_number'] as String,
        invoiceDate: DateTime.parse(maps[i]['invoice_date'] as String),
        totalAmount: maps[i]['total_amount'] as double,
      );
    });
  }

  Future<int> insertInvoice(Invoice invoice) async {
    final db = await database;
    return await db.insert('invoices', {
      'customer_id': invoice.customerId,
      'invoice_number': invoice.invoiceNumber,
      'invoice_date': invoice.invoiceDate.toIso8601String(),
      'due_date': invoice.dueDate?.toIso8601String(),
      'invoice_type': invoice.invoiceType,
      'payment_status': invoice.paymentStatus,
      'invoice_status': invoice.invoiceStatus,
      'subtotal': invoice.subtotal,
      'discount_type': invoice.discountType,
      'discount_value': invoice.discountValue,
      'discount_amount': invoice.discountAmount,
      'tax_rate': invoice.taxRate,
      'tax_amount': invoice.taxAmount,
      'total_amount': invoice.totalAmount,
      'paid_amount': invoice.paidAmount,
      'remaining_amount': invoice.remainingAmount,
      'notes': invoice.notes,
      'payment_terms': invoice.paymentTerms,
      'sync_status': invoice.syncStatus,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateInvoiceSyncStatus(int invoiceId, String status) async {
    final db = await database;
    await db.update(
      'invoices',
      {'sync_status': status},
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
  }

  // ===================== SYNC LOGS =====================

  Future<void> insertSyncLog({
    required String syncType,
    required String status,
    required int recordsCount,
    required int syncedCount,
    required int failedCount,
    String? errorMessage,
    int? durationSeconds,
  }) async {
    final db = await database;
    await db.insert('sync_logs', {
      'sync_type': syncType,
      'status': status,
      'records_count': recordsCount,
      'synced_count': syncedCount,
      'failed_count': failedCount,
      'error_message': errorMessage,
      'duration_seconds': durationSeconds,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ===================== DATABASE CLEANUP =====================

  Future<void> clearAllData() async {
    final db = await database;
    final batch = db.batch();

    batch.delete('invoice_items');
    batch.delete('invoices');
    batch.delete('payments');
    batch.delete('customers');
    batch.delete('products');

    await batch.commit();
  }

  Future<void> deleteDatabase() async {
    final path = join(await getDatabasesPath(), _databaseName);
    await deleteDb(path);
    _database = null;
  }
}
