---
title: "付録A 本書で使ったテストコード全リスト"
---

本文中では章の流れに合わせてテストコードを少しずつ提示してきました。ここでは、写経や手元での再現がしやすいように、主要なテストファイルを完全な形で再掲します。いずれもパッケージ名は counter_app を前提としています。

## 第3章の counter_test.dart

人間だけで Red / Green / Refactor を回した、ロジック分離直後の Counter クラスに対するテストです。「初期値 0」「1回で 1」「2回で 2」という3点の解像度が、後の章で AI への仕様書として機能しました。

```dart
// test/counter/counter_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:counter_app/counter/counter.dart';

void main() {
  group('Counter', () {
    test('生成直後の value は 0 である', () {
      // given
      final counter = Counter();

      // then
      expect(counter.value, 0);
    });

    test('increment で value が 1 増える', () {
      // given
      final counter = Counter();

      // when
      counter.increment();

      // then
      expect(counter.value, 1);
    });

    test('increment を2回呼ぶと value は 2 になる', () {
      // given
      final counter = Counter();

      // when
      counter.increment();
      counter.increment();

      // then
      expect(counter.value, 2);
    });
  });
}
```

## 第8章終了時点の counter_bloc_test.dart 最終形

第6章の Bloc 移行、第7章の機能拡張（デクリメント・リセット・履歴）、第8章のリポジトリ注入までをすべて反映した最終形です。第7章の各テストと第8章のモックを使ったテストを1つのファイルに統合しています。

:::message
第7章時点では `build: CounterBloc.new` と書いていましたが、第8章で CounterBloc のコンストラクタが `CounterRepository` を要求するようになったため、すべてのテストで `build: () => CounterBloc(repository: repository)` に変わっています。また、この統合にあたって一部のテストは名前と形式を本文から調整し、CounterStarted の null ケースなど本文にコードとして登場しなかったテストを数件補完しています（仕様は本文と同じです）。
:::

```dart
// test/counter/counter_bloc_test.dart（第8章終了時点の最終形）
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:counter_app/counter/counter_bloc.dart';
import 'package:counter_app/counter/counter_repository.dart';

class MockCounterRepository extends Mock implements CounterRepository {}

void main() {
  late MockCounterRepository repository;

  setUp(() {
    repository = MockCounterRepository();
    when(() => repository.load()).thenAnswer((_) async => null);
    when(() => repository.save(any())).thenAnswer((_) async {});
  });

  test('初期状態は CounterState(count: 0) である', () {
    expect(CounterBloc(repository: repository).state, const CounterState());
  });

  // ===== 加算 =====

  blocTest<CounterBloc, CounterState>(
    'CounterIncremented で count が 1 になり、履歴に 0 が積まれる',
    build: () => CounterBloc(repository: repository),
    act: (bloc) => bloc.add(const CounterIncremented()),
    expect: () => const [
      CounterState(count: 1, history: [0]),
    ],
  );

  blocTest<CounterBloc, CounterState>(
    'CounterIncremented で save(1) が1回呼ばれる',
    build: () => CounterBloc(repository: repository),
    act: (bloc) => bloc.add(const CounterIncremented()),
    verify: (_) {
      verify(() => repository.save(1)).called(1);
    },
  );

  // ===== 減算 =====

  blocTest<CounterBloc, CounterState>(
    'count が 0 のとき CounterDecremented では何も emit されない',
    build: () => CounterBloc(repository: repository),
    act: (bloc) => bloc.add(const CounterDecremented()),
    expect: () => const <CounterState>[],
  );

  blocTest<CounterBloc, CounterState>(
    'count が 2 のとき CounterDecremented で count が 1 になり、履歴に 2 が積まれる',
    build: () => CounterBloc(repository: repository),
    seed: () => const CounterState(count: 2),
    act: (bloc) => bloc.add(const CounterDecremented()),
    expect: () => const [
      CounterState(count: 1, history: [2]),
    ],
  );

  // ===== リセット =====

  blocTest<CounterBloc, CounterState>(
    'CounterReset で count が 0 に戻り、直前の値が履歴に残る',
    build: () => CounterBloc(repository: repository),
    seed: () => const CounterState(count: 5),
    act: (bloc) => bloc.add(const CounterReset()),
    expect: () => const [
      CounterState(history: [5]),
    ],
  );

  blocTest<CounterBloc, CounterState>(
    'count が 0 で履歴も空のとき CounterReset では何も emit されない',
    build: () => CounterBloc(repository: repository),
    act: (bloc) => bloc.add(const CounterReset()),
    expect: () => const <CounterState>[],
  );

  // ===== 永続化 =====

  blocTest<CounterBloc, CounterState>(
    'CounterStarted で保存済みの値 42 が復元される',
    build: () => CounterBloc(repository: repository),
    setUp: () {
      when(() => repository.load()).thenAnswer((_) async => 42);
    },
    act: (bloc) => bloc.add(const CounterStarted()),
    expect: () => const [CounterState(count: 42)],
  );

  blocTest<CounterBloc, CounterState>(
    '保存済みの値がないとき CounterStarted では何も emit されない',
    build: () => CounterBloc(repository: repository),
    act: (bloc) => bloc.add(const CounterStarted()),
    expect: () => const <CounterState>[],
  );

  // ===== 複数インスタンスの独立性 =====

  blocTest<CounterBloc, CounterState>(
    '別インスタンスの increment はこの Bloc に影響しない',
    build: () => CounterBloc(repository: repository),
    act: (bloc) {
      final other = CounterBloc(repository: repository);
      other.increment();
    },
    expect: () => const <CounterState>[],
  );
}
```

## デフォルトの widget_test.dart

Flutter テンプレートが生成したままの Widget テストです。本書ではこのファイルに一度も手を入れていません。setState から Bloc への移行、機能拡張、永続化の追加を経ても「起動時に 0、＋を押すと 1」というふるまいは変わらなかったため、このテストは最初から最後まで緑のままでした。ふるまいに対するテストが内部構造の変更に対する安全網になる、という本書の主張をこのファイル自身が証明しています。

```dart
// test/widget_test.dart
// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:counter_app/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('1'), findsOneWidget);
  });
}
```

以上が本書のテスト資産の全体像です。次の付録Bでは、これらのテストを AI に「チームの流儀」として伝えるための instructions ファイルの完全版を示します。
