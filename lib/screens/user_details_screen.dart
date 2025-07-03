import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:with_force/providers/auth_provider.dart';


class UserDetailsScreen extends StatefulWidget {
  const UserDetailsScreen({Key? key}) : super(key: key);

  @override
  _UserDetailsScreenState createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  Map<String, dynamic> _userProfile = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
   
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
       final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString('id');
      
      final result = await authService.makeAuthenticatedRequest(
        endpoint: 'user/$id',
        method: 'GET',
        
      );
      
      if (result['success'] && result['data'] != null) {
        setState(() {
          _userProfile = result['data'];
        });
      }
    } catch (e) {
      _showMessage('Error loading profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  Future<void> _updateUserProfile(Map<String, dynamic> updatedData) async {
    setState(() => _isLoading = true);
    
    try {
        final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString('id');
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.makeAuthenticatedRequest(
        endpoint: 'user/$id',
        method: 'PATCH',
        body: updatedData,
      );
      
      if (result['success']) {
        _showMessage('Profile updated successfully', isSuccess: true);
        _loadUserProfile();
      } else {
        _showMessage('Failed to update profile');
      }
    } catch (e) {
      _showMessage('Error updating profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  Future<void> _deleteUserProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString('id');
      
      final result = await authService.makeAuthenticatedRequest(
        endpoint: 'user/$id',
        method: 'DELETE',
      );
      
      if (result['success']) {
        _showMessage('Profile deleted successfully', isSuccess: true);
        Navigator.pop(context); // Go back to the previous screen
      } else {
        _showMessage('Failed to delete profile');
      }
    } catch (e) {
      _showMessage('Error deleting profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editProfile,
          ),
          SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteProfile,
          ),
        ],
        
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              _buildProfileHeader(),
              const SizedBox(height: 20),
              
              // Personal Information
              _buildPersonalInfoCard(),
              const SizedBox(height: 20),
              
              // Physical Information
              _buildPhysicalInfoCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final fullName = '${_userProfile['id']}';
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
              child: Text(
                _getInitials(),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              fullName.isNotEmpty ? fullName : 'User',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,

              ),
            ),
            Text(
              _userProfile['email'] ?? 'No email',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _userProfile['created'] ?? 'No data',

              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _userProfile['updated'] ?? 'Unknown',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _userProfile['onboarded'] == true 
                    ? Colors.green.withOpacity(0.2) 
                    : Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _userProfile['onboarded'] == true ? 'Onboarded' : 'Pending Onboarding',
                style: TextStyle(
                  color: _userProfile['onboarded'] == true ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _editProfile,
              child: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.person, 'First Name', _userProfile['firstName'] ?? 'Not set'),
            _buildInfoRow(Icons.person_outline, 'Last Name', _userProfile['lastName'] ?? 'Not set'),
            _buildInfoRow(Icons.email, 'Email', _userProfile['email'] ?? 'Not set'),
            _buildInfoRow(Icons.cake, 'Birthdate', _formatDate(_userProfile['birthdate'])),
            _buildInfoRow(Icons.wc, 'Gender', _formatGender(_userProfile['gender'])),
          ],
        ),
      ),
    );
  }

  Widget _buildPhysicalInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Physical Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.monitor_weight, 'Weight', 
                _userProfile['weight'] != null ? '${_userProfile['weight']} kg' : 'Not set'),
            _buildInfoRow(Icons.height, 'Height', 
                _userProfile['height'] != null ? '${_userProfile['height']} cm' : 'Not set'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials() {
    final firstName = _userProfile['firstName'] ?? '';
    final lastName = _userProfile['lastName'] ?? '';
    
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    } else if (firstName.isNotEmpty) {
      return firstName[0].toUpperCase();
    } else if (lastName.isNotEmpty) {
      return lastName[0].toUpperCase();
    }
    return 'U';
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Not set';
    
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _formatGender(String? gender) {
    if (gender == null || gender.isEmpty) return 'Not set';
    
    switch (gender.toLowerCase()) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'other':
        return 'Other';
      default:
        return gender;
    }
  }

  void _editProfile() {
    final firstNameController = TextEditingController(text: _userProfile['firstName']);
    final lastNameController = TextEditingController(text: _userProfile['lastName']);
    final ageController = TextEditingController(text: _userProfile['age']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                ),
                TextField(
                  controller: lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                ),
                TextField(
                  controller: ageController,
                  decoration: const InputDecoration(labelText: 'Age'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final updatedData = {
                  'firstName': firstNameController.text,
                  'lastName': lastNameController.text,
                  'age': int.tryParse(ageController.text),
                };
                _updateUserProfile(updatedData);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
   
  }
  void _deleteProfile() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Profile'),
          content: const Text('Are you sure you want to delete your profile? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteUserProfile();
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
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