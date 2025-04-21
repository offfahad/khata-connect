// import 'dart:convert';
// import 'dart:typed_data';

// import 'package:contacts_service/contacts_service.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:khata_connect/main.dart';
// import 'package:khata_connect/models/UserContact.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import '../../blocs/customerBloc.dart';
// import '../../helpers/appLocalizations.dart';
// import '../../models/customer.dart';

// class ImportContacts extends StatefulWidget {
//   const ImportContacts({Key? key}) : super(key: key);

//   @override
//   _ImportContactsState createState() => _ImportContactsState();
// }

// class _ImportContactsState extends State<ImportContacts> {
//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
//   final picker = ImagePicker();
//   bool _hasPermission = false;
//   final CustomerBloc _customerBloc = CustomerBloc();

//   List<UserContact> contactsList = [];
//   List<int> contactsIndexToAdd = [];

//   @override
//   void initState() {
//     super.initState();
//     _askPermissions();
//   }

//   Future<void> _loadContacts() async {
//     try {
//       Iterable<Contact> contacts =
//           await ContactsService.getContacts(withThumbnails: true);

//       List<UserContact> contactsListTemp = [];

//       // Load the local asset image as Uint8List
//       final ByteData bytes =
//           await rootBundle.load('assets/images/noimage_person.png');
//       final Uint8List defaultAvatar = bytes.buffer.asUint8List();

//       for (var contact in contacts) {
//         var mobilenum = contact.phones!.toList();
//         if (mobilenum.isNotEmpty) {
//           var userContact = UserContact(
//             name: contact.displayName ?? 'No Name',
//             phone: mobilenum[0].value ?? 'No Phone',
//             avatar: contact.avatar?.isNotEmpty == true
//                 ? contact.avatar!
//                 : defaultAvatar,
//           );
//           contactsListTemp.add(userContact);
//         }
//       }

//       setState(() {
//         contactsList = contactsListTemp;
//       });
//     } catch (e) {
//       print('Error loading contacts: $e');
//       showPlatformDialog(
//         context: context,
//         builder: (context) => PlatformAlertDialog(
//           title: const Text('Error'),
//           content:
//               const Text('Failed to load contacts. Please try again later.'),
//           actions: [
//             PlatformDialogAction(
//               child: const Text('OK'),
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//             ),
//           ],
//         ),
//       );
//     }
//   }

//   Future<void> _askPermissions() async {
//     while (true) {
//       try {
//         PermissionStatus permissionStatus = await _getContactPermission();
//         if (permissionStatus == PermissionStatus.granted) {
//           setState(() {
//             _hasPermission = true;
//           });
//           _loadContacts();
//           break;
//         } else {
//           setState(() {
//             _hasPermission = false;
//           });
//           _handleInvalidPermissions(permissionStatus);
//           break;
//         }
//       } catch (e) {
//         print('Error requesting permissions: $e');
//         bool openSettings = await showPlatformDialog(
//           context: context,
//           builder: (context) {
//             return PlatformAlertDialog(
//               title: const Text('Contact Permissions'),
//               content: const Text(
//                   'We are having problems retrieving permissions. Would you like to '
//                   'open the app settings to fix?'),
//               actions: [
//                 PlatformDialogAction(
//                   child: const Text('Close'),
//                   onPressed: () {
//                     Navigator.pop(context, false);
//                   },
//                 ),
//                 PlatformDialogAction(
//                   child: const Text('Settings'),
//                   onPressed: () {
//                     Navigator.pop(context, true);
//                   },
//                 ),
//               ],
//             );
//           },
//         );
//         if (openSettings) {
//           await openAppSettings();
//         } else {
//           break;
//         }
//       }
//     }
//   }

//   Future<PermissionStatus> _getContactPermission() async {
//     final status = await Permission.contacts.status;
//     if (!status.isGranted) {
//       final result = await Permission.contacts.request();
//       return result;
//     } else {
//       return status;
//     }
//   }

//   void _handleInvalidPermissions(PermissionStatus permissionStatus) {
//     if (permissionStatus == PermissionStatus.denied) {
//       showPlatformDialog(
//         context: context,
//         builder: (context) => PlatformAlertDialog(
//           title: const Text('Permission Denied'),
//           content: const Text('Access to contact data denied'),
//           actions: [
//             PlatformDialogAction(
//               child: const Text('OK'),
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//             ),
//           ],
//         ),
//       );
//     } else if (permissionStatus == PermissionStatus.restricted) {
//       showPlatformDialog(
//         context: context,
//         builder: (context) => PlatformAlertDialog(
//           title: const Text('Permission Restricted'),
//           content: const Text('Contact data access restricted'),
//           actions: [
//             PlatformDialogAction(
//               child: const Text('OK'),
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//             ),
//           ],
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         elevation: 0.0,
//         forceMaterialTransparency: true,
//         title: Text(
//           AppLocalizations.of(context)!.translate('importContacts'),
//           style: const TextStyle(
//               //color: Colors.black,
//               ),
//         ),
//         //iconTheme: const IconThemeData(
//         //  color: Colors.black, // Change color here
//         //),
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: () {
//           importContacts();
//         },
//         icon: const Icon(Icons.check),
//         label: Text(AppLocalizations.of(context)!.translate('importContacts')),
//       ),
//       body: !_hasPermission || contactsList.isEmpty
//           ? Center(
//               child: Container(
//                 alignment: Alignment.center,
//                 width: MediaQuery.of(context).size.width,
//                 height: 280,
//                 child: CircularProgressIndicator(
//                   valueColor: AlwaysStoppedAnimation<Color>(
//                       Theme.of(context).colorScheme.secondary),
//                 ),
//               ),
//             )
//           : Form(
//               key: _formKey,
//               child: ListView.builder(
//                 padding: const EdgeInsets.all(20),
//                 itemCount: contactsList.length,
//                 shrinkWrap: true,
//                 itemBuilder: (BuildContext ctx, int index) {
//                   UserContact contact = contactsList[index];

//                   final avatar = contact.avatar!.isNotEmpty
//                       ? contact.avatar
//                       : Uint8List(0); // Default empty image if no avatar

//                   return Container(
//                     margin: const EdgeInsets.fromLTRB(0, 0, 0, 4),
//                     padding: const EdgeInsets.all(4),
//                     child: InkWell(
//                       onTap: () {
//                         setState(() {
//                           if (!contactsIndexToAdd.contains(index)) {
//                             contactsIndexToAdd.add(index);
//                           } else {
//                             contactsIndexToAdd.remove(index);
//                           }
//                         });
//                       },
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.start,
//                         children: [
//                           Checkbox(
//                             value: contactsIndexToAdd.contains(index),
//                             onChanged: (bool? value) {
//                               setState(() {
//                                 if (value == true) {
//                                   contactsIndexToAdd.add(index);
//                                 } else {
//                                   contactsIndexToAdd.remove(index);
//                                 }
//                               });
//                             },
//                           ),
//                           const SizedBox(width: 16),
//                           CircleAvatar(
//                             radius: 24,
//                             backgroundColor: Colors.transparent,
//                             child: ClipOval(
//                               child: Container(
//                                 color: Colors.grey.shade200,
//                                 child: Image.memory(
//                                   avatar!,
//                                   height: 54,
//                                   width: 54,
//                                   fit: BoxFit.cover,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 16),
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(contact.name ?? 'No Name'),
//                               const SizedBox(height: 8),
//                               Text(
//                                 contact.phone ?? 'No Phone',
//                                 style: const TextStyle(
//                                   fontSize: 13,
//                                   //color: Colors.grey,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//     );
//   }

//   Future<void> importContacts() async {
//     try {
//       List<UserContact> selectedUserContacts = contactsList.where((contact) {
//         int index = contactsList.indexOf(contact);
//         return contactsIndexToAdd.contains(index);
//       }).toList();

//       final prefs = await SharedPreferences.getInstance();
//       int? selectedBusinessId = prefs.getInt('selected_business');

//       for (var contact in selectedUserContacts) {
//         Customer customer = Customer(
//           name: contact.name,
//           phone: contact.phone,
//           image:
//               contact.avatar!.isNotEmpty ? base64Encode(contact.avatar!) : null,
//           businessId: selectedBusinessId,
//         );
//         await _customerBloc.addCustomer(customer);
//       }

//       Navigator.of(context).popUntil((route) => route.isFirst);
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (context) => MyHomePage(),
//         ),
//       );
//     } catch (e) {
//       print('Error importing contacts: $e');
//       showPlatformDialog(
//         context: context,
//         builder: (context) => PlatformAlertDialog(
//           title: const Text('Error'),
//           content:
//               const Text('Failed to import contacts. Please try again later.'),
//           actions: [
//             PlatformDialogAction(
//               child: const Text('OK'),
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//             ),
//           ],
//         ),
//       );
//     }
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }
// }
