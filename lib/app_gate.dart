import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'models/app_user.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/profile_setup_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'widgets/common.dart';

/// يقرر الشاشة الأولى: التسجيل ← إكمال الملف ← الرئيسية.
class AppGate extends StatelessWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
        final user = snap.data;
        if (user == null) return const LoginScreen();
        return _ProfileGate(key: ValueKey(user.uid), authUser: user);
      },
    );
  }
}

class _ProfileGate extends StatefulWidget {
  final User authUser;
  const _ProfileGate({super.key, required this.authUser});

  @override
  State<_ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<_ProfileGate> {
  late final Stream<AppUser?> _profile =
      FirestoreService.instance.userStream(widget.authUser.uid);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: _profile,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            body: MessageView(
              icon: Icons.cloud_off,
              title: 'تعذر تحميل بياناتك',
              subtitle: '${snap.error}',
            ),
          );
        }
        if (!snap.hasData && snap.connectionState == ConnectionState.waiting) {
          return const LoadingView();
        }
        final profile = snap.data;
        if (profile == null) {
          return ProfileSetupScreen(
            uid: widget.authUser.uid,
            initialName: widget.authUser.displayName ?? '',
            email: widget.authUser.email ?? '',
          );
        }
        return HomeScreen(user: profile);
      },
    );
  }
}
