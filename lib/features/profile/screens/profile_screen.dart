import 'package:bakahyou/database/database.dart';
import 'package:bakahyou/features/profile/services/statistics_service.dart';
import 'package:bakahyou/features/profile/widgets/statistic_card.dart';
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
  late final StatisticsService _statisticsService;

  bool _loading = true;
  String? _error;
  MbProfile? _profile;

  int _totalSeries = 0;
  int _chaptersRead = 0;
  int _volumesRead = 0;
  double _completionRate = 0.0;
  int _totalRereads = 0;

  @override
  void initState() {
    super.initState();
    _statisticsService = StatisticsService(AppDatabase());
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
      final totalSeries = await _statisticsService.getTotalSeries();
      final chaptersRead = await _statisticsService.getChaptersRead();
      final volumesRead = await _statisticsService.getVolumesRead();
      final completionRate = await _statisticsService.getCompletionRate();
      final totalRereads = await _statisticsService.getTotalRereads();

      setState(() {
        _profile = profile;
        _totalSeries = totalSeries;
        _chaptersRead = chaptersRead;
        _volumesRead = volumesRead;
        _completionRate = completionRate;
        _totalRereads = totalRereads;
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
      await _bootstrap();
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
      _totalSeries = 0;
      _chaptersRead = 0;
      _volumesRead = 0;
      _completionRate = 0.0;
      _totalRereads = 0;
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
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _login,
                      child: const Text('Login'),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${username ?? 'User'} Profile',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 28,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'At a Glance',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'A quick snapshot of ${username ?? 'your'} reading habits, ratings, and collection size.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          StatisticCard(
                            icon: Icons.library_books,
                            label: 'Total Series',
                            value: _totalSeries.toString(),
                          ),
                          const SizedBox(width: 16),
                          StatisticCard(
                            icon: Icons.menu_book,
                            label: 'Chapters Read',
                            value: _chaptersRead.toString(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          StatisticCard(
                            icon: Icons.book,
                            label: 'Volumes Read',
                            value: _volumesRead.toString(),
                          ),
                          const SizedBox(width: 16),
                          StatisticCard(
                            icon: Icons.percent,
                            label: 'Completion Rate',
                            value: '${_completionRate.toStringAsFixed(1)}%',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          StatisticCard(
                            icon: Icons.repeat,
                            label: 'Total Rereads',
                            value: _totalRereads.toString(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _logout,
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
