import 'package:flutter/material.dart';
import '../widgets/expandable_info_panel.dart';
import '../models/business.dart';
import '../components/search_bar.dart';
import '../widgets/business_list.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  final List<Business> _businesses = [
    Business(
      id: '1',
      name: 'Local Coffee Shop',
      category: 'Restaurant',
      description: 'Artisanal coffee and fresh pastries. Perfect for morning meetings.',
      address: '123 Main St',
      distance: 0.5,
      imageUrl: '',
      rating: 4.5,
      isOpen: true,
      tags: ['Coffee', 'Breakfast', 'WiFi'],
    ),
    Business(
      id: '2',
      name: 'Green Garden Market',
      category: 'Retail',
      description: 'Fresh organic produce and local products. Supporting local farmers.',
      address: '456 Oak Ave',
      distance: 1.2,
      imageUrl: '',
      rating: 4.8,
      isOpen: true,
      tags: ['Organic', 'Local', 'Fresh'],
    ),
    Business(
      id: '3',
      name: 'Tech Solutions Pro',
      category: 'Service',
      description: 'Professional IT services and computer repair. Quick turnaround guaranteed.',
      address: '789 Tech Blvd',
      distance: 2.1,
      imageUrl: '',
      rating: 4.2,
      isOpen: false,
      tags: ['IT', 'Repair', 'Support'],
    ),
    Business(
      id: '4',
      name: 'Beauty & Wellness Spa',
      category: 'Beauty',
      description: 'Relaxing spa treatments and beauty services. Book your appointment today.',
      address: '321 Wellness Way',
      distance: 0.8,
      imageUrl: '',
      rating: 4.7,
      isOpen: true,
      tags: ['Spa', 'Beauty', 'Relaxation'],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background "map" area
          Positioned.fill(child: _buildMapWidget()),

          // Expandable panel
          ExpandableInfoPanel(
            initialChildSize: 0.18,
            minChildSize: 0.18,
            maxChildSize: 0.85,
            children: [
              // Promo banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_offer, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Special Offer!', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Get 20% off at local businesses this week', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
              // Business list
              BusinessList(
                businesses: _businesses
              ),
            ],
          ),
        ],
      ),
    );
  }



    Widget _buildMapWidget() {
    CameraOptions camera = CameraOptions(
      center: Point(coordinates: Position(-75.56359, 6.25184)), // lng, lat
      zoom: 13,
    );

    return Stack(
      children: [
        MapWidget(
          cameraOptions: camera,
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: CustomSearchBar(controller: _searchController),
          ),
        ),
      ],
    );
  }
}
