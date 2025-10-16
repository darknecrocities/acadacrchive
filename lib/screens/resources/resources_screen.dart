// lib/screens/resources_screen.dart
import "dart:io";
import "package:flutter/material.dart";
import "package:acadarchivelatest/helpers/snack_bar_helper.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "package:http/http.dart" as http;
import "package:path_provider/path_provider.dart";
import "package:open_filex/open_filex.dart";
import "package:permission_handler/permission_handler.dart";
import "../../widgets/card/resources_view_summarizer_card.dart"; // import the widget

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _resources = [];
  List<Map<String, dynamic>> _filteredResources = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  late VoidCallback _searchListener;

  @override
  void initState() {
    super.initState();
    _fetchResources();

    _searchListener = () => _filterResources(_searchController.text);
    _searchController.addListener(_searchListener);
  }

  @override
  void dispose() {
    _searchController.removeListener(_searchListener);
    _searchController.dispose();
    super.dispose();
  }

  void _filterResources(String query) {
    setState(() {
      _filteredResources = _resources
          .where((file) =>
      (file["title"] ?? "").toLowerCase().contains(query.toLowerCase()) ||
          (file["course"] ?? "").toLowerCase().contains(query.toLowerCase()) ||
          (file["semester"] ?? "").toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }


  Future<void> _fetchResources() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        SnackBarHelper.show(context, "Please log in to view your resources.");
        return;
      }

      final response = await supabase
          .from("resources")
          .select()
          .eq("user_id", user.id)
          .order("uploaded_at", ascending: false);

      final resources = List<Map<String, dynamic>>.from(response);
      setState(() {
        _resources = resources;
        _filteredResources = resources;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        SnackBarHelper.show(context, "Error loading resources: $e");
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _downloadFile(String fileUrl) async {
    try {
      if (Platform.isAndroid) {
        if (await Permission.manageExternalStorage.isGranted == false) {
          var status = await Permission.manageExternalStorage.request();
          if (!status.isGranted) {
            SnackBarHelper.show(context, "Storage permission denied.");
            return;
          }
        }
      }

      final uri = Uri.parse(fileUrl);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        String fileName = uri.pathSegments.last;

        Directory downloadDir;
        if (Platform.isAndroid) {
          downloadDir = Directory("/storage/emulated/0/Download");
        } else {
          downloadDir = await getApplicationDocumentsDirectory();
        }

        final filePath = "${downloadDir.path}/$fileName";
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        SnackBarHelper.show(context, "✅ File saved to Downloads as: $fileName");
        await OpenFilex.open(filePath);
      } else {
        SnackBarHelper.show(context, "❌ Failed to download file.");
      }
    } catch (e) {
      SnackBarHelper.show(context, "⚠️ Download error: $e");
    }
  }

  Future<void> _deleteFile(int index, String fileUrl) async {
    try {
      final fileName = Uri.parse(fileUrl).pathSegments.last;
      await supabase.storage.from("files").remove(["uploads/$fileName"]);

      final resourceId = _filteredResources[index]['id'];
      await supabase.from("resources").delete().eq("id", resourceId);

      setState(() {
        _resources.removeWhere((r) => r['id'] == resourceId);
        _filteredResources.removeAt(index);
      });

      SnackBarHelper.show(context, "Resource deleted successfully.");
    } catch (e) {
      SnackBarHelper.show(context, "Failed to delete: $e");
    }
  }

  IconData _getFileIcon(String type) {
    final ext = type.toLowerCase();
    if (ext.contains("pdf")) return Icons.picture_as_pdf;
    if (ext.contains("doc") || ext.contains("word")) return Icons.description;
    if (ext.contains("ppt")) return Icons.slideshow;
    if (ext.contains("jpg") || ext.contains("png")) return Icons.image;
    return Icons.insert_drive_file;
  }

  void _openViewSummarizeCard(Map<String, dynamic> file) {
    final title = file['title'] ?? 'Untitled';
    final fileUrl = file['file_url'] ?? '';
    final description = file['description'] ?? '';
    final course = file['course'] ?? 'Unknown Course';
    final semester = file['semester'] ?? 'Unknown Semester';
    final courseSemester = "$course • $semester";

    showDialog(
      context: context,
      builder: (_) => ResourcesViewSummarizeCard(
        title: title,
        fileUrl: fileUrl,
        description: description,
        courseSemester: courseSemester,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background, // ✅ Dynamic background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Center(
                child: Text(
                  "My Resources",
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  "View, manage, and access all your uploaded\nacademic materials.",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onBackground.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _searchController,
                onChanged: _filterResources,
                decoration: InputDecoration(
                  hintText: "Search resources...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: theme.inputDecorationTheme.fillColor ??
                      theme.colorScheme.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Cards
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredResources.length,
                itemBuilder: (context, index) {
                  final file = _filteredResources[index];
                  return Card(
                    color: theme.cardColor, // ✅ Uses dynamic theme color
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueAccent.withOpacity(0.1),
                        child: Icon(
                          _getFileIcon(file["title"] ?? ""),
                          color: Colors.blueAccent,
                        ),
                      ),
                      title: Text(
                        file["title"] ?? "Untitled",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        "${file["course"] ?? ""} • ${file["semester"] ?? ""}",
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == "view") {
                            _openViewSummarizeCard(file);
                          } else if (value == "download") {
                            await _downloadFile(file["file_url"] ?? "");
                          } else if (value == "delete") {
                            await _deleteFile(index, file["file_url"] ?? "");
                          }
                        },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: "view",
                              child: Row(
                                children: const [
                                  Icon(Icons.visibility, color: Colors.black),
                                  SizedBox(width: 10),
                                  Text("View Details"),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: "download",
                              child: Row(
                                children: const [
                                  Icon(Icons.download, color: Colors.black),
                                  SizedBox(width: 10),
                                  Text("Download"),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: "delete",
                              child: Row(
                                children: const [
                                  Icon(Icons.delete, color: Colors.black),
                                  SizedBox(width: 10),
                                  Text("Delete"),
                                ],
                              ),
                            ),
                          ]

                      ),
                    ),

                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
