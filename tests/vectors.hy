// Known gzip members, CRC/ISIZE checks, and error cases.
use string::{to_bytes};
use gzip::{compress, decompress, crc32, GzipError};

fn is_invalid(Result<Vec<byte>, GzipError> r) -> bool {
    return match r {
        Result::Ok(_) => false,
        Result::Err(e) => match e {
            GzipError::Invalid { message } => message != "",
            default => false,
        },
    };
}

fn eq_bytes(Vec<byte> a, Vec<byte> b) -> bool {
    if len(a) != len(b) {
        return false;
    }
    let i = 0;
    while i < len(a) {
        if a[i] != b[i] {
            return false;
        }
        i = i + 1;
    }
    return true;
}

fn take_ok(Result<Vec<byte>, GzipError> r) -> (bool, Vec<byte>) {
    return match r {
        Result::Ok(v) => (true, v),
        Result::Err(_) => {
            let empty: Vec<byte> = Vec::new();
            (false, empty)
        },
    };
}

fn push_all(Vec<byte> dst, Vec<int> xs) {
    let i = 0;
    while i < len(xs) {
        dst.push(xs[i] as byte);
        i = i + 1;
    }
}

test("python gzip empty") {
    let raw: Vec<byte> = Vec::new();
    let xs: Vec<int> = Vec::new();
    xs.push(31);
    xs.push(139);
    xs.push(8);
    xs.push(0);
    xs.push(0);
    xs.push(0);
    xs.push(0);
    xs.push(0);
    xs.push(2);
    xs.push(3);
    xs.push(3);
    xs.push(0);
    xs.push(0);
    xs.push(0);
    xs.push(0);
    xs.push(0);
    xs.push(0);
    xs.push(0);
    xs.push(0);
    xs.push(0);
    push_all(raw, xs);
    let (ok, out) = take_ok(decompress(raw));
    assert(ok, "inflate")?;
    assert(len(out) == 0, "empty")?;
}

test("crc32 hello") {
    let want: int = 907060870;
    assert(crc32(to_bytes("hello")) == want, "crc hello")?;
}

test("python gzip hello") {
    let raw: Vec<byte> = Vec::new();
    let xs: Vec<int> = Vec::new();
    xs.push(31);
    xs.push(139);
    xs.push(8);
    xs.push(0);
    xs.push(0);
    xs.push(0);
    xs.push(0);
    xs.push(0);
    xs.push(2);
    xs.push(3);
    xs.push(203);
    xs.push(72);
    xs.push(205);
    xs.push(201);
    xs.push(201);
    xs.push(7);
    xs.push(0);
    xs.push(134);
    xs.push(166);
    xs.push(16);
    xs.push(54);
    xs.push(5);
    xs.push(0);
    xs.push(0);
    xs.push(0);
    push_all(raw, xs);
    let (ok, out) = take_ok(decompress(raw));
    assert(ok, "inflate")?;
    assert(eq_bytes(out, to_bytes("hello")), "hello")?;
}

test("gzip fname header") {
    let raw: Vec<byte> = Vec::new();
    let xs: Vec<int> = Vec::new();
    xs.push(31);
    xs.push(139);
    xs.push(8);
    xs.push(8);
    xs.push(0);
    xs.push(0);
    xs.push(0);
    xs.push(0);
    xs.push(2);
    xs.push(255);
    xs.push(120);
    xs.push(0);
    xs.push(203);
    xs.push(200);
    xs.push(4);
    xs.push(0);
    xs.push(172);
    xs.push(42);
    xs.push(147);
    xs.push(216);
    xs.push(2);
    xs.push(0);
    xs.push(0);
    xs.push(0);
    push_all(raw, xs);
    let (ok, out) = take_ok(decompress(raw));
    assert(ok, "inflate")?;
    assert(eq_bytes(out, to_bytes("hi")), "hi")?;
}

test("truncated member is invalid") {
    let (ok, gz) = take_ok(compress(to_bytes("hello")));
    assert(ok, "compress")?;
    let cut: Vec<byte> = Vec::new();
    let i = 0;
    let n = len(gz) - 1;
    while i < n {
        cut.push(gz[i]);
        i = i + 1;
    }
    assert(is_invalid(decompress(cut)), "trunc")?;
}

test("truncated header is invalid") {
    let raw: Vec<byte> = Vec::new();
    raw.push(31 as byte);
    raw.push(139 as byte);
    assert(is_invalid(decompress(raw)), "hdr")?;
}

test("bad magic is invalid") {
    let raw: Vec<byte> = Vec::new();
    raw.push(31 as byte);
    raw.push(138 as byte);
    let i = 0;
    while i < 20 {
        raw.push(0 as byte);
        i = i + 1;
    }
    assert(is_invalid(decompress(raw)), "magic")?;
}

test("bad crc is invalid") {
    let (ok, gz) = take_ok(compress(to_bytes("hello")));
    assert(ok, "compress")?;
    let n = len(gz);
    assert(n >= 8, "trailer")?;
    let bad: Vec<byte> = Vec::new();
    let i = 0;
    while i < n {
        bad.push(gz[i]);
        i = i + 1;
    }
    let last = n - 8;
    let flipped = (bad[last] as int) ^ 1;
    bad[last] = flipped as byte;
    assert(is_invalid(decompress(bad)), "crc")?;
}

test("empty input is invalid") {
    let empty: Vec<byte> = Vec::new();
    assert(is_invalid(decompress(empty)), "empty")?;
}
