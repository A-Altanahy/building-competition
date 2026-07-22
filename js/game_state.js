/* ==========================================================================
   الأشبال - تحدي البناء (Building Competition) - Game State & Rules Engine
   ========================================================================== */

class GameState {
  constructor() {
    this.currentRound = 1;
    this.activeTeamIndex = 0;
    
    this.teams = [
      { id: 'team1', name: 'قاسم شادي', color: '#E63946', balance: 1000, score: 0 },
      { id: 'team2', name: 'مروان محمد', color: '#2563EB', balance: 1000, score: 0 },
      { id: 'team3', name: 'سليم سليمان', color: '#059669', balance: 1000, score: 0 },
      { id: 'team4', name: 'ياسين خالد', color: '#D97706', balance: 1000, score: 0 }
    ];

    // Official building prices
    this.buildingPrices = {
      'بيت': 150,
      'بقالة': 200,
      'فندق': 500,
      'سوق': 800
    };

    // Official base yields
    this.buildingBaseValues = {
      'بيت': 75,
      'بقالة': 150,
      'فندق': 250,
      'سوق': 350
    };

    this.buildingIcons = {
      'بيت': '🏠',
      'بقالة': '🛒',
      'فندق': '🏨',
      'سوق': '🕌'
    };

    // 10x10 grid (100 cells, indexed 1 to 100)
    this.board = {};
    for (let i = 1; i <= 100; i++) {
      this.board[i] = {
        index: i,
        teamId: null,
        building: null, // 'بيت', 'بقالة', 'فندق', 'سوق'
        overrideValue: null,
        shielded: false,
        frozen: false
      };
    }

    this.history = [];
  }

  // Get 8 surrounding cell indices for a given cell (1 to 100)
  getSurroundingIndices(cellIndex) {
    const row = Math.ceil(cellIndex / 10);
    const col = (cellIndex - 1) % 10 + 1;
    const result = [];

    for (let r = row - 1; r <= row + 1; r++) {
      for (let c = col - 1; c <= col + 1; c++) {
        if (r === row && c === col) continue; // skip center
        if (r >= 1 && r <= 10 && c >= 1 && c <= 10) {
          result.push((r - 1) * 10 + c);
        }
      }
    }
    return result;
  }

  // Calculate actual yield for a cell based on Souq (سوق) adjacency rules
  calculateCellValue(cellIndex) {
    const cell = this.board[cellIndex];
    if (!cell || !cell.building) return 0;
    if (cell.overrideValue !== null) return cell.overrideValue;

    const baseVal = this.buildingBaseValues[cell.building] || 0;
    if (cell.building === 'سوق') return baseVal;

    // Count adjacent Souqs (سوق)
    const surroundings = this.getSurroundingIndices(cellIndex);
    let souqCount = 0;
    for (const idx of surroundings) {
      if (this.board[idx] && this.board[idx].building === 'سوق') {
        souqCount++;
      }
    }

    if (souqCount === 0) return baseVal;

    // Rules:
    // - بيت (House): Base 75 → 150 with Souq (Doubles)
    // - بقالة (Grocery): Base 150 → 75 with Souq (Drops to half)
    // - فندق (Hotel): Base 250 → 450 with Souq (+200 Boost)
    if (cell.building === 'بيت') return 150;
    if (cell.building === 'بقالة') return 75;
    if (cell.building === 'فندق') return 450;

    return baseVal;
  }

  placeBuilding(cellIndex, buildingType, teamId) {
    this.saveStateToHistory();
    this.board[cellIndex].building = buildingType;
    this.board[cellIndex].teamId = teamId;
  }

  removeBuilding(cellIndex) {
    this.saveStateToHistory();
    this.board[cellIndex].building = null;
    this.board[cellIndex].teamId = null;
    this.board[cellIndex].overrideValue = null;
  }

  endRound() {
    this.saveStateToHistory();
    // Award yields to each team
    for (let i = 1; i <= 100; i++) {
      const cell = this.board[i];
      if (cell.building && cell.teamId) {
        const yieldVal = this.calculateCellValue(i);
        const team = this.teams.find(t => t.id === cell.teamId);
        if (team) {
          team.balance += yieldVal;
        }
      }
    }
    this.currentRound++;
  }

  saveStateToHistory() {
    const snapshot = {
      round: this.currentRound,
      activeTeamIndex: this.activeTeamIndex,
      teams: JSON.parse(JSON.stringify(this.teams)),
      board: JSON.parse(JSON.stringify(this.board))
    };
    this.history.push(snapshot);
    if (this.history.length > 20) this.history.shift();
  }

  undoRound() {
    if (this.history.length === 0) return;
    const lastState = this.history.pop();
    this.currentRound = lastState.round;
    this.activeTeamIndex = lastState.activeTeamIndex;
    this.teams = lastState.teams;
    this.board = lastState.board;
  }
}
