import 'package:flutter/material.dart';
import 'package:nabtatcompany/models/meter.dart';
import 'package:nabtatcompany/providers/meter_provider.dart';
import 'package:provider/provider.dart';

class AddEditMeterScreen extends StatefulWidget {
  final dynamic meter; // غيرت من Meter? إلى dynamic

  const AddEditMeterScreen({Key? key, this.meter}) : super(key: key);

  @override
  _AddEditMeterScreenState createState() => _AddEditMeterScreenState();
}

class _AddEditMeterScreenState extends State<AddEditMeterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _serialController = TextEditingController();
  final TextEditingController _housingIdController = TextEditingController();
  final TextEditingController _buildingIdController = TextEditingController();
  final TextEditingController _billNumberController = TextEditingController();
  final TextEditingController _billAmountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  String _selectedStatus = 'مسدد';
  bool _isLoading = false;

  final List<String> _paymentStatuses = ['مسدد', 'غير مسدد', 'مستحق'];

  @override
  void initState() {
    super.initState();
    if (widget.meter != null) {
      // تحقق من نوع البيانات
      if (widget.meter is Map<String, dynamic>) {
        // إذا كانت بيانات من API
        final Map<String, dynamic> data = widget.meter;
        _nameController.text = data['name'] ?? '';
        _serialController.text = data['serial_number'] ?? '';
        _housingIdController.text = (data['housing_id'] ?? '').toString();
        _buildingIdController.text = (data['building_id'] ?? '').toString();
        _billNumberController.text = data['bill_number'] ?? '';
        _billAmountController.text = (data['bill_amount'] ?? '').toString();
        _notesController.text = data['notes'] ?? '';
        _selectedStatus = data['payment_status'] ?? 'مسدد';
      } else {
        // إذا كانت كائن Meter
        _nameController.text = widget.meter.name;
        _serialController.text = widget.meter.serialNumber;
        _housingIdController.text = widget.meter.housingId.toString();
        _buildingIdController.text = widget.meter.buildingId?.toString() ?? '';
        _billNumberController.text = widget.meter.billNumber ?? '';
        _billAmountController.text = widget.meter.billAmount?.toString() ?? '';
        _notesController.text = widget.meter.notes ?? '';
        _selectedStatus = widget.meter.paymentStatus;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.meter == null ? 'إضافة عداد جديد' : 'تعديل العداد'),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم العداد *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال اسم العداد';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _serialController,
                      decoration: const InputDecoration(
                        labelText: 'الرقم التسلسلي *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال الرقم التسلسلي';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _housingIdController,
                      decoration: const InputDecoration(
                        labelText: 'رقم الوحدة السكنية *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال رقم الوحدة السكنية';
                        }
                        if (int.tryParse(value) == null) {
                          return 'الرجاء إدخال رقم صحيح';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _buildingIdController,
                      decoration: const InputDecoration(
                        labelText: 'رقم المبنى (اختياري)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _billNumberController,
                      decoration: const InputDecoration(
                        labelText: 'رقم الفاتورة (اختياري)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _billAmountController,
                      decoration: const InputDecoration(
                        labelText: 'مبلغ الفاتورة (اختياري)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'حالة الدفع *',
                        border: OutlineInputBorder(),
                      ),
                      items: _paymentStatuses.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedStatus = value;
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء اختيار حالة الدفع';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات (اختياري)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(widget.meter == null ? 'إضافة' : 'تحديث'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<MeterProvider>(context, listen: false);
      
      // تحويل البيانات إلى Map
      final meterData = {
        'name': _nameController.text,
        'serial_number': _serialController.text,
        'housing_id': int.parse(_housingIdController.text),
        'building_id': _buildingIdController.text.isNotEmpty
            ? int.parse(_buildingIdController.text)
            : null,
        'bill_number': _billNumberController.text.isNotEmpty
            ? _billNumberController.text
            : null,
        'bill_amount': _billAmountController.text.isNotEmpty
            ? double.parse(_billAmountController.text)
            : null,
        'payment_status': _selectedStatus,
        'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
      };

      if (widget.meter == null) {
        // إضافة جديد
        await provider.addMeter(Meter.fromJson({
          ...meterData,
          'id': 0,
          'payment_status': _selectedStatus,
        }));
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة العداد بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // تحديث
        final id = widget.meter is Map<String, dynamic> 
            ? widget.meter['id'] ?? 0 
            : widget.meter.id;
            
        await provider.updateMeter(id, Meter.fromJson({
          ...meterData,
          'id': id,
          'payment_status': _selectedStatus,
        }));
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث العداد بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serialController.dispose();
    _housingIdController.dispose();
    _buildingIdController.dispose();
    _billNumberController.dispose();
    _billAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}