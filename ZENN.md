# Zenn 記事の管理

このディレクトリの Markdown は [Zenn](https://zenn.dev) と GitHub 連携で公開します。

## 前提（初回のみ）

1. [zenn.dev](https://zenn.dev) にログイン。
2. ダッシュボード →「GitHubからのデプロイ」→ このリポジトリと `main` ブランチを連携。

## 依存関係のインストール

```sh
npm install
```

## 記事を書く

```sh
npm run new:article        # articles/<slug>.md を生成
npm run preview            # http://localhost:8000 でプレビュー
```

各記事の先頭にはフロントマターが必要です。

```yaml
---
title: "記事のタイトル"
emoji: "🐦"          # サムネ用の絵文字（1つ）
type: "tech"         # tech: 技術記事 / idea: アイデア
topics: ["flutter", "bloc"]   # タグ（最大5つ、英小文字）
published: false     # true で公開 / false は下書き
---
```

## 公開

`published: true` にして `main` へ push すると、Zenn が自動同期して公開されます。

```sh
git add articles/
git commit -m "記事を追加"
git push origin main
```

## メモ

- Zenn はリポジトリ**ルート直下の `articles/`・`books/`** のみを対象にします。
- 画像は `/images/...` に置いて相対参照できます。
- Mermaid（```` ```mermaid ````）はそのまま利用できます。
