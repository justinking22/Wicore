import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:with_force/providers/auth_provider.dart';
import 'package:with_force/screens/user_details_setup_screen.dart';

import '../screens/user_details_screen.dart';
import '../screens/account_details_screen.dart';
import 'register_device_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  bool _isLoading = false;

  // List of screens for IndexedStack
  static const List<Widget> _screens = [
    AccountDetailsScreen(),
    RegisterDeviceScreen(),
    UserDetailsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkFirstTimeLogin();
  }

  Future<void> _checkFirstTimeLogin() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userData = authService.userData;

    // Check if this is the first time login (you can customize this logic)
    if (userData != null && !_hasCompletedProfile(userData)) {
      // Show user details screen for first-time setup
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showUserDetailsSetup();
      });
    }
  }

  bool _hasCompletedProfile(Map<String, dynamic> userData) {
    // Check if user has completed their profile
    // You can customize this logic based on your requirements
    return userData['profileCompleted'] == true ||
        (userData['name'] != null &&
            userData['phone'] != null &&
            userData['dateOfBirth'] != null);
  }

  void _showUserDetailsSetup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: UserDetailsSetupScreen(
              onCompleted: () {
                Navigator.of(context).pop();
                setState(() {}); // Refresh the home screen
              },
            ),
          ),
    );
  }

  Future<void> _signOut() async {
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.signOut();

      if (result['success']) {
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        _showMessage(result['message']);
      }
    } catch (e) {
      _showMessage('An error occurred: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userData = authService.userData;

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome ${_getDisplayName(userData)}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'profile':
                    _showUserDetailsSetup();
                    break;
                  case 'logout':
                    _signOut();
                    break;
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person, color: Colors.grey),
                          SizedBox(width: 8),
                          Text('Edit Profile'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Sign Out'),
                        ],
                      ),
                    ),
                  ],
            ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Account',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.devices), label: 'Devices'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  String _getDisplayName(Map<String, dynamic>? userData) {
    if (userData == null) return 'User';

    return userData['name'] ??
        userData['email'] ??
        userData['username'] ??
        'User';
  }
}
