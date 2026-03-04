import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/listing_service.dart';
import '../models/listing_model.dart';

// Listing Service Provider
final listingServiceProvider = Provider<ListingService>((ref) {
  return ListingService();
});

// All Listings Stream Provider
final listingsStreamProvider = StreamProvider<List<ListingModel>>((ref) {
  final listingService = ref.watch(listingServiceProvider);
  return listingService.getListingsStream();
});

// User Listings Stream Provider
final userListingsStreamProvider = StreamProvider.family<List<ListingModel>, String>((ref, userId) {
  final listingService = ref.watch(listingServiceProvider);
  return listingService.getUserListingsStream(userId);
});

// Category Filter Notifier (Riverpod 3.x)
class SelectedCategoryNotifier extends Notifier<ListingCategory?> {
  @override
  ListingCategory? build() => null;

  void set(ListingCategory? category) => state = category;
}

final selectedCategoryProvider = NotifierProvider<SelectedCategoryNotifier, ListingCategory?>(() {
  return SelectedCategoryNotifier();
});

// Search Query Notifier (Riverpod 3.x)
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String query) => state = query;
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() {
  return SearchQueryNotifier();
});

// Filtered Listings Provider
final filteredListingsProvider = Provider<AsyncValue<List<ListingModel>>>((ref) {
  final listingsAsync = ref.watch(listingsStreamProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();

  return listingsAsync.when(
    data: (listings) {
      var filtered = listings;

      // Filter by category
      if (selectedCategory != null) {
        filtered = filtered.where((l) => l.category == selectedCategory).toList();
      }

      // Filter by search query
      if (searchQuery.isNotEmpty) {
        filtered = filtered.where((l) =>
            l.name.toLowerCase().contains(searchQuery) ||
            l.address.toLowerCase().contains(searchQuery) ||
            l.description.toLowerCase().contains(searchQuery)).toList();
      }

      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

// Listing Notifier for CRUD operations using new Riverpod 2.0+ syntax
class ListingNotifier extends Notifier<AsyncValue<void>> {
  late ListingService _listingService;

  @override
  AsyncValue<void> build() {
    _listingService = ref.watch(listingServiceProvider);
    return const AsyncValue.data(null);
  }

  Future<String> createListing(ListingModel listing) async {
    state = const AsyncValue.loading();
    try {
      final id = await _listingService.createListing(listing);
      state = const AsyncValue.data(null);
      return id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateListing(String id, ListingModel listing) async {
    state = const AsyncValue.loading();
    try {
      await _listingService.updateListing(id, listing);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteListing(String id) async {
    state = const AsyncValue.loading();
    try {
      await _listingService.deleteListing(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final listingNotifierProvider = NotifierProvider<ListingNotifier, AsyncValue<void>>(() {
  return ListingNotifier();
});

// Single Listing Provider
final singleListingProvider = FutureProvider.family<ListingModel?, String>((ref, id) async {
  final listingService = ref.watch(listingServiceProvider);
  return listingService.getListing(id);
});
