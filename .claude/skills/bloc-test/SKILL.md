---
name: bloc-test
description: このプロジェクトの規約に沿って BLoC のテストを `bloc_test` パッケージで作成する。Bloc の初期状態やイベントごとの状態遷移を検証するテストを書きたいときに使う。
---

# BLoC テストの作成

このプロジェクトでは、BLoC のテストを `bloc_test` パッケージで書く。
モック（mocktail 等）は使わず、**実物の Bloc を直接検証**する。

## 配置

- テストは `lib/` と同じ構成で `test/` 配下に置く。
  例: `lib/counter/counter_bloc.dart` → `test/counter/counter_bloc_test.dart`

## 規約

- 初期状態は通常の `test(...)` + `expect` で確認する。
- 各イベントの状態遷移は `blocTest<Bloc, State>(...)` で書く。
  - `build: Bloc.new`（引数なしコンストラクタ）。
  - `act:` でイベントを `add` する。
  - `expect:` は emit される State の**リスト**を返す。
  - 初期状態と同一の State は emit されない。リセット等で初期状態へ戻す遷移を確認したいときは `seed:` で非初期状態にしてから `act` する。
- テスト名は「<イベント> で <結果>」のように日本語で簡潔に。

## テンプレート

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_test_app/counter/counter_bloc.dart';

void main() {
  test('initial state is CounterState(count: 0)', () {
    expect(CounterBloc().state, const CounterState());
  });

  blocTest<CounterBloc, CounterState>(
    'CounterIncremented で count が 1 になる',
    build: CounterBloc.new,
    act: (bloc) => bloc.add(const CounterIncremented()),
    expect: () => const [CounterState(count: 1)],
  );

  blocTest<CounterBloc, CounterState>(
    'CounterDecremented で count が -1 になる',
    build: CounterBloc.new,
    act: (bloc) => bloc.add(const CounterDecremented()),
    expect: () => const [CounterState(count: -1)],
  );
}
```

## seed を使う例（初期状態へ戻す遷移）

```dart
blocTest<CounterBloc, CounterState>(
  'リセットで count が 0 に戻る',
  build: CounterBloc.new,
  seed: () => const CounterState(count: 5),
  act: (bloc) => bloc.add(const CounterReset()),
  expect: () => const [CounterState(count: 0)],
);
```

## 実行

```sh
flutter test
```

## やってはいけないこと

- モックパッケージで Bloc の依存を差し替えない（実物を検証する）。
- 初期状態と同じ State を `expect` に並べない（emit されないため失敗する）。
