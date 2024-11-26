import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:alphanessone/utils/debug_logger.dart';

class StripeCheckoutWidget extends StatefulWidget {
  final String clientSecret;
  final double amount;
  final String currency;
  final Function(String) onPaymentSuccess;
  final Function(String) onPaymentError;

  const StripeCheckoutWidget({
    super.key,
    required this.clientSecret,
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
  bool _isCardComplete = false;
  PaymentMethod? _selectedPaymentMethod;

  Future<void> _handlePayment() async {
    if (!_isCardComplete && _selectedPaymentMethod == null) {
      widget.onPaymentError('Please complete card details');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // Procedi con il pagamento con carta
      final paymentIntent = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: widget.clientSecret,
        data: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: _selectedPaymentMethod?.billingDetails,
          ),
        ),
      );

      if (paymentIntent.status == PaymentIntentsStatus.Succeeded) {
        widget.onPaymentSuccess(paymentIntent.id);
      } else {
        widget.onPaymentError('Payment failed: ${paymentIntent.status}');
      }
    } catch (e) {
      debugLog('Error processing payment: $e');
      widget.onPaymentError(_getErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is StripeException) {
      switch (error.error.code) {
        case FailureCode.Canceled:
          return 'Payment cancelled';
        case FailureCode.Failed:
          return 'Invalid card details';
        default:
          return error.error.message ?? 'Payment failed';
      }
    }
    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Secure Payment',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Amount: ${(widget.amount).toStringAsFixed(2)} ${widget.currency.toUpperCase()}',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CardField(
              onCardChanged: (card) {
                setState(() {
                  _isCardComplete = card?.complete ?? false;
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                labelText: 'Card Details',
                helperText: 'Enter your card details',
                hintText: 'XXXX XXXX XXXX XXXX',
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              enablePostalCode: true,
              autofocus: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _handlePayment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Pay Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Secure payment powered by Stripe',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 