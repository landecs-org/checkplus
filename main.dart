import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_tensorflow/flutter_tensorflow.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCVP8zaUj2iDrooLbRQNypHqB8QNTLhGDE",
      authDomain: "attendance-fe1c8.firebaseapp.com",
      projectId: "attendance-fe1c8",
      storageBucket: "attendance-fe1c8.appspot.com",
      messagingSenderId: "903463376704",
      appId: "1:903463376704:web:d004c563d56aa286df8ca5",
      measurementId: "G-YY5GQZPSRK",
    ),
  );
  
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(const NearCheckApp());
  });
}

class NearCheckApp extends StatelessWidget {
  const NearCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NearCheck+',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      builder: (context, child) {
        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: child,
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user == null) {
            return const WelcomeScreen();
          }
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (userSnapshot.hasError) {
                return const Scaffold(
                  body: Center(child: Text('Error loading user data')),
                );
              }
              final userData = userSnapshot.data!.data() as Map<String, dynamic>;
              if (userData['role'] == 'teacher') {
                return TeacherDashboard(user: user, userData: userData);
              } else {
                return StudentDashboard(user: user, userData: userData);
              }
            },
          );
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
