import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/models/app_user.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/brand.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../data/profile_repository.dart';
import '../widgets/ai_bio_button.dart';

class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authControllerProvider).value?.userId;
    if (userId == null) return const SizedBox.shrink();
    return ref
        .watch(userByIdProvider(userId))
        .when(
          data: (user) => _EditProfileForm(user: user),
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(
            appBar: AppBar(title: const Text('Edit profile')),
            body: ErrorView(
              message: ApiException.from(e).message,
              onRetry: () => ref.invalidate(userByIdProvider(userId)),
            ),
          ),
        );
  }
}

class _EditProfileForm extends ConsumerStatefulWidget {
  const _EditProfileForm({required this.user});

  final AppUser user;

  @override
  ConsumerState<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends ConsumerState<_EditProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final _firstName = TextEditingController(text: widget.user.firstName);
  late final _lastName = TextEditingController(text: widget.user.lastName);
  late final _location = TextEditingController(text: widget.user.location);
  late final _bio = TextEditingController(text: widget.user.bio);
  late final _website = TextEditingController(text: widget.user.website);
  late final _linkedin = TextEditingController(text: widget.user.linkedinUrl);
  late String? _avatar = widget.user.profilePictureUrl;
  late String? _cover = widget.user.coverPictureUrl;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_firstName, _lastName, _location, _bio, _website, _linkedin]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Picks and shrinks an image: the backend stores it as base64 in the database.
  Future<String?> _pickImage({required double maxWidth}) async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: maxWidth, imageQuality: 80);
    if (file == null) return null;
    return toDataUri(await file.readAsBytes(), mimeType: 'image/jpeg');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    String? orNull(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    try {
      await ref.read(profileRepositoryProvider).updateProfile(widget.user.id, {
        ...widget.user.toJson(),
        'firstName': _firstName.text.trim(),
        'lastName': _lastName.text.trim(),
        'location': orNull(_location),
        'bio': orNull(_bio),
        'website': orNull(_website),
        'linkedinUrl': orNull(_linkedin),
        'profilePictureUrl': _avatar,
        'coverPictureUrl': _cover,
      });
      ref.invalidate(userByIdProvider(widget.user.id));
      ref.invalidate(currentUserProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved')));
        context.pop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? v) => v == null || v.trim().isEmpty ? 'Required' : null;

  Future<void> _changeCover() async {
    final image = await _pickImage(maxWidth: 1400);
    if (image != null) setState(() => _cover = image);
  }

  Future<void> _changeAvatar() async {
    final image = await _pickImage(maxWidth: 600);
    if (image != null) setState(() => _avatar = image);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cover = imageFromApi(_cover);
    final avatar = imageFromApi(_avatar);
    const gap = SizedBox(height: 16);

    Widget cameraBadge({required double size}) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: colors.surface, width: 2),
      ),
      child: Icon(Icons.photo_camera_outlined, size: size * 0.5, color: colors.onPrimary),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      Semantics(
                        button: true,
                        label: 'Change cover photo',
                        child: InkWell(
                          onTap: _changeCover,
                          child: Ink(
                            height: 112,
                            decoration: BoxDecoration(
                              gradient: cover == null ? LinearGradient(colors: [Brand.green, colors.primary]) : null,
                              image: cover == null ? null : DecorationImage(image: cover, fit: BoxFit.cover),
                            ),
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Padding(padding: const EdgeInsets.all(10), child: cameraBadge(size: 34)),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -46,
                        child: Semantics(
                          button: true,
                          label: 'Change profile picture',
                          child: GestureDetector(
                            onTap: _changeAvatar,
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(color: colors.surface, shape: BoxShape.circle),
                                  child: CircleAvatar(
                                    radius: 44,
                                    backgroundImage: avatar,
                                    child: avatar == null
                                        ? Text(widget.user.initials, style: const TextStyle(fontSize: 28))
                                        : null,
                                  ),
                                ),
                                Positioned(right: 0, bottom: 2, child: cameraBadge(size: 30)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 56),
                  Text(
                    'Tap the photos to change them',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Personal info',
              child: Column(
                children: [
                  LabeledField(
                    label: 'First name',
                    child: TextFormField(
                      controller: _firstName,
                      textCapitalization: TextCapitalization.words,
                      validator: _required,
                    ),
                  ),
                  gap,
                  LabeledField(
                    label: 'Last name',
                    child: TextFormField(
                      controller: _lastName,
                      textCapitalization: TextCapitalization.words,
                      validator: _required,
                    ),
                  ),
                  gap,
                  LabeledField(
                    label: 'Location',
                    child: TextFormField(
                      controller: _location,
                      decoration: const InputDecoration(
                        hintText: 'Tunis, Tunisia',
                        prefixIcon: Icon(Icons.place_outlined),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'About me',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _bio,
                    minLines: 3,
                    maxLines: 6,
                    maxLength: 255,
                    decoration: const InputDecoration(
                      hintText: 'What you do, what you are good at — or a few notes for the AI',
                    ),
                  ),
                  AiBioButton(controller: _bio, user: widget.user),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Links',
              child: Column(
                children: [
                  LabeledField(
                    label: 'Website',
                    child: TextFormField(
                      controller: _website,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(hintText: 'mysite.com', prefixIcon: Icon(Icons.language)),
                    ),
                  ),
                  gap,
                  LabeledField(
                    label: 'LinkedIn',
                    child: TextFormField(
                      controller: _linkedin,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        hintText: 'linkedin.com/in/you',
                        prefixIcon: Icon(Icons.business),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save changes'),
          ),
        ),
      ),
    );
  }
}
