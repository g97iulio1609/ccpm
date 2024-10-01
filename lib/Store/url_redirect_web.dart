// lib/Store/url_redirect_web.dart
import 'dart:html' as html;

Future<void> redirectToUrl(Uri url) async {
  html.window.location.href = url.toString();
}
