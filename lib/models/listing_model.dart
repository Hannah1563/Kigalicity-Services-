import 'package:cloud_firestore/cloud_firestore.dart';

enum ListingCategory {
  hospital,
  policeStation,
  library,
  restaurant,
  cafe,
  park,
  touristAttraction,
  utilityOffice,
}

extension ListingCategoryExtension on ListingCategory {
  String get displayName {
    switch (this) {
      case ListingCategory.hospital:
        return 'Hospital';
      case ListingCategory.policeStation:
        return 'Police Station';
      case ListingCategory.library:
        return 'Library';
      case ListingCategory.restaurant:
        return 'Restaurant';
      case ListingCategory.cafe:
        return 'Café';
      case ListingCategory.park:
        return 'Park';
      case ListingCategory.touristAttraction:
        return 'Tourist Attraction';
      case ListingCategory.utilityOffice:
        return 'Utility Office';
    }
  }

  String get icon {
    switch (this) {
      case ListingCategory.hospital:
        return '🏥';
      case ListingCategory.policeStation:
        return '🚔';
      case ListingCategory.library:
        return '📚';
      case ListingCategory.restaurant:
        return '🍽️';
      case ListingCategory.cafe:
        return '☕';
      case ListingCategory.park:
        return '🌳';
      case ListingCategory.touristAttraction:
        return '🏛️';
      case ListingCategory.utilityOffice:
        return '🏢';
    }
  }

  static ListingCategory fromString(String value) {
    return ListingCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ListingCategory.restaurant,
    );
  }
}

class ListingModel {
  final String? id;
  final String name;
  final ListingCategory category;
  final String address;
  final String contactNumber;
  final String description;
  final double latitude;
  final double longitude;
  final String createdBy;
  final DateTime timestamp;

  ListingModel({
    this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.contactNumber,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.createdBy,
    required this.timestamp,
  });

  factory ListingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ListingModel(
      id: doc.id,
      name: data['name'] ?? '',
      category: ListingCategoryExtension.fromString(data['category'] ?? ''),
      address: data['address'] ?? '',
      contactNumber: data['contactNumber'] ?? '',
      description: data['description'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      createdBy: data['createdBy'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category.name,
      'address': address,
      'contactNumber': contactNumber,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'createdBy': createdBy,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  ListingModel copyWith({
    String? id,
    String? name,
    ListingCategory? category,
    String? address,
    String? contactNumber,
    String? description,
    double? latitude,
    double? longitude,
    String? createdBy,
    DateTime? timestamp,
  }) {
    return ListingModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      address: address ?? this.address,
      contactNumber: contactNumber ?? this.contactNumber,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdBy: createdBy ?? this.createdBy,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
