# feature-branch-single-commit-review

`develop` から派生した feature ブランチを対象に、分岐後のコミットを 1 コミット差分単位で順番にレビューする skill です。

## できること

- `merge-base -> 1件目`, `1件目 -> 2件目` のように差分ペア単位でレビューする
- 各指摘について、最新コミット `HEAD` で未修正か修正済みかも確認する
- 各指摘に、GitHub コードレビューのように読める `変更前 / 変更後` の差分抜粋をデフォルトで含める
- レビューレベルを `high` / `middle` / `low` で切り替える
- レビュー結果を `docs/code_review/<branch-name>_YYYYMMDDHHMM.md` に保存する

## レビュー件数

- デフォルトは 10 件単位でレビューします
- 残件がある場合は、その場で続けるか確認します
- 件数を指定すれば、その件数だけレビューできます
- 続きをレビューする場合は、新しいファイルを作らず先に作成したレポートへ追記します

## 出力ファイル

- 保存先: `docs/code_review/`
- ファイル名: `<現在ブランチ名の / を - に置換>_YYYYMMDDHHMM.md`
- 続きレビュー時: 同一ブランチの最新レポートファイルへ追記

例:

- `feature/TASK-1111` -> `docs/code_review/feature-TASK-1111_202603301230.md`

## 使い方

```text
$feature-branch-single-commit-review
```

```text
$feature-branch-single-commit-review で middle 以上だけレビューして
```

```text
$feature-branch-single-commit-review でまず 10 件レビューして
```

```text
$feature-branch-single-commit-review で次の 5 件をレビューして
```

## レポート内容

- 差分ペアごとの指摘
- 各指摘の文頭に置く状態ラベル (`[未修正]` / `[修正済み]` / `[要確認]`)
- 重大度 (`high` / `middle` / `low`)
- 対象ファイルと位置
- GitHub コードレビューのように読める `変更前 / 変更後` の差分抜粋
- 問題内容
- 最新コミットでの状態 (`未修正` / `修正済み` / `要確認`)

## 差分抜粋について

- `変更前 / 変更後` の差分抜粋は追加オプションではなく、デフォルトの出力に含まれます
- 差分抜粋は GitHub コードレビューに近い `diff` コードブロックで出力します
- `-` 行を変更前、`+` 行を変更後として読める形で示します
- 長い差分全文は貼らず、レビュー論点に必要な最小限の hunk に絞って出します

## 関連ファイル

- `SKILL.md`
- `references/review-policy.md`
- `scripts/list_review_ranges.sh`
- `scripts/build_report_path.sh`
