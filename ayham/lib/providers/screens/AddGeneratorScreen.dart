import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:nabtatcompany/models/generator.dart';
import 'package:nabtatcompany/services/generator_service.dart';

class AddGeneratorScreen extends StatefulWidget {
  final Generator? generator;

  const AddGeneratorScreen({super.key, this.generator});

  @override
  State<AddGeneratorScreen> createState() => _AddGeneratorScreenState();
}

class _AddGeneratorScreenState extends State<AddGeneratorScreen> {
  final _formKey = GlobalKey<FormState>();
  late GeneratorService _service;
  
  final TextEditingController _supplierNameController = TextEditingController();
  final TextEditingController _generatorNameController = TextEditingController();
  final TextEditingController _powerCapacityController = TextEditingController();
  final TextEditingController _monthlyRentController = TextEditingController();
  final TextEditingController _yearlyTotalController = TextEditingController();
  final TextEditingController _dieselConsumptionController = TextEditingController();
  final TextEditingController _monthlyDieselCostController = TextEditingController();
  final TextEditingController _buildingIdController = TextEditingController();
  final TextEditingController _housingIdController = TextEditingController();
  final TextEditingController _maintenanceIntervalController = TextEditingController();
  final TextEditingController _operatingHoursController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  String _selectedStatus = 'Working';
  DateTime? _installationDate;
  DateTime? _nextMaintenanceDate;
  
  List<String> _selectedFiles = [];
  List<String> _existingFiles = [];
  List<String> _filesToDelete = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _service = GeneratorService();
    
    if (widget.generator != null) {
      final generator = widget.generator!;
      _supplierNameController.text = generator.supplierName;
      _generatorNameController.text = generator.generatorName;
      _powerCapacityController.text = generator.powerCapacity;
      _monthlyRentController.text = generator.monthlyRent.toString();
      _yearlyTotalController.text = generator.yearlyTotal?.toString() ?? '';
      _selectedStatus = generator.status;
      _dieselConsumptionController.text = generator.dieselConsumptionLitersPerHour?.toString() ?? '';
      _monthlyDieselCostController.text = generator.monthlyDieselCost?.toString() ?? '';
      _buildingIdController.text = generator.buildingId?.toString() ?? '';
      _housingIdController.text = generator.housingId?.toString() ?? '';
      _installationDate = generator.installationDate;
      _nextMaintenanceDate = generator.nextMaintenanceDate;
      _maintenanceIntervalController.text = generator.maintenanceIntervalDays?.toString() ?? '90';
      _operatingHoursController.text = generator.operatingHours.toString();
      _notesController.text = generator.notes ?? '';
      
      if (generator.attachments != null) {
        _existingFiles = List.from(generator.attachments!);
      }
    }
  }

  Future<void> _pickFiles() async {
    try {
      final List<XFile>? files = await _imagePicker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (files != null) {
        for (var file in files) {
          _selectedFiles.add(file.path);
        }
        setState(() {});
      }
    } catch (e) {
      _showErrorSnackBar('Error selecting files: $e');
    }
  }

  void _removeFile(int index, bool isExisting) {
    if (isExisting) {
      final fileName = _existingFiles[index];
      _filesToDelete.add(fileName);
      _existingFiles.removeAt(index);
    } else {
      _selectedFiles.removeAt(index);
    }
    setState(() {});
  }

  Future<void> _selectDate(BuildContext context, bool isInstallation) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isInstallation ? 
          (_installationDate ?? DateTime.now()) : 
          (_nextMaintenanceDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('en', 'US'),
    );
    
    if (picked != null) {
      setState(() {
        if (isInstallation) {
          _installationDate = picked;
        } else {
          _nextMaintenanceDate = picked;
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final monthlyRent = double.tryParse(_monthlyRentController.text);
        final yearlyTotal = _yearlyTotalController.text.isNotEmpty ? 
            double.tryParse(_yearlyTotalController.text) : null;
        final dieselConsumption = _dieselConsumptionController.text.isNotEmpty ? 
            int.tryParse(_dieselConsumptionController.text) : null;
        final monthlyDieselCost = _monthlyDieselCostController.text.isNotEmpty ? 
            double.tryParse(_monthlyDieselCostController.text) : null;
        
        // ⭐⭐⭐ FIX: التحويل الصحيح للمباني والسكن ⭐⭐⭐
        final int? buildingId = _buildingIdController.text.isNotEmpty 
            ? int.tryParse(_buildingIdController.text)
            : null;
        
        final int? housingId = _housingIdController.text.isNotEmpty 
            ? int.tryParse(_housingIdController.text)
            : null;
        
        final maintenanceInterval = _maintenanceIntervalController.text.isNotEmpty ? 
            int.tryParse(_maintenanceIntervalController.text) : null;
        final operatingHours = int.tryParse(_operatingHoursController.text) ?? 0;
        
        if (monthlyRent == null) {
          throw Exception('Invalid monthly rent');
        }
        
        final generator = Generator(
          id: widget.generator?.id,
          supplierName: _supplierNameController.text,
          generatorName: _generatorNameController.text,
          powerCapacity: _powerCapacityController.text,
          monthlyRent: monthlyRent,
          yearlyTotal: yearlyTotal,
          status: _selectedStatus,
          dieselConsumptionLitersPerHour: dieselConsumption,
          monthlyDieselCost: monthlyDieselCost,
          buildingId: buildingId,  // ✅ الآن int? صحيح
          housingId: housingId,    // ✅ الآن int? صحيح
          installationDate: _installationDate,
          nextMaintenanceDate: _nextMaintenanceDate,
          maintenanceIntervalDays: maintenanceInterval,
          operatingHours: operatingHours,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          attachments: _existingFiles,
        );

        print('📤 Submitting generator with:');
        print('   buildingId: ${generator.buildingId} (type: ${generator.buildingId.runtimeType})');
        print('   housingId: ${generator.housingId} (type: ${generator.housingId.runtimeType})');

        if (widget.generator == null || widget.generator!.id == null) {
          await _service.createGenerator(
            generator,
            filePaths: _selectedFiles,
          );
          _showSuccessSnackBar('Generator created successfully');
        } else {
          await _service.updateGenerator(
            widget.generator!.id!,
            generator,
            newFilePaths: _selectedFiles,
            filesToDelete: _filesToDelete.isNotEmpty ? _filesToDelete : null,
          );
          _showSuccessSnackBar('Generator updated successfully');
        }
        
        Navigator.pop(context, true);
      } catch (e) {
        print('❌ Error in _submitForm: $e');
        _showErrorSnackBar('Error: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.generator == null 
              ? 'Add New Generator' 
              : 'Edit Generator',
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Supplier Name
                    TextFormField(
                      controller: _supplierNameController,
                      decoration: const InputDecoration(
                        labelText: 'Supplier Name *',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Supplier name is required';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Generator Name
                    TextFormField(
                      controller: _generatorNameController,
                      decoration: const InputDecoration(
                        labelText: 'Generator Name *',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Generator name is required';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Power Capacity
                    TextFormField(
                      controller: _powerCapacityController,
                      decoration: const InputDecoration(
                        labelText: 'Power Capacity * (e.g., 100KVA)',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Power capacity is required';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Monthly Rent
                    TextFormField(
                      controller: _monthlyRentController,
                      decoration: const InputDecoration(
                        labelText: 'Monthly Rent *',
                        prefixText: '\$',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        suffixText: 'SAR',
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Monthly rent is required';
                        }
                        final rent = double.tryParse(value);
                        if (rent == null || rent <= 0) {
                          return 'Enter a valid amount';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Status
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status *',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Working',
                          child: Text('Working'),
                        ),
                        DropdownMenuItem(
                          value: 'Broken',
                          child: Text('Broken'),
                        ),
                        DropdownMenuItem(
                          value: 'Under Maintenance',
                          child: Text('Under Maintenance'),
                        ),
                        DropdownMenuItem(
                          value: 'Stopped',
                          child: Text('Stopped'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedStatus = value!);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Status is required';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Dates Row
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, true),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Installation Date',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _installationDate != null
                                        ? '${_installationDate!.year}-${_installationDate!.month.toString().padLeft(2, '0')}-${_installationDate!.day.toString().padLeft(2, '0')}'
                                        : 'Select date',
                                    style: TextStyle(
                                      color: _installationDate != null ? Colors.black : Colors.grey,
                                    ),
                                  ),
                                  const Icon(Icons.calendar_today, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, false),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Next Maintenance',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _nextMaintenanceDate != null
                                        ? '${_nextMaintenanceDate!.year}-${_nextMaintenanceDate!.month.toString().padLeft(2, '0')}-${_nextMaintenanceDate!.day.toString().padLeft(2, '0')}'
                                        : 'Select date',
                                    style: TextStyle(
                                      color: _nextMaintenanceDate != null ? Colors.black : Colors.grey,
                                    ),
                                  ),
                                  const Icon(Icons.calendar_today, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Diesel Consumption and Cost
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _dieselConsumptionController,
                            decoration: const InputDecoration(
                              labelText: 'Diesel (L/hr)',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _monthlyDieselCostController,
                            decoration: const InputDecoration(
                              labelText: 'Monthly Diesel Cost',
                              prefixText: '\$',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Building and Housing IDs
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _buildingIdController,
                            decoration: const InputDecoration(
                              labelText: 'Building ID (Optional)',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'Leave empty if not assigned',
                            ),
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _housingIdController,
                            decoration: const InputDecoration(
                              labelText: 'Housing ID (Optional)',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'Leave empty if not assigned',
                            ),
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Maintenance Interval and Operating Hours
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _maintenanceIntervalController,
                            decoration: const InputDecoration(
                              labelText: 'Maintenance Interval (days)',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'Default: 90',
                            ),
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _operatingHoursController,
                            decoration: const InputDecoration(
                              labelText: 'Operating Hours',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'Default: 0',
                            ),
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Files section
                    Card(
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
                                    onPressed: _pickFiles,
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
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
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
                              widget.generator == null 
                                  ? Icons.add_circle 
                                  : Icons.save,
                            ),
                            label: Text(
                              widget.generator == null 
                                  ? 'Create Generator' 
                                  : 'Update Generator',
                              style: const TextStyle(fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: widget.generator == null 
                                  ? Colors.blue 
                                  : Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
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
                  ],
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
                widget.generator == null 
                    ? 'Fields marked with (*) are required - Maximum file size: 5MB'
                    : 'Maximum file size: 5MB',
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

  Widget _getFileIcon(String fileName) {
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

  @override
  void dispose() {
    _supplierNameController.dispose();
    _generatorNameController.dispose();
    _powerCapacityController.dispose();
    _monthlyRentController.dispose();
    _yearlyTotalController.dispose();
    _dieselConsumptionController.dispose();
    _monthlyDieselCostController.dispose();
    _buildingIdController.dispose();
    _housingIdController.dispose();
    _maintenanceIntervalController.dispose();
    _operatingHoursController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}