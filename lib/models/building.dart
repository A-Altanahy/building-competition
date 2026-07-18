enum BuildingType {
  house('بيت', 200, 100),
  grocery('بقالة', 350, 200),
  market('سوق', 400, 300),
  hotel('فندق', 450, 400),
  factory('مصنع', 600, 1000),
  complex('مجمع', 600, 1000);

  final String arabicName;
  final int baseValue;
  final int price;

  const BuildingType(this.arabicName, this.baseValue, this.price);

  static BuildingType? fromArabicName(String name) {
    for (var val in BuildingType.values) {
      if (val.arabicName == name) return val;
    }
    return null;
  }

  String get englishName {
    switch (this) {
      case BuildingType.house:
        return 'House';
      case BuildingType.grocery:
        return 'Grocery';
      case BuildingType.market:
        return 'Market';
      case BuildingType.hotel:
        return 'Hotel';
      case BuildingType.factory:
        return 'Factory';
      case BuildingType.complex:
        return 'Complex';
    }
  }
}
