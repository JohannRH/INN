import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../components/search_bar.dart';

class MapLocationPickerPage extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapLocationPickerPage({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<MapLocationPickerPage> createState() => _MapLocationPickerPageState();
}

class _MapLocationPickerPageState extends State<MapLocationPickerPage> {
  MapboxMap? _mapboxMap;
  CameraOptions? _cameraOptions;

  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _cameraOptions = CameraOptions(
      center: Point(
        coordinates: Position(
          widget.initialLng ?? -75.56359,
          widget.initialLat ?? 6.25184,
        ),
      ),
      zoom: 14,
    );
  }

  // --- Forward geocoding con autocomplete ---
  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    final accessToken = dotenv.env['MAPBOX_ACCESS_TOKEN'];
    
    // Try with more flexible parameters for better coverage
    final url =
        "https://api.mapbox.com/search/geocode/v6/forward?q=${Uri.encodeComponent(query)}&autocomplete=true&country=CO&limit=8&proximity=${widget.initialLng ?? -75.56359},${widget.initialLat ?? 6.25184}&access_token=$accessToken";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data["features"] ?? [];
        
        setState(() {
          _searchResults = List.from(features);
          
          // Add fallback option if no results found or query is specific
          if (features.isEmpty && query.length > 3) {
            _searchResults.add({
              "type": "fallback",
              "properties": {
                "full_address": "Usar: \"$query\"",
                "name": query,
                "description": "Continuar con esta dirección"
              }
            });
          }
        });
      } else {
        // Handle API errors
        setState(() {
          _searchResults = [{
            "type": "fallback", 
            "properties": {
              "full_address": "Usar: \"$query\"",
              "name": query,
              "description": "No se pudieron cargar sugerencias - Usar esta dirección"
            }
          }];
        });
      }
    } catch (e) {
      // Handle network errors
      setState(() {
        _searchResults = [{
          "type": "fallback",
          "properties": {
            "full_address": "Usar: \"$query\"", 
            "name": query,
            "description": "Error de conexión - Usar esta dirección"
          }
        }];
      });
    }
  }

  // --- Reverse geocoding ---
  Future<String?> _reverseGeocode(double lng, double lat) async {
    final accessToken = dotenv.env['MAPBOX_ACCESS_TOKEN'];
    final url =
        "https://api.mapbox.com/search/geocode/v6/reverse?longitude=$lng&latitude=$lat&access_token=$accessToken&country=CO&limit=1";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data["features"].isNotEmpty) {
        return data["features"][0]["properties"]["full_address"] ??
            data["features"][0]["properties"]["place_formatted"];
      }
    }
    return null;
  }

  void _moveCameraTo(double? lng, double? lat, [String? fallbackAddress]) {
    if (_mapboxMap != null && lng != null && lat != null) {
      _mapboxMap!.flyTo(
        CameraOptions(center: Point(coordinates: Position(lng, lat)), zoom: 15),
        MapAnimationOptions(duration: 1500),
      );
    }
    
    setState(() {
      _searchResults.clear();
      if (fallbackAddress != null) {
        _searchController.text = fallbackAddress;
      } else {
        _searchController.clear();
      }
    });
  }

  void _confirmLocation() async {
    if (_mapboxMap != null) {
      final cameraState = await _mapboxMap!.getCameraState();
      final coords = cameraState.center.coordinates;

      String finalAddress;
      
      // Use the search bar text if user typed something specific
      if (_searchController.text.isNotEmpty && _searchController.text != "Buscar ubicación...") {
        final reverseAddress = await _reverseGeocode(coords.lng.toDouble(), coords.lat.toDouble());
        // Combine user input with reverse geocoded result or use user input as fallback
        finalAddress = reverseAddress ?? _searchController.text;
      } else {
        final address = await _reverseGeocode(coords.lng.toDouble(), coords.lat.toDouble());
        finalAddress = address ?? "Ubicación personalizada (${coords.lat.toStringAsFixed(6)}, ${coords.lng.toStringAsFixed(6)})";
      }

      if (!mounted) return;

      Navigator.pop(context, {
        "address": finalAddress,
        "lat": coords.lat.toDouble(),
        "lng": coords.lng.toDouble(),
      });
    }
  }

  IconData _getIconForFeatureType(String? featureType) {
    switch (featureType) {
      case 'address':
        return Icons.home;
      case 'place':
        return Icons.location_city;
      case 'region':
        return Icons.map;
      case 'country':
        return Icons.public;
      case 'neighborhood':
        return Icons.location_on;
      case 'street':
        return Icons.add_road;
      case 'postcode':
        return Icons.local_post_office;
      case 'district':
        return Icons.location_city;
      case 'locality':
        return Icons.location_on;
      default:
        return Icons.place;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          false, // ✅ evita que todo se mueva con el teclado
      appBar: AppBar(title: const Text("Selecciona ubicación")),
      body: Stack(
        children: [
          // --- Mapa ---
          MapWidget(
            key: const ValueKey("map-picker"),
            cameraOptions: _cameraOptions!,
            onMapCreated: (map) {
              _mapboxMap = map;
            },
          ),
          // --- Pin fijo ---
          const Center(
            child: Icon(Icons.location_on, color: Colors.red, size: 40),
          ),
          // --- Barra de búsqueda ---
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Column(
              children: [
                // Remove the Padding since CustomSearchBar already has it
                CustomSearchBar(
                  controller: _searchController,
                  onChanged: (value) {
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce = Timer(const Duration(milliseconds: 400), () {
                      _searchPlaces(value);
                    });
                  },
                  // Optional: Add onTap if you want specific behavior when tapping the search bar
                  onTap: () {
                    // You could expand search results or do other actions here if needed
                  },
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8, left: 16, right: 16), // Adjust margins since CustomSearchBar has its own padding
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      children: _searchResults.map((place) {
                        // Handle fallback/custom address option
                        if (place["type"] == "fallback") {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.edit_location, color: Colors.blue),
                              title: Text(
                                place["properties"]["full_address"], 
                                style: const TextStyle(fontWeight: FontWeight.w600)
                              ),
                              subtitle: Text(
                                place["properties"]["description"],
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                              onTap: () {
                                // Set the search text and keep current camera position
                                setState(() {
                                  _searchController.text = place["properties"]["name"];
                                  _searchResults.clear();
                                });
                              },
                            ),
                          );
                        }
                        
                        // Handle regular geocoding results
                        final text = place["properties"]["full_address"] ??
                            place["properties"]["place_formatted"] ??
                            place["properties"]["name"];
                        final coords = place["geometry"]["coordinates"];
                        
                        return ListTile(
                          leading: Icon(
                            _getIconForFeatureType(place["properties"]["feature_type"]),
                            color: Colors.grey[600],
                          ),
                          title: Text(
                            place["properties"]["name"] ?? text,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            place["properties"]["place_formatted"] ?? text,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                          onTap: () {
                            _moveCameraTo(
                              coords[0].toDouble(), 
                              coords[1].toDouble(), 
                              place["properties"]["name"] ?? text
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
          // --- Botón Confirmar ---
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              onPressed: _confirmLocation,
              icon: const Icon(Icons.check),
              label: const Text("Confirmar ubicación"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
