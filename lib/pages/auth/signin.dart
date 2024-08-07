import 'package:flutter/material.dart';

import '../../helpers/firebase.dart';
import '../backup/backup.dart';

class SignIn extends StatefulWidget {
  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        //backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            'Sign In',
            //style: Theme.of(context).textTheme.displayLarge,
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              //color: Colors.black,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          elevation: 0,
          //backgroundColor: Colors.grey.shade100,
        ),
        body: Container(
          //color: Colors.white,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 50),
                _signInWithGoogleButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _signInWithGoogleButton() {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      ),
      onPressed: () async {
        final String? user = await FirebaseClient().signInWithGoogle();

        if (user != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => Backup(),
            ),
          );
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Image.asset(
            "assets/images/google_logo.png",
            height: 35.0,
          ),
          const SizedBox(width: 10),
          Text(
            'Sign in with Google',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
