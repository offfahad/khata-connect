import 'dart:async';

import 'package:khata_connect/database/transactionRepo.dart';
import 'package:khata_connect/models/transaction.dart';

class TransactionBloc {
  final _transactionRepository = TransactionRepository();

  final _transactionController =
      StreamController<List<Transaction>>.broadcast();

  Stream<List<Transaction>> get transactions => _transactionController.stream;

  TransactionBloc() {
    getTransactions();
  }

  getTransactions({String? query}) async {
    final List<Transaction> transactions =
        await _transactionRepository.getAllTransactions(query: query);
    _transactionController.sink.add(transactions);
    return transactions;
  }

  Future<Transaction> getTransaction(int id) async {
    final Transaction transaction =
        await _transactionRepository.getTransaction(id);
    return transaction;
  }

  Future<double> getBusinessTransactionsTotal(int id) async {
    final double total =
        await _transactionRepository.getBusinessTransactionsTotal(id);
    return total;
  }

  Future<double> getCustomerTransactionsTotal(int id) async {
    final double total =
        await _transactionRepository.getCustomerTransactionsTotal(id);
    return total;
  }

  Future<double> getTotalGivenToCustomers(int businessId) async {
    return await _transactionRepository.getTotalGivenToCustomers(businessId);
  }

  Future<double> getTotalToReceiveFromCustomers(int businessId) async {
    return await _transactionRepository
        .getTotalToReceiveFromCustomers(businessId);
  }

  Future<List<Transaction>> getTransactionsByCustomerId(int cid) async {
    try {
      final List<Transaction> transactions =
          await _transactionRepository.getAllTransactionsByCustomerId(cid);
      return transactions;
    } catch (e) {
      // Handle exceptions or errors
      return [];
    }
  }

  addTransaction(Transaction transaction) async {
    await _transactionRepository.insertTransaction(transaction);
    getTransactions();
  }

  updateTransaction(Transaction transaction) async {
    await _transactionRepository.updateTransaction(transaction);
    getTransactions();
  }

  deleteTransactionById(int id) async {
    _transactionRepository.deleteTransactionById(id);
    getTransactions();
  }

  dispose() {
    _transactionController.close();
  }
}
