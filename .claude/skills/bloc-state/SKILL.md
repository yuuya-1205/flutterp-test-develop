---
name: bloc-state
description: このプロジェクトの規約に沿って BLoC の State クラスを作成・編集する。Equatable を使った不変な State を定義したいとき、または新しいフィールドを State に追加したいときに使う。
---

# BLoC State の作成

このプロジェクトでは、BLoC の State を `Equatable` を使った**不変（immutable）クラス**として実装する。

## 規約

- `Equatable` を継承し、`props` に全フィールドを列挙する（値比較のため）。
- コンストラクタは `const` にする。フィールドは `final`。
- 既定値があるフィールドは名前付き引数の既定値で表現する（例: `this.count = 0`）。
- State は Bloc と同じ `*_bloc.dart` ファイル内の `// ===== State =====` セクションにまとめる。
- 派生値（偶奇など）が必要なら getter として State に持たせる（フィールドは元データのみ）。

## テンプレート

```dart
// ===== State =====

/// <対象>の状態。
class XxxState extends Equatable {
  const XxxState({this.count = 0});

  final int count;

  @override
  List<Object?> get props => [count];
}
```

## フィールドを追加するとき

1. `final` フィールドを追加する。
2. `props` のリストに必ず追加する（漏れると等価判定がバグる）。
3. 既定値が要るなら名前付き引数に既定値を設定する。

## やってはいけないこと

- ミュータブル（可変）なフィールドにしない（必ず `final`）。
- `props` に列挙し忘れない。
- 状態更新のための `copyWith` などは、実際に使う場合のみ追加する（未使用のメソッドは置かない）。
