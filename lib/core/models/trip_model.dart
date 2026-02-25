// lib/core/models/trip_model.dart
class Trip {
  final int? id;
  final String pickup;
  final String dropOff;
  final double fare;
  final String gasTier;
  final DateTime date;
  final int isSynced; // 0 for local, 1 for cloud

  Trip({
    this.id,
    required this.pickup,
    required this.dropOff,
    required this.fare,
    required this.gasTier,
    required this.date,
    this.isSynced = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pickup': pickup,
      'dropOff': dropOff,
      'fare': fare,
      'gasTier': gasTier,
      'date': date.toIso8601String(),
      'isSynced': isSynced,
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'],
      pickup: map['pickup'],
      dropOff: map['dropOff'],
      fare: map['fare'],
      gasTier: map['gasTier'],
      date: DateTime.parse(map['date']),
      isSynced: map['isSynced'],
    );
  }
}
