import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:alphanessone/Store/payment_success_screen.dart';
import 'package:alphanessone/Store/payment_failure_screen.dart';
import 'package:alphanessone/UI/components/button.dart';

class StripeCheckoutWidget extends StatefulWidget {
  final String clientSecret;
  final String sessionId;
  final double amount;
  final String currency;
  final Function(String) onPaymentSuccess;
  final Function(String) onPaymentError;

  const StripeCheckoutWidget({
    super.key,
    required this.clientSecret,
    required this.sessionId,
    required this.amount,
    required this.currency,
    required this.onPaymentSuccess,
    required this.onPaymentError,
  });

  @override
  State<StripeCheckoutWidget> createState() => _StripeCheckoutWidgetState();
}

class _StripeCheckoutWidgetState extends State<StripeCheckoutWidget> {
  bool _isLoading = false;
  String? _error;
  bool _isCardComplete = false;

  Future<void> _handlePayment() async {
    if (!_isCardComplete) {
      setState(() => _error = 'Completa i dettagli della carta');
      return;
    }

    try {
      setState(() => _isLoading = true);

      final paymentIntent = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: widget.clientSecret,
        data: PaymentMethodParams.card(paymentMethodData: PaymentMethodData()),
      );

      if (paymentIntent.status == PaymentIntentsStatus.Succeeded) {
        widget.onPaymentSuccess(widget.sessionId);
        if (mounted) {
          Navigator.of(
            context,
          ).pushReplacement(MaterialPageRoute(builder: (_) => const PaymentSuccessScreen()));
        }
      } else {
        throw Exception('Pagamento fallito: ${paymentIntent.status}');
      }
    } catch (e) {
      setState(() => _error = e.toString());
      widget.onPaymentError(e.toString());
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => PaymentFailureScreen(error: e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: SingleChildScrollView(
          controller: scrollController,
          physics: const ClampingScrollPhysics(),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Pagamento Sicuro',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Importo: ${(widget.amount).toStringAsFixed(2)} ${widget.currency.toUpperCase()}',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                CardField(
                  onCardChanged: (card) {
                    setState(() {
                      _isCardComplete = card?.complete ?? false;
                    });
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    labelText: 'Dettagli Carta',
                    helperText: 'Inserisci i dettagli della tua carta',
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Paga Ora',
                  onPressed: _isLoading ? null : _handlePayment,
                  isLoading: _isLoading,
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.lg,
                  block: true,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text('Pagamento sicuro con Stripe', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
