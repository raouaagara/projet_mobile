/// How well a freelancer's skills fit a job, scored by the AI service (module 2).
/// Used both ways: a freelancer's score on each job, and each applicant's score on a client's job.
class JobMatch {
  const JobMatch({required this.score, this.matched = const [], this.related = const [], this.missing = const []});

  /// 0–100.
  final int score;

  /// Skills the job needs that the freelancer has.
  final List<String> matched;

  /// Skills the job needs that the freelancer has something close to (same field).
  final List<String> related;

  /// Skills the job needs that the freelancer doesn't have.
  final List<String> missing;

  factory JobMatch.fromJson(Map<String, dynamic> json) => JobMatch(
    score: (json['score'] as num?)?.toInt() ?? 0,
    matched: _strings(json['matched']),
    related: _strings(json['related']),
    missing: _strings(json['missing']),
  );
}

/// A skill the freelancer lacks, and how many open jobs that almost fit them ask for it.
class SkillDemand {
  const SkillDemand(this.name, this.jobs);

  final String name;
  final int jobs;

  Map<String, dynamic> toJson() => {'name': name, 'jobs': jobs};
}

/// A job post written by the AI from the client's few words.
class ProjectDraft {
  const ProjectDraft({required this.title, required this.description, this.experienceLevel, this.skillIds = const []});

  final String title;
  final String description;
  final String? experienceLevel;

  /// Catalog skills the AI found in the post.
  final List<int> skillIds;

  factory ProjectDraft.fromJson(Map<String, dynamic> json) => ProjectDraft(
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    experienceLevel: json['experienceLevel'] as String?,
    skillIds: [for (final id in json['skillIds'] as List<dynamic>? ?? []) (id as num).toInt()],
  );
}

List<String> _strings(Object? value) => [for (final s in value as List<dynamic>? ?? []) s as String];
