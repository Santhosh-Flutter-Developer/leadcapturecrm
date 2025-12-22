import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import '/theme/theme.dart';
import '/models/models.dart';
import '/services/services.dart';
import '/views/views.dart';

class DealsViewAppColors {
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

class DealsViewPage extends StatelessWidget {
  final DealModel deal;

  const DealsViewPage({super.key, required this.deal});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DealBloc()..add(StreamDealComments(deal.uid!)),
      child: DealsView(deal: deal),
    );
  }
}

class DealsView extends StatefulWidget {
  final DealModel deal;
  const DealsView({super.key, required this.deal});

  @override
  State<DealsView> createState() => _DealsViewState();
}

class _DealsViewState extends State<DealsView> with TickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<DealBloc>().add(StreamDealComments(widget.deal.uid!));
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

    context.read<DealBloc>().add(
      AddDealComment(dealUid: widget.deal.uid!, commentText: text),
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
        backgroundColor: DealsViewAppColors.grey100,
        appBar: FormWidgets.buildHeader(
          context: context,
          title: "Deal Details",
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
  //     backgroundColor: DealsViewAppColors.white,
  //     elevation: 1.0,
  //     shadowColor: AppColors.black12,
  //     automaticallyImplyLeading: false,
  //     foregroundColor: DealsViewAppColors.black,
  //     // leading: IconButton(
  //     //   onPressed: () {
  //     //     if (Navigator.canPop(context)) {
  //     //       Navigator.pop(context);
  //     //     }
  //     //   },
  //     //   icon: Icon(Icons.close, color: AppColors.black),
  //     // ),
  //     title: Text(
  //       "Deal Details",
  //       style: Theme.of(context).textTheme.titleLarge!.copyWith(
  //         color: DealsViewAppColors.primary,
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
            labelColor: DealsViewAppColors.primary,
            unselectedLabelColor: DealsViewAppColors.grey500,
            indicator: BoxDecoration(
              color: DealsViewAppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.user_tag, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "Deal Details",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.note_2, size: 18),
                    SizedBox(width: 8),
                    Text("Notes", style: Theme.of(context).textTheme.bodySmall),
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
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildDetailsTab(BuildContext context) {
    return _sectionCard(
      "Deal Information",
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
            color: DealsViewAppColors.grey200,
          ),
          Text("Company Info", style: _subHeaderStyle(context)),
          const SizedBox(height: 12),
          _buildGrid(_getCompanyInfo()),
          const Divider(
            height: 28,
            thickness: 1,
            color: DealsViewAppColors.grey200,
          ),
          Text("Deal Agent", style: _subHeaderStyle(context)),
          const SizedBox(height: 12),
          _buildAgentInfoContent(),
        ],
      ),
    );
  }

  TextStyle _subHeaderStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge!.copyWith(
      fontWeight: FontWeight.w600,
      color: DealsViewAppColors.black,
    );
  }

  Widget _buildCommentsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader("Comments", Iconsax.message),
            const Divider(
              height: 28,
              thickness: 1,
              color: DealsViewAppColors.grey200,
            ),
            TextField(
              controller: _commentController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: "Write a comment...",
                filled: true,
                fillColor: DealsViewAppColors.grey50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _addComment,
                icon: const Icon(Iconsax.save_2, size: 18),
                label: Text(
                  "Save",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            const SizedBox(height: 20),
            BlocBuilder<DealBloc, DealState>(
              builder: (context, state) {
                if (state is CommentsLoading) {
                  return WaitingLoading();
                } else if (state is DealCommentsError) {
                  return Text(
                    state.message,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.danger),
                  );
                } else if (state is DealCommentsLoaded) {
                  if (state.comments.isEmpty) {
                    return Center(
                      child: Text(
                        "No comments yet.",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: DealsViewAppColors.grey500,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: state.comments.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final comment = state.comments[index];
                      final timestamp = comment['createdAt'];
                      String formattedTime = "-";
                      if (timestamp != null) {
                        DateTime dateTime;
                        if (timestamp is Timestamp) {
                          dateTime = timestamp.toDate();
                        } else if (timestamp is DateTime) {
                          dateTime = timestamp;
                        } else {
                          dateTime =
                              DateTime.tryParse(timestamp.toString()) ??
                              DateTime.now();
                        }
                        formattedTime =
                            "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
                      }
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: DealsViewAppColors.grey50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              comment['comment'] ?? '',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: DealsViewAppColors.black,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              formattedTime,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.grey),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
                return Center(
                  child: Text(
                    "No comments.",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
            ),
          ],
        ),
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
            color: DealsViewAppColors.grey200,
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
            color: DealsViewAppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: DealsViewAppColors.primary, size: 20),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: DealsViewAppColors.primary,
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: DealsViewAppColors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: DealsViewAppColors.black.withValues(alpha: 0.05),
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
            backgroundColor: DealsViewAppColors.primary.withValues(alpha: 0.15),
            child: const Icon(
              Icons.person,
              size: 50,
              color: DealsViewAppColors.primary,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.deal.dealName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: DealsViewAppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.deal.companyName ?? '',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: DealsViewAppColors.grey500,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    _iconText(Icons.email_outlined, widget.deal.dealEmail),
                    _iconText(
                      Icons.attach_money,
                      "₹${widget.deal.dealValue.toStringAsFixed(2)}",
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

  Widget _iconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: DealsViewAppColors.primary),
        const SizedBox(width: 6),
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: DealsViewAppColors.grey500),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getProfileInfo(BuildContext context) {
    return [
      {"label": "Deal Email", "value": widget.deal.dealEmail},

      {
        "label": "Value",
        "value": "₹${widget.deal.dealValue.toStringAsFixed(2)}",
      },
      {
        "label": "Follow-Up Allowed",
        "value": widget.deal.allowFollowUp ? "Yes" : "No",
      },
      {"label": "Created By", "value": widget.deal.createdBy},
      {
        "label": "Created At",
        "value": widget.deal.createdAt.toLocal().toString().split('.')[0],
      },
      {
        "label": "Updated At",
        "value": widget.deal.updatedAt.toLocal().toString().split('.')[0],
      },
    ];
  }

  List<Map<String, dynamic>> _getCompanyInfo() {
    return [
      {"label": "Company Name", "value": widget.deal.companyName},
      {"label": "Website", "value": widget.deal.companyWebsite ?? "-"},
      {"label": "Mobile", "value": widget.deal.companyMobile ?? "-"},
      {"label": "Country", "value": widget.deal.companyCountry?.name ?? "-"},
      {"label": "State", "value": widget.deal.companyState?.name ?? "-"},
      {"label": "City", "value": widget.deal.companyCity?.name ?? "-"},
      {"label": "Postal Code", "value": widget.deal.companyZipCode ?? "-"},
      {"label": "Address", "value": widget.deal.companyAddress ?? "-"},
    ];
  }

  Widget _buildAgentInfoContent() {
    var employeeModel = CacheService.getUserByUid(widget.deal.createdBy.uid);
    var roleModel = CacheService.roleByUid(employeeModel?.role ?? '');
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: DealsViewAppColors.primary.withValues(alpha: 0.15),
          child: const Icon(
            Icons.person,
            size: 32,
            color: DealsViewAppColors.primary,
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
                color: DealsViewAppColors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              roleModel != null ? roleModel.name : 'N/A',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DealsViewAppColors.grey500,
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
            widget.deal.notes.isEmpty
                ? "No notes available."
                : widget.deal.notes,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: DealsViewAppColors.black,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 20),
          if (widget.deal.attachments.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.deal.attachments.map((file) {
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
                          color: DealsViewAppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          name,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: DealsViewAppColors.primary,
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
                color: DealsViewAppColors.grey500,
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
              color: DealsViewAppColors.grey500,
            ),
          ),
          const SizedBox(height: 6),
          valueWidget,
        ],
      ),
    );
  }
}
