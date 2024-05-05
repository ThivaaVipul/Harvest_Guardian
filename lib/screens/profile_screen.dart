import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:harvest_guardian/constants.dart';
import 'package:harvest_guardian/screens/authentication/signin_screen.dart';
import 'package:harvest_guardian/screens/edit_profile_screen.dart';
import 'package:page_transition/page_transition.dart';

class ProfilePage extends StatefulWidget {
  // ignore: use_key_in_widget_constructors
  const ProfilePage({Key? key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<void> _fetchUser;

  @override
  void initState() {
    super.initState();
    _fetchUser = _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    await FirebaseAuth.instance.currentUser!.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.edit,
              color: Constants.primaryColor,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfilePage(),
                ),
              ).then((_) {
                setState(() {
                  _fetchUser = _fetchUserData();
                });
              });
            },
          ),
        ],
        title: Text(
          "Profile Page",
          style: TextStyle(
            color: Constants.primaryColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Center(
        child: FutureBuilder(
          future: _fetchUser,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              return const UserProfileWidget();
            }
          },
        ),
      ),
    );
  }
}

class UserProfileWidget extends StatelessWidget {
  const UserProfileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) {
                  return Scaffold(
                    backgroundColor: Colors.white,
                    appBar: AppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      leading: IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: Constants.primaryColor,
                          size: 35,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      title: Text(
                        FirebaseAuth.instance.currentUser!.displayName
                            .toString(),
                        style: TextStyle(
                          color: Constants.primaryColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    body: GestureDetector(
                      onHorizontalDragEnd: (details) {
                        Navigator.pop(context);
                      },
                      child: Center(
                        child: Image.network(
                          FirebaseAuth.instance.currentUser!.photoURL ??
                              'https://st4.depositphotos.com/1496387/40483/v/450/depositphotos_404831150-stock-illustration-happy-farmer-logo-agriculture-natural.jpg',
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage(
                  FirebaseAuth.instance.currentUser!.photoURL ??
                      'https://st4.depositphotos.com/1496387/40483/v/450/depositphotos_404831150-stock-illustration-happy-farmer-logo-agriculture-natural.jpg',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        Text(
          FirebaseAuth.instance.currentUser!.displayName ?? '',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(
          height: 10,
        ),
        Text(
          FirebaseAuth.instance.currentUser!.email ?? '',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(
          height: 30,
        ),
        ElevatedButton(
          onPressed: () {
            FirebaseAuth.instance.signOut();
            Navigator.pushReplacement(
              context,
              PageTransition(
                child: const SignIn(),
                type: PageTransitionType.bottomToTop,
              ),
            );
          },
          child: const Text(
            "Logout",
          ),
        ),
      ],
    );
  }
}
