import 'package:khata_connect/models/customer.dart';

import 'customerDao.dart';

class CustomerRepository {
  final customerDao = CustomerDao();

  Future<List<Customer>> getAllCustomers({String? query, int? page}) =>
      customerDao.getCustomers(query: query, page: page);

  Future<Customer> getCustomer(int id) => customerDao.getCustomer(id);

  Future<int> insertCustomer(Customer customer) =>
      customerDao.createCustomer(customer);

  Future<int> updateCustomer(Customer customer) =>
      customerDao.updateCustomer(customer);

  Future<int> deleteCustomerById(int id) => customerDao.deleteCustomer(id);
}
