class UserProfile {
  final String name;
  final String gender;
  final int age;
  final double heightCm;
  final double weightKg;
  final List<String> goals;

  const UserProfile({
    required this.name,
    required this.gender,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.goals,
  });

  UserProfile copyWith({
    String? name,
    String? gender,
    int? age,
    double? heightCm,
    double? weightKg,
    List<String>? goals,
  }) {
    return UserProfile(
      name: name ?? this.name,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      goals: goals ?? this.goals,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'gender': gender,
      'age': age,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'goals': goals,
    };
  }
}
