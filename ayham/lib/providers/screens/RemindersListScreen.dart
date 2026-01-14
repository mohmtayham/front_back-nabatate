import 'package:flutter/material.dart';
import 'package:nabtatcompany/models/payment_reminder.dart';
import 'package:nabtatcompany/providers/screens/AddReminderScreen.dart';
import 'package:nabtatcompany/services/payment_reminder_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class RemindersListScreen extends StatefulWidget {
  const RemindersListScreen({super.key});

  @override
  State<RemindersListScreen> createState() => _RemindersListScreenState();
}

class _RemindersListScreenState extends State<RemindersListScreen> {
  // Variables
  late PaymentReminderService _service;
  List<PaymentReminder> _reminders = [];
  List<PaymentReminder> _filteredReminders = [];
  bool _isLoading = true;
  String _errorMessage = '';
  
  // Filters and search
  String _selectedFilter = 'All';
  String _selectedStatus = 'All';
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;
  
  // Sorting
  String _sortBy = 'Due Date';
  bool _ascending = true;

  @override
  void initState() {
    super.initState();
    _service = PaymentReminderService();
    _loadReminders();
    
    // Add listener for search
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Load reminders
  Future<void> _loadReminders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final reminders = await _service.getReminders();
      setState(() {
        _reminders = reminders;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading reminders: $e';
      });
    }
  }

  // Delete reminder
  Future<void> _deleteReminder(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this reminder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.deleteReminder(id);
        setState(() {
          _reminders.removeWhere((reminder) => reminder.id == id);
          _applyFilters();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reminder deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Mark as paid
  Future<void> _markAsPaid(PaymentReminder reminder) async {
    try {
      await _service.markAsPaid(reminder.id!);
      setState(() {
        final index = _reminders.indexWhere((r) => r.id == reminder.id);
        if (index != -1) {
          _reminders[index] = reminder.copyWith(
            paymentStatus: true,
            paidAt: DateTime.now(),
          );
        }
        _applyFilters();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marked as paid'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Mark as unpaid
  Future<void> _markAsUnpaid(PaymentReminder reminder) async {
    try {
      await _service.markAsUnpaid(reminder.id!);
      setState(() {
        final index = _reminders.indexWhere((r) => r.id == reminder.id);
        if (index != -1) {
          _reminders[index] = reminder.copyWith(
            paymentStatus: false,
            paidAt: null,
          );
        }
        _applyFilters();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marked as unpaid'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Apply filters
  void _applyFilters() {
    List<PaymentReminder> filtered = List.from(_reminders);

    // Filter by type
    if (_selectedFilter != 'All') {
      String type = '';
      switch (_selectedFilter) {
        case 'Electricity':
          type = 'electricity';
          break;
        case 'Water':
          type = 'water';
          break;
        case 'Other':
          type = 'other';
          break;
      }
      filtered = filtered.where((r) => r.paymentType == type).toList();
    }

    // Filter by status
    if (_selectedStatus != 'All') {
      switch (_selectedStatus) {
        case 'Paid':
          filtered = filtered.where((r) => r.paymentStatus).toList();
          break;
        case 'Unpaid':
          filtered = filtered.where((r) => !r.paymentStatus).toList();
          break;
      }
    }

    // Filter by date
    if (_selectedDate != null) {
      filtered = filtered.where((r) {
        return r.dueDate.year == _selectedDate!.year &&
               r.dueDate.month == _selectedDate!.month &&
               r.dueDate.day == _selectedDate!.day;
      }).toList();
    }

    // Filter by search
    final searchQuery = _searchController.text.trim();
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((reminder) {
        return reminder.paymentType.contains(searchQuery) ||
               (reminder.notes ?? '').toLowerCase().contains(searchQuery.toLowerCase()) ||
               reminder.housingId.toString().contains(searchQuery) ||
               (reminder.buildingId?.toString() ?? '').contains(searchQuery) ||
               reminder.amount.toString().contains(searchQuery);
      }).toList();
    }

    // Sorting
    filtered.sort((a, b) {
      int result = 0;
      switch (_sortBy) {
        case 'Due Date':
          result = a.dueDate.compareTo(b.dueDate);
          break;
        case 'Amount':
          result = a.amount.compareTo(b.amount);
          break;
        case 'Created Date':
          result = (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now());
          break;
      }
      return _ascending ? result : -result;
    });

    setState(() {
      _filteredReminders = filtered;
    });
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  // Select date
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('en', 'US'),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _applyFilters();
      });
    }
  }

  // Clear date filter
  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
      _applyFilters();
    });
  }

  // Statistics
  Map<String, dynamic> _calculateStatistics() {
    final total = _reminders.length;
    final paid = _reminders.where((r) => r.paymentStatus).length;
    final pending = total - paid;
    final totalAmount = _reminders.fold(0.0, (sum, r) => sum + r.amount);
    final paidAmount = _reminders.where((r) => r.paymentStatus).fold(0.0, (sum, r) => sum + r.amount);
    
    return {
      'total': total,
      'paid': paid,
      'pending': pending,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'unpaid_amount': totalAmount - paidAmount,
    };
  }

  // Navigate to add
  void _navigateToAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddReminderScreen(),
      ),
    );
    
    if (result == true) {
      await _loadReminders();
    }
  }

  // Navigate to edit
  void _navigateToEdit(PaymentReminder reminder) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddReminderScreen(reminder: reminder),
      ),
    );
    
    if (result == true) {
      await _loadReminders();
    }
  }

  // Download file
  Future<void> _downloadFile(String url, String fileName) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        throw Exception('Cannot open file');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Format date
  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStatistics();
    final format = NumberFormat.decimalPattern();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Reminders'),
        actions: [
          IconButton(
            onPressed: _loadReminders,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _applyFilters();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'Due Date',
                child: Text('Due Date'),
              ),
              const PopupMenuItem(
                value: 'Amount',
                child: Text('Amount'),
              ),
              const PopupMenuItem(
                value: 'Created Date',
                child: Text('Created Date'),
              ),
            ],
            child: const Icon(Icons.sort),
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Colors.blue[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard('Total', stats['total'].toString(), Colors.blue),
                _buildStatCard('Pending', stats['pending'].toString(), Colors.orange),
                _buildStatCard('Paid', stats['paid'].toString(), Colors.green),
                _buildStatCard('Total Amount', '${format.format(stats['total_amount'])}', Colors.purple),
              ],
            ),
          ),
          
          // Filters and search
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[50],
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search reminders...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // Filters row
                Row(
                  children: [
                    // Type filter
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedFilter,
                            isExpanded: true,
                            items: const [
                              'All',
                              'Electricity',
                              'Water',
                              'Other',
                            ].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedFilter = value!;
                                _applyFilters();
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 10),
                    
                    // Status filter
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStatus,
                            isExpanded: true,
                            items: const [
                              'All',
                              'Paid',
                              'Unpaid',
                            ].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedStatus = value!;
                                _applyFilters();
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 10),
                
                // Date filter
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectDate,
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          _selectedDate != null
                              ? _formatDate(_selectedDate!)
                              : 'Filter by Date',
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _selectedDate != null ? Colors.blue[50] : Colors.white,
                        ),
                      ),
                    ),
                    
                    if (_selectedDate != null) ...[
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: _clearDateFilter,
                        icon: const Icon(Icons.clear, color: Colors.red),
                        tooltip: 'Clear date filter',
                      ),
                    ],
                  ],
                ),
                
                // Sorting
                Row(
                  children: [
                    const Text('Sort by: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    Text(_sortBy),
                    IconButton(
                      icon: Icon(
                        _ascending ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() {
                          _ascending = !_ascending;
                          _applyFilters();
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Reminders list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error, color: Colors.red, size: 50),
                              const SizedBox(height: 20),
                              Text(
                                _errorMessage,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _loadReminders,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _filteredReminders.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.receipt_long, size: 80, color: Colors.grey),
                                const SizedBox(height: 20),
                                const Text(
                                  'No reminders found',
                                  style: TextStyle(fontSize: 18, color: Colors.grey),
                                ),
                                if (_selectedFilter != 'All' || 
                                    _selectedStatus != 'All' || 
                                    _selectedDate != null ||
                                    _searchController.text.isNotEmpty)
                                  ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      'There are ${_reminders.length} reminders in total',
                                      style: const TextStyle(color: Colors.blue),
                                    ),
                                    const SizedBox(height: 10),
                                    OutlinedButton(
                                      onPressed: () {
                                        setState(() {
                                          _selectedFilter = 'All';
                                          _selectedStatus = 'All';
                                          _selectedDate = null;
                                          _searchController.clear();
                                          _applyFilters();
                                        });
                                      },
                                      child: const Text('Show All'),
                                    ),
                                  ],
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredReminders.length,
                            itemBuilder: (context, index) {
                              final reminder = _filteredReminders[index];
                              return _buildReminderCard(reminder);
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAdd,
        backgroundColor: Colors.pink,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Reminder', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildReminderCard(PaymentReminder reminder) {
    final isOverdue = reminder.dueDate.isBefore(DateTime.now()) && !reminder.paymentStatus;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: InkWell(
        onTap: () => _showReminderDetails(reminder),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Payment status
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: reminder.paymentStatus 
                      ? Colors.green[100] 
                      : isOverdue 
                          ? Colors.red[100] 
                          : Colors.orange[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  reminder.paymentStatus 
                      ? Icons.check_circle 
                      : isOverdue 
                          ? Icons.warning 
                          : Icons.schedule,
                  color: reminder.paymentStatus 
                      ? Colors.green 
                      : isOverdue 
                          ? Colors.red 
                          : Colors.orange,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _getPaymentTypeName(reminder.paymentType),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: reminder.paymentStatus 
                                  ? Colors.green[700] 
                                  : Colors.black,
                            ),
                          ),
                        ),
                        Text(
                          '${reminder.amount.toStringAsFixed(2)} ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Row(
                      children: [
                        const Icon(Icons.home, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Housing: ${reminder.housingId}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        
                        if (reminder.buildingId != null) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.apartment, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Building: ${reminder.buildingId}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Due: ${_formatDate(reminder.dueDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isOverdue ? Colors.red : Colors.grey,
                          ),
                        ),
                        
                        if (reminder.paymentStatus && reminder.paidAt != null) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.payment, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Paid: ${_formatDate(reminder.paidAt!)}',
                            style: const TextStyle(fontSize: 12, color: Colors.green),
                          ),
                        ],
                      ],
                    ),
                    
                    if (reminder.attachments != null && reminder.attachments!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.attach_file, size: 14, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            '${reminder.attachments!.length} file(s)',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              
              // Action buttons
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue, size: 22),
                    onPressed: () => _navigateToEdit(reminder),
                  ),
                  if (!reminder.paymentStatus)
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green, size: 22),
                      onPressed: () => _markAsPaid(reminder),
                      tooltip: 'Mark as paid',
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.orange, size: 22),
                      onPressed: () => _markAsUnpaid(reminder),
                      tooltip: 'Mark as unpaid',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPaymentTypeName(String type) {
    switch (type) {
      case 'electricity':
        return 'Electricity';
      case 'water':
        return 'Water';
      case 'other':
        return 'Other';
      default:
        return type;
    }
  }

  void _showReminderDetails(PaymentReminder reminder) {
    final isOverdue = reminder.dueDate.isBefore(DateTime.now()) && !reminder.paymentStatus;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Title and status
            Row(
              children: [
                Expanded(
                  child: Text(
                    _getPaymentTypeName(reminder.paymentType),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    reminder.paymentStatus ? 'Paid' : 
                    isOverdue ? 'Overdue' : 'Pending',
                    style: TextStyle(
                      color: reminder.paymentStatus 
                          ? Colors.white 
                          : isOverdue 
                              ? Colors.white 
                              : Colors.black,
                    ),
                  ),
                  backgroundColor: reminder.paymentStatus 
                      ? Colors.green 
                      : isOverdue 
                          ? Colors.red 
                          : Colors.orange[200],
                ),
              ],
            ),
            
            const Divider(height: 30),
            
            // Details
            _buildDetailRow('Housing ID', reminder.housingId.toString()),
            
            if (reminder.buildingId != null)
              _buildDetailRow('Building ID', reminder.buildingId.toString()),
            
            _buildDetailRow('Payment Type', _getPaymentTypeName(reminder.paymentType)),
            
            _buildDetailRow(
              'Due Date', 
              _formatDate(reminder.dueDate),
              isImportant: isOverdue,
            ),
            
            if (isOverdue)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  '⚠️ This reminder is overdue',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            
            _buildDetailRow('Amount', '${reminder.amount.toStringAsFixed(2)} '),
            
            if (reminder.paymentStatus && reminder.paidAt != null)
              _buildDetailRow(
                'Payment Date', 
                _formatDate(reminder.paidAt!),
                isImportant: true,
              ),
            
            if (reminder.notes != null && reminder.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Notes:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(reminder.notes!),
              ),
            ],
            
            // Show attached files
            if (reminder.attachments != null && reminder.attachments!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Attached Files:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 150,
                child: ListView.builder(
                  itemCount: reminder.attachments!.length,
                  itemBuilder: (context, index) {
                    final fileName = reminder.attachments![index];
                    final url = reminder.attachmentUrls != null && 
                                reminder.attachmentUrls!.length > index
                        ? reminder.attachmentUrls![index]
                        : 'http://127.0.0.1:8000/storage/attachments/$fileName';
                    
                    return ListTile(
                      leading: const Icon(Icons.attach_file, color: Colors.blue),
                      title: Text(
                        fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.download, color: Colors.green),
                        onPressed: () => _downloadFile(url, fileName),
                      ),
                    );
                  },
                ),
              ),
            ],
            
            // Additional info
            if (reminder.createdAt != null || reminder.updatedAt != null) ...[
              const SizedBox(height: 16),
              const Text(
                'System Information:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (reminder.createdAt != null)
                _buildDetailRow('Created At', _formatDate(reminder.createdAt!)),
              if (reminder.updatedAt != null)
                _buildDetailRow('Last Updated', _formatDate(reminder.updatedAt!)),
            ],
            
            const SizedBox(height: 30),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToEdit(reminder);
                    },
                    icon: const Icon(Icons.edit, size: 20),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      if (!reminder.paymentStatus) {
                        _markAsPaid(reminder);
                      } else {
                        _markAsUnpaid(reminder);
                      }
                    },
                    icon: Icon(
                      !reminder.paymentStatus ? Icons.check : Icons.close,
                      size: 20,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !reminder.paymentStatus ? Colors.green : Colors.orange,
                    ),
                    label: Text(!reminder.paymentStatus ? 'Pay' : 'Unpay'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteReminder(reminder.id!);
                    },
                    icon: const Icon(Icons.delete, size: 20),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    label: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value, {bool isImportant = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$title:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: isImportant ? Colors.blue : Colors.black,
                fontWeight: isImportant ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}