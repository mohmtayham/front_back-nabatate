import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:nabtatcompany/providers/employee_provider.dart';
import 'package:nabtatcompany/utils/file_utils.dart';

class AttachmentsDialog extends StatefulWidget {
  final int employeeId;
  final String employeeName;

  const AttachmentsDialog({
    required this.employeeId,
    required this.employeeName,
    super.key,
  });

  @override
  State<AttachmentsDialog> createState() => _AttachmentsDialogState();
}

class _AttachmentsDialogState extends State<AttachmentsDialog> {
  bool _isLoading = true;
  bool _isUploading = false;
  bool _isDownloading = false;
  int? _downloadingAttachmentId; // لتتبع أي ملف يتم تحميله حالياً
  List<dynamic> _attachments = [];

  @override
  void initState() {
    super.initState();
    _loadAttachments();
  }

  Future<void> _loadAttachments() async {
    setState(() => _isLoading = true);
    
    final provider = Provider.of<EmployeeProvider>(context, listen: false);
    final attachments = await provider.getAttachments(widget.employeeId);
    
    setState(() {
      _attachments = attachments;
      _isLoading = false;
    });
  }

  Future<void> _uploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
        dialogTitle: 'Select file to upload',
        allowCompression: true,
      );
      
      if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
        File file = File(result.files.first.path!);
        
        if (await file.length() > 10 * 1024 * 1024) {
          _showError('File too large (max 10MB)');
          return;
        }
        
        setState(() => _isUploading = true);
        
        final provider = Provider.of<EmployeeProvider>(context, listen: false);
        await provider.uploadAttachment(widget.employeeId, file);
        
        await _loadAttachments();
        _showSuccess('File uploaded successfully');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteAttachment(int attachmentId, String fileName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "$fileName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final provider = Provider.of<EmployeeProvider>(context, listen: false);
      await provider.deleteAttachment(attachmentId);
      await _loadAttachments();
    }
  }

  Future<void> _downloadAttachment(int attachmentId, String fileName) async {
    print('📱 Starting download for attachment $attachmentId: $fileName');
    
    // تحديث حالة التنزيل للملف المحدد
    setState(() {
      _isDownloading = true;
      _downloadingAttachmentId = attachmentId;
    });
    
    try {
      final provider = Provider.of<EmployeeProvider>(context, listen: false);
      
      try {
        // استدعاء دالة التنزيل
        final downloadedFile = await provider.downloadAttachment(attachmentId);
        
        // التحقق من أن الملف تم تنزيله
        if (downloadedFile != null && await downloadedFile.exists()) {
          // فتح الملف
          await OpenFile.open(downloadedFile.path);
          _showSuccess('File downloaded: $fileName');
        } else {
          _showError('Failed to download file');
        }
      } catch (e) {
        print('🔥 Download error: $e');
        _showError('Download error: $e');
      }
    } catch (e) {
      print('🔥 Error in downloadAttachment: $e');
      _showError('Error: $e');
    } finally {
      // إعادة تعيين حالة التنزيل
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadingAttachmentId = null;
        });
      }
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildAttachmentItem(Map att) {
    final attachmentId = att['id'];
    final fileName = att['file_name'] ?? 'Unknown file';
    final fileType = getFileType(fileName);
    
    // التحقق إذا كان هذا الملف قيد التنزيل
    final isThisFileDownloading = _downloadingAttachmentId == attachmentId && _isDownloading;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: getFileIcon(fileName),
        title: Text(
          fileName,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fileType,
              style: const TextStyle(fontSize: 12),
            ),
            if (att['created_at'] != null)
              Text(
                'Uploaded: ${_formatDate(att['created_at'])}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isThisFileDownloading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.download, color: Colors.blue),
                onPressed: () => _downloadAttachment(attachmentId, fileName),
                tooltip: 'Download',
              ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteAttachment(attachmentId, fileName),
              tooltip: 'Delete',
            ),
          ],
        ),
        onTap: () => _downloadAttachment(attachmentId, fileName),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Attachments: ${widget.employeeName}'),
      content: SizedBox(
        width: 500,
        height: 400,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _attachments.isEmpty
                ? const Center(child: Text('No attachments found'))
                : ListView.builder(
                    itemCount: _attachments.length,
                    itemBuilder: (_, index) {
                      return _buildAttachmentItem(_attachments[index]);
                    },
                  ),
      ),
      actions: [
        if (_isDownloading)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Downloading...',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ElevatedButton(
          onPressed: _isUploading ? null : _uploadFile,
          child: _isUploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Upload New File'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}