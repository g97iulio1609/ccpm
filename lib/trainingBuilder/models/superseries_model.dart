class SuperSet {
  String id;
  String? name;
  List<String> exerciseIds;

  SuperSet({
    required this.id,
    this.name,
    required this.exerciseIds,
  });

  factory SuperSet.fromMap(Map<String, dynamic> map) {
    return SuperSet(
      id: map['id'],
      name: map['name'],
      exerciseIds: List<String>.from(map['exerciseIds']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'exerciseIds': exerciseIds,
    };
  }
}
