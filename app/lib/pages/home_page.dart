import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../widgets/expandable_info_panel.dart';
import '../models/business.dart';
import '../components/search_bar.dart';
import '../widgets/business_list.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../themes/business_icons.dart';
import '../widgets/bitmap.dart';
import '../components/base_map.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  bool _locationGranted = false;
  bool _deniedForever = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLocationPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose(); 
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLocationPermission();
    }
  }

  Future<void> _checkLocationPermission() async {
    try {
      final serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _locationGranted = false;
            _deniedForever = true;
          });
        }
        return;
      }

      var permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
      }

      if (mounted) {
        setState(() {
          _deniedForever = permission == geo.LocationPermission.deniedForever;
          _locationGranted = permission == geo.LocationPermission.whileInUse ||
              permission == geo.LocationPermission.always;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationGranted = false;
        });
      }
    }
  }

  Future<List<Business>> fetchBusinesses() async {
    final response = await Supabase.instance.client
        .from('businesses')
        .select('*, business_types(category_id)');

    final data = response as List<dynamic>;
    return data.map((json) => Business.fromJson(json)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _locationGranted
                ? _buildMapWidget()
                : _buildLocationPermissionScreen(),
          ),
          // Only show the panel when location is granted
          if (_locationGranted)
            ExpandableInfoPanel(
              initialChildSize: 0.18,
              minChildSize: 0.18,
              maxChildSize: 0.85,
              children: [
                _buildPromoBanner(context),
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

  Widget _buildLocationPermissionScreen() {
    // Only show the full permission screen when actually denied forever
    if (!_deniedForever) {
      return Container(
        color: Theme.of(context).colorScheme.surface,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Location Icon
                    TweenAnimationBuilder(
                      duration: const Duration(milliseconds: 1500),
                      tween: Tween<double>(begin: 0.8, end: 1.0),
                      builder: (context, double scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).colorScheme.errorContainer,
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.error.withValues(alpha:0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.location_off,
                              size: 60,
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Title
                    Text(
                      "Ubicación Requerida",
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description
                    Text(
                      "Para mostrarte los negocios cercanos y tu posición en el mapa, necesitamos acceso a tu ubicación.",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Instructions
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                child: const Center(
                                  child: Text(
                                    "1",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Toca 'Abrir Configuración' abajo",
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                child: const Center(
                                  child: Text(
                                    "2",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Ve a Permisos > Ubicación",
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                child: const Center(
                                  child: Text(
                                    "3",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Selecciona 'Permitir' o 'Mientras uso la app'",
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Action Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    await geo.Geolocator.openAppSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.settings),
                      SizedBox(width: 8),
                      Text(
                        "Abrir Configuración",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromoBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary
            ],
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
                  Text('Special Offer!',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Get 20% off at local businesses this week',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMapWidget() {
    return FutureBuilder<geo.Position>(
      future: geo.Geolocator.getCurrentPosition(), // ubicación al inicio
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userPos = snapshot.data!;
        final initialCamera = CameraOptions(
          center: Point(
            coordinates: Position(userPos.longitude, userPos.latitude),
          ),
          zoom: 17.5,
        );

        return BaseMap(
          initialCamera: initialCamera, // arranca en ubicación del usuario
          showUser: true,
          followUser: false,
          drawMarkers: (mapboxMap) async {
            final businesses = await fetchBusinesses();
            final manager = await mapboxMap.annotations.createPointAnnotationManager();

            for (final business in businesses) {
              if (business.latitude == null || business.longitude == null) continue;

              final style = categoryStyles[business.categoryId ?? 16] ?? categoryStyles[16]!;
              final bitmap = await createMarkerBitmap(
                color: style.color,
                icon: style.icon,
                size: 80,
                iconSize: 40,
              );

              await manager.create(PointAnnotationOptions(
                geometry: Point(
                  coordinates: Position(business.longitude!, business.latitude!),
                ),
                image: bitmap,
                textField: business.name,
                textSize: 12.0,
                textColor: style.color.toARGB32(),
                textHaloColor: Colors.white.toARGB32(),
                textHaloWidth: 1.5,
                textOffset: [0, 2],
              ));
            }
          },
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: CustomSearchBar(controller: _searchController),
              ),
            ),
          ],
        );
      },
    );
  }
}