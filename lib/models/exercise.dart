class Exercise {
  final String name;
  final int targetOutput;
  final String unit;

  Exercise({required this.name, required this.targetOutput, required this.unit});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'targetOutput': targetOutput,
      'unit': unit,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      name: map['name'] as String,
      targetOutput: map['targetOutput'] as int,
      unit: map['unit'] as String,
    );
  }
}
