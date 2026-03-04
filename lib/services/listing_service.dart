import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';

class ListingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'listings';

  // Get all listings stream
  Stream<List<ListingModel>> getListingsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ListingModel.fromFirestore(doc)).toList());
  }

  // Get user's listings stream
  Stream<List<ListingModel>> getUserListingsStream(String userId) {
    return _firestore
        .collection(_collection)
        .where('createdBy', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ListingModel.fromFirestore(doc)).toList());
  }

  // Get listings by category stream
  Stream<List<ListingModel>> getListingsByCategoryStream(ListingCategory category) {
    return _firestore
        .collection(_collection)
        .where('category', isEqualTo: category.name)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ListingModel.fromFirestore(doc)).toList());
  }

  // Get single listing
  Future<ListingModel?> getListing(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (doc.exists) {
      return ListingModel.fromFirestore(doc);
    }
    return null;
  }

  // Create listing
  Future<String> createListing(ListingModel listing) async {
    final docRef = await _firestore.collection(_collection).add(
          listing.toFirestore(),
        );
    return docRef.id;
  }

  // Update listing
  Future<void> updateListing(String id, ListingModel listing) async {
    await _firestore.collection(_collection).doc(id).update(
          listing.toFirestore(),
        );
  }

  // Delete listing
  Future<void> deleteListing(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  // Search listings by name
  Future<List<ListingModel>> searchListings(String query) async {
    final snapshot = await _firestore
        .collection(_collection)
        .orderBy('name')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .get();

    return snapshot.docs.map((doc) => ListingModel.fromFirestore(doc)).toList();
  }

  // Get all listings (one-time fetch)
  Future<List<ListingModel>> getAllListings() async {
    final snapshot = await _firestore
        .collection(_collection)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) => ListingModel.fromFirestore(doc)).toList();
  }
}
