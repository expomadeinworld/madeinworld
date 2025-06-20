import '../../core/enums/store_type.dart';

class Store {
  final String id;
  final String name;
  final String city;
  final String address;
  final double latitude;
  final double longitude;
  final StoreType type;
  final bool isActive;

  Store({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.isActive = true,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'],
      name: json['name'],
      city: json['city'],
      address: json['address'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      type: StoreType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'type': type.toString().split('.').last,
      'is_active': isActive,
    };
  }
}


