/// Demo community leaderboard.
///
/// Ranks the current user against seeded peer profiles. Every surface that
/// renders this data must label it as a demo so nobody mistakes it for a live
/// college leaderboard. Swap [CommunityDataSource.seed] for a networked
/// source when the backend exists.
library;

/// A ranked peer on the demo leaderboard.
class CommunityMember {
  const CommunityMember({
    required this.rank,
    required this.name,
    required this.college,
    required this.totalKg,
    required this.totalActions,
    required this.isYou,
  });

  final int rank;
  final String name;
  final String college;
  final double totalKg;
  final int totalActions;
  final bool isYou;

  CommunityMember copyWith({
    bool? isYou,
    int? rank,
    double? totalKg,
    int? totalActions,
  }) {
    return CommunityMember(
      rank: rank ?? this.rank,
      name: name,
      college: college,
      totalKg: totalKg ?? this.totalKg,
      totalActions: totalActions ?? this.totalActions,
      isYou: isYou ?? this.isYou,
    );
  }
}

/// Snapshot of the demo leaderboard for a given user's stats.
class CommunitySnapshot {
  const CommunitySnapshot({
    required this.members,
    required this.collegeTotalKg,
    required this.isDemo,
  });

  final List<CommunityMember> members;
  final double collegeTotalKg;
  final bool isDemo;

  CommunityMember? get currentUser {
    for (final m in members) {
      if (m.isYou) return m;
    }
    return null;
  }
}

/// Where the demo peer list comes from. [seed] is backed by fixed sample data
/// until a live backend exists.
abstract class CommunityDataSource {
  Future<List<CommunityMember>> seed();
}

/// Fixed sample peers used to simulate the leaderboard. Names are bundled,
/// explicitly fictional demo data.
class DemoCommunityDataSource implements CommunityDataSource {
  const DemoCommunityDataSource();

  @override
  Future<List<CommunityMember>> seed() async => const [
        CommunityMember(
          rank: 1,
          name: 'Aarav K.',
          college: 'IIT Delhi',
          totalKg: 148.2,
          totalActions: 172,
          isYou: false,
        ),
        CommunityMember(
          rank: 2,
          name: 'Sahana M.',
          college: 'BITS Pilani',
          totalKg: 141.9,
          totalActions: 165,
          isYou: false,
        ),
        CommunityMember(
          rank: 3,
          name: 'Rohan J.',
          college: 'NIT Trichy',
          totalKg: 135.4,
          totalActions: 158,
          isYou: false,
        ),
        CommunityMember(
          rank: 4,
          name: 'Meera S.',
          college: 'VIT Vellore',
          totalKg: 129.7,
          totalActions: 149,
          isYou: false,
        ),
        CommunityMember(
          rank: 5,
          name: 'Devansh R.',
          college: 'Anna University',
          totalKg: 118.0,
          totalActions: 140,
          isYou: false,
        ),
      ];
}

/// Builds the demo leaderboard from the user's real stats plus seeded peers.
///
/// The current user is inserted by [totalKg]/[totalActions], re-ranked, and
/// flagged `isYou` so the UI can highlight them. Returns [isDemo]=true to
/// force honest labelling.
Future<CommunitySnapshot> computeCommunitySnapshot({
  required CommunityDataSource source,
  required double totalKg,
  required int totalActions,
}) async {
  final peers = await source.seed();
  final all = <CommunityMember>[
    ...peers,
    const CommunityMember(
      rank: 0,
      name: 'You',
      college: '',
      totalKg: 0,
      totalActions: 0,
      isYou: true,
    ).copyWith(totalKg: totalKg, totalActions: totalActions, isYou: true),
  ]..sort((a, b) => b.totalKg.compareTo(a.totalKg));

  var rank = 0;
  var lastKg = -1.0;
  final ranked = <CommunityMember>[];
  for (final m in all) {
    if (m.totalKg != lastKg) rank++;
    lastKg = m.totalKg;
    ranked.add(m.copyWith(rank: rank));
  }

  final collegeTotalKg = ranked.fold<double>(0, (sum, m) => sum + m.totalKg);
  return CommunitySnapshot(
    members: ranked,
    collegeTotalKg: collegeTotalKg,
    isDemo: true,
  );
}