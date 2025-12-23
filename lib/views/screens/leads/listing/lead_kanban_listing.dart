import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/theme/theme.dart';
import '/models/models.dart';
import '/services/services.dart';
import '/views/views.dart';
import '/utils/utils.dart';

class LeadKanbanListing extends StatefulWidget {
  final List<LeadModel> leadList;
  const LeadKanbanListing({super.key, required this.leadList});

  @override
  State<LeadKanbanListing> createState() => _LeadKanbanListingState();
}

class _LeadKanbanListingState extends State<LeadKanbanListing> {
  late Future _future;
  late Map<LeadStatusModel, List<LeadModel>> _leadList;

  LeadModel? _draggedLead;
  LeadStatusModel? _draggedFromList;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _future = _initializeBoard();
  }

  @override
  void didUpdateWidget(covariant LeadKanbanListing oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.leadList != widget.leadList) {
      _future = _initializeBoard();
      setState(() {});
    }
  }

  Future<void> _initializeBoard() async {
    _leadList = await LeadService.getLeadByGroup(leadList: widget.leadList);
  }

  void _handleDragStarted(LeadModel task, LeadStatusModel fromList) {
    setState(() {
      _draggedLead = task;
      _draggedFromList = fromList;
    });
  }

  void _handleDragEnd(DraggableDetails details) {
    if (!details.wasAccepted &&
        _draggedLead != null &&
        _draggedFromList != null) {
      setState(() {
        if (!_leadList[_draggedFromList]!.any(
          (t) => t.uid == _draggedLead!.uid,
        )) {
          _leadList[_draggedFromList]!.add(_draggedLead!);
        }
      });
    }
    setState(() {
      _draggedLead = null;
      _draggedFromList = null;
    });
  }

  Future<void> _updateStatus(String leadUid, LeadStatusModel leadStatus) async {
    try {
      futureLoading(context);
      await LeadService.updateLeadStatus(
        uid: leadUid,
        leadStatus: leadStatus.uid ?? '',
      );
      if (Navigator.canPop(context)) Navigator.pop(context);
      FlushBar.show(context, 'Status updated');
    } catch (e, st) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      debugPrint('$e, $st');
      await ErrorService.recordError(e, st);
      FlushBar.show(context, e.toString(), isSuccess: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const WaitingLoading();
        } else if (snapshot.hasError) {
          return ErrorDisplay(error: snapshot.error.toString());
        } else {
          return Container(
            color: const Color(0xFFF3F4F6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _leadList.entries.map((entry) {
                  return _buildKanbanColumn(entry.key, entry.value);
                }).toList(),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildKanbanColumn(LeadStatusModel list, List<LeadModel> leads) {
    double totalValue = leads.fold(0.0, (sum, item) => sum + item.leadValue);

    return DragTarget<LeadModel>(
      onAcceptWithDetails: (details) async {
        final lead = details.data;
        if (_draggedFromList != list) {
          _leadList[_draggedFromList]!.removeWhere((t) => t.uid == lead.uid);
          setState(() {
            leads.add(lead);
          });
          await _updateStatus(lead.uid ?? '', list);
        }
      },
      builder: (context, candidateData, rejectedData) {
        bool isHovering = candidateData.isNotEmpty;

        return Container(
          width: 260, // Smaller column width
          height: MediaQuery.of(context).size.height * 0.78,
          margin: const EdgeInsets.only(right: 12.0),
          decoration: BoxDecoration(
            color: Color(list.color).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: isHovering ? AppColors.blue : AppColors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildKanbanColumnHeader(list, leads.length, totalValue),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(6.0),
                  itemCount: leads.length,
                  itemBuilder: (context, index) {
                    return _buildKanbanCard(leads[index], list);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKanbanColumnHeader(
    LeadStatusModel list,
    int count,
    double totalValue,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Color(list.color),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  list.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          color: AppColors.white,
          child: Text(
            _currencyFormat.format(totalValue),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppColors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKanbanCard(LeadModel task, LeadStatusModel list) {
    return Draggable<LeadModel>(
      data: task,
      feedback: Material(
        elevation: 4.0,
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          width: 248,
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: _buildCardContent(task),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: Card(
          margin: const EdgeInsets.only(bottom: 6),
          color: AppColors.grey200,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: const SizedBox(height: 50),
        ),
      ),
      onDragStarted: () => _handleDragStarted(task, list),
      onDragEnd: _handleDragEnd,
      child: Card(
        margin: const EdgeInsets.only(bottom: 6.0),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        color: AppColors.white,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: _buildCardContent(task),
        ),
      ),
    );
  }

  Widget _buildCardContent(LeadModel lead) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 12, // Smallest avatar
              backgroundColor: AppColors.blue100,
              child: Text(
                lead.leadName.isNotEmpty
                    ? lead.leadName[0].capitalizeFirst
                    : '',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blue700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                lead.leadName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
            ),
            if (lead.leadEmail.isNotEmpty || lead.companyMobile != null)
              const Icon(
                Icons.contact_mail_outlined,
                size: 12,
                color: AppColors.grey,
              ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _currencyFormat.format(lead.leadValue),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ),
            Text(
              DateFormat('dd MMM').format(lead.createdAt),
              style: const TextStyle(fontSize: 10, color: AppColors.grey),
            ),
          ],
        ),
        if (lead.companyName != null) ...[
          const SizedBox(height: 4),
          Text(
            lead.companyName!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.blue,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}
