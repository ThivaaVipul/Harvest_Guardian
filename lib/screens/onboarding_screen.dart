import 'package:flutter/material.dart';
import 'package:harvest_guardian/constants.dart';
import 'package:harvest_guardian/screens/authentication/signin_screen.dart';
import 'package:harvest_guardian/screens/authentication/signup_screen.dart';
import 'package:page_transition/page_transition.dart';

class OnBoarding extends StatelessWidget {
  const OnBoarding({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
        body: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          height: 350,
          child: Image.asset('assets/images/onboarding.jpg'),
        ),
        const SizedBox(
          height: 30,
        ),
        Text(
          'Welcome To \n Harvest Guardian',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Constants.primaryColor,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(
          height: 50,
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
                context,
                PageTransition(
                    child: const SignUp(),
                    type: PageTransitionType.bottomToTop));
          },
          child: Container(
            width: size.width / 1.2,
            decoration: BoxDecoration(
              color: Constants.primaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            child: const Center(
              child: Text(
                'SignUp',
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
                    child: const SignIn(),
                    type: PageTransitionType.bottomToTop));
          },
          child: Container(
            width: size.width / 1.2,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            child: Center(
              child: Text(
                'SignIn',
                style: TextStyle(
                  color: Constants.primaryColor,
                  fontSize: 18.0,
                ),
              ),
            ),
          ),
        ),
      ],
    ));
  }
}
