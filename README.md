# openvpn-aws

Patched OpenVPN binary for AWS Client VPN with SAML authentication.

AWS Client VPN uses SAML assertions that can exceed standard OpenVPN's buffer sizes
(128-byte password field, 2KB TLS channel, 256-byte option parameters). This project
applies patches to increase these buffers to 128KB–256KB and switches TLS string
encoding from `u16` to `u32`, enabling the full SAML assertion flow.

**This is just the binary.** You also need:
- A SAML authentication helper (opens browser, captures assertion via localhost redirect)
- Connection scripts (manage OpenVPN lifecycle, reconnection, DNS/routing)
- Optional: NetworkManager integration, WireGuard coexistence

## Downloads

Pre-built binaries from [GitHub Releases](https://github.com/addadi/openvpn-aws/releases).

Two release channels tracking upstream [OpenVPN](https://github.com/OpenVPN/openvpn) releases:
- **2.6.x** — Based on [OpenVPN 2.6.x](https://github.com/OpenVPN/openvpn/releases/tag/v2.6.12) (well-tested, production use)
- **2.7.x** — Based on [OpenVPN 2.7.x](https://github.com/OpenVPN/openvpn/releases/tag/v2.7.4) (newer upstream, needs testing)

## Patches

Based on [OpenVPN](https://github.com/OpenVPN/openvpn) — patches are applied to upstream source tarballs, not a fork.

Organized per upstream release series:

| Directory | Version | aws.patch | 0001-unprivileged.patch |
|-----------|---------|-----------|------------------------|
| `patches/2.6.x/` | 2.6.x | Buffer sizes + TLS u16→u32 | systemd unprivileged |
| `patches/2.7.x/` | 2.7.x | TLS u16→u32 only (buffers upstreamed) | systemd unprivileged |

### aws.patch — Buffer Size Increases + TLS Encoding

| Constant | Stock | Patched | File |
|----------|-------|---------|------|
| `USER_PASS_LEN` | 128 | 128KB | `misc.h` |
| `TLS_CHANNEL_BUF_SIZE` | 2KB | 256KB | `common.h` |
| `OPTION_PARM_SIZE` | 256 | 128KB | `options.h` |
| `OPTION_LINE_SIZE` | 256 | 128KB | `options.h` |
| `ERR_BUF_SIZE` | 1280 | 256KB | `error.h` |
| `BUF_SIZE_MAX` | 1MB | 2MB | `buffer.h` |
| `write_string()` | `buf_write_u16` | `buf_write_u32` | `ssl.c` |
| `write_empty_string()` | `buf_write_u16` | `buf_write_u32` | `ssl.c` |
| `key_method_2_write()` | — | u32 length prefix | `ssl.c` |

> Note: 2.7.x already has the buffer size increases upstream. Only the TLS encoding changes are needed.

### 0001-unprivileged.patch — systemd Unprivileged Operation

- Adds `--system` to `systemd-ask-password` (queries system polkit, not user session)
- Adds `User=openvpn` / `Group=network` to systemd service templates
- Adds `AmbientCapabilities=` for fine-grained capability inheritance

## Building

### Local

```bash
make build                           # Default: OpenVPN 2.6.12
make build OPENVPN_VERSION=2.7.4     # Specific version
```

Requires: `autoconf`, `automake`, `libtool`, `libssl-dev`, `liblzo2-dev`, `liblz4-dev`, `libsystemd-dev`.

### CI (GitHub Actions)

Builds both channels on push to master:

| Channel | Version | Release Tag |
|---------|---------|-------------|
| 2.6.x | 2.6.12 | `v2.6.12` |
| 2.7.x | 2.7.4 | `v2.7.4` |

Manual dispatch with version input:

```
gh workflow run build.yml -f version=2.7.4
```

To add a new major.minor version:
1. Create `patches/<major>.<minor>.x/` with adapted patches
2. Run `make build OPENVPN_VERSION=<ver>` locally to verify patches apply
3. Push — CI builds and publishes to GitHub Releases

> **CI does not auto-track upstream releases.** Patches are version-specific and
> must be manually adapted for new major.minor versions. CI will fail cleanly
> if patches don't apply, signaling that updates are needed.

## License

GPL-2.0 — same as upstream OpenVPN.
