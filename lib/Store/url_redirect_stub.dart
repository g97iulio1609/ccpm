// lib/Store/url_redirect_stub.dart
import 'package:url_launcher/url_launcher.dart';

Future<void> redirectToUrl(Uri url) async {
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    throw Exception('Could not launch $url');
  }
}
