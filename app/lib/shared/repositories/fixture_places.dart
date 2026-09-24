import 'package:bictc/features/needs/models/accessibility_need.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum PlaceStatus { accessible, partial, barrier, unknown }

class SamplePlace {
  const SamplePlace({
    required this.name,
    required this.category,
    required this.city,
    required this.area,
    required this.address,
    required this.position,
    required this.status,
    required this.reports,
    required this.updated,
    required this.icon,
    required this.supportedNeeds,
  });

  final String name;
  final String category;
  final String city;
  final String area;
  final String address;
  final LatLng position;
  final PlaceStatus status;
  final int reports;
  final String updated;
  final IconData icon;
  final Set<AccessibilityNeed> supportedNeeds;
}

/// Visual fixtures adapted from docs/figma structure/src/data.ts.
/// Replace only after the shared contract and a real repository are available.
const samplePlaces = <SamplePlace>[
  SamplePlace(
    name: 'SM City North EDSA',
    category: 'Mall',
    city: 'Metro Manila',
    area: 'Quezon City',
    address: 'North Avenue, Quezon City',
    position: LatLng(14.6561, 121.0294),
    status: PlaceStatus.accessible,
    reports: 214,
    updated: 'Sep 2026',
    icon: Icons.storefront_outlined,
    supportedNeeds: {
      AccessibilityNeed.wheelchair,
      AccessibilityNeed.visual,
      AccessibilityNeed.hearing,
      AccessibilityNeed.walker,
      AccessibilityNeed.senior,
      AccessibilityNeed.cognitive,
      AccessibilityNeed.sensory,
      AccessibilityNeed.chronic,
    },
  ),
  SamplePlace(
    name: 'Robinsons Galleria',
    category: 'Mall',
    city: 'Metro Manila',
    area: 'Quezon City',
    address: 'EDSA corner Ortigas Avenue, Quezon City',
    position: LatLng(14.5918, 121.0595),
    status: PlaceStatus.accessible,
    reports: 178,
    updated: 'Aug 2026',
    icon: Icons.storefront_outlined,
    supportedNeeds: {
      AccessibilityNeed.wheelchair,
      AccessibilityNeed.hearing,
      AccessibilityNeed.walker,
      AccessibilityNeed.senior,
      AccessibilityNeed.chronic,
    },
  ),
  SamplePlace(
    name: 'Philippine General Hospital',
    category: 'Hospital',
    city: 'Metro Manila',
    area: 'Manila',
    address: 'Taft Avenue, Ermita, Manila',
    position: LatLng(14.5785, 120.9854),
    status: PlaceStatus.partial,
    reports: 312,
    updated: 'Sep 2026',
    icon: Icons.local_hospital_outlined,
    supportedNeeds: {
      AccessibilityNeed.wheelchair,
      AccessibilityNeed.visual,
      AccessibilityNeed.hearing,
      AccessibilityNeed.walker,
      AccessibilityNeed.senior,
      AccessibilityNeed.cognitive,
      AccessibilityNeed.chronic,
    },
  ),
  SamplePlace(
    name: 'SM Megamall',
    category: 'Mall',
    city: 'Metro Manila',
    area: 'Mandaluyong',
    address: 'EDSA, Mandaluyong City',
    position: LatLng(14.5840, 121.0568),
    status: PlaceStatus.accessible,
    reports: 267,
    updated: 'Sep 2026',
    icon: Icons.storefront_outlined,
    supportedNeeds: {
      AccessibilityNeed.wheelchair,
      AccessibilityNeed.visual,
      AccessibilityNeed.hearing,
      AccessibilityNeed.walker,
      AccessibilityNeed.senior,
      AccessibilityNeed.sensory,
      AccessibilityNeed.chronic,
    },
  ),
  SamplePlace(
    name: 'Ayala Malls Manila Bay',
    category: 'Mall',
    city: 'Metro Manila',
    area: 'Parañaque',
    address: 'Aseana City, Parañaque',
    position: LatLng(14.5232, 120.9833),
    status: PlaceStatus.accessible,
    reports: 143,
    updated: 'Aug 2026',
    icon: Icons.storefront_outlined,
    supportedNeeds: {
      AccessibilityNeed.wheelchair,
      AccessibilityNeed.visual,
      AccessibilityNeed.hearing,
      AccessibilityNeed.walker,
      AccessibilityNeed.senior,
      AccessibilityNeed.cognitive,
      AccessibilityNeed.sensory,
      AccessibilityNeed.chronic,
    },
  ),
  SamplePlace(
    name: 'SM City Cebu',
    category: 'Mall',
    city: 'Cebu',
    area: 'Cebu City',
    address: 'North Reclamation Area, Cebu City',
    position: LatLng(10.3117, 123.9183),
    status: PlaceStatus.accessible,
    reports: 231,
    updated: 'Sep 2026',
    icon: Icons.storefront_outlined,
    supportedNeeds: {
      AccessibilityNeed.wheelchair,
      AccessibilityNeed.visual,
      AccessibilityNeed.walker,
      AccessibilityNeed.senior,
      AccessibilityNeed.chronic,
    },
  ),
  SamplePlace(
    name: 'SM City Davao',
    category: 'Mall',
    city: 'Davao',
    area: 'Davao City',
    address: 'JP Laurel Avenue, Davao City',
    position: LatLng(7.0881, 125.6127),
    status: PlaceStatus.accessible,
    reports: 197,
    updated: 'Sep 2026',
    icon: Icons.storefront_outlined,
    supportedNeeds: {
      AccessibilityNeed.wheelchair,
      AccessibilityNeed.hearing,
      AccessibilityNeed.walker,
      AccessibilityNeed.senior,
      AccessibilityNeed.sensory,
      AccessibilityNeed.chronic,
    },
  ),
  SamplePlace(
    name: 'Mindanao Central Hospital',
    category: 'Hospital',
    city: 'General Santos',
    area: 'General Santos City',
    address: 'E. Fernandez Street, General Santos City',
    position: LatLng(6.1164, 125.1716),
    status: PlaceStatus.barrier,
    reports: 38,
    updated: 'Apr 2026',
    icon: Icons.local_hospital_outlined,
    supportedNeeds: {AccessibilityNeed.hearing, AccessibilityNeed.cognitive},
  ),
];
