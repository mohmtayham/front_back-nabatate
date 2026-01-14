import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:nabtatcompany/models/payment_reminder.dart';
import 'package:nabtatcompany/services/payment_reminder_service.dart';

class AddReminderScreen extends StatefulWidget {
  final PaymentReminder? reminder;

  const AddReminderScreen({super.key, this.reminder});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  late PaymentReminderService _service;
  
  // Form variables
  final TextEditingController _housingIdController = TextEditingController();
  final TextEditingController _buildingIdController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  // State variables
  DateTime? _selectedDate;
  String _selectedPaymentType = 'electricity';
  bool _paymentStatus = false;
  
  // File variables
  List<String> _selectedFiles = []; // New files
  List<String> _existingFiles = []; // Existing files
  List<String> _filesToDelete = []; // Files to delete
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _service = PaymentReminderService();
    
    // Initialize data if editing existing reminder
    if (widget.reminder != null) {
      _housingIdController.text = widget.reminder!.housingId.toString();
      if (widget.reminder!.buildingId != null) {
        _buildingIdController.text = widget.reminder!.buildingId.toString();
      }
      _selectedPaymentType = widget.reminder!.paymentType;
      _selectedDate = widget.reminder!.dueDate;
      _amountController.text = widget.reminder!.amount.toString();
      _paymentStatus = widget.reminder!.paymentStatus;
      _notesController.text = widget.reminder!.notes ?? '';
      
      // Save existing files
      if (widget.reminder!.attachments != null) {
        _existingFiles = List.from(widget.reminder!.attachments!);
      }
    }
  }

  // Select files from gallery
  Future<void> _pickImages() async {
    try {
      final List<XFile>? images = await _imagePicker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (images != null) {
        for (var image in images) {
          _selectedFiles.add(image.path);
        }
        setState(() {});
      }
    } catch (e) {
      _showErrorSnackBar('Error selecting images: $e');
    }
  }

  // Select files from files
  Future<void> _pickFiles() async {
    _pickImages();
  }

  // Remove specific file
  void _removeFile(int index, bool isExisting) {
    if (isExisting) {
      // If existing file, add to delete list
      final fileName = _existingFiles[index];
      _filesToDelete.add(fileName);
      _existingFiles.removeAt(index);
    } else {
      // If new file, remove from list
      _selectedFiles.removeAt(index);
    }
    setState(() {});
  }

  // Submit form
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      setState(() => _isLoading = true);
      
      try {
        final housingId = int.tryParse(_housingIdController.text);
        final amount = double.tryParse(_amountController.text);
        
        if (housingId == null) {
          throw Exception('Invalid housing ID');
        }
        
        if (amount == null) {
          throw Exception('Invalid amount');
        }
        
        final reminder = PaymentReminder(
          id: widget.reminder?.id,
          housingId: housingId,
          buildingId: _buildingIdController.text.isNotEmpty
              ? int.tryParse(_buildingIdController.text)
              : null,
          paymentType: _selectedPaymentType,
          dueDate: _selectedDate!,
          amount: amount,
          paymentStatus: _paymentStatus,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          attachments: _existingFiles,
        );

        print('📤 Preparing to submit reminder...');
        print('✅ payment_status will be sent as: $_paymentStatus');

        if (widget.reminder == null || widget.reminder!.id == null) {
          // Create new with files
          print('➕ Creating new reminder with files...');
          await _service.createReminder(
            reminder,
            filePaths: _selectedFiles,
          );
          _showSuccessSnackBar('Reminder created successfully');
        } else {
          // Update with files
          print('✏️ Updating existing reminder...');
          await _service.updateReminder(
            widget.reminder!.id!,
            reminder,
            newFilePaths: _selectedFiles,
            filesToDelete: _filesToDelete.isNotEmpty ? _filesToDelete : null,
          );
          _showSuccessSnackBar('Reminder updated successfully');
        }
        
        Navigator.pop(context, true);
      } on FormatException catch (e) {
        _showErrorSnackBar('Data conversion error: ${e.message}');
      } catch (e) {
        print('❌ Error in _submitForm: $e');
        _showErrorSnackBar('Error: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    } else if (_selectedDate == null) {
      _showErrorSnackBar('Please select due date');
    }
  }

  // Helper function for file icon
  Widget _getFileIcon(String filePath) {
    final fileName = path.basename(filePath);
    final ext = path.extension(fileName).toLowerCase();
    
    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp'].contains(ext)) {
      return const Icon(Icons.image, color: Colors.blue);
    } else if (['.pdf'].contains(ext)) {
      return const Icon(Icons.picture_as_pdf, color: Colors.red);
    } else if (['.doc', '.docx'].contains(ext)) {
      return const Icon(Icons.description, color: Colors.blue);
    } else if (['.xls', '.xlsx'].contains(ext)) {
      return const Icon(Icons.table_chart, color: Colors.green);
    } else {
      return const Icon(Icons.insert_drive_file);
    }
  }

  // Build files list
  Widget _buildFilesList() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attached Files',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You can upload images (JPG, PNG) or documents (PDF, DOC, XLS)',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            
            // Show existing files
            if (_existingFiles.isNotEmpty) ...[
              const Text(
                'Current files:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ..._existingFiles.asMap().entries.map((entry) {
                final index = entry.key;
                final fileName = entry.value;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: _getFileIcon(fileName),
                    title: Text(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () => _removeFile(index, true),
                      tooltip: 'Delete file',
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],
            
            // Show new files
            if (_selectedFiles.isNotEmpty) ...[
              const Text(
                'New files:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ..._selectedFiles.asMap().entries.map((entry) {
                final index = entry.key;
                final filePath = entry.value;
                final fileName = path.basename(filePath);
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: _getFileIcon(fileName),
                    title: Text(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () => _removeFile(index, false),
                      tooltip: 'Delete file',
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],
            
            // Add file buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.photo),
                    label: const Text('Upload images'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFiles,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Upload files'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            Text(
              'Number of files: ${_existingFiles.length + _selectedFiles.length} file(s)',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      locale: const Locale('en', 'US'),
    );
    
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // ✅ دالة لتحويل DateTime إلى نص مقروء
  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Not available';
    return '${dateTime.toLocal().year}-${dateTime.toLocal().month.toString().padLeft(2, '0')}-${dateTime.toLocal().day.toString().padLeft(2, '0')} ${dateTime.toLocal().hour.toString().padLeft(2, '0')}:${dateTime.toLocal().minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.reminder == null 
              ? 'Add New Payment Reminder' 
              : 'Edit Payment Reminder',
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      // housing_id - required
                      TextFormField(
                        controller: _housingIdController,
                        decoration: const InputDecoration(
                          labelText: 'Housing ID *',
                          hintText: 'Enter housing ID',
                          prefixIcon: Icon(Icons.home),
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'This field is required';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Enter a valid integer';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // building_id - optional
                      TextFormField(
                        controller: _buildingIdController,
                        decoration: const InputDecoration(
                          labelText: 'Building ID (optional)',
                          hintText: 'Enter building ID',
                          prefixIcon: Icon(Icons.apartment),
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // payment_type - required
                      DropdownButtonFormField<String>(
                        value: _selectedPaymentType,
                        decoration: const InputDecoration(
                          labelText: 'Payment Type *',
                          prefixIcon: Icon(Icons.payment),
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: ['electricity', 'water', 'other']
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedPaymentType = value!);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Payment type is required';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // due_date - required
                      InkWell(
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Due Date *',
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedDate != null
                                    ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
                                    : 'Select date',
                                style: TextStyle(
                                  color: _selectedDate != null ? Colors.black : Colors.grey,
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // amount - required
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Amount *',
                          hintText: 'Enter amount',
                          prefixIcon: Icon(Icons.attach_money),
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                          suffixText: 'SAR',
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'This field is required';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null) {
                            return 'Enter a valid number';
                          }
                          if (amount <= 0) {
                            return 'Amount must be greater than zero';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // payment_status - optional
                      Card(
                        elevation: 1,
                        child: SwitchListTile(
                          title: const Text('Payment Status'),
                          subtitle: Text(
                            _paymentStatus ? 'Paid' : 'Not Paid',
                            style: TextStyle(
                              color: _paymentStatus ? Colors.green : Colors.orange,
                            ),
                          ),
                          value: _paymentStatus,
                          onChanged: (value) {
                            setState(() => _paymentStatus = value);
                          },
                          secondary: Icon(
                            _paymentStatus ? Icons.check_circle : Icons.pending,
                            color: _paymentStatus ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                      
                      // ✅ عرض معلومات paid_at إذا كانت payment_status = true أثناء التعديل
                      if (widget.reminder != null && 
                          widget.reminder!.paymentStatus && 
                          widget.reminder!.paidAt != null) ...[
                        const SizedBox(height: 8),
                        Card(
                          elevation: 1,
                          color: Colors.green[50],
                          child: ListTile(
                            leading: const Icon(Icons.timer, color: Colors.green),
                            title: const Text(
                              'Payment Date',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            subtitle: Text(
                              'Paid on: ${_formatDateTime(widget.reminder!.paidAt)}',
                              style: const TextStyle(color: Colors.green),
                            ),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 16),
                      
                      // Attached files
                      _buildFilesList(),
                      
                      const SizedBox(height: 16),
                      
                      // notes - optional
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                          hintText: 'Enter any notes',
                          prefixIcon: Icon(Icons.note),
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        maxLines: 3,
                        textInputAction: TextInputAction.done,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _submitForm,
                              icon: Icon(
                                widget.reminder == null 
                                    ? Icons.add_circle 
                                    : Icons.save,
                              ),
                              label: Text(
                                widget.reminder == null 
                                    ? 'Create Reminder' 
                                    : 'Update Reminder',
                                style: const TextStyle(fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: widget.reminder == null 
                                    ? Colors.blue 
                                    : Colors.green,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : () => Navigator.pop(context),
                              icon: const Icon(Icons.cancel),
                              label: const Text('Cancel', style: TextStyle(fontSize: 16)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(color: Colors.grey),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // ✅ Additional info for editing - الكود المصحح
                      if (widget.reminder != null) ...[
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 10),
                        
                        // استخراج البيانات في متغيرات محلية لتجنب مشاكل null safety
                        Builder(
                          builder: (context) {
                            final reminder = widget.reminder!;
                            final isPaid = reminder.paymentStatus;
                            final paidAt = reminder.paidAt;
                            final createdAt = reminder.createdAt;
                            final updatedAt = reminder.updatedAt;
                            
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.info_outline, color: Colors.blue),
                                title: const Text('Reminder Details:'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (reminder.id != null)
                                      Text('Reminder ID: ${reminder.id}'),
                                    
                                    // حالة الدفع
                                    Text(
                                      'Payment Status: ${isPaid ? 'Paid' : 'Unpaid'}',
                                      style: TextStyle(
                                        color: isPaid ? Colors.green : Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    
                                    // تاريخ الدفع
                                    if (isPaid && paidAt != null)
                                      Text(
                                        'Payment Date: ${_formatDateTime(paidAt)}',
                                        style: const TextStyle(color: Colors.green),
                                      )
                                    else if (!isPaid)
                                      const Text(
                                        'Payment Date: Not paid yet',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    
                                    if (createdAt != null)
                                      Text(
                                        'Created: ${_formatDateTime(createdAt)}',
                                      ),
                                    
                                    if (updatedAt != null)
                                      Text(
                                        'Last Updated: ${_formatDateTime(updatedAt)}',
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 16, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Fields marked with (*) are required - Maximum file size: 5MB',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _housingIdController.dispose();
    _buildingIdController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}