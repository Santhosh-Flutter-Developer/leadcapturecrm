import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:iconsax/iconsax.dart';
import '/services/services.dart';

class OrgChart extends StatefulWidget {
  final List<dynamic> rawData;
  const OrgChart({super.key, required this.rawData});

  @override
  State<OrgChart> createState() => _OrgChartState();
}

class _OrgChartState extends State<OrgChart> {
  final Graph graph = Graph()..isTree = false;

  // Switched to FruchtermanReingoldAlgorithm to resolve RangeError cycles
  final FruchtermanReingoldAlgorithm algorithm = FruchtermanReingoldAlgorithm(
    FruchtermanReingoldConfiguration(iterations: 200, repulsionPercentage: 1.5),
  );

  late Map<String, List<String>> reportingMap;
  final Map<String, Node> nodeCache = {};

  @override
  void initState() {
    super.initState();
    _initializeGraph();
  }

  void _initializeGraph() {
    reportingMap = normalize(widget.rawData);
    _buildGraph();
  }

  void _buildGraph() {
    for (final parent in reportingMap.keys) {
      final parentNode = _getNode(parent);

      for (final child in reportingMap[parent]!) {
        final childNode = _getNode(child);

        // Check if edge already exists to prevent duplicate edge errors
        graph.addEdge(
          parentNode,
          childNode,
          paint: Paint()
            ..color = Colors.blue.withValues(alpha: 0.3)
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke,
        );
      }
    }
  }

  Map<String, List<String>> normalize(List<dynamic> input) {
    final Map<String, List<String>> result = {};

    for (final item in input) {
      if (item is Map && item.isNotEmpty) {
        final entry = item.entries.first;
        final String parentId = entry.key.toString();
        final dynamic rawChildren = entry.value;

        if (rawChildren is Map) {
          result[parentId] = rawChildren.values
              .map((e) => e.toString())
              .toList();
        } else {
          result[parentId] = [];
        }
      }
    }
    return result;
  }

  Node _getNode(String id) {
    return nodeCache.putIfAbsent(id, () => Node.Id(id));
  }

  Widget _nodeWidget(String id) {
    return Container(
      constraints: const BoxConstraints(minWidth: 160),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: Colors.blue.shade500,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Iconsax.user, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  CacheService.getUserByUid(id)?.name ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF2D3748),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Member",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Workflow Hierarchy',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A202C),
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh, color: Colors.blue, size: 20),
            onPressed: () {
              setState(() {
                nodeCache.clear();
                graph.nodes.clear();
                graph.edges.clear();
                _initializeGraph();
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          InteractiveViewer(
            constrained: false,
            boundaryMargin: const EdgeInsets.all(500),
            minScale: 0.01,
            maxScale: 2.0,
            child: GraphView(
              graph: graph,
              algorithm: algorithm,
              paint: Paint()
                ..color = Colors.blue.shade100
                ..strokeWidth = 2
                ..style = PaintingStyle.stroke,
              builder: (Node node) {
                final dynamic value = node.key?.value;
                final String id = value?.toString() ?? "Unknown";
                return _nodeWidget(id);
              },
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Force-directed layout: Zoom & Pan enabled",
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
