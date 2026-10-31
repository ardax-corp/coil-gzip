# Consuming coil-gzip

This package is `gzip`. `use gzip::{compress, decompress, crc32, Gzip, GzipError}` resolves from `src/gzip.hy`. The repo is `https://github.com/ardax-corp/coil-gzip.git`. There is no native/FFI dep.

Raw DEFLATE comes from [`coil-deflate`](https://github.com/ardax-corp/coil-deflate) (`https://github.com/ardax-corp/coil-deflate.git`), package `deflate`.

The Coil compiler does **not** read `coil.toml` or `coil.lock`. Module search is `--root` (repeatable) plus default `src`. It does not follow path or git deps.

## Depend on it

With [spool](https://github.com/ardax-corp/spool):

```bash
spool add gzip --git https://github.com/ardax-corp/coil-gzip.git --rev <commit SHA>
```

This repo has no tags, so pin a commit with `--rev`. spool records the dep, writes `coil.lock` (`rev` + `content_hash`), links `.spool/deps/gzip`, resolves this repo's `deflate` git dependency, and passes `--root` for each plus coil-stdlib to `coil`.

## Without spool

Clone both repos next to your project and pass a root for each:

```bash
git clone https://github.com/ardax-corp/coil-gzip.git ../coil-gzip
git clone https://github.com/ardax-corp/coil-deflate.git ../coil-deflate
coil --root ../coil-gzip/src --root ../coil-deflate/src --root ../coil-stdlib/src main.hy
```

To run this repo's own tests from a checkout with `coil-deflate` as a sibling:

```bash
coil test --root ../coil-deflate/src --root ../coil-stdlib/src
```

CI does the same with deflate checked out under `.ci/coil-deflate`. `[module] roots` in `coil.toml` is read by spool, not by coil.

## Call compress / decompress

Signatures are in [`src/gzip.hy`](../src/gzip.hy). Call patterns are in [`tests/roundtrip.hy`](../tests/roundtrip.hy) and [`tests/vectors.hy`](../tests/vectors.hy).

```coil
use string::{to_bytes};
use gzip::{compress, decompress, Gzip, GzipError};

fn pack_and_unpack() -> Result<Vec<byte>, GzipError> {
    let gz = compress(to_bytes("hello"))?;
    let out = decompress(gz)?;
    let also = Gzip::decompress(gz)?;
    return out;
}
```

`compress` / `decompress` take `Vec<byte>` and return `Result<Vec<byte>, GzipError>`. The DEFLATE payload is RFC 1951 raw blocks, not a zlib wrapper. `decompress` reads exactly one member; concatenated members are not supported.

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
