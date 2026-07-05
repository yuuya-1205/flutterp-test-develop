---
name: test-workflow
description: 品質の高いテストを「テスト設計書 → 実装 → 検証 → レビュー → CI → マージ」まで、各工程で数値メトリクスのゲートを置いて進めるためのワークフロー。テストを追加・改善するとき、カバレッジやテストケースを数値で管理したいときに使う。
---

# テスト品質ワークフロー

テストを「設計書からマージまで」一貫した品質ゲート付きで進める手順。
各フェーズに**数値メトリクス**を置き、満たさないものは次に進めない。

> このプロジェクトの目標カバレッジは **100%**（ライン／ブランチとも）。CI で強制する。
> Bloc/State/テストの書き方は skill **bloc** / **bloc-state** / **bloc-test** を参照。

## フェーズ0. テスト設計書（Design）

> 前段として、`docs/requirements-template.md` で要件を整理しておく（要件整理 → テスト設計 → テスト実装）。

`docs/test-design-template.md` をコピーして設計書を作成する。記入項目は以下。

1. 対象を決める（例: `CounterBloc` / `CounterPage`）。
2. テスト観点を洗い出す：**正常系 / 異常系 / 境界値 / 状態遷移**。
3. テストケース一覧表を作る（ID・観点・前提・操作・期待結果）。
4. レビューで観点漏れを潰す。

> 人間が記入した設計書を起点に、エージェントはフェーズ1以降の実装を行う。

📊 ゲート
- 観点カバレッジ＝カバー観点 / 全観点 = **100%**
- 計画テストケース数を確定（観点ごとの内訳）

## フェーズ1. テスト実装（Implement）

1. skill **bloc-test** に沿って Bloc/State テストを実装。
2. UI は Widget テスト、ロジックは単体テストに分離。
3. テスト名＝期待結果。1ケースの目的を1つに絞る。

📊 ゲート
- 実装済みケース数 / 計画ケース数 = **100%**
- 空テスト・アサーション漏れ = **0**

## フェーズ2. ローカル検証（Verify）

```sh
dart format .
flutter analyze                       # 警告・エラー 0
flutter test --coverage               # coverage/lcov.info を生成
lcov --summary coverage/lcov.info     # カバレッジ率を確認（任意）
# HTML レポート（任意）: genhtml coverage/lcov.info -o coverage/html
tool/metrics.sh                       # 物理KLOC / テスト件数 / テスト密度 / バグ密度
# バグがあれば: tool/metrics.sh <バグ件数>
```

📊 ゲート
- `flutter analyze` 警告 = **0**
- テスト失敗 = **0**
- **ラインカバレッジ = 100%**、**ブランチカバレッジ = 100%**

> カバレッジが 100% に届かない場合は、未到達行（lcov の `DA:` が 0 の行）に対してテストを追加する。
> どうしてもテスト不能な行は `// coverage:ignore-line` 等で明示し、理由をレビューで共有する（多用しない）。

## フェーズ3. PR作成・レビュー（Review）

1. `.github/pull_request_template.md` に沿って**日本語**で記載。
2. UI 変更があれば before / after スクリーンショットを添付。
3. PR 本文にカバレッジ数値・テストケース数を記載。
4. レビュー指摘 → 修正を同じブランチへ push（PR が更新される）。

📊 ゲート
- レビュー指摘の未対応 = **0**
- 追加・変更した行に対応するテストがある（カバレッジ低下 = 0）

## フェーズ4. CI・品質ゲート（CI Gate）

GitHub Actions（`.github/workflows/ci.yml`）が PR で自動実行する。

- `flutter analyze` → `flutter test --coverage` → カバレッジ閾値チェック。
- カバレッジが **100% 未満**なら fail。

📊 マージ前必須
- CI = **green**
- カバレッジ = **100%**
- flaky（再実行で結果が変わる）= **0**

## フェーズ5. マージ（Merge）

1. すべてのゲートを満たす。
2. Squash merge で `main` へ。
3. 作業ブランチを削除。

📊 継続追跡
- main のカバレッジ推移（下降検知）
- バグ流出数（マージ後に発見された不具合）

## メトリクス一覧

| 指標 | 取得方法 | ゲート |
| --- | --- | --- |
| ラインカバレッジ | `lcov --summary` / CI | **100%** |
| ブランチカバレッジ | `lcov --rc lcov_branch_coverage=1` | **100%** |
| 計画/実装ケース数 | 設計書 vs テスト | 一致（100%） |
| analyze 警告数 | `flutter analyze` | 0 |
| テスト失敗数 | `flutter test` | 0 |
| flaky 率 | CI の再実行差分 | 0 |
| レビュー未対応指摘 | PR | 0 |
| 物理KLOC (lib) | `tool/metrics.sh` | 参考値 |
| テスト件数 | `tool/metrics.sh` | 参考値 |
| テスト密度（件/KLOC） | `tool/metrics.sh` | 下降させない |
| バグ密度（件/KLOC） | `tool/metrics.sh <バグ件数>` | 下降トレンド維持 |
