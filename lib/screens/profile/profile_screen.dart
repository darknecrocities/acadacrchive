import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:acadarchivelatest/helpers/navigation_helper.dart';
import 'package:acadarchivelatest/helpers/snack_bar_helper.dart';
import 'package:acadarchivelatest/screens/auth/login_screen.dart';
import 'package:acadarchivelatest/services/supabase_options.dart'; // ✅ ensure this import is here

class ProfileScreen extends StatefulWidget {
  final void Function(bool)? onToggleTheme;
  final bool isDarkMode; // ✅ add this

  const ProfileScreen({
    super.key,
    this.onToggleTheme,
    required this.isDarkMode, // ✅ mark as required
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = SupabaseOptions.client;
  String? _email;
  String? _username;
  String? _profileUrl;
  bool _loadingImage = false;
  bool _darkMode = false;

  int _uploadedFiles = 0;
  double _storageUsedMB = 0;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadProfileImage();
    _loadFileStats();
  }

  Future<void> _loadUserData() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      setState(() {
        _email = user.email;
        _username = user.userMetadata?['username'] ?? 'User';
      });
    } else {
      NavigationHelper.pushReplacement(context, const LoginScreen());
    }
  }

  Future<void> _loadProfileImage() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final filePath = '${user.id}/profile.png';
      final url = supabase.storage.from('profile').getPublicUrl(filePath);
      setState(() => _profileUrl = url);
    } catch (e) {
      debugPrint('Failed to load profile image: $e');
    }
  }

  Future<void> _loadFileStats() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final files = await supabase.storage.from('files').list(path: 'uploads/${user.id}');
      double totalMB = 0;

      for (var file in files) {
        final size = (file.metadata?["size"] ?? 0) as int;
        totalMB += size / (1024 * 1024);
      }

      setState(() {
        _uploadedFiles = files.length;
        _storageUsedMB = totalMB;
      });
    } catch (e) {
      debugPrint('Failed to fetch file stats: $e');
    }
  }

  Future<void> _uploadProfileImage() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (pickedFile == null) return;

      setState(() => _loadingImage = true);

      final file = File(pickedFile.path);
      final filePath = '${user.id}/profile.png';

      await supabase.storage.from('profile').upload(
        filePath,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      final url = supabase.storage.from('profile').getPublicUrl(filePath);
      setState(() {
        _profileUrl = url;
        _loadingImage = false;
      });

      SnackBarHelper.show(context, "Profile picture updated!");
    } catch (e) {
      setState(() => _loadingImage = false);
      SnackBarHelper.show(context, "Failed to upload image: $e");
    }
  }

  Future<void> _editUsername() async {
    final controller = TextEditingController(text: _username ?? "");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Username"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: "Enter new username",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUsername = controller.text.trim();
              if (newUsername.isEmpty) return;

              try {
                await supabase.auth.updateUser(UserAttributes(
                  data: {'username': newUsername},
                ));
                setState(() => _username = newUsername);
                if (mounted) Navigator.pop(context);
                SnackBarHelper.show(context, "Username updated successfully.");
              } catch (e) {
                SnackBarHelper.show(context, "Failed: $e");
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _logOut() async {
    try {
      await supabase.auth.signOut();
      if (mounted) {
        SnackBarHelper.show(context, "Logged out successfully.");
        NavigationHelper.pushReplacement(context, const LoginScreen());
      }
    } catch (e) {
      SnackBarHelper.show(context, "Logout failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _darkMode = isDark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            Text(
              "My Profile",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Manage your account and preferences",
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[700],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 28),

            // 👤 Profile Picture
            Stack(
              children: [
                CircleAvatar(
                  radius: 65,
                  backgroundColor: isDark
                      ? Colors.blueAccent.withAlpha(80)
                      : Colors.blueAccent.withAlpha(50),
                  backgroundImage:
                  _profileUrl != null ? NetworkImage(_profileUrl!) : null,
                  child: _profileUrl == null
                      ? const Icon(Icons.person, size: 70, color: Colors.white)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _uploadProfileImage,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.blueAccent,
                      child: _loadingImage
                          ? const CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white)
                          : const Icon(Icons.edit,
                          size: 20, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // 🧾 Stats Overview
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard("Uploads", "$_uploadedFiles", Icons.upload_file, isDark),
                _buildStatCard("Storage",
                    "${_storageUsedMB.toStringAsFixed(2)} MB", Icons.storage, isDark),
              ],
            ),

            const SizedBox(height: 24),

            // 🧍 User Details
            Card(
              elevation: 3,
              color: isDark ? Colors.grey[850] : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow("Username", _username ?? "Loading...", _editUsername, isDark),
                    const Divider(),
                    _buildDetailRow("Email", _email ?? "Loading...", null, isDark),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 🌗 Theme Toggle
            SwitchListTile(
              value: isDark,
              onChanged: (v) {
                widget.onToggleTheme?.call(v); // ✅ syncs with main.dart
                setState(() => _darkMode = v);
              },
              title: Text(
                "Dark Mode",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              activeColor: Colors.blueAccent,
            ),

            const SizedBox(height: 32),

            // 🚪 Logout Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _logOut,
                icon: const Icon(Icons.logout),
                label: const Text("Log Out", style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: 150,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(blurRadius: 5, color: Colors.black12)],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 30),
          const SizedBox(height: 8),
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, VoidCallback? onEdit, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[300] : Colors.black)),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black)),
            ],
          ),
        ),
        if (onEdit != null)
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, color: Colors.blueAccent),
          ),
      ],
    );
  }
}
