# CatchOPP mobile (Flutter · Android)

App for **clients** and **freelancers**. Talks only to the API Gateway.

## Run

```bash
adb reverse tcp:8085 tcp:8085   # USB phone or emulator: its localhost:8085 → your PC's gateway
flutter pub get
flutter run                     # or Run/Debug from VS Code / Android Studio
```
- Redo `adb reverse` every time you plug the phone back in or restart the emulator
  (`adb` is in `%LOCALAPPDATA%\Android\Sdk\platform-tools`).
- It doesn't depend on Wi-Fi or on your PC's IP, so it keeps working on a phone hotspot.
- Another server: `flutter run --dart-define=API_BASE_URL=http://<ip>:8085`.

The backend (at least `eureka`, `apigetway`, `UserMicroService`) must be running to log in.

## Structure

```
lib/
├── main.dart, app.dart
├── core/                      shared foundation (change via PR to main)
│   ├── config/env.dart        API_BASE_URL, socket URLs
│   ├── network/               dioProvider (base URL + JWT header), ApiException
│   ├── storage/               secure token storage
│   ├── router/                AppPaths (module entry points), router + role guards
│   ├── models/                AppUser, UserRole
│   ├── theme/                 light / dark theme
│   └── utils/                 base64 images, Spring date parsing
├── shared/widgets/            AsyncValueView, ErrorView, EmptyView, UserAvatar
└── features/
    ├── auth/                  login, register, session  (foundation)
    ├── shell/                 bottom navigation + menu   (foundation)
    ├── profile/               Module 1
    ├── projects/              Module 2
    ├── contracts/             Module 3
    ├── messaging/             Module 4
    ├── subscriptions/         Module 5
    └── community/             Module 6
```

Who owns which module: [../docs/WORK_SPLIT.md](../docs/WORK_SPLIT.md).

## Recipe: from endpoint to screen

Example for module 2 — list projects.

**1. Model** — `features/projects/data/project.dart`
```dart
import 'package:json_annotation/json_annotation.dart';
import '../../../core/utils/json_utils.dart';

part 'project.g.dart';

@JsonSerializable()
class Project {
  const Project({required this.id, required this.title, this.budget, this.postedAt});

  final int id;
  @JsonKey(defaultValue: '')
  final String title;
  final double? budget;
  @JsonKey(fromJson: parseApiDate)
  final DateTime? postedAt;

  factory Project.fromJson(Map<String, dynamic> json) => _$ProjectFromJson(json);
  Map<String, dynamic> toJson() => _$ProjectToJson(this);
}
```
Then run `dart run build_runner build`.

**2. Repository + provider** — `features/projects/data/projects_repository.dart`
```dart
final projectsRepositoryProvider =
    Provider((ref) => ProjectsRepository(ref.watch(dioProvider)));

final allProjectsProvider = FutureProvider<List<Project>>(
    (ref) => ref.watch(projectsRepositoryProvider).fetchAll());

class ProjectsRepository {
  ProjectsRepository(this._dio);
  final Dio _dio;

  Future<List<Project>> fetchAll() async {
    try {
      final res = await _dio.get<List<dynamic>>('/Project/allprojects');
      return res.data!.map((e) => Project.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}
```

**3. Screen** — `features/projects/presentation/projects_screen.dart`
```dart
class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find work')),
      body: AsyncValueView(
        value: ref.watch(allProjectsProvider),
        onRetry: () => ref.invalidate(allProjectsProvider),
        data: (projects) => projects.isEmpty
            ? const EmptyView(message: 'No projects yet')
            : RefreshIndicator(
                onRefresh: () => ref.refresh(allProjectsProvider.future),
                child: ListView.builder(
                  itemCount: projects.length,
                  itemBuilder: (_, i) => ListTile(
                    title: Text(projects[i].title),
                    onTap: () => context.push('${AppPaths.projects}/${projects[i].id}'),
                  ),
                ),
              ),
      ),
    );
  }
}
```

**4. Route** — in `features/projects/projects_routes.dart`, replace the placeholder with
`builder: (context, state) => const ProjectsScreen()`.

## Checks before a pull request
```bash
flutter analyze
flutter test
```
