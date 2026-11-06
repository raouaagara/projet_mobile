import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/auth_controller.dart';
import 'client_projects_screen.dart';
import 'freelancer_home_screen.dart';

/// First tab: "My projects" for clients, "Find work" for freelancers.
class ProjectsHomeScreen extends ConsumerWidget {
  const ProjectsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isClient = ref.watch(authControllerProvider).value?.isClient ?? false;
    return isClient ? const ClientProjectsScreen() : const FreelancerHomeScreen();
  }
}
