import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/ui_kit.dart';
import '../../data/chat_socket.dart';
import '../../data/models/availability_models.dart';
import '../messaging_providers.dart';

/// Opens a page of another module, or says it's not there yet (modules live on separate branches).
void openModuleLink(BuildContext context, String location, {required String comingSoon}) {
  if (GoRouter.of(context).configuration.findMatch(Uri.parse(location)).isError) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(comingSoon)));
    return;
  }
  context.push(location);
}

/// Thin bar at the top of the page while the chat connection is not up.
class ConnectionBanner extends ConsumerWidget {
  const ConnectionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(socketStatusProvider);
    if (status == SocketStatus.connected) return const SizedBox(height: 0);
    final connecting = status == SocketStatus.connecting;
    final color = connecting ? AppAccent.amber : AppAccent.red;
    return Container(
      height: 28,
      width: double.infinity,
      color: color.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(connecting ? Icons.sync : Icons.cloud_off_outlined, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            connecting ? 'Connecting to the chat…' : 'Offline — reconnecting…',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Colored dot + status text of a freelancer.
class AvailabilityBadge extends StatelessWidget {
  const AvailabilityBadge({super.key, required this.profile, this.showLocalTime = true});

  final AvailabilityProfile profile;
  final bool showLocalTime;

  @override
  Widget build(BuildContext context) {
    final local = profile.localTime();
    final time = '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: profile.status.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            showLocalTime ? '${profile.statusText} · $time local time' : profile.statusText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ],
    );
  }
}

/// The bar to write at the bottom of a chat: optional attach button, rounded field, green send button.
class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.sending,
    required this.onSend,
    this.onAttach,
    this.onSuggest,
    this.suggesting = false,
    this.hintText = 'Message',
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback? onAttach;

  /// Asks the AI for replies (a spark button); null hides it.
  final VoidCallback? onSuggest;
  final bool suggesting;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide(color: colors.outlineVariant),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(onAttach == null ? 12 : 4, 8, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (onAttach != null)
                IconButton(
                  tooltip: 'Attach',
                  onPressed: sending ? null : onAttach,
                  icon: Icon(Icons.add_circle_outline, color: colors.primary),
                ),
              if (onSuggest != null)
                IconButton(
                  tooltip: 'Suggest replies',
                  onPressed: sending || suggesting ? null : onSuggest,
                  icon: suggesting
                      ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome, color: AppAccent.purple),
                ),
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: hintText,
                    isDense: true,
                    filled: true,
                    fillColor: colors.surfaceContainerLow,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: border,
                    enabledBorder: border,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Send',
                style: IconButton.styleFrom(minimumSize: const Size(46, 46)),
                onPressed: sending ? null : onSend,
                icon: sending
                    ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
