import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:with_force/providers/auth_provider.dart';


class AccountDetailsScreen extends StatefulWidget {
  const AccountDetailsScreen({Key? key}) : super(key: key);

  @override
  _AccountDetailsScreenState createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userData = authService.userData;
    
    return RefreshIndicator(
      onRefresh: _refreshAccountData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Summary Card
            _buildAccountSummaryCard(userData),
            const SizedBox(height: 20),
            
            // Authentication Details
            _buildAuthenticationCard(userData),
            const SizedBox(height: 20),
            
            // Security Settings
          
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSummaryCard(Map<String, dynamic>? userData) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                  child: Text(
                    _getInitials(userData),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData?['name'] ?? userData?['username'] ?? 'User',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userData?['email'] ?? userData?['username'] ?? 'No email',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Active',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.fingerprint, 'User ID', userData?['id'] ?? userData?['username'] ?? 'Not available'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.access_time, 'Member Since', 'Recent'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.verified_user, 'Account Status', 'Verified'),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthenticationCard(Map<String, dynamic>? userData) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Authentication Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.email, 'Login Email', userData?['username'] ?? 'Not available'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.security, 'Authentication Method', 'JWT Token'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.schedule, 'Last Login', 'Today'),
            const SizedBox(height: 8),
            if (userData?['accessToken'] != null)
              _buildInfoRow(Icons.key, 'Token Status', 'Active'),
          ],
        ),
      ),
    );
  }

 

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
    );
  }

  String _getInitials(Map<String, dynamic>? userData) {
    final name = userData?['name'] ?? userData?['username'] ?? 'U';
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Future<void> _refreshAccountData() async {
    setState(() => _isLoading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Make an API call to refresh user data
      final result = await authService.makeAuthenticatedRequest(
        endpoint: 'user/profile',
        method: 'GET',
      );
      
      if (result['success']) {
        _showMessage('Account data refreshed', isSuccess: true);
      } else {
        _showMessage('Failed to refresh data');
      }
    } catch (e) {
      _showMessage('Error refreshing data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _changePassword() {
    Navigator.pushNamed(context, '/forgot-password');
  }

  void _openPrivacySettings() {
    _showMessage('Privacy settings - Coming soon!');
  }

  void _setupTwoFactor() {
    _showMessage('Two-factor authentication - Coming soon!');
  }

  void _openNotificationSettings() {
    _showMessage('Notification settings - Coming soon!');
  }

  void _changeLanguage() {
    _showMessage('Language settings - Coming soon!');
  }

  void _openSupport() {
    _showMessage('Help & Support - Coming soon!');
  }

  void _showMessage(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : null,
      ),
    );
  }
}