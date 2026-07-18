import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/game_controller.dart';
import '../models/team.dart';
import '../models/building.dart';
import '../theme/app_theme.dart';

class StatsView extends StatelessWidget {
  const StatsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<GameController>(context);
    final teams = controller.teams;

    // Check if there's any history to draw a line chart
    bool hasHistory = false;
    for (var team in teams) {
      if (team.scoreHistory.length > 1) {
        hasHistory = true;
        break;
      }
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 900;

    return Scaffold(
      backgroundColor: AppColors.ink, // Slate 900
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الإحصائيات والتحليلات',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            Text(
              'رسم بياني يوضح أداء الفرق والنمو المالي وملكيات الأراضي',
              style: GoogleFonts.cairo(color: AppColors.quiet, fontSize: 14),
            ),
            const SizedBox(height: 30),

            // Top Summary Cards (Responsive Column / Row)
            _buildQuickSummaryStats(controller, isNarrow),
            const SizedBox(height: 30),

            // Charts Section (Responsive Column / Row)
            if (isNarrow)
              Column(
                children: [
                  Container(
                    height: 320,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ترتيب النقاط الحالي للفرق',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(child: _buildBarChart(teams)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 320,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مخطط نمو النقاط عبر الجولات',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: hasHistory
                              ? _buildLineChart(teams)
                              : Center(
                                  child: Text(
                                    'لا توجد بيانات تاريخية كافية. قم بإنهاء بعض الجولات لعرض الرسم البياني.',
                                    style: GoogleFonts.cairo(
                                      color: AppColors.quiet,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  // Bar Chart: Current Standings
                  Expanded(
                    child: Container(
                      height: 350,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ترتيب النقاط الحالي للفرق',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Expanded(child: _buildBarChart(teams)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Line Chart: Score Progression
                  Expanded(
                    child: Container(
                      height: 350,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مخطط نمو النقاط عبر الجولات',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Expanded(
                            child: hasHistory
                                ? _buildLineChart(teams)
                                : Center(
                                    child: Text(
                                      'لا توجد بيانات تاريخية كافية. قم بإنهاء بعض الجولات لعرض الرسم البياني.',
                                      style: GoogleFonts.cairo(
                                        color: AppColors.quiet,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 30),

            // Asset Breakdown per Team
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'توزيع الملكيات والمباني لكل فريق',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...teams.map((team) => _buildTeamAssetRow(team, controller)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSummaryStats(GameController controller, bool isNarrow) {
    int totalOwnedCells = controller.board
        .where((c) => c.ownerTeamId != null)
        .length;
    int unownedCells = controller.board.length - totalOwnedCells;
    int mostAssetsCount = 0;
    Team? topAssetTeam;

    for (var team in controller.teams) {
      int count = controller.board
          .where((c) => c.ownerTeamId == team.id)
          .length;
      if (count > mostAssetsCount) {
        mostAssetsCount = count;
        topAssetTeam = team;
      }
    }

    final cards = [
      _buildStatCard(
        'إجمالي الأراضي المستصلحة',
        '$totalOwnedCells من 100',
        Icons.landscape_rounded,
        Colors.green,
        isNarrow,
      ),
      _buildStatCard(
        'الأراضي الشاغرة (المتاحة)',
        '$unownedCells',
        Icons.hourglass_empty_rounded,
        Colors.amber,
        isNarrow,
      ),
      _buildStatCard(
        'أكثر المالكين للأراضي',
        topAssetTeam != null
            ? '${topAssetTeam.name} ($mostAssetsCount أراضي)'
            : 'لا يوجد حاليًا',
        Icons.apartment_rounded,
        Colors.blue,
        isNarrow,
      ),
    ];

    if (isNarrow) {
      return Column(
        children: [
          cards[0],
          const SizedBox(height: 12),
          cards[1],
          const SizedBox(height: 12),
          cards[2],
        ],
      );
    }

    return Row(
      children: [
        cards[0],
        const SizedBox(width: 16),
        cards[1],
        const SizedBox(width: 16),
        cards[2],
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isNarrow,
  ) {
    Widget container = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isNarrow) {
      return container;
    }
    return Expanded(child: container);
  }

  Widget _buildBarChart(List<Team> teams) {
    // Find the max score among teams
    int maxScoreVal = teams.isEmpty
        ? 0
        : teams.map((t) => t.score).reduce((a, b) => a > b ? a : b);
    double calculatedMaxY = (maxScoreVal < 0 ? 100 : maxScoreVal + 500)
        .toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: calculatedMaxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.ink,
            tooltipBorder: const BorderSide(color: Color(0xFF334155)),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${teams[group.x.toInt()].name}\n${rod.toY.toInt()} نقطة',
                GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < teams.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      teams[index].name.split(' ').take(2).join(' '),
                      style: GoogleFonts.cairo(
                        color: AppColors.muted,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: List.generate(teams.length, (i) {
          final team = teams[i];
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: team.score.toDouble(),
                color: team.color,
                width: 25,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLineChart(List<Team> teams) {
    // Find the max length of scores history and check min/max values
    int maxRounds = teams
        .map((t) => t.scoreHistory.length)
        .reduce((a, b) => a > b ? a : b);

    int minScoreVal = 0;
    int maxScoreVal = 0;
    for (var team in teams) {
      if (team.score > maxScoreVal) maxScoreVal = team.score;
      for (var s in team.scoreHistory) {
        if (s < minScoreVal) minScoreVal = s;
        if (s > maxScoreVal) maxScoreVal = s;
      }
    }

    double calculatedMinY = minScoreVal < 0
        ? (minScoreVal - 200).toDouble()
        : 0.0;
    double calculatedMaxY = (maxScoreVal < 0 ? 100 : maxScoreVal + 500)
        .toDouble();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (maxRounds - 1).toDouble(),
        minY: calculatedMinY,
        maxY: calculatedMaxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: Color(0xFF334155), strokeWidth: 1),
          getDrawingVerticalLine: (_) =>
              const FlLine(color: Color(0xFF334155), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (val, meta) {
                return Text(
                  'ج ${val.toInt() + 1}',
                  style: GoogleFonts.cairo(
                    color: AppColors.quiet,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (val, meta) {
                if (val % 500 == 0 || val == calculatedMaxY - 500) {
                  return Text(
                    '${val.toInt()}',
                    style: GoogleFonts.cairo(
                      color: AppColors.quiet,
                      fontSize: 9,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.ink,
          ),
        ),
        lineBarsData: teams.map((team) {
          return LineChartBarData(
            spots: List.generate(team.scoreHistory.length, (index) {
              return FlSpot(
                index.toDouble(),
                team.scoreHistory[index].toDouble(),
              );
            }),
            isCurved: true,
            color: team.color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: team.color.withValues(alpha: 0.08),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTeamAssetRow(Team team, GameController controller) {
    // Count properties owned by this team
    final cells = controller.board
        .where((c) => c.ownerTeamId == team.id)
        .toList();
    if (cells.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: team.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              team.name,
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            Text(
              'لا يملك أي أراضي حاليًا',
              style: GoogleFonts.cairo(color: AppColors.quiet, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final houseCount = cells
        .where((c) => c.buildingType == BuildingType.house)
        .length;
    final groceryCount = cells
        .where((c) => c.buildingType == BuildingType.grocery)
        .length;
    final marketCount = cells
        .where((c) => c.buildingType == BuildingType.market)
        .length;
    final hotelCount = cells
        .where((c) => c.buildingType == BuildingType.hotel)
        .length;
    final factoryCount = cells
        .where((c) => c.buildingType == BuildingType.factory)
        .length;
    final complexCount = cells
        .where((c) => c.buildingType == BuildingType.complex)
        .length;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: team.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                team.name,
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                'إجمالي العقارات: ${cells.length}',
                style: GoogleFonts.cairo(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Wrap containing visual count chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (houseCount > 0)
                _buildAssetChip(
                  'بيوت',
                  houseCount,
                  BuildingType.house,
                  team.color,
                ),
              if (groceryCount > 0)
                _buildAssetChip(
                  'بقالات',
                  groceryCount,
                  BuildingType.grocery,
                  team.color,
                ),
              if (marketCount > 0)
                _buildAssetChip(
                  'أسواق',
                  marketCount,
                  BuildingType.market,
                  team.color,
                ),
              if (hotelCount > 0)
                _buildAssetChip(
                  'فنادق',
                  hotelCount,
                  BuildingType.hotel,
                  team.color,
                ),
              if (factoryCount > 0)
                _buildAssetChip(
                  'مصانع',
                  factoryCount,
                  BuildingType.factory,
                  team.color,
                ),
              if (complexCount > 0)
                _buildAssetChip(
                  'مجمعات',
                  complexCount,
                  BuildingType.complex,
                  team.color,
                ),
            ],
          ),
          const Divider(color: Color(0xFF334155), height: 24),
        ],
      ),
    );
  }

  Widget _buildAssetChip(
    String label,
    int count,
    BuildingType type,
    Color teamColor,
  ) {
    IconData getIcon() {
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: teamColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(getIcon(), size: 14, color: teamColor),
          const SizedBox(width: 6),
          Text(
            '$label: $count',
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
