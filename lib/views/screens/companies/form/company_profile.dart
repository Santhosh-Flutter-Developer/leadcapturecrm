import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '/models/models.dart';
import '/constants/constants.dart';
import '/views/views.dart';

class CompanyProfile extends StatefulWidget {
  final CompanyModel company;

  const CompanyProfile({
    super.key,
    required this.company,
  });

  @override
  State<CompanyProfile> createState() => _CompanyProfileState();
}

class _CompanyProfileState extends State<CompanyProfile> {
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
          title: "Company Details",
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 10, left: 10, right: 10),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                children: [
                  _buildHeaderCard(context),
                  const SizedBox(height: 24),
                  _buildBasicInfo(context),
                  const SizedBox(height: 20),
                  _buildContactInfo(context),
                  const SizedBox(height: 20),
                  _buildAddressInfo(context),
                  const SizedBox(height: 20),
                  _buildGeofenceInfo(context),
                  const SizedBox(height: 20),
                  _buildKioskInfo(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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
                  imageUrl: widget.company.logoUrl ?? AppStrings.emptyProfilePhotoUrl,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    highlightColor: Theme.of(context).colorScheme.surface,
                    child: Container(color: Theme.of(context).colorScheme.surface),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 45,
                    width: 45,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.business,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
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
                      widget.company.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (widget.company.branchCode != null)
                      Text(
                        "Branch: ${widget.company.branchCode}",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 20,
                      runSpacing: 6,
                      children: [
                        if (widget.company.email != null)
                          _iconText(context, Icons.email, widget.company.email!),
                        if (widget.company.phone != null)
                          _iconText(context, Icons.phone, widget.company.phone!),
                        if (widget.company.gstin != null)
                          _iconText(context, Icons.numbers, widget.company.gstin!),
                      ],
                    ),
                  ],
                ),
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
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
      ],
    );
  }

  Widget _buildBasicInfo(BuildContext context) {
    final items = [
      {"label": "Company Name", "value": widget.company.name},
      {"label": "Branch Code", "value": widget.company.branchCode ?? "-"},
      {"label": "GSTIN", "value": widget.company.gstin ?? "-"},
      {"label": "Status", "value": widget.company.isActive ? "Active" : "Inactive"},
    ];

    return expandableSection(
      context: context,
      title: "Basic Information",
      icon: Icons.info_outline,
      initiallyExpanded: true,
      child: _infoGrid(context, items),
    );
  }

  Widget _buildContactInfo(BuildContext context) {
    final items = [
      {"label": "Email", "value": widget.company.email ?? "-"},
      {"label": "Phone", "value": widget.company.phone ?? "-"},
    ];

    return expandableSection(
      context: context,
      title: "Contact Information",
      icon: Icons.contact_phone,
      initiallyExpanded: false,
      child: _infoGrid(context, items),
    );
  }

  Widget _buildAddressInfo(BuildContext context) {
    final items = [
      {"label": "Address", "value": widget.company.address ?? "-"},
      {"label": "Country", "value": widget.company.country ?? "-"},
      {"label": "State", "value": widget.company.state ?? "-"},
      {"label": "City", "value": widget.company.city ?? "-"},
      {"label": "Pincode", "value": widget.company.pincode ?? "-"},
    ];

    return expandableSection(
      context: context,
      title: "Address Information",
      icon: Icons.location_on,
      initiallyExpanded: false,
      child: _infoGrid(context, items),
    );
  }

  Widget _buildGeofenceInfo(BuildContext context) {
    final items = [
      {"label": "Latitude", "value": widget.company.latitude?.toString() ?? "-"},
      {"label": "Longitude", "value": widget.company.longitude?.toString() ?? "-"},
      {"label": "Radius (meters)", "value": widget.company.radius.toString()},
    ];

    return expandableSection(
      context: context,
      title: "Geo-fencing Settings",
      icon: Icons.radar,
      initiallyExpanded: false,
      child: _infoGrid(context, items),
    );
  }

  Widget _buildKioskInfo(BuildContext context) {
    final items = [
      {"label": "Without Login", "value": widget.company.withoutLoginEnabled ? "Enabled" : "Disabled"},
      {"label": "Notification Language", "value": widget.company.notificationLanguage == 'en' ? "English" : "Tamil"},
      {"label": "Kiosk Username", "value": widget.company.kioskUsername ?? "-"},
    ];

    return expandableSection(
      context: context,
      title: "Kiosk Settings",
      icon: Icons.no_accounts,
      initiallyExpanded: false,
      child: _infoGrid(context, items),
    );
  }

  Widget expandableSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget child,
    bool initiallyExpanded = false,
  }) {
    return Container(
      decoration: _cardDecoration(),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.all(16),
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        initiallyExpanded: initiallyExpanded,
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        children: [child],
      ),
    );
  }

  Widget _infoGrid(BuildContext context, List<Map<String, dynamic>> items) {
    return LayoutBuilder(
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
    );
  }

  Widget _infoTile(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value.isEmpty ? "-" : value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ],
  );
}
