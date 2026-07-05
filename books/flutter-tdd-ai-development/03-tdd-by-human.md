---
title: "第3章 まずは人間だけでTDD ― Red / Green / Refactor"
---

AI にテストを渡す前に、そのテストを書く人間自身が TDD のリズムを体で知っている必要があります。本章では AI を使わず、最小のロジックを題材に Red / Green / Refactor のサイクルを1周ずつ実況します。

## テストファーストの基本サイクル

TDD の基本サイクルは3つの状態の繰り返しです。

1. **Red**: まだ存在しないふるまいに対するテストを書き、失敗させる。
2. **Green**: そのテストを通す最小限の実装を書く。
3. **Refactor**: テストが緑のまま、コードを整理する。

重要なのは順序です。テストを先に書くことで、「これから書くコードは何をすべきか」が実装前に文章とコードで固定されます。第1章で述べたとおり、この「実装前に固定された期待値」こそが、後の章で AI に渡す仕様書になります。まずは人間だけでこの感覚をつかみましょう。

## カウンターのロジックをWidgetから分離する

前章で見たとおり、デフォルトのカウンターアプリではロジックが `_MyHomePageState` の中に埋まっています。`_counter++` をテストしようとすると Widget ごと起動する必要があり、「1増える」という単純なふるまいの検証としては大げさです。

そこで最初の設計判断として、カウンターのロジックを純粋な Dart クラスに切り出すことにします。置き場所は `lib/counter/counter.dart`、テストは lib と同じ構成で `test/counter/counter_test.dart` に置きます。この「テストは lib をミラーした構成で置く」というルールは、本書を通して守ります。

ただし TDD ですから、先にクラスを書いてはいけません。書くのはテストからです。

## 最初のテストを書く：increment のふるまい

`Counter` クラスに期待するふるまいを、まずテストとして書き下ろします。テスト名は日本語で「<操作> で <結果>」の形式に統一します。

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

3つのケースを用意しました。「初期値は 0」「1回で 1」「2回で 2」。一見冗長に見えるかもしれませんが、この3点セットには意味があります。初期値のテストは出発点を固定し、1回のテストは増分を固定し、2回のテストは「状態が蓄積される」ことを固定します。この解像度の違いが AI に与える影響は、第4章で実験して確かめます。

## Red → Green → Refactor を体で覚える

ここからサイクルを実況します。

**Red。** この時点で `flutter test` を実行すると、テストは失敗どころかコンパイルエラーになります。`lib/counter/counter.dart` がまだ存在しないからです。コンパイルエラーも立派な Red です。「テストが要求しているものがまだ世界に存在しない」ことを、ツールが正確に教えてくれています。

:::message
Red を確認せずに実装へ進むのは避けてください。一度も失敗していないテストは、「本当にそのふるまいを検証できているか」が未確認のテストです。
:::

**Green。** テストを通す最小限の実装を書きます。

```dart
// lib/counter/counter.dart
class Counter {
  int _value = 0;

  int get value => _value;

  void increment() => _value++;
}
```

`flutter test` を再実行すると、3件すべてが緑になります。フィールド `_value` を private にして getter だけを公開しているのは、値の変更経路を `increment` に限定するためです。テストも `counter.value` という読み取り専用の窓から結果を観測しています。

**Refactor。** 今回の実装は十分小さいため、コード側で整理することはほとんどありません。その代わり、呼び出し側を整理します。`_MyHomePageState` に `final Counter _counter = Counter();` を持たせ、FAB のハンドラを次のように書き換えます。

```dart
// lib/main.dart（_MyHomePageState の抜粋）
void _incrementCounter() {
  setState(() {
    _counter.increment();
  });
}
```

表示側は `'${_counter.value}'` を参照します。setState はまだ残っていますが、その役割は「再描画の指示」だけになり、「数を増やす」というロジックは `Counter` に移りました。状態管理の導入は第6章まで待ちますが、責務の線はここで引けたことになります。

書き換えのあと、必ず `flutter test` を実行してください。`counter_test.dart` の3件に加えて、デフォルトの widget_test.dart も緑のままのはずです。内部構造を変えてもふるまいが変わっていないことを、既存のテストが保証してくれています。これが Refactor の安全網です。

## given / when / then でテストを「読める仕様」にする

先ほどのテストには `// given` `// when` `// then` というコメントを入れました。これは飾りではなく、本書を通して守る構造規約です。

- **given**: 前提を整える（テスト対象を生成する、初期状態を作る）
- **when**: 検証したい操作を1つ実行する
- **then**: 結果を検証する

この3区分でテストを書くと、テストがそのまま「<前提> のとき <操作> すると <結果> になる」という仕様文として読めるようになります。たとえば2つ目のテストは「生成直後の Counter に対して increment を呼ぶと、value が 1 になる」と、コメントに沿って上から読み下せます。

人間のレビュアーにとって読みやすいことはもちろんですが、本書の文脈ではもうひとつ効能があります。given / when / then で区切られたテストは、AI にとっても「前提・操作・期待結果」が明確に分離された仕様書になるのです。曖昧さのないテストは、曖昧さのないプロンプトです。

これで、人間だけで回す TDD の1サイクルを体験しました。次章ではいよいよこのサイクルに AI を組み込み、「テストは人間が書き、実装は AI に任せる」開発を実験します。テストの解像度が AI の出力をどう変えるかに注目してください。
