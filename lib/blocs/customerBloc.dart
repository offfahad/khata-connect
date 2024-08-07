import 'dart:async';

import 'package:khata_connect/database/customerRepo.dart';
import 'package:khata_connect/models/customer.dart';

class CustomerBloc {
  final _customerRepository = CustomerRepository();

  final _customersController = StreamController<List<Customer>>.broadcast();

  Stream<List<Customer>> get customers => _customersController.stream;

  CustomerBloc() {
    getCustomers();
  }

  Future<List<Customer>> getCustomers({String? query, int? page}) async {
    final List<Customer> customers =
        await _customerRepository.getAllCustomers(query: query, page: page);
    _customersController.sink.add(customers);
    return customers;
  }

  Future<Customer>getCustomer(int id) async {
    final Customer customer = await _customerRepository.getCustomer(id);
    return customer;
  }

  Future<List<Customer>> addCustomer(Customer customer) async {
    await _customerRepository.insertCustomer(customer);
    return getCustomers();
  }

  Future<List<Customer>>updateCustomer(Customer customer) async {
    await _customerRepository.updateCustomer(customer);
    return getCustomers();
  }

  Future<List<Customer>> deleteCustomerById(int id) async {
    await _customerRepository.deleteCustomerById(id);
    return getCustomers();
  }

  dispose() {
    _customersController.close();
  }
}
