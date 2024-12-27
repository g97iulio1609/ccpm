// lib/Store/in_app_purchase.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:alphanessone/Store/in_app_purchase_web.dart';
import 'package:alphanessone/Store/in_app_purchase_mobile.dart';

class InAppPurchaseScreen extends StatelessWidget {
  const InAppPurchaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: kIsWeb
          ? const InAppPurchaseScreenWeb()
          : const InAppPurchaseScreenMobile(),
    );
  }
}
