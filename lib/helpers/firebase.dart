import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseClient {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleSignInAccount = await _googleSignIn.signIn();

      if (googleSignInAccount == null) {
        // User canceled the sign-in process
        return null;
      }

      final GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      final UserCredential authResult = await _auth.signInWithCredential(credential);
      final User? user = authResult.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-null',
          message: 'User is null after sign-in.',
        );
      }

      // Ensure the user is authenticated
      assert(!user.isAnonymous);
      assert(await user.getIdToken() != null);

      // Ensure the current user is the same as the signed-in user
      final User? currentUser = _auth.currentUser;
      assert(user.uid == currentUser?.uid);

      return user.toString();
    } catch (e) {
      print('Error signing in with Google: $e');
      if (e is FirebaseAuthException) {
        // Handle FirebaseAuthException specifically
        print('FirebaseAuthException code: ${e.code}');
        print('FirebaseAuthException message: ${e.message}');
      }
      return null;
    }
  }
}
