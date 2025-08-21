import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:alphanessone/UI/legal/privacy_policy_link.dart';
import 'auth_service.dart';
import 'auth_buttons.dart';
import 'form_fields.dart';
import 'package:alphanessone/UI/components/button.dart';

class AuthForm extends HookConsumerWidget {
  const AuthForm({super.key, required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isLogin = useState(true);
    final userEmail = useState('');
    final userPassword = useState('');
    final userName = useState('');
    final userGender = useState('');
    final privacyConsentAccepted = useState(false);
    final theme = Theme.of(context);

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title Section
          Center(
            child: Text(
              isLogin.value ? 'Ben tornato' : 'Crea account',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isLogin.value
                ? 'Accedi per continuare il tuo percorso'
                : 'Unisciti e inizia la tua trasformazione',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),

          // Social Sign In
          Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.surface, theme.colorScheme.surface.withAlpha(26)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outline.withAlpha(26)),
            ),
            child: const GoogleSignInButtonWrapper(),
          ),
          const SizedBox(height: 24),

          // Divider
          Row(
            children: [
              Expanded(child: Divider(color: theme.colorScheme.outline.withAlpha(26))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'oppure continua con',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(child: Divider(color: theme.colorScheme.outline.withAlpha(26))),
            ],
          ),
          const SizedBox(height: 24),

          // Form Fields
          EmailField(userEmail: userEmail),
          const SizedBox(height: 16),
          PasswordField(userPassword: userPassword),

          // Registration Fields
          if (!isLogin.value) ...[
            const SizedBox(height: 16),
            UsernameField(userName: userName),
            const SizedBox(height: 16),
            GenderField(userGender: userGender),
            const SizedBox(height: 20),

            // Privacy Consent Checkbox - OBBLIGATORIO per registrazione
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: theme.colorScheme.surfaceContainerHighest.a * 0.3,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: privacyConsentAccepted.value
                      ? theme.colorScheme.primary.withValues(
                          alpha: theme.colorScheme.primary.a * 0.5,
                        )
                      : theme.colorScheme.outline.withValues(
                          alpha: theme.colorScheme.outline.a * 0.3,
                        ),
                  width: privacyConsentAccepted.value ? 2 : 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.scale(
                    scale: 1.1,
                    child: Checkbox(
                      value: privacyConsentAccepted.value,
                      onChanged: (value) {
                        privacyConsentAccepted.value = value ?? false;
                      },
                      activeColor: theme.colorScheme.primary,
                      checkColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Consenso Privacy Policy',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Accetto il trattamento dei miei dati personali secondo la ',
                              ),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const TextSpan(
                                text:
                                    ' e i Termini di Servizio. Questo consenso è obbligatorio per la registrazione.',
                              ),
                            ],
                          ),
                        ),
                        if (!privacyConsentAccepted.value) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer.withValues(
                                alpha: theme.colorScheme.errorContainer.a * 0.3,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 14,
                                  color: theme.colorScheme.error,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Consenso obbligatorio',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.error,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Submit Button
          SubmitButton(
            formKey: formKey,
            isLogin: isLogin,
            authService: authService,
            userEmail: userEmail,
            userPassword: userPassword,
            userName: userName,
            userGender: userGender,
            privacyConsentAccepted: privacyConsentAccepted,
          ),

          const SizedBox(height: 16),

          // Toggle Auth Mode
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isLogin.value ? 'Non sei registrato? ' : 'Hai già un account? ',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              AppButton(
                label: isLogin.value ? 'Registrati' : 'Accedi',
                onPressed: () => isLogin.value = !isLogin.value,
                variant: AppButtonVariant.subtle,
              ),
            ],
          ),

          if (isLogin.value) ...[
            AppButton(
              onPressed: () async {
                final email = userEmail.value.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Inserisci l\'email per reimpostare la password')),
                  );
                  return;
                }
                try {
                  await authService.sendPasswordResetEmail(email);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Email di reimpostazione inviata')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Errore: ${e.toString()}')));
                  }
                }
              },
              label: 'Password dimenticata?',
              variant: AppButtonVariant.subtle,
            ),
          ],

          // Privacy Policy Link - Prominente e ben visibile
          const SizedBox(height: 24),
          const PrivacyPolicyLink(),

          // Informazioni GDPR per tutti gli utenti
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: theme.colorScheme.surfaceContainerHighest.a * 0.2,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(
                  alpha: theme.colorScheme.outline.a * 0.2,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.security, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isLogin.value
                        ? 'I tuoi dati sono protetti secondo il GDPR. Consulta la Privacy Policy per maggiori dettagli.'
                        : 'Proteggiamo i tuoi dati secondo il GDPR. Il consenso è necessario per procedere.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
