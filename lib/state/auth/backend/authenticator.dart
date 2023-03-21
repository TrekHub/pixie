import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pixie/state/auth/constants/constants.dart';
import 'package:pixie/state/auth/models/auth_result.dart';
import 'package:pixie/state/posts/typedefs/user_id.dart';

class Authenticator {
  //getting the user id
  UserId? get userId => FirebaseAuth.instance.currentUser?.uid;

  //checking if the user is signed in
  bool get isSignedIn => userId != null;

  //getting the user's name
  String get displayName =>
      FirebaseAuth.instance.currentUser?.displayName ?? '';

  //getting the user's email
  String get email => FirebaseAuth.instance.currentUser?.email ?? '';

//logout function
  Future<void> logOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    await FacebookAuth.instance.logOut();
  }


//login with facebook
  Future<AuthResult> loginWithFacebook() async {
    final loginResult = await FacebookAuth.instance.login();
    final token = loginResult.accessToken?.token;

    if (token == null) {
      //user has aborted the process
      return AuthResult.aborted;
    }
    //user credentials
    final oauthCredential = FacebookAuthProvider.credential(token);

    try {
      await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      return AuthResult.success;
    } on FirebaseAuthException catch (e) {
      final email = e.email;
      final credential = e.credential;
      if (e.code == Constants.accountExistWithDifferentCredential &&
          email != null &&
          credential != null) {
        final providers =
            await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);

        if (providers.contains(Constants.googleCom)) {
          await loginWithGoogle();
          FirebaseAuth.instance.currentUser?.linkWithCredential(credential);
        }
        return AuthResult.success;
      }
      return AuthResult.failure;
    }
  }

  

  //login with google
  Future<AuthResult> loginWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: [
        Constants.emailScope,
      ],
    );

    final signInAccount = await googleSignIn.signIn();

    if (signInAccount == null) {
      //user has aborted the process
      return AuthResult.aborted;
    }
    final googleAuth = await signInAccount.authentication;
    final oauthCredentials = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    try {
      await  FirebaseAuth.instance.signInWithCredential(oauthCredentials);
      return AuthResult.success;

    } catch (e) {
      return AuthResult.failure;
    }
  }
}
