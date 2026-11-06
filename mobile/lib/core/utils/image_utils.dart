import 'dart:convert';

import 'package:flutter/widgets.dart';

/// The backend stores images (avatars, covers, project images, signatures)
/// either as base64 strings / data URIs or as http URLs.
/// This returns the right [ImageProvider] for both, or null.
ImageProvider? imageFromApi(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return NetworkImage(value);
  }
  final data = value.contains(',') ? value.substring(value.indexOf(',') + 1) : value;
  try {
    return MemoryImage(base64Decode(data));
  } on FormatException {
    return null;
  }
}

/// Encodes raw bytes as a data URI, the format the web app sends.
String toDataUri(List<int> bytes, {String mimeType = 'image/png'}) =>
    'data:$mimeType;base64,${base64Encode(bytes)}';
