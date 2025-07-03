import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:with_force/providers/auth_provider.dart';

class UserDetailsSetupScreen extends StatefulWidget {
  final VoidCallback onCompleted;
  final Map<String, dynamic>? initialData;
  final bool isOnboarding;

  const UserDetailsSetupScreen({
    Key? key,
    required this.onCompleted,
    this.initialData,
    this.isOnboarding = false,
  }) : super(key: key);

  @override
  _UserDetailsSetupScreenState createState() => _UserDetailsSetupScreenState();
}

class _UserDetailsSetupScreenState extends State<UserDetailsSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  
  DateTime? _selectedBirthdate;
  String? _selectedGender;
  bool _isLoading = false;

  final List<String> _genderOptions = ['male', 'female', 'other'];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    if (widget.initialData != null) {
      final data = widget.initialData!;
      _firstNameController.text = data['firstName'] ?? '';
      _lastNameController.text = data['lastName'] ?? '';
      _emailController.text = data['email'] ?? '';
      _weightController.text = data['weight']?.toString() ?? '';
      _heightController.text = data['height']?.toString() ?? '';
      _selectedGender = data['gender'];
      
      if (data['birthdate'] != null) {
        try {
          _selectedBirthdate = DateTime.parse(data['birthdate']);
        } catch (e) {
          // Invalid date format
        }
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isOnboarding ? 'Complete Your Profile' : 'Edit Profile'),
        automaticallyImplyLeading: !widget.isOnboarding,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header for onboarding
              if (widget.isOnboarding) ...[
                Icon(
                  Icons.person_add,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome! Let\'s set up your profile',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'This helps us personalize your experience',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
              ],
              
              // Personal Information Section
              _buildSectionHeader('Personal Information'),
              const SizedBox(height: 16),
              
              // First Name
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name *',
                  hintText: 'Enter your first name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Last Name
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name *',
                  hintText: 'Enter your last name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  hintText: 'Enter your email address',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email address';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Date of Birth
              InkWell(
                onTap: _selectBirthdate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    prefixIcon: Icon(Icons.cake),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _selectedBirthdate != null
                        ? '${_selectedBirthdate!.day}/${_selectedBirthdate!.month}/${_selectedBirthdate!.year}'
                        : 'Select your date of birth',
                    style: TextStyle(
                      color: _selectedBirthdate != null ? null : Colors.grey[600],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Gender
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: Icon(Icons.wc),
                  border: OutlineInputBorder(),
                ),
                items: _genderOptions.map((gender) {
                  return DropdownMenuItem(
                    value: gender,
                    child: Text(_formatGenderDisplay(gender)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              
              // Physical Information Section
              _buildSectionHeader('Physical Information'),
              const SizedBox(height: 16),
              
              // Weight
              TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  hintText: 'Enter your weight',
                  prefixIcon: Icon(Icons.monitor_weight),
                  border: OutlineInputBorder(),
                  suffixText: 'kg',
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final weight = double.tryParse(value);
                    if (weight == null || weight <= 0) {
                      return 'Please enter a valid weight';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Height
              TextFormField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Height (cm)',
                  hintText: 'Enter your height',
                  prefixIcon: Icon(Icons.height),
                  border: OutlineInputBorder(),
                  suffixText: 'cm',
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final height = double.tryParse(value);
                    if (height == null || height <= 0) {
                      return 'Please enter a valid height';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                        widget.initialData != null ? 'Update Profile' : 'Complete Setup',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
              
              // Skip button for onboarding
              if (widget.isOnboarding) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading ? null : _skipSetup,
                  child: const Text('Skip for now'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  String _formatGenderDisplay(String gender) {
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

  Future<void> _selectBirthdate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedBirthdate ?? DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        _selectedBirthdate = date;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      final profileData = <String, dynamic>{
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'birthdate': _selectedBirthdate?.toIso8601String().split('T')[0], // Format as YYYY-MM-DD
        'gender': _selectedGender,
        'onboarded': true,
      };

      // Add weight and height if provided
      if (_weightController.text.isNotEmpty) {
        profileData['weight'] = double.tryParse(_weightController.text);
      }
      if (_heightController.text.isNotEmpty) {
        profileData['height'] = double.tryParse(_heightController.text);
      }

      final result = await authService.makeAuthenticatedRequest(
        endpoint: 'user',
        method: 'POST',
        body: profileData,
      );

      if (result['success']) {
        _showMessage('Profile saved successfully!', isSuccess: true);
        widget.onCompleted();
        if (!widget.isOnboarding) {
          Navigator.pop(context);
        }
      } else {
        _showMessage(result['message'] ?? 'Failed to save profile');
      }
    } catch (e) {
      _showMessage('Error saving profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _skipSetup() {
    widget.onCompleted();
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