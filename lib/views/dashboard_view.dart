import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/game_controller.dart';
import '../models/building.dart';
import '../models/team.dart';
import '../theme/app_theme.dart';
import '../utils/platform_utils.dart';
import '../widgets/competition_board.dart';
import 'settings_view.dart';
import 'spectator_view.dart';
import 'stats_view.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _activeTab = 0;
  int? _selectedCellIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            _buildSidebar(),
            Expanded(child: _buildMainContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    final compact = MediaQuery.sizeOf(context).width < 1120;
    final items = [
      (0, 'لوحة المدينة', Icons.grid_view_rounded),
      (1, 'الإحصاءات والترتيب', Icons.insights_rounded),
      (2, 'إعدادات اللعبة', Icons.tune_rounded),
      (3, 'الشاشة المزدوجة', Icons.present_to_all_rounded),
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: compact ? 82 : 220,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(left: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 22),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 11 : 16),
            child: Container(
              height: compact ? 54 : 78,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.teal, AppColors.cyan],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: compact
                  ? const Center(
                      child: Icon(
                        Icons.apartment_rounded,
                        color: AppColors.ink,
                        size: 28,
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.apartment_rounded,
                            color: AppColors.ink,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'دوري فتية الرشد',
                              style: appTextStyle(
                                size: 16,
                                weight: FontWeight.w900,
                                color: AppColors.ink,
                              ),
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 10),
            Text(
              'المسابقة الثقافية العقارية',
              style: appTextStyle(size: 11, color: AppColors.muted),
            ),
          ],
          const SizedBox(height: 30),
          ...items.map(
            (item) => _SidebarItem(
              title: item.$2,
              icon: item.$3,
              compact: compact,
              active: _activeTab == item.$1,
              onTap: () => setState(() => _activeTab = item.$1),
            ),
          ),
          const Spacer(),
          Padding(
            padding: EdgeInsets.all(compact ? 11 : 14),
            child: Tooltip(
              message: 'فتح شاشة الجمهور',
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  final controller = context.read<GameController>();
                  openSpectatorWindow(controller.exportGameStateJson());
                },
                child: Container(
                  height: compact ? 48 : 50,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.5),
                    ),
                  ),
                  child: compact
                      ? const Center(
                          child: Icon(Icons.tv_rounded, color: AppColors.gold),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.tv_rounded,
                              color: AppColors.gold,
                              size: 19,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'شاشة الجمهور',
                              style: appTextStyle(
                                size: 12,
                                weight: FontWeight.w800,
                                color: AppColors.gold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_activeTab) {
      case 1:
        return const StatsView();
      case 2:
        return const SettingsView();
      case 3:
        return _buildDualScreenPanel();
      default:
        return _buildGamePanel();
    }
  }

  Widget _buildDualScreenPanel() {
    return Row(
      children: [
        const Expanded(flex: 11, child: SpectatorBody(showBackButton: false)),
        const VerticalDivider(width: 4, thickness: 4, color: AppColors.border),
        Expanded(flex: 9, child: _buildGamePanel(isDualScreen: true)),
      ],
    );
  }

  Widget _buildGamePanel({bool isDualScreen = false}) {
    final compact = MediaQuery.sizeOf(context).width < 1000;
    return Column(
      children: [
        _buildTopActionBar(),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 10 : 18,
              14,
              compact ? 10 : 18,
              16,
            ),
            child: compact
                ? Column(
                    children: [
                      if (!isDualScreen)
                        const SizedBox(height: 104, child: ScoreboardStrip()),
                      const SizedBox(height: 12),
                      Expanded(child: _buildBoardPanel()),
                      if (_selectedCellIndex != null) ...[
                        const SizedBox(height: 12),
                        SizedBox(height: 280, child: _buildInspectorPanel()),
                      ],
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!isDualScreen) ...[
                        const SizedBox(width: 270, child: ScoreboardPanel()),
                        const SizedBox(width: 14),
                      ],
                      Expanded(child: _buildBoardPanel()),
                      if (_selectedCellIndex != null) ...[
                        const SizedBox(width: 14),
                        SizedBox(
                          width: isDualScreen ? 270 : 315,
                          child: _buildInspectorPanel(),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildBoardPanel() {
    return Container(
      decoration: panelDecoration(color: AppColors.ink),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.map_rounded,
                  color: AppColors.teal,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'خريطة المدينة',
                    style: appTextStyle(size: 17, weight: FontWeight.w900),
                  ),
                  Text(
                    'اختر مربعاً لمراجعة الملكية والمبنى',
                    style: appTextStyle(size: 11, color: AppColors.muted),
                  ),
                ],
              ),
              const Spacer(),
              _LegendChip(color: AppColors.gold, label: 'تأثير مصنع'),
              const SizedBox(width: 7),
              _LegendChip(color: AppColors.cyan, label: 'تأثير مجمع'),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: CompetitionBoard(
              selectedIndex: _selectedCellIndex,
              onCellSelected: (index) =>
                  setState(() => _selectedCellIndex = index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectorPanel() {
    return Container(
      decoration: panelDecoration(color: AppColors.surface),
      padding: const EdgeInsets.all(16),
      child: CellInspectorPanel(
        selectedIndex: _selectedCellIndex,
        onClosed: () => setState(() => _selectedCellIndex = null),
      ),
    );
  }

  Widget _buildTopActionBar() {
    return Consumer<GameController>(
      builder: (context, controller, _) {
        final progress = controller.isGameOver
            ? 1.0
            : controller.roundNumber / GameController.maxRounds;
        return Container(
          height: 88,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: controller.isGameOver
                      ? AppColors.gold.withValues(alpha: 0.16)
                      : AppColors.teal.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: controller.isGameOver
                        ? AppColors.gold
                        : AppColors.teal,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      controller.isGameOver
                          ? Icons.emoji_events_rounded
                          : Icons.flag_rounded,
                      color: controller.isGameOver
                          ? AppColors.gold
                          : AppColors.teal,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      controller.isGameOver
                          ? 'اكتملت المسابقة'
                          : 'الجولة ${controller.roundNumber} من ${GameController.maxRounds}',
                      style: appTextStyle(size: 13, weight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 110,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    minHeight: 7,
                    value: progress,
                    backgroundColor: AppColors.border,
                    color: controller.isGameOver
                        ? AppColors.gold
                        : AppColors.teal,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              _InfoPill(
                icon: Icons.construction_rounded,
                label: controller.isGameOver
                    ? 'لا يوجد بناء'
                    : 'بناء ${controller.buildAllowance}',
              ),
              const SizedBox(width: 8),
              _InfoPill(
                icon: Icons.location_city_rounded,
                label:
                    '${controller.board.where((c) => c.ownerTeamId != null).length} مبنى',
              ),
              const Spacer(),
              IconButton(
                onPressed: controller.canUndo ? controller.undo : null,
                tooltip: 'تراجع',
                icon: const Icon(Icons.undo_rounded),
                color: controller.canUndo ? AppColors.text : AppColors.quiet,
              ),
              IconButton(
                onPressed: controller.canRedo ? controller.redo : null,
                tooltip: 'إعادة',
                icon: const Icon(Icons.redo_rounded),
                color: controller.canRedo ? AppColors.text : AppColors.quiet,
              ),
              IconButton(
                onPressed: toggleWebFullScreen,
                tooltip: 'شاشة كاملة',
                icon: const Icon(Icons.fullscreen_rounded),
                color: AppColors.text,
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: controller.isGameOver
                    ? null
                    : () => _showEndRoundConfirmation(context, controller),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  foregroundColor: AppColors.text,
                  disabledBackgroundColor: AppColors.border,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: Text(
                  controller.isGameOver ? 'انتهت اللعبة' : 'إنهاء الجولة',
                  style: appTextStyle(size: 12, weight: FontWeight.w900),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEndRoundConfirmation(
    BuildContext context,
    GameController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'تسوية الجولة ${controller.roundNumber}',
            style: appTextStyle(size: 18, weight: FontWeight.w900),
          ),
          content: Text(
            'سيتم احتساب عوائد جميع المباني وخصم تكاليف المباني الجديدة. بعد الجولة السادسة ستظهر النتيجة النهائية.',
            style: appTextStyle(size: 13, color: AppColors.muted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'مراجعة',
                style: appTextStyle(color: AppColors.muted),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.coral),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                'احتساب الآن',
                style: appTextStyle(size: 12, weight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && context.mounted) {
      controller.endRound();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'تم احتساب عوائد الجولة ${controller.roundNumber - 1}',
            style: appTextStyle(
              size: 12,
              weight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ),
      );
    }
  }
}

class _SidebarItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool compact;
  final bool active;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.title,
    required this.icon,
    required this.compact,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 11 : 12, vertical: 3),
      child: Tooltip(
        message: title,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 52,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.teal.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: active
                  ? Border.all(color: AppColors.teal.withValues(alpha: 0.55))
                  : null,
            ),
            child: compact
                ? Center(
                    child: Icon(
                      icon,
                      color: active ? AppColors.teal : AppColors.muted,
                      size: 23,
                    ),
                  )
                : Row(
                    children: [
                      const SizedBox(width: 14),
                      Icon(
                        icon,
                        color: active ? AppColors.teal : AppColors.muted,
                        size: 21,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: appTextStyle(
                            size: 13,
                            weight: active ? FontWeight.w900 : FontWeight.w600,
                            color: active ? AppColors.text : AppColors.muted,
                          ),
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

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.gold),
          const SizedBox(width: 6),
          Text(
            label,
            style: appTextStyle(
              size: 11,
              weight: FontWeight.w800,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: appTextStyle(size: 9, weight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class ScoreboardPanel extends StatelessWidget {
  const ScoreboardPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final teams = [...controller.teams]
      ..sort((a, b) => b.score.compareTo(a.score));
    return Container(
      decoration: panelDecoration(),
      padding: const EdgeInsets.fromLTRB(14, 15, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: AppColors.gold,
                size: 21,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'الترتيب الحالي',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: appTextStyle(size: 16, weight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'النقاط • عدد المباني • العائد القادم',
            style: appTextStyle(size: 10, color: AppColors.muted),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: ListView.separated(
              itemCount: teams.length,
              separatorBuilder: (_, _) => const SizedBox(height: 9),
              itemBuilder: (context, index) =>
                  _TeamScoreCard(team: teams[index], rank: index + 1),
            ),
          ),
        ],
      ),
    );
  }
}

class ScoreboardStrip extends StatelessWidget {
  const ScoreboardStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final teams = [...controller.teams]
      ..sort((a, b) => b.score.compareTo(a.score));
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: teams.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) => SizedBox(
        width: 205,
        child: _TeamScoreCard(
          team: teams[index],
          rank: index + 1,
          compact: true,
        ),
      ),
    );
  }
}

class _TeamScoreCard extends StatelessWidget {
  final Team team;
  final int rank;
  final bool compact;
  const _TeamScoreCard({
    required this.team,
    required this.rank,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = context.read<GameController>();
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 11),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: rank == 1
              ? AppColors.gold.withValues(alpha: 0.8)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 25 : 28,
            height: compact ? 25 : 28,
            decoration: BoxDecoration(
              color: rank == 1 ? AppColors.gold : AppColors.border,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: appTextStyle(
                  size: 11,
                  weight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
          const SizedBox(width: 9),
          Container(
            width: 5,
            height: 38,
            decoration: BoxDecoration(
              color: team.color,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: appTextStyle(
                    size: compact ? 11 : 12,
                    weight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${controller.ownedCellCount(team.id)} مبنى  •  +${controller.calculateTeamIncome(team.id)} / ج',
                  style: appTextStyle(size: 9, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Text(
            '${team.score}',
            style: appTextStyle(
              size: compact ? 15 : 17,
              weight: FontWeight.w900,
              color: rank == 1 ? AppColors.gold : AppColors.text,
            ),
          ),
          if (!compact)
            IconButton(
              tooltip: 'تعديل النقاط',
              onPressed: () => _showScoreAdjustment(context, controller, team),
              icon: const Icon(
                Icons.edit_note_rounded,
                size: 19,
                color: AppColors.muted,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 26),
            ),
        ],
      ),
    );
  }

  void _showScoreAdjustment(
    BuildContext context,
    GameController controller,
    Team team,
  ) {
    final amount = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'تعديل نقاط ${team.name}',
            style: appTextStyle(size: 17, weight: FontWeight.w900),
          ),
          content: TextField(
            controller: amount,
            keyboardType: TextInputType.number,
            style: appTextStyle(),
            decoration: InputDecoration(
              labelText: 'موجب للإضافة، سالب للخصم',
              labelStyle: appTextStyle(size: 12, color: AppColors.muted),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('إلغاء', style: appTextStyle(color: AppColors.muted)),
            ),
            FilledButton(
              onPressed: () {
                final value = int.tryParse(amount.text);
                if (value != null) controller.adjustScore(team.id, value);
                Navigator.pop(dialogContext);
              },
              child: Text(
                'حفظ',
                style: appTextStyle(
                  size: 12,
                  weight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CellInspectorPanel extends StatelessWidget {
  final int? selectedIndex;
  final VoidCallback onClosed;
  const CellInspectorPanel({
    super.key,
    required this.selectedIndex,
    required this.onClosed,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedIndex == null) return _emptyState();
    final controller = context.watch<GameController>();
    final cell = controller.board[selectedIndex! - 1];
    final owner = cell.ownerTeamId == null
        ? null
        : controller.teams.firstWhere((team) => team.id == cell.ownerTeamId);
    final complex = controller.hasOwnedInfluence(
      cell.index,
      BuildingType.complex,
    );
    final factory = controller.hasOwnedInfluence(
      cell.index,
      BuildingType.factory,
    );
    final value = controller.calculateCellValue(cell.index);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'المربع ${cell.index}',
                  style: appTextStyle(size: 18, weight: FontWeight.w900),
                ),
              ),
              IconButton(
                onPressed: onClosed,
                tooltip: 'إغلاق',
                icon: const Icon(Icons.close_rounded, color: AppColors.muted),
              ),
            ],
          ),
          Text(
            'تفاصيل الملكية والتأثير',
            style: appTextStyle(size: 11, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          Text(
            'المالك',
            style: appTextStyle(
              size: 11,
              weight: FontWeight.w800,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _OwnerChip(
                label: 'شاغر',
                selected: owner == null,
                color: AppColors.quiet,
                onTap: () => controller.setCellOwner(cell.index, null),
              ),
              ...controller.teams.map(
                (team) => _OwnerChip(
                  label: team.name,
                  selected: owner?.id == team.id,
                  color: team.color,
                  onTap: () => controller.setCellOwner(cell.index, team.id),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'نوع المبنى',
            style: appTextStyle(
              size: 11,
              weight: FontWeight.w800,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 8) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: BuildingType.values
                    .map(
                      (type) => SizedBox(
                        width: width,
                        child: _BuildingChoice(
                          type: type,
                          selected: cell.buildingType == type,
                          enabled: owner != null,
                          onTap: () =>
                              controller.setCellBuilding(cell.index, type),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'العائد المتوقع في الجولة',
                  style: appTextStyle(size: 11, color: AppColors.muted),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      '$value',
                      style: appTextStyle(
                        size: 28,
                        weight: FontWeight.w900,
                        color: owner == null
                            ? AppColors.quiet
                            : AppColors.green,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'نقطة',
                      style: appTextStyle(
                        size: 11,
                        weight: FontWeight.w800,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 18),
                _ValueLine(
                  label: 'تكلفة البناء',
                  value: '${cell.buildingType.price} نقطة',
                ),
                _ValueLine(
                  label: 'القيمة الأساسية',
                  value: '${cell.buildingType.baseValue} نقطة',
                ),
                if (factory || complex) ...[
                  const SizedBox(height: 5),
                  Text(
                    factory && complex
                        ? 'تأثير مصنع + مجمع: عودة للقيمة الأساسية'
                        : factory
                        ? 'متأثر بمصنع قريب'
                        : 'متأثر بمجمع قريب',
                    style: appTextStyle(
                      size: 10,
                      weight: FontWeight.w800,
                      color: factory && complex
                          ? AppColors.gold
                          : AppColors.cyan,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app_rounded,
            color: AppColors.teal.withValues(alpha: 0.65),
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            'اختر مربعاً من الخريطة',
            style: appTextStyle(size: 14, weight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          Text(
            'ستظهر هنا خيارات الملكية والمبنى والعائد',
            textAlign: TextAlign.center,
            style: appTextStyle(size: 11, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _OwnerChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _OwnerChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.2) : AppColors.ink,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: appTextStyle(
                size: 10,
                weight: FontWeight.w800,
                color: selected ? AppColors.text : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuildingChoice extends StatelessWidget {
  final BuildingType type;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  const _BuildingChoice({
    required this.type,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.teal.withValues(alpha: 0.16)
                : AppColors.ink,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: selected ? AppColors.teal : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                buildingIconFor(type),
                size: 21,
                color: selected ? AppColors.teal : AppColors.muted,
              ),
              const SizedBox(height: 3),
              Text(
                type.arabicName,
                style: appTextStyle(size: 10, weight: FontWeight.w900),
              ),
              Text(
                '${type.price} ن',
                style: appTextStyle(size: 8, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValueLine extends StatelessWidget {
  final String label;
  final String value;
  const _ValueLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: appTextStyle(size: 10, color: AppColors.muted)),
          Text(value, style: appTextStyle(size: 10, weight: FontWeight.w800)),
        ],
      ),
    );
  }
}
