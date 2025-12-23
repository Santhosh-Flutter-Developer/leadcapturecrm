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
    double totalValue = deals.fold(0.0, (sum, item) => sum + item.dealValue);

    return DragTarget<DealModel>(
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
              _buildKanbanColumnHeader(list, deals.length, totalValue),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(6.0),
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

  Widget _buildKanbanCard(DealModel task, DealStatusModel list) {
    return Draggable<DealModel>(
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

  Widget _buildCardContent(DealModel deal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 12, // Smallest avatar
              backgroundColor: AppColors.blue100,
              child: Text(
                deal.dealName.isNotEmpty
                    ? deal.dealName[0].capitalizeFirst
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
                deal.dealName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
            ),
            if (deal.dealEmail.isNotEmpty || deal.companyMobile != null) ...[
              const Icon(
                Icons.contact_mail_outlined,
                size: 12,
                color: AppColors.grey,
              ),
            ],
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
                _currencyFormat.format(deal.dealValue),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ),
            Text(
              DateFormat('dd MMM').format(deal.createdAt),
              style: const TextStyle(fontSize: 10, color: AppColors.grey),
            ),
          ],
        ),
        if (deal.companyName != null) ...[
          const SizedBox(height: 4),
          Text(
            deal.companyName!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.blue,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                UserAvatar(
                  userData: deal.createdBy,
                  showCrown: false,
                  size: 15,
                ),
                SizedBox(width: 4),
                Text(
                  deal.createdBy.name,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
