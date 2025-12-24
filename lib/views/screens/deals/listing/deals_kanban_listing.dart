import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/theme/theme.dart';
import '/models/models.dart';
import '/services/services.dart';
import '/views/views.dart';
import '/utils/utils.dart';

class DealKanbanListing extends StatefulWidget {
  final List<DealModel> dealList;
  const DealKanbanListing({super.key, required this.dealList});

  @override
  State<DealKanbanListing> createState() => _DealKanbanListingState();
}

class _DealKanbanListingState extends State<DealKanbanListing> {
  late Future _future;
  late Map<DealStatusModel, List<DealModel>> _dealList;

  DealModel? _draggedDeal;
  DealStatusModel? _draggedFromList;

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
  void didUpdateWidget(covariant DealKanbanListing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dealList != widget.dealList) {
      _future = _initializeBoard();
      setState(() {});
    }
  }

  Future<void> _initializeBoard() async {
    _dealList = await DealService.getDealByGroup(dealList: widget.dealList);
  }

  void _handleDragStarted(DealModel task, DealStatusModel fromList) {
    setState(() {
      _draggedDeal = task;
      _draggedFromList = fromList;
    });
  }

  void _handleDragEnd(DraggableDetails details) {
    if (!details.wasAccepted &&
        _draggedDeal != null &&
        _draggedFromList != null) {
      setState(() {
        if (!_dealList[_draggedFromList]!.any(
          (t) => t.uid == _draggedDeal!.uid,
        )) {
          _dealList[_draggedFromList]!.add(_draggedDeal!);
        }
      });
    }
    setState(() {
      _draggedDeal = null;
      _draggedFromList = null;
    });
  }

  Future<void> _updateStatus(String dealUid, DealStatusModel dealStatus) async {
    try {
      futureLoading(context);
      await DealService.updateDealStatus(
        uid: dealUid,
        dealStatus: dealStatus.uid ?? '',
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
              physics: const BouncingScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _dealList.entries.map((entry) {
                  return _buildKanbanColumn(entry.key, entry.value);
                }).toList(),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildKanbanColumn(DealStatusModel list, List<DealModel> deals) {
    return DragTarget<DealModel>(
      onWillAcceptWithDetails: (details) => details.data.uid != null,
      onAcceptWithDetails: (details) async {
        final deal = details.data;
        if (_draggedFromList != list) {
          _dealList[_draggedFromList]!.removeWhere((t) => t.uid == deal.uid);
          setState(() {
            deals.add(deal);
          });
          await _updateStatus(deal.uid ?? '', list);
        }
      },
      builder: (context, candidateData, rejectedData) {
        bool isHovering = candidateData.isNotEmpty;
        double totalValue = deals.fold(
          0.0,
          (sum, item) => sum + item.dealValue,
        );

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 260,
          height: MediaQuery.of(context).size.height * 0.78,
          margin: const EdgeInsets.only(right: 12.0),
          decoration: BoxDecoration(
            color: isHovering
                ? Color(list.color).withValues(alpha: 0.1)
                : Color(list.color).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: isHovering ? AppColors.blue : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildKanbanColumnHeader(list, deals.length, totalValue),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 10,
                  ),
                  itemCount: deals.length,
                  itemBuilder: (context, index) {
                    return _buildKanbanCard(deals[index], list);
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
    DealStatusModel list,
    int count,
    double totalValue,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Color(list.color),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: AppColors.white,
          child: Text(
            _currencyFormat.format(totalValue),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: AppColors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKanbanCard(DealModel task, DealStatusModel list) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      // Use Draggable, but handle the click inside the child
      child: Draggable<DealModel>(
        data: task,
        // The feedback is what follows the finger
        feedback: Material(
          elevation: 8.0,
          borderRadius: BorderRadius.circular(12.0),
          color: Colors.transparent,
          child: Transform.rotate(
            angle: 0.05, // Slight tilt for pro feel
            child: Container(
              width: 244,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: AppColors.blue.withValues(alpha: 0.5),
                ),
              ),
              child: _buildCardContent(task),
            ),
          ),
        ),
        // The placeholder widget left in the list while dragging
        childWhenDragging: Opacity(
          opacity: 0.2,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.grey200,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        onDragStarted: () => _handleDragStarted(task, list),
        onDragEnd: _handleDragEnd,
        // The actual card in the list
        child: InkWell(
          onTap: () {
            // Open deal view page
            if (kIsDesktop) {
              GeneralDialog.showRTLSheet(context, DealsViewPage(deal: task));
            } else {
              Sheet.showSheet(context, widget: DealsViewPage(deal: task));
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12.0),
            child: _buildCardContent(task),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(DealModel deal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.blue100,
              child: Text(
                deal.dealName.isNotEmpty ? deal.dealName[0].toUpperCase() : '?',
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
                deal.dealName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
            ),
            if (deal.dealEmail.isNotEmpty || deal.companyMobile != null)
              const Icon(
                Icons.contact_mail_outlined,
                size: 12,
                color: AppColors.grey,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _currencyFormat.format(deal.dealValue),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.success,
                ),
              ),
            ),
            Text(
              DateFormat('dd MMM').format(deal.createdAt),
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.grey600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (deal.companyName != null && deal.companyName!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            deal.companyName!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.blue700,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}
