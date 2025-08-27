import 'package:flutter/material.dart';
import '../widgets/expandable_info_panel.dart';
import '../models/business.dart';
import '../components/search_bar.dart';
import '../widgets/business_list.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();

   Future<List<Business>> fetchBusinesses() async {
    final response = await Supabase.instance.client
        .from('businesses')
        .select();

    final data = response as List<dynamic>;
    return data.map((json) => Business.fromJson(json)).toList();
  }

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
              
              // Lista de negocios desde Supabase
              FutureBuilder<List<Business>>(
                future: fetchBusinesses(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.data!.isEmpty) {
                    return const Center(child: Text("No businesses found"));
                  }
                  return BusinessList(businesses: snapshot.data!);
                },
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
