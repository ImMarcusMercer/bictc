import 'package:bictc/app/design_system.dart';
import 'package:bictc/features/needs/models/accessibility_need.dart';
import 'package:bictc/shared/repositories/fixture_places.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

enum DiscoveryMode { places, map }

class DiscoveryHome extends StatefulWidget {
  const DiscoveryHome({
    required this.mode,
    required this.selectedNeeds,
    super.key,
  });

  final DiscoveryMode mode;
  final Set<AccessibilityNeed> selectedNeeds;

  @override
  State<DiscoveryHome> createState() => _DiscoveryHomeState();
}

class _DiscoveryHomeState extends State<DiscoveryHome> {
  static const _cities = [
    'All',
    'Metro Manila',
    'Cebu',
    'Davao',
    'General Santos',
  ];

  final _search = TextEditingController();
  String _city = 'Metro Manila';
  PlaceStatus? _status;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<SamplePlace> get _visiblePlaces {
    final query = _search.text.trim().toLowerCase();
    final places = samplePlaces.where((place) {
      return (_city == 'All' || place.city == _city) &&
          (_status == null || place.status == _status) &&
          (query.isEmpty ||
              '${place.name} ${place.area} ${place.category} ${place.address}'
                  .toLowerCase()
                  .contains(query));
    }).toList();

    places.sort((a, b) => _matchCount(b).compareTo(_matchCount(a)));
    return places;
  }

  int _matchCount(SamplePlace place) =>
      place.supportedNeeds.intersection(widget.selectedNeeds).length;

  void _clearFilters() {
    setState(() {
      _search.clear();
      _city = 'All';
      _status = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final places = _visiblePlaces;
    return Column(
      children: [
        _header(),
        _cityFilters(),
        _statusFilters(),
        _needsContext(),
        Expanded(
          child: widget.mode == DiscoveryMode.places
              ? _placeList(places)
              : _fullMap(places),
        ),
      ],
    );
  }

  Widget _header() => ColoredBox(
    color: AppColors.primary,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 4,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                children: [
                  Text(
                    'AccessPH',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(color: Colors.white),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.all(Radius.circular(6)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text(
                        'PH',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 3,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: Colors.white70,
                  ),
                  Text(
                    _city == 'All' ? 'All Philippines' : _city,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('place-search'),
            controller: _search,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search place or area...',
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(_search.clear),
                    ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDesign.controlRadius),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _cityFilters() => ColoredBox(
    color: Colors.white,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            for (var index = 0; index < _cities.length; index++) ...[
              if (index > 0) const SizedBox(width: 7),
              _cityChip(_cities[index]),
            ],
          ],
        ),
      ),
    ),
  );

  Widget _cityChip(String city) => ChoiceChip(
    materialTapTargetSize: MaterialTapTargetSize.padded,
    label: Text(city == 'All' ? 'PH All' : city),
    selected: _city == city,
    onSelected: (_) => setState(() => _city = city),
    showCheckmark: false,
    selectedColor: AppColors.primary,
    backgroundColor: Colors.white,
    labelStyle: TextStyle(
      color: _city == city ? Colors.white : AppColors.ink,
      fontWeight: FontWeight.w800,
      fontSize: 12,
    ),
    side: BorderSide(
      color: _city == city ? AppColors.primary : AppColors.border,
    ),
    shape: const StadiumBorder(),
  );

  Widget _statusFilters() {
    final cityPlaces = samplePlaces.where(
      (place) => _city == 'All' || place.city == _city,
    );
    final filters = <PlaceStatus?>[null, ...PlaceStatus.values];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            for (var index = 0; index < filters.length; index++) ...[
              if (index > 0) const SizedBox(width: 7),
              _statusChip(filters[index], cityPlaces),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusChip(PlaceStatus? status, Iterable<SamplePlace> cityPlaces) {
    final selected = _status == status;
    return FilterChip(
      materialTapTargetSize: MaterialTapTargetSize.padded,
      key: Key('status-${status?.name ?? 'all'}'),
      label: Text(status?.label ?? 'All'),
      avatar: Icon(
        status?.icon ?? Icons.circle,
        size: 16,
        color: selected ? Colors.white : (status?.color ?? AppColors.primary),
      ),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => setState(() => _status = status),
      backgroundColor: Colors.white,
      selectedColor: AppColors.ink,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.ink,
        fontWeight: FontWeight.w800,
        fontSize: 12,
      ),
      side: BorderSide(color: selected ? AppColors.ink : AppColors.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesign.controlRadius),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      tooltip: status == null
          ? 'Show all statuses'
          : '${status.label}: ${cityPlaces.where((place) => place.status == status).length} sample places',
    );
  }

  Widget _needsContext() => ColoredBox(
    color: const Color(0xFFE8F0FE),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Text(
              'Best Places for You',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 10),
            if (widget.selectedNeeds.isEmpty)
              const Text(
                'Choose needs in More',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            for (final need in widget.selectedNeeds) ...[
              Chip(
                avatar: Icon(need.icon, size: 16, color: AppColors.primary),
                label: Text(need.label),
                visualDensity: VisualDensity.compact,
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.border),
                labelStyle: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
            ],
          ],
        ),
      ),
    ),
  );

  Widget _placeList(List<SamplePlace> places) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: ListView(
        key: const Key('places-list'),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
        children: [
          Text(
            '${places.length} ${places.length == 1 ? 'place' : 'places'} found · Sample data',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          if (places.isEmpty) _emptyState(),
          for (final place in places) ...[
            _placeCard(place),
            const SizedBox(height: 10),
          ],
        ],
      ),
    ),
  );

  Widget _emptyState() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28),
    child: Column(
      children: [
        const Icon(Icons.search_off_rounded, size: 42, color: AppColors.muted),
        const SizedBox(height: 8),
        Text('No places found', style: Theme.of(context).textTheme.titleMedium),
        const Text('Try another city, status, or search term.'),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _clearFilters,
          child: const Text('Clear filters'),
        ),
      ],
    ),
  );

  Widget _placeCard(SamplePlace place) {
    final matches = _matchCount(place);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppDesign.cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDesign.cardRadius),
        onTap: () => _showPlace(place),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDesign.cardRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: place.status.color,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppDesign.cardRadius),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F0FE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        place.icon,
                        color: AppColors.primary,
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontSize: 15),
                          ),
                          Text(
                            '${place.category} · ${place.area}',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 6,
                            runSpacing: 5,
                            children: [
                              _statusBadge(place.status),
                              if (widget.selectedNeeds.isNotEmpty)
                                _matchBadge(matches),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.muted),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 2,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Icon(
                          Icons.groups_outlined,
                          size: 14,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${place.reports} sample reports',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Updated ${place.updated}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _matchBadge(int matches) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.08),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Icon(Icons.auto_awesome, size: 13, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(
          '$matches of ${widget.selectedNeeds.length} needs',
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );

  Widget _statusBadge(PlaceStatus status) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: status.color.withValues(alpha: 0.09),
      border: Border.all(color: status.color.withValues(alpha: 0.35)),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Icon(status.icon, size: 13, color: status.color),
        const SizedBox(width: 4),
        Text(
          status.label,
          style: TextStyle(
            color: status.color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );

  Widget _fullMap(List<SamplePlace> places) => Stack(
    key: const Key('full-map'),
    children: [
      _map(places),
      Positioned(
        top: 10,
        left: 10,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Text(
              _mapSummary(places),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
      const Positioned(
        bottom: 32,
        left: 10,
        right: 10,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.all(Radius.circular(30)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                'Map needs internet · Places works offline',
                style: TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
        ),
      ),
    ],
  );

  String _mapSummary(List<SamplePlace> places) {
    if (widget.selectedNeeds.isEmpty) return '${places.length} sample places';
    final matches = places.where((place) => _matchCount(place) > 0).length;
    return '$matches of ${places.length} match selected needs';
  }

  Widget _map(List<SamplePlace> places) {
    final center = switch (_city) {
      'Cebu' => const LatLng(10.3157, 123.8854),
      'Davao' => const LatLng(7.1907, 125.4553),
      'General Santos' => const LatLng(6.1164, 125.1716),
      'All' => const LatLng(12.8797, 121.7740),
      _ => const LatLng(14.5995, 121.0000),
    };
    return FlutterMap(
      key: ValueKey(_city),
      options: MapOptions(
        initialCenter: center,
        initialZoom: _city == 'All' ? 5.3 : 11.3,
      ),
      children: [
        TileLayer(
          urlTemplate: const String.fromEnvironment(
            'MAP_TILE_URL',
            defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),
          userAgentPackageName: 'com.artemis.bictc',
        ),
        MarkerLayer(
          markers: [
            for (final place in places)
              Marker(
                point: place.position,
                width: 46,
                height: 48,
                child: Semantics(
                  label:
                      '${place.name}, ${place.status.label}, ${_matchCount(place)} selected needs matched',
                  button: true,
                  child: GestureDetector(
                    onTap: () => _showPlace(place),
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        Icon(
                          Icons.location_pin,
                          size: 44,
                          color: place.status.color,
                        ),
                        if (_matchCount(place) > 0)
                          const Positioned(
                            top: 5,
                            child: Icon(
                              Icons.star,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const Align(
          alignment: Alignment.bottomLeft,
          child: DecoratedBox(
            decoration: BoxDecoration(color: Colors.white70),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                '© OpenStreetMap contributors',
                style: TextStyle(fontSize: 9, color: AppColors.ink),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showPlace(SamplePlace place) {
    final matches = _matchCount(place);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(place.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                '${place.category} · ${place.area}',
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 5,
                children: [
                  _statusBadge(place.status),
                  if (widget.selectedNeeds.isNotEmpty) _matchBadge(matches),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(place.address)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${place.reports} sample reports · Updated ${place.updated}',
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              const Text(
                'Recommendation matches are based on sample feature tags. Check current, detailed evidence before planning a visit.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension _StatusDisplay on PlaceStatus {
  String get label => switch (this) {
    PlaceStatus.accessible => 'Accessible',
    PlaceStatus.partial => 'Partial',
    PlaceStatus.barrier => 'Barrier',
    PlaceStatus.unknown => 'Unknown',
  };

  IconData get icon => switch (this) {
    PlaceStatus.accessible => Icons.check_box_outlined,
    PlaceStatus.partial => Icons.warning_amber_rounded,
    PlaceStatus.barrier => Icons.block_outlined,
    PlaceStatus.unknown => Icons.help_outline,
  };

  Color get color => switch (this) {
    PlaceStatus.accessible => AppColors.accessible,
    PlaceStatus.partial => AppColors.partial,
    PlaceStatus.barrier => AppColors.barrier,
    PlaceStatus.unknown => AppColors.unknown,
  };
}
