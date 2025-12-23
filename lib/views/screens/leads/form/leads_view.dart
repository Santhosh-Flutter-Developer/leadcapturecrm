import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import '/models/models.dart';
import '/services/services.dart';
import '/theme/theme.dart';
import '/views/views.dart';

class LeadsViewAppColors {
  static const Color primary = Color(0xFF3B82F6);
  static const Color white = AppColors.white;
  static const Color black = AppColors.black87;
  static const Color info = AppColors.blue;
  static const Color warning = AppColors.orange;
  static const Color success = AppColors.success;

  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey500 = AppColors.grey;
}

class LeadsViewPage extends StatelessWidget {
  final LeadModel lead;

  const LeadsViewPage({super.key, required this.lead});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LeadBloc()
        ..add(StreamLeadComments(lead.uid!))
        ..add(StreamLeadHistory(lead.uid!)),
      child: LeadsView(lead: lead),
    );
  }
}

class LeadsView extends StatefulWidget {
  final LeadModel lead;
  const LeadsView({super.key, required this.lead});

  @override
  State<LeadsView> createState() => _LeadsViewState();
}

class _LeadsViewState extends State<LeadsView> with TickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  late LeadCategoryModel widgetLeadCategory;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    widgetLeadCategory = CacheService.leadCategoryByUid(
      widget.lead.leadCategory,
    )!;

    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _addComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    context.read<LeadBloc>().add(
      AddLeadComment(leadUid: widget.lead.uid!, commentText: text),
    );

    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        bottomLeft: Radius.circular(16),
      ),
      child: Scaffold(
        backgroundColor: LeadsViewAppColors.grey100,
        appBar: FormWidgets.buildHeader(
          context: context,
          title: "Lead Details",
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1250),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;
                  return Flex(
                    direction: isWide ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        flex: 2,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(context),
                              const SizedBox(height: 24),
                              _buildInfoTabs(context),
                            ],
                          ),
                        ),
                      ),
                      if (isWide) const SizedBox(width: 24),
                      if (!isWide) const SizedBox(height: 24),
                      Flexible(flex: 1, child: _buildCommentsSection(context)),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // PreferredSizeWidget _buildHeaderBar(BuildContext context) {
  //   return AppBar(
  //     backgroundColor: LeadsViewAppColors.white,
  //     elevation: 1.0,
  //     shadowColor: AppColors.black12,
  //     automaticallyImplyLeading: false,
  //     foregroundColor: LeadsViewAppColors.black,
  //     // leading: IconButton(
  //     //   onPressed: () {
  //     //     if (Navigator.canPop(context)) {
  //     //       Navigator.pop(context);
  //     //     }
  //     //   },
  //     //   icon: Icon(Icons.close, color: AppColors.black),
  //     // ),
  //     title: Text(
  //       "Lead Details",
  //       style: Theme.of(context).textTheme.titleLarge!.copyWith(
  //         color: LeadsViewAppColors.primary,
  //         fontWeight: FontWeight.bold,
  //       ),
  //     ),
  //   );
  // }

  Widget _buildInfoTabs(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: _cardDecoration(),
          child: TabBar(
            controller: _tabController,
            labelColor: LeadsViewAppColors.primary,
            unselectedLabelColor: LeadsViewAppColors.grey500,
            indicator: BoxDecoration(
              color: LeadsViewAppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.user_tag, size: 18),
                    SizedBox(width: 8),
                    Text("Lead Details"),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.note_2, size: 18),
                    SizedBox(width: 8),
                    Text("Notes"),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.activity, size: 18),
                    SizedBox(width: 8),
                    Text("History"),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AnimatedBuilder(
          animation: _tabController,
          builder: (context, child) {
            return IndexedStack(
              index: _tabController.index,
              children: [
                _buildDetailsTab(context),
                _buildNotesAndAttachments(context),
                _buildHistorySection(),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildDetailsTab(BuildContext context) {
    return _sectionCard(
      "Lead Information",
      Iconsax.user_tag,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Profile Info", style: _subHeaderStyle(context)),
          const SizedBox(height: 12),
          _buildGrid(_getProfileInfo(context)),
          const Divider(
            height: 28,
            thickness: 1,
            color: LeadsViewAppColors.grey200,
          ),
          Text("Company Info", style: _subHeaderStyle(context)),
          const SizedBox(height: 12),
          _buildGrid(_getCompanyInfo()),
          const Divider(
            height: 28,
            thickness: 1,
            color: LeadsViewAppColors.grey200,
          ),
          Text("Lead Agent", style: _subHeaderStyle(context)),
          const SizedBox(height: 12),
          _buildAgentInfoContent(),
        ],
      ),
    );
  }

  TextStyle _subHeaderStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
      fontWeight: FontWeight.w600,
      color: LeadsViewAppColors.black,
    );
  }

  Widget _buildCommentsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader("Comments", Iconsax.message),
          const Divider(
            height: 28,
            thickness: 1,
            color: LeadsViewAppColors.grey200,
          ),
          TextField(
            controller: _commentController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: "Write a comment...",
              filled: true,
              fillColor: LeadsViewAppColors.grey50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder(
            valueListenable: _commentController,
            builder: (context, TextEditingValue value, _) {
              return ElevatedButton.icon(
                onPressed: value.text.trim().isEmpty ? null : _addComment,
                icon: const Icon(Iconsax.save_2, size: 18),
                label: const Text("Save"),
              );
            },
          ),
          const SizedBox(height: 20),

          /// Make comments scrollable
          Expanded(
            child: BlocBuilder<LeadBloc, LeadState>(
              builder: (context, state) {
                if (state is LeadDetailLoaded) {
                  final comments = state.comments;

                  if (comments.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline,
                            size: 40,
                            color: AppColors.grey,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "No comments yet",
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: comments.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final comment = comments[index];

                      final createdBy = comment['createdBy'];
                      String authorName = 'Unknown';
                      if (createdBy is Map<String, dynamic>) {
                        authorName = createdBy['name'] ?? 'Unknown';
                      }

                      final timestamp = comment['createdAt'];
                      DateTime dateTime = DateTime.now();
                      if (timestamp is Timestamp) {
                        dateTime = timestamp.toDate();
                      } else if (timestamp is DateTime) {
                        dateTime = timestamp;
                      }

                      final formattedTime =
                          "${dateTime.day.toString().padLeft(2, '0')}/"
                          "${dateTime.month.toString().padLeft(2, '0')}/"
                          "${dateTime.year} "
                          "${dateTime.hour.toString().padLeft(2, '0')}:"
                          "${dateTime.minute.toString().padLeft(2, '0')}";

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: LeadsViewAppColors.primary
                                .withValues(alpha: 0.15),
                            child: Text(
                              authorName[0].toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: LeadsViewAppColors.grey50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: LeadsViewAppColors.grey200,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    authorName,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(comment['comment']),
                                  const SizedBox(height: 6),
                                  Text(
                                    formattedTime,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: AppColors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                }

                if (state is LeadDetailError) {
                  return Center(
                    child: Text(
                      state.message,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.danger),
                    ),
                  );
                }

                return const Center(child: WaitingLoading());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return _sectionCard(
      "History",
      Iconsax.activity,
      BlocBuilder<LeadBloc, LeadState>(
        builder: (context, state) {
          if (state is LeadDetailLoaded) {
            final history = state.history;

            if (history.isEmpty) {
              return Text(
                "No history available.",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: LeadsViewAppColors.grey500,
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: history.map((h) {
                final date = h.timestamp;
                final performedBy = h.userId;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: LeadsViewAppColors.grey50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: LeadsViewAppColors.grey200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        h.updateDisposition,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Iconsax.user,
                            size: 14,
                            color: LeadsViewAppColors.grey500,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            performedBy,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: LeadsViewAppColors.grey500),
                          ),
                          const Spacer(),
                          Text(
                            "${date.day.toString().padLeft(2, '0')}/"
                            "${date.month.toString().padLeft(2, '0')}/"
                            "${date.year}",
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: LeadsViewAppColors.grey500),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          }

          if (state is LeadDetailError) {
            return Text(
              state.message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.danger),
            );
          }

          return const Center(child: WaitingLoading());
        },
      ),
    );
  }

  Widget _sectionCard(String title, IconData icon, Widget child) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(title, icon),
          const Divider(
            height: 28,
            thickness: 1,
            color: LeadsViewAppColors.grey200,
          ),
          child,
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: LeadsViewAppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: LeadsViewAppColors.primary, size: 20),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: LeadsViewAppColors.primary,
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: LeadsViewAppColors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: LeadsViewAppColors.black.withValues(alpha: 0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: LeadsViewAppColors.primary.withValues(alpha: 0.15),
            child: const Icon(
              Icons.person,
              size: 50,
              color: LeadsViewAppColors.primary,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.lead.leadName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: LeadsViewAppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.lead.companyName ?? '',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: LeadsViewAppColors.grey500,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    _iconText(Icons.email_outlined, widget.lead.leadEmail),
                    _iconText(Icons.source, widgetLeadCategory.name),
                    _iconText(
                      Icons.category_outlined,
                      CacheService.leadStatusByUid(
                            widget.lead.leadStatus,
                          )?.name ??
                          '',
                    ),
                    _iconText(
                      Icons.attach_money,
                      "₹${widget.lead.leadValue.toStringAsFixed(2)}",
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(BuildContext context, String status) {
    final lower = status.toLowerCase();

    final Color backgroundColor = lower.contains('in progress')
        ? LeadsViewAppColors.info
        : lower.contains('pending')
        ? LeadsViewAppColors.warning
        : lower.contains('completed')
        ? LeadsViewAppColors.success
        : LeadsViewAppColors.grey500;

    final bool isLight = backgroundColor.computeLuminance() > 0.5;
    final Color textColor = isLight
        ? LeadsViewAppColors.black
        : LeadsViewAppColors.white;

    return Theme(
      data: Theme.of(context).copyWith(
        chipTheme: Theme.of(context).chipTheme.copyWith(
          side: BorderSide.none,
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      child: Chip(
        label: Text(
          status,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: LeadsViewAppColors.primary),
        const SizedBox(width: 6),
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: LeadsViewAppColors.grey500),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getProfileInfo(BuildContext context) {
    return [
      {"label": "Lead Email", "value": widget.lead.leadEmail},
      {"label": "Source", "value": widgetLeadCategory.name},
      {
        "label": "Status",
        "value": _statusChip(
          context,
          CacheService.leadStatusByUid(widget.lead.leadStatus)?.name ?? '',
        ),
      },
      {"label": "Category", "value": widgetLeadCategory.name},
      {
        "label": "Value",
        "value": "₹${widget.lead.leadValue.toStringAsFixed(2)}",
      },
      {
        "label": "Follow-Up Allowed",
        "value": widget.lead.allowFollowUp ? "Yes" : "No",
      },
      {"label": "Created By", "value": widget.lead.createdBy},
      {
        "label": "Created At",
        "value": widget.lead.createdAt.toLocal().toString().split('.')[0],
      },
      {
        "label": "Updated At",
        "value": widget.lead.updatedAt.toLocal().toString().split('.')[0],
      },
    ];
  }

  List<Map<String, dynamic>> _getCompanyInfo() {
    return [
      {"label": "Company Name", "value": widget.lead.companyName},
      {"label": "Website", "value": widget.lead.companyWebsite ?? "-"},
      {"label": "Mobile", "value": widget.lead.companyMobile ?? "-"},
      {"label": "Country", "value": widget.lead.companyCountry?.name ?? "-"},
      {"label": "State", "value": widget.lead.companyState?.name ?? "-"},
      {"label": "City", "value": widget.lead.companyCity?.name ?? "-"},
      {"label": "Postal Code", "value": widget.lead.companyZipCode ?? "-"},
      {"label": "Address", "value": widget.lead.companyAddress ?? "-"},
    ];
  }

  Widget _buildAgentInfoContent() {
    var employeeModel = CacheService.getUserByUid(widget.lead.createdBy.uid);
    var roleModel = CacheService.roleByUid(employeeModel?.role ?? '');
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: LeadsViewAppColors.primary.withValues(alpha: 0.15),
          child: const Icon(
            Icons.person,
            size: 32,
            color: LeadsViewAppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              employeeModel != null ? employeeModel.name : 'N/A',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: LeadsViewAppColors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              roleModel != null ? roleModel.name : 'N/A',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: LeadsViewAppColors.grey500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesAndAttachments(BuildContext context) {
    return _sectionCard(
      "Notes & Attachments",
      Iconsax.note_2,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.lead.notes.isEmpty
                ? "No notes available."
                : widget.lead.notes,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: LeadsViewAppColors.black,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 20),
          if (widget.lead.attachments.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.lead.attachments.map((file) {
                final name = file.name;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: () async {
                      if (await canLaunchUrl(Uri.parse(file.url))) {
                        await launchUrl(
                          Uri.parse(file.url),
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    child: Row(
                      children: [
                        const Icon(
                          Icons.attach_file,
                          size: 18,
                          color: LeadsViewAppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          name,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: LeadsViewAppColors.primary,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            )
          else
            Text(
              "No attachments added.",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: LeadsViewAppColors.grey500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<Map<String, dynamic>> info) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 800
            ? 3
            : constraints.maxWidth > 500
            ? 2
            : 1;

        return Wrap(
          spacing: 20,
          runSpacing: 12,
          children: info.map((item) {
            final label = item["label"]?.toString() ?? '';
            final value = item["value"];

            return SizedBox(
              width: (constraints.maxWidth / crossCount) - 24,
              child: _infoTile(
                label,
                value is Widget ? value : Text(value?.toString() ?? '-'),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _infoTile(String label, Widget valueWidget) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: LeadsViewAppColors.grey500,
            ),
          ),
          const SizedBox(height: 6),
          valueWidget,
        ],
      ),
    );
  }
}
