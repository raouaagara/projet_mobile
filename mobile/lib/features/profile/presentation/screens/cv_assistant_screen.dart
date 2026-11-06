import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../data/ai_access.dart';
import '../../data/models/cv_analysis.dart';
import '../../data/skill_test_repository.dart';
import '../widgets/premium_required.dart';

/// AI CV assistant (Premium): analyses a CV for a target domain and rewrites it.
class CvAssistantScreen extends ConsumerWidget {
  const CvAssistantScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI CV assistant')),
      body: AsyncValueView(
        value: ref.watch(aiAccessProvider),
        onRetry: () => ref.invalidate(aiAccessProvider),
        data: (hasAccess) => hasAccess ? const _CvAssistant() : const PremiumRequired(feature: 'The AI CV assistant'),
      ),
    );
  }
}

enum _Source { text, photo }

class _CvAssistant extends ConsumerStatefulWidget {
  const _CvAssistant();

  @override
  ConsumerState<_CvAssistant> createState() => _CvAssistantState();
}

class _CvAssistantState extends ConsumerState<_CvAssistant> {
  final _text = TextEditingController();
  String _domain = cvTargetDomains.first;
  _Source _source = _Source.text;
  XFile? _photo;
  bool _loading = false;
  CvAnalysis? _result;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _snack(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _pickPhoto(ImageSource source) async {
    final photo = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 85);
    if (photo != null) setState(() => _photo = photo);
  }

  Future<void> _analyze() async {
    final repository = ref.read(skillTestRepositoryProvider);
    if (_source == _Source.text && _text.text.trim().length < 50) {
      _snack('Paste your whole CV (at least a few lines).');
      return;
    }
    if (_source == _Source.photo && _photo == null) {
      _snack('Take or choose a photo of your CV first.');
      return;
    }
    setState(() => _loading = true);
    try {
      final result = _source == _Source.text
          ? await repository.analyzeCvText(cvText: _text.text.trim(), targetDomain: _domain)
          : await repository.analyzeCvImage(
              bytes: await _photo!.readAsBytes(),
              mimeType: _photo!.mimeType ?? 'image/jpeg',
              targetDomain: _domain,
            );
      setState(() => _result = result);
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      return _ResultView(result: _result!, domain: _domain, onRestart: () => setState(() => _result = null));
    }
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppAccent.purple.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const IconBubble(icon: Icons.auto_awesome, color: AppAccent.purple, size: 52, solid: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your CV, tailored by AI',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'For the jobs you want, with the skills to add.',
                      style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        LabeledField(
          label: 'Target domain',
          child: DropdownButtonFormField<String>(
            initialValue: _domain,
            items: [for (final d in cvTargetDomains) DropdownMenuItem(value: d, child: Text(d))],
            onChanged: (v) => setState(() => _domain = v!),
          ),
        ),
        const SizedBox(height: 16),
        LabeledField(
          label: 'Your CV',
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<_Source>(
              segments: const [
                ButtonSegment(value: _Source.text, icon: Icon(Icons.notes), label: Text('Paste text')),
                ButtonSegment(value: _Source.photo, icon: Icon(Icons.photo_camera_outlined), label: Text('Photo')),
              ],
              selected: {_source},
              onSelectionChanged: (s) => setState(() => _source = s.first),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_source == _Source.text)
          TextField(
            controller: _text,
            minLines: 10,
            maxLines: 20,
            decoration: const InputDecoration(hintText: 'Paste the text of your CV (French or English)'),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  IconBubble(
                    icon: _photo == null ? Icons.document_scanner_outlined : Icons.check_rounded,
                    color: _photo == null ? AppAccent.blue : AppAccent.green,
                    size: 60,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _photo == null ? 'A clear photo of each page works best.' : _photo!.name,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _pickPhoto(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('Camera'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _pickPhoto(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Gallery'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _loading ? null : _analyze,
          icon: _loading
              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.auto_awesome),
          label: Text(_loading ? 'Analysing… (up to a minute)' : 'Analyse my CV'),
        ),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result, required this.domain, required this.onRestart});

  final CvAnalysis result;
  final String domain;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget section(String title, IconData icon, Widget child) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SectionCard(title: title, icon: icon, child: child),
    );

    Widget chips(List<String> items) =>
        Wrap(spacing: 8, runSpacing: 8, children: [for (final s in items) PillTag(s, icon: Icons.add)]);

    // Strengths and suggestions are sentences: a list reads better than chips.
    Widget bullets(List<String> items, {required IconData icon, required Color color}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Expanded(child: Text(s, style: const TextStyle(height: 1.4))),
              ],
            ),
          ),
      ],
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            const IconBubble(icon: Icons.auto_awesome, color: AppAccent.purple, size: 44, solid: true),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Your CV for $domain',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (result.summary.isNotEmpty) section('Summary', Icons.insights_outlined, Text(result.summary)),
        if (result.strengthAreas.isNotEmpty)
          section(
            'Strengths',
            Icons.thumb_up_alt_outlined,
            bullets(result.strengthAreas, icon: Icons.check_circle_outline, color: AppAccent.green),
          ),
        if (result.missingSkills.isNotEmpty) section('Skills to add', Icons.trending_up, chips(result.missingSkills)),
        if (result.suggestions.isNotEmpty)
          section(
            'Suggestions',
            Icons.lightbulb_outline,
            bullets(result.suggestions, icon: Icons.lightbulb_outline, color: AppAccent.amber),
          ),
        section(
          'Improved CV',
          Icons.description_outlined,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SelectableText(result.improvedCv, style: theme.textTheme.bodySmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: result.improvedCv));
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
                      }
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        SharePlus.instance.share(ShareParams(text: result.improvedCv, subject: 'My CV — $domain')),
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ],
              ),
            ],
          ),
        ),
        OutlinedButton(onPressed: onRestart, child: const Text('Analyse another CV')),
      ],
    );
  }
}
