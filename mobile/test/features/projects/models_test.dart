import 'package:catchopp_mobile/features/projects/data/models/project.dart';
import 'package:catchopp_mobile/features/projects/data/models/project_enums.dart';
import 'package:catchopp_mobile/features/projects/data/models/project_notification.dart';
import 'package:catchopp_mobile/features/projects/data/models/proposal.dart';
import 'package:catchopp_mobile/features/projects/presentation/format.dart';
import 'package:catchopp_mobile/features/projects/presentation/project_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  // Copied from GET /Project/1 on the real backend.
  const projectJson = {
    'id': 1,
    'title': 'Flutter app for a restaurant',
    'description': 'We need an Android app.',
    'image': null,
    'ExperienceLevel': 'Intermediate',
    'budget': 1200.0,
    'postedAt': '2026-09-26',
    'status': 'OPEN',
    'category': 'MOBILE_DEVELOPMENT',
    'jobType': 'FIXED_PRICE',
    'clientId': 2,
    'likes': 1,
    'loves': 3,
    'hahas': 0,
    'supports': 0,
    'requiredCompetenceIds': [1, 2],
  };

  group('Project', () {
    test('reads the backend JSON', () {
      final p = Project.fromJson(projectJson);
      expect(p.id, 1);
      expect(p.experienceLevel, 'Intermediate');
      expect(p.budget, 1200);
      expect(p.postedAt, DateTime(2026, 9, 26));
      expect(p.status, ProjectStatus.open);
      expect(p.category, ProjectCategory.mobileDevelopment);
      expect(p.jobType, JobType.fixedPrice);
      expect(p.totalReactions, 4);
      expect(p.reactions(ProjectReaction.love), 3);
      expect(p.requiredCompetenceIds, [1, 2]);
      expect(p.budgetLabel, r'$1,200');
    });

    test('tolerates missing and unknown values', () {
      final p = Project.fromJson(const {'id': 3, 'status': 'ARCHIVED', 'category': 'SPACE', 'jobType': 'X'});
      expect(p.title, '');
      expect(p.budget, 0);
      expect(p.status, ProjectStatus.unknown);
      expect(p.category, ProjectCategory.other);
      expect(p.jobType, isNull);
      expect(p.requiredCompetenceIds, isEmpty);
      expect(p.imageProvider, isNull);
    });

    test('writes what the backend expects', () {
      final json = Project.fromJson(projectJson).toJson();
      expect(json['ExperienceLevel'], 'Intermediate'); // capital E, or the backend ignores it
      expect(json['postedAt'], '2026-09-26');
      expect(json['status'], 'OPEN');
      expect(json['category'], 'MOBILE_DEVELOPMENT');
      expect(json['jobType'], 'FIXED_PRICE');
      expect(json.containsKey('likes'), isFalse); // counters are server-side
      expect(json.containsKey('image'), isFalse); // no nulls
    });

    test('hourly budgets show per hour', () {
      expect(project(1, budget: 35, jobType: JobType.hourly).budgetLabel, r'$35/h');
    });
  });

  test('Proposal reads the embedded project and writes a LocalDate', () {
    final proposal = Proposal.fromJson({
      'id': 1,
      'bidAmount': 1100.0,
      'estimationEndDate': '2026-10-30',
      'status': 'ACCEPTED',
      'freelancerId': 7,
      'project': projectJson,
    });
    expect(proposal.status, ProposalStatus.accepted);
    expect(proposal.project!.title, 'Flutter app for a restaurant');
    expect(proposal.estimationEndDate, DateTime(2026, 10, 30));

    final json = Proposal(bidAmount: 900, estimationEndDate: DateTime(2026, 11, 2), freelancerId: 7).toJson();
    expect(json, {'bidAmount': 900.0, 'estimationEndDate': '2026-11-02', 'status': 'PENDING', 'freelancerId': 7});
  });

  test('Notification reads "read" (Jackson) and "isRead"', () {
    final a = ProjectNotification.fromJson(const {
      'id': 1,
      'message': 'A new proposal',
      'createdAt': '2026-09-26T13:11:07',
      'projectId': 1,
      'read': true,
    });
    expect(a.read, isTrue);
    expect(a.createdAt, DateTime(2026, 9, 26, 13, 11, 7));
    expect(ProjectNotification.fromJson(const {'id': 2, 'isRead': true}).read, isTrue);
    expect(ProjectNotification.fromJson(const {'id': 3}).read, isFalse);
  });

  group('FeedFilter', () {
    final projects = [
      project(1, title: 'Flutter app', budget: 1200, category: ProjectCategory.mobileDevelopment),
      project(2, title: 'Logo', budget: 150, category: ProjectCategory.uiUxDesign, experience: ExperienceLevel.entry),
      project(3, title: 'Closed job', status: ProjectStatus.closed),
      project(4, title: 'Angular site', budget: 700, jobType: JobType.hourly),
    ];
    List<int?> ids(FeedFilter f) => f.apply(projects).map((p) => p.id).toList();

    test('shows open projects, newest first', () => expect(ids(const FeedFilter()), [4, 2, 1]));
    test('searches title and description', () {
      expect(ids(const FeedFilter(query: 'flutter')), [1]);
      expect(ids(const FeedFilter(query: 'DESCRIPTION of logo')), [2]);
    });
    test('filters', () {
      expect(ids(const FeedFilter(category: ProjectCategory.uiUxDesign)), [2]);
      expect(ids(const FeedFilter(jobType: JobType.hourly)), [4]);
      expect(ids(const FeedFilter(experience: ExperienceLevel.entry)), [2]);
      expect(ids(const FeedFilter(budget: BudgetRange.under500)), [2]);
      expect(ids(const FeedFilter(budget: BudgetRange.from500To1000)), [4]);
      expect(ids(const FeedFilter(budget: BudgetRange.over1000)), [1]);
      expect(const FeedFilter(budget: BudgetRange.over1000, jobType: JobType.hourly).activeCount, 2);
    });
    test('sorts', () {
      expect(ids(const FeedFilter(sort: FeedSort.oldest)), [1, 2, 4]);
      expect(ids(const FeedFilter(sort: FeedSort.highestBudget)), [1, 4, 2]);
      expect(ids(const FeedFilter(sort: FeedSort.lowestBudget)), [2, 4, 1]);
    });
  });

  test('postedLabel', () {
    final now = DateTime(2026, 9, 26, 18);
    expect(postedLabel(DateTime(2026, 9, 26), now: now), 'Posted today');
    expect(postedLabel(DateTime(2026, 9, 25), now: now), 'Posted yesterday');
    expect(postedLabel(DateTime(2026, 9, 20), now: now), 'Posted 6 days ago');
    expect(postedLabel(DateTime(2026, 5, 2), now: now), 'Posted May 2, 2026');
    expect(postedLabel(null, now: now), '');
  });
}
