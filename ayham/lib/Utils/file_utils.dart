import 'package:flutter/material.dart';

Icon getFileIcon(String fileName) {
  final extension = fileName.split('.').last.toLowerCase();
  if (['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(extension)) {
    return const Icon(Icons.image, color: Colors.green, size: 30);
  } else if (['pdf'].contains(extension)) {
    return const Icon(Icons.picture_as_pdf, color: Colors.red, size: 30);
  } else if (['doc', 'docx'].contains(extension)) {
    return const Icon(Icons.description, color: Colors.blue, size: 30);
  } else if (['xls', 'xlsx'].contains(extension)) {
    return const Icon(Icons.table_chart, color: Colors.green, size: 30);
  } else {
    return const Icon(Icons.insert_drive_file, color: Colors.grey, size: 30);
  }
}

String getFileType(String fileName) {
  final extension = fileName.split('.').last.toLowerCase();
  if (['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(extension)) return 'Image';
  if (['pdf'].contains(extension)) return 'PDF Document';
  if (['doc', 'docx'].contains(extension)) return 'Word Document';
  if (['xls', 'xlsx'].contains(extension)) return 'Excel Sheet';
  return 'File';
}

String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / 1048576).toStringAsFixed(1)} MB';
}