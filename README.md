# coil-gzip

Userland RFC 1952 gzip for [coil](https://github.com/ardax-corp/coil-lang). Package name is `gzip`, so `use gzip::{compress, decompress, Gzip, GzipError}` resolves here.

This repo is **private**. There is no native library, no ZIP, and no `[ffi] allow`. A gzip member is a 10-byte header (plus optional extra/name/comment/hcrc on decode), a **raw DEFLATE** body from [`coil-deflate`](https://github.com/ardax-corp/coil-deflate), then CRC32 and ISIZE.

## API

```coil
use gzip::{compress, decompress, GzipError};

let gz = compress(to_bytes("hello"))?;
let out = decompress(gz)?;
```

`compress` / `decompress` take `Vec<byte>` and return `Result<Vec<byte>, GzipError>`. Bad input returns `GzipError`, not a panic.

| Function | Role |
|----------|------|
| `compress` | RFC 1952 member (`Vec<byte>` → `Vec<byte>`) |
| `decompress` | RFC 1952 inflate + CRC32/ISIZE |
| `Gzip::compress` / `Gzip::decompress` | Same, as methods |

## Layout

| Path | Role |
|------|------|
| `src/gzip.hy` | `Gzip`, `GzipError`, CRC32, member wrap |
| `coil.toml` | spool manifest (`[package] name = "gzip"`); coil does not read it |

## Consume

Sibling checkouts of this repo and `coil-deflate`, plus `--root` for each so the compiler can load `gzip.hy` and `deflate.hy`. coil reads no `coil.toml`. `spool add gzip --git https://github.com/ardax-corp/coil-gzip.git --rev <commit SHA>` is the spool path once coil-deflate has a tag to resolve. See [docs/consume.md](docs/consume.md).

## License

MIT. See [LICENSE](LICENSE).
