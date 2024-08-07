import 'package:khata_connect/models/customer.dart';

class Transaction {
  int? id;
  int? businessId;
  int? uid;
  String? ttype;
  double? amount;
  String? comment;
  Customer? customer;
  DateTime? date;
  String? attachment;

  Transaction(
      {this.id,
      this.businessId,
      this.uid,
      this.ttype,
      this.amount,
      this.comment,
      this.customer,
      this.date,
      this.attachment});

  factory Transaction.fromDatabaseJson(Map<String, dynamic> data) =>
      Transaction(
          id: data['id'],
          businessId: data['businessId'],
          uid: data['uid'],
          ttype: data['ttype'],
          amount: data['amount'],
          comment: data['comment'],
          date: data['date'] != null ? DateTime.parse(data['date']) : null,
          attachment: data['attachment'],
          customer: data['customer'] != null ? Customer.fromDatabaseJson(data['customer']) : null);

  Map<String, dynamic> toDatabaseJson() => {
        'id': id,
        'businessId': businessId,
        'uid': uid,
        'ttype': ttype,
        'amount': amount,
        'comment': comment,
        'date': date?.toString(),
        'attachment': attachment,
        'customer': customer?.toDatabaseJson()
      };
}
