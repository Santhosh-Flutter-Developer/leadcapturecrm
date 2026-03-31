import 'package:flutter/material.dart';

class EmployeeReport extends StatefulWidget {
  final String employeeId;
  const EmployeeReport({super.key, required this.employeeId});

  @override
  State<EmployeeReport> createState() => _EmployeeReportState();
}

class _EmployeeReportState extends State<EmployeeReport> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Employee Report")),
      body: Center(child: Text("Report for Employee: ${widget.employeeId}")),
    );
  }
}
