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

  bool isAdmin = false;
  bool isEmployee = false;
  String? user;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    isAdmin = await Spdb.isAdminLoggedIn();
    isEmployee = await Spdb.isEmployeeLoggedIn();
    user = await Spdb.getUid();
    monthCode = DateTime.now().year * 100 + _selectedMonth;

    setState(() {
      _handler = SalaryLedgerService.getMonthlySummary(
        monthCode,
        userId: isEmployee ? user : null,
      );
    });
  }

  String searchQuery = "";

  void _showSearch() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Search Employee"),
          content: TextField(
            onChanged: (val) {
              setState(() => searchQuery = val.toLowerCase());
            },
            decoration: const InputDecoration(hintText: "Enter Employee ID"),
          ),
        );
      },
    );
  }

  Future<void> _generateSalary() async {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kIsMobile
          ? AppBar(leading: Back(), title: Text(_pageTitle))
          : null,
      body: RefreshIndicator(
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
              _selectedMonth = index + 1;
              _init();
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isAdmin ? "Employee Salaries" : "My Salary",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (isAdmin)
          IconButton(
            icon: const Icon(Iconsax.search_normal),
            onPressed: () {
              _showSearch();
            },
          ),
        if (isAdmin)
          IconButton(
            icon: const Icon(Icons.calculate),
            onPressed: _generateSalary,
          ),
      ],
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
            ),
            ("Gross Pay", summary.totalGrossPay, Iconsax.wallet_3, Colors.blue),
            (
              "Net Pay",
              summary.totalAmount,
              Iconsax.money_recive,
              Colors.green,
            ),
            (
              "Deductions",
              summary.totalDeductions,
              Iconsax.money_send,
              Colors.red,
            ),
          ]
        : [
            (
              "Net Pay",
              summary.totalAmount,
              Iconsax.money_recive,
              Colors.green,
            ),
            (
              "Deductions",
              summary.totalDeductions,
              Iconsax.money_send,
              Colors.red,
            ),
          ];
    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final item = items[i];

          return Container(
            width: screenWidth * 0.19,
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

                      const SizedBox(height: 4),

                      Text(
                        "₹${item.$2.toStringAsFixed(2)}",
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
      // temporary logic
      return s.netPayValue > 0 ? "Generated" : "Pending";
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
                    color: getStatus(salary) == "Generated"
                        ? Colors.blue.withOpacity(.1)
                        : Colors.orange.withOpacity(.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    getStatus(salary),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: getStatus(salary) == "Generated"
                          ? Colors.blue
                          : Colors.orange,
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

            /// 📄 ACTION
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
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
            ),
          ],
        ),
      ),
    );
  }

  // void _openSalaryDetails(SalaryModel salary) {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     builder: (_) {
  //       return Padding(
  //         padding: const EdgeInsets.all(16),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Text(
  //               "Salary Breakdown",
  //               style: TextStyle(fontWeight: FontWeight.bold),
  //             ),

  //             const SizedBox(height: 10),

  //             _info("Earned", "₹${salary.earnAmount}"),
  //             _info("OT Amount", "₹${salary.otAmount}"),
  //             _info("PF", "₹${salary.pfAmount}"),
  //             _info("ESI", "₹${salary.esiAmount}"),
  //             _info("Other Deduction", "₹${salary.otherDeduction}"),
  //             _info("Total Deduction", "₹${salary.totalDeduction}"),

  //             const Divider(),

  //             _info("Net Pay", "₹${salary.netPay}", color: Colors.green),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

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
