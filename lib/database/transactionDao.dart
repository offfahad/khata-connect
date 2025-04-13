import 'dart:async';

import 'package:khata_connect/database/database.dart';
import 'package:khata_connect/models/transaction.dart';

class TransactionDao {
  final dbProvider = DatabaseProvider.dbProvider;

  Future<int> createTransaction(Transaction transaction) async {
    final db = await dbProvider.database;
    var result =
        await db.insert(transactionTABLE, transaction.toDatabaseJson());
    return result;
  }

  Future<List<Transaction>> getTransactions({
    List<String>? columns,
    String? query,
  }) async {
    final db = await dbProvider.database;

    List<Map<String, dynamic>> result;
    if (query != null && query.isNotEmpty) {
      result = await db.query(transactionTABLE, columns: columns);
    } else {
      result = await db.query(transactionTABLE, columns: columns);
    }

    List<Transaction> transactions = result.isNotEmpty
        ? result.map((item) => Transaction.fromDatabaseJson(item)).toList()
        : [];

    return transactions;
  }

  Future<List<Transaction>> getTransactionsByCustomerId(int cid) async {
    final db = await dbProvider.database;

    List<Map<String, dynamic>> result =
        await db.query(transactionTABLE, where: 'uid = ?', whereArgs: [cid]);

    List<Transaction> transactions = result.isNotEmpty
        ? result.map((item) => Transaction.fromDatabaseJson(item)).toList()
        : [];

    return transactions;
  }

  Future<Transaction?> getTransaction(int id) async {
    final db = await dbProvider.database;
    List<Map<String, dynamic>> maps =
        await db.query(transactionTABLE, where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Transaction.fromDatabaseJson(maps.first);
    }
    return null;
  }

  Future<double> getCustomerTransactionsTotal(int cid) async {
    final db = await dbProvider.database;
    List<Map<String, dynamic>> result =
        await db.query(transactionTABLE, where: 'uid = ?', whereArgs: [cid]);

    List<Transaction> transactions = result.isNotEmpty
        ? result.map((item) => Transaction.fromDatabaseJson(item)).toList()
        : [];

    double totalTransaction = 0;
    transactions.forEach((trans) {
      if (trans.ttype == 'payment') {
        totalTransaction += trans.amount ?? 0;
      } else {
        totalTransaction -= trans.amount ?? 0;
      }
    });

    return totalTransaction;
  }

  Future<double> getBusinessTransactionsTotal(int bid) async {
    final db = await dbProvider.database;
    List<Map<String, dynamic>> result = await db
        .query(transactionTABLE, where: 'businessId = ?', whereArgs: [bid]);

    List<Transaction> transactions = result.isNotEmpty
        ? result.map((item) => Transaction.fromDatabaseJson(item)).toList()
        : [];

    double totalTransaction = 0;
    transactions.forEach((trans) {
      if (trans.ttype == 'payment') {
        totalTransaction += trans.amount ?? 0;
      } else {
        totalTransaction -= trans.amount ?? 0;
      }
    });

    return totalTransaction;
  }

  Future<double> getTotalGivenToCustomers(int businessId) async {
    final db = await dbProvider.database;
    List<Map<String, dynamic>> result = await db.query(
      transactionTABLE,
      where: 'businessId = ? AND ttype = ?',
      whereArgs: [businessId, 'credit'],
    );

    double totalGiven = result.fold(0, (sum, item) {
      return sum + (item['amount'] ?? 0);
    });

    return totalGiven;
  }

  Future<double> getTotalToReceiveFromCustomers(int businessId) async {
    final db = await dbProvider.database;
    List<Map<String, dynamic>> result = await db.query(
      transactionTABLE,
      where: 'businessId = ? AND ttype = ?',
      whereArgs: [businessId, 'payment'],
    );

    double totalToReceive = result.fold(0, (sum, item) {
      return sum + (item['amount'] ?? 0);
    });

    return totalToReceive;
  }

  Future<int> updateTransaction(Transaction transaction) async {
    final db = await dbProvider.database;
    var result = await db.update(transactionTABLE, transaction.toDatabaseJson(),
        where: "id = ?", whereArgs: [transaction.id]);

    return result;
  }

  Future<int> deleteTransaction(int id) async {
    final db = await dbProvider.database;
    var result =
        await db.delete(transactionTABLE, where: 'id = ?', whereArgs: [id]);

    return result;
  }
}
