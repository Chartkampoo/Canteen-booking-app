class CanteenTable {
  final String id;
  final String name;
  final String location;
  final int capacity;
  final bool isBooked;
  final String? bookedByUid;
  final String? bookedByName;

  const CanteenTable({
    required this.id,
    required this.name,
    required this.location,
    required this.capacity,
    this.isBooked = false,
    this.bookedByUid,
    this.bookedByName,
  });

  factory CanteenTable.fromMap(String id, Map<String, dynamic> data) {
    return CanteenTable(
      id: id,
      name: data['name'] ?? '',
      location: data['location'] ?? '',
      capacity: data['capacity'] ?? 4,
      isBooked: data['isBooked'] ?? false,
      bookedByUid: data['bookedByUid'],
      bookedByName: data['bookedByName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'capacity': capacity,
      'isBooked': isBooked,
      'bookedByUid': bookedByUid,
      'bookedByName': bookedByName,
    };
  }

  CanteenTable copyWith(
      {bool? isBooked, String? bookedByUid, String? bookedByName}) {
    return CanteenTable(
      id: id,
      name: name,
      location: location,
      capacity: capacity,
      isBooked: isBooked ?? this.isBooked,
      bookedByUid: bookedByUid,
      bookedByName: bookedByName,
    );
  }
}
