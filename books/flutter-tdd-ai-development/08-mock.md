---
title: "第8章 外部依存とモック ― 保存機能を追加する"
---

前章までのカウンターは、アプリを終了すると値が消えてしまいます。本章では「カウント値を保存し、次回起動時に復元する」という要件を追加します。ここで初めて、SharedPreferences という**外部依存**がコードベースに入ってきます。外部依存はテストの書き方を大きく変える分岐点であり、同時に AI に実装を任せるときに事故が起きやすいポイントでもあります。テストを仕様書として保ちながら、この境界をどう扱うかが本章のテーマです。

## カウント値の永続化という要件

まず要件を言葉で固めます。

- アプリ起動時に、保存済みのカウント値があればそれを復元する。
- カウント値が変わるたびに、その値を保存する。
- 保存先は端末のローカルストレージ（SharedPreferences）とする。

一見小さな要件ですが、これまでの機能追加と決定的に違う点があります。**Bloc の中だけでは完結しない**ことです。SharedPreferences はプラットフォーム（Android / iOS など）のネイティブ実装に依存しており、`flutter test` が動くピュアな Dart のテスト環境には、その裏側が存在しません。つまり、Bloc が SharedPreferences を直接触る設計にしてしまうと、これまで書いてきた blocTest がそのままでは動かなくなります。

ここで立ち止まって考えたいのは、「Bloc のテストで検証したいことは何か」です。本書がテストで守りたいのは「加算したら count が増え、その値が保存**されようとする**こと」「起動時に保存済みの値が復元**されること**」という**ふるまい**であって、「SharedPreferences が実際にディスクへ書き込むこと」ではありません。後者は shared_preferences パッケージ自身のテストが保証すべき領域です。

検証したいふるまいと、検証しなくてよい外部の実装。この線引きをコードの構造に落とし込む道具が、依存性注入とインターフェース分離です。

## 依存性注入とインターフェース分離

「保存・復元」という関心事を、まずインターフェースとして切り出します。

```dart
// lib/counter/counter_repository.dart
/// カウント値の保存・復元を担う境界インターフェース。
abstract class CounterRepository {
  Future<int?> load();

  Future<void> save(int value);
}
```

`load` は保存済みの値がなければ null を返し、`save` は値を受け取って保存する。それだけの契約です。SharedPreferences の「S」の字も出てきません。Bloc から見える世界はこのインターフェースまでで、その先に何があるか（SharedPreferences なのか、ファイルなのか、サーバーなのか）を Bloc は知りません。

実装クラスは別ファイルに置きます。

```dart
// lib/counter/shared_preferences_counter_repository.dart
import 'package:shared_preferences/shared_preferences.dart';

import 'counter_repository.dart';

class SharedPreferencesCounterRepository implements CounterRepository {
  static const _key = 'counter_value';

  @override
  Future<int?> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key);
  }

  @override
  Future<void> save(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, value);
  }
}
```

そして Bloc には、この `CounterRepository` を**コンストラクタで注入**します。あわせて「起動時に保存済みの値を読み込む」ための `CounterStarted` イベントを追加し、各ハンドラを async 化します。

```dart
// lib/counter/counter_bloc.dart（第8章での変更点の抜粋）

/// 起動イベント。保存済みの値を読み込む。
class CounterStarted extends CounterEvent {
  const CounterStarted();
}

class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc({required CounterRepository repository})
      : _repository = repository,
        super(const CounterState()) {
    on<CounterStarted>(_onStarted);
    on<CounterIncremented>(_onIncremented);
    on<CounterDecremented>(_onDecremented);
    on<CounterReset>(_onReset);
  }

  final CounterRepository _repository;

  /// 保存済みの値を読み込む（add をラップした入口＝公開メソッド）。
  void start() => add(const CounterStarted());

  Future<void> _onStarted(
    CounterStarted event,
    Emitter<CounterState> emit,
  ) async {
    final saved = await _repository.load();
    if (saved != null) {
      emit(state.copyWith(count: saved));
    }
  }

  Future<void> _onIncremented(
    CounterIncremented event,
    Emitter<CounterState> emit,
  ) async {
    final next = state.count + 1;
    emit(state.copyWith(
      count: next,
      history: [...state.history, state.count],
    ));
    await _repository.save(next);
  }

  // decrement / reset も同じパターンで save を呼ぶ
}
```

この構造の利点は明快です。本番コードでは `CounterBloc(repository: SharedPreferencesCounterRepository())` と組み立て、テストでは同じコンストラクタに**偽物のリポジトリ**を渡す。Bloc のコードは一切変わりません。依存を外から差し込めるようにしておくこと（依存性注入）と、差し込み口を抽象に絞ること（インターフェース分離）は、テスト容易性のための基本装備です。

組み立て側の main.dart も更新します。「起動時の復元」は、BlocProvider の create で Bloc を生成した直後に公開メソッド start() を呼ぶことで実現します。

```dart
// lib/main.dart（第8章での組み立て）
void main() {
  runApp(MyApp(repository: SharedPreferencesCounterRepository()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.repository});

  /// 差し替え可能な保存先。未指定ならインメモリ実装を使う。
  final CounterRepository? repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BlocProvider(
        create: (_) => CounterBloc(
          repository: repository ?? InMemoryCounterRepository(),
        )..start(),
        child: const CounterPage(),
      ),
    );
  }
}
```

InMemoryCounterRepository は、値をメモリ上のフィールドに持つだけの小さな実装です。

```dart
// lib/counter/in_memory_counter_repository.dart
import 'counter_repository.dart';

class InMemoryCounterRepository implements CounterRepository {
  int? _value;

  @override
  Future<int?> load() async => _value;

  @override
  Future<void> save(int value) async {
    _value = value;
  }
}
```

この一手間には理由があります。デフォルトの widget_test.dart は `const MyApp()` を pump しますが、テスト環境には SharedPreferences のプラグインが存在しません。repository を未指定にしたときのフォールバックをインメモリ実装にしておくことで、**widget_test.dart は今回も1文字も書き換えずに緑のまま**です。本番の main() だけが実物の SharedPreferencesCounterRepository を渡します。

第5章の instructions ファイルに「モックするのは外部境界（リポジトリ等）だけ」という規約を書いたことを思い出してください。あの一文は、まさにこの `CounterRepository` のような境界を想定したものでした。

## mocktail でリポジトリをモックする

偽物のリポジトリを手書きすることもできますが、本書では mocktail パッケージを使います。mocktail はコード生成なしで動くモックライブラリで、`Mock` を継承したクラスを1行定義するだけで使えます。

テストの正とする書き方は次のとおりです。

```dart
// test/counter/counter_bloc_test.dart（第8章）
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
    'CounterIncremented で save(1) が1回呼ばれる',
    build: () => CounterBloc(repository: repository),
    act: (bloc) => bloc.add(const CounterIncremented()),
    verify: (_) {
      verify(() => repository.save(1)).called(1);
    },
  );
}
```

読み解くポイントを整理します。

- **setUp でデフォルトの応答を用意する**。`load()` は「保存なし（null）」、`save()` は「何もせず完了」を既定にしておくと、各テストは自分の関心がある部分だけを上書きすれば済みます。
- **状態の検証と呼び出しの検証を使い分ける**。復元のテストは「emit される State」を `expect:` で検証し、保存のテストは「リポジトリの `save(1)` が1回呼ばれたこと」を `verify:` で検証しています。前者は結果の検証、後者は外部境界との相互作用の検証です。
- **`thenAnswer((_) async => ...)` で Future を返す**。モック対象のメソッドが async の場合、同期値を返す `thenReturn` ではなく `thenAnswer` を使います（後述の落とし穴に直結します）。

そして、この2つのテストこそが本章の要件の仕様書です。「CounterStarted で保存済みの値 42 が復元される」「CounterIncremented で save(1) が1回呼ばれる」。テスト名を読むだけで要件が復元できる状態を保てているか、常に確認してください。

## 外部依存があるコードをAIに書かせるときの落とし穴

外部依存が絡む実装は、AI に任せると独特の失敗パターンが出やすい領域です。本書の経験から、典型的な落とし穴を4つ挙げます。いずれも「AI が間違える」というより、**規約や境界を明示しないと AI がもっともらしい別解に流れる**という性質のものです。

### 落とし穴1: 自作クラスまでモックしてしまう

モックライブラリを導入した途端、AI は何でもモックしたがる傾向があります。典型例は `CounterState` のような自作の値オブジェクトまで `Mock` で置き換えたテストを生成してくるケースです。値オブジェクトをモックすると、Equatable による等価比較というふるまいそのものが失われ、テストは「モックがモックを検証する」空洞になります。モックするのは `CounterRepository` のような**外部境界だけ**。この規約は instructions ファイルに明記しておくべきですし、第5章のテンプレートにはすでに書いてあります。

### 落とし穴2: async メソッドに thenReturn を使う

`when(() => repository.load()).thenReturn(42)` のようなコードを AI が生成することがあります。`load()` の戻り値は `Future<int?>` なので、これは実行時に型の不整合で落ちるか、スタブが効かずにテストが不可解に失敗します。async メソッドのスタブは必ず `thenAnswer((_) async => 42)` の形にします。レビューで見抜きやすいように、「async のスタブは thenAnswer」という一文をチーム規約に入れておくと確実です。

### 落とし穴3: verify で実装詳細を縛りすぎる

`verify` は強力ですが、AI に任せると「`load()` が先に呼ばれ、次に `save()` が呼ばれ、それ以外の呼び出しはない」といった、実装手順を丸ごと固定するテストを書きがちです。こうしたテストはリファクタリングのたびに壊れ、第7章で確認した「テストが壊れる＝仕様変更の検知」というシグナルをノイズで埋めてしまいます。verify で検証するのは「save(1) が1回呼ばれた」のような、**仕様として意味のある相互作用**に絞ります。

### 落とし穴4: モックと実装側テストの守備範囲を混ぜる

`SharedPreferencesCounterRepository` 自体のテストには、モックではなく `SharedPreferences.setMockInitialValues({})` を使ってテスト用のインメモリ実装に差し替える方法があります。ここで AI に指示が曖昧だと、Bloc のテストに setMockInitialValues が紛れ込んだり、逆にリポジトリ実装のテストで mocktail を使って SharedPreferences をモックしようとしたりと、境界の両側がごちゃ混ぜになった出力が返ってくることがあります。住み分けは明確です。**Bloc のテストは CounterRepository を mocktail でモックする。リポジトリ実装のテストは setMockInitialValues で SharedPreferences 側を差し替える。**それぞれのテストが検証する層を1つに保ちます。

:::message
4つに共通する対処は同じです。落とし穴を検知するのはテストとレビューであり、落とし穴を予防するのは instructions ファイルの規約です。AI に渡すプロンプトへ毎回注意書きを書くのではなく、規約として一度書き、テストで機械的に守らせるのが本書の流儀です。
:::

## 統合テストとWidgetテストの使い分け

最後に、本章で増えたテストの守備範囲を整理して、テスト全体の地図を描き直します。

本章までに登場したテストは、実はすべて `flutter test` で動く高速なテストです。Bloc の unit テスト（blocTest）はモックしたリポジトリとの組み合わせでロジックを検証し、第2章から一度も書き換えていないデフォルトの widget_test.dart は「起動して + を押したら 1 になる」という画面のふるまいを検証しています。Widget テストはテスト用の描画環境で動くため、実端末もエミュレータも不要で、数秒で完走します。

一方で、この構成には意図的な**穴**があります。「SharedPreferences が実機で本当に読み書きできるか」「アプリを本当に再起動したら値が復元されるか」は、どのテストも検証していません。ここを埋めるのが統合テスト（integration_test パッケージによる、実機・エミュレータ上でアプリ全体を動かすテスト）です。

使い分けの基準を本書は次のように置きます。

| テストの種類 | 実行環境 | 検証すること | 速度 |
| --- | --- | --- | --- |
| unit テスト（blocTest） | Dart VM | ロジックと状態遷移。外部境界はモック | 速い |
| Widget テスト | テスト用描画環境 | 画面のふるまい（表示・タップ・遷移） | 速い |
| 統合テスト | 実機・エミュレータ | 外部依存を含めた全体の結合 | 遅い |

原則は「**ピラミッドの下から埋める**」です。ロジックの正しさは unit テストで、画面のふるまいは Widget テストで検証し尽くし、統合テストには「本物の SharedPreferences と本物のアプリが正しくつながっているか」という、下の層では原理的に検証できない確認だけを残します。統合テストは強力ですが遅く、壊れたときの原因特定も難しいため、数を絞るほど開発のリズムは保たれます。そしてこの構成は AI との協働でも効きます。数秒で回る unit / Widget テストの層が厚いほど、AI が生成したコードの合否判定が速く、Red / Green のサイクルが途切れないからです。

外部依存を境界の向こうに隔離し、モックでふるまいを仕様化し、テストの層ごとに守備範囲を決める。ここまでで、カウンターアプリの設計とテストは一通りの完成を見ました。次章では、この揃ったテスト群を「人間が手で回すもの」から「CI が自動で回すゲート」へ引き上げます。
