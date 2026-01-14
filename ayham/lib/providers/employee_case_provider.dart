import 'package:flutter/material.dart';
import '../models/employee_case.dart';
import '../services/employee_case_service.dart';

class EmployeeCaseProvider extends ChangeNotifier {
  final _service = EmployeeCaseService();

  List<EmployeeCase> _cases = [];
  bool _loading = false;
  String? _error;

  List<EmployeeCase> get cases => _cases;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> loadCases(int employeeId) async {
    _loading = true;
    notifyListeners();

    try {
      _cases = await _service.fetchCases(employeeId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> addCase(int employeeId, EmployeeCase employeeCase) async {
    final newCase = await _service.createCase(employeeId, employeeCase);
    _cases.insert(0, newCase);
    notifyListeners();
  }

  Future<void> updateCase(int caseId, EmployeeCase employeeCase) async {
    final updated = await _service.updateCase(caseId, employeeCase);
    final index = _cases.indexWhere((c) => c.id == caseId);
    if (index != -1) _cases[index] = updated;
    notifyListeners();
  }

  Future<void> deleteCase(int caseId) async {
    await _service.deleteCase(caseId);
    _cases.removeWhere((c) => c.id == caseId);
    notifyListeners();
  }
}
