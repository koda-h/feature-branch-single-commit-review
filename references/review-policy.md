# Review Policy

## Severity Definition

### `high`

- 仕様破壊、主要ロジックの欠陥、データ破壊、セキュリティ問題、権限制御不備
- 本番障害や不正処理に直結しうる差分

### `middle`

- 条件漏れ、例外系の不足、回帰リスク、テスト不足、保守性を大きく落とす実装
- 直ちに致命傷ではないが、手戻りや障害の起点になりやすい差分

### `low`

- 可読性、命名、軽微な重複、コメント不足、小さな設計の揺れ
- 今すぐ壊れないが、積み重なると負債になる差分

## Threshold Rule

- `high` 指定: `high` のみ出す
- `middle` 指定: `high` と `middle` を出す
- `low` 指定または未指定: 全レベルを出す

## Report Template

```md
# Code Review

- Review time: 2026-03-30 12:30
- Base branch: develop
- Current branch: feature/xxx
- Merge base: abcdef1
- Reviewed commit pairs: 3
- Remaining commit pairs: 9
- Threshold: middle 以上
- Saved path: docs/code_review/feature-KP-1111_202603301230.md

## Findings

### High

- なし

### Middle

1. `a9e265be` -> `e5837e7a`
   - [middle] `path/to/file.ext:123`
     問題点の要約。どう壊れるか、なぜ不足かを簡潔に書く。
     最新コミットでの状態: 修正済み

### Low

- 閾値が `middle` 以上なら、このセクションは省略してよい

## Out Of Scope

- 今回レビューしていないコミットや範囲があればここに書く

## Notes

- 指摘事項なし、または要確認事項があればここに書く
- 残件がある場合は、ここで「デフォルトは10件単位で確認していること」と「件数指定でも続けられること」をユーザーに案内する
- 続きレビューの場合は、新規ファイルを作らずこのレポートに追記する
```

## Required Behavior

- レビュー本文は日本語で書く
- 指摘は重大度の高い順に並べる
- 各重大度セクションでは、差分ペアごとに `1. \`from_short\` -> \`to_short\`` の行を置く
- 各指摘に `最新コミットでの状態: 未修正 / 修正済み / 要確認` を必ず書く
- 各差分ペアの確認時に、必ず `HEAD` 時点の実装も確認してから結論を書く
- 1 回のレビュー対象はデフォルトで 10 件まで
- ユーザーが件数を指定した場合は、その件数を優先する
- 残件がある場合は自動で続行せず、デフォルトは 10 件だが件数指定でも続けられることをユーザーへ明示して確認する
- 続きレビューでは `build_report_path.sh --reuse-latest` を使い、同一ブランチの既存レポートへ追記する
- 指摘が 0 件でもレポートファイルは必ず作成する
- 保存前に `mkdir -p docs/code_review` を実行してよい
- 保存ファイル名は `<current-branch with / replaced by ->_<YYYYMMDDHHMM>.md` の形式にする
