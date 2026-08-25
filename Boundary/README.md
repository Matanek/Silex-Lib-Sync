# SecureCrypto boundary

`SecureSession` uses a small C ABI implemented with the audited primitives in
Zig's standard library. The Silex source wrapper lives in
`Module/SecureSession/Crypto.sx`; the complete native source is
`Source/SecureCrypto.zig`.

The checked-in archives were built with Zig 0.16.0 from the package root:

```text
zig build-lib Boundary/Source/SecureCrypto.zig -O ReleaseSmall -target aarch64-macos -femit-bin=Boundary/macos-arm64/libSecureCrypto.a
zig build-lib Boundary/Source/SecureCrypto.zig -O ReleaseSmall -target x86_64-linux -femit-bin=Boundary/linux-x64/libSecureCrypto.a
zig build-lib Boundary/Source/SecureCrypto.zig -O ReleaseSmall -target x86_64-windows -femit-bin=Boundary/windows-x64/SecureCrypto.lib
zig build-lib Boundary/Source/SecureCrypto.zig -O ReleaseSmall -target aarch64-windows -femit-bin=Boundary/windows-arm64/SecureCrypto.lib
```

From `Boundary/`, verify the distributed artifacts with:

```text
shasum -a 256 -c SHA256SUMS.txt
```

Regenerating an archive requires regenerating `SHA256SUMS.txt`, recompiling a
public `SecureSession` consumer for every target and rerunning the native
cryptographic and client/server integration tests before commit.
