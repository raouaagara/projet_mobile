import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'models/subscription_models.dart';

/// Local SQFlite database for the subscriptions module.
/// Caches plans, the active subscription and payment history for offline use.
class SubscriptionDatabase {
  SubscriptionDatabase._();
  static final SubscriptionDatabase instance = SubscriptionDatabase._();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'subscriptions.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Table: subscription plans
    await db.execute('''
      CREATE TABLE subscription_plans (
        id          INTEGER PRIMARY KEY,
        name        TEXT    NOT NULL,
        type        TEXT    NOT NULL,
        price       REAL    NOT NULL,
        duration    TEXT    NOT NULL,
        description TEXT,
        benefits    TEXT,
        hasAiCvAccess INTEGER NOT NULL DEFAULT 0,
        aiCvLimit   INTEGER,
        cachedAt    TEXT    NOT NULL
      )
    ''');

    // Table: active user subscription
    await db.execute('''
      CREATE TABLE active_subscription (
        id          INTEGER PRIMARY KEY,
        userId      INTEGER NOT NULL,
        planId      INTEGER NOT NULL,
        planName    TEXT    NOT NULL,
        planPrice   REAL    NOT NULL,
        planType    TEXT    NOT NULL,
        status      TEXT    NOT NULL,
        startDate   TEXT,
        endDate     TEXT,
        autoRenew   INTEGER NOT NULL DEFAULT 0,
        cachedAt    TEXT    NOT NULL
      )
    ''');

    // Table: payment history
    await db.execute('''
      CREATE TABLE payment_history (
        id            INTEGER PRIMARY KEY,
        userId        INTEGER NOT NULL,
        amount        REAL    NOT NULL,
        paymentMethod TEXT,
        status        TEXT,
        paidAt        TEXT,
        invoiceRef    TEXT,
        cachedAt      TEXT    NOT NULL
      )
    ''');
  }

  // ── Plans ──────────────────────────────────────────────────────

  /// Save plans to local DB (replaces existing data).
  Future<void> cachePlans(List<SubscriptionPlan> plans) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await txn.delete('subscription_plans');
      for (final plan in plans) {
        await txn.insert('subscription_plans', {
          'id': plan.id,
          'name': plan.name,
          'type': plan.type.name,
          'price': plan.price,
          'duration': plan.duration,
          'description': plan.description,
          'benefits': plan.benefitsText,
          'hasAiCvAccess': plan.hasAiCvAccess ? 1 : 0,
          'aiCvLimit': plan.aiCvLimit,
          'cachedAt': now,
        });
      }
    });
  }

  /// Get cached plans. Returns empty list if nothing cached.
  Future<List<SubscriptionPlan>> getCachedPlans() async {
    final db = await database;
    final rows = await db.query('subscription_plans', orderBy: 'price ASC');

    return rows.map((row) => SubscriptionPlan(
      id: row['id'] as int,
      name: row['name'] as String,
      price: (row['price'] as num).toDouble(),
      duration: row['duration'] as String? ?? 'monthly',
      description: row['description'] as String?,
      benefitsText: row['benefits'] as String?,
      hasAiCvAccess: (row['hasAiCvAccess'] as int) == 1,
      aiCvLimit: row['aiCvLimit'] as int?,
    )).toList();
  }

  /// Returns true if plans cache is fresh (less than 1 hour old).
  Future<bool> arePlansFresh() async {
    final db = await database;
    final rows = await db.query('subscription_plans', columns: ['cachedAt'], limit: 1);
    if (rows.isEmpty) return false;

    final cachedAt = DateTime.tryParse(rows.first['cachedAt'] as String? ?? '');
    if (cachedAt == null) return false;
    return DateTime.now().difference(cachedAt).inHours < 1;
  }

  // ── Active subscription ────────────────────────────────────────

  /// Save the active subscription for a user.
  Future<void> cacheActiveSubscription(int userId, UserSubscription sub) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await txn.delete('active_subscription', where: 'userId = ?', whereArgs: [userId]);
      await txn.insert('active_subscription', {
        'id': sub.id,
        'userId': userId,
        'planId': sub.plan.id,
        'planName': sub.plan.name,
        'planPrice': sub.plan.price,
        'planType': sub.plan.type.name,
        'status': sub.status.name,
        'startDate': sub.startDate?.toIso8601String(),
        'endDate': sub.endDate?.toIso8601String(),
        'autoRenew': sub.autoRenew ? 1 : 0,
        'cachedAt': now,
      });
    });
  }

  /// Get the cached active subscription for a user. Returns null if none.
  Future<UserSubscription?> getCachedActiveSubscription(int userId) async {
    final db = await database;
    final rows = await db.query(
      'active_subscription',
      where: 'userId = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final row = rows.first;
    final plan = SubscriptionPlan(
      id: row['planId'] as int,
      name: row['planName'] as String,
      price: (row['planPrice'] as num).toDouble(),
      type: PlanType.values.firstWhere(
        (e) => e.name == row['planType'],
        orElse: () => PlanType.unknown,
      ),
    );

    return UserSubscription(
      id: row['id'] as int,
      plan: plan,
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.name == row['status'],
        orElse: () => SubscriptionStatus.unknown,
      ),
      startDate: row['startDate'] != null ? DateTime.tryParse(row['startDate'] as String) : null,
      endDate: row['endDate'] != null ? DateTime.tryParse(row['endDate'] as String) : null,
      autoRenew: (row['autoRenew'] as int) == 1,
    );
  }

  /// Remove the cached active subscription for a user (e.g. after cancel).
  Future<void> clearActiveSubscription(int userId) async {
    final db = await database;
    await db.delete('active_subscription', where: 'userId = ?', whereArgs: [userId]);
  }

  // ── Payment history ────────────────────────────────────────────

  /// Save payment history for a user.
  Future<void> cachePayments(int userId, List<SubscriptionPayment> payments) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await txn.delete('payment_history', where: 'userId = ?', whereArgs: [userId]);
      for (final p in payments) {
        await txn.insert('payment_history', {
          'id': p.id,
          'userId': userId,
          'amount': p.amount,
          'paymentMethod': p.paymentMethod,
          'status': p.status,
          'paidAt': p.paidAt?.toIso8601String(),
          'invoiceRef': p.invoiceRef,
          'cachedAt': now,
        });
      }
    });
  }

  /// Get cached payment history for a user. Returns empty list if none.
  Future<List<SubscriptionPayment>> getCachedPayments(int userId) async {
    final db = await database;
    final rows = await db.query(
      'payment_history',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );

    return rows.map((row) => SubscriptionPayment(
      id: row['id'] as int,
      amount: (row['amount'] as num).toDouble(),
      paymentMethod: row['paymentMethod'] as String?,
      status: row['status'] as String?,
      paidAt: row['paidAt'] != null ? DateTime.tryParse(row['paidAt'] as String) : null,
      invoiceRef: row['invoiceRef'] as String?,
    )).toList();
  }

  // ── Cleanup ────────────────────────────────────────────────────

  /// Clear all cached data (e.g. on logout).
  Future<void> clearAll() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('subscription_plans');
      await txn.delete('active_subscription');
      await txn.delete('payment_history');
    });
  }

  /// Close the database connection.
  Future<void> close() async {
    final db = await database;
    await db.close();
    _db = null;
  }
}
