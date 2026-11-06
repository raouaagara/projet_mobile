import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../../../../core/utils/image_utils.dart';

/// White "paper" to sign with a finger, like the web app's signature pad.
/// Read the result with [SignaturePadController.exportDataUri].
class SignaturePadController extends SignatureController {
  SignaturePadController() : super(penStrokeWidth: 2.5, penColor: Colors.black, exportBackgroundColor: Colors.white);

  /// PNG data URI, or null if nothing was drawn.
  Future<String?> exportDataUri() async {
    if (isEmpty) return null;
    final bytes = await toPngBytes();
    return bytes == null ? null : toDataUri(bytes);
  }
}

class SignaturePad extends StatelessWidget {
  const SignaturePad({super.key, required this.controller, this.error = false, this.height = 170});

  final SignaturePadController controller;

  /// Red border when a signature is required but missing.
  final bool error;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: error ? colors.error : colors.outline, width: error ? 2 : 1),
        ),
        child: Stack(
          children: [
            Signature(controller: controller, height: height, backgroundColor: Colors.white),
            // Baseline and hint, like on paper.
            Positioned(
              left: 20,
              right: 20,
              bottom: 36,
              child: IgnorePointer(child: Container(height: 1, color: Colors.black26)),
            ),
            Positioned(
              left: 20,
              bottom: 12,
              child: IgnorePointer(
                child: ValueListenableBuilder(
                  valueListenable: controller,
                  builder: (context, points, _) => Text(
                    points.isEmpty ? 'Sign here with your finger' : '',
                    style: const TextStyle(color: Colors.black45, fontSize: 12),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: ValueListenableBuilder(
                valueListenable: controller,
                builder: (context, points, _) => points.isEmpty
                    ? const SizedBox()
                    : TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: Colors.black87),
                        onPressed: controller.clear,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Clear'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A signature saved on a contract (PNG data URI).
class SignatureImage extends StatelessWidget {
  const SignatureImage({super.key, this.label, required this.dataUri, this.name});

  final String? label;
  final String? dataUri;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final image = imageFromApi(dataUri);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 6),
        ],
        Container(
          height: 80,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          alignment: Alignment.center,
          child: image == null
              ? const Text('Not signed yet', style: TextStyle(color: Colors.black45))
              : Padding(
                  padding: const EdgeInsets.all(6),
                  child: Image(image: image, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox()),
                ),
        ),
        if (name != null) ...[const SizedBox(height: 4), Text(name!, style: theme.textTheme.bodySmall)],
      ],
    );
  }
}

/// Scrolls to the card holding the signature pad, e.g. when the user tries to send without signing.
void showSignatureCard(GlobalKey card) {
  final context = card.currentContext;
  if (context == null) return;
  Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 300), alignment: 0.3).ignore();
}
