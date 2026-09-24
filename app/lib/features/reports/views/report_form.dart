import 'package:bictc/shared/models/community_report.dart';
import 'package:bictc/shared/repositories/reports_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

const reportCities = [
  'Metro Manila',
  'Cebu',
  'Davao',
  'Iloilo',
  'General Santos',
  'Other',
];

class ReportForm extends StatefulWidget {
  const ReportForm({
    super.key,
    required this.repository,
    required this.initialStatus,
  });
  final ReportsRepository repository;
  final ReportStatus initialStatus;
  @override
  State<ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<ReportForm> {
  final _form = GlobalKey<FormState>();
  final _author = TextEditingController();
  final _place = TextEditingController();
  final _description = TextEditingController();
  late ReportStatus _status = widget.initialStatus;
  String _city = reportCities.first;
  DateTime _observed = DateUtils.dateOnly(DateTime.now());
  ReportPhoto? _photo;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    widget.repository.addListener(_authChanged);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _recoverPhoto();
    }
  }

  Future<void> _recoverPhoto() async {
    if (!widget.repository.canContribute) return;
    _busy = true;
    try {
      final recovered = await ImagePicker().retrieveLostData();
      if (recovered.isEmpty) return;
      if (recovered.exception != null) throw recovered.exception!;
      final files = recovered.files;
      if (files == null || files.isEmpty) return;
      if (await files.first.length() > 5 * 1024 * 1024) {
        throw const FormatException('Choose a photo smaller than 5 MB.');
      }
      final photo = ReportPhoto(await files.first.readAsBytes());
      if (mounted && widget.repository.canContribute) {
        setState(() {
          _photo = photo;
          _error = 'Recovered your photo after the app restarted. Re-enter the report details before publishing.';
        });
      }
    } on MissingPluginException {
      // A platform without the picker cannot have a recoverable selection.
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not restore the previous photo. Please select it again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _authChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.repository.removeListener(_authChanged);
    _author.dispose();
    _place.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (!widget.repository.canContribute || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        imageQuality: 85,
      );
      if (file != null) {
        if (await file.length() > 5 * 1024 * 1024) {
          throw const FormatException('Choose a photo smaller than 5 MB.');
        }
        final photo = ReportPhoto(await file.readAsBytes());
        if (mounted) setState(() => _photo = photo);
      }
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Unable to open this photo. Try a JPEG, PNG, or WebP image.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _publish() async {
    if (_busy ||
        !widget.repository.canContribute ||
        !_form.currentState!.validate()) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final attached = await widget.repository.submit(
        ReportDraft(
          author: _author.text,
          place: _place.text,
          city: _city,
          description: _description.text,
          status: _status,
          observedAt: _observed,
          photo: _photo,
        ),
      );
      if (mounted) {
        Navigator.pop(
          context,
          attached
              ? 'Report published.'
              : 'Report published. Photo attachment could not be confirmed.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not confirm publication. Check your connection and sign-in. Check the feed before trying again to avoid a duplicate.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(
    TextEditingController controller,
    String label,
    int max, {
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      enabled: !_busy,
      maxLength: max,
      minLines: lines,
      maxLines: lines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) => value == null || value.trim().isEmpty
          ? 'Enter ${label.toLowerCase()}.'
          : null,
    ),
  );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Share an access report')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Share what you observed. Reports are community observations, not accessibility certification.',
                ),
                const SizedBox(height: 20),
                if (!widget.repository.canContribute)
                  const Text(
                    'Your session ended. Sign in again before publishing.',
                  ),
                _field(_author, 'Public display name', 80),
                _field(_place, 'Establishment name', 160),
                DropdownButtonFormField<String>(
                  initialValue: _city,
                  decoration: const InputDecoration(labelText: 'City / region'),
                  items: reportCities
                      .map(
                        (city) =>
                            DropdownMenuItem(value: city, child: Text(city)),
                      )
                      .toList(),
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _city = value!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ReportStatus>(
                  initialValue: _status,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Observed access',
                  ),
                  items: ReportStatus.values
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        ),
                      )
                      .toList(),
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _status = value!),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    'Observed ${_observed.toIso8601String().substring(0, 10)}',
                  ),
                  onPressed: _busy
                      ? null
                      : () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _observed,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (date != null && mounted) {
                            setState(() => _observed = date);
                          }
                        },
                ),
                const SizedBox(height: 16),
                _field(_description, 'What did you observe?', 2000, lines: 4),
                const Text(
                  'Optional photo: avoid faces and private information. Your name, report, and attached photo will be publicly readable.',
                ),
                if (_photo != null) ...[
                  const SizedBox(height: 12),
                  Image.memory(
                    _photo!.bytes,
                    height: 160,
                    fit: BoxFit.contain,
                    errorBuilder: (_, error, stack) =>
                        const Text('Photo preview unavailable.'),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _photo = null),
                    child: const Text('Remove photo'),
                  ),
                ],
                OutlinedButton.icon(
                  onPressed: _busy || !widget.repository.canContribute
                      ? null
                      : _pickPhoto,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(_photo == null ? 'Add photo' : 'Change photo'),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Semantics(liveRegion: true, child: Text(_error!)),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy || !widget.repository.canContribute
                      ? null
                      : _publish,
                  child: Text(_busy ? 'Please wait…' : 'Publish report'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
