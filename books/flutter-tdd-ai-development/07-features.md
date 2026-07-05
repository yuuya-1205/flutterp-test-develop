---
title: "第7章 機能拡張ラッシュ ― テストファーストでAIと増築する"
---

第6章で、カウンターの状態管理は Bloc に移行しました。土台が整ったので、本章では一気に機能を増やします。デクリメント、リセット、履歴、カウンターの複数化。4つの機能を、すべて同じリズムで追加していきます。

そのリズムとは「テストを書く → AIに投げる → レビューする」です。人間が書いたテストが仕様書となり、AIが実装し、人間が差分をレビューする。第4章で確立し、第5章の instructions ファイルで精度を上げたこのサイクルを、本章では4回連続で回します。繰り返すうちに、どこで人間の判断が必要になるのかがはっきり見えてくるはずです。

## 機能1：デクリメントと下限値（0未満にしない）

最初の機能は減算です。仕様は次の2点とします。

- decrement を呼ぶと count が 1 減る
- count が 0 のときは何もしない（0未満にはならない）

まずテストを書きます。実装より先に、仕様をコードとして固定するのが本書のやり方です。

```dart
// test/counter/counter_bloc_test.dart（追加分）
blocTest<CounterBloc, CounterState>(
  'CounterDecremented で count が 1 減る',
  build: CounterBloc.new,
  seed: () => const CounterState(count: 2),
  act: (bloc) => bloc.add(const CounterDecremented()),
  expect: () => const [CounterState(count: 1)],
);

blocTest<CounterBloc, CounterState>(
  'count が 0 のとき CounterDecremented では何も emit されない',
  build: CounterBloc.new,
  act: (bloc) => bloc.add(const CounterDecremented()),
  expect: () => const <CounterState>[],
);
```

新しい要素が2つあります。1つ目は `seed:` です。blocTest は seed で「テスト開始時点の状態」を指定できます。count が 2 の状態から始めれば、「1 減って 1 になる」ことを1ケースで検証できます。

2つ目が本章の最初の教材ポイント、**「何もしない」の書き方**です。仕様は「0 のときは何もしない」でした。Bloc の言葉に翻訳すると「State を emit しない」です。そして blocTest の expect は「emit された State のリスト」でしたから、何も emit されないことは**空リスト**で表現します。「何も起きない」というふるまいまでテストで固定できるのが、blocTest の expect がリストである利点です。

テストは当然 Red です（そもそも CounterDecremented が存在しないのでコンパイルが通りません）。ここで AI に投げます。

> test/counter/counter_bloc_test.dart に減算のテストを2つ追加しました。lib/counter/counter_bloc.dart を修正してテストを通してください。既存のイベント・公開メソッドの構成に合わせてください。

instructions ファイルが効いていれば、AI は既存の CounterIncremented と対称な形で実装してきます。典型的な出力はこうです。

```dart
// lib/counter/counter_bloc.dart（追加分）

/// 減算イベント（0未満にはしない）。
class CounterDecremented extends CounterEvent {
  const CounterDecremented();
}

// Bloc 側
/// 減算する。0未満にはならない。
void decrement() => add(const CounterDecremented());

void _onDecremented(CounterDecremented event, Emitter<CounterState> emit) {
  if (state.count == 0) return; // 下限値。emit しない
  emit(CounterState(count: state.count - 1));
}
```

テストは Green です。ただしここで1つ、興味深い分岐点があります。AI は次のような実装を返してくることもあります。

```dart
void _onDecremented(CounterDecremented event, Emitter<CounterState> emit) {
  emit(CounterState(count: (state.count - 1).clamp(0, state.count)));
}
```

count が 0 のとき、この実装は「0 のまま emit しようとする」実装です。一見、ガード版と同じふるまいに見えます。ところが実際に走らせると、**空リストのテストはこの clamp 実装を Red にします**。第6章で触れた「現在と等しい State は emit されない」という抑制は、そのインスタンスが一度でも State を emit した後にだけ働くもので、**生成直後の最初の emit は、初期状態と等価でも必ず通知される**からです（初期状態をリスナーへ知らせられるようにするための仕様です）。seed を使っていないこのテストでは、clamp 実装が emit する CounterState(count: 0) がそのままリストに現れ、expect の空リストと食い違います。「0 のときはイベントを処理しない」という仕様を満たすのは、早期 return で emit 自体を行わないガード版だけです。空リストの expect は「何も起きないこと」まで検証できる、想像以上に解像度の高い書き方だと分かります。

## 機能2：リセット機能

2つ目はリセットです。仕様は「count を 0 に戻す」。同じリズムでテストから書きます。

```dart
// test/counter/counter_bloc_test.dart（追加分）
blocTest<CounterBloc, CounterState>(
  'CounterReset で count が 0 に戻る',
  build: CounterBloc.new,
  seed: () => const CounterState(count: 5),
  act: (bloc) => bloc.add(const CounterReset()),
  expect: () => const [CounterState()],
);

blocTest<CounterBloc, CounterState>(
  'count が 0 のとき CounterReset では何も emit されない',
  build: CounterBloc.new,
  act: (bloc) => bloc.add(const CounterReset()),
  expect: () => const <CounterState>[],
);
```

AI に投げると、まずはこんな素直な実装が返ってくることがあります。

```dart
// lib/counter/counter_bloc.dart（追加分）

/// リセットイベント。
class CounterReset extends CounterEvent {
  const CounterReset();
}

// Bloc 側
/// 0 にリセットする。
void reset() => add(const CounterReset());

void _onReset(CounterReset event, Emitter<CounterState> emit) {
  emit(const CounterState());
}
```

1つ目のテストは通りますが、2つ目のテスト（0 のときは emit されない）は **Red** です。理由は機能1で確認したとおり、生成直後の最初の emit は初期状態と等価でも通知されるためです。失敗ログを添えてもう一度 AI に依頼すると、ガード付きの実装が返ってきます。

```dart
void _onReset(CounterReset event, Emitter<CounterState> emit) {
  if (state.count == 0) return; // 既に初期状態なら何もしない
  emit(const CounterState());
}
```

これで2つとも Green です。「0 のときは何もしない」という仕様を空リストの expect で書いたことが、実装のガードまで AI を導いた形です。テストの解像度がそのまま実装の正確さに変換されています。

## 機能3：カウント履歴の保持

3つ目は少し毛色が違います。「各操作の直前の count を履歴として残す」という仕様で、**State の形そのものが変わる**変更です。

- CounterState に `history`（`List<int>`）を追加する
- increment / decrement / reset のたびに、操作直前の count を history の末尾に追加する

まずテストです。スペックとなる代表ケースを書きます。

```dart
// test/counter/counter_bloc_test.dart（追加分）
blocTest<CounterBloc, CounterState>(
  'CounterIncremented で count が 1 になり、履歴に 0 が積まれる',
  build: CounterBloc.new,
  act: (bloc) => bloc.add(const CounterIncremented()),
  expect: () => const [
    CounterState(count: 1, history: [0]),
  ],
);

blocTest<CounterBloc, CounterState>(
  'CounterReset で count が 0 に戻り、直前の値が履歴に残る',
  build: CounterBloc.new,
  seed: () => const CounterState(count: 5),
  act: (bloc) => bloc.add(const CounterReset()),
  expect: () => const [
    CounterState(history: [5]),
  ],
);
```

### 既存テストが Red になる ― 仕様変更の検知

AI に実装させてテストを走らせると、新しいテストは Green になりますが、代わりに**既存のテストが Red になります**。たとえば第6章で書いた「CounterIncremented で count が 1 になる」は、expect が `[CounterState(count: 1)]` でした。実装後の実際の emit は `CounterState(count: 1, history: [0])` です。Equatable は props 全体で等価判定するため、履歴の分だけ一致せず失敗します。

これはトラブルではありません。**テストがふるまいの変化を検知した**、つまりテストが仕事をした瞬間です。「increment しても State は count しか変わらない」という旧仕様が、「履歴も変わる」という新仕様に置き換わった。既存テストの Red は、その仕様変更が既存のふるまいに波及したことの証明です。

対処の原則ははっきりしています。**仕様が変わったのだから、テストから直す**。旧仕様のテストを新仕様の期待値に書き換えます（先に挙げた新テストと重複するものは削除して統合します）。逆に、もし「仕様を変えたつもりがないのに」既存テストが Red になったら、それは実装のバグです。同じ Red でも意味がまったく違います。この区別を自分で説明できることが、テストを仕様書として運用する上での分岐点になります。

:::message alert
ここで AI に「失敗している既存テストも直しておいて」と丸投げしてはいけません。テストは仕様書です。仕様書の書き換えは人間の仕事であり、AI に任せると「実装に合わせてテストを直す」という本末転倒（instructions ファイルで禁止した行為）を人間側から招くことになります。
:::

### copyWith を「必要になったから」導入する

State のフィールドが2つになると、ハンドラ側で毎回 `CounterState(count: ..., history: ...)` と全フィールドを書き並べるのは冗長で、書き漏らしの温床になります。ここで初めて copyWith を導入します。

第6章の時点で copyWith を用意しなかったのは意図的です。フィールドが1つしかない State に copyWith を足しても、使われないコードが増えるだけでした。「いずれ要るだろう」で書くのではなく、必要になった瞬間に導入する。YAGNI（You Aren't Gonna Need It）の実践です。AI は聞かれなくても copyWith や toJson を先回りして生成してくる傾向がありますが、採用するかどうかの判断基準は「今この変更に必要か」に置きます。

機能3を反映した counter_bloc.dart の全体像がこちらです。本章の最終形でもあります。

```dart
// lib/counter/counter_bloc.dart（第7章終了時点）
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

// ===== Event =====

sealed class CounterEvent extends Equatable {
  const CounterEvent();

  @override
  List<Object?> get props => [];
}

/// 加算イベント。
class CounterIncremented extends CounterEvent {
  const CounterIncremented();
}

/// 減算イベント（0未満にはしない）。
class CounterDecremented extends CounterEvent {
  const CounterDecremented();
}

/// リセットイベント。
class CounterReset extends CounterEvent {
  const CounterReset();
}

// ===== State =====

/// カウンターの状態。count と操作履歴を持つ。
class CounterState extends Equatable {
  const CounterState({this.count = 0, this.history = const []});

  final int count;
  final List<int> history;

  CounterState copyWith({int? count, List<int>? history}) {
    return CounterState(
      count: count ?? this.count,
      history: history ?? this.history,
    );
  }

  @override
  List<Object?> get props => [count, history];
}

// ===== Bloc =====

/// カウンターの状態管理を担う Bloc。
class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(const CounterState()) {
    on<CounterIncremented>(_onIncremented);
    on<CounterDecremented>(_onDecremented);
    on<CounterReset>(_onReset);
  }

  /// 加算する（add をラップした入口＝公開メソッド）。
  void increment() => add(const CounterIncremented());

  /// 減算する。0未満にはならない。
  void decrement() => add(const CounterDecremented());

  /// 0 にリセットする。
  void reset() => add(const CounterReset());

  void _onIncremented(CounterIncremented event, Emitter<CounterState> emit) {
    emit(state.copyWith(
      count: state.count + 1,
      history: [...state.history, state.count],
    ));
  }

  void _onDecremented(CounterDecremented event, Emitter<CounterState> emit) {
    if (state.count == 0) return; // 下限値。emit しない
    emit(state.copyWith(
      count: state.count - 1,
      history: [...state.history, state.count],
    ));
  }

  void _onReset(CounterReset event, Emitter<CounterState> emit) {
    if (state.count == 0 && state.history.isEmpty) return;
    emit(CounterState(history: [...state.history, state.count]));
  }
}
```

細部を2つ確認します。まず `history: [...state.history, state.count]` は、既存リストを変更せず新しいリストを作るスプレッド構文です。State は不変に保つのが Bloc の前提なので、`state.history.add(...)` のような破壊的変更は使いません。

次に `_onReset` のガードです。機能2では `state.count == 0` だけを見て「何もしない」と判断していました。しかし履歴が加わった今、reset は「直前の count を履歴に積む」操作でもあります。ガードを count だけで判定したままだと、count が 0 で履歴だけが残っている状態からの reset まで弾いてしまい、逆にガードを外すと完全な初期状態からの reset で `CounterState(history: [0])` という**別の State** が生まれ、何もしていないのに履歴に 0 が積まれます。「何もしない」と言い切れるのは count が 0 かつ履歴も空のときだけ。だからガードの条件が `state.count == 0 && state.history.isEmpty` に広がりました。仕様が変われば、ガードの意味も一緒に変わるわけです。

## 機能4：カウンターの複数化

最後の機能は「カウンターを2つ画面に並べ、それぞれ独立に動かせるようにする」です。AI にこの要望を素朴に投げると、CounterBloc に ID の Map を持たせるような大改造を提案してくることがあります。しかし Bloc の設計では、その必要はありません。**Bloc クラスは1カウンター分の責務のままにして、インスタンスを複数作り、BlocProvider で個別にぶら下げる**のが素直な方針です。

まず「CounterBloc のインスタンスは互いに独立している」ことをテストで固定します。最初の試みはこう書きたくなります。

```dart
// test/counter/counter_bloc_test.dart（最初の試み）
test('複数の CounterBloc は互いに影響しない', () {
  // given
  final blocA = CounterBloc();
  final blocB = CounterBloc();

  // when
  blocA.increment();

  // then
  expect(blocA.state, const CounterState(count: 1, history: [0])); // 失敗する
  expect(blocB.state, const CounterState());
});
```

このテストは失敗します。バグではなく、**add したイベントの処理は非同期**だからです。increment() の直後には、まだ State は更新されていません。blocTest が内部で emit を待ってくれていたことが、素の test で書いてみると分かります。ここでは stream を1回 await して処理完了を待つ形に直します。

```dart
// test/counter/counter_bloc_test.dart
test('複数の CounterBloc は互いに影響しない', () async {
  // given
  final blocA = CounterBloc();
  final blocB = CounterBloc();

  // when
  blocA.increment();
  await blocA.stream.first;

  // then
  expect(blocA.state, const CounterState(count: 1, history: [0]));
  expect(blocB.state, const CounterState());
});
```

blocA だけが進み、blocB は初期状態のまま。Bloc がインスタンス単位で状態を閉じ込めていることの確認です。UI 側は、第6章で CounterPage に置いていた表示部分（BlocBuilder とボタン）を CounterView という Widget として lib/counter/counter_page.dart に切り出したうえで、BlocProvider を2つ並べるだけで済みます。

```dart
// lib/counter/counter_page.dart（2カウンター画面のスケッチ）
Column(
  children: [
    Expanded(
      child: BlocProvider(
        create: (_) => CounterBloc(),
        child: const CounterView(),
      ),
    ),
    Expanded(
      child: BlocProvider(
        create: (_) => CounterBloc(),
        child: const CounterView(),
      ),
    ),
  ],
)
```

CounterView は BlocBuilder で「最も近い祖先の CounterBloc」を購読するため、同じ Widget を2つ置くだけで独立した2カウンターになります。ロジックのコードは1行も変わっていません。「機能追加＝クラスの改造」と考えがちなところで、構成の変更だけで済ませられるのは、Bloc が状態をインスタンスに閉じ込めているおかげです。

## 各機能で繰り返す：テストを書く → AIに投げる → レビューする

4つの機能を通して、やったことは毎回同じでした。

1. **テストを書く**（人間）。仕様を blocTest の expect に翻訳する。「何もしない」なら空リスト、State の形が変わるなら新しい期待値。ここが仕様策定です。
2. **AIに投げる**（AI）。テストと instructions ファイルを文脈として渡し、実装させる。プロンプトは「このテストを通してください。既存の構成に合わせてください」でほぼ足ります。
3. **レビューする**（人間）。テストが Green であることは前提にすぎません。差分を読み、意図と一致しているかを確認する。

このサイクルを支えていたのは「1機能ずつ、全テスト Green の状態から始める」という規律です。デクリメントとリセットと履歴を1つのプロンプトでまとめて依頼することもできますが、そうすると Red の原因が「新機能が未実装だから」なのか「既存のふるまいを壊したから」なのか切り分けられなくなります。歩幅を小さく保つのは、人間だけの TDD でもテスト駆動AI開発でも変わらない原則です。

そして機能3で見たとおり、既存テストの Red は敵ではありません。仕様変更が波及範囲ごと可視化されたのですから、テストという仕様書を人間が書き換え、実装を追従させる。この順序さえ守れば、AI に大きな変更を任せても軸はぶれません。

## AIの出力レビューの観点：テストが通っていても見るべき場所

最後に、ステップ3のレビューで何を見るべきかを整理します。テストは仕様の検証を自動化してくれますが、**テストが表現していないことは何も保証しません**。本章の実例に基づいて、Green の裏で確認すべき観点を挙げます。

**過剰な一般化。** カウンターの上限・下限を引数で設定できる `maxCount` / `minCount`、増分を変えられる `step` パラメータ。AI は「気を利かせて」こうした拡張ポイントを盛り込んでくることがあります。テストは通ります（余計な機能はテストを壊さないからです）。しかし誰も頼んでいない一般化は、そのまま保守対象になります。copyWith を履歴導入まで書かなかったのと同じ基準、「今この変更に必要か」で削ります。

**頼んでいない公開APIの追加。** リセット機能を依頼したら `undo()` や `clearHistory()` や `setCount(int value)` まで生えていた、というのは典型的なパターンです。特に `setCount` のような「状態を直接書き換える入口」は、イベント経由で状態を変えるという Bloc の設計を静かに骨抜きにします。公開メソッドの一覧は Bloc の契約そのものなので、diff にシグネチャの追加があれば必ず依頼内容と突き合わせます。

**props への追加漏れ。** 本章で最も危険な例です。AI が CounterState に history フィールドを足しつつ、props を `[count]` のまま更新し忘れたとします。すると Equatable は history を無視して等価判定するため、`CounterState(count: 1, history: [0])` と `CounterState(count: 1, history: [])` が「等しい」ことになります。結果、履歴が壊れていても expect の比較は成立し、**テストは Green のまま機能だけが壊れます**。さらに BlocBuilder は同値の State では再描画しないため、UI の履歴表示も更新されません。Equatable を使う State にフィールドを足す diff を見たら、props に同じフィールドが並んでいるかを最初に確認してください。

**命名。** テストは名前を検証しません。イベント名が `DecrementEvent` になっていても、公開メソッドが `minusOne()` でも、テストの中でその名前を使っていない限り Green になり得ます。本書の規約ではイベントは「Counter + 過去分詞」（CounterDecremented）、公開メソッドは動詞（decrement）です。命名の乱れは instructions ファイルの改善材料でもあります。レビューで直すたびに規約へ還元すれば、次のサイクルから AI の初手が揃ってきます。

**意図と実装の一致。** 同じ Green でも、意図の表現が異なる実装はあります。たとえば機能1のガードを `if (state.count <= 0) return;` と書いてもテストはすべて通りますが、count が負になり得ない設計で `<=` を使うと「負もあり得る」と読めてしまいます。テストでは選べないこの領域は、人間が「仕様の意図を最も率直に表すのはどちらか」で判断します。

:::message
なお、本章でこれだけ内部構造を作り替えても、第2章から据え置きのデフォルト widget_test.dart（起動時 0 →「+」タップ → 1）は一度も Red になっていません。ふるまいベースのテストの安定性は、機能拡張ラッシュの中でも変わらず効いています。
:::

カウンターは、減らせて、リセットでき、履歴を持ち、複数並べられるようになりました。ただし今のカウントはアプリを終了すると消えてしまいます。次章では保存機能、つまり外部依存を持つ処理をテストファーストで扱います。ここで初めて「モック」が登場します。
