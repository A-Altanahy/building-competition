import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/game_controller.dart';
import '../models/board_cell.dart';
import '../models/building.dart';
import '../models/team.dart';
import '../theme/app_theme.dart';

class IsometricBoardWidget extends StatefulWidget {
  final int? selectedIndex;
  final ValueChanged<int>? onCellSelected;
  final bool spectator;

  const IsometricBoardWidget({
    super.key,
    this.selectedIndex,
    this.onCellSelected,
    this.spectator = false,
  });

  @override
  State<IsometricBoardWidget> createState() => _IsometricBoardWidgetState();
}

class _IsometricBoardWidgetState extends State<IsometricBoardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final rows = controller.settings.gridRows;
    final cols = controller.settings.gridCols;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        return Center(
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return CustomPaint(
                size: Size(availableWidth, availableHeight),
                painter: _IsometricPainter(
                  controller: controller,
                  rows: rows,
                  cols: cols,
                  selectedIndex: widget.selectedIndex,
                  animProgress: _animController.value,
                  spectator: widget.spectator,
                ),
                child: GestureDetector(
                  onTapUp: (details) {
                    final index = _hitTestCell(
                      details.localPosition,
                      availableWidth,
                      availableHeight,
                      rows,
                      cols,
                    );
                    if (index != null && widget.onCellSelected != null) {
                      widget.onCellSelected!(index);
                    }
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  int? _hitTestCell(
    Offset localPosition,
    double width,
    double height,
    int rows,
    int cols,
  ) {
    final tileW = math.min(width, height) / (cols * 0.7);
    final tileH = tileW / 2;
    final originX = width / 2;
    final originY = height * 0.18;

    final relX = localPosition.dx - originX;
    final relY = localPosition.dy - originY;

    final c = (relX / (tileW / 2) + relY / (tileH / 2)) / 2;
    final r = (relY / (tileH / 2) - relX / (tileW / 2)) / 2;

    final col = c.floor() + 1;
    final row = r.floor() + 1;

    if (col >= 1 && col <= cols && row >= 1 && row <= rows) {
      return (row - 1) * cols + col;
    }
    return null;
  }
}

class _IsometricPainter extends CustomPainter {
  final GameController controller;
  final int rows;
  final int cols;
  final int? selectedIndex;
  final double animProgress;
  final bool spectator;

  _IsometricPainter({
    required this.controller,
    required this.rows,
    required this.cols,
    required this.selectedIndex,
    required this.animProgress,
    required this.spectator,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final tileW = math.min(size.width, size.height) / (cols * 0.7);
    final tileH = tileW / 2;
    final tileDepth = tileW * 0.2;
    final originX = size.width / 2;
    final originY = size.height * 0.18;

    Offset gridToIso(int col, int row) {
      final x = (col - row) * (tileW / 2) + originX;
      final y = (col + row) * (tileH / 2) + originY;
      return Offset(x, y);
    }

    // 1. Draw Market & Complex Aura Rings
    for (int i = 1; i <= controller.board.length; i++) {
      final cell = controller.board[i - 1];
      if (cell.buildingType == BuildingType.market ||
          cell.buildingType == BuildingType.complex) {
        final r = (cell.index - 1) ~/ cols + 1;
        final c = (cell.index - 1) % cols + 1;
        final center = gridToIso(c, r);

        final auraPaint = Paint()
          ..shader = RadialGradient(
            colors: [
              AppColors.gold.withValues(alpha: 0.35),
              AppColors.gold.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: tileW * 2.2));

        canvas.drawOval(
          Rect.fromCenter(
            center: center,
            width: tileW * 3.6,
            height: tileH * 3.6,
          ),
          auraPaint,
        );
      }
    }

    // 2. Render Grid Tiles in Z-Order (Back-to-Front)
    for (int r = 1; r <= rows; r++) {
      for (int c = 1; c <= cols; c++) {
        final index = (r - 1) * cols + c;
        final cell = controller.board[index - 1];
        final isSelected = selectedIndex == cell.index;

        final pos = gridToIso(c, r);
        final elevation = isSelected ? 8.0 : 0.0;
        final topY = pos.dy - elevation;

        Team? owner;
        if (cell.ownerTeamId != null) {
          for (final t in controller.teams) {
            if (t.id == cell.ownerTeamId) {
              owner = t;
              break;
            }
          }
        }

        // Draw 3D Side Walls
        final leftPath = Path()
          ..moveTo(pos.dx - tileW / 2, topY)
          ..lineTo(pos.dx, topY + tileH / 2)
          ..lineTo(pos.dx, topY + tileH / 2 + tileDepth)
          ..lineTo(pos.dx - tileW / 2, topY + tileDepth)
          ..close();

        final rightPath = Path()
          ..moveTo(pos.dx, topY + tileH / 2)
          ..lineTo(pos.dx + tileW / 2, topY)
          ..lineTo(pos.dx + tileW / 2, topY + tileDepth)
          ..lineTo(pos.dx, topY + tileH / 2 + tileDepth)
          ..close();

        canvas.drawPath(leftPath, Paint()..color = const Color(0xFF1A1E26));
        canvas.drawPath(rightPath, Paint()..color = const Color(0xFF12151B));

        // Draw Top Polygon
        final topPath = Path()
          ..moveTo(pos.dx, topY - tileH / 2)
          ..lineTo(pos.dx + tileW / 2, topY)
          ..lineTo(pos.dx, topY + tileH / 2)
          ..lineTo(pos.dx - tileW / 2, topY)
          ..close();

        final tileColor = owner != null
            ? owner.color.withValues(alpha: 0.35)
            : ((c + r) % 2 == 0
                ? const Color(0xFF2A303C)
                : const Color(0xFF222733));

        canvas.drawPath(topPath, Paint()..color = tileColor);

        // Border Outline
        final borderPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 2.5 : 1.0
          ..color = isSelected
              ? AppColors.cyan
              : (owner != null ? owner.color : const Color(0xFF3A4252));

        canvas.drawPath(topPath, borderPaint);

        // Draw Cell Index Number
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${cell.index}',
            style: TextStyle(
              color: owner != null ? Colors.white : Colors.grey[500],
              fontSize: tileW * 0.18,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.rtl,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            pos.dx - textPainter.width / 2,
            topY - textPainter.height / 2,
          ),
        );
      }
    }

    // 3. Render Connection Beams between Market/Factory & Surrounding Tiles
    for (int i = 1; i <= controller.board.length; i++) {
      final cell = controller.board[i - 1];
      if (cell.buildingType == BuildingType.market ||
          cell.buildingType == BuildingType.factory ||
          cell.buildingType == BuildingType.complex) {
        final r = (cell.index - 1) ~/ cols + 1;
        final c = (cell.index - 1) % cols + 1;
        final src = gridToIso(c, r);

        final surroundings = controller.getSurroundingIndices(cell.index);
        for (final sIdx in surroundings) {
          final targetCell = controller.board[sIdx - 1];
          if (targetCell.ownerTeamId != null) {
            final tr = (sIdx - 1) ~/ cols + 1;
            final tc = (sIdx - 1) % cols + 1;
            final dest = gridToIso(tc, tr);

            final beamColor = cell.buildingType == BuildingType.factory
                ? AppColors.gold
                : AppColors.cyan;

            final linePaint = Paint()
              ..color = beamColor.withValues(alpha: 0.6)
              ..strokeWidth = 2.0;

            canvas.drawLine(src, dest, linePaint);

            // Animated light particle along beam
            final p = (animProgress * 2) % 1.0;
            final px = src.dx + (dest.dx - src.dx) * p;
            final py = src.dy + (dest.dy - src.dy) * p;

            canvas.drawCircle(Offset(px, py), 3.0, Paint()..color = Colors.white);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _IsometricPainter oldDelegate) => true;
}
