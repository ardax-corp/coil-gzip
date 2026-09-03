# Consuming coil-gzip

This package is `gzip`. `use gzip::{compress, decompress, Gzip, GzipError}` resolves from `src/gzip.hy`. This repo is **private** (`https://github.com/ardax-corp/coil-gzip.git`); clone with credentials that can read it. There is no native/FFI dep.

Raw DEFLATE is [`coil-deflate`](https://github.com/ardax-corp/coil-deflate) (`https://github.com/ardax-corp/coil-deflate.git`), also private. Do not vendor those sources here.

Coil-to-Coil deps will be spool-owned once a public `spool` CLI exists. Until then `{ git }` parses and the pin is `coil.lock` `rev` + `content_hash`.

The Coil compiler does **not** read `coil.toml`. Module search is `--root` (repeatable) plus default `src`. It does not follow path or git deps.

## Sibling checkout

Clone this repo next to `coil-deflate`. Pass the deflate sources on the compiler flag:

```
coil test --root ../coil-deflate/src
```

CI checks out deflate under `.ci/coil-deflate` and runs:

```
coil test --root .ci/coil-deflate/src
```

`[module] roots` in `coil.toml` is spool schema (same sibling path). It is not a compiler input.

## Git dep and coil.lock

`{ git }` is the parseable form. `version` is optional schema, not a tag. `rev` on the dep is stored only. Do not run `spool add`. There is no public spool CLI.

```toml
[dependencies]
deflate = { git = "https://github.com/ardax-corp/coil-deflate.git" }
gzip = { git = "https://github.com/ardax-corp/coil-gzip.git" }
```

This repo has no tags. The pin is `coil.lock` `rev` + `content_hash`. Omit `tag`. Use sibling checkout until spool materializes `.spool/deps`. The compiler does not read `coil.lock` and does not inject roots.

```
# spool lockfile v1
[[package]]
name = 'deflate'
git = 'https://github.com/ardax-corp/coil-deflate.git'
rev = '07f945931f89bd97281513b50f7cbfb35111c872'
content_hash = '<tree SHA>'
```

`rev` is the commit. `content_hash` is that commit's git tree (`git rev-parse 'HEAD^{tree}'`). Replace both when you move the pin.

## Call compress / decompress

Signatures are in [`src/gzip.hy`](../src/gzip.hy). Call patterns are in [`tests/roundtrip.hy`](../tests/roundtrip.hy) and [`tests/vectors.hy`](../tests/vectors.hy).

```coil
use string::{to_bytes};
use gzip::{compress, decompress, Gzip, GzipError};

let gz = compress(to_bytes("hello"))?;
let out = decompress(gz)?;
let also = Gzip::decompress(gz)?;
```

`compress` / `decompress` take `Vec<byte>` and return `Result<Vec<byte>, GzipError>`. The DEFLATE payload is RFC 1951 raw blocks, not a zlib wrapper.

### GzipError

```coil
enum GzipError {
    Invalid { message: string },
}
```

Malformed input returns `GzipError::Invalid`, not a panic.

```coil
match decompress(Vec::new()) {
    Result::Ok(_) => false,
    Result::Err(e) => match e {
        GzipError::Invalid { message } => message != "",
        default => false,
    },
}
```
