import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geobeep/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:geobeep/main.dart';
import 'package:geobeep/screen/login.dart';
import 'package:geobeep/utils/app_logger.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    AppLogger.log("AuthWrapper build called");
    
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Add debug logging for connection state
        AppLogger.log("AuthWrapper stream connection state: ${snapshot.connectionState}");
        
        // If connection state is waiting, show a loading indicator
        if (snapshot.connectionState == ConnectionState.waiting) {
          AppLogger.log("AuthWrapper waiting for auth state");
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // If we have a user, navigate to the main content
        if (snapshot.hasData) {
          AppLogger.log("AuthWrapper: User authenticated, showing MainPage");
          return MainPage();
        }
        
        // Otherwise, show the login screen
        AppLogger.log("AuthWrapper: No user, showing LoginPage");
        return LoginPage();
      },
    );
  }
}
