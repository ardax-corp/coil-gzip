// Round-trip gzip compress/decompress and header magic.
use tests::assert;
use string::{to_bytes};
use gzip::{compress, decompress, Gzip, GzipError};

fn eq_bytes(Vec<byte> a, Vec<byte> b) -> bool {
    if a.len() != b.len() {
        return false;
    }
    let i = 0;
    while i < a.len() {
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

fn roundtrip(Vec<byte> src) -> bool {
    let (cok, gz) = take_ok(compress(src));
    if !cok {
        return false;
    }
    let (dok, out) = take_ok(decompress(gz));
    if !dok {
        return false;
    }
    if !eq_bytes(src, out) {
        return false;
    }
    let (cok2, also) = take_ok(Gzip::compress(src));
    if !cok2 {
        return false;
    }
    let (dok2, out2) = take_ok(Gzip::decompress(also));
    if !dok2 {
        return false;
    }
    return eq_bytes(src, out2);
}

fn repeat_byte(byte c, int n) -> Vec<byte> {
    let out: Vec<byte> = Vec::new();
    let i = 0;
    while i < n {
        out.push(c);
        i = i + 1;
    }
    return out;
}

test("empty roundtrip") {
    let src: Vec<byte> = Vec::new();
    assert!(roundtrip(src), "empty");
}

test("hello roundtrip") {
    assert!(roundtrip(to_bytes("hello")), "hello");
}

test("repeated bytes roundtrip") {
    assert!(roundtrip(repeat_byte("a" as byte, 100)), "repeats");
}

test("pangram roundtrip") {
    assert!(roundtrip(to_bytes("The quick brown fox jumps over the lazy dog")), "pangram");
}

test("gzip magic 1f 8b") {
    let (ok, gz) = take_ok(compress(to_bytes("hello")));
    assert!(ok, "compress");
    assert!(gz.len() >= 10, "header");
    assert!((gz[0] as int) == 31, "id1");
    assert!((gz[1] as int) == 139, "id2");
    assert!((gz[2] as int) == 8, "cm");
}
