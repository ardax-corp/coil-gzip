# Vendored coil-deflate pin

`src/deflate.hy` is a **documented copy** of private `ardax-corp/coil-deflate` at commit `07f945931f89bd97281513b50f7cbfb35111c872`.

GitHub Actions `GITHUB_TOKEN` is repo-scoped. Checkout of `ardax-corp/coil-deflate` from this workflow failed with `repository not found` (same as a 403 on a private repo). Neither repo is public. There is no org PAT in this workflow.

Local development still uses `--root ../coil-deflate/src`. CI uses `--root vendor/coil-deflate/src`.
