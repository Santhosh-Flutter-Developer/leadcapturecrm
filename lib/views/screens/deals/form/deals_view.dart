import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:line_icons/line_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '/utils/utils.dart';
import '/models/models.dart';
import '/services/services.dart';
import '/views/views.dart';
import '/constants/constants.dart';

class DealsViewAppColors {
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

class DealsViewPage extends StatelessWidget {
  final DealModel deal;

  const DealsViewPage({super.key, required this.deal});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DealBloc()
        ..add(StreamDealComments(deal.uid!))
        ..add(StreamDealHistory(deal.uid!)),
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
  String? _currentUid;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    context.read<DealBloc>().add(
      AddDealComment(dealUid: widget.deal.uid!, commentText: text),
    );
    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Deal Management",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: DealsViewAppColors.textPrimary,
            fontSize: 18,
          ),
        ),
        actions: [
          if (_isAdmin || widget.deal.createdBy.uid == _currentUid) ...[
            _appBarButton(Iconsax.edit, "Edit", () {
              if (kIsMobile) {
                Sheet.showSheet(
                  context,
                  widget: DealEdit(uid: widget.deal.uid ?? ''),
                );
              } else {
                GeneralDialog.showRTLSheet(
                  context,
                  DealEdit(uid: widget.deal.uid ?? ''),
                );
              }
            }),
            const SizedBox(width: 8),
            _appBarButton(Iconsax.trash, "Delete", () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (context) => const ConfirmDialog(
                  title: 'Delete Deal',
                  content: 'Are you sure you want to delete this deal?',
                ),
              );

              if (result == true) {
                try {
                  await DealService.deleteDeal(uid: widget.deal.uid ?? '');
                  FlushBar.show(context, 'Deal deleted successfully');
                } catch (e, st) {
                  await ErrorService.recordError(e, st);
                  FlushBar.show(context, e.toString(), isSuccess: false);
                }
              }
            }, isDanger: true),
          ],
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: DealsViewAppColors.border, height: 1),
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
                  if (isWide)
                    Container(
                      width: 450,
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(color: DealsViewAppColors.border),
                        ),
                        color: DealsViewAppColors.white,
                      ),
                      child: _buildCommentsSection(),
                    ),
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
            ? DealsViewAppColors.danger
            : DealsViewAppColors.primary,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isDanger
              ? DealsViewAppColors.danger
              : DealsViewAppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildProfessionalHeader() {
    final status = CacheService.dealStatusByUid(widget.deal.dealStatus ?? '');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DealsViewAppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DealsViewAppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ─── AVATAR ───────────────────────────────
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: DealsViewAppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                widget.deal.dealName[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 32,
                  color: DealsViewAppColors.primary,
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
                /// NAME + STATUS
                Row(
                  children: [
                    Expanded(
                      child: Tooltip(
                        message: widget.deal.dealName,
                        child: Text(
                          widget.deal.dealName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: DealsViewAppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: _buildStatusBadge(status?.name ?? 'Unknown'),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                /// COMPANY
                Text(
                  widget.deal.companyName ?? 'Unspecified Company',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    color: DealsViewAppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 12),

                /// QUICK ACTIONS
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _quickAction(
                      Iconsax.call,
                      "Call",
                      () {
                        if (widget.deal.companyMobile?.isNotEmpty ?? false) {
                          launchUrl(
                            Uri.parse("tel:${widget.deal.companyMobile}"),
                          );
                        }
                      },
                      tooltip: widget.deal.companyMobile?.isNotEmpty ?? false
                          ? "Call ${widget.deal.companyMobile}"
                          : "No contact number available",
                    ),
                    _quickAction(
                      Iconsax.sms,
                      "Email",
                      () {},
                      tooltip: widget.deal.dealEmail.isNotEmpty
                          ? "Mail ${widget.deal.dealEmail}"
                          : "No contact mail available",
                    ),
                    _quickAction(
                      LineIcons.whatSApp,
                      "WA",
                      () {
                        if (widget.deal.companyMobile?.isNotEmpty ?? false) {
                          launchUrl(
                            Uri.parse("tel:${widget.deal.companyMobile}"),
                          );
                        }
                      },
                      color: Colors.green,
                      tooltip: widget.deal.dealEmail.isNotEmpty
                          ? "Message ${widget.deal.dealEmail}"
                          : "No contact number available",
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          /// ─── LEAD VALUE ───────────────────────────
          IntrinsicWidth(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: DealsViewAppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DealsViewAppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "Deal Value",
                    style: TextStyle(
                      color: DealsViewAppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),

                  /// AMOUNT SAFE RENDER
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "${widget.deal.companyCountry?.currencySymbol ?? '₹'}${NumberFormat('#,##,###').format(widget.deal.dealValue)}",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: DealsViewAppColors.textPrimary,
                      ),
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

  Widget _buildStatusBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: DealsViewAppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: DealsViewAppColors.success.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: DealsViewAppColors.success,
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
            color: DealsViewAppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: DealsViewAppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color ?? DealsViewAppColors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: DealsViewAppColors.textPrimary,
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
        border: Border(bottom: BorderSide(color: DealsViewAppColors.border)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: DealsViewAppColors.primary,
        unselectedLabelColor: DealsViewAppColors.textSecondary,
        indicatorColor: DealsViewAppColors.primary,
        indicatorWeight: 3,
        labelPadding: const EdgeInsets.symmetric(horizontal: 24),
        isScrollable: true,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        tabs: const [
          Tab(text: "Deal Profile"),
          Tab(text: "Files & Notes"),
          Tab(text: "History Log"),
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
          ],
        );
      },
    );
  }

  Widget _buildOverviewTab() {
    return Column(
      children: [
        _infoSection("Engagement Details", [
          _dataPoint(Iconsax.sms, "Email Address", widget.deal.dealEmail),
          _dataPoint(
            Iconsax.user_add,
            "Assigned Agent",
            widget.deal.createdBy.name,
          ),
          _dataPoint(
            Iconsax.calendar_1,
            "Capture Date",
            DateFormat('MMM dd, yyyy').format(widget.deal.createdAt),
          ),
        ]),
        const SizedBox(height: 16),
        _infoSection("Corporate Profile", [
          _dataPoint(
            Iconsax.buildings,
            "Company Name",
            widget.deal.companyName ?? 'N/A',
          ),
          _dataPoint(
            Iconsax.global,
            "Web Presence",
            widget.deal.companyWebsite ?? 'N/A',
            isLink: true,
          ),
          _dataPoint(
            Iconsax.call,
            "Business Contact",
            widget.deal.companyMobile ?? 'N/A',
          ),
          _dataPoint(
            Iconsax.location,
            "Office Location",
            "${widget.deal.companyCity?.name ?? 'Unknown'}, ${widget.deal.companyCountry?.name ?? 'Unknown'}",
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
        color: DealsViewAppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DealsViewAppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: DealsViewAppColors.textPrimary,
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
              color: DealsViewAppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: DealsViewAppColors.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: DealsViewAppColors.textSecondary,
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
                        ? DealsViewAppColors.primary
                        : DealsViewAppColors.textPrimary,
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
                color: DealsViewAppColors.textPrimary,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text(
                "Comments & Activity",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              _buildCommentCountIndicator(),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: BlocBuilder<DealBloc, DealState>(
            builder: (context, state) {
              if (state is DealDetailLoaded) {
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

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    final name = comment['createdBy']['name'] ?? 'System';
    final date = comment['createdAt'] != null
        ? (comment['createdAt'] as Timestamp).toDate()
        : DateTime.now();

    var userId = comment['createdBy']['uid'];
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
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: DealsViewAppColors.textPrimary,
                    ),
                  ),
                  Text(
                    DateFormat('MMM dd, hh:mm a').format(date),
                    style: const TextStyle(
                      color: DealsViewAppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                comment['comment'] ?? '',
                style: const TextStyle(
                  height: 1.5,
                  fontSize: 13,
                  color: DealsViewAppColors.textPrimary,
                ),
              ),
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
        color: DealsViewAppColors.white,
        border: const Border(top: BorderSide(color: DealsViewAppColors.border)),
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
                color: DealsViewAppColors.textSecondary,
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: DealsViewAppColors.background,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: _addComment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DealsViewAppColors.primary,
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
          Icon(icon, size: 48, color: DealsViewAppColors.border),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: DealsViewAppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DealsViewAppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DealsViewAppColors.border),
      ),
      child: BlocBuilder<DealBloc, DealState>(
        builder: (context, state) {
          if (state is DealDetailLoaded) {
            if (state.history.isEmpty) {
              return _emptyState(Iconsax.activity, "No activity logs yet");
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.history.length,
              itemBuilder: (context, index) => _buildTimelineItem(
                state.history[index],
                index == state.history.length - 1,
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildTimelineItem(DealHistoryModel history, bool isLast) {
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
                  color: DealsViewAppColors.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: DealsViewAppColors.primary,
                    width: 2,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 1, color: DealsViewAppColors.border),
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
                      color: DealsViewAppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Modified by ${CacheService.getUserByUid(history.userId)?.name ?? 'System'}",
                    style: const TextStyle(
                      color: DealsViewAppColors.textSecondary,
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
                      color: DealsViewAppColors.textSecondary,
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

  Widget _buildCommentCountIndicator() {
    return BlocBuilder<DealBloc, DealState>(
      builder: (context, state) {
        if (state is DealDetailLoaded) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: DealsViewAppColors.background,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: DealsViewAppColors.border),
            ),
            child: Text(
              state.comments.length.toString(),
              style: const TextStyle(
                color: DealsViewAppColors.textPrimary,
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
              widget.deal.notes.isEmpty
                  ? "No internal notes provided."
                  : widget.deal.notes,
              style: const TextStyle(
                fontSize: 14,
                height: 1.7,
                color: DealsViewAppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        _infoSection("Shared Attachments", [
          if (widget.deal.attachments.isEmpty)
            const Text(
              "No documents found.",
              style: TextStyle(
                color: DealsViewAppColors.textSecondary,
                fontSize: 13,
              ),
            )
          else
            ...widget.deal.attachments.map(
              (file) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: DealsViewAppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DealsViewAppColors.border),
                ),
                child: ListTile(
                  dense: true,
                  leading: const Icon(
                    Iconsax.document_text,
                    color: DealsViewAppColors.primary,
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
}
