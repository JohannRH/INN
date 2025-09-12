import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class BaseMap extends StatelessWidget {
  final CameraOptions? initialCamera;
  final void Function(MapboxMap map)? onMapCreated;
  final List<Widget>? children;
  final Future<void> Function(MapboxMap map)? drawMarkers;
  final double? minZoom;
  final double? maxZoom;
  final bool followUser; 
  final bool showUser;

  const BaseMap({
    super.key,
    this.initialCamera,
    this.onMapCreated,
    this.children,
    this.drawMarkers,
    this.minZoom,
    this.maxZoom,
    this.followUser = false,
    this.showUser = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapWidget(
          key: const ValueKey("base-map"),
          styleUri: "mapbox://styles/johannrh/cmehiomgu002k01rt7svneiu7",
          cameraOptions: initialCamera ??
              CameraOptions(
                center: Point(coordinates: Position(-75.576613, 6.299480)),
                zoom: 16.0,
                bearing: 0,
                pitch: 0,
              ),
          onMapCreated: (mapboxMap) async {
            await _setZoomConstraints(mapboxMap);

            if (showUser || followUser) {
              await mapboxMap.location.updateSettings(
                LocationComponentSettings(
                  enabled: true,
                  pulsingEnabled: true,
                  puckBearingEnabled: true,
                ),
              );
            }

            // Cámara que sigue al usuario (solo si followUser es true)
            if (followUser) {
              await mapboxMap.setCamera(
                CameraOptions(zoom: 16, center: null),
              );
            }

            if (onMapCreated != null) {
              onMapCreated!(mapboxMap);
            }
            if (drawMarkers != null) {
              await drawMarkers!(mapboxMap);
            }
          },
        ),
        if (children != null) ...children!,
      ],
    );
  }

  Future<void> _setZoomConstraints(MapboxMap mapboxMap) async {
    try {
      await mapboxMap.setBounds(CameraBoundsOptions(
        minZoom: minZoom ?? 16.8,
        maxZoom: maxZoom ?? 18.5,
      ));
    } catch (e) {
      debugPrint('Error setting zoom constraints: $e');
    }
  }
}
