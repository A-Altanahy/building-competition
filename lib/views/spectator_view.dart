import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/game_controller.dart';
import '../models/building.dart';
import '../models/team.dart';
import '../utils/platform_utils.dart';

class SpectatorView extends StatelessWidget {
  const SpectatorView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF090D16),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SpectatorBody(showBackButton: true),
      ),
    );
  }
}

class SpectatorBody extends StatelessWidget {
  final bool showBackButton;
  const SpectatorBody({super.key, this.showBackButton = false});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<GameController>(context);
    final sortedTeams = List<Team>.from(controller.teams)
      ..sort((a, b) => b.score.compareTo(a.score));

    IconData getBuildingIcon(BuildingType type) {
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
          return Icons.precision_manufacturing_rounded;
        case BuildingType.complex:
          return Icons.domain_rounded;
      }
    }

    return Stack(
      children: [
        // Main content: scoreboard and grid side-by-side
        Row(
          children: [
            // Right Section: Big Scoreboard
            Container(
              width: 320, // Reduced from 380 to make it fit split screens better
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                border: Border(
                  left: BorderSide(color: Color(0xFF1E293B), width: 2),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'ترتيب منافسة فتية الرشد',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  Text(
                    'الجولة الحالية: ${controller.roundNumber}',
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF3B82F6),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Rank Cards
                  Expanded(
                    child: ListView.builder(
                      itemCount: sortedTeams.length,
                      itemBuilder: (context, index) {
                        final team = sortedTeams[index];
                        final isFirst = index == 0 && team.score > 0;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isFirst ? const Color(0xFFF59E0B) : const Color(0xFF334155),
                              width: isFirst ? 2 : 1,
                            ),
                            boxShadow: isFirst
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFF59E0B).withOpacity(0.2),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              // Rank badge
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isFirst ? const Color(0xFFF59E0B) : const Color(0xFF475569),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Team info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      team.name,
                                      style: GoogleFonts.cairo(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),

                              // Color bar indicator & Points
                              Container(
                                width: 4,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: team.color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),

                              Text(
                                '${team.score}',
                                style: GoogleFonts.cairo(
                                  color: isFirst ? const Color(0xFFF59E0B) : Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Left Section: Interactive-Looking Large Grid (Spectator Mode)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final gridSpacing = 6.0;
                    final cols = 10;
                    final rows = 10;

                    final availableWidth = constraints.maxWidth;
                    final availableHeight = constraints.maxHeight;

                    // Calculate cell size that keeps cells square and fits bounds
                    final cellWidth = (availableWidth - (cols - 1) * gridSpacing) / cols;
                    final cellHeight = (availableHeight - (rows - 1) * gridSpacing) / rows;

                    final cellSize = cellWidth < cellHeight ? cellWidth : cellHeight;

                    final gridWidth = cellSize * cols + (cols - 1) * gridSpacing;
                    final gridHeight = cellSize * rows + (rows - 1) * gridSpacing;

                    return Center(
                      child: SizedBox(
                        width: gridWidth,
                        height: gridHeight,
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            crossAxisSpacing: gridSpacing,
                            mainAxisSpacing: gridSpacing,
                          ),
                          itemCount: controller.board.length,
                          itemBuilder: (context, index) {
                            final cellIndex = index + 1;
                            final cell = controller.board[index];
                            final cellValue = controller.calculateCellValue(cellIndex);

                            Team? ownerTeam;
                            if (cell.ownerTeamId != null) {
                              ownerTeam = controller.teams.firstWhere((t) => t.id == cell.ownerTeamId);
                            }

                            final isNeutral = ownerTeam == null;
                            final themeColor = ownerTeam?.color ?? const Color(0xFF1E293B);

                            return Container(
                              decoration: BoxDecoration(
                                color: isNeutral
                                    ? const Color(0xFF1E293B).withOpacity(0.4)
                                    : themeColor.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isNeutral ? const Color(0xFF334155) : themeColor,
                                  width: isNeutral ? 1 : 2,
                                ),
                                boxShadow: isNeutral
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: themeColor.withOpacity(0.15),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        )
                                      ],
                              ),
                              child: LayoutBuilder(
                                builder: (context, cellConstraints) {
                                  final cellHeight = cellConstraints.maxHeight;

                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          '$cellIndex',
                                          style: GoogleFonts.cairo(
                                            color: isNeutral ? const Color(0xFF475569) : Colors.white70,
                                            fontSize: cellHeight * 0.20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: cellHeight * 0.04),
                                      Icon(
                                        getBuildingIcon(cell.buildingType),
                                        color: isNeutral ? const Color(0xFF334155) : themeColor,
                                        size: cellHeight * 0.35,
                                      ),
                                      SizedBox(height: cellHeight * 0.04),
                                      if (!isNeutral)
                                        Flexible(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: themeColor,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '$cellValue',
                                                style: GoogleFonts.cairo(
                                                  color: Colors.white,
                                                  fontSize: cellHeight * 0.18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                }
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),

        // Fullscreen toggle button
        Positioned(
          left: showBackButton ? 70 : 20,
          top: 20,
          child: FloatingActionButton.small(
            backgroundColor: const Color(0xFF1E293B),
            foregroundColor: Colors.white,
            tooltip: 'شاشة كاملة',
            onPressed: () {
              toggleWebFullScreen();
            },
            child: const Icon(Icons.fullscreen_rounded),
          ),
        ),

        // Back button floating in top-left (for moderator to exit spectator view)
        if (showBackButton)
          Positioned(
            left: 20,
            top: 20,
            child: FloatingActionButton.small(
              backgroundColor: const Color(0xFF1E293B),
              foregroundColor: Colors.white,
              child: const Icon(Icons.arrow_back_rounded),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
      ],
    );
  }
}
