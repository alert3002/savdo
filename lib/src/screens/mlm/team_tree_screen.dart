import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/search/product_search_controller.dart' show apiClientProvider;
import '../../ui/navigation/shop_layer_app_bar.dart';

class TeamTreeNode {
  const TeamTreeNode({
    required this.id,
    required this.parentId,
    required this.level,
    required this.fullName,
    required this.phoneLast4,
    required this.bonusBalance,
  });

  final String id;
  final String? parentId;
  final int level;
  final String fullName;
  final String phoneLast4;
  final String bonusBalance;

  factory TeamTreeNode.fromJson(Map<String, dynamic> json) {
    return TeamTreeNode(
      id: (json['id'] ?? '').toString(),
      parentId: json['parent_id']?.toString(),
      level: (json['level'] as num?)?.toInt() ?? 0,
      fullName: (json['full_name'] ?? '').toString(),
      phoneLast4: (json['phone_last4'] ?? '').toString(),
      bonusBalance: (json['bonus_balance'] ?? '0.00').toString(),
    );
  }
}

final teamTreeProvider = FutureProvider<List<TeamTreeNode>>((ref) async {
  final token = ref.watch(authControllerProvider).accessToken;
  if (token == null || token.isEmpty) return const [];

  final api = ref.watch(apiClientProvider);
  try {
    final decoded = await api.getJsonAny(
      '/api/v1/mlm/tree/',
      bearerToken: token,
    );
    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(TeamTreeNode.fromJson)
          .toList(growable: false);
    }
    if (decoded is Map<String, dynamic>) {
      final raw = decoded['results'];
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map(TeamTreeNode.fromJson)
            .toList(growable: false);
      }
    }
    return const [];
  } on ApiException catch (e) {
    if (e.statusCode == 401) {
      await ref.read(authControllerProvider.notifier).logout();
      return const [];
    }
    rethrow;
  }
});

class TeamTreeScreen extends ConsumerWidget {
  const TeamTreeScreen({super.key});

  Future<void> _showNodePopup(BuildContext context, TeamTreeNode n) async {
    final name = n.fullName.trim().isEmpty ? 'Пользователь' : n.fullName.trim();
    final last4 = n.phoneLast4.trim().isEmpty ? '—' : n.phoneLast4.trim();
    final balance = n.bonusBalance;

    await showDialog<void>(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        return AlertDialog(
          title: Text(name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Телефон: ****$last4',
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Баланс: $balance TJS',
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
    );
  }

  _TreeLayout _layoutTree(List<TeamTreeNode> nodes) {
    final byId = <String, _LayoutNode>{};
    for (final n in nodes) {
      byId[n.id] = _LayoutNode(n);
    }
    for (final n in nodes) {
      final me = byId[n.id]!;
      final pid = n.parentId;
      final parent = pid == null ? null : byId[pid];
      me.parent = parent;
      parent?.children.add(me);
    }

    // Root = level==0 if present, else first node without parent, else first node.
    _LayoutNode root =
        byId.values.firstWhere((x) => x.node.level == 0, orElse: () {
      return byId.values.firstWhere((x) => x.parent == null,
          orElse: () => byId.values.first);
    });

    // Ensure stable child order: keep API order (already in lft order).
    // (children list is appended in input order)

    double nextX = 0;
    void dfs(_LayoutNode cur, int depth) {
      cur.depth = depth;
      if (cur.children.isEmpty) {
        cur.prelim = nextX;
        nextX += 1;
        return;
      }
      for (final c in cur.children) {
        dfs(c, depth + 1);
      }
      final first = cur.children.first.prelim;
      final last = cur.children.last.prelim;
      cur.prelim = (first + last) / 2.0;
    }

    dfs(root, 0);

    // Collect all nodes reachable from root.
    final ordered = <_LayoutNode>[];
    void collect(_LayoutNode cur) {
      ordered.add(cur);
      for (final c in cur.children) {
        collect(c);
      }
    }

    collect(root);

    // Normalize x so minimum is 0.
    double minPrelim = ordered.first.prelim;
    double maxPrelim = ordered.first.prelim;
    int maxDepth = ordered.first.depth;
    for (final n in ordered) {
      if (n.prelim < minPrelim) minPrelim = n.prelim;
      if (n.prelim > maxPrelim) maxPrelim = n.prelim;
      if (n.depth > maxDepth) maxDepth = n.depth;
    }

    const nodeW = 180.0;
    const nodeH = 62.0;
    const hGap = 38.0;
    const vGap = 48.0;
    const margin = 24.0;

    final dx = nodeW + hGap;
    final dy = nodeH + vGap;

    for (final n in ordered) {
      final x = (n.prelim - minPrelim) * dx + margin;
      final y = n.depth * dy + margin;
      n.offset = Offset(x, y);
    }

    final width = ((maxPrelim - minPrelim) * dx) + nodeW + margin * 2;
    final height = (maxDepth * dy) + nodeH + margin * 2;

    return _TreeLayout(
      root: root,
      nodes: ordered,
      nodeSize: const Size(nodeW, nodeH),
      canvasSize: Size(width, height),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tree = ref.watch(teamTreeProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Дерево команды'),
        actions: shopLayerAppBarActions(context),
      ),
      body: tree.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (nodes) {
          if (nodes.isEmpty) {
            return const Center(child: Text('Команда пока пустая.'));
          }

          final layout = _layoutTree(nodes);
          final nodeSize = layout.nodeSize;

          return InteractiveViewer(
            minScale: 0.6,
            maxScale: 2.4,
            boundaryMargin: const EdgeInsets.all(140),
            child: SizedBox(
              width: layout.canvasSize.width,
              height: layout.canvasSize.height,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _TreeLinesPainter(
                        nodes: layout.nodes,
                        nodeSize: nodeSize,
                        color: scheme.outlineVariant.withValues(alpha: 0.55),
                        highlight: scheme.primary.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                  for (final n in layout.nodes)
                    Positioned(
                      left: n.offset.dx,
                      top: n.offset.dy,
                      width: nodeSize.width,
                      height: nodeSize.height,
                      child: _TreeNodeCard(
                        node: n.node,
                        isRoot: n.node.level == 0,
                        onTap: () => _showNodePopup(context, n.node),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LayoutNode {
  _LayoutNode(this.node);

  final TeamTreeNode node;
  _LayoutNode? parent;
  final List<_LayoutNode> children = <_LayoutNode>[];

  // layout fields
  double prelim = 0;
  int depth = 0;
  Offset offset = Offset.zero;
}

class _TreeLayout {
  const _TreeLayout({
    required this.root,
    required this.nodes,
    required this.nodeSize,
    required this.canvasSize,
  });

  final _LayoutNode root;
  final List<_LayoutNode> nodes;
  final Size nodeSize;
  final Size canvasSize;
}

class _TreeLinesPainter extends CustomPainter {
  _TreeLinesPainter({
    required this.nodes,
    required this.nodeSize,
    required this.color,
    required this.highlight,
  });

  final List<_LayoutNode> nodes;
  final Size nodeSize;
  final Color color;
  final Color highlight;

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final strong = Paint()
      ..color = highlight
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke;

    final r = 10.0;

    for (final n in nodes) {
      final p = n.parent;
      if (p == null) continue;

      final parentCenter = Offset(
        p.offset.dx + nodeSize.width / 2,
        p.offset.dy + nodeSize.height,
      );
      final childCenter = Offset(
        n.offset.dx + nodeSize.width / 2,
        n.offset.dy,
      );

      // Draw as a smooth elbow: down from parent, then to child.
      final midY = (parentCenter.dy + childCenter.dy) / 2;
      final path = Path()
        ..moveTo(parentCenter.dx, parentCenter.dy)
        ..lineTo(parentCenter.dx, midY - r)
        ..quadraticBezierTo(parentCenter.dx, midY, parentCenter.dx + (childCenter.dx - parentCenter.dx) * 0.15, midY)
        ..lineTo(childCenter.dx - (childCenter.dx - parentCenter.dx) * 0.15, midY)
        ..quadraticBezierTo(childCenter.dx, midY, childCenter.dx, midY + r)
        ..lineTo(childCenter.dx, childCenter.dy);

      canvas.drawPath(path, base);

      // Emphasize edges from root slightly.
      if ((p.node.level == 0)) {
        canvas.drawPath(path, strong);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TreeLinesPainter oldDelegate) {
    return oldDelegate.nodes != nodes ||
        oldDelegate.nodeSize != nodeSize ||
        oldDelegate.color != color ||
        oldDelegate.highlight != highlight;
  }
}

class _TreeNodeCard extends StatelessWidget {
  const _TreeNodeCard({
    required this.node,
    required this.isRoot,
    required this.onTap,
  });

  final TeamTreeNode node;
  final bool isRoot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final name = node.fullName.trim().isEmpty ? 'Пользователь' : node.fullName.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (isRoot ? scheme.primary : scheme.outlineVariant).withValues(alpha: 0.55),
              width: isRoot ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isRoot ? Icons.star_outline : Icons.person_outline,
                  color: scheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '****${node.phoneLast4} • ${node.bonusBalance} TJS',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

