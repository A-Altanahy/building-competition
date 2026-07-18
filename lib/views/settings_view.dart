import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/game_controller.dart';
import '../models/game_settings.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final Map<String, TextEditingController> _nameControllers = {};
  final Map<String, Color> _selectedColors = {};
  final TextEditingController _saveNameController = TextEditingController();
  List<File> _savedFiles = [];

  // 12 beautiful presets for team colors
  final List<Color> _colorPresets = const [
    Color(0xFFEF4444), // Rose Red
    Color(0xFFF97316), // Orange
    Color(0xFFF59E0B), // Amber Yellow
    Color(0xFF10B981), // Emerald Green
    Color(0xFF06B6D4), // Cyan/Teal
    Color(0xFF3B82F6), // Royal Blue
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Violet Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF64748B), // Slate Grey
    Color(0xFF78350F), // Brown
    Color(0xFF1E3A8A), // Navy Blue
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedGames();
  }

  void _loadSavedGames() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = Provider.of<GameController>(context, listen: false);
      final files = await controller.getSavedGames();
      setState(() {
        _savedFiles = files;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = Provider.of<GameController>(context);
    final settings = controller.settings;

    // Initialize controllers with current names and colors
    for (var key in settings.teamNames.keys) {
      if (!_nameControllers.containsKey(key)) {
        _nameControllers[key] = TextEditingController(text: settings.teamNames[key]);
      }
      if (!_selectedColors.containsKey(key)) {
        _selectedColors[key] = settings.teamColors[key] ?? Colors.grey;
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _nameControllers.values) {
      controller.dispose();
    }
    _saveNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<GameController>(context);

    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 900;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إعدادات اللعبة وإدارة البيانات',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            Text(
              'تعديل أسماء الفرق والألوان، حفظ وتحميل ملفات اللعبة، وإعادة التعيين',
              style: GoogleFonts.cairo(
                color: const Color(0xFF64748B),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 30),

            if (isNarrow)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Team Customization Form
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تخصيص أسماء الفرق وألوانها',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ..._nameControllers.keys.map((key) => _buildTeamEditor(key)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981), // Emerald 500
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            _applySettings(controller);
                          },
                          icon: const Icon(Icons.check_circle_rounded),
                          label: Text(
                            'حفظ وتطبيق التغييرات الجديدة',
                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Actions Section
                  _buildActionsColumn(controller),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Right Section: Team Customization Form
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تخصيص أسماء الفرق وألوانها',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ..._nameControllers.keys.map((key) => _buildTeamEditor(key)),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981), // Emerald 500
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              _applySettings(controller);
                            },
                            icon: const Icon(Icons.check_circle_rounded),
                            label: Text(
                              'حفظ وتطبيق التغييرات الجديدة',
                              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Left Section: Save/Load & Actions
                  Expanded(
                    flex: 2,
                    child: _buildActionsColumn(controller),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsColumn(GameController controller) {
    return Column(
      children: [
        // Save Game
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'حفظ حالة اللعبة الحالية',
                style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _saveNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'اسم ملف الحفظ (مثال: الجولة الأولى)',
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
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final name = _saveNameController.text.trim();
                  if (name.isNotEmpty) {
                    await controller.saveToFile(name);
                    _saveNameController.clear();
                    _loadSavedGames();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF10B981),
                        content: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            'تم حفظ اللعبة بنجاح!',
                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.save_rounded, size: 18),
                label: Text('حفظ اللعبة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Saved Files List
        Container(
          height: 280,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الألعاب المحفوظة سابقًا',
                style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _savedFiles.isEmpty
                    ? Center(
                        child: Text(
                          'لا توجد ألعاب محفوظة حاليًا',
                          style: GoogleFonts.cairo(color: const Color(0xFF64748B), fontSize: 12),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _savedFiles.length,
                        itemBuilder: (context, index) {
                          final file = _savedFiles[index];
                          final filename = file.path.split('/').last.replaceAll('.json', '');

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF334155)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    filename,
                                    style: GoogleFonts.cairo(color: Colors.white, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.file_open_rounded, color: Colors.green, size: 20),
                                      tooltip: 'تحميل اللعبة',
                                      onPressed: () {
                                        _confirmLoadGame(context, controller, file);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_rounded, color: Colors.red, size: 20),
                                      tooltip: 'حذف ملف الحفظ',
                                      onPressed: () async {
                                        await file.delete();
                                        _loadSavedGames();
                                      },
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
          ),
        ),
        const SizedBox(height: 20),

        // Reset Game
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'منطقة خطر (إعادة الضبط)',
                style: GoogleFonts.cairo(color: const Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'سيؤدي هذا الخيار إلى مسح جميع النقاط وإخلاء جميع خلايا الأراضي والبدء بلعبة جديدة تمامًا.',
                style: GoogleFonts.cairo(color: const Color(0xFF94A3B8), fontSize: 11),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  _confirmResetGame(context, controller);
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text('إعادة ضبط اللعبة كاملة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamEditor(String teamKey) {
    final currentColor = _selectedColors[teamKey] ?? Colors.grey;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'فريق ${teamKey.replaceAll('team', '')}:',
                style: GoogleFonts.cairo(color: const Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _nameControllers[teamKey],
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Presets Color picker
          Padding(
            padding: const EdgeInsets.only(right: 64.0),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _colorPresets.map((color) {
                final isSelected = currentColor.value == color.value;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedColors[teamKey] = color;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 4, spreadRadius: 1)]
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(color: Color(0xFF334155), height: 30),
        ],
      ),
    );
  }

  void _applySettings(GameController controller) {
    final Map<String, String> names = {};
    final Map<String, Color> colors = {};

    for (var key in _nameControllers.keys) {
      names[key] = _nameControllers[key]!.text.trim().isNotEmpty
          ? _nameControllers[key]!.text.trim()
          : controller.settings.teamNames[key]!;
      colors[key] = _selectedColors[key] ?? controller.settings.teamColors[key]!;
    }

    controller.updateSettings(
      GameSettings(
        teamNames: names,
        teamColors: colors,
        gridRows: controller.settings.gridRows,
        gridCols: controller.settings.gridCols,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF10B981),
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            'تم تطبيق وحفظ الإعدادات الجديدة للفرق بنجاح!',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  void _confirmLoadGame(BuildContext context, GameController controller, File file) {
    final filename = file.path.split('/').last.replaceAll('.json', '');
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: Text('تحميل اللعبة المحفوظة', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
            content: Text(
              'هل تريد بالتأكيد تحميل ملف الحفظ "$filename"؟ سيتم فقدان تقدم اللعبة الحالية غير المحفوظ.',
              style: GoogleFonts.cairo(color: const Color(0xFF94A3B8)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('إلغاء', style: GoogleFonts.cairo(color: const Color(0xFF94A3B8))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                onPressed: () async {
                  await controller.loadFromFile(file);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF10B981),
                      content: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          'تم تحميل ملف الحفظ "$filename" بنجاح!',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                },
                child: Text('تحميل الآن', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmResetGame(BuildContext context, GameController controller) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: Text('إعادة ضبط اللعبة', style: GoogleFonts.cairo(color: const Color(0xFFEF4444), fontWeight: FontWeight.bold)),
            content: Text(
              'هل تريد بالتأكيد إخلاء اللوحة بالكامل وتصفير نقاط جميع الفرق للبدء من الصفر؟ لا يمكن التراجع عن هذا الإجراء.',
              style: GoogleFonts.cairo(color: const Color(0xFF94A3B8)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('إلغاء', style: GoogleFonts.cairo(color: const Color(0xFF94A3B8))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                onPressed: () {
                  controller.initializeGame();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFFEF4444),
                      content: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          'تمت إعادة ضبط اللعبة بالكامل!',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                },
                child: Text('نعم، إعادة ضبط', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }
}
