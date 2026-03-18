import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:leadcapture/models/src/salary_ledger_model.dart';
import 'package:leadcapture/services/database/src/spdb.dart';
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
      _handler = SalaryLedgerService.getMonthlySummary(monthCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kIsMobile
          ? AppBar(leading: Back(), title: Text(_pageTitle))
          : null,
      body: FutureBuilder<SalarySummary>(
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
                _init();
              });
            },
          );
        },
      ),
    );
  }

  Widget _summaryCards(SalarySummary summary) {
    final items = [
      ("Gross Pay", summary.totalGrossPay, Iconsax.wallet_3, Colors.blue),
      ("Net Pay", summary.totalAmount, Iconsax.money_recive, Colors.green),
      ("Deductions", summary.totalDeductions, Iconsax.money_send, Colors.red),
      ("OT Hours", summary.totalHours, Iconsax.timer_1, Colors.orange),
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

    if (filteredList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// ICON
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(.15),
                    Colors.blue.withOpacity(.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.empty_wallet,
                size: 46,
                color: Colors.blue,
              ),
            ),

            const SizedBox(height: 20),

            /// TITLE
            const Text(
              "No Salary Records Available",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 8),

            /// SUBTITLE
            Text(
              "Salary details for the selected month are not available yet.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 6),
          ],
        ),
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
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Salary #${salary.salaryNumber}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Paid",
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// WORK DETAILS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _info("Working Days", salary.workingDays)),
                Expanded(child: _info("Leave Days", salary.leaveDays)),
                Expanded(child: _info("OT Hours", salary.otHours)),
              ],
            ),

            const Divider(height: 28),

            /// EARNINGS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _info("Earned", "₹${salary.earnAmount}")),
                Expanded(child: _info("OT", "₹${salary.otAmount}")),
                Expanded(
                  child: _info(
                    "Gross",
                    "₹${salary.grossPay}",
                    color: Colors.blue,
                  ),
                ),
              ],
            ),

            const Divider(height: 28),

            /// FINAL
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _info(
                    "Deduction",
                    "₹${salary.totalDeduction}",
                    color: Colors.red,
                  ),
                ),

                Expanded(
                  child: _info(
                    "Net Pay",
                    "₹${salary.netPay}",
                    color: Colors.green,
                  ),
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
