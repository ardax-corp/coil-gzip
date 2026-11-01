# coil-gzip

Userland RFC 1952 gzip for [coil](https://github.com/ardax-corp/coil-lang). Package name is `gzip`, so `use gzip::{compress, decompress, crc32, Gzip, GzipError}` resolves here.

Pure Coil: no native library, no ZIP, and no `[ffi] allow`. A gzip member is a 10-byte header (plus optional extra/name/comment/hcrc on decode), a **raw DEFLATE** body from [`coil-deflate`](https://github.com/ardax-corp/coil-deflate), then CRC32 and ISIZE.

## Example

```coil
use tests::assert;
use string::{to_bytes, from_bytes};
use gzip::{compress, decompress, GzipError};

fn roundtrip(string text) -> Result<string, GzipError> {
    let gz = compress(to_bytes(text))?;
    let out = decompress(gz)?;
    return from_bytes(out).ok() ?? "";
}

fn main() {
    assert!((roundtrip("hello hello hello").ok() ?? "") == "hello hello hello");
}
```

Run it with `coil --root ../coil-gzip/src --root ../coil-deflate/src --root ../coil-stdlib/src main.coil` (or `spool run`).

## API

`compress` / `decompress` take `Vec<byte>` and return `Result<Vec<byte>, GzipError>`. `decompress` checks the CRC32 and ISIZE trailer. Bad input returns `GzipError::Invalid { message }`, not a panic.

| Item | Role |
|------|------|
| `compress` | RFC 1952 member (`Vec<byte>` → `Vec<byte>`) |
| `decompress` | RFC 1952 inflate + CRC32/ISIZE check |
| `Gzip::compress` / `Gzip::decompress` | Same, as static methods |
| `crc32` | IEEE CRC-32 of a byte vector |
| `GzipError` | Failure type (`Invalid { message }`) |

## Layout

| Path | Role |
|------|------|
| `src/gzip.coil` | The `gzip` module: `compress` / `decompress`, `Gzip`, `GzipError`, `crc32`, member header and trailer handling |
| `tests/` | Round-trip, known-vector and error-case tests (`coil test`) |
| `coil.toml` | spool manifest (`[package] name = "gzip"`, depends on `deflate`); coil does not read it |

## Consume

```bash
spool add gzip --git https://github.com/ardax-corp/coil-gzip.git --rev <commit SHA>
```

No tags yet, so pin a commit. spool also fetches the `deflate` dependency. Without spool, clone this repo and [coil-deflate](https://github.com/ardax-corp/coil-deflate) next to your project and pass `--root ../coil-gzip/src --root ../coil-deflate/src` to `coil`. See [docs/consume.md](docs/consume.md).

## License

MIT. See [LICENSE](LICENSE).
