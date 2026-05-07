# openvpn-aws

Patched OpenVPN for AWS Client VPN with SAML authentication.

Standard OpenVPN has buffer sizes too small for AWS SAML tokens (128-byte password field, 2KB TLS channel). This build increases all relevant buffers to handle the full SAML assertion flow.

## Patches

| Patch | Purpose |
|-------|---------|
| `aws.patch` | Increases buffer sizes for SAML auth (password 128→128KB, TLS channel 2KB→256KB, options 256→128KB, u16→u32 string encoding) |
| `0001-unprivileged.patch` | Runs OpenVPN as unprivileged user with ambient capabilities (systemd) |

Base version: **OpenVPN 2.6.12**

## Build (Arch Linux)

```bash
makepkg -s
sudo pacman -U openvpn-aws-*.pkg.tar.zst
```

This installs `/usr/bin/openvpn-aws`, coexisting with the stock `openvpn` package.

## Buffer Changes (aws.patch)

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
