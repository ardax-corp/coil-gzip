// Package root (`gzip`). RFC 1952 gzip members in pure Coil: a header, a raw
// DEFLATE body from the `deflate` package, then CRC32 and ISIZE. `compress` /
// `decompress` are the entry points; `Gzip` carries the same pair as static
// methods, `GzipError` is the failure type and `crc32` is the checksum the
// trailer uses. The byte and header helpers are internal.
use deflate::{Deflate, DeflateError};

/// Why `compress` or `decompress` failed.
///
/// Bad input is reported through this error, never a panic. Errors from the
/// DEFLATE body are passed through with the same message. There is one
/// variant today; match it with a `default` arm so a later variant does not
/// break your code.
///
/// # Examples
///
/// ```
/// use gzip::{decompress, GzipError};
/// use string::{to_bytes};
/// # use tests::assert;
/// let reason = match decompress(to_bytes("not a gzip member")) {
///     Result::Ok(_) => "",
///     Result::Err(e) => match e {
///         GzipError::Invalid { message } => message,
///         default => "other",
///     },
/// };
/// assert!(reason == "bad magic");
/// ```
enum GzipError {
    /// The input is not a valid gzip member. `message` is a short reason,
    /// such as `"bad magic"`, `"truncated header"`, `"bad crc"` or a DEFLATE
    /// error like `"truncated"`.
    Invalid { message: string },
}

fn invalid(string message) -> GzipError {
    return GzipError::Invalid { message: message };
}

fn u32_mask() -> int {
    let a: int = 65535;
    let sixteen: int = 16;
    return a | (a << sixteen);
}

fn crc_poly() -> int {
    let eight: int = 8;
    let sixteen: int = 16;
    let twenty_four: int = 24;
    let a: int = 237;
    let b: int = 184;
    let c: int = 131;
    let d: int = 32;
    return (a << twenty_four) | (b << sixteen) | (c << eight) | d;
}

/// IEEE CRC-32 of `data` (the gzip / zlib / PNG checksum, ISO 3309), as an
/// unsigned 32-bit value in an `int`.
///
/// Uses the reflected polynomial 0xEDB88320 with the usual all-ones initial
/// value and final XOR. The checksum of empty input is 0.
///
/// # Examples
///
/// ```
/// use gzip::{crc32};
/// use string::{to_bytes};
/// # use tests::assert;
/// // The standard check value, 0xCBF43926.
/// assert!(crc32(to_bytes("123456789")) == 3421780262);
/// assert!(crc32(Vec::new()) == 0);
/// ```
fn crc32(Vec<byte> data) -> int {
    let poly = crc_poly();
    let mask = u32_mask();
    let crc = mask;
    let i = 0;
    while i < data.len() {
        crc = crc ^ (data[i] as int);
        let b = 0;
        let eight: int = 8;
        while b < eight {
            if (crc & 1) == 1 {
                crc = (crc >> 1) ^ poly;
            } else {
                crc = crc >> 1;
            }
            b = b + 1;
        }
        crc = crc & mask;
        i = i + 1;
    }
    return (crc ^ mask) & mask;
}

fn put_u32_le(Vec<byte> out, int n) {
    let x = n & u32_mask();
    let lo: int = 255;
    let eight: int = 8;
    let sixteen: int = 16;
    let twenty_four: int = 24;
    out.push((x & lo) as byte);
    out.push(((x >> eight) & lo) as byte);
    out.push(((x >> sixteen) & lo) as byte);
    out.push(((x >> twenty_four) & lo) as byte);
}

fn get_u32_le(Vec<byte> data, int i) -> int {
    let eight: int = 8;
    let sixteen: int = 16;
    let twenty_four: int = 24;
    let a = data[i] as int;
    let b = data[i + 1] as int;
    let c = data[i + 2] as int;
    let d = data[i + 3] as int;
    return (a | (b << eight) | (c << sixteen) | (d << twenty_four)) & u32_mask();
}

fn skip_zero_string(Vec<byte> data, int i) -> Result<int, GzipError> {
    let p = i;
    while true {
        if p >= data.len() {
            raise invalid("truncated header");
        }
        let c = data[p] as int;
        p = p + 1;
        if c == 0 {
            return p;
        }
    }
}

fn header_end(Vec<byte> data) -> Result<int, GzipError> {
    if data.len() < 10 {
        raise invalid("truncated header");
    }
    if (data[0] as int) != 31 {
        raise invalid("bad magic");
    }
    if (data[1] as int) != 139 {
        raise invalid("bad magic");
    }
    if (data[2] as int) != 8 {
        raise invalid("bad method");
    }
    let flg = data[3] as int;
    let reserved: int = 224;
    let fextra: int = 4;
    let fname: int = 8;
    let fcomment: int = 16;
    let fhcrc: int = 2;
    if (flg & reserved) != 0 {
        raise invalid("reserved flags");
    }
    let i = 10;
    if (flg & fextra) != 0 {
        if i + 2 > data.len() {
            raise invalid("truncated extra");
        }
        let eight: int = 8;
        let xlen = (data[i] as int) | ((data[i + 1] as int) << eight);
        i = i + 2 + xlen;
        if i > data.len() {
            raise invalid("truncated extra");
        }
    }
    if (flg & fname) != 0 {
        i = skip_zero_string(data, i)?;
    }
    if (flg & fcomment) != 0 {
        i = skip_zero_string(data, i)?;
    }
    if (flg & fhcrc) != 0 {
        if i + 2 > data.len() {
            raise invalid("truncated hcrc");
        }
        i = i + 2;
    }
    return i;
}

fn slice_bytes(Vec<byte> data, int start, int end) -> Vec<byte> {
    let out: Vec<byte> = Vec::new();
    let i = start;
    while i < end {
        out.push(data[i]);
        i = i + 1;
    }
    return out;
}

fn inflate_raw(Vec<byte> body) -> Result<Vec<byte>, GzipError> {
    return match Deflate::decompress(body) {
        Result::Ok(v) => v,
        Result::Err(e) => match e {
            DeflateError::Invalid { message } => raise invalid(message),
            default => raise invalid("deflate"),
        },
    };
}

/// The RFC 1952 codec, as a namespace for `Gzip::compress` and
/// `Gzip::decompress`.
///
/// The free functions `compress` and `decompress` call these and behave the
/// same; use whichever spelling reads better. There is nothing to construct.
///
/// # Examples
///
/// ```
/// use gzip::{Gzip};
/// use string::{to_bytes};
/// # use tests::assert;
/// let src = to_bytes("abcabcabcabc");
/// let gz = Gzip::compress(src).ok() ?? Vec::new();
/// let back = Gzip::decompress(gz).ok() ?? Vec::new();
/// assert!(back == src);
/// ```
class Gzip {
    _unused: int,
}

impl Gzip {
    /// Wraps `data` in a single gzip member (RFC 1952).
    ///
    /// The member is a 10-byte header with no flags, no file name and a zero
    /// modification time (OS byte 255, unknown), the `Deflate::compress`
    /// body, then the CRC32 and the input length mod 2^32, both little-endian.
    /// The output reads with `gunzip` and other gzip tools.
    ///
    /// # Errors
    ///
    /// Returns `GzipError::Invalid` only if the DEFLATE encoder fails, which it
    /// does not today.
    ///
    /// # Examples
    ///
    /// ```
    /// use gzip::{Gzip};
    /// use string::{to_bytes};
    /// # use tests::assert;
    /// let gz = Gzip::compress(to_bytes("hello")).ok() ?? Vec::new();
    /// // Magic bytes 1f 8b, then method 8 (DEFLATE).
    /// assert!(gz[0] == 31 as byte && gz[1] == 139 as byte && gz[2] == 8 as byte);
    /// ```
    pub static fn compress(Vec<byte> data) -> Result<Vec<byte>, GzipError> {
        let body = match Deflate::compress(data) {
            Result::Ok(v) => v,
            Result::Err(e) => match e {
                DeflateError::Invalid { message } => raise invalid(message),
                default => raise invalid("deflate"),
            },
        };
        let out: Vec<byte> = Vec::new();
        out.push(31 as byte);
        out.push(139 as byte);
        out.push(8 as byte);
        out.push(0 as byte);
        out.push(0 as byte);
        out.push(0 as byte);
        out.push(0 as byte);
        out.push(0 as byte);
        out.push(0 as byte);
        out.push(255 as byte);
        let i = 0;
        while i < body.len() {
            out.push(body[i]);
            i = i + 1;
        }
        put_u32_le(out, crc32(data));
        put_u32_le(out, data.len() & u32_mask());
        return out;
    }

    /// Decompresses one gzip member (RFC 1952) and checks its trailer.
    ///
    /// The header may carry the optional extra field, file name, comment and
    /// header CRC; they are skipped, not returned. The last 8 bytes of `data`
    /// are taken as the CRC32 and ISIZE trailer, so `data` must hold exactly
    /// one member: concatenated members are not supported.
    ///
    /// # Errors
    ///
    /// Returns `GzipError::Invalid` for a short or truncated input, wrong magic
    /// bytes, a method other than DEFLATE, reserved flag bits, a malformed
    /// DEFLATE body, or a CRC32 or length that does not match the output.
    ///
    /// # Examples
    ///
    /// ```
    /// use gzip::{Gzip};
    /// use string::{to_bytes};
    /// # use tests::assert;
    /// let gz = Gzip::compress(to_bytes("hello")).ok() ?? Vec::new();
    /// assert!((Gzip::decompress(gz).ok() ?? Vec::new()) == to_bytes("hello"));
    /// // Flip a body byte: the CRC check (or the inflater) rejects it.
    /// gz[12] = (gz[12] as int ^ 1) as byte;
    /// assert!(Gzip::decompress(gz).is_err());
    /// ```
    pub static fn decompress(Vec<byte> data) -> Result<Vec<byte>, GzipError> {
        let start = header_end(data)?;
        if start + 8 > data.len() {
            raise invalid("truncated member");
        }
        let trail = data.len() - 8;
        let body = slice_bytes(data, start, trail);
        let out = inflate_raw(body)?;
        let crc_got = get_u32_le(data, trail);
        let isize_got = get_u32_le(data, trail + 4);
        if crc_got != crc32(out) {
            raise invalid("bad crc");
        }
        if isize_got != (out.len() & u32_mask()) {
            raise invalid("bad isize");
        }
        return out;
    }
}

/// Wraps `data` in a single gzip member (RFC 1952). Same as `Gzip::compress`.
///
/// The body is raw DEFLATE from the `deflate` package; the trailer is the
/// CRC32 and length of `data`.
///
/// # Errors
///
/// Returns `GzipError::Invalid` only if the DEFLATE encoder fails, which it
/// does not today.
///
/// # Examples
///
/// ```
/// use gzip::{compress, decompress};
/// use string::{to_bytes, from_bytes};
/// # use tests::assert;
/// let gz = compress(to_bytes("hello hello hello hello")).ok() ?? Vec::new();
/// let back = decompress(gz).ok() ?? Vec::new();
/// assert!((from_bytes(back).ok() ?? "") == "hello hello hello hello");
/// ```
fn compress(Vec<byte> data) -> Result<Vec<byte>, GzipError> {
    return Gzip::compress(data)?;
}

/// Decompresses one gzip member (RFC 1952) and checks its CRC32 and length.
/// Same as `Gzip::decompress`.
///
/// Reads members from other gzip writers too, including headers with a file
/// name, comment, extra field or header CRC. `data` must hold exactly one
/// member.
///
/// # Errors
///
/// Returns `GzipError::Invalid` when the input is truncated, is not a gzip
/// member, has a malformed body, or fails the CRC32 or length check. It never
/// panics on bad input.
///
/// # Examples
///
/// ```
/// use gzip::{compress, decompress, GzipError};
/// use string::{to_bytes};
/// # use tests::assert;
/// fn roundtrip(Vec<byte> data) -> Result<Vec<byte>, GzipError> {
///     return decompress(compress(data)?)?;
/// }
///
/// fn main() {
///     let src = to_bytes("abracadabra");
///     assert!((roundtrip(src).ok() ?? Vec::new()) == src);
///     assert!(decompress(Vec::new()).is_err());
/// }
/// ```
fn decompress(Vec<byte> data) -> Result<Vec<byte>, GzipError> {
    return Gzip::decompress(data)?;
}
