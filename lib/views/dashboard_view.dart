import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import '../controllers/game_controller.dart';
import '../models/building.dart';
import '../models/team.dart';
import '../models/board_cell.dart';
import 'stats_view.dart';
import 'settings_view.dart';
import 'spectator_view.dart';
import '../utils/platform_utils.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _activeTab = 0; // 0: Game, 1: Stats, 2: Settings, 3: Dual Screen
  int? _selectedCellIndex; // 1-indexed

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate 900
      body: Row(
        textDirection: TextDirection.rtl, // Navigation bar on the right
        children: [
          // Navigation Sidebar (Arabic RTL sidebar)
          _buildSidebar(),

          // Main Content Area
          Expanded(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: _buildMainContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B), // Slate 800
        border: Border(
          left: BorderSide(color: Color(0xFF334155), width: 1), // Slate 700
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    // App Title / Logo
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFF3B82F6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.dashboard_rounded, color: Colors.white),
                            const SizedBox(width: 10),
                            Text(
                              'دوري فتية الرشد',
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'المسابقة الثقافية العقارية',
                      style: GoogleFonts.cairo(
                        color: const Color(0xFF94A3B8), // Slate 400
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Sidebar Menu Items
                    _buildSidebarItem(0, 'لوحة التحكم', Icons.grid_view_rounded),
                    _buildSidebarItem(1, 'الإحصائيات والترتيب', Icons.bar_chart_rounded),
                    _buildSidebarItem(2, 'إعدادات اللعبة', Icons.settings_rounded),
                    _buildSidebarItem(3, 'الشاشة المزدوجة', Icons.splitscreen_rounded),

                    const Spacer(),

                    // Spectator View Trigger Button
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6), // Blue 500
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 4,
                        ),
                        onPressed: () {
                          final controller = Provider.of<GameController>(context, listen: false);
                          openSpectatorWindow(controller.exportGameStateJson());
                        },
                        icon: const Icon(Icons.tv_rounded, size: 20),
                        label: Text(
                          'شاشة العرض (الجمهور)',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildSidebarItem(int index, String title, IconData icon) {
    final isActive = _activeTab == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: () {
          setState(() {
            _activeTab = index;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF334155) : Colors.transparent, // Active Slate 700
            borderRadius: BorderRadius.circular(10),
            border: isActive
                ? const Border(
                    right: BorderSide(color: Color(0xFFEF4444), width: 4), // Red Indicator
                  )
                : null,
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                icon,
                color: isActive ? const Color(0xFF3B82F6) : const Color(0xFF94A3B8),
                size: 22,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.cairo(
                    color: isActive ? Colors.white : const Color(0xFF94A3B8),
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_activeTab) {
      case 0:
        return _buildGamePanel(isDualScreen: false);
      case 1:
        return const StatsView();
      case 2:
        return const SettingsView();
      case 3:
        return _buildDualScreenPanel();
      default:
        return _buildGamePanel(isDualScreen: false);
    }
  }

  Widget _buildDualScreenPanel() {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        // Left Pane: Audience Spectator Screen (55% width)
        const Expanded(
          flex: 11,
          child: SpectatorBody(showBackButton: false),
        ),
        
        // Split border divider
        const VerticalDivider(
          width: 4,
          thickness: 4,
          color: Color(0xFF334155),
        ),
        
        // Right Pane: Moderator Control Grid & Inspector (45% width)
        Expanded(
          flex: 9,
          child: _buildGamePanel(isDualScreen: true),
        ),
      ],
    );
  }

  Widget _buildGamePanel({bool isDualScreen = false}) {
    return Column(
      children: [
        // Top Action Bar (Round Counter, Undo, Redo, End Round)
        _buildTopActionBar(),

        // Main Board Split View (Scoreboard left, Grid center, Cell Inspector right)
        Expanded(
          child: Row(
            textDirection: TextDirection.rtl, // Scoreboard right-ish, Grid center, Inspector left
            children: [
              // Left Section: Scoreboard & Points Adjustment
              if (!isDualScreen)
                Container(
                  width: 320,
                  color: const Color(0xFF0F172A),
                  padding: const EdgeInsets.all(16.0),
                  child: const ScoreboardWidget(),
                ),

              // Center Section: 10x10 Grid View
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(isDualScreen ? 10.0 : 20.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: BoardGridWidget(
                          selectedIndex: _selectedCellIndex,
                          onCellSelected: (index) {
                            setState(() {
                              _selectedCellIndex = index;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Right Section: Cell Inspector
              Container(
                width: isDualScreen ? 270 : 320,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  border: Border(
                    right: BorderSide(color: Color(0xFF334155), width: 1),
                  ),
                ),
                padding: const EdgeInsets.all(12.0),
                child: CellInspectorWidget(
                  selectedIndex: _selectedCellIndex,
                  onClosed: () {
                    setState(() {
                      _selectedCellIndex = null;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopActionBar() {
    final controller = Provider.of<GameController>(context);
    return Container(
      height: 80,
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: MediaQuery.of(context).size.width - 250, // Sidebar offset
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Round info
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Text(
                      'الجولة: ${controller.roundNumber}',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),

              // Undo/Redo/Fullscreen Buttons
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.undo_rounded),
                    color: controller.canUndo ? Colors.white : Colors.grey,
                    tooltip: 'تراجع عن الجولة',
                    onPressed: controller.canUndo ? () => controller.undo() : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.redo_rounded),
                    color: controller.canRedo ? Colors.white : Colors.grey,
                    tooltip: 'إعادة التطبيق',
                    onPressed: controller.canRedo ? () => controller.redo() : null,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.fullscreen_rounded),
                    color: Colors.white,
                    tooltip: 'شاشة كاملة',
                    onPressed: () {
                      toggleWebFullScreen();
                    },
                  ),
                ],
              ),

              // End Round Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444), // Red 500
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 4,
                ),
                onPressed: () {
                  _showEndRoundConfirmation(context, controller);
                },
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(
                  'إنهاء الجولة وحساب النقاط',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEndRoundConfirmation(BuildContext context, GameController controller) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: Text(
              'تأكيد إنهاء الجولة',
              style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: Text(
              'هل أنت متأكد من إنهاء الجولة الحالية؟ سيتم تحديث رصيد النقاط لجميع الفرق وتطبيق خصومات البناء على المباني الجديدة.',
              style: GoogleFonts.cairo(color: const Color(0xFF94A3B8)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'إلغاء',
                  style: GoogleFonts.cairo(color: const Color(0xFF94A3B8)),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                onPressed: () {
                  controller.endRound();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF10B981),
                      content: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          'تم إنهاء الجولة بنجاح وحساب النقاط!',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                },
                child: Text(
                  'نعم، إنهاء الجولة',
                  style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
// BoardGridWidget: 10x10 grid of cells
// ==========================================
class BoardGridWidget extends StatelessWidget {
  final int? selectedIndex;
  final Function(int) onCellSelected;

  const BoardGridWidget({
    super.key,
    required this.selectedIndex,
    required this.onCellSelected,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<GameController>(context);
    final cells = controller.board;

    return LayoutBuilder(
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
              itemCount: cells.length,
              itemBuilder: (context, index) {
                final cellIndex = index + 1;
                final cell = cells[index];
                final isSelected = selectedIndex == cellIndex;
                final cellValue = controller.calculateCellValue(cellIndex);

                // Find owner team
                Team? ownerTeam;
                if (cell.ownerTeamId != null) {
                  ownerTeam = controller.teams.firstWhere((t) => t.id == cell.ownerTeamId);
                }

                return CellWidget(
                  cell: cell,
                  value: cellValue,
                  ownerTeam: ownerTeam,
                  isSelected: isSelected,
                  onTap: () => onCellSelected(cellIndex),
                  cellSize: cellSize,
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// ==========================================
// CellWidget: Individual Grid Tile
// ==========================================
class CellWidget extends StatelessWidget {
  final BoardCell cell;
  final int value;
  final Team? ownerTeam;
  final bool isSelected;
  final VoidCallback onTap;
  final double cellSize;

  const CellWidget({
    super.key,
    required this.cell,
    required this.value,
    required this.ownerTeam,
    required this.isSelected,
    required this.onTap,
    required this.cellSize,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = ownerTeam?.color ?? const Color(0xFF334155); // Slate 700 if neutral
    final isNeutral = ownerTeam == null;

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

    return Tooltip(
      message: 'الخلية ${cell.index}\n${ownerTeam?.name ?? 'بدون مالك'}\n${cell.buildingType.arabicName}: $value نقطة',
      textStyle: GoogleFonts.cairo(color: Colors.white, fontSize: 11),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(6)),
      child: Material(
        color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isNeutral
                  ? const Color(0xFF1E293B).withOpacity(0.6)
                  : themeColor.withOpacity(0.25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? Colors.white
                    : (isNeutral ? const Color(0xFF334155) : themeColor),
                width: isSelected ? 2.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: (ownerTeam?.color ?? Colors.white).withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: LayoutBuilder(
              builder: (context, cellConstraints) {
                final cellHeight = cellConstraints.maxHeight;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Cell index
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${cell.index}',
                        style: GoogleFonts.cairo(
                          color: isNeutral ? const Color(0xFF64748B) : Colors.white70,
                          fontSize: cellHeight * 0.20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: cellHeight * 0.04),
                    // Building Icon
                    Icon(
                      getBuildingIcon(cell.buildingType),
                      color: isNeutral ? const Color(0xFF475569) : themeColor,
                      size: cellHeight * 0.35,
                    ),
                    SizedBox(height: cellHeight * 0.04),
                    // Calculated points
                    if (!isNeutral)
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '$value',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: cellHeight * 0.18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// ScoreboardWidget: Score List and Controls
// ==========================================
class ScoreboardWidget extends StatelessWidget {
  const ScoreboardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<GameController>(context);
    final sortedTeams = List<Team>.from(controller.teams)
      ..sort((a, b) => b.score.compareTo(a.score));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'لائحة النقاط والترتيب',
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 20),

        // Team list
        Expanded(
          child: ListView.builder(
            itemCount: sortedTeams.length,
            itemBuilder: (context, index) {
              final team = sortedTeams[index];
              final isLeader = index == 0 && team.score > 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isLeader ? const Color(0xFFF59E0B) : const Color(0xFF334155),
                    width: isLeader ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Rank Badge
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: isLeader ? const Color(0xFFF59E0B) : const Color(0xFF475569),
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Team Name & Color Dot
                    Expanded(
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
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  team.name,
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Score Display & Adjustments button
                    Row(
                      children: [
                        Text(
                          '${team.score}',
                          style: GoogleFonts.cairo(
                            color: isLeader ? const Color(0xFFF59E0B) : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF94A3B8), size: 20),
                          tooltip: 'تعديل النقاط يدويًا',
                          onPressed: () => _showPointsAdjustmentDialog(context, controller, team),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showPointsAdjustmentDialog(BuildContext context, GameController controller, Team team) {
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: Text(
              'تعديل نقاط: ${team.name}',
              style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'النقاط الحالية: ${team.score}',
                  style: GoogleFonts.cairo(color: const Color(0xFF94A3B8), fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'قيمة النقاط (موجب للإضافة، سالب للخصم)',
                    labelStyle: GoogleFonts.cairo(color: const Color(0xFF64748B), fontSize: 12),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF334155)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'إلغاء',
                  style: GoogleFonts.cairo(color: const Color(0xFF94A3B8)),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                onPressed: () {
                  final val = int.tryParse(amountController.text);
                  if (val != null) {
                    controller.adjustScore(team.id, val);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF10B981),
                        content: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            'تم تعديل نقاط فريق ${team.name} بمقدار $val',
                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  }
                },
                child: Text(
                  'حفظ التعديل',
                  style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
// CellInspectorWidget: Inspector Side Panel
// ==========================================
class CellInspectorWidget extends StatelessWidget {
  final int? selectedIndex;
  final VoidCallback onClosed;

  const CellInspectorWidget({
    super.key,
    required this.selectedIndex,
    required this.onClosed,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedIndex == null) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.grid_goldenratio_rounded, color: Color(0xFF475569), size: 48),
              const SizedBox(height: 16),
              Text(
                'اختر خلية من الخريطة لعرض تفاصيلها وتعديلها',
                style: GoogleFonts.cairo(color: const Color(0xFF64748B), fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final cellIndex = selectedIndex!;
    final controller = Provider.of<GameController>(context);
    final cell = controller.board[cellIndex - 1];
    final calculatedValue = controller.calculateCellValue(cellIndex);

    // Context details
    final surrounding = controller.getSurroundingIndices(cellIndex);
    final complexNeighbors = surrounding
        .where((idx) => controller.board[idx - 1].buildingType == BuildingType.complex)
        .toList();
    final factoryNeighbors = surrounding
        .where((idx) => controller.board[idx - 1].buildingType == BuildingType.factory)
        .toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تفاصيل الخلية $cellIndex',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                onPressed: onClosed,
              ),
            ],
          ),
          const Divider(color: Color(0xFF334155), height: 30),

        // Owner selection
        Text(
          'المالك (الفريق المستحوذ)',
          style: GoogleFonts.cairo(color: const Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: cell.ownerTeamId,
              dropdownColor: const Color(0xFF0F172A),
              hint: Text('لا يوجد (بدون مالك)', style: GoogleFonts.cairo(color: const Color(0xFF475569))),
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
              isExpanded: true,
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text('لا يوجد (بدون مالك)', style: GoogleFonts.cairo(color: const Color(0xFF94A3B8))),
                ),
                ...controller.teams.map((team) {
                  return DropdownMenuItem<String?>(
                    value: team.id,
                    child: Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: team.color, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text(team.name, style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }),
              ],
              onChanged: (val) {
                controller.setCellOwner(cellIndex, val);
              },
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Building selection
        Text(
          'نوع المبنى القائم',
          style: GoogleFonts.cairo(color: const Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<BuildingType>(
              value: cell.buildingType,
              dropdownColor: const Color(0xFF0F172A),
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
              isExpanded: true,
              items: BuildingType.values.map((type) {
                return DropdownMenuItem<BuildingType>(
                  value: type,
                  child: Text(
                    '${type.arabicName} (تكلفة: ${type.price}، قاعدة: ${type.baseValue})',
                    style: GoogleFonts.cairo(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  controller.setCellBuilding(cellIndex, val);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 30),

        // Calculations & Modifiers Display Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'حساب قيمة الإنتاج المالي',
                style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 12),
              _buildValueRow('القيمة الأساسية للمبنى:', '${cell.buildingType.baseValue} ن'),
              _buildValueRow('تكلفة التشييد للبناء:', '${cell.buildingType.price} ن'),
              const Divider(color: Color(0xFF334155), height: 20),

              // Modifiers status
              if (cell.buildingType != BuildingType.complex && cell.buildingType != BuildingType.factory) ...[
                _buildModifierStatusRow('مجمعات محيطة (تأثير مجمع):', complexNeighbors.isNotEmpty, complexNeighbors.length),
                _buildModifierStatusRow('مصانع محيطة (تأثير مصنع):', factoryNeighbors.isNotEmpty, factoryNeighbors.length),
                const Divider(color: Color(0xFF334155), height: 20),
              ],

              // Final computed value
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'القيمة الفعلية للجولة:',
                    style: GoogleFonts.cairo(color: const Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    '$calculatedValue ن',
                    style: GoogleFonts.cairo(color: const Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildValueRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.cairo(color: const Color(0xFF64748B), fontSize: 12)),
          Text(value, style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildModifierStatusRow(String label, bool active, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.cairo(color: const Color(0xFF64748B), fontSize: 12)),
          Text(
            active ? 'نشط ($count)' : 'غير متوفر',
            style: GoogleFonts.cairo(
              color: active ? const Color(0xFFF59E0B) : const Color(0xFF475569),
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
