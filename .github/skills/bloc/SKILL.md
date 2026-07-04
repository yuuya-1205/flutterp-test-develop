---
name: bloc
description: このプロジェクトの規約に沿って BLoC（Event + State + Bloc）を作成・編集する。新しい機能の状態管理を BLoC で追加したいとき、イベントやハンドラを足したいときに使う。
---

# BLoC の作成

このプロジェクトでは、素の BLoC パターン（`bloc` / `flutter_bloc` + `equatable`）を使う。
**Event・State・Bloc は1つの `<feature>_bloc.dart` ファイルにまとめる**（part 分割や Facade 用の別ファイルは作らない）。

## ファイル構成

`lib/<feature>/<feature>_bloc.dart` に、次の3セクションをこの順で並べる。

```dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

// ===== Event =====
// ... イベント定義

// ===== State =====
// ... State 定義（skill: bloc-state を参照）

// ===== Bloc =====
// ... Bloc 本体
```

## Event の規約

- `sealed class XxxEvent extends Equatable` を基底にする（`props => []`）。
- 個々のイベントは `const` コンストラクタを持つサブクラス。
- 各イベントに簡潔な doc コメントを付ける。

```dart
sealed class CounterEvent extends Equatable {
  const CounterEvent();

  @override
  List<Object?> get props => [];
}

/// 加算イベント。
class CounterIncremented extends CounterEvent {
  const CounterIncremented();
}
```

## Bloc の規約

- コンストラクタで初期 State を `super(...)` に渡し、`on<Event>(_onXxx)` でハンドラを**メソッド参照**として登録する（インラインのラムダにしない）。
- UI へ公開する操作は、`add` を隠蔽した**公開メソッド**（`add` をラップした入口）として実装する。UI はこのメソッドを呼び、`add` は直接書かせない。
- ハンドラは `void _onXxx(XxxEvent event, Emitter<State> emit)` の名前付きメソッドにする。

```dart
/// <対象>の状態管理を担う Bloc。
class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(const CounterState()) {
    on<CounterIncremented>(_onIncremented);
    on<CounterDecremented>(_onDecremented);
  }

  /// 加算する（add をラップした入口＝公開メソッド）。
  void increment() => add(const CounterIncremented());

  /// 減算する（add をラップした入口＝公開メソッド）。
  void decrement() => add(const CounterDecremented());

  void _onIncremented(CounterIncremented event, Emitter<CounterState> emit) {
    emit(CounterState(count: state.count + 1));
  }

  void _onDecremented(CounterDecremented event, Emitter<CounterState> emit) {
    emit(CounterState(count: state.count - 1));
  }
}
```

## やってはいけないこと

- Event を別ファイル（part 'xxx_event.dart'）に分割しない。
- 別ファイルの Facade クラスを作らない（公開メソッドは Bloc 内に置く）。
- ハンドラ登録をインラインのラムダで書かない（メソッド参照にする）。
- 使わないヘルパー・引数（未使用の usecase 注入など）を持ち込まない。

## 関連

- State の詳細は skill **bloc-state** を参照。
- テストの書き方は skill **bloc-test** を参照。
