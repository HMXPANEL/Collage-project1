import 'package:eco_action/features/community/community_engine.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSource implements CommunityDataSource {
  const _FakeSource(this.peers);

  final List<CommunityMember> peers;

  @override
  Future<List<CommunityMember>> seed() async => peers;
}

void main() {
  test('current user is inserted, ranked, and flagged isYou', () async {
    const source = _FakeSource([
      CommunityMember(
        rank: 1,
        name: 'A',
        college: 'X',
        totalKg: 100,
        totalActions: 10,
        isYou: false,
      ),
      CommunityMember(
        rank: 2,
        name: 'B',
        college: 'X',
        totalKg: 80,
        totalActions: 8,
        isYou: false,
      ),
    ]);

    final snapshot = await computeCommunitySnapshot(
      source: source,
      totalKg: 90,
      totalActions: 9,
    );

    final you = snapshot.currentUser!;
    expect(you.isYou, isTrue);
    expect(you.rank, 2);
    expect(you.totalKg, 90);
    expect(snapshot.members.map((m) => m.rank), [1, 2, 3]);
    expect(snapshot.isDemo, isTrue);
    expect(snapshot.collegeTotalKg, 270);
  });

  test('ties share a rank and leave the next rank open', () async {
    const source = _FakeSource([
      CommunityMember(
        rank: 1,
        name: 'A',
        college: 'X',
        totalKg: 100,
        totalActions: 10,
        isYou: false,
      ),
    ]);

    final snapshot = await computeCommunitySnapshot(
      source: source,
      totalKg: 100,
      totalActions: 9,
    );

    final you = snapshot.currentUser!;
    expect(you.rank, 1, reason: 'ties must share rank 1');
  });

  test('zero activity still renders but you are at the bottom', () async {
    const source = _FakeSource([
      CommunityMember(
        rank: 1,
        name: 'A',
        college: 'X',
        totalKg: 100,
        totalActions: 10,
        isYou: false,
      ),
    ]);

    final snapshot = await computeCommunitySnapshot(
      source: source,
      totalKg: 0,
      totalActions: 0,
    );

    expect(snapshot.currentUser!.rank, 2);
    expect(snapshot.currentUser!.totalActions, 0);
  });
}