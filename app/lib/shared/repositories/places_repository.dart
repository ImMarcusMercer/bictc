import 'package:bictc/app/supabase_config.dart';
import 'package:bictc/features/needs/models/accessibility_need.dart';
import 'package:bictc/shared/repositories/fixture_places.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SamplePlace placeFromJson(Map<String, dynamic> row) => SamplePlace(
  id: row['id'] as String?,
  name: row['name'] as String,
  category: row['category'] as String,
  city: row['city'] as String,
  area: row['area'] as String,
  address: row['address'] as String,
  position: LatLng(
    (row['latitude'] as num).toDouble(),
    (row['longitude'] as num).toDouble(),
  ),
  status: PlaceStatus.values.byName(row['access_status'] as String),
  reports: (row['report_count'] as num?)?.toInt() ?? 0,
  updated: row['last_observed_at'] as String? ?? 'Unknown',
  icon: switch (row['category']) {
    'Hospital' => Icons.local_hospital_outlined,
    'Mall' => Icons.storefront_outlined,
    _ => Icons.place_outlined,
  },
  supportedNeeds: AccessibilityNeed.values
      .where(
        (need) =>
            (row['supported_need_codes'] as List? ?? []).contains(need.name),
      )
      .toSet(),
);
Map<String, dynamic> placeToJson(SamplePlace place) => {
  'id': place.id,
  'name': place.name,
  'category': place.category,
  'city': place.city,
  'area': place.area,
  'address': place.address,
  'latitude': place.position.latitude,
  'longitude': place.position.longitude,
  'access_status': place.status.name,
  'report_count': place.reports,
  'last_observed_at': place.updated,
  'supported_need_codes': place.supportedNeeds
      .map((need) => need.name)
      .toList(),
};

abstract interface class PlacesRepository {
  bool get isPreview;
  Future<List<SamplePlace>> fetch();
}

PlacesRepository createPlacesRepository() =>
    SupabaseConfig.fromEnvironment() == null
    ? PreviewPlacesRepository()
    : SupabasePlacesRepository(Supabase.instance.client);

class PreviewPlacesRepository implements PlacesRepository {
  @override
  bool get isPreview => true;
  @override
  Future<List<SamplePlace>> fetch() async => samplePlaces;
}

class SupabasePlacesRepository implements PlacesRepository {
  SupabasePlacesRepository(this.client);
  final SupabaseClient client;
  @override
  bool get isPreview => false;
  @override
  Future<List<SamplePlace>> fetch() async {
    final places = <SamplePlace>[];
    for (var offset = 0; ; offset += 200) {
      final rows = await client
          .from('establishments')
          .select()
          .order('id')
          .range(offset, offset + 199);
      places.addAll(rows.map(placeFromJson));
      if (rows.length < 200) return places;
    }
  }
}
