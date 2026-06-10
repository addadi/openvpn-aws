# openvpn-aws

Patched OpenVPN for AWS Client VPN with SAML authentication.

Standard OpenVPN has buffer sizes too small for AWS SAML tokens (128-byte password field, 2KB TLS channel), and does not understand the 3-byte prefix AWS Client VPN servers put on control channel messages. This build fixes both.

Base version: **OpenVPN 2.7.4** (pinned in `Makefile` as `OPENVPN_VERSION`; consumed by the [awsvpn](https://github.com/addadi/awsvpn) client via `OPENVPN_AWS_VERSION`). The 2.6.x patch variants are kept for building legacy 2.6.20.

## Patches

Each patch has a 2.6.x and a 2.7.x variant; the right one is selected automatically from the version being built.

| Patch (2.6.x / 2.7.x) | Purpose |
|-------|---------|
| `aws.patch` / `aws-2.7.x.patch` | Increases buffer sizes for SAML auth (password 128→128KB, TLS channel 2KB→256KB, options 256→128KB, u16→u32 string encoding) |
| `patches/push-reply-prefix-fix.patch` / `patches/push-reply-prefix-fix-2.7.x.patch` | Handles AWS Client VPN's 3-byte prefixed control channel messages (`PUSH_REPLY`, `AUTH_FAILED`) — without it the tunnel comes up with no routes |
| `0001-unprivileged.patch` / `0001-unprivileged-2.7.x.patch` | Runs OpenVPN as unprivileged user with ambient capabilities (systemd) |

## CI / Release flow

`.github/workflows/build.yml`:

1. **check-upstream** — on push, weekly cron, or manual dispatch. Builds when the `Makefile` pin differs from `LAST_BUILT_VERSION` (or when a version is given via dispatch input); no-op when they match.
2. **build** — downloads the upstream tarball from GitHub, **verifies its sha256 against the checked-in `upstream-sha256sums`** (fail-closed), applies the version-appropriate patch set (any patch failure fails the build), compiles, smoke-tests that the prefix-fix symbols are present in the compiled objects.
3. **release** — publishes the binary (`openvpn-aws-<version>-x86_64`) and a per-release `SHA256SUMS` as GitHub release assets, then commits the new `LAST_BUILT_VERSION`. Skipped when the release tag already exists and matches `LAST_BUILT_VERSION`, so an already-released version is never re-published.
4. **patch-conflict** — on build failure, files an issue asking for a patch rebase.

To build a new upstream version: add its tarball hash to `upstream-sha256sums`, bump `OPENVPN_VERSION` in the `Makefile`, and push (or use `workflow_dispatch` with the version input).

## Local build (any distro)

```bash
make            # fetch + verify + patch + build -> ./openvpn-aws
make patch OPENVPN_VERSION=2.6.20   # legacy version, picks the 2.6.x patches
sudo make install                   # /usr/local/bin/openvpn-aws
```

## Arch Linux package (PKGBUILD)

The `PKGBUILD` builds the same 2.7.4 + full patch set (unprivileged + aws + push-reply-prefix-fix) from the signed upstream git tag (`?signed`, verified against `validpgpkeys`):

```bash
makepkg -s
sudo pacman -U openvpn-aws-*.pkg.tar.zst
```

This installs `/usr/bin/openvpn-aws`, coexisting with the stock `openvpn` package.

## Buffer Changes (aws.patch / aws-2.7.x.patch)

| Constant | Stock | Patched | File |
|----------|-------|---------|------|
| `USER_PASS_LEN` | 128 | 128KB | `misc.h` |
| `TLS_CHANNEL_BUF_SIZE` | 2KB | 256KB | `common.h` |
| `OPTION_PARM_SIZE` | 256 | 128KB | `options.h` |
| `OPTION_LINE_SIZE` | 256 | 128KB | `options.h` |
| `ERR_BUF_SIZE` | 1280 | 256KB | `error.h` |
| `BUF_SIZE_MAX` | 1MB | 2MB | `buffer.h` |

Additionally: `buf_write_u16` → `buf_write_u32` for string lengths, and key length prefix in `key_method_2_write`.

## License

GPL-2.0 — same as upstream OpenVPN.
