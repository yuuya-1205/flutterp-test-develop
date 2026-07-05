<!-- docs/test-design-template.md を counter 機能向けに記入した「見本」。フェーズ0の成果物。 -->

# テスト設計書: CounterBloc / CounterPage

| 項目 | 内容 |
| --- | --- |
| 対象 | `CounterBloc`（単体） / `CounterPage`（Widget） |
| 種別 | 単体（Bloc）＋ Widget（UI） |
| 対応要件 | `docs/requirements/counter.md` |
| 作成日 / 記入者 | 2026-07-05 / （記入例） |
| ステータス | 確定 |

## 1. テスト対象と範囲

- 対象: カウンターの状態遷移（Bloc）と画面表示・操作（Page）。
- 範囲に含む: 初期状態、加算による状態遷移、画面の初期表示と加算後表示。
- 範囲に含まない: 減算・リセット・永続化（要件のスコープ外）。

## 2. テスト観点の洗い出し

| 観点カテゴリ | 観点（テストで確認したいこと） | カバー状況 |
| --- | --- | --- |
| 正常系 | 初期状態は count = 0 | ✅ |
| 正常系 | increment で count が 1 増える | ✅ |
| 境界値 | 加算前の初期値 0 | ✅（TC-01 で兼ねる） |
| 状態遷移 | increment 連続で count が積み上がる | ✅ |
| 異常系 | 該当なし（外部入力・失敗経路が無い） | ✅ 該当なし（理由記載） |
| UI | 初期表示が "0"、加算後に "1" | ✅ |

📊 観点カバレッジ = 6 / 6 = **100%**（異常系は「該当なし」を明示してカバー扱い）

## 3. テストケース一覧

| ID | 観点 | 前提 (Given) | 操作 (When) | 期待結果 (Then) |
| --- | --- | --- | --- | --- |
| TC-01 | 正常系/境界値 | Bloc 生成直後 | なし | state == CounterState(count: 0) |
| TC-02 | 正常系 | count = 0 | `increment()` を1回 | [CounterState(count: 1)] を emit |
| TC-03 | 状態遷移 | count = 0 | `increment()` を2回 | [count:1, count:2] を emit |
| TC-04 | UI | CounterPage 表示 | 描画直後 | "0" が1つ表示される |
| TC-05 | UI | CounterPage 表示 | ＋ボタンをタップ | "1" が表示され "0" は消える |

📊 計画テストケース数: **5 件**
（内訳 — 正常系: 2 / 異常系: 0 / 境界値: 1(兼) / 状態遷移: 1 / UI: 2）

## 4. テストデータ / 前提条件

- モックは使わず実物の `CounterBloc` を検証（bloc-test 規約）。
- Widget テストは `BlocProvider` で `CounterBloc` を供給して `CounterPage` を描画。

## 5. 実装マッピング（フェーズ1への引き継ぎ）

| ケース ID | テスト種別 | 配置ファイル |
| --- | --- | --- |
| TC-01..03 | 単体（bloc_test） | `test/counter/counter_bloc_test.dart` |
| TC-04..05 | Widget | `test/counter/counter_page_test.dart` |

## 6. レビューチェック（設計ゲート）

- [x] 4観点（正常系/異常系/境界値/状態遷移）に漏れがない
- [x] 各ケースが「期待結果」で命名できている
- [x] 計画ケース数が確定している（5件）
- [x] 対応する要件（受け入れ条件）をすべて満たしている
