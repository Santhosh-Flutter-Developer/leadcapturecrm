import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:line_icons/line_icons.dart';
import 'package:mime/mime.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '/utils/utils.dart';
import '/models/models.dart';
import '/services/services.dart';
import '/views/views.dart';
import '/theme/theme.dart';
import '/constants/constants.dart';
import 'package:path/path.dart' as path;

class LeadsViewAppColors {
  static const Color primary = Color(0xFF2563EB);
  static const Color secondary = Color(0xFF64748B);
  static const Color background = Color(0xFFF8FAFC);
  static const Color white = Colors.white;
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  static const Color danger = Color(0xFFEF4444);
}

class LeadsViewPage extends StatelessWidget {
  final LeadModel lead;

  const LeadsViewPage({super.key, required this.lead});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LeadBloc()
        ..add(StreamLeadComments(lead.uid!))
        ..add(StreamLeadHistory(lead.uid!))
        ..add(StreamLeadActivities(lead.uid!)),
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
  String? _currentUid;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    var leadCategory = CacheService.leadCategoryByUid(widget.lead.leadCategory);
    widgetLeadCategory = leadCategory ?? LeadCategoryModel.fromEmptyMap();
    _tabController = TabController(length: 5, vsync: this);
    _loadOwnership();
  }

  Future<void> _loadOwnership() async {
    final uid = await Spdb.getUid();
    final isAdmin = await Spdb.isAdminLoggedIn();
    setState(() {
      _currentUid = uid;
      _isAdmin = isAdmin;
    });
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
    return Scaffold(
      backgroundColor: LeadsViewAppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: LeadsViewAppColors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Lead Management",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: LeadsViewAppColors.textPrimary,
            fontSize: 18,
          ),
        ),
        actions: [
          if (_isAdmin || widget.lead.createdBy.uid == _currentUid) ...[
            _appBarButton(Iconsax.edit, "Edit", () {
              if (kIsMobile) {
                Sheet.showSheet(
                  context,
                  widget: LeadEdit(uid: widget.lead.uid ?? ''),
                );
              } else {
                GeneralDialog.showRTLSheet(
                  context,
                  LeadEdit(uid: widget.lead.uid ?? ''),
                );
              }
            }),
            const SizedBox(width: 8),
            _appBarButton(Iconsax.trash, "Delete", () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (context) => const ConfirmDialog(
                  title: 'Delete Lead',
                  content: 'Are you sure you want to delete this lead?',
                ),
              );

              if (result != true) return;

              try {
                final deletedLead = widget.lead;
                final isUndoPressed = ValueNotifier(false);
                await LeadService.deleteLead(uid: widget.lead.uid ?? '');

                if (!mounted) return;

                FlushBar.show(
                  context,
                  'Lead deleted successfully',
                  actionLabel: 'UNDO',
                  onActionPressed: () async {
                    isUndoPressed.value = true;
                    await LeadService.restoreLead(deletedLead);

                    // refresh list
                    context.read<LeadBloc>().add(StreamLead());

                    Navigator.of(context).pop('restored');
                  },
                );
                // Future.delayed(const Duration(seconds: 4), () {
                // if (!isUndoPressed.value && mounted) {
                //   Navigator.of(context).pop('deleted');
                // }
                // });
              } catch (e, st) {
                await ErrorService.recordError(e, st);
                if (mounted) {
                  FlushBar.show(context, e.toString(), isSuccess: false);
                }
              }
            }, isDanger: true),
          ],
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: LeadsViewAppColors.border, height: 1),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 1000;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: isWide ? 7 : 1,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfessionalHeader(),
                          const SizedBox(height: 24),
                          _buildModernTabs(),
                          const SizedBox(height: 24),
                          _buildTabContent(),
                        ],
                      ),
                    ),
                  ),
                  // if (isWide)
                  //   Container(
                  //     width: 450,
                  //     decoration: const BoxDecoration(
                  //       border: Border(
                  //         left: BorderSide(color: LeadsViewAppColors.border),
                  //       ),
                  //       color: LeadsViewAppColors.white,
                  //     ),
                  //     child: _buildCommentsSection(),
                  //   ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _appBarButton(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isDanger = false,
  }) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(
        icon,
        size: 16,
        color: isDanger
            ? LeadsViewAppColors.danger
            : LeadsViewAppColors.primary,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isDanger
              ? LeadsViewAppColors.danger
              : LeadsViewAppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildProfessionalHeader() {
    final status = CacheService.leadStatusByUid(widget.lead.leadStatus);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine if we are on a small screen
        final bool isMobile = constraints.maxWidth < 600;

        return Container(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          decoration: BoxDecoration(
            color: LeadsViewAppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: LeadsViewAppColors.border),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// ─── AVATAR ───────────────────────────────
                  Container(
                    width: isMobile ? 60 : 80,
                    height: isMobile ? 60 : 80,
                    decoration: BoxDecoration(
                      color: LeadsViewAppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        widget.lead.leadName[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: isMobile ? 24 : 32,
                          color: LeadsViewAppColors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  /// ─── MAIN CONTENT ─────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              widget.lead.leadName,
                              style: TextStyle(
                                fontSize: isMobile ? 18 : 22,
                                fontWeight: FontWeight.w800,
                                color: LeadsViewAppColors.textPrimary,
                              ),
                            ),
                            _buildStatusBadge(status?.name ?? 'Unknown'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.lead.companyName ?? 'Unspecified Company',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            color: LeadsViewAppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        // On Desktop, Quick Actions stay here
                        if (!isMobile) ...[
                          const SizedBox(height: 12),
                          _buildActionsRow(),
                        ],
                      ],
                    ),
                  ),

                  // On Desktop, Lead Value stays on the top right
                  if (!isMobile) ...[
                    const SizedBox(width: 16),
                    _buildLeadValueCard(),
                  ],
                ],
              ),

              // On Mobile, Quick Actions and Lead Value stack below
              if (isMobile) ...[
                const SizedBox(height: 20),
                const Divider(height: 1, color: LeadsViewAppColors.border),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: _buildActionsRow()),
                    const SizedBox(width: 12),
                    _buildLeadValueCard(),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Helper to build the Action Buttons
  Widget _buildActionsRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _quickAction(
          Iconsax.call,
          "Call",
          () {
            if (widget.lead.companyMobile?.isNotEmpty ?? false) {
              launchUrl(Uri.parse("tel:${widget.lead.companyMobile}"));
            }
          },
          tooltip: widget.lead.companyMobile?.isNotEmpty ?? false
              ? "Call ${widget.lead.companyMobile}"
              : "No contact number available",
        ),
        _quickAction(
          Iconsax.sms,
          "Email",
          () {},
          tooltip: widget.lead.leadEmail.isNotEmpty
              ? "Mail ${widget.lead.leadEmail}"
              : "No contact mail available",
        ),
        _quickAction(
          LineIcons.whatSApp,
          "WA",
          () {},
          color: Colors.green,
          tooltip: "WhatsApp Message",
        ),
      ],
    );
  }

  /// Helper to build the Lead Value side-box
  Widget _buildLeadValueCard() {
    return IntrinsicWidth(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: LeadsViewAppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: LeadsViewAppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Lead Value",
              style: TextStyle(
                color: LeadsViewAppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "${widget.lead.companyCountry?.currencySymbol ?? '₹'}${NumberFormat('#,##,###').format(widget.lead.leadValue)}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: LeadsViewAppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: LeadsViewAppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: LeadsViewAppColors.success.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: LeadsViewAppColors.success,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _quickAction(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
    String? tooltip,
  }) {
    return InkWell(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: LeadsViewAppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: LeadsViewAppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color ?? LeadsViewAppColors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: LeadsViewAppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTabs() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: LeadsViewAppColors.border)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: LeadsViewAppColors.primary,
        unselectedLabelColor: LeadsViewAppColors.textSecondary,
        indicatorColor: LeadsViewAppColors.primary,
        indicatorWeight: 3,
        labelPadding: const EdgeInsets.symmetric(horizontal: 24),
        isScrollable: true,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        tabs: const [
          Tab(text: "Lead Profile"),
          Tab(text: "Files & Notes"),
          Tab(text: "History Log"),
          Tab(text: "Comments"),
          Tab(text: "Activities"),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        return IndexedStack(
          index: _tabController.index,
          children: [
            _buildOverviewTab(),
            _buildNotesTab(),
            _buildTimelineTab(),
            _buildCommentsTab(),
            _buildActivitiesTab(),
          ],
        );
      },
    );
  }

  Widget _buildOverviewTab() {
    return Column(
      children: [
        _infoSection("Engagement Details", [
          _dataPoint(Iconsax.sms, "Email Address", widget.lead.leadEmail),
          _dataPoint(Iconsax.category, "Lead Segment", widgetLeadCategory.name),
          _dataPoint(
            Iconsax.user_add,
            "Assigned Agent",
            widget.lead.createdBy.name,
          ),
          _dataPoint(
            Iconsax.calendar_1,
            "Capture Date",
            DateFormat('MMM dd, yyyy').format(widget.lead.createdAt),
          ),
        ]),
        const SizedBox(height: 16),
        _infoSection("Corporate Profile", [
          _dataPoint(
            Iconsax.buildings,
            "Company Name",
            widget.lead.companyName ?? 'N/A',
          ),
          _dataPoint(
            Iconsax.global,
            "Web Presence",
            widget.lead.companyWebsite ?? 'N/A',
            isLink: true,
          ),
          _dataPoint(
            Iconsax.call,
            "Business Contact",
            widget.lead.companyMobile ?? 'N/A',
          ),
          _dataPoint(
            Iconsax.location,
            "Office Location",
            "${widget.lead.companyCity?.name ?? 'Unknown'}, ${widget.lead.companyCountry?.name ?? 'Unknown'}",
          ),
        ]),
      ],
    );
  }

  Widget _infoSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: LeadsViewAppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LeadsViewAppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: LeadsViewAppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(spacing: 40, runSpacing: 24, children: children),
        ],
      ),
    );
  }

  Widget _dataPoint(
    IconData icon,
    String label,
    String value, {
    bool isLink = false,
  }) {
    return SizedBox(
      width: 280,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: LeadsViewAppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: LeadsViewAppColors.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: LeadsViewAppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isLink
                        ? LeadsViewAppColors.primary
                        : LeadsViewAppColors.textPrimary,
                    decoration: isLink ? TextDecoration.underline : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Row(
            children: [
              const Icon(
                Iconsax.message_text_1,
                color: LeadsViewAppColors.textPrimary,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text(
                "Comments ",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              _buildCommentCountIndicator(),
            ],
          ),
        ),
        const Divider(height: 1),

        SizedBox(
          height: 400,
          child: BlocBuilder<LeadBloc, LeadState>(
            builder: (context, state) {
              if (state is LeadDetailLoaded) {
                if (state.comments.isEmpty) {
                  return _emptyState(
                    Iconsax.message_minus,
                    "No comments found",
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: state.comments.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 32),
                  itemBuilder: (context, index) =>
                      _buildCommentItem(state.comments[index]),
                );
              }
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            },
          ),
        ),

        _buildCommentInputArea(),
      ],
    );
  }

  Widget _buildCommentItem(LeadCommentModel comment) {
    final name = comment.createdBy.name;
    final date = comment.timestamp;

    var userId = comment.createdBy.uid;
    var user = CacheService.getUserByUid(userId);

    UserDataModel userDataModel = UserDataModel.fromEmptyMap();
    if (user is AdminModel) {
      userDataModel = UserDataModel(
        uid: userId,
        name: user.name,
        desc: user.email,
        profilePic: user.profileImageUrl,
        userType: UserType.admin,
      );
    } else if (user is EmployeeModel) {
      userDataModel = UserDataModel(
        uid: userId,
        name: user.name,
        desc: user.email,
        profilePic: user.profileImageUrl,
        userType: UserType.employee,
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UserAvatar(userData: userDataModel),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: LeadsViewAppColors.textPrimary,
                          ),
                        ),
                        Text(
                          comment.comment,
                          style: const TextStyle(
                            height: 1.5,
                            fontSize: 13,
                            color: LeadsViewAppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('MMM dd, hh:mm a').format(date),
                        style: const TextStyle(
                          color: LeadsViewAppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          showMenu(
                            context: context,
                            color: Colors.white, // popup background
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            position: const RelativeRect.fromLTRB(
                              100,
                              100,
                              0,
                              0,
                            ),
                            items: [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: const [
                                    Icon(Icons.edit, size: 18),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.delete,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Delete'),
                                  ],
                                ),
                              ),
                            ],
                          ).then((value) {
                            if (value == 'edit') {
                              _editComment(comment);
                            } else if (value == 'delete') {
                              _deleteComment(comment);
                            }
                          });
                        },
                        child: Icon(
                          Iconsax.more,
                          color: LeadsViewAppColors.primary,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              if (comment.attachments.isNotEmpty) ...[
                const SizedBox(height: 12),
                AttachmentPreview(attachments: comment.attachments),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentInputArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LeadsViewAppColors.white,
        border: const Border(top: BorderSide(color: LeadsViewAppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _commentController,
            maxLines: 3,
            minLines: 1,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: "Add a comment...",
              hintStyle: const TextStyle(
                color: LeadsViewAppColors.textSecondary,
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: LeadsViewAppColors.background,
              contentPadding: const EdgeInsets.all(16),
              suffixIcon: IconButton(
                tooltip: 'Add Attachment',
                icon: Icon(Iconsax.document),
                onPressed: () {
                  _uploadFiles();
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: _addComment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LeadsViewAppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Post Comment",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: LeadsViewAppColors.border),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: LeadsViewAppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTab() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: LeadsViewAppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: LeadsViewAppColors.border),
        ),
        child: BlocBuilder<LeadBloc, LeadState>(
          builder: (context, state) {
            if (state is LeadDetailLoaded) {
              if (state.history.isEmpty) {
                return _emptyState(Iconsax.activity, "No activity logs yet");
              }

              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.55,
                child: ListView.builder(
                  itemCount: state.history.length,
                  itemBuilder: (context, index) => _buildTimelineItem(
                    state.history[index],
                    index == state.history.length - 1,
                  ),
                ),
              );
            }

            return const WaitingLoading();
          },
        ),
      ),
    );
  }

  Widget _buildTimelineItem(LeadHistoryModel history, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: LeadsViewAppColors.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: LeadsViewAppColors.primary,
                    width: 2,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 1, color: LeadsViewAppColors.border),
                ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    history.updateDisposition,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: LeadsViewAppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${CacheService.getUserByUid(history.userId)?.name ?? 'System'}",
                    style: const TextStyle(
                      color: LeadsViewAppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat(
                      'MMM dd, yyyy • hh:mm a',
                    ).format(history.timestamp),
                    style: const TextStyle(
                      color: LeadsViewAppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: LeadsViewAppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LeadsViewAppColors.border),
      ),
      child: _buildCommentsSection(),
    );
  }

  Widget _buildActivitiesTab() {
    return Container(
      // Match the padding and decoration of your _infoSection
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: LeadsViewAppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LeadsViewAppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ─── HEADER SECTION ───────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Activities",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: LeadsViewAppColors.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: _scheduleActivity,
                style: TextButton.styleFrom(
                  backgroundColor: LeadsViewAppColors.primary.withValues(
                    alpha: 0.1,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Iconsax.add, size: 18),
                label: const Text(
                  "Schedule",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          /// ─── CONTENT SECTION ──────────────────────────
          BlocBuilder<LeadBloc, LeadState>(
            builder: (context, state) {
              if (state is LeadDetailLoaded) {
                if (state.activities.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: _emptyState(
                      Iconsax.calendar,
                      "No activities scheduled yet",
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.activities.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (_, i) => _activityItem(state.activities[i]),
                );
              }
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: WaitingLoading(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _activityItem(LeadActivityModel activity) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LeadsViewAppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LeadsViewAppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: LeadsViewAppColors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _activityIcon(activity.type),
              color: LeadsViewAppColors.primary,
              size: 20,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: LeadsViewAppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Iconsax.clock,
                      size: 12,
                      color: LeadsViewAppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat(
                        'MMM dd • hh:mm a',
                      ).format(activity.scheduledAt),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: LeadsViewAppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              size: 18,
              color: LeadsViewAppColors.textSecondary,
            ),
            onSelected: (value) {
              if (value == 'edit') {
                _scheduleActivity(activity);
              } else if (value == 'delete') {
                context.read<LeadBloc>().add(
                  DeleteLeadActivity(
                    leadUid: widget.lead.uid!,
                    activityUid: activity.uid!,
                  ),
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCountIndicator() {
    return BlocBuilder<LeadBloc, LeadState>(
      builder: (context, state) {
        if (state is LeadDetailLoaded) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: LeadsViewAppColors.background,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: LeadsViewAppColors.border),
            ),
            child: Text(
              state.comments.length.toString(),
              style: const TextStyle(
                color: LeadsViewAppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildNotesTab() {
    return Column(
      children: [
        _infoSection("Internal Documentation", [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              widget.lead.notes.isEmpty
                  ? "No internal notes provided."
                  : widget.lead.notes,
              style: const TextStyle(
                fontSize: 14,
                height: 1.7,
                color: LeadsViewAppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        _infoSection("Shared Attachments", [
          if (widget.lead.attachments.isEmpty)
            const Text(
              "No documents found.",
              style: TextStyle(
                color: LeadsViewAppColors.textSecondary,
                fontSize: 13,
              ),
            )
          else
            ...widget.lead.attachments.map(
              (file) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: LeadsViewAppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: LeadsViewAppColors.border),
                ),
                child: ListTile(
                  dense: true,
                  leading: const Icon(
                    Iconsax.document_text,
                    color: LeadsViewAppColors.primary,
                    size: 20,
                  ),
                  title: Text(
                    file.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: const Text(
                    "External Resource",
                    style: TextStyle(fontSize: 11),
                  ),
                  trailing: const Icon(Iconsax.export_1, size: 16),
                  onTap: () {},
                ),
              ),
            ),
        ]),
      ],
    );
  }

  void _editComment(LeadCommentModel comment) {
    final TextEditingController controller = TextEditingController(
      text: comment.comment,
    );

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Edit",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.50,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Edit",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),

                  /// Textbox
                  FormFields(
                    controller: controller,
                    label: "Comment",
                    hintText: "Edit your comment here...",
                  ),

                  const SizedBox(height: 20),

                  /// Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("Cancel"),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          final value = controller.text.trim();

                          if (value.isNotEmpty) {
                            await LeadService.editLeadComment(
                              leadUid: widget.lead.uid ?? '',
                              commentUid: comment.uid ?? '',
                              commentText: value,
                            );
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LeadsViewAppColors.primary,
                        ),
                        child: Text(
                          "Submit",
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.white),
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

      /// Animation
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(opacity: anim1.value, child: child),
        );
      },
    );
  }

  IconData _activityIcon(LeadActivityType type) {
    switch (type) {
      case LeadActivityType.call:
        return Iconsax.call;
      case LeadActivityType.meeting:
        return Iconsax.video;
      case LeadActivityType.followUp:
        return Iconsax.refresh;
      case LeadActivityType.task:
        return Iconsax.task;
    }
  }

  void _deleteComment(LeadCommentModel comment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Comment"),
        content: const Text("Are you sure you want to delete this comment?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              "Delete",
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await LeadService.deleteLeadComment(
        leadUid: widget.lead.uid ?? '',
        commentUid: comment.uid ?? '',
      );
    }
  }

  void _uploadFiles() async {
    var files = await FilePick.pickFiles(context);

    if (files?.isNotEmpty ?? false) {
      final int count = files!.length;

      final bool? confirm = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.white, // 👈 force white background
            title: const Text(
              "Confirm Upload",
              style: TextStyle(color: Colors.black),
            ),
            content: Text(
              "Are you sure you want to upload these $count file${count > 1 ? 's' : ''}?",
              style: const TextStyle(color: Colors.black),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.black54),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: LeadsViewAppColors.primary,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  "Upload",
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.white),
                ),
              ),
            ],
          );
        },
      );

      if (confirm == true) {
        _startUpload(files);
      }
    }
  }

  void _startUpload(List<File> files) async {
    try {
      futureLoading(context);
      List<FileModel> attachments = [];

      if (files.isNotEmpty) {
        List<String> urls = await StorageService.uploadFilesInBatch(
          files: files,
          folder: StorageFolder.leadAttachments,
        );

        for (var i = 0; i < files.length; i++) {
          var file = files[i];
          var mimeType = lookupMimeType(file.path) ?? '';

          attachments.add(
            FileModel(
              name: path.basename(file.path),
              extension: path.extension(file.path).replaceAll('.', ''),
              size: file.lengthSync(),
              url: urls[i],
              mimeType: mimeType,
            ),
          );
        }
      }

      var user = await Spdb.getUser();

      LeadCommentModel leadCommentModel = LeadCommentModel(
        userId: user.uid,
        comment:
            "Added ${attachments.length} attachment${attachments.length > 1 ? 's' : ''}",
        attachments: attachments,
        timestamp: DateTime.now(),
        createdBy: user,
      );

      await LeadService.addLeadComment(
        leadUid: widget.lead.uid ?? '',
        comment: leadCommentModel,
      );
      Navigator.pop(context);
    } catch (e) {
      Navigator.pop(context);
      FlushBar.show(
        context,
        "Failed to upload files: ${e.toString()}",
        isSuccess: false,
      );
    }
  }

  void _scheduleActivity([LeadActivityModel? existing]) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<LeadBloc>(),
        child: ScheduleLeadActivityDialog(
          leadUid: widget.lead.uid!,
          existing: existing,
        ),
      ),
    );
  }
}

class ScheduleLeadActivityDialog extends StatefulWidget {
  final String leadUid;
  final LeadActivityModel? existing;

  const ScheduleLeadActivityDialog({
    super.key,
    required this.leadUid,
    this.existing,
  });

  @override
  State<ScheduleLeadActivityDialog> createState() =>
      _ScheduleLeadActivityDialogState();
}

class _ScheduleLeadActivityDialogState
    extends State<ScheduleLeadActivityDialog> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();

  LeadActivityType selectedType = LeadActivityType.call;

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      titleController.text = e.title;
      descController.text = e.description;
      selectedType = e.type;
      selectedDate = e.scheduledAt;
      selectedTime = TimeOfDay.fromDateTime(e.scheduledAt);
    }
  }

  DateTime? get scheduledDateTime {
    if (selectedDate == null || selectedTime == null) return null;

    return DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (date != null) {
      setState(() => selectedDate = date);
    }
  }

  Future<void> pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      setState(() => selectedTime = time);
    }
  }

  void saveActivity() {
    final scheduled = scheduledDateTime;

    if (titleController.text.isEmpty || scheduled == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fill all required fields")));
      return;
    }

    if (_isEditing) {
      final updated = LeadActivityModel(
        uid: widget.existing!.uid,
        title: titleController.text.trim(),
        description: descController.text.trim(),
        type: selectedType,
        scheduledAt: scheduled,
        createdBy: widget.existing!.createdBy,
        createdAt: widget.existing!.createdAt,
        completed: widget.existing!.completed,
      );
      context.read<LeadBloc>().add(
        EditLeadActivity(leadUid: widget.leadUid, activity: updated),
      );
    } else {
      final activity = LeadActivityModel(
        title: titleController.text.trim(),
        description: descController.text.trim(),
        type: selectedType,
        scheduledAt: scheduled,
        createdBy: "user",
        createdAt: DateTime.now(),
      );
      context.read<LeadBloc>().add(
        AddLeadActivity(leadUid: widget.leadUid, activity: activity),
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? "Edit Activity" : "Schedule Activity"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// TITLE
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),

            const SizedBox(height: 12),

            /// DESCRIPTION
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: "Description"),
            ),

            const SizedBox(height: 12),

            /// TYPE DROPDOWN
            DropdownButtonFormField<LeadActivityType>(
              initialValue: selectedType,
              items: LeadActivityType.values
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e.name.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => selectedType = v!),
              decoration: const InputDecoration(labelText: "Activity Type"),
            ),

            const SizedBox(height: 12),

            /// DATE
            ListTile(
              title: Text(
                selectedDate == null
                    ? "Select Date"
                    : selectedDate.toString().split(' ')[0],
              ),
              trailing: const Icon(Icons.calendar_month),
              onTap: pickDate,
            ),

            /// TIME
            ListTile(
              title: Text(
                selectedTime == null
                    ? "Select Time"
                    : selectedTime!.format(context),
              ),
              trailing: const Icon(Icons.access_time),
              onTap: pickTime,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(onPressed: saveActivity, child: const Text("Save")),
      ],
    );
  }
}
