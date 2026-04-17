import 'package:flutter/material.dart';
import '../models/mb_profile.dart';
import '../services/profile_auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileAuthService _auth = ProfileAuthService();

  bool _loading = true;
  String? _error;
  MbProfile? _profile;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final loggedIn = await _auth.hasSession();
      if (!loggedIn) {
        setState(() {
          _profile = null;
          _loading = false;
        });
        return;
      }

      final profile = await _auth.fetchProfile();
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _auth.login();
      final profile = await _auth.fetchProfile();
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    await _auth.logout();
    setState(() {
      _profile = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final username = _profile?.nickname?.isNotEmpty == true
        ? _profile!.nickname
        : (_profile?.preferredUsername?.isNotEmpty == true
              ? _profile!.preferredUsername
              : null);

    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _profile == null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Log in with MangaBaka to view your profile and scopes.',
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _login,
                      child: const Text('Login on MangaBaka'),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username != null ? "${username}'s Profile" : 'Profile',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('ID: ${_profile!.id}'),
                    const SizedBox(height: 8),
                    Text('Role: ${_profile!.role}'),
                    const SizedBox(height: 8),
                    Text('Scopes: ${_profile!.scopes.join(', ')}'),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: _logout,
                      child: const Text('Logout'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
