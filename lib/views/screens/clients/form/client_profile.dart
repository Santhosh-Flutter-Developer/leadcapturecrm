import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '/models/models.dart';
import '/theme/theme.dart';
import '/constants/constants.dart';
import '/views/views.dart';

class ClientProfile extends StatelessWidget {
  final ClientModel client;

  const ClientProfile({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        bottomLeft: Radius.circular(16),
      ),
      child: Scaffold(
        appBar: FormWidgets.buildHeader(
          context: context,
          title: "Client Details",
        ),
        backgroundColor: AppColors.grey50,
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 10, left: 10, right: 10),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                children: [
                  // _buildHeader(context),
                  // const SizedBox(height: 24),
                  _buildHeaderCard(context),
                  const SizedBox(height: 24),
                  _buildContactInfo(context),
                  const SizedBox(height: 20),
                  _buildCompanyInfo(context),
                  const SizedBox(height: 24),
                  _buildProjectsCard(context),
                  const SizedBox(height: 24),
                  _buildInvoicesCard(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget _buildHeader(BuildContext context) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  //     decoration: const BoxDecoration(
  //       color: AppColors.white,
  //       boxShadow: [
  //         BoxShadow(
  //           color: AppColors.black12,
  //           blurRadius: 4,
  //           offset: Offset(0, 2),
  //         ),
  //       ],
  //     ),
  //     child: Row(
  //       children: [
  //         // IconButton(
  //         //   onPressed: () {
  //         //     if (Navigator.canPop(context)) {
  //         //       Navigator.pop(context);
  //         //     }
  //         //   },
  //         //   icon: const Icon(Icons.close, color: AppColors.black),
  //         // ),
  //         // const SizedBox(width: 8),
  //         Text(
  //           "Client Details",
  //           style: Theme.of(context).textTheme.titleLarge!.copyWith(
  //             color: AppColors.primary,
  //             fontWeight: FontWeight.bold,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: CachedNetworkImage(
                  imageUrl:
                      client.profilePictureUrl != null &&
                          client.profilePictureUrl!.isNotEmpty
                      ? client.profilePictureUrl!
                      : AppStrings.emptyProfilePhotoUrl,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: AppColors.grey300,
                    highlightColor: AppColors.grey100,
                    child: Container(color: AppColors.white),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                  height: 45,
                  width: 45,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.clientName!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      client.companyName!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 20,
                      runSpacing: 6,
                      children: [
                        _iconText(context, Icons.email, client.email!),
                        _iconText(context, Icons.phone, client.mobileNumber!),
                        _iconText(
                          context,
                          Icons.language,
                          client.officialWebsite ?? "No website",
                        ),
                        _iconText(
                          context,
                          Icons.location_on,
                          "${client.city?.name ?? '-'}, ${client.state?.name ?? '-'}",
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _statCard(
                context,
                Icons.folder_open_outlined,
                "Projects",
                "8",
                const Color(0xFF1E88E5),
              ),
              _statCard(
                context,
                Icons.attach_money,
                "Earnings",
                "\$24,000",
                const Color(0xFF43A047),
              ),
              _statCard(
                context,
                Icons.receipt_long_outlined,
                "Due Invoices",
                "2",
                const Color(0xFFE53935),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconText(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.grey600),
        const SizedBox(width: 6),
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.black54),
        ),
      ],
    );
  }

  Widget _statCard(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo(BuildContext context) {
    final contactItems = [
      {
        "label": "Client Name",
        "value": "${client.salutation} ${client.clientName}",
      },
      {"label": "Email", "value": client.email},
      {"label": "Mobile", "value": client.mobileNumber},
      {"label": "Gender", "value": client.gender},
      {
        "label": "Login Allowed",
        "value": client.loginAllowed == true ? "Yes" : "No",
      },
      {
        "label": "Email Notifications",
        "value": client.receiveEmailNotifications == true ? "Yes" : "No",
      },
    ];

    return _expandableSection(
      context: context,
      title: "Contact Details",
      icon: Icons.person_outline,
      items: contactItems,
    );
  }

  Widget _buildCompanyInfo(BuildContext context) {
    final companyItems = [
      {"label": "Company Name", "value": client.companyName},
      {"label": "Website", "value": client.officialWebsite},
      {"label": "GST/VAT No", "value": client.gstVatNumber},
      {"label": "Office Phone", "value": client.officePhoneNo},
      {
        "label": "Location",
        "value": "${client.city?.name ?? '-'}, ${client.state?.name ?? '-'}",
      },
      {"label": "Postal Code", "value": client.postalCode},
      {"label": "Company Address", "value": client.companyAddress},
      {"label": "Shipping Address", "value": client.shippingAddress},
      {"label": "Notes", "value": client.notes},
    ];

    return _expandableSection(
      context: context,
      title: "Company Details",
      icon: Icons.apartment_outlined,
      items: companyItems,
    );
  }

  Widget _expandableSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Map<String, dynamic>> items,
  }) {
    return Container(
      decoration: _cardDecoration(),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.all(16),
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 800
                  ? 3
                  : constraints.maxWidth > 500
                  ? 2
                  : 1;

              return Wrap(
                spacing: 20,
                runSpacing: 12,
                children: items.map((item) {
                  return SizedBox(
                    width: constraints.maxWidth / crossAxisCount - 24,
                    child: _infoTile(
                      context,
                      item["label"].toString(),
                      item["value"]?.toString() ?? "-",
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsCard(BuildContext context) {
    return _sectionContainer(
      context: context,
      title: "Projects",
      icon: Icons.folder_open_outlined,
      child: Column(
        children: [
          _listTile(
            context,
            "CRM Development",
            "In Progress",
            AppColors.orange,
          ),
          _listTile(
            context,
            "E-Commerce Website",
            "Completed",
            AppColors.success,
          ),
          _listTile(context, "Mobile App Design", "Pending", AppColors.danger),
        ],
      ),
    );
  }

  Widget _buildInvoicesCard(BuildContext context) {
    return _sectionContainer(
      context: context,
      title: "Invoices",
      icon: Icons.receipt_long_outlined,
      child: Column(
        children: [
          _invoiceTile(
            context,
            "Invoice #INV-2025-01",
            "Paid",
            AppColors.success,
          ),
          _invoiceTile(
            context,
            "Invoice #INV-2025-02",
            "Pending",
            AppColors.orange,
          ),
          _invoiceTile(
            context,
            "Invoice #INV-2025-03",
            "Overdue",
            AppColors.danger,
          ),
        ],
      ),
    );
  }

  Widget _invoiceTile(
    BuildContext context,
    String title,
    String status,
    Color color,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.receipt_outlined, color: AppColors.black54),
      title: Text(title, style: Theme.of(context).textTheme.bodyMedium),
      trailing: Text(
        status,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _listTile(
    BuildContext context,
    String title,
    String status,
    Color color,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.circle, color: color, size: 14),
      title: Text(title, style: Theme.of(context).textTheme.bodyMedium),
      trailing: Text(
        status,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _infoTile(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value.isEmpty ? "-" : value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.black87,
          ),
        ),
      ],
    );
  }

  Widget _sectionContainer({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, title, icon),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: AppColors.grey.withValues(alpha: 0.1),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ],
  );
}
