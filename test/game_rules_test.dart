import 'package:flutter_test/flutter_test.dart';
import 'package:cultural_building_competition/controllers/game_controller.dart';
import 'package:cultural_building_competition/models/building.dart';

void main() {
  group('Game Rules & Calculations Tests', () {
    late GameController controller;

    setUp(() {
      controller = GameController();
    });

    test('Initial board is empty and scores are zero', () {
      expect(controller.roundNumber, equals(1));
      expect(controller.board.length, equals(100));
      for (var cell in controller.board) {
        expect(cell.ownerTeamId, isNull);
        expect(cell.buildingType, equals(BuildingType.house));
      }
      for (var team in controller.teams) {
        expect(team.score, equals(0));
      }
    });

    test('Base values are correct when no modifiers are present', () {
      // Set different buildings on different tiles (no overlap or surrounding Complex/Factory)
      // Cell 1: House -> 200
      // Cell 3: Grocery -> 350
      // Cell 5: Market -> 400
      // Cell 7: Hotel -> 450
      // Cell 9: Factory -> 600
      // Cell 11: Complex -> 600

      controller.setCellBuilding(1, BuildingType.house);
      controller.setCellBuilding(3, BuildingType.grocery);
      controller.setCellBuilding(5, BuildingType.market);
      controller.setCellBuilding(7, BuildingType.hotel);
      controller.setCellBuilding(9, BuildingType.factory);
      controller.setCellBuilding(51, BuildingType.complex);

      expect(controller.calculateCellValue(1), equals(200));
      expect(controller.calculateCellValue(3), equals(350));
      expect(controller.calculateCellValue(5), equals(400));
      expect(controller.calculateCellValue(7), equals(450));
      expect(controller.calculateCellValue(9), equals(600));
      expect(controller.calculateCellValue(51), equals(600));
    });

    test('Complex modifiers boost house/hotel, penalize grocery/market', () {
      // Cell 5: Complex (row 1, col 5)
      controller.setCellBuilding(5, BuildingType.complex);

      // Surrounding cells of 5:
      // Row 1: col 4 (index 4), col 6 (index 6)
      // Row 2: col 4 (index 14), col 5 (index 15), col 6 (index 16)
      controller.setCellBuilding(
        4,
        BuildingType.house,
      ); // should be 350 (base 200)
      controller.setCellBuilding(
        6,
        BuildingType.hotel,
      ); // should be 600 (base 450)
      controller.setCellBuilding(
        14,
        BuildingType.grocery,
      ); // should be 200 (base 350)
      controller.setCellBuilding(
        16,
        BuildingType.market,
      ); // should be 250 (base 400)

      expect(controller.calculateCellValue(4), equals(350));
      expect(controller.calculateCellValue(6), equals(600));
      expect(controller.calculateCellValue(14), equals(200));
      expect(controller.calculateCellValue(16), equals(250));
    });

    test('Factory modifiers penalize house/hotel, boost grocery/market', () {
      // Cell 15: Factory (row 2, col 5)
      controller.setCellBuilding(15, BuildingType.factory);

      // Surrounding cells of 15:
      // Row 1: col 4 (index 4), col 5 (index 5), col 6 (index 6)
      // Row 2: col 4 (index 14), col 6 (index 16)
      // Row 3: col 4 (index 24), col 5 (index 25), col 6 (index 26)
      controller.setCellBuilding(
        5,
        BuildingType.house,
      ); // should be 50 (base 200)
      controller.setCellBuilding(
        6,
        BuildingType.hotel,
      ); // should be 300 (base 450)
      controller.setCellBuilding(
        14,
        BuildingType.grocery,
      ); // should be 500 (base 350)
      controller.setCellBuilding(
        16,
        BuildingType.market,
      ); // should be 550 (base 400)

      expect(controller.calculateCellValue(5), equals(50));
      expect(controller.calculateCellValue(6), equals(300));
      expect(controller.calculateCellValue(14), equals(500));
      expect(controller.calculateCellValue(16), equals(550));
    });

    test(
      'Overlapping Complex and Factory cancels modifiers (restores base)',
      () {
        // Cell 5: Complex (row 1, col 5)
        // Cell 15: Factory (row 2, col 5)
        controller.setCellBuilding(5, BuildingType.complex);
        controller.setCellBuilding(15, BuildingType.factory);

        // Cell 6 (row 1, col 6) is surrounding to BOTH 5 and 15
        controller.setCellBuilding(6, BuildingType.house); // base 200
        controller.setCellBuilding(16, BuildingType.grocery); // base 350

        expect(controller.calculateCellValue(6), equals(200));
        expect(controller.calculateCellValue(16), equals(350));
      },
    );

    test('Gameplay loop: endRound calculations and build cost deductions', () {
      // Round 1:
      // Team 1 ('team1') owns cell 1 (House, price 100, value 200)
      controller.setCellOwner(1, 'team1');
      controller.setCellBuilding(1, BuildingType.house);

      // Run endRound
      controller.endRound();

      // Team 1 points: 0 + 200 (House value) - 100 (House price) = 100
      expect(controller.teams[0].score, equals(100));
      expect(controller.roundNumber, equals(2));

      // Round 2:
      // Keep everything the same. No new buildings built.
      controller.endRound();

      // Team 1 points: 100 + 200 (House value) - 0 (no build price) = 300
      expect(controller.teams[0].score, equals(300));
      expect(controller.roundNumber, equals(3));

      // Round 3:
      // Change cell 1 to a Hotel (price 400, value 450)
      controller.setCellBuilding(1, BuildingType.hotel);
      controller.endRound();

      // Team 1 points: 300 + 450 (Hotel value) - 400 (Hotel price) = 350
      expect(controller.teams[0].score, equals(350));
      expect(controller.roundNumber, equals(4));

      // Undo Round 3
      controller.undo();
      expect(controller.roundNumber, equals(3));
      expect(controller.teams[0].score, equals(300));

      // Undo Round 2
      controller.undo();
      expect(controller.roundNumber, equals(2));
      expect(controller.teams[0].score, equals(100));
    });

    test('Removing an owner clears the building and its influence', () {
      controller.setCellOwner(15, 'team1');
      controller.setCellBuilding(15, BuildingType.factory);
      controller.setCellOwner(5, 'team2');
      controller.setCellBuilding(5, BuildingType.house);

      expect(controller.calculateCellValue(5), equals(50));

      controller.setCellOwner(15, null);

      expect(controller.board[14].buildingType, equals(BuildingType.house));
      expect(controller.calculateCellValue(5), equals(200));
    });

    test('A custom value override can be cleared', () {
      controller.setCellOwner(1, 'team1');
      controller.setCellBuilding(1, BuildingType.house);
      controller.setCellOverrideValue(1, 999);
      expect(controller.calculateCellValue(1), equals(999));

      controller.setCellOverrideValue(1, null);
      expect(controller.calculateCellValue(1), equals(200));
    });

    test('The competition stops after six rounds', () {
      for (var i = 0; i < GameController.maxRounds; i++) {
        controller.endRound();
      }

      expect(controller.isGameOver, isTrue);
      expect(controller.roundNumber, equals(7));

      controller.endRound();
      expect(controller.roundNumber, equals(7));
    });
  });
}
