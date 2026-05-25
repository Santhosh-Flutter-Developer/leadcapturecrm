import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import 'package:leadcapture/models/src/salary_ledger_model.dart';
import 'package:leadcapture/models/src/employee_model.dart';
import 'package:leadcapture/services/firebase/src/employee_service.dart';
import 'package:leadcapture/theme/theme.dart';
import 'package:leadcapture/utils/src/xls_export.dart';
import 'package:leadcapture/utils/src/platform.dart';
import 'package:leadcapture/views/ui/src/back.dart';
import 'package:leadcapture/views/ui/src/loading.dart';

class PayslipDetailScreen extends StatefulWidget {
  final SalaryModel salary;

  const PayslipDetailScreen({
    super.key,
    required this.salary,
  });

  @override
  State<PayslipDetailScreen> createState() => _PayslipDetailScreenState();
}

class _PayslipDetailScreenState extends State<PayslipDetailScreen> {
  Future<EmployeeModel?>? _employeeFuture;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _employeeFuture = EmployeeService.getEmployee(uid: widget.salary.employeeId);
  }

  String _getMonthName(String monthCodeStr) {
    if (monthCodeStr.length >= 6) {
      final year = monthCodeStr.substring(0, 4);
      final monthIndex = int.tryParse(monthCodeStr.substring(4, 6)) ?? 1;
      const months = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
      ];
      if (monthIndex >= 1 && monthIndex <= 12) {
        return "${months[monthIndex - 1]} $year";
      }
    }
    return monthCodeStr;
  }

  String _formatCurrency(String value) {
    final val = double.tryParse(value) ?? 0;
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    return formatter.format(val);
  }

  Future<void> _exportExcel(EmployeeModel? employee) async {
    setState(() => _isExporting = true);
    try {
      await XlsExport.payslipReportExport(
        salary: widget.salary,
        employee: employee,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Excel Payslip exported and downloaded successfully!"),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to export Excel: $e"),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = !kIsMobile;
    final monthName = _getMonthName(widget.salary.salaryNumber);

    return Scaffold(
      backgroundColor: context.colors.bgColor,
      appBar: AppBar(
        leading: const Back(),
        title: Text("Payslip - $monthName"),
        elevation: 0,
        backgroundColor: context.colors.cardColor,
        foregroundColor: context.colors.textPrimary,
      ),
      body: FutureBuilder<EmployeeModel?>(
        future: _employeeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: WaitingLoading());
          }

          final employee = snapshot.data;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 900 : double.infinity,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Sleek Logo / Header Card (Srisoftwarez Theme)
                    _buildCompanyHeader(monthName),
                    const SizedBox(height: 16),

                    // 2. Employee Metadata block
                    _buildEmployeeBlock(employee),
                    const SizedBox(height: 16),

                    // 3. Responsive Earnings & Deductions Layout
                    isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildEarningsCard()),
                              const SizedBox(width: 16),
                              Expanded(child: _buildDeductionsCard()),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildEarningsCard(),
                              const SizedBox(height: 16),
                              _buildDeductionsCard(),
                            ],
                          ),
                    const SizedBox(height: 16),

                    // 4. Earning vs Deduction Summary Bar
                    _buildSummaryTotals(),
                    const SizedBox(height: 16),

                    // 5. Net Salary Highlights Banner
                    _buildNetPayBanner(),
                    const SizedBox(height: 24),

                    // 6. Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isExporting ? null : () => _exportExcel(employee),
                          icon: _isExporting
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Iconsax.document_download),
                          label: Text(_isExporting ? "Exporting..." : "Download Excel"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompanyHeader(String monthName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "SRISOFTWAREZ",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Salary Payslip Statement",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              monthName.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeBlock(EmployeeModel? employee) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "EMPLOYEE INFORMATION",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: 0.8,
            ),
          ),
          const Divider(height: 20, thickness: 1),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: employee?.profileImageUrl != null
                    ? NetworkImage(employee!.profileImageUrl!)
                    : null,
                child: employee?.profileImageUrl == null
                    ? Text(
                        (employee?.name.isNotEmpty == true)
                            ? employee!.name[0].toUpperCase()
                            : "E",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee?.name ?? "Employee Name N/A",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      employee?.designation ?? "Designation N/A",
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Details Grid
          _buildInfoRow([
            _infoItem("Employee ID", employee?.employeeId ?? widget.salary.employeeId),
            _infoItem("Department", employee?.department?.join(', ') ?? "N/A"),
          ]),
          const SizedBox(height: 12),
          _buildInfoRow([
            _infoItem(
              "Pay Period",
              widget.salary.salaryFromDate.isNotEmpty
                  ? "${DateFormat('dd/MM/yyyy').format(DateTime.parse(widget.salary.salaryFromDate))} - ${DateFormat('dd/MM/yyyy').format(DateTime.parse(widget.salary.salaryToDate))}"
                  : "N/A",
            ),
            _infoItem(
              "Working Days",
              "${widget.salary.workingDays} Days (${widget.salary.leaveDays} Leaves)",
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildInfoRow(List<Widget> children) {
    return Row(
      children: children.map((child) => Expanded(child: child)).toList(),
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: context.colors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: context.colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "EARNINGS",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                  letterSpacing: 0.8,
                ),
              ),
              Icon(Iconsax.money_recive, color: AppColors.success.withValues(alpha: 0.7), size: 18),
            ],
          ),
          const Divider(height: 20, thickness: 1),
          _buildItemRow("Basic & Earned Salary", _formatCurrency(widget.salary.earnAmount)),
          _buildItemRow("Overtime Pay (${widget.salary.otHours} hrs)", _formatCurrency(widget.salary.otAmount)),
          _buildItemRow("Incentives & Performance Bonus", _formatCurrency(widget.salary.incentive)),
        ],
      ),
    );
  }

  Widget _buildDeductionsCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "DEDUCTIONS",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.danger,
                  letterSpacing: 0.8,
                ),
              ),
              Icon(Iconsax.money_send, color: AppColors.danger.withValues(alpha: 0.7), size: 18),
            ],
          ),
          const Divider(height: 20, thickness: 1),
          _buildItemRow("Provident Fund (PF)", _formatCurrency(widget.salary.pfAmount)),
          _buildItemRow("Employee State Ins (ESI)", _formatCurrency(widget.salary.esiAmount)),
          _buildItemRow("Advance Salary Deduction", _formatCurrency(widget.salary.advanceDeduction)),
          _buildItemRow("Other/Permission Deductions", _formatCurrency(widget.salary.otherDeduction)),
        ],
      ),
    );
  }

  Widget _buildItemRow(String title, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? context.colors.textPrimary : context.colors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? context.colors.textPrimary : context.colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTotals() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "GROSS EARNINGS",
                  style: TextStyle(fontSize: 10, color: context.colors.textSecondary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(widget.salary.grossPay),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 30, width: 1, color: context.colors.divider),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "TOTAL DEDUCTIONS",
                  style: TextStyle(fontSize: 10, color: context.colors.textSecondary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(widget.salary.totalDeduction),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetPayBanner() {
    final netPayVal = double.tryParse(widget.salary.netPay) ?? 0;
    final amountInWords = XlsExport.numberToWords(netPayVal.toInt());

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bannerBg = isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFD1FAE5);
    final bannerBorder = isDark ? const Color(0xFF059669).withValues(alpha: 0.4) : const Color(0xFFA7F3D0);
    final bannerTitleColor = isDark ? const Color(0xFF34D399) : const Color(0xFF047857);
    final bannerValueColor = isDark ? const Color(0xFF10B981) : const Color(0xFF065F46);
    final bannerWordsColor = isDark ? const Color(0xFF34D399).withValues(alpha: 0.8) : const Color(0xFF065F46);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bannerBg,
        border: Border.all(color: bannerBorder, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            "NET TAKE-HOME SALARY",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: bannerTitleColor,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(widget.salary.netPay),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: bannerValueColor,
            ),
          ),
          if (amountInWords.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              "Rupees $amountInWords Only",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: bannerWordsColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
