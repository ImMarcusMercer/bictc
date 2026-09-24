import 'package:bictc/app/design_system.dart';
import 'package:bictc/features/auth/views/login_page.dart';
import 'package:bictc/features/reports/views/report_form.dart';
import 'package:bictc/shared/models/community_report.dart';
import 'package:bictc/shared/repositories/reports_repository.dart';
import 'package:flutter/material.dart';

class CommunityReports extends StatefulWidget {
  const CommunityReports({super.key, this.repository});
  final ReportsRepository? repository;
  @override
  State<CommunityReports> createState() => _CommunityReportsState();
}

class _CommunityReportsState extends State<CommunityReports> {
  late final ReportsRepository _repository =
      widget.repository ?? createReportsRepository();
  List<CommunityReport> _reports = [];
  String? _city, _error;
  ReportStatus? _status;
  bool _loading = true, _more = false;
  final Set<String> _voting = {};
  int _request = 0;
  @override
  void initState() {
    super.initState();
    _repository.addListener(_authChanged);
    _load();
  }

  @override
  void dispose() {
    _repository.removeListener(_authChanged);
    if (widget.repository == null) _repository.dispose();
    super.dispose();
  }

  void _authChanged() {
    if (mounted) _load();
  }

  Future<void> _load({bool append = false, bool clear = false}) async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
      if (clear) _reports = [];
    });
    try {
      final rows = await _repository.fetch(
        city: _city,
        status: _status,
        offset: append ? _reports.length : 0,
      );
      if (!mounted || request != _request) return;
      setState(() {
        _reports = append ? [..._reports, ...rows] : rows;
        _more = rows.length == 20;
      });
    } catch (_) {
      if (mounted && request == _request) {
        setState(
          () => _error = 'Unable to load reports. You may be offline. Check your connection and retry.',
        );
      }
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  Future<bool> _signIn() async {
    if (_repository.canContribute) return true;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => LoginPage(repository: _repository)),
    );
    return mounted && _repository.canContribute;
  }

  Future<void> _compose(ReportStatus status) async {
    if (!await _signIn() || !mounted) return;
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) =>
            ReportForm(repository: _repository, initialStatus: status),
      ),
    );
    if (!mounted || result == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
    _city = null;
    _status = null;
    await _load(clear: true);
  }

  Future<void> _helpful(CommunityReport report) async {
    if (_voting.contains(report.id) || !await _signIn() || !mounted) return;
    setState(() => _voting.add(report.id));
    try {
      await _repository.setHelpful(report.id, !report.isHelpful);
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not update helpful. Check your connection and sign-in.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _voting.remove(report.id));
    }
  }

  void _clear() {
    _city = null;
    _status = null;
    _load(clear: true);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Container(
            color: AppColors.accent,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community Reports',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Help others navigate with confidence.',
                  style: TextStyle(color: Colors.white),
                ),
                Text(
                  _repository.canContribute
                      ? 'Share your observations with the community.'
                      : 'Guests can browse. Sign in to report or upload.',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.accent,
                      ),
                      onPressed: () => _compose(ReportStatus.partial),
                      icon: const Icon(Icons.flag),
                      label: const Text('Report Issue'),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        minimumSize: const Size(48, 48),
                      ),
                      onPressed: () => _compose(ReportStatus.accessible),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Good Access'),
                    ),
                  ],
                ),
                if (_repository.canContribute)
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    onPressed: () async {
                      try {
                        await _repository.signOut();
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Unable to sign out. Please retry.',
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Sign out'),
                  ),
              ],
            ),
          ),
          _chips([
            ChoiceChip(
              label: const Text('All PH'),
              selected: _city == null,
              onSelected: (_) {
                _city = null;
                _load(clear: true);
              },
            ),
            ...reportCities.map(
              (city) => ChoiceChip(
                label: Text(city),
                selected: _city == city,
                onSelected: (_) {
                  _city = city;
                  _load(clear: true);
                },
              ),
            ),
          ]),
          _chips([
            ChoiceChip(
              label: const Text('All Reports'),
              selected: _status == null,
              onSelected: (_) {
                _status = null;
                _load(clear: true);
              },
            ),
            ...ReportStatus.values.map(
              (status) => ChoiceChip(
                avatar: Icon(_icon(status), size: 18, color: _color(status)),
                label: Text(status.label),
                selected: _status == status,
                onSelected: (_) {
                  _status = status;
                  _load(clear: true);
                },
              ),
            ),
          ]),
          if (_repository.isPreview)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Sample reports • Read-only preview'),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              '${_reports.length} REPORTS${_more ? ' LOADED' : ''}',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Semantics(liveRegion: true, child: Text(_error!)),
                  TextButton(
                    onPressed: () => _load(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          if (!_loading && _error == null && _reports.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.forum_outlined, size: 40),
                  const SizedBox(height: 12),
                  const Text('No reports match these filters.'),
                  TextButton(
                    onPressed: _clear,
                    child: const Text('Clear filters'),
                  ),
                ],
              ),
            ),
          ..._reports.map(_card),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Loading reports',
                ),
              ),
            ),
          if (_more && !_loading)
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton(
                onPressed: () => _load(append: true),
                child: const Text('Load more'),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
  Widget _chips(List<Widget> chips) => ColoredBox(
    color: Colors.white,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: chips
            .map(
              (chip) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: chip,
              ),
            )
            .toList(),
      ),
    ),
  );
  Widget _card(CommunityReport report) => Container(
    margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(height: 4, color: _color(report.status)),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    child: Text(report.author.characters.first),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.author,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${_age(report.createdAt)} · ${report.city}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                children: [
                  Icon(
                    _icon(report.status),
                    size: 18,
                    color: _color(report.status),
                  ),
                  Text(
                    report.status.label,
                    style: TextStyle(
                      color: _color(report.status),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                report.place,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(report.description),
              const SizedBox(height: 8),
              Text(
                'Observed ${report.observedAt.toIso8601String().substring(0, 10)}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              if (report.photoPath != null)
                ReportImage(
                  key: ValueKey(report.photoPath),
                  repository: _repository,
                  path: report.photoPath!,
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Chip(
                    avatar: const Icon(Icons.person_outline, size: 16),
                    label: const Text('User Reported'),
                  ),
                  Text(report.verification.replaceAll('_', ' ')),
                  OutlinedButton.icon(
                    onPressed:
                        !_repository.canContribute ||
                            _voting.contains(report.id)
                        ? null
                        : () => _helpful(report),
                    icon: Icon(
                      report.isHelpful
                          ? Icons.thumb_up
                          : Icons.thumb_up_outlined,
                      size: 18,
                    ),
                    label: Text('${report.helpfulCount} helpful'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
  static Color _color(ReportStatus status) => switch (status) {
    ReportStatus.accessible => AppColors.accessible,
    ReportStatus.partial => AppColors.partial,
    ReportStatus.barrier => AppColors.barrier,
  };
  static IconData _icon(ReportStatus status) => switch (status) {
    ReportStatus.accessible => Icons.check_circle_outline,
    ReportStatus.partial => Icons.warning_amber,
    ReportStatus.barrier => Icons.block,
  };
  static String _age(DateTime created) {
    final elapsed = DateTime.now().difference(created);
    if (elapsed.inMinutes < 1) return 'Just now';
    if (elapsed.inHours < 1) return '${elapsed.inMinutes} min ago';
    if (elapsed.inDays < 1) return '${elapsed.inHours} hr ago';
    return '${elapsed.inDays} d ago';
  }
}

class ReportImage extends StatefulWidget {
  const ReportImage({super.key, required this.repository, required this.path});
  final ReportsRepository repository;
  final String path;
  @override
  State<ReportImage> createState() => _ReportImageState();
}

class _ReportImageState extends State<ReportImage> {
  late Future<String> _url = widget.repository.photoUrl(widget.path);
  Widget _retry() => TextButton.icon(
    onPressed: () =>
        setState(() => _url = widget.repository.photoUrl(widget.path)),
    icon: const Icon(Icons.refresh),
    label: const Text('Photo unavailable. Retry'),
  );
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: FutureBuilder<String>(
      future: _url,
      builder: (context, snapshot) {
        if (snapshot.hasError) return _retry();
        if (!snapshot.hasData) return const Text('Loading photo…');
        return Image.network(
          snapshot.data!,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          semanticLabel: 'Community report photo',
          errorBuilder: (_, error, stack) => _retry(),
        );
      },
    ),
  );
}
