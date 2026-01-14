import 'package:flutter/material.dart';
import 'package:nabtatcompany/models/generator.dart';
import 'package:nabtatcompany/providers/screens/AddGeneratorScreen.dart';
import 'package:nabtatcompany/services/generator_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class GeneratorsListScreen extends StatefulWidget {
  const GeneratorsListScreen({super.key});

  @override
  State<GeneratorsListScreen> createState() => _GeneratorsListScreenState();
}

class _GeneratorsListScreenState extends State<GeneratorsListScreen> {
  late GeneratorService _service;
  List<Generator> _generators = [];
  List<Generator> _filteredGenerators = [];
  bool _isLoading = true;
  String _errorMessage = '';
  
  String _selectedFilter = 'All';
  String _selectedStatus = 'All';
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _service = GeneratorService();
    _loadGenerators();
  }

  Future<void> _loadGenerators() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final generators = await _service.getGenerators();
      setState(() {
        _generators = generators;
        _filteredGenerators = generators;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading generators: $e';
      });
    }
  }

  Future<void> _deleteGenerator(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this generator?'),
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
        await _service.deleteGenerator(id);
        setState(() {
          _generators.removeWhere((generator) => generator.id == id);
          _filteredGenerators.removeWhere((generator) => generator.id == id);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Generator deleted successfully'),
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

  Future<void> _markForMaintenance(int id) async {
    try {
      await _service.markForMaintenance(id);
      await _loadGenerators();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generator marked for maintenance'),
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

  Future<void> _completeMaintenance(int id) async {
    try {
      await _service.completeMaintenance(id);
      await _loadGenerators();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maintenance completed'),
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

  void _applyFilters() {
    List<Generator> filtered = List.from(_generators);

    // فلترة حسب حالة الجينر
    if (_selectedFilter != 'All') {
      switch (_selectedFilter) {
        case 'Working':
          filtered = filtered.where((g) => g.status == 'Working').toList();
          break;
        case 'Broken':
          filtered = filtered.where((g) => g.status == 'Broken').toList();
          break;
        case 'Under Maintenance':
          filtered = filtered.where((g) => g.status == 'Under Maintenance').toList();
          break;
        case 'Stopped':
          filtered = filtered.where((g) => g.status == 'Stopped').toList();
          break;
      }
    }

    // فلترة حسب حالة الصيانة
    if (_selectedStatus != 'All') {
      switch (_selectedStatus) {
        case 'Needs Maintenance':
          filtered = filtered.where((g) => 
              g.nextMaintenanceDate != null && 
              g.nextMaintenanceDate!.isBefore(DateTime.now())).toList();
          break;
        case 'Active':
          filtered = filtered.where((g) => 
              g.status == 'Working' || g.status == 'Under Maintenance').toList();
          break;
        case 'With Building':
          filtered = filtered.where((g) => g.buildingId != null).toList();
          break;
        case 'With Housing':
          filtered = filtered.where((g) => g.housingId != null).toList();
          break;
        case 'No Building/Housing':
          filtered = filtered.where((g) => g.buildingId == null && g.housingId == null).toList();
          break;
      }
    }

    // فلترة حسب البحث
    final searchQuery = _searchController.text.trim();
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((generator) {
        return generator.generatorName.toLowerCase().contains(searchQuery.toLowerCase()) ||
               generator.supplierName.toLowerCase().contains(searchQuery.toLowerCase()) ||
               generator.powerCapacity.toLowerCase().contains(searchQuery.toLowerCase()) ||
               (generator.notes ?? '').toLowerCase().contains(searchQuery.toLowerCase()) ||
               (generator.buildingId?.toString() ?? '').contains(searchQuery) ||
               (generator.housingId?.toString() ?? '').contains(searchQuery);
      }).toList();
    }

    setState(() {
      _filteredGenerators = filtered;
    });
  }

  Map<String, dynamic> _calculateStatistics() {
    final total = _generators.length;
    final working = _generators.where((g) => g.status == 'Working').length;
    final broken = _generators.where((g) => g.status == 'Broken').length;
    final underMaintenance = _generators.where((g) => g.status == 'Under Maintenance').length;
    final totalMonthlyCost = _generators.fold(0.0, (sum, g) => sum + (g.totalMonthlyCost ?? g.monthlyRent));
    final needsMaintenance = _generators.where((g) => 
        g.nextMaintenanceDate != null && g.nextMaintenanceDate!.isBefore(DateTime.now())).length;
    
    return {
      'total': total,
      'working': working,
      'broken': broken,
      'under_maintenance': underMaintenance,
      'needs_maintenance': needsMaintenance,
      'total_monthly_cost': totalMonthlyCost,
    };
  }

  void _navigateToAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddGeneratorScreen(),
      ),
    );
    
    if (result == true) {
      await _loadGenerators();
    }
  }

  void _navigateToEdit(Generator generator) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddGeneratorScreen(generator: generator),
      ),
    );
    
    if (result == true) {
      await _loadGenerators();
    }
  }

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

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Working':
        return Colors.green;
      case 'Broken':
        return Colors.red;
      case 'Under Maintenance':
        return Colors.orange;
      case 'Stopped':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Working':
        return Icons.power;
      case 'Broken':
        return Icons.error;
      case 'Under Maintenance':
        return Icons.build;
      case 'Stopped':
        return Icons.power_off;
      default:
        return Icons.question_mark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStatistics();
    final format = NumberFormat.decimalPattern();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generators'),
        actions: [
          IconButton(
            onPressed: _loadGenerators,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
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
                _buildStatCard('Working', stats['working'].toString(), Colors.green),
                _buildStatCard('Needs Maint.', stats['needs_maintenance'].toString(), Colors.orange),
                _buildStatCard('Monthly Cost', '\$${format.format(stats['total_monthly_cost'])}', Colors.purple),
              ],
            ),
          ),
          
          // Filters
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[50],
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search generators...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) => _applyFilters(),
                ),
                
                const SizedBox(height: 10),
                
                Row(
                  children: [
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
                              'Working',
                              'Broken',
                              'Under Maintenance',
                              'Stopped',
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
                              'Needs Maintenance',
                              'Active',
                              'With Building',
                              'With Housing',
                              'No Building/Housing',
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
              ],
            ),
          ),
          
          // Generators list
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
                                onPressed: _loadGenerators,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _filteredGenerators.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.electrical_services, size: 80, color: Colors.grey),
                                const SizedBox(height: 20),
                                const Text(
                                  'No generators found',
                                  style: TextStyle(fontSize: 18, color: Colors.grey),
                                ),
                                if (_generators.isNotEmpty)
                                  ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      '${_generators.length} generators hidden by filters',
                                      style: const TextStyle(color: Colors.blue),
                                    ),
                                    const SizedBox(height: 10),
                                    OutlinedButton(
                                      onPressed: () {
                                        setState(() {
                                          _selectedFilter = 'All';
                                          _selectedStatus = 'All';
                                          _searchController.clear();
                                          _applyFilters();
                                        });
                                      },
                                      child: const Text('Show All'),
                                    ),
                                  ]
                                else
                                  const SizedBox(height: 10),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredGenerators.length,
                            itemBuilder: (context, index) {
                              final generator = _filteredGenerators[index];
                              return _buildGeneratorCard(generator);
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAdd,
        backgroundColor: Colors.pink,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Generator', style: TextStyle(color: Colors.white)),
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

  Widget _buildGeneratorCard(Generator generator) {
    final needsMaintenance = generator.nextMaintenanceDate != null && 
        generator.nextMaintenanceDate!.isBefore(DateTime.now());
    final hasBuilding = generator.buildingId != null;
    final hasHousing = generator.housingId != null;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: InkWell(
        onTap: () => _showGeneratorDetails(generator),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // حالة الجينر
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getStatusColor(generator.status).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getStatusIcon(generator.status),
                  color: _getStatusColor(generator.status),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // التفاصيل
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            generator.generatorName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: needsMaintenance ? Colors.red : Colors.black,
                            ),
                          ),
                        ),
                        Text(
                          '\$${generator.monthlyRent.toStringAsFixed(2)}',
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
                        const Icon(Icons.business, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Supplier: ${generator.supplierName}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Row(
                      children: [
                        const Icon(Icons.flash_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          generator.powerCapacity,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        
                        if (hasBuilding) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.apartment, size: 14, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            'Building #${generator.buildingId}',
                            style: const TextStyle(fontSize: 12, color: Colors.blue),
                          ),
                        ],
                        
                        if (hasHousing) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.home, size: 14, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            'Housing #${generator.housingId}',
                            style: const TextStyle(fontSize: 12, color: Colors.green),
                          ),
                        ],
                      ],
                    ),
                    
                    if (needsMaintenance)
                      Row(
                        children: [
                          const Icon(Icons.warning, size: 14, color: Colors.red),
                          const SizedBox(width: 4),
                          Text(
                            'Maintenance overdue!',
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              
              // الأزرار
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue, size: 22),
                    onPressed: () => _navigateToEdit(generator),
                    tooltip: 'Edit',
                  ),
                  if (generator.status == 'Working' || generator.status == 'Stopped')
                    IconButton(
                      icon: const Icon(Icons.build, color: Colors.orange, size: 22),
                      onPressed: () => _markForMaintenance(generator.id!),
                      tooltip: 'Mark for Maintenance',
                    ),
                  if (generator.status == 'Under Maintenance')
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green, size: 22),
                      onPressed: () => _completeMaintenance(generator.id!),
                      tooltip: 'Complete Maintenance',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGeneratorDetails(Generator generator) {
    final needsMaintenance = generator.nextMaintenanceDate != null && 
        generator.nextMaintenanceDate!.isBefore(DateTime.now());
    final hasBuilding = generator.buildingId != null;
    final hasHousing = generator.housingId != null;
    
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
            
            // العنوان والحالة
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _getStatusColor(generator.status).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStatusIcon(generator.status),
                    color: _getStatusColor(generator.status),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        generator.generatorName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        generator.supplierName,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    generator.status,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: _getStatusColor(generator.status),
                ),
              ],
            ),
            
            const Divider(height: 30),
            
            // التفاصيل الأساسية
            _buildDetailRow('Power Capacity', generator.powerCapacity),
            _buildDetailRow('Monthly Rent', '\$${generator.monthlyRent.toStringAsFixed(2)}'),
            _buildDetailRow('Yearly Total', '\$${generator.yearlyTotal?.toStringAsFixed(2) ?? "N/A"}'),
            
            if (generator.dieselConsumptionLitersPerHour != null)
              _buildDetailRow('Diesel Consumption', '${generator.dieselConsumptionLitersPerHour} L/hr'),
            
            if (generator.monthlyDieselCost != null)
              _buildDetailRow('Monthly Diesel Cost', '\$${generator.monthlyDieselCost!.toStringAsFixed(2)}'),
            
            if (generator.totalMonthlyCost != null)
              _buildDetailRow(
                'Total Monthly Cost', 
                '\$${generator.totalMonthlyCost!.toStringAsFixed(2)}',
                isImportant: true,
              ),
            
            // معلومات الموقع
            if (hasBuilding || hasHousing) ...[
              const SizedBox(height: 16),
              const Text(
                'Location Information:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
            ],
            
            if (hasBuilding)
              _buildDetailRow(
                'Building', 
                generator.building?['name'] != null 
                    ? '${generator.building!['name']} (#${generator.buildingId})' 
                    : 'Building #${generator.buildingId}',
              ),
            
            if (hasHousing)
              _buildDetailRow(
                'Housing', 
                generator.housing?['name'] != null 
                    ? '${generator.housing!['name']} (#${generator.housingId})' 
                    : 'Housing #${generator.housingId}',
              ),
            
            // معلومات الصيانة
            const SizedBox(height: 16),
            const Text(
              'Maintenance Information:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            
            if (generator.installationDate != null)
              _buildDetailRow('Installation Date', _formatDate(generator.installationDate!)),
            
            if (generator.nextMaintenanceDate != null)
              _buildDetailRow(
                'Next Maintenance', 
                _formatDate(generator.nextMaintenanceDate!),
                isImportant: needsMaintenance,
              ),
            
            if (needsMaintenance)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: const Text(
                  '⚠️ Maintenance overdue! This generator needs immediate attention.',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            
            if (generator.maintenanceIntervalDays != null)
              _buildDetailRow('Maintenance Interval', '${generator.maintenanceIntervalDays} days'),
            
            if (generator.operatingHours > 0)
              _buildDetailRow('Operating Hours', '${generator.operatingHours} hours'),
            
            // الملفات المرفقة
            if (generator.attachments != null && generator.attachments!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Attached Files:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: generator.attachments!.length,
                  itemBuilder: (context, index) {
                    final fileName = generator.attachments![index];
                    final url = generator.attachmentUrls != null && 
                                generator.attachmentUrls!.length > index
                        ? generator.attachmentUrls![index]
                        : 'http://127.0.0.1:8000/storage/generators/$fileName';
                    
                    return Container(
                      margin: const EdgeInsets.only(right: 10),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.attach_file, color: Colors.blue),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 80,
                                child: Text(
                                  fileName.length > 15 
                                      ? '${fileName.substring(0, 15)}...' 
                                      : fileName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            
            // الملاحظات
            if (generator.notes != null && generator.notes!.isNotEmpty) ...[
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
                child: Text(generator.notes!),
              ),
            ],
            
            // معلومات النظام
            if (generator.createdAt != null || generator.updatedAt != null) ...[
              const SizedBox(height: 16),
              const Text(
                'System Information:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (generator.createdAt != null)
                _buildDetailRow('Created At', _formatDate(generator.createdAt!)),
              if (generator.updatedAt != null)
                _buildDetailRow('Last Updated', _formatDate(generator.updatedAt!)),
            ],
            
            const SizedBox(height: 30),
            
            // أزرار الإجراءات
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToEdit(generator);
                    },
                    icon: const Icon(Icons.edit, size: 20),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 10),
                if (generator.status == 'Working' || generator.status == 'Stopped')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _markForMaintenance(generator.id!);
                      },
                      icon: const Icon(Icons.build, size: 20),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      label: const Text('Maintenance'),
                    ),
                  )
                else if (generator.status == 'Under Maintenance')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _completeMaintenance(generator.id!);
                      },
                      icon: const Icon(Icons.check, size: 20),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      label: const Text('Complete'),
                    ),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteGenerator(generator.id!);
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
            width: 140,
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
                color: isImportant ? Colors.red : Colors.black,
                fontWeight: isImportant ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}