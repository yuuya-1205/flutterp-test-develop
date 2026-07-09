# Widgetbook

このプロジェクトのウィジェットカタログです。アプリ本体を起動せずに、
個々のウィジェットをプレビュー・確認できます（React の Storybook 相当）。

現在カタログに登録済みのウィジェット（Figma「自動車マッチングApp」由来）:

- `LogoutButton` — ログアウトボタン（primary[300] #1FA2CB）
- `WithdrawLink` — 退会するリンク（alert #FF4242）
- ログアウト / 退会エリア — Figma フレーム `1742-10957` の再現

## 起動方法（ローカル）

まず依存を取得します。

```bash
flutter pub get
```

### ブラウザ（Chrome）で開く

```bash
flutter run -d chrome -t widgetbook/main.dart
```

### ローカルホストの URL で開く（web-server）

ポートを固定して Web サーバとして起動すると、ブラウザで
`http://localhost:8080` を開いてアクセスできます。

```bash
flutter run -d web-server --web-port 8080 -t widgetbook/main.dart
```

起動後、コンソールに次のように表示されます:

```
Serving at http://localhost:8080
```

## 新しいウィジェットを追加するには

`widgetbook/main.dart` の `directories` に `WidgetbookComponent` /
`WidgetbookUseCase` を追記します。手動構成のため build_runner は不要です。
