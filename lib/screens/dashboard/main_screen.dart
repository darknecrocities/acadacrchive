import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:acadarchivelatest/screens/dashboard/home_screen.dart";
import "package:acadarchivelatest/screens/upload/upload_screen.dart";
import "package:acadarchivelatest/screens/resources/resources_screen.dart";
import "package:acadarchivelatest/screens/profile/profile_screen.dart";
import "package:acadarchivelatest/screens/analytics/analytics_screen.dart";

class MainScreen extends StatefulWidget {
  final void Function(bool isDark)? onToggleTheme; // ✅ for theme switching
  const MainScreen({super.key, this.onToggleTheme});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // ✅ Hide Android/iOS system navigation and status bars
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _setSelectedIndex(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> screens = [
      HomeScreen(onNavigateToTab: _setSelectedIndex),
      const ResourcesScreen(),
      const UploadScreen(),
      const AnalyticsScreen(),
      ProfileScreen(onToggleTheme: widget.onToggleTheme, isDarkMode: isDarkMode),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Row(
          children: [
            Icon(Icons.storage, color: isDarkMode ? Colors.white : Colors.black),
            const SizedBox(width: 6),
            Text(
              "AcadArchive",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: IndexedStack(
          key: ValueKey<int>(_selectedIndex),
          index: _selectedIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _setSelectedIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor:
        isDarkMode ? Colors.grey[900] : Colors.white,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        showUnselectedLabels: true,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.file_copy_outlined),
            activeIcon: Icon(Icons.file_copy),
            label: "Resources",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_outlined),
            activeIcon: Icon(Icons.upload),
            label: "Upload",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: "Analytics",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // ✅ Restore UI bars when leaving this screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }
}
