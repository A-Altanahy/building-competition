import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/game_controller.dart';
import '../models/board_cell.dart';
import '../models/building.dart';
import '../models/team.dart';
import '../theme/app_theme.dart';

IconData buildingIconFor(BuildingType type) {
  switch (type) {
    case BuildingType.house:
      return Icons.home_rounded;
    case BuildingType.grocery:
      return Icons.local_grocery_store_rounded;
    case BuildingType.market:
      return Icons.storefront_rounded;
    case BuildingType.hotel:
      return Icons.hotel_rounded;
    case BuildingType.factory:
      return Icons.factory_rounded;
    case BuildingType.complex:
      return Icons.apartment_rounded;
  }
}

class CompetitionBoard extends StatelessWidget {
  final int? selectedIndex;
  final ValueChanged<int>? onCellSelected;
  final bool spectator;

  const CompetitionBoard({
    super.key,
    this.selectedIndex,
    this.onCellSelected,
    this.spectator = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final rows = controller.settings.gridRows;
    final cols = controller.settings.gridCols;

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = spectator ? 6.0 : 5.0;
        final sizeByWidth =
            (constraints.maxWidth - spacing * (cols - 1)) / cols;
        final sizeByHeight =
            (constraints.maxHeight - spacing * (rows - 1)) / rows;
        final cellSize = sizeByWidth < sizeByHeight
            ? sizeByWidth
            : sizeByHeight;
        final boardWidth = cellSize * cols + spacing * (cols - 1);
        final boardHeight = cellSize * rows + spacing * (rows - 1);

        return Center(
          child: SizedBox(
            width: boardWidth,
            height: boardHeight,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.board.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
              ),
              itemBuilder: (context, index) {
                final cell = controller.board[index];
                Team? owner;
                if (cell.ownerTeamId != null) {
                  for (final team in controller.teams) {
                    if (team.id == cell.ownerTeamId) {
                      owner = team;
                      break;
                    }
                  }
                }
                return _CompetitionCell(
                  cell: cell,
                  owner: owner,
                  value: controller.calculateCellValue(cell.index),
                  selected: selectedIndex == cell.index,
                  factoryInfluence: controller.hasOwnedInfluence(
                    cell.index,
                    BuildingType.factory,
                  ),
                  complexInfluence: controller.hasOwnedInfluence(
                    cell.index,
                    BuildingType.complex,
                  ),
                  size: cellSize,
                  spectator: spectator,
                  onTap: onCellSelected == null
                      ? null
                      : () => onCellSelected!(cell.index),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _CompetitionCell extends StatelessWidget {
  final BoardCell cell;
  final Team? owner;
  final int value;
  final bool selected;
  final bool factoryInfluence;
  final bool complexInfluence;
  final double size;
  final bool spectator;
  final VoidCallback? onTap;

  const _CompetitionCell({
    required this.cell,
    required this.owner,
    required this.value,
    required this.selected,
    required this.factoryInfluence,
    required this.complexInfluence,
    required this.size,
    required this.spectator,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = owner == null;
    final ownerColor = owner?.color ?? AppColors.border;
    final influenceColors = <Color>[];
    if (factoryInfluence) influenceColors.add(AppColors.gold);
    if (complexInfluence) influenceColors.add(AppColors.cyan);

    final decoration = BoxDecoration(
      color: isEmpty ? AppColors.ink : ownerColor.withValues(alpha: 0.18),
      gradient: influenceColors.isEmpty
          ? null
          : LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: influenceColors.length == 1
                  ? [
                      influenceColors.first.withValues(alpha: 0.22),
                      AppColors.ink,
                    ]
                  : [
                      AppColors.gold.withValues(alpha: 0.18),
                      AppColors.cyan.withValues(alpha: 0.18),
                    ],
            ),
      borderRadius: BorderRadius.circular(spectator ? 10 : 9),
      border: Border.all(
        color: selected
            ? AppColors.gold
            : (isEmpty ? AppColors.border : ownerColor),
        width: selected ? 2.5 : (isEmpty ? 1 : 1.6),
      ),
      boxShadow: selected
          ? [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.28),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ]
          : null,
    );

    final label = isEmpty
        ? 'المربع ${cell.index} - أرض شاغرة'
        : 'المربع ${cell.index} - ${cell.buildingType.arabicName} - ${owner!.name} - $value نقطة';

    return Tooltip(
      message: label,
      textStyle: appTextStyle(size: 11),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(spectator ? 10 : 9),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: decoration,
            padding: EdgeInsets.all(size < 38 ? 2 : 4),
            child: Stack(
              children: [
                Positioned(
                  top: 1,
                  right: 2,
                  child: Text(
                    '${cell.index}',
                    style: appTextStyle(
                      size: size < 38 ? 7 : 10,
                      weight: FontWeight.w700,
                      color: isEmpty ? AppColors.quiet : AppColors.text,
                    ),
                  ),
                ),
                Center(
                  child: isEmpty
                      ? Icon(
                          Icons.add_rounded,
                          size: size * (spectator ? 0.28 : 0.24),
                          color: AppColors.quiet.withValues(alpha: 0.65),
                        )
                      : Icon(
                          buildingIconFor(cell.buildingType),
                          size: size * (spectator ? 0.36 : 0.34),
                          color: ownerColor,
                        ),
                ),
                if (!isEmpty && size >= 35)
                  Positioned(
                    bottom: 1,
                    left: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: ownerColor,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '$value',
                        style: appTextStyle(
                          size: size < 48 ? 8 : 10,
                          weight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                if (factoryInfluence || complexInfluence)
                  Positioned(
                    top: 2,
                    left: 2,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (factoryInfluence)
                          const _InfluenceDot(color: AppColors.gold),
                        if (complexInfluence)
                          const _InfluenceDot(color: AppColors.cyan),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfluenceDot extends StatelessWidget {
  final Color color;
  const _InfluenceDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      margin: const EdgeInsets.only(left: 2),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
