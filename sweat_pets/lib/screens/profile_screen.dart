import 'package:flutter/material.dart';
import 'package:sweat_pets/models/user_profile.dart';
import 'package:sweat_pets/models/achievements.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// A screen to display and manage user profiles
class ProfileScreen extends StatefulWidget {
  /// Callback when going back
  final VoidCallback? onBackPressed;
  
  /// Callback when user wants to select a pet
  final VoidCallback? onSelectPet;

  /// Creates a profile screen
  const ProfileScreen({
    Key? key,
    this.onBackPressed,
    this.onSelectPet,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _currentProfile;
  List<Achievement> _unlockedAchievements = [];
  List<Map<String, dynamic>> _profileList = [];
  bool _isLoading = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _profileNameController = TextEditingController();
  bool _editingName = false;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _profileNameController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load current profile
      final profile = await UserProfile.load();
      
      // Load achievements
      final achievements = Achievements.getUserAchievements(profile);
      final unlocked = achievements.where((a) => a.unlocked).toList();
      
      // Get list of available profiles
      final profileList = await _getProfileList();
      
      setState(() {
        _currentProfile = profile;
        _unlockedAchievements = unlocked;
        _profileList = profileList;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading profile data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<List<Map<String, dynamic>>> _getProfileList() async {
    final prefs = await SharedPreferences.getInstance();
    
    // For now, we just have one profile, but we'll structure this for future expansion
    final profileData = prefs.getString('sweatPetUser');
    if (profileData == null) {
      return [];
    }
    
    try {
      final userData = jsonDecode(profileData) as Map<String, dynamic>;
      return [userData];
    } catch (e) {
      debugPrint('Error loading profile list: $e');
      return [];
    }
  }
  
  Future<void> _createNewProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    
    // Create a new profile with a unique ID
    final newProfile = UserProfile.defaultProfile();
    
    // Set the name
    newProfile.name = name;
    
    // Save the new profile
    await newProfile.save();
    
    // Reload data
    _loadData();
    
    // Reset the text field
    _nameController.clear();
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: colorScheme.surfaceVariant,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBackPressed,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24.0),
                    color: colorScheme.surfaceVariant,
                    child: Column(
                      children: [
                        // Profile avatar
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: colorScheme.primary.withOpacity(0.2),
                          child: Icon(
                            Icons.person,
                            size: 48,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Profile ID
                        _editingName
                          ? Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _profileNameController,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: 'Enter your name',
                                        border: OutlineInputBorder(),
                                      ),
                                      autofocus: true,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.check),
                                    onPressed: _saveProfileName,
                                  ),
                                ],
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentProfile?.name ?? 'Trainer',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 16),
                                  onPressed: () {
                                    setState(() {
                                      _profileNameController.text = _currentProfile?.name ?? 'Trainer';
                                      _editingName = true;
                                    });
                                  },
                                ),
                              ],
                            ),
                        const SizedBox(height: 8),
                        
                        // Last sync time
                        if (_currentProfile?.lastSync != null)
                          Text(
                            'Last synced: ${_formatDate(_currentProfile!.lastSync!)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Stats section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stats',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildStatCard(
                          title: 'Total Steps',
                          value: '${_currentProfile?.steps ?? 0}',
                          icon: Icons.directions_walk,
                          color: Colors.blue,
                        ),
                        _buildStatCard(
                          title: 'Pet Level',
                          value: '${_currentProfile?.activePetState?.currentLevel ?? 1}',
                          icon: Icons.pets,
                          color: Colors.orange,
                        ),
                        _buildStatCard(
                          title: 'Achievements',
                          value: '${_unlockedAchievements.length}/${Achievements.all.length}',
                          icon: Icons.emoji_events,
                          color: Colors.amber,
                        ),
                      ],
                    ),
                  ),
                  
                  // Pet section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'My Pets',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.blue.withOpacity(0.2),
                                  child: const Icon(Icons.pets, color: Colors.blue),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentProfile?.activePet?.name ?? 'SweatPet',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Level: ${_currentProfile?.activePetState?.currentLevel ?? 1}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: widget.onSelectPet,
                                  child: const Text('CHANGE'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Achievements section
                  if (_unlockedAchievements.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Unlocked Achievements',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._buildAchievementItems(),
                        ],
                      ),
                    ),
                  
                  // Add new profile section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Create New Profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Profile Name',
                            hintText: 'Enter a name for the new profile',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _createNewProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                          ),
                          child: const Text('Create Profile'),
                        ),
                      ],
                    ),
                  ),
                  
                  // Profile list section
                  if (_profileList.isNotEmpty && _profileList.length > 1)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Available Profiles',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._buildProfileItems(),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  List<Widget> _buildHistoryItems() {
    if (_currentProfile == null || _currentProfile!.history.isEmpty) {
      return [
        const Text('No history available yet'),
      ];
    }
    
    // Sort history by date, newest first
    final sortedHistory = List<Map<String, dynamic>>.from(_currentProfile!.history)
      ..sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
    
    // Take only the 10 most recent entries
    final recentHistory = sortedHistory.take(10).toList();
    
    return recentHistory.map((item) {
      final dateStr = item['date'] as String;
      final steps = item['steps'] as int;
      
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '$steps steps',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
  
  List<Widget> _buildAchievementItems() {
    return _unlockedAchievements.map((achievement) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.amber.withOpacity(0.2),
                child: Icon(achievement.icon, color: Colors.amber),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      achievement.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    if (achievement.unlockedAt != null)
                      Text(
                        'Unlocked: ${_formatDate(achievement.unlockedAt!)}',
                        style: TextStyle(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
  
  List<Widget> _buildProfileItems() {
    return _profileList.map((profile) {
      final id = profile['id'] as String;
      final isCurrentProfile = _currentProfile != null && _currentProfile!.id == id;
      
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        color: isCurrentProfile 
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'User #${id.substring(0, 6)}',
                style: TextStyle(
                  fontWeight: isCurrentProfile ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (isCurrentProfile)
                Chip(
                  label: const Text('Current'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      );
    }).toList();
  }
  
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  void _saveProfileName() {
    if (_currentProfile == null) return;
    
    final newName = _profileNameController.text.trim();
    if (newName.isEmpty) return;
    
    setState(() {
      _currentProfile!.name = newName;
      _editingName = false;
    });
    
    // Save profile
    _currentProfile!.save();
  }
} 