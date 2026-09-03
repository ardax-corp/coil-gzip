// Package root. RFC 1952 gzip member (header + raw DEFLATE + CRC32 + ISIZE).
use deflate::{Deflate, DeflateError};

/// Gzip member failure. `message` is a short reason, not a panic.
enum GzipError {
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

/// IEEE CRC-32 (gzip / ISO 3309), reflected polynomial 0xEDB88320.
fn crc32(Vec<byte> data) -> int {
    let poly = crc_poly();
    let mask = u32_mask();
    let crc = mask;
    let i = 0;
    while i < len(data) {
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
        if p >= len(data) {
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
    if len(data) < 10 {
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
        if i + 2 > len(data) {
            raise invalid("truncated extra");
        }
        let eight: int = 8;
        let xlen = (data[i] as int) | ((data[i + 1] as int) << eight);
        i = i + 2 + xlen;
        if i > len(data) {
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
        if i + 2 > len(data) {
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

/// RFC 1952 codec. `compress` wraps raw DEFLATE; `decompress` checks CRC32 and ISIZE.
class Gzip {
    _unused: int,
}

impl Gzip {
    /// Header (FLG=0) + `Deflate::compress` + CRC32 + ISIZE.
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
        while i < len(body) {
            out.push(body[i]);
            i = i + 1;
        }
        put_u32_le(out, crc32(data));
        put_u32_le(out, len(data) & u32_mask());
        return out;
    }

    /// Parse one gzip member. Trailer is the last 8 bytes (CRC32 + ISIZE).
    pub static fn decompress(Vec<byte> data) -> Result<Vec<byte>, GzipError> {
        let start = header_end(data)?;
        if start + 8 > len(data) {
            raise invalid("truncated member");
        }
        let trail = len(data) - 8;
        let body = slice_bytes(data, start, trail);
        let out = inflate_raw(body)?;
        let crc_got = get_u32_le(data, trail);
        let isize_got = get_u32_le(data, trail + 4);
        if crc_got != crc32(out) {
            raise invalid("bad crc");
        }
        if isize_got != (len(out) & u32_mask()) {
            raise invalid("bad isize");
        }
        return out;
    }
}

/// RFC 1952 compress (`Vec<byte>` → gzip member).
fn compress(Vec<byte> data) -> Result<Vec<byte>, GzipError> {
    return Gzip::compress(data)?;
}

/// RFC 1952 decompress (gzip member → `Vec<byte>`).
fn decompress(Vec<byte> data) -> Result<Vec<byte>, GzipError> {
    return Gzip::decompress(data)?;
}
