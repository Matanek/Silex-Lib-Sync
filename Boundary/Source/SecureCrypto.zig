const std = @import("std");

const ChaCha20Poly1305 = std.crypto.aead.chacha_poly.ChaCha20Poly1305;
const HkdfSha256 = std.crypto.kdf.hkdf.HkdfSha256;
const X25519 = std.crypto.dh.X25519;

export fn sync_secure_public_key(
    secret_pointer: [*]const u8,
    output_pointer: [*]u8,
) callconv(.c) i32 {
    const secret = secret_pointer[0..X25519.secret_length].*;
    const public_key = X25519.recoverPublicKey(secret) catch return 1;
    @memcpy(output_pointer[0..X25519.public_length], &public_key);
    return 0;
}

export fn sync_secure_shared_secret(
    secret_pointer: [*]const u8,
    public_pointer: [*]const u8,
    output_pointer: [*]u8,
) callconv(.c) i32 {
    const secret = secret_pointer[0..X25519.secret_length].*;
    const public_key = public_pointer[0..X25519.public_length].*;
    const shared = X25519.scalarmult(secret, public_key) catch return 1;
    @memcpy(output_pointer[0..X25519.shared_length], &shared);
    return 0;
}

export fn sync_secure_derive(
    input_pointer: [*]const u8,
    input_count: u64,
    salt_pointer: [*]const u8,
    salt_count: u64,
    context_pointer: [*]const u8,
    context_count: u64,
    output_pointer: [*]u8,
    output_count: u64,
) callconv(.c) i32 {
    const input_length = std.math.cast(usize, input_count) orelse return 1;
    const salt_length = std.math.cast(usize, salt_count) orelse return 1;
    const context_length = std.math.cast(usize, context_count) orelse return 1;
    const output_length = std.math.cast(usize, output_count) orelse return 1;
    if (output_length > HkdfSha256.prk_length * 255) return 1;

    const key = HkdfSha256.extract(
        salt_pointer[0..salt_length],
        input_pointer[0..input_length],
    );
    HkdfSha256.expand(
        output_pointer[0..output_length],
        context_pointer[0..context_length],
        key,
    );
    return 0;
}

export fn sync_secure_seal(
    key_pointer: [*]const u8,
    nonce_pointer: [*]const u8,
    associated_pointer: [*]const u8,
    associated_count: u64,
    message_pointer: [*]const u8,
    message_count: u64,
    ciphertext_pointer: [*]u8,
    tag_pointer: [*]u8,
) callconv(.c) i32 {
    const associated_length = std.math.cast(usize, associated_count) orelse return 1;
    const message_length = std.math.cast(usize, message_count) orelse return 1;
    const key = key_pointer[0..ChaCha20Poly1305.key_length].*;
    const nonce = nonce_pointer[0..ChaCha20Poly1305.nonce_length].*;
    var tag: [ChaCha20Poly1305.tag_length]u8 = undefined;
    ChaCha20Poly1305.encrypt(
        ciphertext_pointer[0..message_length],
        &tag,
        message_pointer[0..message_length],
        associated_pointer[0..associated_length],
        nonce,
        key,
    );
    @memcpy(tag_pointer[0..ChaCha20Poly1305.tag_length], &tag);
    return 0;
}

export fn sync_secure_open(
    key_pointer: [*]const u8,
    nonce_pointer: [*]const u8,
    associated_pointer: [*]const u8,
    associated_count: u64,
    ciphertext_pointer: [*]const u8,
    ciphertext_count: u64,
    tag_pointer: [*]const u8,
    message_pointer: [*]u8,
) callconv(.c) i32 {
    const associated_length = std.math.cast(usize, associated_count) orelse return 1;
    const ciphertext_length = std.math.cast(usize, ciphertext_count) orelse return 1;
    const key = key_pointer[0..ChaCha20Poly1305.key_length].*;
    const nonce = nonce_pointer[0..ChaCha20Poly1305.nonce_length].*;
    const tag = tag_pointer[0..ChaCha20Poly1305.tag_length].*;
    ChaCha20Poly1305.decrypt(
        message_pointer[0..ciphertext_length],
        ciphertext_pointer[0..ciphertext_length],
        tag,
        associated_pointer[0..associated_length],
        nonce,
        key,
    ) catch return 2;
    return 0;
}
