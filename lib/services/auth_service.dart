import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:geobeep/utils/app_logger.dart';
import 'package:geobeep/providers/station_provider.dart';
import 'package:provider/provider.dart';
import 'package:geobeep/main.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    AppLogger.log("AuthService factory called");
    return _instance;
  }
  AuthService._internal() {
    AppLogger.log("AuthService initialized");
    _initializeAuth();
  } // Initialize auth settings and set up auth state listener
  Future<void> _initializeAuth() async {
    try {
      // Disable app verification for Firebase Auth to prevent reCAPTCHA issues
      await _auth.setSettings(appVerificationDisabledForTesting: true);
      AppLogger.log("Firebase Auth settings configured to disable reCAPTCHA");

      // Set up auth state listener to notify other services
      _auth.authStateChanges().listen((User? user) {
        if (user != null) {
          AppLogger.log("AuthService: User signed in: ${user.uid}");
        } else {
          AppLogger.log("AuthService: User signed out");
        }

        // Find StationProvider instance from provider tree
        final navigatorContext = navigatorKey.currentContext;
        if (navigatorContext != null) {
          try {
            final stationProvider = Provider.of<StationProvider>(
              navigatorContext,
              listen: false,
            );

            // Notify StationProvider of auth state change
            AppLogger.log(
              "AuthService: Notifying StationProvider of auth change",
            );
            stationProvider.onUserChanged(user);

            if (user != null) {
              AppLogger.log(
                "AuthService: StationProvider notified for login: ${user.uid}",
              );
            } else {
              AppLogger.log("AuthService: StationProvider notified for logout");
            }
          } catch (e) {
            AppLogger.log("Failed to notify StationProvider: $e");
          }
        } else {
          AppLogger.log(
            "AuthService: navigatorKey.currentContext is null, cannot notify StationProvider",
          );
        }
      });
    } catch (e) {
      AppLogger.log("Failed to configure Firebase Auth settings: $e");
    }
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;
  // Stream of auth state changes
  Stream<User?> get authStateChanges {
    AppLogger.log("AuthService: authStateChanges requested");
    return _auth.authStateChanges();
  }

  // Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      AppLogger.log("Attempting to sign in with email: $email");

      // Sign in with email and password
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      AppLogger.log("Sign in successful for user: ${userCredential.user?.uid}");
      return userCredential;
    } on FirebaseAuthException catch (e) {
      AppLogger.log("Firebase Auth exception: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      AppLogger.log("General sign in error: $e");
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
    String username,
  ) async {
    try {
      // Create user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(username);

      // Reload user to make sure we have the updated profile
      await userCredential.user?.reload();

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with the credential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Verify password reset code
  Future<bool> verifyPasswordResetCode(String code) async {
    try {
      await _auth.verifyPasswordResetCode(code);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Confirm password reset
  Future<void> confirmPasswordReset(String code, String newPassword) async {
    try {
      await _auth.confirmPasswordReset(code: code, newPassword: newPassword);
    } catch (e) {
      rethrow;
    }
  }

  // Check if user has premium features
  Future<bool> hasPremiumFeatures() async {
    if (!isAuthenticated) {
      return false;
    }

    // This is a simple implementation. In a real app, you might check a database
    // or server for subscription status
    return true;
  }

  // Check if user is in guest mode
  bool get isGuestMode => !isAuthenticated;

  // Guest mode message
  String get guestModeMessage =>
      'Masuk atau daftar untuk mengakses fitur lengkap';
}
