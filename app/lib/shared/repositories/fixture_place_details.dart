import 'package:bictc/shared/repositories/fixture_places.dart';

/// Screenshot preview content only, not observed or certified evidence.
class SamplePlaceDetails {
  const SamplePlaceDetails({required this.good, required this.partial});
  final int good;
  final int partial;
}

SamplePlaceDetails? sampleDetailsFor(SamplePlace place) =>
    place.isSample &&
        place.name == 'SM City North EDSA' &&
        place.area == 'Quezon City'
    ? const SamplePlaceDetails(good: 7, partial: 3)
    : null;
