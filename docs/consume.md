# Consuming coil-gzip

This package is `gzip`. `use gzip::{compress, decompress, Gzip, GzipError}` resolves from `src/gzip.hy`. This repo is **private** (`https://github.com/ardax-corp/coil-gzip.git`); clone with credentials that can read it. There is no native/FFI dep.

Raw DEFLATE is [`coil-deflate`](https://github.com/ardax-corp/coil-deflate) (`https://github.com/ardax-corp/coil-deflate.git`).

The Coil compiler does **not** read `coil.toml` or `coil.lock`. Module search is `--root` (repeatable) plus default `src`. It does not follow path or git deps.

## Depend on it

With [spool](https://github.com/ardax-corp/spool):

```bash
spool add gzip --git https://github.com/ardax-corp/coil-gzip.git --rev <commit SHA>
```

spool records the dep, writes `coil.lock` (`rev` + `content_hash`), links `.spool/deps/gzip`, resolves this repo's `deflate` dependency, and passes `--root` for each plus coil-stdlib to `coil`. Neither repo has tags yet, and this repo's `coil.toml` declares `deflate` with no `version` or `rev`, so the transitive resolve finds no matching tag. Until coil-deflate is tagged (or pinned here), use the sibling checkout.

## Sibling checkout

Clone this repo next to `coil-deflate`. Pass the deflate sources on the compiler flag:

```
coil test --root ../coil-deflate/src
```

CI checks out deflate under `.ci/coil-deflate` and runs:

```
coil test --root .ci/coil-deflate/src
```

A consumer passes both: `--root ../coil-gzip/src --root ../coil-deflate/src`. `[module] roots` in `coil.toml` is read by spool, not by coil.

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
