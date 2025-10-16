import "package:flutter/material.dart";

class HomeScreen extends StatefulWidget {
  final Function(int) onNavigateToTab;

  const HomeScreen({super.key, required this.onNavigateToTab});

  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 160),
          const Text("Your Academic Organizer", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text("Upload new resources or view your saved\nnotes, projects, and assignments.", style: TextStyle(color: Colors.grey[800], fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => widget.onNavigateToTab(2),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)
                )
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload_rounded),
                  SizedBox(width: 8),
                  Text("Upload Resources", style: TextStyle(fontSize: 16))
                ]
              )
            )
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => widget.onNavigateToTab(1),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.blueAccent,
                shadowColor: Colors.transparent,
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(
                  color: Colors.blueAccent,
                  width: 1
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)
                )
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.file_copy_rounded),
                  SizedBox(width: 8),
                  Text("My Resources", style: TextStyle(fontSize: 16))
                ]
              )
            )
          )
        ]
      )
    );
  }
}
