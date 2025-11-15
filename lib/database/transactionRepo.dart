import 'package:khata_connect/database/transactionDao.dart';
import 'package:khata_connect/models/transaction.dart';

class TransactionRepository {
  final transactionDao = TransactionDao();

  Future getAllTransactions({String? query}) =>
      transactionDao.getTransactions(query: query);

  Future getTransaction(int id) => transactionDao.getTransaction(id);

  Future getCustomerTransactionsTotal(int id) =>
      transactionDao.getCustomerTransactionsTotal(id);

  Future<double> getTotalToGiveToCustomers(int businessId) {
    return transactionDao.getTotalToGiveToCustomers(businessId);
  }

  Future<double> getTotalToReceiveFromCustomers(int businessId) {
    return transactionDao.getTotalToReceiveFromCustomers(businessId);
  }

  Future<double> getBusinessTransactionsTotal(int id) =>
      transactionDao.getBusinessTransactionsTotal(id);

  Future getAllTransactionsByCustomerId(int cid) =>
      transactionDao.getTransactionsByCustomerId(cid);

  Future insertTransaction(Transaction transaction) =>
      transactionDao.createTransaction(transaction);

  Future updateTransaction(Transaction transaction) =>
      transactionDao.updateTransaction(transaction);

  Future deleteTransactionById(int id) => transactionDao.deleteTransaction(id);
}
