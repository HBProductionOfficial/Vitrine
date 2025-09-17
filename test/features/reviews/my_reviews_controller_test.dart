import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitrine/src/core/storage/preferences.dart';
import 'package:vitrine/src/features/auth/presentation/auth_controller.dart';
import 'package:vitrine/src/features/reviews/my_reviews_controller.dart';

void main() {
  late SharedPreferences prefs;

  ProviderContainer containerFor(int? userId) => ProviderContainer.test(
    overrides: [preferencesProvider.overrideWithValue(prefs), currentUserIdProvider.overrideWithValue(userId)],
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('a saved review survives a restart', () {
    containerFor(1).read(myReviewsProvider.notifier).save(5, rating: 4, comment: '  No clumps.  ', reviewer: 'Emily');

    final review = containerFor(1).read(myReviewsProvider)[5]!;
    expect(review.rating, 4);
    expect(review.comment, 'No clumps.');
    expect(review.reviewer, 'Emily');
    expect(review.date, isNotNull);
  });

  test('saving again replaces the review instead of adding a second one', () {
    final container = containerFor(1);
    final reviews = container.read(myReviewsProvider.notifier);

    reviews.save(5, rating: 2, comment: 'Meh', reviewer: 'Emily');
    reviews.save(5, rating: 5, comment: 'Grew on me', reviewer: 'Emily');

    expect(container.read(myReviewsProvider), hasLength(1));
    expect(container.read(myReviewsProvider)[5]!.rating, 5);
  });

  test('a deleted review can be put back', () {
    final container = containerFor(1);
    final reviews = container.read(myReviewsProvider.notifier)..save(5, rating: 3, comment: 'Fine', reviewer: 'Emily');

    final removed = reviews.remove(5)!;
    expect(container.read(myReviewsProvider), isEmpty);

    reviews.restore(5, removed);
    expect(container.read(myReviewsProvider)[5]!.comment, 'Fine');
  });

  test('each account sees only its own reviews', () {
    containerFor(1).read(myReviewsProvider.notifier).save(5, rating: 3, comment: 'Fine', reviewer: 'Emily');
    expect(containerFor(2).read(myReviewsProvider), isEmpty);
  });
}
