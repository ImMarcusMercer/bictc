import 'package:bictc/app/design_system.dart';
import 'package:bictc/shared/repositories/favorites_repository.dart';
import 'package:bictc/shared/repositories/fixture_place_details.dart';
import 'package:bictc/shared/repositories/fixture_places.dart';
import 'package:bictc/shared/repositories/local_store.dart';
import 'package:bictc/shared/repositories/reports_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlaceDetailsScreen extends StatefulWidget {
  const PlaceDetailsScreen({required this.place, this.favorites, super.key});
  final SamplePlace place;
  final FavoritesRepository? favorites;

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  late final _session = createReportsRepository();
  late final _favorites =
      widget.favorites ??
      createFavoritesRepository(_session, DeviceLocalStore());
  SamplePlace get place => widget.place;
  SamplePlaceDetails? get details => sampleDetailsFor(place);
  static const _mint = Color(0xFFECFCF3);
  static const _green = Color(0xFF25D990);

  @override
  void initState() {
    super.initState();
    _favorites.addListener(_refresh);
    if (widget.favorites == null) _favorites.initialize();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _favorites.removeListener(_refresh);
    if (widget.favorites == null) {
      _favorites.dispose();
      _session.dispose();
    }
    super.dispose();
  }

  String get _mapLink => Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': '${place.position.latitude},${place.position.longitude}',
  }).toString();

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _save() async {
    try {
      if (_favorites.error != null) await _favorites.refresh();
      await _favorites.toggle(place);
      if (!mounted) return;
      _message(
        _favorites.contains(place)
            ? 'Saved to favorites${_favorites.session.userId == null ? ' on this device' : ''}.'
            : 'Removed from favorites.',
      );
    } catch (_) {
      if (mounted) _message('Could not save this place. Please try again.');
    }
  }

  Future<void> _copy(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) _message('Copied to clipboard.');
    } catch (_) {
      if (mounted) _message('Could not copy. Please select and copy the text.');
    }
  }

  void _showAction({required bool directions}) {
    final text = directions
        ? _mapLink
        : '${place.name}\n${place.address}\n$_mapLink';
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(directions ? 'Directions' : 'Share this place'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                directions
                    ? 'Copy this directions link and open it in your browser or maps app.'
                    : 'Copy the place details to share them.',
              ),
              const SizedBox(height: 16),
              SelectableText(text),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () => _copy(text),
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _header(),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 16, 10, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _summary(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _actionButton(
                              'Directions',
                              Icons.map_outlined,
                              () => _showAction(directions: true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _actionButton(
                              'Share',
                              Icons.link,
                              () => _showAction(directions: false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'ACCESSIBILITY FEATURES',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (details != null) ...[
                        _featureCard(
                          title: 'Main Entrance Ramp',
                          icon: Icons.door_front_door,
                          iconColor: const Color(0xFFBC815F),
                          source: 'Community Verified',
                          description: 'Gentle slope, handrails on both sides',
                        ),
                        const SizedBox(height: 12),
                        _featureCard(
                          title: 'Accessible Parking',
                          icon: Icons.local_parking_rounded,
                          iconColor: const Color(0xFF509BEC),
                          source: 'AI Detected · Suggestion',
                          description: 'Sample photo suggestion. Community confirmation needed.',
                          ai: true,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Sample preview · Summary and features are illustrative. Check current evidence before visiting.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ] else
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            children: [
                              Icon(
                                Icons.fact_check_outlined,
                                color: AppColors.muted,
                                size: 32,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'No detailed evidence yet',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Feature conditions and verification are unknown. Check with the establishment before visiting.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: MediaQuery.paddingOf(context).bottom),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _header() => ColoredBox(
    color: AppColors.primary,
    child: SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _headerButton(
                      icon: Icons.arrow_back,
                      tooltip: 'Back',
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        place.name,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    _favoriteButton(),
                  ],
                ),
                const SizedBox(height: 26),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.19),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        place.icon,
                        color: const Color(0xFFB9E6FF),
                        size: 34,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${place.category} · ${place.area}',
                            style: const TextStyle(
                              color: Color(0xFFD7EAFF),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            place.name,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            place.address,
                            style: const TextStyle(
                              color: Color(0xFFD7EAFF),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      children: [
                        _favoriteButton(),
                        const SizedBox(height: 4),
                        _headerButton(
                          icon: Icons.link,
                          tooltip: 'Copy place link',
                          onPressed: () => _copy(_mapLink),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _badge(
                      _statusLabel,
                      _statusIcon,
                      _statusColor,
                      place.status == PlaceStatus.accessible
                          ? _mint
                          : Colors.white,
                      size: 15,
                      roomy: true,
                    ),
                    if (details != null)
                      _badge(
                        'Community Verified',
                        Icons.check,
                        Colors.white,
                        const Color(0xFF1260E8),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  String get _statusLabel => switch (place.status) {
    PlaceStatus.accessible => 'Accessible',
    PlaceStatus.partial => 'Accessible with limitations',
    PlaceStatus.barrier => 'Significant barrier',
    PlaceStatus.unknown => 'Insufficient information',
  };
  IconData get _statusIcon => switch (place.status) {
    PlaceStatus.accessible => Icons.check_box,
    PlaceStatus.partial => Icons.warning_rounded,
    PlaceStatus.barrier => Icons.close,
    PlaceStatus.unknown => Icons.help_outline,
  };
  Color get _statusColor => switch (place.status) {
    PlaceStatus.accessible => AppColors.accessible,
    PlaceStatus.partial => AppColors.partial,
    PlaceStatus.barrier => AppColors.barrier,
    PlaceStatus.unknown => AppColors.unknown,
  };

  Widget _favoriteButton() => _headerButton(
    icon: _favorites.contains(place) ? Icons.favorite : Icons.favorite_border,
    tooltip: _favorites.contains(place)
        ? 'Remove from favorites'
        : 'Save to favorites',
    onPressed: _favorites.loading || _favorites.saving ? null : _save,
  );

  Widget _headerButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) => IconButton(
    onPressed: onPressed,
    tooltip: tooltip,
    icon: Icon(icon, size: 23),
    style: IconButton.styleFrom(
      foregroundColor: Colors.white,
      disabledForegroundColor: Colors.white70,
      backgroundColor: Colors.white.withValues(alpha: 0.19),
      minimumSize: const Size(48, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );

  Widget _summary() => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x080F1F2E),
          offset: Offset(0, 2),
          blurRadius: 2,
        ),
      ],
    ),
    child: Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _stat(
                'GOOD',
                details?.good,
                Icons.check_box,
                AppColors.accessible,
                const Color(0xFF55CF91),
              ),
              _stat(
                'PARTIAL',
                details?.partial,
                Icons.warning_rounded,
                AppColors.partial,
                const Color(0xFFFFB13B),
              ),
              _stat(
                'ISSUE',
                details == null ? null : 0,
                Icons.close_rounded,
                AppColors.barrier,
                const Color(0xFFFF5183),
              ),
              _stat(
                'UNKNOWN',
                details == null ? null : 0,
                Icons.question_mark_rounded,
                AppColors.ink,
                const Color(0xFFFF5183),
                last: true,
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          color: AppColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            runSpacing: 5,
            children: [
              Text(
                '${place.reports} ${place.isSample ? 'sample' : 'community'} reports',
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
              Text(
                'Updated ${place.updated}',
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _stat(
    String label,
    int? count,
    IconData icon,
    Color color,
    Color iconColor, {
    bool last = false,
  }) => Expanded(
    child: Container(
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(right: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 2),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 5),
          Text(
            count?.toString() ?? '—',
            style: TextStyle(
              fontFamily: 'Outfit',
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 9,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _actionButton(String label, IconData icon, VoidCallback action) =>
      OutlinedButton(
        onPressed: action,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primaryDark,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 7,
          children: [
            Icon(icon, size: 17),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
      );

  Widget _badge(
    String text,
    IconData icon,
    Color foreground,
    Color background, {
    double size = 10,
    bool roomy = false,
  }) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: roomy ? 14 : 10,
      vertical: roomy ? 9 : 5,
    ),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(roomy ? 12 : 20),
      border: Border.all(color: foreground.withValues(alpha: 0.2)),
    ),
    child: Text.rich(
      TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Icon(icon, size: size + 3, color: foreground),
            ),
          ),
          TextSpan(text: text),
        ],
      ),
      style: TextStyle(
        color: foreground,
        fontSize: size,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _featureCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String source,
    required String description,
    bool ai = false,
  }) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _mint,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _green),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 26, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              ai ? Icons.help_outline : Icons.check_box,
              size: 25,
              color: AppColors.accessible,
              semanticLabel: ai
                  ? 'Unverified suggestion'
                  : 'Good, sample community verification',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _badge(
          source,
          ai ? Icons.auto_awesome : Icons.groups,
          ai ? const Color(0xFF006B65) : const Color(0xFF2349AC),
          ai ? const Color(0xFFD0FAF1) : const Color(0xFFE0EAFF),
        ),
        const SizedBox(height: 9),
        Text(
          description,
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
      ],
    ),
  );
}
