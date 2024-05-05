// ignore_for_file: use_build_context_synchronously, avoid_print, use_key_in_widget_constructors

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:harvest_guardian/constants.dart';
import 'package:harvest_guardian/screens/authentication/signin_screen.dart';
import 'package:harvest_guardian/screens/navigator.dart';
import 'package:harvest_guardian/widgets/custom_textfield.dart';
import 'package:page_transition/page_transition.dart';
import 'package:validators/validators.dart' as validator;

class SignUp extends StatefulWidget {
  const SignUp({Key? key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  late TextEditingController usernameController;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController();
    emailController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.38,
                          child: Image.asset('assets/images/signup.png'),
                        ),
                        const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 35.0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        CustomTextfield(
                          controller: usernameController,
                          obscureText: false,
                          hintText: 'Enter Username',
                          icon: Icons.person,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a username';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        CustomTextfield(
                          controller: emailController,
                          obscureText: false,
                          hintText: 'Enter Email',
                          icon: Icons.alternate_email,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an email';
                            } else if (!validator.isEmail(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        CustomTextfield(
                          controller: passwordController,
                          obscureText: true,
                          hintText: 'Enter Password',
                          icon: Icons.lock,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            } else if (value.length < 6) {
                              return 'Password must be at least 6 characters long';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        GestureDetector(
                          onTap: () {
                            if (_formKey.currentState!.validate()) {
                              signup();
                            }
                          },
                          child: Container(
                            width: size.width,
                            decoration: BoxDecoration(
                              color: Constants.primaryColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 20),
                            child: const Center(
                              child: Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        const Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text('OR'),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        InkWell(
                          onTap: () {
                            signUpWithGoogle();
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Constants.blackColor),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Image.asset('assets/images/google.png',
                                    height: 30.0),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                  child: Text(
                                    'Continue with Google',
                                    style: TextStyle(fontSize: 18.0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                                context,
                                PageTransition(
                                    child: const SignIn(),
                                    type: PageTransitionType.bottomToTop));
                          },
                          child: Center(
                            child: Text.rich(
                              TextSpan(children: [
                                TextSpan(
                                  text: 'Have an Account? ',
                                  style: TextStyle(
                                    color: Constants.blackColor,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Login',
                                  style: TextStyle(
                                    color: Constants.primaryColor,
                                  ),
                                ),
                              ]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> signup() async {
    setState(() {
      _loading = true;
    });
    FocusScope.of(context).unfocus();
    final auth = FirebaseAuth.instance;
    try {
      await auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      await FirebaseAuth.instance.currentUser!
          .updateDisplayName(usernameController.text);

      await addDataOfNewUser(FirebaseAuth.instance.currentUser!);

      Navigator.pushReplacement(
        context,
        PageTransition(
          child: const PageNavigator(),
          type: PageTransitionType.bottomToTop,
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _loading = false;
      });
      if (e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The account already exists for that email.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred. Please try again later.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      print("Error signing up: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> signUpWithGoogle() async {
    setState(() {
      _loading = true;
    });
    FocusScope.of(context).unfocus();
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final FirebaseAuth auth = FirebaseAuth.instance;

    try {
      await googleSignIn.signOut();
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();
      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );
        final UserCredential userCredential =
            await auth.signInWithCredential(credential);
        final User? user = userCredential.user;

        if (user != null) {
          if (userCredential.additionalUserInfo?.isNewUser ?? false) {
            addDataOfNewUser(user);
          }

          Navigator.pushReplacement(
            context,
            PageTransition(
              child: const PageNavigator(),
              type: PageTransitionType.bottomToTop,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to sign in with Google.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _loading = false;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to sign in with Google.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      print('Error signing in with Google: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> addDataOfNewUser(User user) async {
    try {
      print('User: $user');
      print('Email: ${user.email}');
      print('DisplayName: ${user.displayName}');
      print('PhotoUrl: ${user.photoURL}');

      DatabaseReference userRef =
          FirebaseDatabase.instance.ref().child('Users').child(user.uid);

      String photoUrl = user.photoURL ??
          'https://st4.depositphotos.com/1496387/40483/v/450/depositphotos_404831150-stock-illustration-happy-farmer-logo-agriculture-natural.jpg';

      await userRef.set({
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': photoUrl,
      });
    } catch (e) {
      print('Error adding user data: $e');
      rethrow;
    }
  }
}
