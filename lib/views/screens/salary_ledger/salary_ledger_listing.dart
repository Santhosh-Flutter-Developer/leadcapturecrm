import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:leadcapture/models/src/salary_ledger_model.dart';
import 'package:leadcapture/services/database/src/spdb.dart';
import 'package:leadcapture/services/firebase/firebase.dart';
import 'package:leadcapture/services/firebase/src/salary_service.dart';
import 'package:leadcapture/utils/src/platform.dart';
import 'package:leadcapture/views/ui/src/back.dart';
import 'package:leadcapture/views/ui/src/loading.dart';

class SalaryLedgerList extends StatefulWidget {
  const SalaryLedgerList({super.key});

  @override
  State<SalaryLedgerList> createState() => _SalaryLedgerListState();
}

const String _pageTitle = "Salary";

class _SalaryLedgerListState extends State<SalaryLedgerList> {
  Future<SalarySummary>? _handler;
  int _selectedMonth = DateTime.now().month;
  int monthCode = DateTime.now().year * 100 + DateTime.now().month;
  Set<String> expandedCards = {};
  final TextEditingController _searchController = TextEditingController();
  final int _selectedYear = DateTime.now().year;

  bool isAdmin = false;
  bool isEmployee = false;
  String? user;
  bool isGenerating = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    isAdmin = await Spdb.isAdminLoggedIn();
    isEmployee = await Spdb.isEmployeeLoggedIn();
    user = await Spdb.getUid();

    // Month+Year selection
    monthCode = _selectedYear * 100 + _selectedMonth;
    setState(() {
      _handler = SalaryLedgerService.getMonthlySummary(
        monthCode,
        userId: isEmployee ? user : null,
      );
    });
  }

  String searchQuery = "";

  Future<void> _generateSalary() async {
    setState(() => isGenerating = true);

    try {
      final monthCode = DateTime.now().year * 100 + _selectedMonth;

      if (isAdmin) {
        final users = await EmployeeService.getAllEmployees();

        for (var emp in users) {
          final attendance =
              await SalaryLedgerService.getAttendanceSummaryForUser(
                emp.employeeId,
                monthCode,
              );

          await SalaryLedgerService.processMonthlySalary(
            monthCode: monthCode,
            attendance: attendance,
          );
        }
      } else {
        final attendance = await SalaryLedgerService.getAttendanceSummary(
          monthCode,
        );

        await SalaryLedgerService.processMonthlySalary(
          monthCode: monthCode,
          attendance: attendance,
        );
      }

      _init();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Salary Generated Successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed: $e")));
    }

    setState(() => isGenerating = false);
  }

  void _downloadPayslip(SalaryModel salary) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.picture_as_pdf),
            title: Text("Download PDF"),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.visibility),
            title: Text("Preview"),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Color statusColor(String status) {
    switch (status) {
      case "Generated":
        return Colors.green;
      case "Processing":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kIsMobile
          ? AppBar(leading: Back(), title: Text(_pageTitle))
          : null,
      body: isAdmin ? _adminView() : _employeeView(),
    );
  }

  Widget _adminView() {
    return RefreshIndicator(
      onRefresh: () async => _init(),
      child: FutureBuilder<SalarySummary>(
        future: _handler,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const WaitingLoading();
          }

          if (!snap.hasData) {
            return const Center(child: Text("No salary data found"));
          }

          final summary = snap.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _monthFilter(),
              const SizedBox(height: 8),
              _monthTitle(),
              const SizedBox(height: 16),

              _header(),

              const SizedBox(height: 16),
              _summaryCards(summary),

              const SizedBox(height: 16),
              _salaryList(summary.items),
            ],
          );
        },
      ),
    );
  }

  Widget _employeeView() {
    return RefreshIndicator(
      onRefresh: () async => _init(),
      child: FutureBuilder<SalarySummary>(
        future: _handler,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const WaitingLoading();
          }

          if (!snap.hasData) {
            return const Center(child: Text("No salary data found"));
          }

          final summary = snap.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _monthFilter(),
              const SizedBox(height: 8),
              _monthTitle(),

              const SizedBox(height: 16),

              _summaryCards(summary),

              const SizedBox(height: 16),

              /// Only their salary
              _salaryList(summary.items),
            ],
          );
        },
      ),
    );
  }

  Widget _monthFilter() {
    final months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: months.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = _selectedMonth == index + 1;

          return ChoiceChip(
            label: Text(months[index]),
            selected: isSelected,
            showCheckmark: false,

            labelStyle: TextStyle(
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),

            selectedColor: Colors.blue,
            backgroundColor: Colors.grey.shade100,

            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),

            onSelected: (_) {
              setState(() {
                _selectedMonth = index + 1;
                monthCode = DateTime.now().year * 100 + _selectedMonth;
                _handler = SalaryLedgerService.getMonthlySummary(
                  monthCode,
                  userId: isEmployee ? user : null,
                );
              });
            },
          );
        },
      ),
    );
  }

  Widget _monthTitle() {
    final year = DateTime.now().year;

    return Text(
      "Salary for ${_selectedMonth.toString().padLeft(2, '0')}/$year",
      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                /// ICON
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Iconsax.wallet_3,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),

                const SizedBox(width: 10),

                /// TEXT
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAdmin ? "Employee Salaries" : "My Salary",
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAdmin
                          ? "Manage & generate payroll"
                          : "Your monthly salary",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (isAdmin) ...[
            const SizedBox(width: 10),
            Flexible(
              child: Container(
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() => searchQuery = val.toLowerCase());
                  },

                  textAlignVertical: TextAlignVertical.center,

                  style: const TextStyle(fontSize: 12),

                  decoration: InputDecoration(
                    hintText: "Search employee ID...",
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),

                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 8, right: 4),
                      child: Icon(
                        Iconsax.search_normal,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                    ),

                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.close, size: 14),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => searchQuery = "");
                            },
                          )
                        : null,

                    isDense: true,

                    border: InputBorder.none,

                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 0,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            Tooltip(
              message: "Generate Salary",
              child: GestureDetector(
                onTap: isGenerating ? null : _generateSalary,
                child: Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withOpacity(.15),
                        Colors.blue.withOpacity(.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: isGenerating
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: WaitingLoading(),
                          )
                        : const Icon(
                            Icons.calculate,
                            color: Colors.blue,
                            size: 20,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryCards(SalarySummary summary) {
    final items = isAdmin
        ? [
            (
              "Employees",
              summary.items.length.toDouble(),
              Iconsax.people,
              Colors.purple,
              false,
            ),
            (
              "Gross Pay",
              summary.totalGrossPay,
              Iconsax.wallet_3,
              Colors.blue,
              true,
            ),
            (
              "Net Pay",
              summary.totalAmount,
              Iconsax.money_recive,
              Colors.green,
              true,
            ),
            (
              "Deductions",
              summary.totalDeductions,
              Iconsax.money_send,
              Colors.red,
              true,
            ),
          ]
        : [
            (
              "Net Pay",
              summary.totalAmount,
              Iconsax.money_recive,
              Colors.green,
              true,
            ),
            (
              "Deductions",
              summary.totalDeductions,
              Iconsax.money_send,
              Colors.red,
              true,
            ),
          ];

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final item = items[i];

          return Container(
            width: kIsMobile ? 160 : 220,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.04),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                /// ICON
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: item.$4.withOpacity(.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.$3, color: item.$4, size: 20),
                ),

                const SizedBox(width: 10),

                /// TEXT
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.$1,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        item.$5 ? "This month" : "Count",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        item.$5
                            ? "₹${item.$2.toStringAsFixed(2)}"
                            : item.$2.toInt().toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: item.$4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _salaryList(List<SalaryModel> items) {
    List<SalaryModel> filteredList = [];

    if (isAdmin) {
      filteredList = items;
    } else if (isEmployee) {
      filteredList = items
          .where((salary) => salary.employeeId == user)
          .toList();
    }

    if (isAdmin && searchQuery.isNotEmpty) {
      filteredList = filteredList
          .where(
            (e) =>
                e.employeeId.toLowerCase().contains(searchQuery.toLowerCase()),
          )
          .toList();
    }

    filteredList.sort((a, b) => b.toDate.compareTo(a.toDate));

    if (filteredList.isEmpty) {
      return Column(
        children: [
          const SizedBox(height: 60),

          Icon(Iconsax.empty_wallet, size: 60, color: Colors.grey),

          const SizedBox(height: 12),

          const Text(
            "No Salary Records",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 6),

          Text(
            "No salary found for selected month",
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),

          const SizedBox(height: 16),

          if (isAdmin)
            ElevatedButton.icon(
              onPressed: _generateSalary,
              icon: const Icon(Icons.calculate),
              label: const Text("Generate Salary"),
            ),
        ],
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        return _salaryCard(filteredList[index]);
      },
    );
  }

  Widget _salaryCard(SalaryModel salary) {
    String formatCurrency(String value) {
      final val = double.tryParse(value) ?? 0;
      return "₹${val.toStringAsFixed(2)}";
    }

    bool isExpanded = expandedCards.contains(salary.salaryNumber);
    String getStatus(SalaryModel s) {
      if (double.tryParse(s.netPay) == null) return "Pending";
      if (double.parse(s.netPay) == 0) return "Processing";
      return "Generated";
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Salary #${salary.salaryNumber}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (isAdmin)
                      Text(
                        "Emp: ${salary.employeeId}",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor(getStatus(salary)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    getStatus(salary),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor(getStatus(salary)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.withOpacity(.15),
                    Colors.green.withOpacity(.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    "Net Salary",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatCurrency(salary.netPay),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// 📊 WORK INFO
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _info("Working Days", salary.workingDays)),
                Expanded(child: _info("Leave Days", salary.leaveDays)),
                Expanded(child: _info("OT Hours", salary.otHours)),
              ],
            ),

            const Divider(height: 28),

            /// 💰 EARNINGS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _info("Earned", formatCurrency(salary.earnAmount)),
                ),
                Expanded(child: _info("OT", formatCurrency(salary.otAmount))),
                Expanded(
                  child: _info(
                    "Gross",
                    formatCurrency(salary.grossPay),
                    color: Colors.blue,
                  ),
                ),
              ],
            ),

            const Divider(height: 28),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _info(
                    "Deduction",
                    formatCurrency(salary.totalDeduction),
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            if (isExpanded) ...[
              const Divider(),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: _info("PF", formatCurrency(salary.pfAmount))),
                  Expanded(
                    child: _info("ESI", formatCurrency(salary.esiAmount)),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _info(
                      "Other",
                      formatCurrency(salary.otherDeduction),
                    ),
                  ),
                  Expanded(
                    child: _info(
                      "Advance",
                      formatCurrency(salary.advanceDeduction),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 6),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (isExpanded) {
                        expandedCards.remove(salary.salaryNumber);
                      } else {
                        expandedCards.add(salary.salaryNumber);
                      }
                    });
                  },
                  child: Text(isExpanded ? "Hide Details" : "View Details"),
                ),

                TextButton.icon(
                  onPressed: () {
                    _downloadPayslip(salary);
                  },
                  icon: Icon(Icons.download, size: 16),
                  label: Text("Payslip"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(String title, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),

        const SizedBox(height: 4),

        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black,
          ),
        ),
      ],
    );
  }
}
