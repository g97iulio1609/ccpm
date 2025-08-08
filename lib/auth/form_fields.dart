import 'package:flutter/material.dart';

class _BaseFormField extends StatelessWidget {
  final String label;
  final Widget child;

  const _BaseFormField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class EmailField extends StatelessWidget {
  const EmailField({super.key, required this.userEmail});
  final ValueNotifier<String> userEmail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _BaseFormField(
      label: 'Email',
      child: TextFormField(
        key: const ValueKey('email'),
        validator: (value) =>
            (value == null || value.isEmpty || !value.contains('@'))
            ? 'Please enter a valid email address'
            : null,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.email],
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(77),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withAlpha(51),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          hintText: 'Enter your email',
          hintStyle: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
          ),
          helperText: 'We will never share your email',
          helperStyle: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        onSaved: (value) => userEmail.value = value ?? '',
      ),
    );
  }
}

class PasswordField extends StatelessWidget {
  const PasswordField({super.key, required this.userPassword});
  final ValueNotifier<String> userPassword;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showPassword = ValueNotifier(false);

    return _BaseFormField(
      label: 'Password',
      child: ValueListenableBuilder<bool>(
        valueListenable: showPassword,
        builder: (context, isVisible, _) {
          return TextFormField(
            key: const ValueKey('password'),
            obscureText: !isVisible,
            validator: (value) =>
                (value == null || value.isEmpty || value.length < 7)
                ? 'Password must be at least 7 characters long'
                : null,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(
                77,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withAlpha(51),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.error,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              hintText: 'Enter your password',
              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
              ),
              helperText: 'At least 7 characters',
              helperStyle: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility_off : Icons.visibility,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: () => showPassword.value = !isVisible,
              ),
            ),
            onSaved: (value) => userPassword.value = value ?? '',
          );
        },
      ),
    );
  }
}

class UsernameField extends StatelessWidget {
  const UsernameField({super.key, required this.userName});
  final ValueNotifier<String> userName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _BaseFormField(
      label: 'Username',
      child: TextFormField(
        key: const ValueKey('username'),
        validator: (value) =>
            (value == null || value.isEmpty || value.length < 4)
            ? 'Please enter at least 4 characters'
            : null,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.username],
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(77),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withAlpha(51),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          hintText: 'Choose a username',
          hintStyle: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
          ),
          helperText: 'This will be visible to others',
          helperStyle: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        onSaved: (value) => userName.value = value ?? '',
      ),
    );
  }
}

class GenderField extends StatelessWidget {
  const GenderField({super.key, required this.userGender});
  final ValueNotifier<String> userGender;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _BaseFormField(
      label: 'Gender',
      child: DropdownButtonFormField<String>(
        key: const ValueKey('gender'),
        value: userGender.value.isEmpty ? null : userGender.value,
        items: const [
          DropdownMenuItem(value: 'Male', child: Text('Male')),
          DropdownMenuItem(value: 'Female', child: Text('Female')),
          DropdownMenuItem(value: 'Other', child: Text('Other')),
        ],
        onChanged: (value) => userGender.value = value ?? '',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(77),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withAlpha(51),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          hintText: 'Select your gender',
          hintStyle: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
          ),
        ),
        icon: Icon(
          Icons.arrow_drop_down,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        dropdownColor: theme.colorScheme.surface,
      ),
    );
  }
}
