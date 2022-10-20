# Maintainer: 7thCore

pkgname=arma3srv-script
pkgver=1.1
pkgrel=2
pkgdesc='Arma 3 server script for running the server on linux.'
arch=('x86_64')
license=('GPL3')
depends=('bash'
         'coreutils'
         'sudo'
         'grep'
         'sed'
         'awk'
         'curl'
         'rsync'
         'wget'
         'findutils'
         'tmux'
         'jq'
         'zip'
         'unzip'
         'p7zip'
         'postfix'
         's-nail'
         'steamcmd')
install=arma3srv-script.install
source=('bash_profile'
        'arma3srv-script.bash'
        'arma3srv-send-notification.service'
        'arma3srv.service'
        'arma3srv-timer-1.service'
        'arma3srv-timer-1.timer'
        'arma3srv-timer-2.service'
        'arma3srv-timer-2.timer')
sha256sums=('f1e2f643b81b27d16fe79e0563e39c597ce42621ae7c2433fd5b70f1eeab5d63'
            'b73d88c2ff0253dfb29602c361bae34691e2da3a5f322160f20b874830eb8c90'
            '3c8c4af7aada541b0bb83e60160f17a985580d43b88fbb8958984026c657e113'
            'e8ccc9821ea89826160867aa63e8000e91f8f4051ae8f3215d78d7403744eaf7'
            'c53ffd7e1b352e91896cb1c59cbd634aa62a4905707a07b3f8d2a31245773e88'
            'b309af027a8465b0584befa786020d6209e125f0995e7ef57fe22ed1432cec92'
            '53a16655371556c5891387b64722892c8cd00acd632ef1f382e1acdf298811c3'
            '9a6ea0b55a90116a43c3b0eaa052eae2a94aeeeba5c26c559fb7dbe86dd522b2')

package() {
  install -d -m0755 "${pkgdir}/usr/bin"
  install -d -m0755 "${pkgdir}/srv/arma3srv"
  install -d -m0755 "${pkgdir}/srv/arma3srv/server"
  install -d -m0755 "${pkgdir}/srv/arma3srv/config"
  install -d -m0755 "${pkgdir}/srv/arma3srv/updates"
  install -d -m0755 "${pkgdir}/srv/arma3srv/backups"
  install -d -m0755 "${pkgdir}/srv/arma3srv/logs"
  install -d -m0755 "${pkgdir}/srv/arma3srv/.config"
  install -d -m0755 "${pkgdir}/srv/arma3srv/.config/systemd"
  install -d -m0755 "${pkgdir}/srv/arma3srv/.config/systemd/user"
  install -D -Dm755 "${srcdir}/arma3srv-script.bash" "${pkgdir}/usr/bin/arma3srv-script"
  install -D -Dm755 "${srcdir}/arma3srv-timer-1.timer" "${pkgdir}/srv/arma3srv/.config/systemd/user/arma3srv-timer-1.timer"
  install -D -Dm755 "${srcdir}/arma3srv-timer-1.service" "${pkgdir}/srv/arma3srv/.config/systemd/user/arma3srv-timer-1.service"
  install -D -Dm755 "${srcdir}/arma3srv-timer-2.timer" "${pkgdir}/srv/arma3srv/.config/systemd/user/arma3srv-timer-2.timer"
  install -D -Dm755 "${srcdir}/arma3srv-timer-2.service" "${pkgdir}/srv/arma3srv/.config/systemd/user/arma3srv-timer-2.service"
  install -D -Dm755 "${srcdir}/arma3srv-send-notification.service" "${pkgdir}/srv/arma3srv/.config/systemd/user/arma3srv-send-notification.service"
  install -D -Dm755 "${srcdir}/arma3srv.service" "${pkgdir}/srv/arma3srv/.config/systemd/user/arma3srv.service"
  install -D -Dm755 "${srcdir}/bash_profile" "${pkgdir}/srv/arma3srv/.bash_profile"
}
