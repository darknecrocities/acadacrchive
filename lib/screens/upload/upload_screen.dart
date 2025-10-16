import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:acadarchivelatest/helpers/snack_bar_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  static const List<String> _semesters = ["1st Semester", "2nd Semester"];

  final _titleController = TextEditingController();
  final _courseController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedSemester;
  File? _selectedFile;

  String? _fileName;
  String? _fileSize;
  bool _isUploading = false;

  bool get _isImage =>
      _selectedFile != null &&
          (_fileName!.toLowerCase().endsWith(".jpg") ||
              _fileName!.toLowerCase().endsWith(".jpeg") ||
              _fileName!.toLowerCase().endsWith(".png"));

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ["pdf", "docx", "ppt", "pptx", "jpg", "jpeg", "png"],
    );

    if (result == null) return;

    final file = File(result.files.single.path!);
    final fileSizeInBytes = await file.length();

    setState(() {
      _selectedFile = file;
      _fileName = result.files.single.name;
      _fileSize = _formatBytes(fileSizeInBytes, 2);
    });

    SnackBarHelper.show(context, "File selected successfully.");
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) {
      if (mounted) SnackBarHelper.show(context, "Please select a file first.");
      return;
    }
    if (_titleController.text.isEmpty ||
        _courseController.text.isEmpty ||
        _selectedSemester == null) {
      if (mounted) SnackBarHelper.show(context, "Please fill all required fields.");
      return;
    }

    if (mounted) setState(() => _isUploading = true);

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() => _isUploading = false);
        SnackBarHelper.show(context, "You must be logged in to upload files.");
      }
      return;
    }
    String sanitizeFileName(String fileName) {
      // Remove characters not allowed in Supabase storage keys
      return fileName.replaceAll(RegExp(r'[^\w\-.]'), '_');
    }


    final sanitizedFileName = sanitizeFileName(_fileName!);

    final filePath =
        "uploads/${user.id}/${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName";


    try {
      // Upload file to the 'uploads' folder
      await supabase.storage.from('files').upload(
        filePath,
        _selectedFile!,
        fileOptions: const FileOptions(upsert: true),
      );

      // Get public URL
      final publicUrl = supabase.storage.from('files').getPublicUrl(filePath);

      // Insert metadata into database
      final insertResponse = await supabase.from('resources').insert({
        'user_id': user.id,
        'title': _titleController.text,
        'course': _courseController.text,
        'semester': _selectedSemester!,
        'description': _descriptionController.text,
        'file_url': publicUrl,
        'uploaded_at': DateTime.now().toIso8601String(),
      }).select();


      if (insertResponse.isEmpty) {
        throw Exception("Failed to save metadata.");
      }

      if (mounted) {
        SnackBarHelper.show(context, "File uploaded successfully!");
        // Reset form
        setState(() {
          _selectedFile = null;
          _fileName = null;
          _fileSize = null;
          _titleController.clear();
          _courseController.clear();
          _descriptionController.clear();
          _selectedSemester = null;
        });
      }
    } catch (e) {
      print("Upload failed: $e");
      if (mounted) SnackBarHelper.show(context, "Upload failed: $e");
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }


  String _formatBytes(int bytes, int decimals) {
    if (bytes == 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    final i = (log(bytes) / log(1024)).floor();
    final size = bytes / pow(1024, i);
    return "${size.toStringAsFixed(decimals)} ${suffixes[i]}";
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Center(
            child: Text("Upload Resource",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              "Submit your academic files to store and\naccess them across devices.",
              style: TextStyle(color: Colors.grey[800], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),

          // Title Field
          const Text("Title",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                  hintText: "Enter title",
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12)),
            ),
          ),
          const SizedBox(height: 16),

          // Course Field
          const Text("Course",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: TextField(
              controller: _courseController,
              decoration: const InputDecoration(
                  hintText: "Enter course",
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12)),
            ),
          ),
          const SizedBox(height: 16),

          // Semester Dropdown
          const Text("Semester",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: DropdownButtonFormField<String>(
              value: _selectedSemester,
              hint: const Text("Select semester"),
              onChanged: (value) => setState(() => _selectedSemester = value),
              style: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                  color: Colors.black),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              items: _semesters
                  .map((sem) => DropdownMenuItem(value: sem, child: Text(sem)))
                  .toList(),
              dropdownColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Description Field
          const Text("Description (Optional)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                  hintText: "Enter description",
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12)),
            ),
          ),
          const SizedBox(height: 32),

          // File Preview / Info
          if (_selectedFile != null && _isImage)
            Center(
              child: Image.file(
                _selectedFile!,
                width: 150,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
          Center(
            child: Text(
              (_selectedFile != null)
                  ? "Selected file:\n$_fileName ($_fileSize)"
                  : "No file selected yet.",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              "Allowed file types: pdf, docx, ppt, pptx, jpg, png",
              style: TextStyle(color: Colors.grey[800], fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),

          // Select File Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isUploading ? null : _pickFile,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.blueAccent,
                  shadowColor: Colors.transparent,
                  side: const BorderSide(color: Colors.blueAccent, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6))),
              child: const Text("Select File", style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 16),

          // Upload Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isUploading ? null : _uploadFile,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isUploading)
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  else
                    const Icon(Icons.upload),
                  const SizedBox(width: 8),
                  Text(_isUploading ? "Uploading..." : "Upload",
                      style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
