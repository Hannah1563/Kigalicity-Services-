import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/listing_model.dart';
import '../../providers/listing_provider.dart';
import '../listing/listing_detail_screen.dart';

class MapViewScreen extends ConsumerStatefulWidget {
  const MapViewScreen({super.key});

  @override
  ConsumerState<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends ConsumerState<MapViewScreen> {
  GoogleMapController? _mapController;
  ListingModel? _selectedListing;

  // Kigali center coordinates
  static const LatLng _kigaliCenter = LatLng(-1.9403, 29.8739);

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Set<Marker> _buildMarkers(List<ListingModel> listings) {
    return listings.map((listing) {
      return Marker(
        markerId: MarkerId(listing.id ?? ''),
        position: LatLng(listing.latitude, listing.longitude),
        infoWindow: InfoWindow(
          title: listing.name,
          snippet: listing.category.displayName,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ListingDetailScreen(
                  listingId: listing.id!,
                ),
              ),
            );
          },
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _getCategoryColor(listing.category),
        ),
        onTap: () {
          setState(() {
            _selectedListing = listing;
          });
        },
      );
    }).toSet();
  }

  double _getCategoryColor(ListingCategory category) {
    switch (category) {
      case ListingCategory.hospital:
        return BitmapDescriptor.hueRed;
      case ListingCategory.policeStation:
        return BitmapDescriptor.hueBlue;
      case ListingCategory.library:
        return BitmapDescriptor.hueOrange;
      case ListingCategory.restaurant:
        return BitmapDescriptor.hueYellow;
      case ListingCategory.cafe:
        return BitmapDescriptor.hueMagenta;
      case ListingCategory.park:
        return BitmapDescriptor.hueGreen;
      case ListingCategory.touristAttraction:
        return BitmapDescriptor.hueCyan;
      case ListingCategory.utilityOffice:
        return BitmapDescriptor.hueViolet;
    }
  }

  @override
  Widget build(BuildContext context) {
    final listings = ref.watch(listingsStreamProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map View'),
        elevation: 0,
        actions: [
          PopupMenuButton<ListingCategory?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by category',
            onSelected: (category) {
              ref.read(selectedCategoryProvider.notifier).set(category);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All Categories'),
              ),
              const PopupMenuDivider(),
              ...ListingCategory.values.map((category) {
                return PopupMenuItem(
                  value: category,
                  child: Row(
                    children: [
                      Text(category.icon),
                      const SizedBox(width: 8),
                      Text(category.displayName),
                    ],
                  ),
                );
              }),
            ],
          ),
        ],
      ),
      body: listings.when(
        data: (allListings) {
          // Filter listings if category is selected
          final filteredListings = selectedCategory != null
              ? allListings.where((l) => l.category == selectedCategory).toList()
              : allListings;

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: _kigaliCenter,
                  zoom: 12,
                ),
                markers: _buildMarkers(filteredListings),
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                onTap: (_) {
                  setState(() {
                    _selectedListing = null;
                  });
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: true,
                mapToolbarEnabled: true,
              ),
              // Selected listing card
              if (_selectedListing != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ListingDetailScreen(
                              listingId: _selectedListing!.id!,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  _selectedListing!.category.icon,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _selectedListing!.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedListing!.address,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              // Category filter indicator
              if (selectedCategory != null)
                Positioned(
                  top: 16,
                  left: 16,
                  child: Chip(
                    label: Text('${selectedCategory.icon} ${selectedCategory.displayName}'),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      ref.read(selectedCategoryProvider.notifier).set(null);
                    },
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              const Text('Error loading map data'),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  ref.invalidate(listingsStreamProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () {
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(_kigaliCenter, 12),
          );
        },
        child: const Icon(Icons.center_focus_strong),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}
