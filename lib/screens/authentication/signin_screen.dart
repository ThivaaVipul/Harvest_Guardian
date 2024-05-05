// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:harvest_guardian/constants.dart';
import 'package:harvest_guardian/screens/authentication/forgot_password_screen.dart';
import 'package:harvest_guardian/screens/authentication/signup_screen.dart';
import 'package:harvest_guardian/screens/navigator.dart';
import 'package:harvest_guardian/widgets/custom_textfield.dart';
import 'package:page_transition/page_transition.dart';
import 'package:validators/validators.dart' as validator;

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
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
                          child: Image.asset('assets/images/signin.png'),
                        ),
                        const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 35.0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        CustomTextfield(
                          controller: emailController,
                          obscureText: false,
                          hintText: 'Enter Email',
                          icon: Icons.alternate_email,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
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
                              return 'Please enter your password';
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
                              login();
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
                                'Sign In',
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
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                                context,
                                PageTransition(
                                    child: const ForgotPassword(),
                                    type: PageTransitionType.bottomToTop));
                          },
                          child: Center(
                            child: Text.rich(
                              TextSpan(children: [
                                TextSpan(
                                  text: 'Forgot Password? ',
                                  style: TextStyle(
                                    color: Constants.blackColor,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Reset Here',
                                  style: TextStyle(
                                    color: Constants.primaryColor,
                                  ),
                                ),
                              ]),
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
                          height: 20,
                        ),
                        InkWell(
                          onTap: () {
                            signInWithGoogle();
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
                          height: 20,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                                context,
                                PageTransition(
                                    child: const SignUp(),
                                    type: PageTransitionType.bottomToTop));
                          },
                          child: Center(
                            child: Text.rich(
                              TextSpan(children: [
                                TextSpan(
                                  text: 'New to Harvest Guardian? ',
                                  style: TextStyle(
                                    color: Constants.blackColor,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Register',
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

  Future<void> login() async {
    setState(() {
      _loading = true;
    });
    FocusScope.of(context).unfocus();
    final auth = FirebaseAuth.instance;
    try {
      await auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      Navigator.pushReplacement(
        context,
        PageTransition(
          child: const PageNavigator(),
          type: PageTransitionType.bottomToTop,
        ),
      );
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException caught: $e");
      setState(() {
        _loading = false;
      });
      if (e.code == 'user-not-found') {
        // Notify user that no user found with this email
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No user found with this email.'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (e.code == 'wrong-password') {
        // Notify user about incorrect password
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incorrect password.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        // Notify user about other errors
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred. Please try again later.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Error signing in: $e");
      // Notify user about unexpected errors
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> signInWithGoogle() async {
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
}
