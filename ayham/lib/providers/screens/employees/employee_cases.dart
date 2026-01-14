import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nabtatcompany/providers/employee_case_provider.dart';
import 'package:nabtatcompany/models/employee_case.dart';
import 'package:nabtatcompany/models/meter.dart';
import 'package:nabtatcompany/providers/meter_provider.dart';

class EmployeeCasesScreen extends StatefulWidget {
  final int employeeId;

  const EmployeeCasesScreen({super.key, required this.employeeId});

  @override
  State<EmployeeCasesScreen> createState() => _EmployeeCasesScreenState();
}

class _EmployeeCasesScreenState extends State<EmployeeCasesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<EmployeeCaseProvider>().loadCases(widget.employeeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeCaseProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Cases'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(child: Text(provider.error!))
              : ListView.builder(
                  itemCount: provider.cases.length,
                  itemBuilder: (context, index) {
                    final EmployeeCase c = provider.cases[index];

                                    return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(c.caseType),
                      subtitle: Text(c.notes ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          provider.deleteCase(c.id!);
                        },
                      ),
                    ),
                  );

                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Case'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  ElevatedButton(
            onPressed: () {
              context.read<EmployeeCaseProvider>().addCase(
                widget.employeeId,
                EmployeeCase(
                  caseType: titleController.text,
                  status: 'open', // or 'pending', 'new', etc
                  notes: descController.text,
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          )

        ],
      ),
    );
  }
}
