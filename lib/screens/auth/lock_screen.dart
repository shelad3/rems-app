import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';

class LockScreen extends StatefulWidget {
  final Widget child;

  const LockScreen({super.key, required this.child});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with WidgetsBindingObserver {
  final _auth = AuthService.instance;
  bool _locked = true;
  bool _canAuthenticate = false;
  bool _authInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _auth.lock();
      if (mounted) setState(() => _locked = true);
    }
    if (state == AppLifecycleState.resumed && _locked && !_authInProgress) {
      _tryAuthenticate();
    }
  }

  Future<void> _init() async {
    await _auth.load();
    try {
      _canAuthenticate = await _auth.canAuthenticate();
    } catch (_) {
      _canAuthenticate = false;
    }
    if (!_auth.lockEnabled) {
      if (mounted) setState(() => _locked = false);
    } else {
      _tryAuthenticate();
    }
  }

  Future<void> _tryAuthenticate() async {
    if (_authInProgress) return;
    setState(() => _authInProgress = true);
    try {
      final success = await _auth.authenticate().timeout(
        const Duration(seconds: 30),
        onTimeout: () => false,
      );
      if (mounted) {
        setState(() => _locked = !success);
      }
    } catch (_) {
      // auth failed - user can tap button to retry
    } finally {
      if (mounted) setState(() => _authInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_locked || !_auth.lockEnabled) return widget.child;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.home_work_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'REMS',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Real Estate Management System',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 48),
                if (_authInProgress)
                  const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Authenticating...'),
                    ],
                  )
                else ...[
                  FilledButton.icon(
                    onPressed: _tryAuthenticate,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Unlock with Biometrics'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(260, 52),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() => _locked = false);
                    },
                    icon: const Icon(Icons.lock_open),
                    label: const Text('Enter with Passcode'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(260, 52),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      _auth.setLockEnabled(false);
                      setState(() => _locked = false);
                    },
                    child: Text(
                      'Disable App Lock',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
