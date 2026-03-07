# @repo/wiki

Repository wiki generator package.

## Script Contracts

- `pnpm run wiki:generate`
  - Generate zh-TW source wiki into `docs/wiki-mdx/*`
  - Sync en-US mirror skeleton into `docs/wiki-mdx/en-US/*`
- `pnpm run wiki:check`
  - Check zh-TW wiki drift
  - Check en-US mirror drift
- `pnpm run wiki:sync:en`
  - Rebuild en-US mirror skeleton from zh-TW source
- `pnpm run wiki:check:en`
  - Check en-US mirror drift only
- `pnpm run wiki:build:site`
  - Render HTML site from zh-TW wiki only
  - Output target: `apps/public/wiki-site/*`
- `pnpm run wiki:check:site`
  - Check rendered HTML drift in app public target

## Bilingual Front Matter Contract

Generated wiki pages include the following fields:

- `doc_id`
- `lang`
- `source_of_truth`
- `translation_status`
- `source_hash`
- `owner`
- `last_synced_utc`

Contract validation command:

```bash
pnpm run verify:bilingual:contracts
```

## Site Visibility Contract

- Frontend route `/repoWiki` keeps loading `wiki-site/README.html`.
- HTML is a build artifact and is not tracked by git.
- `build-site` ignores `docs/wiki-mdx/en-US/*` and renders a single-language HTML site for now.
