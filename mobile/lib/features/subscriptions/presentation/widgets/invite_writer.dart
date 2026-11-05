import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/brand.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../profile/data/competence_repository.dart';
import '../../../profile/data/models/competence.dart';
import '../../data/referral_repository.dart';

enum InviteChannel {
  whatsapp('WhatsApp', 'WHATSAPP', Icons.chat_outlined),
  linkedin('LinkedIn', 'LINKEDIN', Icons.work_outline),
  email('Email', 'EMAIL', Icons.mail_outline);

  const InviteChannel(this.label, this.apiName, this.icon);

  final String label;
  final String apiName;
  final IconData icon;
}

String _phoneLanguage() => switch (PlatformDispatcher.instance.locale.languageCode) {
  'fr' => 'French',
  'ar' => 'Arabic',
  _ => 'English',
};

/// "Write my invite with AI": a personal message with my code, for the channel I pick, editable, then shared.
class InviteWriterCard extends ConsumerStatefulWidget {
  const InviteWriterCard({super.key, required this.code});

  final String code;

  @override
  ConsumerState<InviteWriterCard> createState() => _InviteWriterCardState();
}

class _InviteWriterCardState extends ConsumerState<InviteWriterCard> {
  final _message = TextEditingController();
  InviteChannel _channel = InviteChannel.whatsapp;
  bool _writing = false;
  bool _written = false;
  String? _error;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _write() async {
    setState(() {
      _writing = true;
      _error = null;
    });
    try {
      final me = await ref.read(currentUserProvider.future).timeout(const Duration(seconds: 8));
      // The skills only make the message more personal: without the catalog, write it anyway.
      final catalog = await ref
          .read(competenceCatalogProvider.future)
          .timeout(const Duration(seconds: 8))
          .catchError((_) => <Competence>[]);
      final skills = [
        for (final c in catalog)
          if (me?.competenceIds.contains(c.id) ?? false) c.name,
      ].take(5).join(', ');
      final text = await ref
          .read(referralRepositoryProvider)
          .writeInvite(
            code: widget.code,
            firstName: me?.firstName,
            role: me?.role.name.toUpperCase(),
            skills: skills,
            channel: _channel.apiName,
            language: _phoneLanguage(),
          );
      if (!mounted) return;
      _message.text = text;
      setState(() => _written = true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _writing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppAccent.purple.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppAccent.purple, size: 20),
              const SizedBox(width: 8),
              Text(
                'Write my invite with AI',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'A personal message with your code, for where you share it.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          FilterPills<InviteChannel>(
            values: InviteChannel.values,
            selected: _channel,
            label: (c) => c.label,
            icon: (c) => c.icon,
            onSelected: (c) => setState(() => _channel = c),
          ),
          const SizedBox(height: 12),
          if (_written) ...[
            TextField(
              controller: _message,
              minLines: 3,
              maxLines: 10,
              decoration: InputDecoration(filled: true, fillColor: theme.colorScheme.surface),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _message.text));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message copied')));
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                    onPressed: () =>
                        SharePlus.instance.share(ShareParams(subject: 'Join me on ${Brand.name}', text: _message.text)),
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: AiButton(label: _written ? 'Write another' : 'Write it', busy: _writing, onPressed: _write),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
            ),
        ],
      ),
    );
  }
}
