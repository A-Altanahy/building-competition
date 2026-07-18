import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/team.dart';
import '../models/building.dart';
import '../models/board_cell.dart';
import '../models/game_settings.dart';
import '../models/game_state.dart';

class GameController extends ChangeNotifier {
  GameSettings _settings = GameSettings.defaultSettings();
  late List<Team> _teams;
  late List<BoardCell> _board;
  int _roundNumber = 1;

  // History stack for undo/redo
  final List<GameState> _undoStack = [];
  final List<GameState> _redoStack = [];

  // Track owners and buildings from the previous round to calculate build cost deductions
  Map<int, String?> _previousRoundOwners = {};
  Map<int, BuildingType> _previousRoundBuildings = {};

  GameSettings get settings => _settings;
  List<Team> get teams => _teams;
  List<BoardCell> get board => _board;
  int get roundNumber => _roundNumber;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  GameController() {
    initializeGame();
  }

  void initializeGame() {
    _teams = _settings.teamNames.entries.map((entry) {
      return Team(
        id: entry.key,
        name: entry.value,
        color: _settings.teamColors[entry.key] ?? Colors.grey,
        score: 0,
      );
    }).toList();

    _board = List.generate(
      _settings.gridRows * _settings.gridCols,
      (index) => BoardCell(
        index: index + 1,
        ownerTeamId: null,
        buildingType: BuildingType.house,
      ),
    );

    _roundNumber = 1;
    _previousRoundOwners.clear();
    _previousRoundBuildings.clear();
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }

  // Returns list of surrounding indices (1-indexed)
  List<int> getSurroundingIndices(int index) {
    List<int> surrounding = [];
    int rows = _settings.gridRows;
    int cols = _settings.gridCols;

    int row = ((index - 1) ~/ cols) + 1;
    int col = ((index - 1) % cols) + 1;

    for (int r = -1; r <= 1; r++) {
      for (int c = -1; c <= 1; c++) {
        if (r == 0 && c == 0) continue;
        int newRow = row + r;
        int newCol = col + c;
        if (newRow >= 1 && newRow <= rows && newCol >= 1 && newCol <= cols) {
          surrounding.add((newRow - 1) * cols + newCol);
        }
      }
    }
    return surrounding;
  }

  // Calculate cell value dynamically based on surrounding Complexes and Factories
  int calculateCellValue(int index) {
    final cell = _board[index - 1];
    
    // Custom overrides take highest priority if set
    if (cell.customValueOverride != null) {
      return cell.customValueOverride!;
    }

    final building = cell.buildingType;

    // Factory and Complex themselves are not affected by surrounding modifiers
    if (building == BuildingType.factory || building == BuildingType.complex) {
      return building.baseValue;
    }

    final surroundingIndices = getSurroundingIndices(index);
    final surroundingBuildings = surroundingIndices
        .map((idx) => _board[idx - 1].buildingType)
        .toList();

    final hasComplex = surroundingBuildings.contains(BuildingType.complex);
    final hasFactory = surroundingBuildings.contains(BuildingType.factory);

    // If both are present, or neither is, use the base value
    if ((hasComplex && hasFactory) || (!hasComplex && !hasFactory)) {
      return building.baseValue;
    }

    if (hasComplex) {
      switch (building) {
        case BuildingType.house:
          return 350;
        case BuildingType.hotel:
          return 600;
        case BuildingType.grocery:
          return 200;
        case BuildingType.market:
          return 250;
        default:
          return building.baseValue;
      }
    }

    if (hasFactory) {
      switch (building) {
        case BuildingType.house:
          return 50;
        case BuildingType.hotel:
          return 300;
        case BuildingType.grocery:
          return 500;
        case BuildingType.market:
          return 550;
        default:
          return building.baseValue;
      }
    }

    return building.baseValue;
  }

  // Set owner of cell (1-indexed)
  void setCellOwner(int index, String? teamId) {
    _board[index - 1] = _board[index - 1].copyWith(
      ownerTeamId: teamId,
      clearOwner: teamId == null,
    );
    notifyListeners();
  }

  // Set building type of cell (1-indexed)
  void setCellBuilding(int index, BuildingType buildingType) {
    _board[index - 1] = _board[index - 1].copyWith(
      buildingType: buildingType,
    );
    notifyListeners();
  }

  // Set cell override value
  void setCellOverrideValue(int index, int? value) {
    _board[index - 1] = _board[index - 1].copyWith(
      customValueOverride: value,
    );
    notifyListeners();
  }

  // Save current state snapshot to undo stack
  void _saveSnapshot() {
    _undoStack.add(
      GameState(
        board: _board.map((c) => c.copyWith()).toList(),
        teams: _teams.map((t) => t.copyWith()).toList(),
        roundNumber: _roundNumber,
        timestamp: DateTime.now(),
        previousRoundOwners: Map.from(_previousRoundOwners),
        previousRoundBuildings: Map.from(_previousRoundBuildings),
      ),
    );
    _redoStack.clear();
  }

  // End Round: calculate scores and deduct costs
  void endRound() {
    _saveSnapshot();

    // 1. Calculate building values for this round
    final cellValues = List.generate(
      _board.length,
      (i) => calculateCellValue(i + 1),
    );

    // 2. Track new round's building layout and owners
    final Map<int, String?> currentRoundOwners = {};
    final Map<int, BuildingType> currentRoundBuildings = {};

    // 3. Process score updates
    for (int i = 0; i < _board.length; i++) {
      final cell = _board[i];
      final index = cell.index;
      final ownerId = cell.ownerTeamId;

      if (ownerId != null) {
        final teamIndex = _teams.indexWhere((t) => t.id == ownerId);
        if (teamIndex != -1) {
          // Add income (calculated cell value)
          _teams[teamIndex].score += cellValues[i];

          // Check if building is newly built by this team on this cell
          final prevOwner = _previousRoundOwners[index];
          final prevBuilding = _previousRoundBuildings[index];

          // Charge price if:
          // - The cell was not owned by this team in the previous round
          // - OR the building type changed
          if (prevOwner != ownerId || prevBuilding != cell.buildingType) {
            // Deduct cost
            _teams[teamIndex].score -= cell.buildingType.price;
          }

          // Record for next round's baseline
          currentRoundOwners[index] = ownerId;
          currentRoundBuildings[index] = cell.buildingType;
        }
      }
    }

    // Update previous baseline
    _previousRoundOwners = currentRoundOwners;
    _previousRoundBuildings = currentRoundBuildings;

    // 4. Update team histories and increment round
    for (var team in _teams) {
      team.scoreHistory.add(team.score);
    }

    _roundNumber++;
    notifyListeners();
  }

  // Revert to previous round
  void undo() {
    if (!canUndo) return;

    // Save current state for redo
    _redoStack.add(
      GameState(
        board: _board.map((c) => c.copyWith()).toList(),
        teams: _teams.map((t) => t.copyWith()).toList(),
        roundNumber: _roundNumber,
        timestamp: DateTime.now(),
        previousRoundOwners: Map.from(_previousRoundOwners),
        previousRoundBuildings: Map.from(_previousRoundBuildings),
      ),
    );

    final previousState = _undoStack.removeLast();
    _board = previousState.board;
    _teams = previousState.teams;
    _roundNumber = previousState.roundNumber;
    _previousRoundOwners = previousState.previousRoundOwners;
    _previousRoundBuildings = previousState.previousRoundBuildings;

    notifyListeners();
  }

  // Redo undone action
  void redo() {
    if (!canRedo) return;

    _undoStack.add(
      GameState(
        board: _board.map((c) => c.copyWith()).toList(),
        teams: _teams.map((t) => t.copyWith()).toList(),
        roundNumber: _roundNumber,
        timestamp: DateTime.now(),
        previousRoundOwners: Map.from(_previousRoundOwners),
        previousRoundBuildings: Map.from(_previousRoundBuildings),
      ),
    );

    final nextState = _redoStack.removeLast();
    _board = nextState.board;
    _teams = nextState.teams;
    _roundNumber = nextState.roundNumber;
    _previousRoundOwners = nextState.previousRoundOwners;
    _previousRoundBuildings = nextState.previousRoundBuildings;

    notifyListeners();
  }

  // Adjust score manually (e.g. penalties, bonuses)
  void adjustScore(String teamId, int amount) {
    final index = _teams.indexWhere((t) => t.id == teamId);
    if (index != -1) {
      _saveSnapshot();
      _teams[index].score += amount;
      notifyListeners();
    }
  }

  // Save current game state to JSON
  String exportGameStateJson() {
    final Map<String, dynamic> data = {
      'settings': _settings.toJson(),
      'roundNumber': _roundNumber,
      'teams': _teams.map((t) => t.toJson()).toList(),
      'board': _board.map((c) => c.toJson()).toList(),
      'previousRoundOwners': _previousRoundOwners.map((k, v) => MapEntry(k.toString(), v)),
      'previousRoundBuildings': _previousRoundBuildings.map((k, v) => MapEntry(k.toString(), v.name)),
    };
    return jsonEncode(data);
  }

  // Load game state from JSON
  void importGameStateJson(String jsonString) {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;

    if (data.containsKey('settings')) {
      _settings = GameSettings.fromJson(data['settings'] as Map<String, dynamic>);
    }

    _roundNumber = data['roundNumber'] as int;

    _teams = (data['teams'] as List).map((t) => Team.fromJson(t as Map<String, dynamic>)).toList();

    _board = (data['board'] as List).map((c) => BoardCell.fromJson(c as Map<String, dynamic>)).toList();

    _previousRoundOwners.clear();
    if (data.containsKey('previousRoundOwners')) {
      final prevO = data['previousRoundOwners'] as Map<String, dynamic>;
      prevO.forEach((k, v) {
        _previousRoundOwners[int.parse(k)] = v as String?;
      });
    } else {
      // Fallback for older saves: initialize owners from current board owners
      for (var cell in _board) {
        if (cell.ownerTeamId != null) {
          _previousRoundOwners[cell.index] = cell.ownerTeamId;
        }
      }
    }

    _previousRoundBuildings.clear();
    if (data.containsKey('previousRoundBuildings')) {
      final prevB = data['previousRoundBuildings'] as Map<String, dynamic>;
      prevB.forEach((k, v) {
        _previousRoundBuildings[int.parse(k)] = BuildingType.values.byName(v as String);
      });
    }

    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }

  // Save game to default storage location or custom file
  Future<File> saveToFile(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/cultural_competition/$filename.json';
    final file = File(path);
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    return file.writeAsString(exportGameStateJson());
  }

  // Load game from file path
  Future<void> loadFromFile(File file) async {
    final contents = await file.readAsString();
    importGameStateJson(contents);
  }

  // Get list of saved files
  Future<List<File>> getSavedGames() async {
    final directory = await getApplicationDocumentsDirectory();
    final folderPath = '${directory.path}/cultural_competition';
    final folder = Directory(folderPath);
    if (!await folder.exists()) {
      return [];
    }
    return folder
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.json'))
        .cast<File>()
        .toList();
  }

  // Modify settings
  void updateSettings(GameSettings newSettings) {
    _settings = newSettings;
    initializeGame();
  }
}
