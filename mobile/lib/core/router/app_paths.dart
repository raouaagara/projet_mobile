/// Entry-point URLs of every module — the contract between the 6 modules.
///
/// Use these to navigate to another person's module:
///   context.push(AppPaths.wallet);
/// Sub-pages (details, forms...) are declared by each module in its own
/// `<module>_routes.dart`, under its entry path (e.g. `/projects/:id`).
///
/// Only change this file through a pull request to `main`.
abstract final class AppPaths {
  // ── Auth (foundation) ───────────────────────────────────────────
  static const splash = '/splash';
  static const onboarding = '/welcome'; // the 3 intro pages, first launch only
  static const login = '/login';
  static const register = '/register';

  // ── Bottom navigation tabs ──────────────────────────────────────
  static const projects = '/projects'; // Module 2 – Projects & Proposals
  static const contracts = '/contracts'; // Module 3 – Contracts & Payments
  static const messages = '/messages'; // Module 4 – Messaging & Support
  static const community = '/community'; // Module 6 – Community
  static const menu = '/menu'; // foundation

  // ── Full-screen entry points (opened from the menu) ─────────────
  static const profile = '/profile'; // Module 1
  static const skillTests = '/skill-tests'; // Module 1 (freelancer)
  static const wallet = '/wallet'; // Module 3
  static const support = '/support'; // Module 4
  static const availability = '/availability'; // Module 4 (freelancer)
  static const worldClock = '/world-clock'; // Module 4 (client)
  static const subscriptions = '/subscriptions'; // Module 5 (freelancer)
  static const rewards = '/rewards'; // Module 5 (freelancer)
  static const referral = '/referral'; // Module 5 (freelancer)

  /// Only freelancers may open these (and their sub-pages).
  static const freelancerOnly = [skillTests, availability, subscriptions, rewards, referral];

  /// Only clients may open these (and their sub-pages).
  static const clientOnly = [worldClock];
}
