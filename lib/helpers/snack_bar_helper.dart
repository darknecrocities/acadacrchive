import "package:flutter/material.dart";

class SnackBarHelper {
  static void show(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.grey[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 2500),
        content: Text(text, style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500))
      )
    );
  }
}