import 'package:catchopp_mobile/features/community/data/models/community_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  group('models', () {
    test('feed item and Post entity give the same counts and my reaction', () {
      final fromFeed = FeedPost.fromFeedJson(const {
        'id': 1,
        'content': 'Riverpod 3?',
        'authorId': 2,
        'isAnnouncement': false,
        'createdAt': '2026-09-26T23:12:53',
        'groupId': 1,
        'groupName': 'Flutter devs',
        'clubId': null,
        'clubName': null,
        'reactionCounts': {'LOVE': 1, 'LIKE': 1, 'SAD': 0},
        'totalReactions': 2,
        'commentsCount': 1,
        'userReaction': 'LOVE',
      });
      final fromPost = FeedPost.fromPostJson(const {
        'id': 1,
        'content': 'Riverpod 3?',
        'authorId': 2,
        'isAnnouncement': false,
        'createdAt': '2026-09-26T23:12:53',
        'group': {'id': 1, 'name': 'Flutter devs', 'type': 'PUBLIC'},
        'club': null,
        'comments': [
          {'id': 1, 'authorId': 1, 'content': 'Riverpod too', 'createdAt': '2026-09-26T23:12:53'},
        ],
        'reactions': [
          {'id': 1, 'authorId': 7, 'type': 'LOVE'},
          {'id': 2, 'authorId': 2, 'type': 'LIKE'},
        ],
      }, userId: 7);
      for (final post in [fromFeed, fromPost]) {
        expect(post.reactionCounts, {ReactionKind.love: 1, ReactionKind.like: 1});
        expect(post.totalReactions, 2);
        expect(post.commentsCount, 1);
        expect(post.userReaction, ReactionKind.love);
        expect(post.placeName, 'Flutter devs');
      }
    });

    test('switching and removing a reaction', () {
      const post = FeedPost(
        id: 1,
        content: 'x',
        reactionCounts: {ReactionKind.love: 1, ReactionKind.like: 1},
        userReaction: ReactionKind.love,
      );
      final switched = post.withReaction(ReactionKind.wow);
      expect(switched.reactionCounts, {ReactionKind.like: 1, ReactionKind.wow: 1});
      expect(switched.userReaction, ReactionKind.wow);
      final removed = switched.withReaction(null);
      expect(removed.reactionCounts, {ReactionKind.like: 1});
      expect(removed.userReaction, isNull);
      expect(post.withCommentsCount(4).commentsCount, 4);
    });

    test('event, club and membership', () {
      final event = CommunityEvent.fromJson(const {
        'id': 1,
        'title': 'Flutter meetup',
        'location': 'ESPRIT',
        'startDate': '2026-10-10T18:00:00',
        'endDate': '2026-10-10T21:00:00',
        'group': {'id': 1, 'name': 'Flutter devs', 'type': 'PUBLIC'},
        'club': null,
        'creatorId': 2,
        'status': 'PENDING',
      });
      expect(event.status, EventStatus.pending);
      expect(event.hostName, 'Flutter devs');
      expect(event.isPast(DateTime(2026, 10, 11)), isTrue);
      expect(event.isPast(DateTime(2026, 10, 1)), isFalse);

      final club = Club.fromJson(const {
        'id': 1,
        'name': 'UI/UX Design Club',
        'interests': 'design, figma,ux',
        'creatorId': 2,
        'status': 'PAUSED',
      });
      expect(club.interests, ['design', 'figma', 'ux']);
      expect(club.isPaused, isTrue);

      final membership = GroupMembership.fromJson(const {
        'id': 2,
        'group': {'id': 1, 'name': 'Flutter devs', 'type': 'PUBLIC'},
        'userId': 2,
        'role': 'ADMIN',
        'joinedAt': '2026-09-26T23:12:52',
      });
      expect(membership.role, MemberRole.admin);
      expect(membership.group!.isPublic, isTrue);
    });
  });

  testWidgets('groups: mine first, then the ones to discover', (tester) async {
    final repository = FakeCommunityRepository(
      memberships: [const GroupMembership(id: 1, userId: me, group: flutterGroup, role: MemberRole.admin)],
    );
    await pumpCommunityApp(tester, repository: repository);

    expect(find.text('My groups'), findsOneWidget);
    expect(find.textContaining('Admin'), findsOneWidget);
    expect(find.text('Discover'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget); // the private group
  });

  testWidgets('join a public group, post, react (shown at once) and comment', (tester) async {
    final repository = FakeCommunityRepository();
    await pumpCommunityApp(tester, repository: repository, location: '/community/groups/1');

    expect(find.text('Join the group to post and comment.'), findsOneWidget);
    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();
    expect(repository.memberships.single.group!.id, 1);

    await tester.enterText(find.byType(TextField), 'Anyone tried Riverpod 3?');
    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();
    expect(find.text('Anyone tried Riverpod 3?'), findsOneWidget);

    await tester.ensureVisible(find.text('React')); // below the group card and the new post
    await tester.pumpAndSettle();
    await tester.tap(find.text('React'));
    await tester.pumpAndSettle();
    expect(find.text('👍 1'), findsOneWidget);
    expect(repository.reactions[(1, me)], ReactionKind.like);
    await tester.tap(find.text('Reacted')); // tapping again removes it
    await tester.pumpAndSettle();
    expect(repository.reactions, isEmpty);

    await tester.tap(find.text('Anyone tried Riverpod 3?'));
    await tester.pumpAndSettle();
    // The "Welcome" snackbar from joining covers the comment bar for a few seconds.
    tester.state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger)).hideCurrentSnackBar();
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Write a comment'), 'Yes, with go_router 17');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(find.text('Yes, with go_router 17'), findsOneWidget);
    expect(find.text('1 comment'), findsOneWidget);
  });

  testWidgets('AI: groups and events picked for me from my skills', (tester) async {
    final repository = FakeCommunityRepository();
    await pumpCommunityApp(tester, repository: repository);

    expect(find.text('Picked for you'), findsOneWidget);
    await tester.tap(find.text('Show me'));
    await tester.pumpAndSettle();
    expect(repository.recommendedFor, ['Flutter']); // my skills' names
    expect(find.text('Flutter meetup Tunis'), findsOneWidget);
    expect(find.text('Event. Meet other mobile developers.'), findsOneWidget);
  });

  testWidgets('AI: write the post from a few words; a scam is refused with the reason', (tester) async {
    final repository = FakeCommunityRepository(
      memberships: [const GroupMembership(id: 1, userId: me, group: flutterGroup, role: MemberRole.member)],
    );
    await pumpCommunityApp(tester, repository: repository, location: '/community/groups/1');

    await tester.enterText(find.byType(TextField), 'riverpod 3 tips?');
    await tester.tap(find.text('Write with AI'));
    await tester.pumpAndSettle();
    expect(repository.draftWhere, 'Flutter devs');
    expect(find.text('Hi everyone! Has anyone tried Riverpod 3 in a real app? I would love your tips.'), findsOneWidget);

    tester.state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger)).hideCurrentSnackBar();
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Send me crypto and I double it in 24h');
    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();
    expect(find.text('Keep payments on Workify: they are protected by escrow.'), findsOneWidget);
    expect(repository.posts.where((p) => p.content.contains('crypto')), isEmpty);
  });

  testWidgets('a private group stays closed to non-members', (tester) async {
    await pumpCommunityApp(tester, repository: FakeCommunityRepository(), location: '/community/groups/3');

    expect(find.textContaining('This group is private'), findsOneWidget);
    expect(find.text('Join'), findsNothing);
  });

  testWidgets('events: approved upcoming ones, and mine waiting for approval', (tester) async {
    final soon = DateTime.now().add(const Duration(days: 5));
    final repository = FakeCommunityRepository(
      events: [
        CommunityEvent(
          id: 1,
          title: 'Flutter meetup',
          startDate: soon,
          status: EventStatus.approved,
          group: flutterGroup,
          creatorId: 2,
        ),
        CommunityEvent(
          id: 2,
          title: 'My workshop',
          startDate: soon,
          status: EventStatus.pending,
          group: flutterGroup,
          creatorId: me,
        ),
        CommunityEvent(
          id: 3,
          title: 'Someone else pending',
          startDate: soon,
          status: EventStatus.pending,
          creatorId: 2,
        ),
        CommunityEvent(
          id: 4,
          title: 'Last year',
          startDate: DateTime(2025, 1, 1),
          status: EventStatus.approved,
          creatorId: 2,
        ),
      ],
    );
    await pumpCommunityApp(tester, repository: repository);
    await tester.tap(find.text('Events'));
    await tester.pumpAndSettle();

    expect(find.text('Flutter meetup'), findsOneWidget);
    expect(find.text('My events waiting for approval'), findsOneWidget);
    expect(find.text('My workshop'), findsOneWidget);
    expect(find.text('Someone else pending'), findsNothing);
    expect(find.text('Last year'), findsNothing);

    await tester.tap(find.text('My workshop'));
    await tester.pumpAndSettle();
    expect(find.text('Waiting for approval'), findsOneWidget);
  });

  testWidgets('clubs: search by interest; only the creator posts', (tester) async {
    final repository = FakeCommunityRepository(
      clubs: const [
        Club(id: 1, name: 'UI/UX Design Club', interestsText: 'design,figma', creatorId: me),
        Club(id: 2, name: 'Data club', interestsText: 'python,ml', creatorId: 2),
        Club(id: 3, name: 'Paused club', interestsText: 'misc', creatorId: 2, status: 'PAUSED'),
      ],
    );
    await pumpCommunityApp(tester, repository: repository);
    await tester.tap(find.text('Clubs'));
    await tester.pumpAndSettle();

    expect(find.text('Paused club'), findsNothing); // someone else's paused club
    await tester.tap(find.text('figma'));
    await tester.pumpAndSettle();
    expect(find.text('UI/UX Design Club'), findsOneWidget);
    expect(find.text('Data club'), findsNothing);

    await tester.tap(find.text('UI/UX Design Club'));
    await tester.pumpAndSettle();
    expect(find.text('You run this club'), findsOneWidget);
    expect(find.text('Share news with the club…'), findsOneWidget);
  });

  testWidgets('new event: says what is missing', (tester) async {
    await pumpCommunityApp(tester, repository: FakeCommunityRepository(), location: '/community/events/new');

    expect(find.text('Join a group or create a club first.'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'e.g. Flutter meetup'), 'Meetup');
    await tester.enterText(find.widgetWithText(TextFormField, 'e.g. ESPRIT, Ariana — or a Meet link'), 'ESPRIT');
    await tester.ensureVisible(find.text('Create the event'));
    await tester.tap(find.text('Create the event'));
    await tester.pumpAndSettle();
    expect(find.text('Pick the group or club hosting it'), findsOneWidget);
  });
}
