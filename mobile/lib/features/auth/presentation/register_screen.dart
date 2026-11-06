import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/countries.dart';
import '../../../core/models/user_role.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/router/app_paths.dart';
import 'auth_controller.dart';
import 'widgets/auth_widgets.dart';

/// Second step of the sign-up: the account form, for the [role] chosen before.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key, required this.role});

  final UserRole role;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _country;
  bool _agreed = false;
  bool _showTermsError = false;
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_firstName, _lastName, _email, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState!.validate();
    setState(() => _showTermsError = !_agreed);
    if (!valid || !_agreed) return;
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).register(
            firstName: _firstName.text,
            lastName: _lastName.text,
            email: _email.text,
            password: _password.text,
            role: widget.role,
            country: _country,
          );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _required(String? v) => v == null || v.trim().isEmpty ? 'Required' : null;

  void _back() => context.canPop() ? context.pop() : context.go(AppPaths.register);

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: AuthLayout(
          header: AuthHeader(compact: true, onBack: _back),
          content: [
            AuthTitle(
              'Create a new account',
              subtitle: widget.role == UserRole.client ? 'You are joining as a client' : 'You are joining as a freelancer',
            ),
            const SizedBox(height: 24),
            LabeledField(
              label: 'First name',
              child: TextFormField(
                controller: _firstName,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.givenName],
                decoration: const InputDecoration(hintText: 'Enter your first name'),
                validator: _required,
              ),
            ),
            const SizedBox(height: 16),
            LabeledField(
              label: 'Last name',
              child: TextFormField(
                controller: _lastName,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.familyName],
                decoration: const InputDecoration(hintText: 'Enter your last name'),
                validator: _required,
              ),
            ),
            const SizedBox(height: 16),
            LabeledField(
              label: 'Email',
              child: TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(hintText: 'Enter your email'),
                validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
              ),
            ),
            const SizedBox(height: 16),
            LabeledField(label: 'Country', child: _CountryField(onSelected: (name) => _country = name)),
            const SizedBox(height: 16),
            LabeledField(
              label: 'Password',
              child: TextFormField(
                controller: _password,
                obscureText: _obscure,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  hintText: 'At least 6 characters',
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    tooltip: _obscure ? 'Show password' : 'Hide password',
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) => v == null || v.length < 6 ? 'At least 6 characters' : null,
              ),
            ),
            const SizedBox(height: 12),
            _TermsCheckbox(
              agreed: _agreed,
              showError: _showTermsError && !_agreed,
              onChanged: (value) => setState(() => _agreed = value),
            ),
          ],
          actions: [
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create my account'),
            ),
            const SizedBox(height: 8),
            AuthSwitchLink(
              question: 'Already have an account?',
              action: 'Log in',
              onTap: () => context.go(AppPaths.login),
            ),
          ],
        ),
      ),
    );
  }
}

/// Country picker with flags; type to filter the list. Optional.
class _CountryField extends StatelessWidget {
  const _CountryField({required this.onSelected});

  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<String>(
      expandedInsets: EdgeInsets.zero,
      enableFilter: true,
      requestFocusOnTap: true,
      menuHeight: 320,
      hintText: 'Select your country',
      onSelected: onSelected,
      dropdownMenuEntries: [
        for (final country in countries)
          DropdownMenuEntry(
            value: country.name,
            label: country.name,
            leadingIcon: Text(flagOf(country.code), style: const TextStyle(fontSize: 20)),
          ),
      ],
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({required this.agreed, required this.showError, required this.onChanged});

  final bool agreed;
  final bool showError;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onChanged(!agreed),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(value: agreed, onChanged: (value) => onChanged(value ?? false)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text.rich(
                    TextSpan(
                      style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                      children: const [
                        TextSpan(text: 'Yes, I understand and agree to the '),
                        TextSpan(text: 'Workify Terms of Service', style: TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showError)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 2),
            child: Text(
              'Please accept the terms to create your account',
              style: theme.textTheme.bodySmall?.copyWith(color: colors.error),
            ),
          ),
      ],
    );
  }
}
