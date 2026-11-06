import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/app_user.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../data/profile_ai_repository.dart';

/// "Write with AI" under a bio field: what is typed there becomes notes for the AI,
/// and the answer replaces it (with Undo).
class AiBioButton extends ConsumerStatefulWidget {
  const AiBioButton({super.key, required this.controller, required this.user});

  final TextEditingController controller;
  final AppUser user;

  @override
  ConsumerState<AiBioButton> createState() => _AiBioButtonState();
}

class _AiBioButtonState extends ConsumerState<AiBioButton> {
  bool _writing = false;

  Future<void> _write() async {
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    final notes = widget.controller.text.trim();
    setState(() => _writing = true);
    try {
      final bio = await ref.read(profileAiRepositoryProvider).writeBio(widget.user, notes: notes.isEmpty ? null : notes);
      if (!mounted) return;
      widget.controller.text = bio;
      messenger.showSnackBar(SnackBar(
        content: const Text('The AI wrote your bio. Change anything before saving.'),
        action: SnackBarAction(label: 'Undo', onPressed: () => widget.controller.text = notes),
      ));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _writing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: AiButton(label: 'Write with AI', busy: _writing, onPressed: _write),
    );
  }
}
