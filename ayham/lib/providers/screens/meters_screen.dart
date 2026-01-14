import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:nabtatcompany/models/meter.dart';
import 'package:nabtatcompany/providers/meter_provider.dart';
import 'package:nabtatcompany/providers/screens/add_edit_meter_screen.dart';
import 'package:nabtatcompany/providers/screens/notification_screen.dart';
import 'package:nabtatcompany/providers/screens/meter_detail_screen.dart';

class MetersScreen extends StatefulWidget {
  const MetersScreen({Key? key}) : super(key: key);

  @override
  State<MetersScreen> createState() => _MetersScreenState();
}

class _MetersScreenState extends State<MetersScreen> {
  String _selectedFilter = 'الكل';
  final TextEditingController _searchController = TextEditingController();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMeters());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMeters() async {
    try {
      await Provider.of<MeterProvider>(context, listen: false).fetchMeters();
    } catch (e) {
      debugPrint('Error loading meters: $e');
    }
  }

  Future<void> _refreshMeters() async {
    if (!mounted) return;
    setState(() => _isRefreshing = true);
    try {
      await Provider.of<MeterProvider>(context, listen: false).fetchMeters();
    } catch (e) {
      debugPrint('Error refreshing meters: $e');
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  List<Meter> _getFilteredMeters(List<Meter> allMeters) {
    List<Meter> filtered = allMeters;

    // Search
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((meter) {
        return meter.name.toLowerCase().contains(query) ||
            meter.serialNumber.toLowerCase().contains(query) ||
            (meter.billNumber?.toLowerCase().contains(query) ?? false) ||
            (meter.housing?.name.toLowerCase().contains(query) ?? false) ||
            (meter.building?.name.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Filter by payment status
    if (_selectedFilter != 'الكل') {
      filtered = filtered
          .where((meter) => meter.paymentStatus == _selectedFilter)
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة العدادات'),
        backgroundColor: const Color(0xFF2C3E50),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'الإشعارات',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshMeters,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: Consumer<MeterProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && !_isRefreshing) {
            return _buildLoadingState();
          }

          if (provider.error != null) {
            return _buildErrorState(provider.error!, provider);
          }

          final filteredMeters = _getFilteredMeters(provider.meters);

          if (filteredMeters.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              _buildSearchBar(),
              _buildFilterChips(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshMeters,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filteredMeters.length,
                    itemBuilder: (context, index) {
                      final meter = filteredMeters[index];
                      return _buildMeterCard(meter, context);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2C3E50),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditMeterScreen()),
          ).then((_) => _refreshMeters());
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('جاري تحميل العدادات...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, MeterProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C3E50)),
              onPressed: () {
                provider.clearError();
                _refreshMeters();
              },
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        _buildSearchBar(),
        _buildFilterChips(),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.electric_meter_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('لا توجد عدادات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  if (_searchController.text.isNotEmpty || _selectedFilter != 'الكل') ...[
                    const Text('لم يتم العثور على عدادات تطابق معايير البحث', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C3E50)),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _selectedFilter = 'الكل');
                      },
                      child: const Text('عرض جميع العدادات'),
                    ),
                  ] else
                    const Text('قم بإضافة عداد جديد باستخدام زر الإضافة', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      color: Colors.grey[50],
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'ابحث عن عداد...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      color: Colors.grey[50],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: const [
            _FilterChip(label: 'الكل', icon: Icons.all_inclusive),
            _FilterChip(label: 'مسدد', icon: Icons.check_circle),
            _FilterChip(label: 'غير مسدد', icon: Icons.cancel),
            _FilterChip(label: 'مستحق', icon: Icons.pending),
          ],
        ),
      ),
    );
  }

  Widget _buildMeterCard(Meter meter, BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (meter.paymentStatus) {
      case 'مسدد':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'مسدد';
        break;
      case 'غير مسدد':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'غير مسدد';
        break;
      case 'مستحق':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'مستحق';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusText = 'غير محدد';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MeterDetailScreen(meterId: meter.id)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.electric_meter, color: statusColor, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Text(meter.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(statusText, style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text('الرقم التسلسلي: ${meter.serialNumber}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  if (meter.housing != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(children: [
                        const Icon(Icons.home, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(meter.housing!.name, style: const TextStyle(fontSize: 14)),
                      ]),
                    ),
                  if (meter.billAmount != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(children: [
                        const Icon(Icons.attach_money, size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Text('${meter.billAmount!.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                        if (meter.billNumber != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text('(${meter.billNumber!})', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ),
                      ]),
                    ),
                  if (meter.notes != null && meter.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(children: [
                        const Icon(Icons.notes, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(child: Text(meter.notes!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.grey))),
                      ]),
                    ),
                ]),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (value) => _handleMenuAction(value, meter, context),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: _MenuRow(icon: Icons.edit, color: Colors.blue, text: 'تعديل')),
                  PopupMenuItem(value: 'view', child: _MenuRow(icon: Icons.visibility, color: Colors.green, text: 'عرض التفاصيل')),
                  PopupMenuItem(value: 'delete', child: _MenuRow(icon: Icons.delete, color: Colors.red, text: 'حذف')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(String action, Meter meter, BuildContext context) {
    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddEditMeterScreen(meter: meter)),
        ).then((_) => _refreshMeters());
        break;
      case 'view':
        Navigator.push(context, MaterialPageRoute(builder: (_) => MeterDetailScreen(meterId: meter.id)));
        break;
      case 'delete':
        _showDeleteDialog(context, meter);
        break;
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, Meter meter) async {
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        title: const Row(children: [Icon(Icons.warning, color: Colors.orange), SizedBox(width: 8), Text('تأكيد الحذف')]),
        content: Text('هل أنت متأكد من حذف العداد "${meter.name}"؟\nالرقم التسلسلي: ${meter.serialNumber}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Provider.of<MeterProvider>(context, listen: false).deleteMeter(meter.id);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم حذف العداد "${meter.name}" بنجاح'), backgroundColor: Colors.green),
                );
                _refreshMeters();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('خطأ في حذف العداد: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_MetersScreenState>()!;
    final isSelected = state._selectedFilter == label;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        selected: isSelected,
        onSelected: (selected) => state.setState(() => state._selectedFilter = selected ? label : 'الكل'),
        selectedColor: const Color(0xFF2C3E50),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isSelected ? const Color(0xFF2C3E50) : Colors.grey.shade300),
        ),
        label: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey),
          const SizedBox(width: 4),
          Text(label),
        ]),
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade700),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(children: [Icon(icon, size: 20, color: color), const SizedBox(width: 8), Text(text)]);
  }
}
