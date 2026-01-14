import 'package:flutter/material.dart';
import 'package:nabtatcompany/models/meter.dart';
import 'package:nabtatcompany/providers/meter_provider.dart';
import 'package:nabtatcompany/providers/screens/add_edit_meter_screen.dart';
import 'package:provider/provider.dart';

class MeterDetailScreen extends StatelessWidget {
  final int meterId;

  const MeterDetailScreen({Key? key, required this.meterId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل العداد'),
        backgroundColor: const Color(0xFF2C3E50),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // يمكن إضافة تحديث للبيانات
            },
          ),
        ],
      ),
      body: FutureBuilder<Meter>(
        future: Provider.of<MeterProvider>(context, listen: false).getMeter(meterId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'حدث خطأ',
                    style: TextStyle(fontSize: 18, color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('العودة'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('العداد غير موجود'),
            );
          }

          final meter = snapshot.data!;
          return _buildMeterDetails(meter, context);
        },
      ),
    );
  }

  Widget _buildMeterDetails(Meter meter, BuildContext context) {
    Color statusColor;
    switch (meter.paymentStatus) {
      case 'مسدد':
        statusColor = Colors.green;
        break;
      case 'غير مسدد':
        statusColor = Colors.red;
        break;
      case 'مستحق':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // بطاقة المعلومات الأساسية
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.electric_meter, color: Colors.blue),
                    title: const Text(
                      'اسم العداد',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    subtitle: Text(
                      meter.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.numbers, color: Colors.blue),
                    title: const Text(
                      'الرقم التسلسلي',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    subtitle: Text(
                      meter.serialNumber,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.payment, color: Colors.blue),
                    title: const Text(
                      'حالة الدفع',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    subtitle: Chip(
                      label: Text(
                        meter.paymentStatus,
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // بطاقة الموقع
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'الموقع',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.home, color: Colors.green),
                    title: const Text('الوحدة السكنية'),
                    subtitle: Text(meter.housing?.name ?? 'غير محدد'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.business, color: Colors.green),
                    title: const Text('المبنى'),
                    subtitle: Text(meter.building?.name ?? 'غير محدد'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // بطاقة الفاتورة
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'معلومات الفاتورة',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.receipt, color: Colors.orange),
                    title: const Text('رقم الفاتورة'),
                    subtitle: Text(meter.billNumber ?? 'غير محدد'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.attach_money, color: Colors.orange),
                    title: const Text('مبلغ الفاتورة'),
                    subtitle: Text(
                      meter.billAmount != null
                          ? '${meter.billAmount!.toStringAsFixed(2)}'
                          : 'غير محدد',
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (meter.notes != null && meter.notes!.isNotEmpty)
            Column(
              children: [
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ملاحظات',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          meter.notes!,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 16),

          // بطاقة التواريخ
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'التواريخ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (meter.createdAt != null)
                    ListTile(
                      leading: const Icon(Icons.calendar_today, color: Colors.teal),
                      title: const Text('تاريخ الإنشاء'),
                      subtitle: Text(
                        '${meter.createdAt!.toLocal()}'.split(' ')[0],
                      ),
                    ),
                  if (meter.updatedAt != null)
                    ListTile(
                      leading: const Icon(Icons.update, color: Colors.teal),
                      title: const Text('تاريخ التحديث'),
                      subtitle: Text(
                        '${meter.updatedAt!.toLocal()}'.split(' ')[0],
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // أزرار الإجراءات
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEditMeterScreen(meter: meter),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('تعديل'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // إضافة منطق لدفع الفاتورة
                  },
                  icon: const Icon(Icons.payment),
                  label: const Text('دفع الفاتورة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}