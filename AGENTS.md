# AGENTS.md

このファイルは、GitHub Copilot（Copilot CLI / coding agent など）がこのリポジトリで作業するときに
常に従う基本ルールをまとめたものです。詳細な規約は各 Skill（`.github/skills/`）や `docs/` に委譲し、
ここには「入口と地図」となる本質的なルールだけを置きます。

> Copilot は `.github/skills/<name>/SKILL.md` を Skill として読み込みます。
> 状態管理・テストの具体的な書き方は、対応する Skill を参照してください。

## 1. プロジェクト概要

- Dart / Flutter 製のクロスプラットフォームアプリ（Android / iOS / Web / Linux / macOS / Windows）です。
- Flutter SDK は `^3.9.2` を前提とします。
- 状態管理は BLoC（`flutter_bloc` / `bloc`）+ Equatable を採用したシンプルな構成です。

## 2. アーキテクチャ / ディレクトリ構成

機能ごとに `lib/<feature>/` を切り、Bloc と画面をまとめます。
Event・State・Bloc は1つの `*_bloc.dart` に集約します。

```txt
lib/
  main.dart                  # 起動地点・BlocProvider の設定
  counter/
    counter_bloc.dart        # Event / State / Bloc（同一ファイルにまとめる）
    counter_page.dart        # 画面ウィジェット
test/                        # lib/ と同じ構成でテストを配置
```

- 状態の保持と更新は **Bloc** が担います。
- UI は Bloc のイベントを直接 add せず、Bloc が公開する `increment()` / `decrement()` を呼び出します（`BlocBuilder` で状態を購読）。
- Event / State は `Equatable` で値比較できるようにします。
- ネイティブ設定（`android/`, `ios/` など）は必要な場合のみ変更します。
- 依存パッケージの追加・更新は `pubspec.yaml` を介して行います。

## 3. コーディング規約

- `analysis_options.yaml` で有効化された `flutter_lints` のルールに従います。
- 命名は Dart の慣例に従う（クラス: `UpperCamelCase`、変数・メソッド: `lowerCamelCase`、ファイル: `snake_case`）。
- ウィジェットは可能な限り `const` コンストラクタを使用します。
- コメントは日本語で記述して構いません。

## 4. ビルド・実行・テスト（検証）

変更を加えたら、**必ず**以下を実行して結果を確認してください。

```sh
flutter pub get      # 依存関係の取得
flutter run          # アプリの実行（接続中のデバイス／エミュレータ）
flutter test         # テストの実行
dart format .        # コードフォーマット
flutter analyze      # 静的解析(lint)
```

- コードを変更したら、最低でも `flutter analyze` と `flutter test` を実行し、成功を確認してから完了とみなします。
- フォーマット（`dart format .`）も可能な限り通してください。

## 5. 作業の進め方

### やること（DO）

- 大きな変更は、いきなり実装せず **まず方針（プラン）を提示** し、合意してから実装します。
- 実装前に、関連するドキュメント（「6. 参照ドキュメント」）を確認します。
- 1つのセッション（作業）では1テーマに集中し、区切りがついたらコミットします。
- 変更は対象に絞り、必要な範囲だけを修正します。
- UI の挙動を変更した場合は、対応するウィジェットテストを追加・更新します。

### やってはいけないこと（DON'T）

- `main` に直接コミットしない（作業ブランチで行う）。
- リクエストに関係のないファイルを変更しない。
- ネイティブ設定（`android/`, `ios/` など）を理由なく変更しない。

### ブランチ戦略（GitHub Flow）

`main` を常にリリース可能な状態に保ち、変更は **main から切った短命の作業ブランチ**で行います。

- `main` … 常にデプロイ可能。直接コミットしない。
- 作業ブランチ … `main` から切り、用途に応じて以下の接頭辞を付けます。
  - `feature/<内容>` … 機能追加（例: `feature/counter-bloc`）
  - `fix/<内容>` … バグ修正（例: `fix/decrement-overflow`）
  - `docs/<内容>` … ドキュメント・設定のみの変更（例: `docs/branch-strategy`）
  - `<内容>` はケバブケース（小文字 + ハイフン）で簡潔に。

進め方:

1. `main` を最新化してから作業ブランチを切る。
2. 1ブランチ＝1テーマに絞り、こまめにコミットする。
3. `flutter analyze` / `flutter test` を通してから Pull Request を作成する。
4. レビュー後に `main` へマージし、作業ブランチは削除する。

Pull Request:

- 本文は `.github/pull_request_template.md` のテンプレートに沿って**日本語**で記載する。
- UI に変化がある場合は、テンプレートの欄に **before / after のスクリーンショット**を必ず添付する。

## 6. 参照ドキュメント（地図）

実装前に、関連する以下のドキュメントを確認してください。

- `README.md` … プロジェクトの概要・入門情報
- `pubspec.yaml` … 依存関係・アセットの定義
- `analysis_options.yaml` … 静的解析(lint)ルール
- `.github/skills/` … Copilot が読み込む Skill 群（`bloc` / `bloc-state` / `bloc-test` / `test-workflow`）
- `docs/requirements-template.md` … 要件整理のテンプレート（TDD の起点。テスト設計の前段）
- `docs/test-design-template.md` … テスト設計書のテンプレート（テスト実装の起点）
- `tool/metrics.sh` … 物理KLOC / テスト件数 / テスト密度 / バグ密度を算出するスクリプト
