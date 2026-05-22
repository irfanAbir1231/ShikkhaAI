/// Student domain model representing a registered user.
class Student {
  const Student({
    required this.id,
    required this.name,
    required this.email,
    required this.gradeLevel,
  });

  final int id;
  final String name;
  final String email;
  final String gradeLevel;

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      gradeLevel: json['grade_level'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'grade_level': gradeLevel,
      };

  Student copyWith({
    int? id,
    String? name,
    String? email,
    String? gradeLevel,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      gradeLevel: gradeLevel ?? this.gradeLevel,
    );
  }

  @override
  String toString() =>
      'Student(id: $id, name: $name, email: $email, gradeLevel: $gradeLevel)';
}
