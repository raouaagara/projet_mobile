import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a link in the browser / external app, with a message if it fails.
Future<void> openExternalUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url.startsWith('http') ? url : 'https://$url');
  final opened = uri != null && await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Could not open $url')));
  }
}
