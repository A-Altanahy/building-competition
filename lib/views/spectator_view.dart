import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/game_controller.dart';
import '../models/team.dart';
import '../theme/app_theme.dart';
import '../utils/platform_utils.dart';
import '../widgets/competition_board.dart';

class SpectatorView extends StatelessWidget {
  const SpectatorView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.ink,
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
    final controller = context.watch<GameController>();
    final teams = [...controller.teams]
      ..sort((a, b) => b.score.compareTo(a.score));
    final compact = MediaQuery.sizeOf(context).width < 920;

    return Stack(
      children: [
        Column(
          children: [
            _SpectatorHeader(controller: controller),
            Expanded(
              child: compact
                  ? Column(
                      children: [
                        SizedBox(
                          height: 128,
                          child: _SpectatorStandings(
                            teams: teams,
                            compact: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(child: _SpectatorBoard()),
                      ],
                    )
                  : Row(
                      children: [
                        SizedBox(
                          width: 340,
                          child: _SpectatorStandings(teams: teams),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: _SpectatorBoard()),
                      ],
                    ),
            ),
          ],
        ),
        Positioned(
          top: 18,
          left: showBackButton ? 72 : 18,
          child: _CircleButton(
            icon: Icons.fullscreen_rounded,
            tooltip: 'شاشة كاملة',
            onTap: toggleWebFullScreen,
          ),
        ),
        if (showBackButton)
          Positioned(
            top: 18,
            left: 18,
            child: _CircleButton(
              icon: Icons.arrow_back_rounded,
              tooltip: 'عودة',
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
      ],
    );
  }
}

class _SpectatorHeader extends StatelessWidget {
  final GameController controller;
  const _SpectatorHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.teal, AppColors.cyan],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.apartment_rounded,
              color: AppColors.ink,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'دوري فتية الرشد',
                style: appTextStyle(size: 19, weight: FontWeight.w900),
              ),
              Text(
                'المسابقة الثقافية العقارية',
                style: appTextStyle(size: 11, color: AppColors.muted),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: controller.isGameOver
                  ? AppColors.gold.withValues(alpha: 0.15)
                  : AppColors.teal.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: controller.isGameOver ? AppColors.gold : AppColors.teal,
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
                  size: 18,
                ),
                const SizedBox(width: 7),
                Text(
                  controller.isGameOver
                      ? 'النتيجة النهائية'
                      : 'الجولة ${controller.roundNumber} من ${GameController.maxRounds}',
                  style: appTextStyle(size: 13, weight: FontWeight.w900),
                ),
              ],
            ),
          ),
          const SizedBox(width: 86),
        ],
      ),
    );
  }
}

class _SpectatorBoard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    return Container(
      margin: const EdgeInsets.only(left: 18, bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: panelDecoration(color: AppColors.canvas),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.map_rounded, color: AppColors.teal, size: 20),
              const SizedBox(width: 8),
              Text(
                'خريطة المدينة',
                style: appTextStyle(size: 16, weight: FontWeight.w900),
              ),
              const Spacer(),
              Text(
                '${controller.board.where((cell) => cell.ownerTeamId != null).length} مبنى مستثمَر',
                style: appTextStyle(size: 11, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(child: CompetitionBoard(spectator: true)),
        ],
      ),
    );
  }
}

class _SpectatorStandings extends StatelessWidget {
  final List<Team> teams;
  final bool compact;
  const _SpectatorStandings({required this.teams, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<GameController>();
    return Container(
      margin: EdgeInsets.only(
        right: compact ? 18 : 18,
        bottom: compact ? 0 : 18,
      ),
      padding: const EdgeInsets.all(16),
      decoration: panelDecoration(color: AppColors.surface),
      child: compact
          ? ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: teams.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) => SizedBox(
                width: 205,
                child: _StandingsCard(
                  team: teams[index],
                  rank: index + 1,
                  controller: controller,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: AppColors.gold,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ترتيب الفرق',
                      style: appTextStyle(size: 18, weight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  'النقاط الحالية والعائد المتوقع',
                  style: appTextStyle(size: 11, color: AppColors.muted),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: ListView.separated(
                    itemCount: teams.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _StandingsCard(
                      team: teams[index],
                      rank: index + 1,
                      controller: controller,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _StandingsCard extends StatelessWidget {
  final Team team;
  final int rank;
  final GameController controller;
  const _StandingsCard({
    required this.team,
    required this.rank,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: rank == 1 ? AppColors.gold : AppColors.border,
          width: rank == 1 ? 1.5 : 1,
        ),
        boxShadow: rank == 1
            ? [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  blurRadius: 14,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: rank == 1 ? AppColors.gold : AppColors.border,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: appTextStyle(
                  size: 12,
                  weight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 5,
            height: 32,
            decoration: BoxDecoration(
              color: team.color,
              borderRadius: BorderRadius.circular(6),
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
                  style: appTextStyle(size: 12, weight: FontWeight.w900),
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
              size: 18,
              weight: FontWeight.w900,
              color: rank == 1 ? AppColors.gold : AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _CircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: AppColors.text),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
