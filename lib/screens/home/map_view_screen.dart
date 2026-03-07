import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/listing_model.dart';
import '../../providers/listing_provider.dart';
import '../listing/listing_detail_screen.dart';

class MapViewScreen extends ConsumerStatefulWidget {
  const MapViewScreen({super.key});

  @override
  ConsumerState<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends ConsumerState<MapViewScreen> {
  final MapController _mapController = MapController();
  
  // Kigali city center coordinates
  static const LatLng _kigaliCenter = LatLng(-1.9403, 29.8739);
  static const double _defaultZoom = 13.0;
  
  LatLng? _currentLocation;
  bool _isLoadingLocation = false;
  ListingCategory? _selectedCategory;
  ListingModel? _selectedListing;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location services are disabled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are permanently denied'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  void _centerOnLocation() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 15.0);
    } else {
      _mapController.move(_kigaliCenter, _defaultZoom);
    }
  }

  void _showListingDetails(ListingModel listing) {
    setState(() => _selectedListing = listing);
    
    // Center map on selected listing
    _mapController.move(
      LatLng(listing.latitude, listing.longitude),
      16.0,
    );
  }

  Color _getCategoryColor(ListingCategory category) {
    switch (category) {
      case ListingCategory.hospital:
        return Colors.red;
      case ListingCategory.policeStation:
        return Colors.blue;
      case ListingCategory.library:
        return Colors.purple;
      case ListingCategory.restaurant:
        return Colors.orange;
      case ListingCategory.cafe:
        return Colors.brown;
      case ListingCategory.park:
        return Colors.green;
      case ListingCategory.touristAttraction:
        return Colors.teal;
      case ListingCategory.utilityOffice:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(ListingCategory category) {
    switch (category) {
      case ListingCategory.hospital:
        return Icons.local_hospital;
      case ListingCategory.policeStation:
        return Icons.local_police;
      case ListingCategory.library:
        return Icons.local_library;
      case ListingCategory.restaurant:
        return Icons.restaurant;
      case ListingCategory.cafe:
        return Icons.local_cafe;
      case ListingCategory.park:
        return Icons.park;
      case ListingCategory.touristAttraction:
        return Icons.museum;
      case ListingCategory.utilityOffice:
        return Icons.business;
    }
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(listingsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map View'),
        elevation: 0,
        actions: [
          if (_isLoadingLocation)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: _getCurrentLocation,
              tooltip: 'Get my location',
            ),
        ],
      ),
      body: Column(
        children: [
          // Category filter chips
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: const Text('All'),
                    selected: _selectedCategory == null,
                    onSelected: (_) {
                      setState(() => _selectedCategory = null);
                    },
                  ),
                ),
                ...ListingCategory.values.map((category) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      avatar: Icon(
                        _getCategoryIcon(category),
                        size: 18,
                        color: _selectedCategory == category
                            ? Colors.white
                            : _getCategoryColor(category),
                      ),
                      label: Text(category.displayName),
                      selected: _selectedCategory == category,
                      selectedColor: _getCategoryColor(category),
                      onSelected: (_) {
                        setState(() {
                          _selectedCategory = _selectedCategory == category
                              ? null
                              : category;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          // Map
          Expanded(
            child: Stack(
              children: [
                listingsAsync.when(
                  data: (listings) {
                    // Filter listings by category if selected
                    final filteredListings = _selectedCategory != null
                        ? listings.where((l) => l.category == _selectedCategory).toList()
                        : listings;

                    return FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _kigaliCenter,
                        initialZoom: _defaultZoom,
                        onTap: (_, __) {
                          setState(() => _selectedListing = null);
                        },
                      ),
                      children: [
                        // OpenStreetMap tiles (free, no API key needed)
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.kigali.cityservices',
                          maxZoom: 19,
                        ),
                        // Current location marker
                        if (_currentLocation != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _currentLocation!,
                                width: 40,
                                height: 40,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.3),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.blue,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.my_location,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        // Listing markers
                        MarkerLayer(
                          markers: filteredListings.map((listing) {
                            final isSelected = _selectedListing?.id == listing.id;
                            return Marker(
                              point: LatLng(listing.latitude, listing.longitude),
                              width: isSelected ? 50 : 40,
                              height: isSelected ? 50 : 40,
                              child: GestureDetector(
                                onTap: () => _showListingDetails(listing),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? _getCategoryColor(listing.category)
                                        : _getCategoryColor(listing.category).withValues(alpha: 0.8),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: isSelected ? 3 : 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        blurRadius: isSelected ? 8 : 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      _getCategoryIcon(listing.category),
                                      color: Colors.white,
                                      size: isSelected ? 24 : 20,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
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
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error loading map: $error'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(listingsStreamProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                // Map controls
                Positioned(
                  right: 16,
                  bottom: _selectedListing != null ? 200 : 16,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'zoom_in',
                        onPressed: () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(
                            _mapController.camera.center,
                            currentZoom + 1,
                          );
                        },
                        child: const Icon(Icons.add),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'zoom_out',
                        onPressed: () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(
                            _mapController.camera.center,
                            currentZoom - 1,
                          );
                        },
                        child: const Icon(Icons.remove),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'center',
                        onPressed: _centerOnLocation,
                        child: const Icon(Icons.center_focus_strong),
                      ),
                    ],
                  ),
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
                                  color: _getCategoryColor(_selectedListing!.category)
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Icon(
                                    _getCategoryIcon(_selectedListing!.category),
                                    color: _getCategoryColor(_selectedListing!.category),
                                    size: 28,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
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
                                      _selectedListing!.category.displayName,
                                      style: TextStyle(
                                        color: _getCategoryColor(_selectedListing!.category),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            _selectedListing!.address,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
