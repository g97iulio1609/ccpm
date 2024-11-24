// lib/Store/url_redirect_web.dart
import 'dart:html' as html;
import 'package:js/js.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

@JS('Stripe')
external dynamic StripeConstructor(String key, [dynamic options]);

Future<void> redirectToUrl(Uri url) async {
  // Non facciamo più il redirect, questa funzione verrà deprecata
  throw UnimplementedError('Usa StripeCheckout invece del redirect');
}

class StripeCheckout {
  static late dynamic stripeJs;
  static late Stripe stripeInstance;

  static Future<void> initStripe() async {
    final publishableKey = 'pk_live_51Lk8noGIoD20nGKnKB5igqB4Kpry8VQpYgWwm0t5dJWTCOX4pQXdg9N24dM1fSgZP3oVoYPTZj4SGYIp9aT05Mrr00a4XOvZg6';
    
    stripeJs = StripeConstructor(publishableKey, {
      'betas': ['elements_enable_deferred_intent'],
    });

    Stripe.publishableKey = publishableKey;
    stripeInstance = Stripe.instance;
    await stripeInstance.applySettings();
  }
}
