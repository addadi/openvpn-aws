pkgname=openvpn-aws
pkgver=2.7.4
pkgrel=1
pkgdesc='An easy-to-use, robust and highly configurable VPN (Virtual Private Network) with AWS extensions'
arch=('x86_64')
url='https://openvpn.net/index.php/open-source.html'
license=('custom')
depends=('libcap-ng' 'libcap-ng.so'
         'libnl' 'libnl-genl-3.so' 'libnl-3.so'
         'lz4'
         'lzo' 'liblzo2.so'
         'openssl' 'libcrypto.so' 'libssl.so'
         'pkcs11-helper' 'libpkcs11-helper.so'
         'systemd-libs' 'libsystemd.so')
optdepends=('easy-rsa: easy CA and certificate handling'
            'pam: authenticate via PAM')
makedepends=('git' 'systemd' 'python-docutils')
install=openvpn.install
validpgpkeys=('F554A3687412CFFEBDEFE0A312F5F7B42F2B01E7'  # OpenVPN - Security Mailing List <security@openvpn.net>
              'B62E6A2B4E56570B7BDC6BE01D829EFECA562812') # Gert Doering <gert@v6.de>
source=("git+https://github.com/OpenVPN/openvpn.git#tag=v${pkgver}?signed"
        '0001-unprivileged-2.7.x.patch'
        'sysusers.conf'
        'tmpfiles.conf'
        'aws-2.7.x.patch'
        'patches/push-reply-prefix-fix-2.7.x.patch')
sha256sums=('SKIP'
            '1b3e5e4b941b70b9f882c3b7b261f61f8c614a6bcb073af6868ad5013e6c7574'
            '15669f82ac8b412eb3840ba9b39de20ca9b04bf082516c229577a5cb4e1a9610'
            'b1436f953a4f1be7083711d11928a9924993f940ff56ff92d288d6100df673fc'
            '209be9322d073991f70816af21a4566567016faab8462a3274ac1e579cfb7ea4'
            '5b75eec8549e009f49ab4edab651aa42632e5a4fc0e78169cb664ddc9c723bb5')

prepare() {
  cd "${srcdir}"/${pkgname%-aws}

  # https://www.mail-archive.com/openvpn-devel@lists.sourceforge.net/msg19302.html
  sed -i '/^CONFIGURE_DEFINES=/s/set/env/g' configure.ac

  # start with unprivileged user and keep granted privileges
  patch -Np1 < ../0001-unprivileged-2.7.x.patch
  # large SAML token buffers for AWS Client VPN
  patch -Np1 < ../aws-2.7.x.patch
  # AWS control channel 3-byte prefix handling (PUSH_REPLY / AUTH_FAILED)
  patch -Np1 < ../push-reply-prefix-fix-2.7.x.patch

  autoreconf --force --install
}

build() {
  mkdir "${srcdir}"/build
  cd "${srcdir}"/build

  "${srcdir}"/openvpn/configure \
    --prefix=/usr \
    --sbindir=/usr/bin \
    --enable-dco \
    --enable-pkcs11 \
    --enable-plugins \
    --enable-systemd \
    --enable-x509-alt-username
  make
}

check() {
  cd "${srcdir}"/build

  make check
}

package() {
  cd "${srcdir}"/build

  # Install openvpn
  make DESTDIR="${pkgdir}" install

  # Install sysusers and tmpfiles files
  install -D -m0644 ../sysusers.conf "${pkgdir}"/usr/lib/sysusers.d/openvpn.conf
  install -D -m0644 ../tmpfiles.conf "${pkgdir}"/usr/lib/tmpfiles.d/openvpn.conf

  # Install license
  install -d -m0755 "${pkgdir}"/usr/share/licenses/openvpn/
  ln -sf /usr/share/doc/openvpn/{COPYING,COPYRIGHT.GPL} "${pkgdir}"/usr/share/licenses/openvpn/

  cd "${srcdir}"/${pkgname%-aws}

  # Install examples
  install -d -m0755 "${pkgdir}"/usr/share/openvpn
  cp -r sample/sample-config-files "${pkgdir}"/usr/share/openvpn/examples

  # Install contrib
  for FILE in $(find contrib -type f); do
    case "$(file --brief --mime-type --no-sandbox "${FILE}")" in
      "text/x-shellscript")
        install -D -m0755 "${FILE}" "${pkgdir}/usr/share/openvpn/${FILE}" ;;
      *)
        install -D -m0644 "${FILE}" "${pkgdir}/usr/share/openvpn/${FILE}" ;;
    esac
  done
}
