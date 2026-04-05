---
name: feature-branch-single-commit-review
description: Use this skill when reviewing a feature branch that was created from `develop` and you want findings per single-commit diff in commit order. It resolves the branch point against `develop`, reviews each adjacent diff from the merge base to `HEAD` in batches of 10 by default, cross-checks every finding against the latest commit to determine whether it is already fixed, supports severity thresholds `high`, `middle`, and `low`, and saves the review result to `docs/code_review/<sanitized-feature-branch>_YYYYMMDDHHMM.md`.
---

# Feature Branch Single Commit Review

## Overview

`develop` ブランチから作成された feature ブランチを前提に、分岐後コミットを 1 コミット差分単位で先頭から順番にレビューする skill です。`merge-base -> 1件目`, `1件目 -> 2件目`, `2件目 -> 3件目` の順で見たうえで、各指摘について必ず最新コミットでも現象が残っているか確認します。レビューはデフォルトで 10 件単位で進め、残りがある場合は次を続けるかユーザーへ確認します。

## When To Use

- 現在の作業ブランチが `develop` 起点の feature ブランチで、差分レビューを 1 コミット単位に分解して順番に見たいとき
- 一度に全部ではなく、まず 10 件ずつ区切ってレビューを進めたいとき
- `high` / `middle` / `low` の閾値を指定して、指摘をそのレベル以上だけに絞りたいとき
- レビュー結果をチャットだけでなく、リポジトリ内の `docs/code_review/` 配下に Markdown として残したいとき

## Severity Threshold

- 指定が `high` の場合: `high` のみ出す
- 指定が `middle` の場合: `high` と `middle` を出す
- 指定が `low` の場合: `high` / `middle` / `low` を出す
- 指定がない場合: `low` とみなし、全レベルを出す
- 日本語表現は次のように解釈してよい:
  - `高`, `高以上` -> `high`
  - `中`, `中以上` -> `middle`
  - `低`, `低以上`, `全部`, `全件` -> `low`

レベル定義と出力テンプレートは [references/review-policy.md](references/review-policy.md) を参照します。

## Batch Size

- デフォルトは 10 件
- ユーザーが件数を明示した場合はその件数を優先する
- 件数指定がない場合は、差分ペアが 11 件以上あっても最初の 10 件だけレビューする
- 1 バッチが終わって未レビューの差分ペアが残る場合は、そこで止めてユーザーに続行確認を返す
- 続行確認では、次のように伝える:
  - 既定では 10 件ずつ確認していること
  - 件数を指定すれば、たとえば 5 件や 20 件のように任意件数でも確認できること

## Review Workflow

1. Git リポジトリ直下、または対象リポジトリ内で作業していることを確認する。
2. `develop` を基準ブランチとして、`scripts/list_review_ranges.sh` でレビュー順序を解決する。
3. 今回レビューする件数を決める。指定がなければ 10 件、指定があればその件数を使う。
4. 列挙された差分ペアのうち、今回のバッチ対象だけを先頭から順番にレビューする。
5. 各ペアについて `git show --stat --summary <to_commit>` と `git diff <from_commit>..<to_commit>` で差分を読む。
6. 差分ペアで問題候補を見つけたら、必ず対象箇所の hunk を抜き出し、`変更前` と `変更後` が分かる差分抜粋を用意する。表示は GitHub コードレビューに近い `diff` コードブロックを優先し、必要最小限の行数に絞る。
7. 必ず `git diff <to_commit>..HEAD` や `git show HEAD` も確認し、最新コミット時点で修正済みかどうかを判定する。
8. まず `high` を探し、次に `middle`、最後に `low` を整理する。`low` は閾値が `low` のときだけ出す。
9. 各指摘は、どの差分ペアで見つかったか分かるように `1. \`from_short\` -> \`to_short\`` の見出しの下にまとめる。
10. 各指摘には `最新コミットでの状態` を文頭で明記する:
   - `未修正`
   - `修正済み`
   - `要確認`
11. 各指摘には、対象ファイルと位置の説明に加えて `変更前` / `変更後` の差分抜粋を必ず含める。必要に応じて前後数行の文脈を残してよいが、レビュー論点に関係しない行は省く。
12. 指摘が 0 件でも、レビュー対象範囲・閾値・確認した差分ペア数はレポートに残す。
13. 保存先パスを決める。
14. 初回レビューなら `scripts/build_report_path.sh` で新規パスを作る。続きレビューなら `scripts/build_report_path.sh --reuse-latest` で既存レポートを再利用する。
15. 続きレビューでは新しいファイルを作らず、先に作成済みのレポートへ追記する。
16. レビュー結果を `docs/code_review/<sanitized-feature-branch>_YYYYMMDDHHMM.md` に保存または追記し、最後に保存先パスを明示する。
17. 未レビューの差分ペアが残っている場合は、そこで止めてユーザーに続行確認を返す。確認文には「デフォルトは 10 件」「件数指定でも続けられる」を含める。

## Target Commit Rules

- 基準ブランチは固定で `develop`
- 分岐点は `git merge-base develop HEAD` で求める
- feature ブランチ上のコミット列は `git rev-list --reverse <merge-base>..HEAD` で求める
- `merge-base..HEAD` にコミットがない場合はレビューしない
- レビュー単位は次の 1 コミット差分ペアとする:
  - 1件目: `<merge-base> -> <first_commit>`
  - 2件目: `<first_commit> -> <second_commit>`
  - 3件目以降も同様
- デフォルトでは `merge-base..HEAD` に含まれる全コミットを差分ペアとして順番にレビューする
- ただし 1 回の実行でレビューするのは、デフォルトで先頭から 10 件まで
- ユーザーが件数を指定した場合は、その件数だけ先頭からレビューする
- 指定コミットのみをレビューしたいときは、別途 SHA を明示した運用に切り分ける
- レポートにはレビューした差分ペア数を残す

## Output Rules

- レビュー本文は必ず日本語で書く
- findings を先に並べ、重大度の高い順に出す
- 各重大度セクションでは、差分ペアごとに連番を振る:
  - 例: `1. `a9e265be` -> `e5837e7a``
- 各指摘には少なくとも次を含める:
  - 文頭の状態ラベル: `[未修正]` / `[修正済み]` / `[要確認]`
  - レベル: `high` / `middle` / `low`
  - どの差分ペアでの指摘か
  - 対象ファイルと位置
  - 何が問題か
  - どう壊れるか、または何が不足しているか
  - `変更前` と `変更後` が分かる差分抜粋
  - 最新コミットでの状態: `未修正` / `修正済み` / `要確認`
- 各差分ペアのレビューでは、指摘がある場合もない場合も最新コミットを一度は確認する
- 差分抜粋は GitHub コードレビューに近い `diff` コードブロックを優先し、`-` 行を変更前、`+` 行を変更後として読める形にする
- 差分抜粋はレビュー論点に必要な最小限の hunk に絞る。長い差分をそのまま貼らない
- 1 回の実行でレビューした件数と、残件数を最後に明記する
- 続きレビューでは、新規ファイルを作らず同一ブランチの既存レポートへ追記する
- 指摘がない場合は `指摘事項なし` と明記する
- 憶測で埋めず、差分から断定できない点は `要確認` とする
- レビュー対象外の範囲がある場合は `対象外` セクションに分ける

## Saving The Report

保存先はカレントリポジトリ配下の `docs/code_review/` に固定します。ディレクトリがなければ作成します。

ファイル名のブランチ部分は、現在ブランチ名の `/` を `-` に置換した値を使います。

例:

- `feature/TASK-1111` -> `feature-TASK-1111`
- `feature/TASK-1111_fix-mail` -> `feature-TASK-1111_fix-mail`

保存先生成は `scripts/build_report_path.sh` を使ってよいです。

```bash
mkdir -p docs/code_review
report_path="$(bash scripts/build_report_path.sh --branch feature/TASK-1111 --timestamp 202603301805)"
# => docs/code_review/feature-TASK-1111_202603301805.md
```

続きレビューでは既存レポートを再利用します。

```bash
report_path="$(bash scripts/build_report_path.sh --branch feature/TASK-1111 --reuse-latest)"
# => docs/code_review/feature-TASK-1111_202603301805.md
```

レポート本文は [references/review-policy.md](references/review-policy.md) のテンプレートに沿って組み立て、最終的にそのままファイルへ保存します。

## Command Notes

- `git` コマンドが sandbox 制約や一時ディレクトリ制約で失敗したら、推測せず必要な権限をリクエストする
- diff が大きい場合でも、1 回に見る対象は常に 1 コミット差分ペアに限定する
- 生成したレポートファイルは最後にユーザーへパスを伝える
- ブランチ名が `feature/` で始まらない場合も、保存ファイル名は現在ブランチ名をそのまま `/` -> `-` 変換して使う

## Example Requests

- `$feature-branch-single-commit-review でこの feature ブランチのコミット差分を先頭から順番にレビューして`
- `$feature-branch-single-commit-review でまず 10 件レビューして`
- `$feature-branch-single-commit-review で次の 5 件をレビューして`
- `$feature-branch-single-commit-review で middle 以上だけレビューして`
- `$feature-branch-single-commit-review で各指摘に diff 範囲と、最新コミットで修正済みかどうかを付けてレビューして`
- `$feature-branch-single-commit-review で GitHub コードレビューのように変更前と変更後の差分も出して`

## Resources

- `scripts/list_review_ranges.sh`
  - `develop` との分岐点から、`merge-base -> 1件目 -> 2件目 ...` のレビュー順序を返す
- `scripts/build_report_path.sh`
  - 現在ブランチ名をファイル名向けに正規化し、初回は新規パス、続きでは既存レポートパスを返す
- [references/review-policy.md](references/review-policy.md)
  - レベル定義、出力テンプレート、保存時の書式をまとめている
