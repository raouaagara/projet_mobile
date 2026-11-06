import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/models/user_role.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../data/chat_repository.dart';
import '../../data/chat_socket.dart';
import '../../data/models/chat_models.dart';
import '../../messaging_paths.dart';
import '../format.dart';
import '../messaging_providers.dart';
import '../widgets/common.dart';

const _reactionChoices = ['👍', '❤️', '😂', '😮', '🙏', '🎉'];

/// The phone's language, as the AI understands it ("French"), for translations.
String _myLanguage() => switch (PlatformDispatcher.instance.locale.languageCode) {
  'fr' => 'French',
  'ar' => 'Arabic',
  'en' => 'English',
  'de' => 'German',
  'es' => 'Spanish',
  'it' => 'Italian',
  final code => code,
};

/// A conversation with [otherUserId], live: new messages, edits, deletes, reactions, read receipts.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversationId, required this.otherUserId});

  final int conversationId;
  final int otherUserId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  late final OpenConversation _openConversation;
  StreamSubscription<MessageRejected>? _rejections;
  bool _sending = false;
  bool _suggesting = false;

  /// Replies suggested by the AI, shown above the composer until one is picked or a message is sent.
  List<String> _suggestions = const [];

  /// AI translations shown under their message, by message id.
  final _translations = <int, String>{};

  @override
  void initState() {
    super.initState();
    _openConversation = ref.read(openConversationProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openConversation.set(widget.conversationId);
      final controller = ref.read(conversationProvider(widget.conversationId).notifier);
      controller.markRead();
      _rejections = controller.rejections.stream.listen((rejection) {
        if (!mounted) return;
        if (_input.text.isEmpty) _input.text = rejection.content;
        _snack('Not sent: ${rejection.reason}');
      });
    });
  }

  @override
  void dispose() {
    _rejections?.cancel();
    _input.dispose();
    final id = widget.conversationId;
    final open = _openConversation;
    // Providers can't change while the tree is being torn down.
    Future.microtask(() => open.clear(id));
    super.dispose();
  }

  void _snack(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  ConversationController get _controller => ref.read(conversationProvider(widget.conversationId).notifier);

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _controller.send(text, recipientId: widget.otherUserId);
      _input.clear();
      if (_suggestions.isNotEmpty) setState(() => _suggestions = const []);
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _suggest() async {
    final me = ref.read(authControllerProvider).value?.userId;
    if (me == null) return;
    setState(() => _suggesting = true);
    try {
      final replies = await ref.read(chatRepositoryProvider).suggestReplies(widget.conversationId, me);
      if (mounted) setState(() => _suggestions = replies);
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _suggesting = false);
    }
  }

  /// Puts the reply in the box (not sent): the user can still change it.
  void _pick(String reply) {
    _input.value = TextEditingValue(
      text: reply,
      selection: TextSelection.collapsed(offset: reply.length),
    );
    setState(() => _suggestions = const []);
  }

  Future<void> _attach() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MenuTile(
              icon: Icons.photo_outlined,
              color: AppAccent.purple,
              title: 'Photo',
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            MenuTile(
              icon: Icons.photo_camera_outlined,
              color: AppAccent.blue,
              title: 'Camera',
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            MenuTile(
              icon: Icons.picture_as_pdf_outlined,
              color: AppAccent.red,
              title: 'PDF document',
              onTap: () => Navigator.pop(context, 'pdf'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null) return;

    List<int>? bytes;
    String? name;
    if (choice == 'pdf') {
      final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['pdf']);
      if (file == null) return;
      bytes = await file.xFile.readAsBytes();
      name = file.name;
    } else {
      final image = await ImagePicker().pickImage(
        source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (image == null) return;
      bytes = await image.readAsBytes();
      name = image.name;
    }
    if (bytes.length > 10 * 1024 * 1024) {
      _snack('The file is too big (10 MB max).');
      return;
    }
    setState(() => _sending = true);
    try {
      await _controller.sendFile(
        bytes: bytes,
        fileName: name,
        recipientId: widget.otherUserId,
        caption: _input.text.trim(),
      );
      _input.clear();
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _showActions(ChatMessage message, bool mine) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (final emoji in _reactionChoices)
                    IconButton(
                      tooltip: 'React $emoji',
                      onPressed: () => Navigator.pop(context, 'react:$emoji'),
                      icon: Text(emoji, style: const TextStyle(fontSize: 26)),
                    ),
                ],
              ),
            ),
            const Divider(),
            if (message.text.isNotEmpty && message.id != null)
              ListTile(
                leading: const Icon(Icons.translate, color: AppAccent.purple),
                title: Text(_translations.containsKey(message.id) ? 'Hide translation' : 'Translate'),
                onTap: () => Navigator.pop(context, 'translate'),
              ),
            if (message.text.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy'),
                onTap: () => Navigator.pop(context, 'copy'),
              ),
            if (mine && message.attachmentUrl == null)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit'),
                onTap: () => Navigator.pop(context, 'edit'),
              ),
            if (mine)
              ListTile(
                leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                title: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    try {
      if (action.startsWith('react:')) {
        await _controller.react(message, action.substring(6));
      } else if (action == 'translate') {
        final id = message.id!;
        if (_translations.remove(id) != null) {
          setState(() {});
        } else {
          final text = await ref.read(chatRepositoryProvider).translate(id, _myLanguage());
          if (mounted) setState(() => _translations[id] = text);
        }
      } else if (action == 'copy') {
        await Clipboard.setData(ClipboardData(text: message.text));
        _snack('Copied');
      } else if (action == 'edit') {
        final text = await _editDialog(message.text);
        if (text != null && text != message.text) await _controller.edit(message, text);
      } else if (action == 'delete') {
        await _controller.delete(message);
      }
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  Future<String?> _editDialog(String initial) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit message'),
        content: TextField(controller: controller, autofocus: true, minLines: 1, maxLines: 6),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authControllerProvider).value?.userId;
    final messages = ref.watch(conversationProvider(widget.conversationId));
    final other = ref.watch(chatUserProvider(widget.otherUserId)).value;
    final availability = ref.watch(availabilityOfProvider(widget.otherUserId));

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        centerTitle: false,
        actions: [
          if ((messages.value?.length ?? 0) >= 3)
            IconButton(
              tooltip: 'Catch me up',
              icon: const Icon(Icons.summarize_outlined),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => _CatchUpSheet(conversationId: widget.conversationId, userId: me ?? 0),
              ),
            ),
        ],
        title: InkWell(
          onTap: () => openModuleLink(
            context,
            LinkedPaths.profile(widget.otherUserId),
            comingSoon: 'Public profiles arrive with module 1 (profile).',
          ),
          child: Row(
            children: [
              UserAvatar(user: other, radius: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      other?.fullName ?? '…',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (availability != null)
                      AvailabilityBadge(profile: availability)
                    else if (other != null)
                      Text(
                        other.role == UserRole.freelancer ? 'Freelancer' : 'Client',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          const ConnectionBanner(),
          Expanded(
            child: AsyncValueView(
              value: messages,
              onRetry: () => ref.invalidate(conversationProvider(widget.conversationId)),
              data: (messages) => messages.isEmpty
                  ? EmptyView(icon: Icons.waving_hand_outlined, message: 'Say hello to ${other?.firstName ?? 'them'}!')
                  : _MessageList(
                      messages: messages,
                      me: me ?? 0,
                      translations: _translations,
                      onLongPress: _showActions,
                    ),
            ),
          ),
          if (_suggestions.isNotEmpty) _SuggestedReplies(replies: _suggestions, onPick: _pick),
          ChatComposer(
            controller: _input,
            sending: _sending,
            onSend: _send,
            onAttach: _attach,
            onSuggest: (messages.value?.isNotEmpty ?? false) ? _suggest : null,
            suggesting: _suggesting,
          ),
        ],
      ),
    );
  }
}

/// "Catch me up": the AI's summary of the conversation, decisions, and to-dos for each side.
class _CatchUpSheet extends ConsumerStatefulWidget {
  const _CatchUpSheet({required this.conversationId, required this.userId});

  final int conversationId;
  final int userId;

  @override
  ConsumerState<_CatchUpSheet> createState() => _CatchUpSheetState();
}

class _CatchUpSheetState extends ConsumerState<_CatchUpSheet> {
  late Future<ChatCatchUp> _catchUp = _load();

  Future<ChatCatchUp> _load() => ref.read(chatRepositoryProvider).catchUp(widget.conversationId, widget.userId);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget title(String text) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 6),
      child: Text(text, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
    );
    Widget line(String text, IconData icon, Color color) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(height: 1.45))),
        ],
      ),
    );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, scroll) => FutureBuilder<ChatCatchUp>(
        future: _catchUp,
        builder: (context, snapshot) {
          final children = <Widget>[
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppAccent.purple),
                const SizedBox(width: 8),
                Text('Catch me up', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
          ];
          if (snapshot.connectionState != ConnectionState.done) {
            children.add(
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          } else if (snapshot.hasError) {
            children.add(
              ErrorView(
                message: ApiException.from(snapshot.error!).message,
                onRetry: () => setState(() => _catchUp = _load()),
              ),
            );
          } else {
            final c = snapshot.data!;
            children.addAll([
              const SizedBox(height: 12),
              for (final s in c.summary)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(s, style: theme.textTheme.bodyLarge?.copyWith(height: 1.45)),
                ),
              if (c.decisions.isNotEmpty) ...[
                title('Agreed'),
                for (final d in c.decisions) line(d, Icons.handshake_outlined, AppAccent.green),
              ],
              if (c.myTodos.isNotEmpty) ...[
                title('For you'),
                for (final t in c.myTodos) line(t, Icons.radio_button_unchecked, AppAccent.purple),
              ],
              if (c.theirTodos.isNotEmpty) ...[
                title('For them'),
                for (final t in c.theirTodos) line(t, Icons.schedule, AppAccent.blue),
              ],
              const SizedBox(height: 16),
              Text(
                'Written by AI from the last messages.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ]);
          }
          return ListView(controller: scroll, padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), children: children);
        },
      ),
    );
  }
}

/// The AI's replies as tappable chips, sideways, with a light violet edge: they are suggestions, not messages.
class _SuggestedReplies extends StatelessWidget {
  const _SuggestedReplies({required this.replies, required this.onPick});

  final List<String> replies;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: AppAccent.purple.withValues(alpha: 0.06),
      padding: const EdgeInsets.fromLTRB(12, 8, 0, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final reply in replies)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  avatar: const Icon(Icons.auto_awesome, size: 14, color: AppAccent.purple),
                  label: Text(reply),
                  labelStyle: theme.textTheme.bodyMedium,
                  side: BorderSide(color: AppAccent.purple.withValues(alpha: 0.3)),
                  backgroundColor: theme.colorScheme.surface,
                  onPressed: () => onPick(reply),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.me,
    required this.onLongPress,
    this.translations = const {},
  });

  final List<ChatMessage> messages;
  final int me;
  final Map<int, String> translations;
  final void Function(ChatMessage message, bool mine) onLongPress;

  @override
  Widget build(BuildContext context) {
    // Newest at the bottom: the list is reversed, so build from the end.
    final items = <Widget>[];
    for (var i = messages.length - 1; i >= 0; i--) {
      final message = messages[i];
      final mine = message.senderId == me;
      items.add(
        _Bubble(
          message: message,
          mine: mine,
          translation: translations[message.id],
          onLongPress: () => onLongPress(message, mine),
        ),
      );
      final time = message.timestamp;
      final previous = i > 0 ? messages[i - 1].timestamp : null;
      if (time != null && (previous == null || !DateUtils.isSameDay(previous, time))) {
        items.add(_DaySeparator(label: dayLabel(time)));
      }
    }
    return ListView(reverse: true, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), children: items);
  }
}

class _DaySeparator extends StatelessWidget {
  const _DaySeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine, required this.onLongPress, this.translation});

  final ChatMessage message;
  final bool mine;

  /// The AI translation, shown under the original.
  final String? translation;
  final VoidCallback onLongPress;

  Future<void> _openAttachment(BuildContext context) async {
    final url = message.attachmentUrl!;
    if (message.isImage) {
      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _ImageViewer(url: url)));
      return;
    }
    final opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Can't open this file.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final background = mine ? colors.primary : colors.surface;
    final foreground = mine ? colors.onPrimary : colors.onSurface;
    final reactions = message.reactions;
    final time = message.timestamp;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Column(
            crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onLongPress: onLongPress,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                  decoration: BoxDecoration(
                    color: background,
                    border: mine ? null : Border.all(color: colors.outlineVariant),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(mine ? 20 : 6),
                      bottomRight: Radius.circular(mine ? 6 : 20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.attachmentUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: GestureDetector(
                            onTap: () => _openAttachment(context),
                            child: message.isImage
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      message.attachmentUrl!,
                                      height: 200,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) =>
                                          _FileChip(name: message.attachmentName, color: foreground),
                                    ),
                                  )
                                : _FileChip(name: message.attachmentName, color: foreground),
                          ),
                        ),
                      if (message.text.isNotEmpty)
                        Text(message.text, style: TextStyle(color: foreground, fontSize: 15)),
                      if (translation != null) ...[
                        Divider(height: 14, color: foreground.withValues(alpha: 0.25)),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.translate, size: 13, color: foreground.withValues(alpha: 0.7)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                translation!,
                                style: TextStyle(color: foreground, fontSize: 15, fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (time != null)
                            Text(
                              hourMinute(time),
                              style: theme.textTheme.labelSmall?.copyWith(color: foreground.withValues(alpha: 0.7)),
                            ),
                          if (mine) ...[
                            const SizedBox(width: 4),
                            Icon(
                              message.seen == false ? Icons.done : Icons.done_all,
                              size: 14,
                              color: foreground.withValues(alpha: message.seen == true ? 1 : 0.7),
                              semanticLabel: message.seen == false ? 'Sent' : 'Seen',
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (reactions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Wrap(
                    spacing: 4,
                    children: [
                      for (final entry in reactions.entries)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: colors.outlineVariant),
                          ),
                          child: Text('${entry.key} ${entry.value}', style: theme.textTheme.labelSmall),
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
}

class _FileChip extends StatelessWidget {
  const _FileChip({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pdf = name.toLowerCase().endsWith('.pdf');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(pdf ? Icons.picture_as_pdf : Icons.insert_drive_file_outlined, color: color),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, decoration: TextDecoration.underline, decorationColor: color),
          ),
        ),
      ],
    );
  }
}

class _ImageViewer extends StatelessWidget {
  const _ImageViewer({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: Center(child: InteractiveViewer(child: Image.network(url))),
    );
  }
}
