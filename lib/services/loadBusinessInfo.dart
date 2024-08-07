import 'package:flutter/cupertino.dart';

import '../blocs/businessBloc.dart';
import '../providers/stateNotifier.dart';
import '../models/business.dart';
Future<void> loadBusinessInfo(BuildContext context) async {
  final Business businessInfo = Business(
    id: 0,
    name: "",
    phone: "",
    email: "",
    address: "",
    logo: "",
    website: "",
    role: "",
    companyName: "MY COMPANY",
  );

  final BusinessBloc businessBloc = BusinessBloc();
  await businessBloc.addBusiness(businessInfo);
  changeSelectedBusiness(context, 0);
}
