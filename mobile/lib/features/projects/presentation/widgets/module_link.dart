import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Opens a page of another module, or says it's not there yet.
///
/// Each module is built on its own branch, so until they're merged a link to
/// another module (e.g. module 3's contract page) may have no route.
void openModuleLink(BuildContext context, String location, {required String comingSoon}) {
  final router = GoRouter.of(context);
  if (router.configuration.findMatch(Uri.parse(location)).isError) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(comingSoon)));
    return;
  }
  context.push(location);
}
