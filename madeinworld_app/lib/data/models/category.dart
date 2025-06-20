import '../../core/enums/store_type.dart';

class Category {
  final String id;
  final String name;
  final StoreTypeAssociation storeTypeAssociation;

  Category({
    required this.id,
    required this.name,
    required this.storeTypeAssociation,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      storeTypeAssociation: StoreTypeAssociation.values.firstWhere(
        (e) => e.toString().split('.').last == json['store_type_association'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'store_type_association': storeTypeAssociation.toString().split('.').last,
    };
  }
}


