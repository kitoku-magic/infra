#!/bin/bash

#----------------------------------------------------------#
# 本スクリプトは、必ずauto_install_start.sh経由で実行する事
#----------------------------------------------------------#

#----------------------------------------------------------#
# 初期処理
#----------------------------------------------------------#
# 共通関数を読み込む
source ./auto_install_start_functions.sh

# 初期処理
source ./auto_install_start_init.sh 2 "$#" "${1}" "${2}"

check_command_status "初期処理が失敗しました。"

# 各種パラメータ情報を読み込む
source ./parameter_"${1}".conf

# 呼び出し元のチェック
COMMAND_HISTORIES[0]="bash -c source /home/${2}/auto_install_start_by_${2}.sh ${1} ${2}"
COMMAND_HISTORIES[1]="script -c source /home/${2}/auto_install_start_by_${2}.sh ${1} ${2}"

pid=$$
for COMMAND_HISTORY in "${COMMAND_HISTORIES[@]}"
do
  # プロセスIDから、紐づくコマンドを取得
  cmd="$(cat /proc/$pid/cmdline | tr '\0' ' ' | sed 's/<tab>*$\| *$//')"
  echo $cmd
  if [ "$cmd" != "$COMMAND_HISTORY" ]; then
    echo "呼び出し元のコマンド履歴が一致していません。cmd=${cmd}" 1>&2
    exit 1
  fi
  # プロセスIDから、親プロセスIDを取得
  pid=$(awk '/^PPid:/{print $2}' /proc/$pid/status)
done

#----------------------------------------------------------#
# gccのインストール
#----------------------------------------------------------#
echo "gccのインストールを行います。"

print_current_time

mkdir -p /home/${GENERAL_USER_NAME}/src

cd /home/${GENERAL_USER_NAME}/src

curl ${CURL_RETRY_OPTION} -O https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.xz

check_command_status "gccのダウンロードに失敗しました。"

tar Jxvf ./gcc-${GCC_VERSION}.tar.xz

check_command_status "gccファイルの解凍に失敗しました。"

cd gcc-${GCC_VERSION}

change_dnf_package install "${GCC_REQUIRE_PACKAGE}" ${EXEC_USER_NAME}

check_command_status "gccの必須パッケージのインストールに失敗しました。"

./contrib/download_prerequisites

check_command_status "gccのインストールに必要なライブラリのダウンロードに失敗しました。"

mkdir build

cd build

echo "../configure --enable-languages=c,c++ --prefix=/opt/gcc/${GCC_VERSION} --disable-bootstrap --disable-multilib" > ./gcc_ccc

bash ./gcc_ccc

check_command_status "gccのconfigureに失敗しました。"

make

check_command_status "gccのmakeに失敗しました。"

sudo make install

check_command_status "gccのmake installに失敗しました。"

GCC_PACKAGE='gcc gcc-c++'
change_dnf_package remove "${GCC_PACKAGE}" ${EXEC_USER_NAME}

check_command_status "gccパッケージのアンインストールに失敗しました。"

sudo ln -s /opt/gcc/${GCC_VERSION} /opt/gcc/current

sudo cp /etc/profile /etc/profile.org

check_command_status "/etc/profileのバックアップに失敗しました。"

echo 'export PATH=/opt/gcc/current/bin:$PATH' | sudo tee -a /etc/profile

source /etc/profile

check_command_status "gccの/etc/profileの反映に失敗しました。"

cd /opt/gcc/current/lib64/

ls libstdc*-gdb.py | sed -r "s/(libstdc.+-gdb\.py)/sudo mv \1 ignore-\1/g" | bash

echo '/opt/gcc/current/lib64' | sudo tee -a /etc/ld.so.conf.d/gcc.conf

sudo ldconfig

check_command_status "gcc用のldconfigに失敗しました。"

print_current_time

echo "gccのインストールが完了しました。"

#----------------------------------------------------------#
# zlibのインストール
#----------------------------------------------------------#
echo "zlibのインストールを行います。"

print_current_time

cd /home/${GENERAL_USER_NAME}/src

curl ${CURL_RETRY_OPTION} -O https://zlib.net/zlib-${ZLIB_VERSION}.tar.gz

check_command_status "zlibのダウンロードに失敗しました。"

tar zxvf ./zlib-${ZLIB_VERSION}.tar.gz

check_command_status "zlibファイルの解凍に失敗しました。"

cd zlib-${ZLIB_VERSION}

change_dnf_package install "${ZLIB_REQUIRE_PACKAGE}" ${EXEC_USER_NAME}

check_command_status "zlibの必須パッケージのインストールに失敗しました。"

echo "./configure --prefix=/opt/zlib/${ZLIB_VERSION}" > ./zlib_ccc

bash ./zlib_ccc

check_command_status "zlibのconfigureに失敗しました。"

make

check_command_status "zlibのmakeに失敗しました。"

sudo make install

check_command_status "zlibのmake installに失敗しました。"

sudo ln -s /opt/zlib/${ZLIB_VERSION} /opt/zlib/current

echo '/opt/zlib/current/lib' | sudo tee -a /etc/ld.so.conf.d/zlib.conf

sudo ldconfig

check_command_status "zlib用のldconfigに失敗しました。"

export LD_LIBRARY_PATH=/opt/zlib/current/lib

check_command_status "LD_LIBRARY_PATHのexportに失敗しました。"

print_current_time

echo "zlibのインストールが完了しました。"

#----------------------------------------------------------#
# OpenSSLのインストール
#----------------------------------------------------------#
echo "OpenSSLのインストールを行います。"

print_current_time

cd /home/${GENERAL_USER_NAME}/src

curl ${CURL_RETRY_OPTION} -L -O https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz

check_command_status "OpenSSLのダウンロードに失敗しました。"

tar zxvf ./openssl-${OPENSSL_VERSION}.tar.gz

check_command_status "OpenSSLファイルの解凍に失敗しました。"

cd openssl-${OPENSSL_VERSION}

echo "./config --prefix=/opt/openssl/${OPENSSL_VERSION} --openssldir=/opt/openssl/${OPENSSL_VERSION} shared zlib enable-md2" > ./openssl_ccc

change_dnf_package install "${OPENSSL_REQUIRE_PACKAGE}" ${EXEC_USER_NAME}

check_command_status "OpenSSLの必須パッケージのインストールに失敗しました。"

bash ./openssl_ccc

check_command_status "OpenSSLのconfigureに失敗しました。"

make

check_command_status "OpenSSLのmakeに失敗しました。"

sudo make install

check_command_status "OpenSSLのmake installに失敗しました。"

sudo ln -s /opt/openssl/${OPENSSL_VERSION} /opt/openssl/current

sudo mv /opt/openssl/current/ssl /opt/openssl/current/ssl.bk

sudo ln -s /etc/pki/tls /opt/openssl/current/ssl

sudo sed -i -e 's@^\(export PATH=\)\(.\+\)\(\$PATH\)$@\1\2/opt/openssl/current/bin:\3@g' /etc/profile

source /etc/profile

check_command_status "OpenSSLの/etc/profileの反映に失敗しました。"

echo '/opt/openssl/current/lib64' | sudo tee -a /etc/ld.so.conf.d/openssl.conf

sudo ldconfig

check_command_status "OpenSSL用のldconfigに失敗しました。"

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/openssl/current/lib64:/usr/lib:/usr/lib64

check_command_status "LD_LIBRARY_PATHのexportに失敗しました。"

print_current_time

echo "OpenSSLのインストールが完了しました。"

#----------------------------------------------------------#
# OpenSSHのインストール
#----------------------------------------------------------#
echo "OpenSSHのインストールを行います。"

print_current_time

cd /home/${GENERAL_USER_NAME}/src

curl ${CURL_RETRY_OPTION} -O http://www.ftp.ne.jp/OpenBSD/OpenSSH/portable/openssh-${OPENSSH_VERSION}.tar.gz

check_command_status "OpenSSHのダウンロードに失敗しました。"

tar zxvf openssh-${OPENSSH_VERSION}.tar.gz

check_command_status "OpenSSHファイルの解凍に失敗しました。"

cd openssh-${OPENSSH_VERSION}

echo "./configure \
--sysconfdir=/etc/ssh \
--libexecdir=/usr/libexec \
--bindir=/usr/bin \
--sbindir=/usr/sbin \
--with-libedit \
--with-md5-passwords \
--with-pam \
--with-privsep-path=/var/empty/sshd \
--with-ssl-dir=/opt/openssl/current \
--with-ssl-engine \
--with-zlib" > ./openssh_ccc

change_dnf_package install "${OPENSSH_REQUIRE_PACKAGE}" ${EXEC_USER_NAME}

check_command_status "OpenSSHの必須パッケージのインストールに失敗しました。"

bash ./openssh_ccc

check_command_status "OpenSSHのconfigureに失敗しました。"

make

check_command_status "OpenSSHのmakeに失敗しました。"

sudo rm -rf /etc/ssh

sudo make install

check_command_status "OpenSSHのmake installに失敗しました。"

print_current_time

echo "OpenSSHのインストールが完了しました。"

#----------------------------------------------------------#
# SSHの設定
#----------------------------------------------------------#
echo "SSHの設定を行います。"

mkdir ~/.ssh

chmod 700 ~/.ssh

echo $SSH_PUBLIC_KEY > ~/${SSH_AUTHORIZED_KEYS_FILE}

chmod 600 ~/${SSH_AUTHORIZED_KEYS_FILE}

cat <<EOF | sudo tee /etc/sysconfig/sshd
# Configuration file for the sshd service.

# The server keys are automatically generated if they are missing.
# To change the automatic creation uncomment and change the appropriate
# line. Accepted key types are: DSA RSA ECDSA ED25519.
# The default is "RSA ECDSA ED25519"

# AUTOCREATE_SERVER_KEYS=""
# AUTOCREATE_SERVER_KEYS="RSA ECDSA ED25519"

# Do not change this option unless you have hardware random
# generator and you REALLY know what you are doing

SSH_USE_STRONG_RNG=0
# SSH_USE_STRONG_RNG=1
EOF

sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.org

check_command_status "ssh設定ファイルのバックアップに失敗しました。"

PORT='Port'
SYSLOG_FACILITY='SyslogFacility'
LOG_LEVEL='LogLevel'
LOGIN_GRACE_TIME='LoginGraceTime'
PERMIT_ROOT_LOGIN='PermitRootLogin'
STRICT_MODES='StrictModes'
MAX_AUTH_TRIES='MaxAuthTries'
MAX_SESSIONS='MaxSessions'
PUBKEY_AUTHENTICATION='PubkeyAuthentication'
AUTHORIZED_KEYS_FILE='AuthorizedKeysFile'
HOSTBASED_AUTHENTICATION='HostbasedAuthentication'
IGNORE_USER_KNOWN_HOSTS='IgnoreUserKnownHosts'
IGNORE_RHOSTS='IgnoreRhosts'
PERMIT_EMPTY_PASSWORDS='PermitEmptyPasswords'
PASSWORD_AUTHENTICATION='PasswordAuthentication'
CHALLENGE_RESPONSE_AUTHENTICATION='ChallengeResponseAuthentication'
USE_PAM='UsePAM'
TCP_KEEP_ALIVE='TCPKeepAlive'
CLIENT_ALIVE_INTERVAL='ClientAliveInterval'
CLIENT_ALIVE_COUNT_MAX='ClientAliveCountMax'
ALLOW_GROUPS='AllowGroups'

declare -a SSH_KEY_SETTINGS=(
  ${PORT}
  ${SYSLOG_FACILITY}
  ${LOG_LEVEL}
  ${LOGIN_GRACE_TIME}
  ${PERMIT_ROOT_LOGIN}
  ${STRICT_MODES}
  ${MAX_AUTH_TRIES}
  ${MAX_SESSIONS}
  ${PUBKEY_AUTHENTICATION}
  ${AUTHORIZED_KEYS_FILE}
  ${HOSTBASED_AUTHENTICATION}
  ${IGNORE_USER_KNOWN_HOSTS}
  ${IGNORE_RHOSTS}
  ${PERMIT_EMPTY_PASSWORDS}
  ${PASSWORD_AUTHENTICATION}
  ${CHALLENGE_RESPONSE_AUTHENTICATION}
  ${USE_PAM}
  ${TCP_KEEP_ALIVE}
  ${CLIENT_ALIVE_INTERVAL}
  ${CLIENT_ALIVE_COUNT_MAX}
  ${ALLOW_GROUPS}
)

declare -A SSH_SETTINGS

SSH_SETTINGS[${PORT}]=$SSH_PORT
SSH_SETTINGS[${SYSLOG_FACILITY}]=$SSH_SYSLOG_FACILITY
SSH_SETTINGS[${LOG_LEVEL}]=$SSH_LOG_LEVEL
SSH_SETTINGS[${LOGIN_GRACE_TIME}]=$SSH_LOGIN_GRACE_TIME
SSH_SETTINGS[${PERMIT_ROOT_LOGIN}]=$SSH_PERMIT_ROOT_LOGIN
SSH_SETTINGS[${STRICT_MODES}]=$SSH_STRICT_MODES
SSH_SETTINGS[${MAX_AUTH_TRIES}]=$SSH_MAX_AUTHTRIES
SSH_SETTINGS[${MAX_SESSIONS}]=$SSH_MAX_SESSIONS
SSH_SETTINGS[${PUBKEY_AUTHENTICATION}]=$SSH_PUBKEY_AUTHENTICATION
SSH_SETTINGS[${AUTHORIZED_KEYS_FILE}]=$SSH_AUTHORIZED_KEYS_FILE
SSH_SETTINGS[${HOSTBASED_AUTHENTICATION}]=$SSH_HOSTBASED_AUTHENTICATION
SSH_SETTINGS[${IGNORE_USER_KNOWN_HOSTS}]=$SSH_IGNORE_USER_KNOWN_HOSTS
SSH_SETTINGS[${IGNORE_RHOSTS}]=$SSH_IGNORE_RHOSTS
SSH_SETTINGS[${PERMIT_EMPTY_PASSWORDS}]=$SSH_PERMIT_EMPTY_PASSWORDS
SSH_SETTINGS[${PASSWORD_AUTHENTICATION}]=$SSH_PASSWORD_AUTHENTICATION
SSH_SETTINGS[${CHALLENGE_RESPONSE_AUTHENTICATION}]=$SSH_CHALLENGE_RESPONSE_AUTHENTICATION
SSH_SETTINGS[${USE_PAM}]=$SSH_USE_PAM
SSH_SETTINGS[${TCP_KEEP_ALIVE}]=$SSH_TCP_KEEP_ALIVE
SSH_SETTINGS[${CLIENT_ALIVE_INTERVAL}]=$SSH_CLIENT_ALIVE_INTERVAL
SSH_SETTINGS[${CLIENT_ALIVE_COUNT_MAX}]=$SSH_CLIENT_ALIVE_COUNTMAX
SSH_SETTINGS[${ALLOW_GROUPS}]=$SSH_ALLOW_GROUPS

for k in ${SSH_KEY_SETTINGS[@]}
do
  sudo sed -i -e "/^${k}\s\+.*/s/^/# /g" /etc/ssh/sshd_config

  check_command_status "SSHの${k}のコメントアウトに失敗しました。"

  echo "${k} ${SSH_SETTINGS[$k]}" | sudo tee -a /etc/ssh/sshd_config

  check_command_status "SSHの${k}の設定に失敗しました。"
done

SSHD_CONFIG_CHECK_RESULT=`sudo sshd -t`

check_command_status "SSHD_CONFIGの構文チェックの実行結果ステータスが不正です。"

if [ "$SSHD_CONFIG_CHECK_RESULT" != "" ]; then
  echo "SSHD_CONFIGの構文チェックで以下のエラーが発生しました。"
  echo "$SSHD_CONFIG_CHECK_RESULT"
  exit 1
fi

cat <<EOF | sudo tee /etc/systemd/system/sshd-keygen.service
[Unit]
Description=OpenSSH Server Key Generation
ConditionFileNotEmpty=|!/etc/ssh/ssh_host_rsa_key
ConditionFileNotEmpty=|!/etc/ssh/ssh_host_ecdsa_key
ConditionFileNotEmpty=|!/etc/ssh/ssh_host_ed25519_key
PartOf=sshd.service sshd.socket

[Service]
ExecStart=/usr/sbin/sshd-keygen
Type=oneshot
RemainAfterExit=yes
EOF

cat <<'EOF' | sudo tee /etc/systemd/system/sshd.service
[Unit]
Description=OpenSSH server daemon
Documentation=man:sshd(8) man:sshd_config(5)
After=network.target sshd-keygen.service
Wants=sshd-keygen.service

[Service]
Type=simple
EnvironmentFile=/etc/sysconfig/sshd
ExecStart=/usr/sbin/sshd -D $OPTIONS
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=on-failure
RestartSec=42s

[Install]
WantedBy=multi-user.target
EOF

cat <<'EOF' | sudo tee /etc/systemd/system/sshd@.service
[Unit]
Description=OpenSSH per-connection server daemon
Documentation=man:sshd(8) man:sshd_config(5)
Wants=sshd-keygen.service
After=sshd-keygen.service

[Service]
EnvironmentFile=-/etc/sysconfig/sshd
ExecStart=-/usr/sbin/sshd -i $OPTIONS
StandardInput=socket
EOF

cat <<EOF | sudo tee /etc/systemd/system/sshd.socket
[Unit]
Description=OpenSSH Server Socket
Documentation=man:sshd(8) man:sshd_config(5)
Conflicts=sshd.service

[Socket]
ListenStream=${SSH_SETTINGS['Port']}
Accept=yes

[Install]
WantedBy=sockets.target
EOF

sudo systemctl restart sshd.service

check_command_status "OpenSSHの起動に失敗しました。"

sudo systemctl enable sshd.service

check_command_status "OpenSSHの自動起動の設定に失敗しました。"

echo "SSH用の公開鍵認証の設定が完了しました。"

#----------------------------------------------------------#
# nftables（ファイアウォール）の基本設定と反映
# @see https://wiki.archlinux.jp/index.php/Nftables#.E3.83.92.E3.83.B3.E3.83.88.E3.81.A8.E3.83.86.E3.82.AF.E3.83.8B.E3.83.83.E3.82.AF
# @see https://thinca.hatenablog.com/entry/nftables-settings-memo-2020
# @see https://bogamp.hatenablog.com/entry/2024/10/27/032444
#----------------------------------------------------------#
echo "nftables（ファイアウォール）の基本設定と反映を行います。"

# nftの初期化
sudo nft flush ruleset

# テーブル作成
sudo nft add table ip my_nft4_table

sudo nft add table ip6 my_nft6_table

# チェイン作成
sudo nft add chain ip my_nft4_table input { type filter hook input priority 0 \; policy drop \; }

sudo nft add chain ip my_nft4_table forward { type filter hook forward priority 0 \;  policy drop \; }

sudo nft add chain ip my_nft4_table output { type filter hook output priority 0 \; policy accept \; }

sudo nft add chain ip6 my_nft6_table input { type filter hook input priority 0 \; policy drop \; }

sudo nft add chain ip6 my_nft6_table forward { type filter hook forward priority 0 \;  policy drop \; }

sudo nft add chain ip6 my_nft6_table output { type filter hook output priority 0 \; policy accept \; }

sudo nft add chain ip my_nft4_table TCP

sudo nft add chain ip6 my_nft6_table TCPV6

# セット作成
sudo nft add set ip my_nft4_table ssh_dos_counter { type ipv4_addr\; size 65535\; flags dynamic\; }

# IPv4ルール作成

sudo nft add rule ip my_nft4_table input ct state related,established accept

sudo nft add rule ip my_nft4_table input ct state invalid drop

sudo nft add rule ip my_nft4_table input iif lo accept

sudo nft add rule ip my_nft4_table input meta l4proto icmp accept

sudo nft add rule ip my_nft4_table input ip protocol icmp icmp type echo-request ct state new accept

sudo nft add rule ip my_nft4_table input ip protocol tcp tcp flags \& \(fin\|syn\|rst\|ack\) == syn jump TCP

sudo nft add rule ip my_nft4_table input ip protocol tcp reject with tcp reset

sudo nft add rule ip my_nft4_table input counter reject with icmp type port-unreachable

sudo nft add rule ip my_nft4_table input counter reject with icmp type host-prohibited

sudo nft add rule ip my_nft4_table TCP tcp dport ${SSH_SETTINGS['Port']} update @ssh_dos_counter { ip saddr ct count over 2 } log prefix \"SSH Attacked:\" drop

sudo nft add rule ip my_nft4_table TCP tcp dport ${SSH_SETTINGS['Port']} accept

# IPv6ルール作成

sudo nft add rule ip6 my_nft6_table input ct state related,established accept

sudo nft add rule ip6 my_nft6_table input ct state invalid drop

sudo nft add rule ip6 my_nft6_table input iif lo accept

sudo nft add rule ip6 my_nft6_table input meta l4proto ipv6-icmp accept

sudo nft add rule ip6 my_nft6_table input icmpv6 type echo-request ct state new accept

sudo nft add rule ip6 my_nft6_table input tcp flags \& \(fin\|syn\|rst\|ack\) == syn jump TCPV6

sudo nft add rule ip6 my_nft6_table input reject with tcp reset

sudo nft add rule ip6 my_nft6_table input counter reject with icmpv6 type port-unreachable

sudo nft add rule ip6 my_nft6_table input counter reject with icmpv6 type admin-prohibited

sudo systemctl stop firewalld.service

check_command_status "firewalldの停止に失敗しました。"

sudo systemctl disable firewalld.service

check_command_status "firewalldの自動起動の停止に失敗しました。"

sudo systemctl start nftables.service

check_command_status "nftablesの起動に失敗しました。"

sudo systemctl enable nftables.service

check_command_status "nftablesの自動起動の設定に失敗しました。"

echo "nftables（ファイアウォール）の基本設定と反映が完了しました。"

#----------------------------------------------------------#
# 環境変数などの設定
#----------------------------------------------------------#
echo "環境変数などの設定を行います。"

sudo cp /etc/locale.conf /etc/locale.conf.org

check_command_status "/etc/locale.confのバックアップに失敗しました。"

sudo localectl set-locale LANG=ja_JP.UTF-8

source /etc/locale.conf

echo 'export HISTSIZE=10000' | sudo tee -a /etc/profile
echo 'export HISTFILESIZE=100000' | sudo tee -a /etc/profile
echo "export HISTTIMEFORMAT='%Y/%m/%d %H:%M:%S '" | sudo tee -a /etc/profile

source /etc/profile

sudo cp /etc/bashrc /etc/bashrc.org

check_command_status "/etc/bashrcのバックアップに失敗しました。"

echo "alias mv='mv -i'" | sudo tee -a /etc/bashrc
echo "alias cp='cp -i'" | sudo tee -a /etc/bashrc
echo "alias rm='rm -i'" | sudo tee -a /etc/bashrc

source /etc/bashrc

cp /home/${GENERAL_USER_NAME}/.bashrc /home/${GENERAL_USER_NAME}/.bashrc.org

check_command_status "${GENERAL_USER_NAME}のbashrcのバックアップに失敗しました。"

echo 'alias sudo='\''sudo env PATH=$PATH'\' | tee -a /home/${GENERAL_USER_NAME}/.bashrc

source /home/${GENERAL_USER_NAME}/.bashrc

echo "環境変数などの設定が完了しました。"

#----------------------------------------------------------#
# logrotateの設定
#----------------------------------------------------------#
echo "logrotateの設定を行います。"

cat <<'EOF' | sudo tee /etc/cron.daily/logrotate
#!/bin/sh

/usr/sbin/logrotate -s /var/lib/logrotate/logrotate.status /etc/logrotate.conf
EXITVALUE=$?
if [ $EXITVALUE != 0 ]; then
    /usr/bin/logger -t logrotate "ALERT exited abnormally with [$EXITVALUE]"
fi
exit 0
EOF

sudo cp /etc/logrotate.conf /etc/logrotate.conf.org

check_command_status "logrotateの設定ファイルのバックアップに失敗しました。"

sudo sed -i -e 's/^weekly.*/daily/g' /etc/logrotate.conf
sudo sed -i -e 's/^\(rotate\s\)[0-9]\+$/\1365/g' /etc/logrotate.conf

echo "logrotateの設定が完了しました。"

#----------------------------------------------------------#
# cronの設定
#----------------------------------------------------------#
echo "cronの設定を行います。"

sudo cp /etc/crontab /etc/crontab.org

check_command_status "crontabの設定ファイルのバックアップに失敗しました。"

sudo sed -i -e "s/^\(MAILTO=\).\+$/\1${SYSTEM_ADMINISTRATOR_MAIL_ADDRESS}/g" /etc/crontab

# 後で修正するのでコメントアウトしておく
echo '######comment_out! 00 00 * * * root /etc/cron.daily/logrotate' | sudo tee -a /etc/crontab
echo '######comment_out! 00 04 * * * root run-parts /etc/cron.daily' | sudo tee -a /etc/crontab

echo "cronの設定が完了しました。"

#----------------------------------------------------------#
# vimのインストール
#----------------------------------------------------------#
echo "vimのインストールを行います。"

print_current_time

cd /home/${GENERAL_USER_NAME}/src

change_dnf_package install "${VIM_REQUIRE_PACKAGE}" ${EXEC_USER_NAME}

check_command_status "vimの必須パッケージのインストールに失敗しました。"

curl ${CURL_RETRY_OPTION} -O https://ftp.nluug.nl/pub/vim/unix/vim-${VIM_VERSION}.tar.bz2

check_command_status "vimのダウンロードに失敗しました。"

tar jxvf vim-${VIM_VERSION}.tar.bz2

check_command_status "vimファイルの解凍に失敗しました。"

cd vim${VIM_VERSION//./}

echo "./configure \
--prefix=/opt/vim/${VIM_VERSION} \
--with-features=huge \
--with-x \
--disable-selinux \
--enable-cscope \
--enable-fail-if-missing \
--enable-fontset \
--enable-gui=${VIM_GUI_TOOL} \
--enable-multibyte \
--enable-xim" > ./vim_ccc

bash ./vim_ccc

check_command_status "vimのconfigureに失敗しました。"

make

check_command_status "vimのmakeに失敗しました。"

sudo make install

check_command_status "vimのmake installに失敗しました。"

sudo ln -s /opt/vim/${VIM_VERSION} /opt/vim/current

sudo sed -i -e 's@^\(export PATH=\)\(.\+\)\(\$PATH\)$@\1\2/opt/vim/current/bin:\3@g' /etc/profile

source /etc/profile

check_command_status "vimの/etc/profileの反映に失敗しました。"

print_current_time

echo "vimのインストールが完了しました。"

#----------------------------------------------------------#
# vimの設定
#----------------------------------------------------------#
echo "vimの設定を行います。"

cat <<EOF | tee ~/.vimrc
if &compatible
  set nocompatible
endif

set encoding=utf-8

scriptencoding utf-8

"------------------------------------------------------"
" 文字コード
"------------------------------------------------------"
" 保存時の文字コード
set fileencoding=utf-8
" 読み込み時の文字コードの自動判別. 左側が優先される
set fileencodings=ucs-bom,utf-8,euc-jp,sjis,cp932
" 改行コードの自動判別. 左側が優先される
set fileformats=unix,dos,mac
" □や○文字が崩れる問題を解決
set ambiwidth=double

"------------------------------------------------------"
" 編集
"------------------------------------------------------"
" バックアップファイルを作らない
set nobackup
" スワップファイルを作らない
set noswapfile
" 編集中のファイルが変更されたら自動で読み直す
set autoread
" バッファが編集中でもその他のファイルを開けるように
set hidden
" ファイルを保存していない場合に、ファイルの保存を確認するダイアログを出す
set confirm

"------------------------------------------------------"
" タブ・インデント
"------------------------------------------------------"
" 不可視文字を可視化(行末のスペースは「-」、タブ文字は「^ 」、行末文字は「↲」)
set list listchars=trail:-,tab:^\ ,eol:↲
" タブ入力を複数の空白入力に置き換える
set expandtab
" 画面上でタブ文字が占める幅
set tabstop=2
" 連続した空白に対してタブキーやバックスペースキーでカーソルが動く幅
set softtabstop=2
" 改行時に前の行のインデントを継続する
set autoindent
" 改行時に前の行の構文をチェックし次の行のインデントを増減する
set smartindent
" smartindentで増減する幅
set shiftwidth=2

"------------------------------------------------------"
" 文字列検索
"------------------------------------------------------"
" インクリメンタルサーチ. １文字入力毎に検索を行う
set incsearch
" 検索パターンに大文字小文字を区別しない
set ignorecase
" 検索パターンに大文字を含んでいたら大文字小文字を区別する
set smartcase
" 検索結果をハイライト
set hlsearch
" 検索時に最後まで行ったら最初に戻る
set wrapscan

" ESCキー2度押しでハイライトの切り替え
nnoremap <silent><Esc><Esc> :<C-u>set nohlsearch!<CR>

"------------------------------------------------------"
" カーソル
"------------------------------------------------------"
" 行末の1文字先までカーソルを移動できるように
set virtualedit=onemore
" カーソルの左右移動で行末から次の行の行頭への移動が可能になる
set whichwrap=b,s,h,l,<,>,[,],~
" カーソルラインをハイライト
set cursorline

" 行が折り返し表示されていた場合、行単位ではなく表示行単位でカーソルを移動する
nnoremap j gj
nnoremap k gk
nnoremap <down> gj
nnoremap <up> gk

" バックスペースキーの有効化
set backspace=indent,eol,start

"------------------------------------------------------"
" 表示
"------------------------------------------------------"
" 行番号を表示
"set number
" モードを表示する
set showmode
" 背景色の設定
set background=dark
" 括弧の対応関係を一瞬表示する
set showmatch matchtime=1
" ステータスラインを常に表示
set laststatus=2
" 入力中のコマンドをステータスに表示する
set showcmd
" タイトルを表示
set title
" 省略されずに表示
set display=lastline
" yでコピーした時にクリップボードに入る
set guioptions+=a
" ハイライト表示をON
syntax on

"------------------------------------------------------"
" コマンド補完
"------------------------------------------------------"
" コマンドラインの補完
set wildmode=list:longest
" 保存するコマンド履歴の数
set history=10000

"------------------------------------------------------"
" コピー・ペースト設定
"------------------------------------------------------"
" ヤンクでクリップボードにコピー
set clipboard&
set clipboard^=unnamedplus,unnamed,autoselect

" 挿入モードで貼り付けを行う時にペーストモードに切り替える
if &term =~ "xterm"
  let &t_ti .= "\e[?2004h"
  let &t_te .= "\e[?2004l"
  let &pastetoggle = "\e[201~"

  function XTermPasteBegin(ret)
    set paste
    return a:ret
  endfunction

  noremap <special> <expr> <Esc>[200~ XTermPasteBegin("0i")
  inoremap <special> <expr> <Esc>[200~ XTermPasteBegin("")
  cnoremap <special> <Esc>[200~ <nop>
  cnoremap <special> <Esc>[201~ <nop>
endif

" 挿入モードから抜ける時にペーストモードを解除する
autocmd InsertLeave * set nopaste

"------------------------------------------------------"
" ファイルタイプ設定
"------------------------------------------------------"
" ファイルタイプ別のVimプラグイン/インデントを有効にする
filetype plugin indent on
EOF

echo "vimの設定が完了しました。"

#----------------------------------------------------------#
# MySQLのインストール
#----------------------------------------------------------#
if [ "$IS_MYSQL_INSTALL" -eq 1 ]; then
  echo "MySQLのインストールを行います。"

  print_current_time

  sudo useradd -s /bin/false mysql

  check_command_status "MySQLユーザーの作成に失敗しました。"

  cd /home/${GENERAL_USER_NAME}/src

  curl ${CURL_RETRY_OPTION} -L -O https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz

  check_command_status "cmakeのダウンロードに失敗しました。"

  tar xvzf cmake-${CMAKE_VERSION}.tar.gz

  check_command_status "cmakeファイルの解凍に失敗しました。"

  cd cmake-${CMAKE_VERSION}

  echo "export OPENSSL_ROOT_DIR=/opt/openssl/current" > ./cmake_ccc

  echo "./configure --prefix=/opt/cmake/${CMAKE_VERSION} CC=\"/opt/gcc/current/bin/gcc\" CXX=\"/opt/gcc/current/bin/g++\" CXXFLAGS=\"-std=c++11\"" >> ./cmake_ccc

  bash ./cmake_ccc

  check_command_status "cmakeのconfigureに失敗しました。"

  make

  check_command_status "cmakeのmakeに失敗しました。"

  sudo make install

  check_command_status "cmakeのmake installに失敗しました。"

  sudo ln -s /opt/cmake/${CMAKE_VERSION} /opt/cmake/current

  sudo sed -i -e 's@^\(export PATH=\)\(.\+\)\(\$PATH\)$@\1\2/opt/cmake/current/bin:\3@g' /etc/profile

  source /etc/profile

  check_command_status "cmakeの/etc/profileの反映に失敗しました。"

  cd /home/${GENERAL_USER_NAME}/src

  curl ${CURL_RETRY_OPTION} -L -O https://downloads.mysql.com/archives/get/p/23/file/mysql-${MYSQL_FULL_VERSION}.tar.gz

  check_command_status "mysqlのダウンロードに失敗しました。"

  tar xvzf mysql-${MYSQL_FULL_VERSION}.tar.gz

  check_command_status "mysqlファイルの解凍に失敗しました。"

  cd mysql-${MYSQL_FULL_VERSION}

  mkdir build

  cd build

  echo "cmake .. \
  -DCMAKE_INSTALL_PREFIX=/opt/db/mysql/${MYSQL_FULL_VERSION} \
  -DDEFAULT_CHARSET=utf8mb4 \
  -DDEFAULT_COLLATION=utf8mb4_bin \
  -DENABLED_LOCAL_INFILE=1 \
  -DMYSQL_DATADIR=/opt/db/mysql/${MYSQL_FULL_VERSION}/data \
  -DMYSQL_UNIX_ADDR=/opt/db/mysql/${MYSQL_FULL_VERSION}/tmp/mysql.sock \
  -DWITH_EXTRA_CHARSETS=all \
  -DWITH_SSL=/opt/openssl/current \
  -DZLIB_LIBRARY=/opt/zlib/current/lib/libz.so \
  -DZLIB_INCLUDE_DIR=/opt/zlib/current/include \
  -DWITH_INNOBASE_STORAGE_ENGINE=1" > ./mysql_ccc

  change_dnf_package install "${MYSQL_REQUIRE_PACKAGE}" ${EXEC_USER_NAME}

  BEFORE_PATH=`echo $PATH`

  # 一時的にパスを変更してMySQLのmakeを成功させる様にする
  export PATH=/opt/rh/gcc-toolset-12/root/usr/bin:$PATH

  bash ./mysql_ccc

  check_command_status "mysqlのcmakeに失敗しました。"

  make

  check_command_status "mysqlのmakeに失敗しました。"

  sudo make install

  check_command_status "mysqlのmake installに失敗しました。"

  sudo ln -s /opt/db/mysql/${MYSQL_FULL_VERSION} /opt/db/mysql/current

  export PATH=$BEFORE_PATH

  sudo sed -i -e 's@^\(export PATH=\)\(.\+\)\(\$PATH\)$@\1\2/opt/db/mysql/current/bin:\3@g' /etc/profile

  source /etc/profile

  check_command_status "mysqlの/etc/profileの反映に失敗しました。"

  echo '/opt/db/mysql/current/lib' | sudo tee /etc/ld.so.conf.d/mysql.conf

  sudo ldconfig

  check_command_status "mysql用のldconfigに失敗しました。"

  sudo mkdir -p /opt/db/mysql/current/log

  sudo mkdir -p /opt/db/mysql/current/tmp

  sudo mkdir -p /opt/db/mysql/current/data

  sudo mkdir -p /opt/db/mysql/current/bin_log

  sudo touch /opt/db/mysql/current/log/slow_query.log

  sudo touch /opt/db/mysql/current/log/general.log

  sudo chmod -R 755 /opt/db/mysql/current/log

  sudo chmod 644 /opt/db/mysql/current/log/*

  sudo chown -R mysql:mysql /opt/db/mysql/${MYSQL_FULL_VERSION}

  cat <<EOF | sudo tee /etc/my.cnf
[mysqld]
basedir=/opt/db/mysql/current
datadir=/opt/db/mysql/current/data
tmpdir=/opt/db/mysql/current/tmp
port=${MYSQL_PORT}
socket=/opt/db/mysql/current/tmp/mysql.sock
character-set-server=utf8mb4
collation-server=utf8mb4_bin
default-storage-engine=InnoDB
explicit_defaults_for_timestamp=1
default_password_lifetime=0
lower_case_table_names=1
secure-file-priv=/opt/db/mysql/current/tmp
sql_mode=TRADITIONAL,NO_AUTO_VALUE_ON_ZERO,ONLY_FULL_GROUP_BY
user=mysql
log-error=/opt/db/mysql/current/log/mysqld.log
pid-file=/opt/db/mysql/current/tmp/mysqld.pid

server-id=1
log-bin=/opt/db/mysql/current/bin_log/mysql-bin-log
log_bin_index=/opt/db/mysql/current/bin_log/bin.list
max_binlog_size=256M
binlog_expire_logs_seconds=8553600

innodb_file_per_table=1
innodb_default_row_format=DYNAMIC
innodb_lock_wait_timeout=30
innodb_status_output=1
innodb_status_output_locks=1

log_output=TABLE,FILE
slow_query_log=1
slow_query_log_file=/opt/db/mysql/current/log/slow_query.log
long_query_time=0.3
min_examined_row_limit=0
log_queries_not_using_indexes=1
log_slow_admin_statements=1

general_log=1
general_log_file=/opt/db/mysql/current/log/general.log

[mysqld_safe]
log-error=/opt/db/mysql/current/log/mysqld_safe.log
pid-file=/opt/db/mysql/current/tmp/mysqld_safe.pid

[mysqldump]
default-character-set=utf8mb4
quick

[mysql]
default-character-set=utf8mb4
port=${MYSQL_PORT}
socket=/opt/db/mysql/current/tmp/mysql.sock
prompt='\\\\U [\\\\d]>\\\\_'

[client]
default-character-set=utf8mb4
port=${MYSQL_PORT}
socket=/opt/db/mysql/current/tmp/mysql.sock
EOF

  sudo /opt/db/mysql/current/bin/mysqld --defaults-file=/etc/my.cnf --initialize-insecure --user=mysql --basedir=/opt/db/mysql/current --datadir=/opt/db/mysql/current/data

  check_command_status "mysqlの初期化に失敗しました。"

  cat <<'EOF' | sudo tee /etc/systemd/system/mysqld.service
[Unit]
Description=MySQL Server
After=syslog.target
After=network.target

[Service]
Type=simple
User=mysql
Group=mysql
PIDFile=/opt/db/mysql/current/tmp/mysqld.pid
ExecStart=/opt/db/mysql/current/bin/mysqld --defaults-file=/etc/my.cnf
ExecReload=/usr/bin/kill -HUP $MAINPID
ExecStop=/usr/bin/kill $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

  cat <<'EOF' | sudo tee /etc/logrotate.d/mysql
/opt/db/mysql/current/log/*.log {
  daily
  missingok
  rotate 365
  dateext
  create 0644 mysql mysql
  su mysql mysql
  sharedscripts
  postrotate
    /bin/mv /opt/db/mysql/current/log/general.log-`date +'%Y%m%d'` /opt/db/mysql/current/log/general.log-`date +'%Y%m%d' -d '1days ago'`
    /bin/mv /opt/db/mysql/current/log/slow_query.log-`date +'%Y%m%d'` /opt/db/mysql/current/log/slow_query.log-`date +'%Y%m%d' -d '1days ago'`
    /bin/mv /opt/db/mysql/current/log/mysqld.log-`date +'%Y%m%d'` /opt/db/mysql/current/log/mysqld.log-`date +'%Y%m%d' -d '1days ago'`
    [ ! -f /opt/db/mysql/current/tmp/mysqld.pid ] || kill -USR1 `cat /opt/db/mysql/current/tmp/mysqld.pid`
  endscript
}
EOF

  sudo nft add rule ip my_nft4_table TCP tcp dport ${MYSQL_PORT} accept

  sudo systemctl start mysqld

  check_command_status "mysqlの起動に失敗しました。"

  sudo systemctl enable mysqld

  check_command_status "mysqlの自動起動設定に失敗しました。"

  # 起動直後は、socketファイルが見つからないエラーが発生するので、しばらくリトライする
  IS_SUCCESS=0
  for i in `seq 1 30`
  do
    sudo /opt/db/mysql/current/bin/mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -uroot mysql
    if [ "$?" -eq 0 ]; then
      IS_SUCCESS=1
      break;
    fi
    sleep 2
  done

  if [ "$IS_SUCCESS" -eq 0 ]; then
    echo "mysqlのタイムゾーン設定に失敗しました。"
    exit 1
  fi

  mysql -uroot --execute="INSTALL PLUGIN validate_password SONAME 'validate_password.so';"

  mysql -uroot --execute="set global validate_password_policy = 'LOW';"

  mysql -uroot --execute="ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';"

  check_command_status "mysqlのrootのパスワード変更に失敗しました。"

  rm -f ~/.mysql_history

  sudo sed -i -e "/^pid-file=.\+$/a default-time-zone='Asia/Tokyo'" /etc/my.cnf

  sudo sed -i -e "/^general_log_file=.\+$/a plugin-load=/opt/db/mysql/current/lib/plugin/validate_password.so" /etc/my.cnf

  sudo sed -i -e "/^plugin-load=.\+$/a validate-password=FORCE_PLUS_PERMANENT" /etc/my.cnf

  sudo sed -i -e "/^validate-password=.\+$/a validate_password_policy=MEDIUM" /etc/my.cnf

  sudo sed -i -e "/^validate_password_policy=.\+$/a validate_password_length=8" /etc/my.cnf

  sudo systemctl restart mysqld

  check_command_status "mysqlの再起動に失敗しました。"

  print_current_time

  echo "MySQLのインストールが完了しました。"
fi

#----------------------------------------------------------#
# Nginxのインストール
#----------------------------------------------------------#
echo "Nginxのインストールを行います。"

print_current_time

sudo useradd -s /bin/false nginx

check_command_status "Nginxユーザーの作成に失敗しました。"

cd /home/${GENERAL_USER_NAME}/src

curl ${CURL_RETRY_OPTION} -O http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz

check_command_status "nginxのダウンロードに失敗しました。"

tar xvzf nginx-${NGINX_VERSION}.tar.gz

check_command_status "nginxファイルの解凍に失敗しました。"

cd nginx-${NGINX_VERSION}

# OpenSSLのパスは、インストールしたバイナリの方ではなく、ダウンロードしたソースの方を指定する
echo "./configure \
--prefix=/opt/nginx/${NGINX_VERSION} \
--sbin-path=/opt/nginx/${NGINX_VERSION}/sbin/nginx \
--pid-path=/opt/nginx/${NGINX_VERSION}/tmp/nginx.pid \
--lock-path=/opt/nginx/${NGINX_VERSION}/tmp/nginx.lock \
--http-log-path=/opt/nginx/${NGINX_VERSION}/logs/access.log \
--error-log-path=/opt/nginx/${NGINX_VERSION}/logs/error.log \
--with-openssl=/home/${GENERAL_USER_NAME}/src/openssl-${OPENSSL_VERSION} \
--user=nginx \
--group=nginx \
--with-http_v2_module \
--with-http_ssl_module \
--with-http_realip_module" > ./nginx_ccc

# インストール時にccコマンドを使うので、gccコマンドを参照する様にする
export CC=gcc

bash ./nginx_ccc

check_command_status "nginxのconfigureに失敗しました。"

make

check_command_status "nginxのmakeに失敗しました。"

sudo make install

check_command_status "nginxのmake installに失敗しました。"

sudo ln -s /opt/nginx/${NGINX_VERSION} /opt/nginx/current

sudo sed -i -e 's@^\(export PATH=\)\(.\+\)\(\$PATH\)$@\1\2/opt/nginx/current/bin:\3@g' /etc/profile

source /etc/profile

check_command_status "nginxの/etc/profileの反映に失敗しました。"

sudo mkdir -p ${DOCUMENT_ROOT}

sudo mkdir -p /opt/nginx/current/conf.d

sudo touch /opt/nginx/current/logs/access.log

sudo touch /opt/nginx/current/logs/error.log

sudo chmod -R 755 /opt/nginx/current/logs

sudo chmod 644 /opt/nginx/current/logs/*

sudo chown -R nginx:nginx /opt/nginx/${NGINX_VERSION}

cat <<EOF | sudo tee /opt/nginx/current/conf.d/http.conf
server {
  listen ${HTTP_PORT};
  server_name ${HOST_NAME};
  root ${DOCUMENT_ROOT};
  index index.php index.html;

  location / {
    try_files \$uri \$uri/ /index.php\$is_args\$args;
  }

  location ~ \.php$ {
    try_files \$uri =404;
    include /opt/nginx/current/conf/fastcgi_params;
    fastcgi_pass unix:/opt/php/current/tmp/php-fpm.sock;
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    fastcgi_param PHP_ENV ${ENVIRONMENT_FULL};
  }
}
EOF

sudo cp /opt/nginx/current/conf/nginx.conf /opt/nginx/current/conf/nginx.conf.org

check_command_status "nginx設定ファイルのバックアップに失敗しました。"

cat <<'EOF' | sudo tee /opt/nginx/current/conf/nginx.conf
user nginx;
worker_processes auto;

error_log logs/error.log warn;

pid tmp/nginx.pid;

events {
  worker_connections 1024;
  multi_accept on;
  use epoll;
}

http {
  include mime.types;
  default_type application/octet-stream;

  log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                  '$status $body_bytes_sent "$http_referer" '
                  '"$http_user_agent" "$http_x_forwarded_for"';

  access_log logs/access.log main;

  server_tokens off;
  sendfile on;
  tcp_nopush on;
  tcp_nodelay on;
  keepalive_timeout 10;
  client_header_timeout 10;
  client_body_timeout 10;
  reset_timedout_connection on;
  send_timeout 10;

  include /opt/nginx/current/conf.d/*.conf;
}
EOF

cat <<'EOF' | sudo tee /etc/systemd/system/nginx.service
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/opt/nginx/current/tmp/nginx.pid
ExecStartPre=/opt/nginx/current/sbin/nginx -t
ExecStart=/opt/nginx/current/sbin/nginx
ExecReload=/usr/bin/kill -s HUP $MAINPID
ExecStop=/usr/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

cat <<'EOF' | sudo tee /etc/logrotate.d/nginx
/opt/nginx/current/logs/*.log {
  daily
  missingok
  rotate 365
  dateext
  create 0644 nginx nginx
  su nginx nginx
  sharedscripts
  postrotate
    /bin/mv /opt/nginx/current/logs/access.log-`date +'%Y%m%d'` /opt/nginx/current/logs/access.log-`date +'%Y%m%d' -d '1days ago'`
    /bin/mv /opt/nginx/current/logs/error.log-`date +'%Y%m%d'` /opt/nginx/current/logs/error.log-`date +'%Y%m%d' -d '1days ago'`
    [ ! -f /opt/nginx/current/tmp/nginx.pid ] || kill -USR1 `cat /opt/nginx/current/tmp/nginx.pid`
  endscript
}
EOF

sudo nft add set ip my_nft4_table httpv4_dos_counter { type ipv4_addr\; size 65535\; flags dynamic,timeout\; timeout 2m\; }

sudo nft add set ip6 my_nft6_table httpv6_dos_counter { type ipv6_addr\; size 65535\; flags dynamic,timeout\; timeout 2m\; }

sudo nft add rule ip my_nft4_table TCP tcp dport ${HTTP_PORT} update @httpv4_dos_counter { ip saddr limit rate over 20/minute burst 1 packets } log prefix \"HTTPV4 Attacked:\" drop

sudo nft add rule ip my_nft4_table TCP tcp dport ${HTTP_PORT} accept

sudo nft add rule ip6 my_nft6_table TCPV6 tcp dport ${HTTP_PORT} update @httpv6_dos_counter { ip6 saddr limit rate over 20/minute burst 1 packets } log prefix \"HTTPV6 Attacked:\" drop

sudo nft add rule ip6 my_nft6_table TCPV6 tcp dport ${HTTP_PORT} accept

print_current_time

echo "Nginxのインストールが完了しました。"

#----------------------------------------------------------#
# PHPのインストール
#----------------------------------------------------------#
echo "PHPのインストールを行います。"

print_current_time

cd /home/${GENERAL_USER_NAME}/src

curl ${CURL_RETRY_OPTION} -O https://www.php.net/distributions/php-${PHP_VERSION}.tar.xz

check_command_status "PHPのダウンロードに失敗しました。"

tar Jxvf ./php-${PHP_VERSION}.tar.xz

check_command_status "PHPファイルの解凍に失敗しました。"

cd php-${PHP_VERSION}

echo "./configure \
--prefix=/opt/php/${PHP_VERSION} \
--with-openssl \
--with-system-ciphers \
--with-mysqli=mysqlnd \
--with-pdo-mysql=mysqlnd \
--with-fpm-systemd \
--enable-mbstring \
--enable-fpm \
--with-fpm-user=nginx \
--with-fpm-group=nginx \
--without-sqlite3 \
--without-pdo-sqlite \
--without-pear" > ./php_ccc

change_dnf_package install "${PHP_REQUIRE_PACKAGE}" ${EXEC_USER_NAME}

check_command_status "PHPの必須パッケージのインストールに失敗しました。"

# 「--with-openssl」で指定出来なくなったので、インストールしたOpenSSLの場所を教える為に必要
export PKG_CONFIG_PATH=/opt/openssl/current/lib64/pkgconfig

bash ./php_ccc

check_command_status "PHPのconfigureに失敗しました。"

make

check_command_status "PHPのmakeに失敗しました。"

sudo make install

check_command_status "PHPのmake installに失敗しました。"

sudo ln -s /opt/php/${PHP_VERSION} /opt/php/current

sudo sed -i -e 's@^\(export PATH=\)\(.\+\)\(\$PATH\)$@\1\2/opt/php/current/bin:\3@g' /etc/profile

source /etc/profile

check_command_status "PHPの/etc/profileの反映に失敗しました。"

if [ "$PHP_INI_CURL_CAINFO" != "" ]; then
  sudo curl ${CURL_RETRY_OPTION} https://curl.se/ca/cacert.pem -o ${PHP_INI_CURL_CAINFO}

  check_command_status "PHPのcurl用のcacert.pemのダウンロードに失敗しました。"

  sudo chown ${GENERAL_USER_NAME}:${GENERAL_USER_NAME} ${PHP_INI_CURL_CAINFO}
fi

sudo mkdir -p /opt/php/current/log

sudo touch $PHP_INI_ERROR_LOG

sudo chmod -R 777 /opt/php/current/log

if [ "$PHP_INI_SESSION_SAVE_HANDLER" = "files" ]; then
  sudo mkdir -p $PHP_INI_SESSION_SAVE_PATH

  sudo chmod -R 777 $PHP_INI_SESSION_SAVE_PATH
fi

sudo cp php.ini-production /opt/php/current/lib/php.ini

sudo cp /opt/php/current/lib/php.ini /opt/php/current/lib/php.ini.org

check_command_status "php.iniのバックアップに失敗しました。"

PHP_INI_KEY_ZEND_MULTIBYTE='zend\.multibyte'
PHP_INI_KEY_ZEND_SCRIPT_ENCODING='zend\.script_encoding'
PHP_INI_KEY_ZEND_EXCEPTION_IGNORE_ARGS='zend\.exception_ignore_args'
PHP_INI_KEY_EXPOSE_PHP='expose_php'
PHP_INI_KEY_MEMORY_LIMIT='memory_limit'
PHP_INI_KEY_ERROR_REPORTING='error_reporting'
PHP_INI_KEY_DISPLAY_ERRORS='display_errors'
PHP_INI_KEY_DISPLAY_STARTUP_ERRORS='display_startup_errors'
PHP_INI_KEY_LOG_ERRORS_MAX_LEN='log_errors_max_len'
PHP_INI_KEY_HTML_ERRORS='html_errors'
PHP_INI_KEY_ERROR_LOG='error_log'
PHP_INI_KEY_POST_MAX_SIZE='post_max_size'
PHP_INI_KEY_DEFAULT_CHARSET='default_charset'
PHP_INI_KEY_UPLOAD_MAX_FILESIZE='upload_max_filesize'
PHP_INI_KEY_ALLOW_URL_FOPEN='allow_url_fopen'
PHP_INI_KEY_ALLOW_URL_INCLUDE='allow_url_include'
PHP_INI_KEY_DATE_TIMEZONE='date\.timezone'
PHP_INI_KEY_MYSQLI_DEFAULT_PORT='mysqli\.default_port'
PHP_INI_KEY_MYSQLND_COLLECT_STATISTICS='mysqlnd\.collect_statistics'
PHP_INI_KEY_MYSQLND_COLLECT_MEMORY_STATISTICS='mysqlnd\.collect_memory_statistics'
PHP_INI_KEY_SESSION_SAVE_HANDLER='session\.save_handler'
PHP_INI_KEY_SESSION_SAVE_PATH='session\.save_path'
PHP_INI_KEY_SESSION_USE_STRICT_MODE='session\.use_strict_mode'
PHP_INI_KEY_SESSION_USE_COOKIES='session\.use_cookies'
PHP_INI_KEY_SESSION_COOKIE_SECURE='session\.cookie_secure'
PHP_INI_KEY_SESSION_USE_ONLY_COOKIES='session\.use_only_cookies'
PHP_INI_KEY_SESSION_NAME='session\.name'
PHP_INI_KEY_SESSION_AUTO_START='session\.auto_start'
PHP_INI_KEY_SESSION_COOKIE_LIFETIME='session\.cookie_lifetime'
PHP_INI_KEY_SESSION_COOKIE_PATH='session\.cookie_path'
PHP_INI_KEY_SESSION_COOKIE_DOMAIN='session\.cookie_domain'
PHP_INI_KEY_SESSION_COOKIE_HTTPONLY='session\.cookie_httponly'
PHP_INI_KEY_SESSION_COOKIE_SAMESITE='session\.cookie_samesite'
PHP_INI_KEY_SESSION_SERIALIZE_HANDLER='session\.serialize_handler'
PHP_INI_KEY_SESSION_GC_PROBABILITY='session\.gc_probability'
PHP_INI_KEY_SESSION_GC_DIVISOR='session\.gc_divisor'
PHP_INI_KEY_SESSION_GC_MAXLIFETIME='session\.gc_maxlifetime'
PHP_INI_KEY_SESSION_REFERER_CHECK='session\.referer_check'
PHP_INI_KEY_SESSION_CACHE_LIMITER='session\.cache_limiter'
PHP_INI_KEY_SESSION_CACHE_EXPIRE='session\.cache_expire'
PHP_INI_KEY_SESSION_USE_TRANS_SID='session\.use_trans_sid'
PHP_INI_KEY_SESSION_SID_LENGTH='session\.sid_length'
PHP_INI_KEY_SESSION_TRANS_SID_TAGS='session\.trans_sid_tags'
PHP_INI_KEY_SESSION_TRANS_SID_HOSTS='session\.trans_sid_hosts'
PHP_INI_KEY_SESSION_SID_BITS_PER_CHARACTER='session\.sid_bits_per_character'
PHP_INI_KEY_SESSION_UPLOAD_PROGRESS_CLEANUP='session\.upload_progress\.cleanup'
PHP_INI_KEY_SESSION_LAZY_WRITE='session\.lazy_write'
PHP_INI_KEY_ZEND_ASSERTIONS='zend\.assertions'
PHP_INI_KEY_ASSERT_ACTIVE='assert\.active'
PHP_INI_KEY_ASSERT_EXCEPTION='assert\.exception'
PHP_INI_KEY_MBSTRING_LANGUAGE='mbstring\.language'
PHP_INI_KEY_MBSTRING_ENCODING_TRANSLATION='mbstring\.encoding_translation'
PHP_INI_KEY_MBSTRING_DETECT_ORDER='mbstring\.detect_order'
PHP_INI_KEY_MBSTRING_SUBSTITUTE_CHARACTER='mbstring\.substitute_character'
PHP_INI_KEY_MBSTRING_STRICT_DETECTION='mbstring\.strict_detection'
PHP_INI_KEY_CURL_CAINFO='curl\.cainfo'
PHP_INI_KEY_OPENSSL_CAFILE='openssl\.cafile'
PHP_INI_KEY_OPENSSL_CAPATH='openssl\.capath'

declare -a PHP_INI_KEY_SETTINGS=(
  ${PHP_INI_KEY_ZEND_MULTIBYTE}
  ${PHP_INI_KEY_ZEND_SCRIPT_ENCODING}
  ${PHP_INI_KEY_ZEND_EXCEPTION_IGNORE_ARGS}
  ${PHP_INI_KEY_EXPOSE_PHP}
  ${PHP_INI_KEY_MEMORY_LIMIT}
  ${PHP_INI_KEY_ERROR_REPORTING}
  ${PHP_INI_KEY_DISPLAY_ERRORS}
  ${PHP_INI_KEY_DISPLAY_STARTUP_ERRORS}
  ${PHP_INI_KEY_LOG_ERRORS_MAX_LEN}
  ${PHP_INI_KEY_HTML_ERRORS}
  ${PHP_INI_KEY_ERROR_LOG}
  ${PHP_INI_KEY_POST_MAX_SIZE}
  ${PHP_INI_KEY_DEFAULT_CHARSET}
  ${PHP_INI_KEY_UPLOAD_MAX_FILESIZE}
  ${PHP_INI_KEY_ALLOW_URL_FOPEN}
  ${PHP_INI_KEY_ALLOW_URL_INCLUDE}
  ${PHP_INI_KEY_DATE_TIMEZONE}
  ${PHP_INI_KEY_MYSQLI_DEFAULT_PORT}
  ${PHP_INI_KEY_MYSQLND_COLLECT_STATISTICS}
  ${PHP_INI_KEY_MYSQLND_COLLECT_MEMORY_STATISTICS}
  ${PHP_INI_KEY_SESSION_SAVE_HANDLER}
  ${PHP_INI_KEY_SESSION_SAVE_PATH}
  ${PHP_INI_KEY_SESSION_USE_STRICT_MODE}
  ${PHP_INI_KEY_SESSION_USE_COOKIES}
  ${PHP_INI_KEY_SESSION_COOKIE_SECURE}
  ${PHP_INI_KEY_SESSION_USE_ONLY_COOKIES}
  ${PHP_INI_KEY_SESSION_NAME}
  ${PHP_INI_KEY_SESSION_AUTO_START}
  ${PHP_INI_KEY_SESSION_COOKIE_LIFETIME}
  ${PHP_INI_KEY_SESSION_COOKIE_PATH}
  ${PHP_INI_KEY_SESSION_COOKIE_DOMAIN}
  ${PHP_INI_KEY_SESSION_COOKIE_HTTPONLY}
  ${PHP_INI_KEY_SESSION_COOKIE_SAMESITE}
  ${PHP_INI_KEY_SESSION_SERIALIZE_HANDLER}
  ${PHP_INI_KEY_SESSION_GC_PROBABILITY}
  ${PHP_INI_KEY_SESSION_GC_DIVISOR}
  ${PHP_INI_KEY_SESSION_GC_MAXLIFETIME}
  ${PHP_INI_KEY_SESSION_REFERER_CHECK}
  ${PHP_INI_KEY_SESSION_CACHE_LIMITER}
  ${PHP_INI_KEY_SESSION_CACHE_EXPIRE}
  ${PHP_INI_KEY_SESSION_USE_TRANS_SID}
  ${PHP_INI_KEY_SESSION_SID_LENGTH}
  ${PHP_INI_KEY_SESSION_TRANS_SID_TAGS}
  ${PHP_INI_KEY_SESSION_TRANS_SID_HOSTS}
  ${PHP_INI_KEY_SESSION_SID_BITS_PER_CHARACTER}
  ${PHP_INI_KEY_SESSION_UPLOAD_PROGRESS_CLEANUP}
  ${PHP_INI_KEY_SESSION_LAZY_WRITE}
  ${PHP_INI_KEY_ZEND_ASSERTIONS}
  ${PHP_INI_KEY_ASSERT_ACTIVE}
  ${PHP_INI_KEY_ASSERT_EXCEPTION}
  ${PHP_INI_KEY_MBSTRING_LANGUAGE}
  ${PHP_INI_KEY_MBSTRING_ENCODING_TRANSLATION}
  ${PHP_INI_KEY_MBSTRING_DETECT_ORDER}
  ${PHP_INI_KEY_MBSTRING_SUBSTITUTE_CHARACTER}
  ${PHP_INI_KEY_MBSTRING_STRICT_DETECTION}
  ${PHP_INI_KEY_CURL_CAINFO}
  ${PHP_INI_KEY_OPENSSL_CAFILE}
  ${PHP_INI_KEY_OPENSSL_CAPATH}
)

declare -A PHP_INI_SETTINGS

PHP_INI_SETTINGS[${PHP_INI_KEY_ZEND_MULTIBYTE}]=" ${PHP_INI_ZEND_MULTIBYTE}"
PHP_INI_SETTINGS[${PHP_INI_KEY_ZEND_SCRIPT_ENCODING}]=" ${PHP_INI_ZEND_SCRIPT_ENCODING}"
PHP_INI_SETTINGS[${PHP_INI_KEY_ZEND_EXCEPTION_IGNORE_ARGS}]=" ${PHP_INI_ZEND_EXCEPTION_IGNORE_ARGS}"
PHP_INI_SETTINGS[${PHP_INI_KEY_EXPOSE_PHP}]=" ${PHP_INI_EXPOSE_PHP}"
PHP_INI_SETTINGS[${PHP_INI_KEY_MEMORY_LIMIT}]=" ${PHP_INI_MEMORY_LIMIT}"
PHP_INI_SETTINGS[${PHP_INI_KEY_ERROR_REPORTING}]=" ${PHP_INI_ERROR_REPORTING}"
PHP_INI_SETTINGS[${PHP_INI_KEY_DISPLAY_ERRORS}]=" ${PHP_INI_DISPLAY_ERRORS}"
PHP_INI_SETTINGS[${PHP_INI_KEY_DISPLAY_STARTUP_ERRORS}]=" ${PHP_INI_DISPLAY_STARTUP_ERRORS}"
PHP_INI_SETTINGS[${PHP_INI_KEY_LOG_ERRORS_MAX_LEN}]=" ${PHP_INI_LOG_ERRORS_MAX_LEN}"
PHP_INI_SETTINGS[${PHP_INI_KEY_HTML_ERRORS}]=" ${PHP_INI_HTML_ERRORS}"
PHP_INI_SETTINGS[${PHP_INI_KEY_ERROR_LOG}]=" ${PHP_INI_ERROR_LOG}"
PHP_INI_SETTINGS[${PHP_INI_KEY_POST_MAX_SIZE}]=" ${PHP_INI_POST_MAX_SIZE}"
PHP_INI_SETTINGS[${PHP_INI_KEY_DEFAULT_CHARSET}]=" ${PHP_INI_DEFAULT_CHARSET}"
PHP_INI_SETTINGS[${PHP_INI_KEY_UPLOAD_MAX_FILESIZE}]=" ${PHP_INI_UPLOAD_MAX_FILESIZE}"
PHP_INI_SETTINGS[${PHP_INI_KEY_ALLOW_URL_FOPEN}]=" ${PHP_INI_ALLOW_URL_FOPEN}"
PHP_INI_SETTINGS[${PHP_INI_KEY_ALLOW_URL_INCLUDE}]=" ${PHP_INI_ALLOW_URL_INCLUDE}"
PHP_INI_SETTINGS[${PHP_INI_KEY_DATE_TIMEZONE}]=" ${PHP_INI_DATE_TIMEZONE}"
PHP_INI_SETTINGS[${PHP_INI_KEY_MYSQLI_DEFAULT_PORT}]=" ${PHP_INI_MYSQLI_DEFAULT_PORT}"
PHP_INI_SETTINGS[${PHP_INI_KEY_MYSQLND_COLLECT_STATISTICS}]=" ${PHP_INI_MYSQLND_COLLECT_STATISTICS}"
PHP_INI_SETTINGS[${PHP_INI_KEY_MYSQLND_COLLECT_MEMORY_STATISTICS}]=" ${PHP_INI_MYSQLND_COLLECT_MEMORY_STATISTICS}"
PHP_INI_SETTINGS[${PHP_INI_KEY_SESSION_SAVE_HANDLER}]=" ${PHP_INI_SESSION_SAVE_HANDLER}"
PHP_INI_SETTINGS[${PHP_INI_KEY_SESSION_SAVE_PATH}]=" ${PHP_INI_SESSION_SAVE_PATH}"
PHP_INI_SETTINGS[${PHP_INI_KEY_SESSION_USE_STRICT_MODE}]=" ${PHP_INI_SESSION_USE_STRICT_MODE}"
PHP_INI_SETTINGS[${PHP_INI_KEY_SESSION_USE_COOKIES}]=" ${PHP_INI_SESSION_USE_COOKIES}"
PHP_INI_SETTINGS[${PHP_INI_KEY_SESSION_COOKIE_SECURE}]=" ${PHP_INI_SESSION_COOKIE_SECURE}"
PHP_INI_SETTINGS[${PHP_INI_KEY_SESSION_USE_ONLY_COOKIES}]=" ${PHP_INI_SESSION_USE_ONLY_COOKIES}"
PHP_INI_SETTINGS[${PHP_INI_KEY_SESSION_NAME}]=" ${PHP_INI_SESSION_NAME}"
PHP_INI_SETTINGS[${PHP_INI_KEY_SESSION_AUTO_START}]=" ${PHP_INI_SESSION_AUTO_START}"
PHP_INI_SETTINGS[${PHP_INI_KEY_SESSION_COOKIE_LIFETIME}]=" ${PHP_INI_SESSION_COOKIE_LIFETIME}"
PHP_INI_SETTINGS[${PHP_INI_KEY_SESSION_COOKIE_PATH}]=" ${PHP_INI_SESSION_COOKIE_PATH}"
# 設定する場合は、変数名の前に半角スペースを１文字入れる
PHP_INI_SETTINGS[${PHP_INI_KEY_SESSION_COOKIE_DOMAIN}]="${PHP_INI_SESSION_COOKIE_DOMAIN}"
PHP_INI_SETTINGS[${PHP_INI_KEY_SESSION_COOKIE_HTTPONLY}]=" ${PHP_INI_SESSION_COOKIE_HTTPONLY}"
PHP_INI_SETTINGS[${PHP_INI_KEY_SESSION_COOKIE_SAMESITE}]=" ${PHP_INI_SESSION_COOKIE_SAMESITE}"
PHP_INI_SETTINGS[${PHP_INI_KEY_SESSION_SERIALIZE_HANDLER}]=" ${PHP_INI_SESSION_SERIALIZE_HANDLER}"
PHP_INI_SETTINGS[${PHP_INI_KEY_SESSION_GC_PROBABILITY}]=" ${PHP_INI_SESSION_GC_PROBABILITY}"
PHP_INI_SETTINGS[${PHP_INI_KEY_SESSION_GC_DIVISOR}]=" ${PHP_INI_SESSION_GC_DIVISOR}"
PHP_INI_SETTINGS[${PHP_INI_KEY_SESSION_GC_MAXLIFETIME}]=" ${PHP_INI_SESSION_GC_MAXLIFETIME}"
# 設定する場合は、変数名の前に半角スペースを１文字入れる
PHP_INI_SETTINGS[${PHP_INI_KEY_SESSION_REFERER_CHECK}]="${PHP_INI_SESSION_REFERER_CHECK}"
PHP_INI_SETTINGS[${PHP_INI_KEY_SESSION_CACHE_LIMITER}]=" ${PHP_INI_SESSION_CACHE_LIMITER}"
PHP_INI_SETTINGS[${PHP_INI_KEY_SESSION_CACHE_EXPIRE}]=" ${PHP_INI_SESSION_CACHE_EXPIRE}"
PHP_INI_SETTINGS[${PHP_INI_KEY_SESSION_USE_TRANS_SID}]=" ${PHP_INI_SESSION_USE_TRANS_SID}"
PHP_INI_SETTINGS[${PHP_INI_KEY_SESSION_SID_LENGTH}]=" ${PHP_INI_SESSION_SID_LENGTH}"
PHP_INI_SETTINGS[${PHP_INI_KEY_SESSION_TRANS_SID_TAGS}]=" ${PHP_INI_SESSION_TRANS_SID_TAGS}"
# 設定する場合は、変数名の前に半角スペースを１文字入れる
PHP_INI_SETTINGS[${PHP_INI_KEY_SESSION_TRANS_SID_HOSTS}]="${PHP_INI_SESSION_TRANS_SID_HOSTS}"
PHP_INI_SETTINGS[${PHP_INI_KEY_SESSION_SID_BITS_PER_CHARACTER}]=" ${PHP_INI_SESSION_SID_BITS_PER_CHARACTER}"
PHP_INI_SETTINGS[${PHP_INI_KEY_SESSION_UPLOAD_PROGRESS_CLEANUP}]=" ${PHP_INI_SESSION_UPLOAD_PROGRESS_CLEANUP}"
PHP_INI_SETTINGS[${PHP_INI_KEY_SESSION_LAZY_WRITE}]=" ${PHP_INI_SESSION_LAZY_WRITE}"
PHP_INI_SETTINGS[${PHP_INI_KEY_ZEND_ASSERTIONS}]=" ${PHP_INI_ZEND_ASSERTIONS}"
PHP_INI_SETTINGS[${PHP_INI_KEY_ASSERT_ACTIVE}]=" ${PHP_INI_ASSERT_ACTIVE}"
PHP_INI_SETTINGS[${PHP_INI_KEY_ASSERT_EXCEPTION}]=" ${PHP_INI_ASSERT_EXCEPTION}"
PHP_INI_SETTINGS[${PHP_INI_KEY_MBSTRING_LANGUAGE}]=" ${PHP_INI_MBSTRING_LANGUAGE}"
PHP_INI_SETTINGS[${PHP_INI_KEY_MBSTRING_ENCODING_TRANSLATION}]=" ${PHP_INI_MBSTRING_ENCODING_TRANSLATION}"
PHP_INI_SETTINGS[${PHP_INI_KEY_MBSTRING_DETECT_ORDER}]=" ${PHP_INI_MBSTRING_DETECT_ORDER}"
PHP_INI_SETTINGS[${PHP_INI_KEY_MBSTRING_SUBSTITUTE_CHARACTER}]=" ${PHP_INI_MBSTRING_SUBSTITUTE_CHARACTER}"
PHP_INI_SETTINGS[${PHP_INI_KEY_MBSTRING_STRICT_DETECTION}]=" ${PHP_INI_MBSTRING_STRICT_DETECTION}"
PHP_INI_SETTINGS[${PHP_INI_KEY_CURL_CAINFO}]=" ${PHP_INI_CURL_CAINFO}"
PHP_INI_SETTINGS[${PHP_INI_KEY_OPENSSL_CAFILE}]=" ${PHP_INI_OPENSSL_CAFILE}"
# 設定する場合は、変数名の前に半角スペースを１文字入れる
PHP_INI_SETTINGS[${PHP_INI_KEY_OPENSSL_CAPATH}]="${PHP_INI_OPENSSL_CAPATH}"

for k in ${PHP_INI_KEY_SETTINGS[@]}
do
  sudo sed -i -e 's%^;\?\('"${k}"'\).\+$%\1 ='"${PHP_INI_SETTINGS[$k]}"'%g' /opt/php/current/lib/php.ini

  check_command_status "php.iniの${k}の設定に失敗しました。"
done

print_current_time

echo "PHPのインストールが完了しました。"

#----------------------------------------------------------#
# PHP-fpmの設定
#----------------------------------------------------------#
echo "PHP-fpmの設定を行います。"

sudo mkdir -p /opt/php/current/tmp

sudo chown -R nginx:nginx /opt/php/current/tmp

sudo cp /opt/php/current/etc/php-fpm.conf.default /opt/php/current/etc/php-fpm.conf

check_command_status "php-fpm.confのバックアップに失敗しました。"

sudo sed -i -e 's%^;\?\(pid.*=\).*$%\1 /opt/php/current/tmp/php-fpm.pid%g' /opt/php/current/etc/php-fpm.conf

sudo sed -i -e 's%^;\?\(error_log.*=\).*$%\1 /opt/php/current/log/php-fpm.log%g' /opt/php/current/etc/php-fpm.conf

sudo sed -i -e 's%^;\?\(include.*=\).*$%\1 /opt/php/current/etc/php-fpm.d/*.conf%g' /opt/php/current/etc/php-fpm.conf

sudo cp /opt/php/current/etc/php-fpm.d/www.conf.default /opt/php/current/etc/php-fpm.d/www.conf

check_command_status "www.confのバックアップに失敗しました。"

sudo sed -i -e 's%^;\?\(user.*=\).*$%\1 nginx%g' /opt/php/current/etc/php-fpm.d/www.conf

sudo sed -i -e 's%^;\?\(group.*=\).*$%\1 nginx%g' /opt/php/current/etc/php-fpm.d/www.conf

sudo sed -i -e 's%^;\?\(listen[^\.]*=\).*$%\1 /opt/php/current/tmp/php-fpm.sock%g' /opt/php/current/etc/php-fpm.d/www.conf

sudo sed -i -e 's%^;\?\(listen\.owner.*=\).*$%\1 nginx%g' /opt/php/current/etc/php-fpm.d/www.conf

sudo sed -i -e 's%^;\?\(listen\.group.*=\).*$%\1 nginx%g' /opt/php/current/etc/php-fpm.d/www.conf

sudo sed -i -e 's%^;\?\(listen\.mode.*=\).*$%\1 0660%g' /opt/php/current/etc/php-fpm.d/www.conf

sudo sed -i -e "s%^;\?\(pm[^\.]*=\).*$%\1 ${PHP_FPM_PM}%g" /opt/php/current/etc/php-fpm.d/www.conf

sudo sed -i -e "s%^;\?\(pm\.max_children.*=\).*$%\1 ${PHP_FPM_PM_MAX_CHILDREN}%g" /opt/php/current/etc/php-fpm.d/www.conf

sudo sed -i -e "s%^;\?\(pm\.start_servers.*=\).*$%\1 ${PHP_FPM_PM_START_SERVERS}%g" /opt/php/current/etc/php-fpm.d/www.conf

sudo sed -i -e "s%^;\?\(pm\.min_spare_servers.*=\).*$%\1 ${PHP_FPM_PM_MIN_SPARE_SERVERS}%g" /opt/php/current/etc/php-fpm.d/www.conf

sudo sed -i -e "s%^;\?\(pm\.max_spare_servers.*=\).*$%\1 ${PHP_FPM_PM_MAX_SPARE_SERVERS}%g" /opt/php/current/etc/php-fpm.d/www.conf

sudo sed -i -e "s%^;\?\(pm\.process_idle_timeout.*=\).*$%\1 ${PHP_FPM_PM_PROCESS_IDLE_TIMEOUT}%g" /opt/php/current/etc/php-fpm.d/www.conf

sudo sed -i -e "s%^;\?\(pm\.max_requests.*=\).*$%\1 ${PHP_FPM_PM_MAX_REQUESTS}%g" /opt/php/current/etc/php-fpm.d/www.conf

cat <<'EOF' | sudo tee /etc/logrotate.d/php
/opt/php/current/log/*.log {
  daily
  missingok
  rotate 365
  dateext
  create 0777 root root
  su root root
  sharedscripts
  postrotate
    /bin/mv /opt/php/current/log/php.log-`date +'%Y%m%d'` /opt/php/current/log/php.log-`date +'%Y%m%d' -d '1days ago'`
    /bin/mv /opt/php/current/log/php-fpm.log-`date +'%Y%m%d'` /opt/php/current/log/php-fpm.log-`date +'%Y%m%d' -d '1days ago'`
    [ ! -f /opt/php/current/tmp/php-fpm.pid ] || kill -USR1 `cat /opt/php/current/tmp/php-fpm.pid`
  endscript
}
EOF

cat <<'EOF' | sudo tee /etc/systemd/system/php-fpm.service
[Unit]
Description=PHP FastCGI Process Manager
After=syslog.target network.target nginx.service

[Service]
Type=forking
User=nginx
Group=nginx
PIDFile=/opt/php/current/tmp/php-fpm.pid
ExecStart=/opt/php/current/sbin/php-fpm
ExecReload=/bin/kill -USR2 $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload

check_command_status "php-fpm用のdaemon-reloadに失敗しました。"

sudo systemctl start nginx

check_command_status "nginxの起動に失敗しました。"

sudo systemctl enable nginx

check_command_status "nginxの自動起動設定に失敗しました。"

sudo systemctl start php-fpm

check_command_status "php-fpmの起動に失敗しました。"

sudo systemctl enable php-fpm

check_command_status "php-fpmの自動起動設定に失敗しました。"

echo "PHP-fpmの設定が完了しました。"

#----------------------------------------------------------#
# Pythonのインストール
# pyenvだと「ERROR: The Python ssl extension was not compiled. Missing the OpenSSL lib?」というエラーが出てインストール出来ないので
# ソースからインストール
#----------------------------------------------------------#
if [ "$IS_PYTHON_INSTALL" -eq 1 ]; then
  echo "Pythonのインストールを行います。"

  print_current_time

  cd /home/${GENERAL_USER_NAME}/src

  curl ${CURL_RETRY_OPTION} -O https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}a1.tar.xz

  check_command_status "Pythonのダウンロードに失敗しました。"

  tar Jxvf Python-${PYTHON_VERSION}a1.tar.xz

  check_command_status "Pythonファイルの解凍に失敗しました。"

  cd Python-${PYTHON_VERSION}a1

  change_dnf_package install "${PYTHON_REQUIRE_PACKAGE}" ${EXEC_USER_NAME}

  check_command_status "Pythonの必須パッケージのインストールに失敗しました。"

  echo "./configure --prefix=/opt/python/${PYTHON_VERSION} --with-openssl=/opt/openssl/current --with-openssl-rpath=auto --with-ensurepip=install --enable-optimizations" > ./python_ccc

  bash ./python_ccc

  check_command_status "Pythonのconfigureに失敗しました。"

  make

  check_command_status "Pythonのmakeに失敗しました。"

  sudo make install

  check_command_status "Pythonのmake installに失敗しました。"

  sudo ln -s /opt/python/${PYTHON_VERSION} /opt/python/current

  sudo sed -i -e 's@^\(export PATH=\)\(.\+\)\(\$PATH\)$@\1\2/opt/python/current/bin:\3@g' /etc/profile

  source /etc/profile

  check_command_status "Pythonの/etc/profileの反映に失敗しました。"

  sudo /opt/python/current/bin/pip3 install --upgrade pip

  sudo /opt/python/current/bin/pip3 install pipenv

  echo 'export PIPENV_VENV_IN_PROJECT=1' | sudo tee -a /etc/profile

  source /etc/profile

  check_command_status "pipenvの/etc/profileの反映に失敗しました。"

  print_current_time

  echo "Pythonのインストールが完了しました。"
fi

#----------------------------------------------------------#
# Redisのインストール
#----------------------------------------------------------#
echo "Redisのインストールを行います。"

print_current_time

sudo useradd -s /bin/false redis

check_command_status "Redisユーザーの作成に失敗しました。"

cd /home/${GENERAL_USER_NAME}/src

curl ${CURL_RETRY_OPTION} -L https://download.redis.io/releases/redis-${REDIS_VERSION}.tar.gz -o redis-${REDIS_VERSION}.tar.gz

check_command_status "Redisのダウンロードに失敗しました。"

tar zxvf ./redis-${REDIS_VERSION}.tar.gz

check_command_status "Redisファイルの解凍に失敗しました。"

cd redis-${REDIS_VERSION}

make

check_command_status "Redisのmakeに失敗しました。"

sudo make PREFIX=/opt/no_sql/redis/${REDIS_VERSION} install

check_command_status "Redisのmake installに失敗しました。"

sudo ln -s /opt/no_sql/redis/${REDIS_VERSION} /opt/no_sql/redis/current

sudo sed -i -e 's@^\(export PATH=\)\(.\+\)\(\$PATH\)$@\1\2/opt/no_sql/redis/current/bin:\3@g' /etc/profile
↲
source /etc/profile
↲
check_command_status "Redisの/etc/profileの反映に失敗しました。"

sudo mkdir -p /etc/redis

sudo mkdir -p /opt/no_sql/redis/current/dir

sudo chmod -R 755 /opt/no_sql/redis/current

sudo chown -R redis:redis /opt/no_sql/redis/${REDIS_VERSION}

sudo cp redis.conf /etc/redis/

sudo sed -i -e 's%^.*\(supervised +\)auto$%\1 systemd%g' /etc/redis/redis.conf

sudo sed -i -e 's%^.*\(dir \)./$%\1/opt/no_sql/redis/current/dir%g' /etc/redis/redis.conf

sudo sed -i -e 's%^.*\(bind 127.0.0.1\).*$%\1%g' /etc/redis/redis.conf

sudo sed -i -e 's%^.*\(protected-mode \).*$%\1yes%g' /etc/redis/redis.conf

sudo sed -i -e 's%^.*\(requirepass \).*$%\1${REDIS_PASSWORD}%g' /etc/redis/redis.conf

cat <<'EOF' | sudo tee /etc/systemd/system/redis.service
[Unit]
Description=Redis In-Memory Data Store
After=network.target

[Service]
Type=notify
ExecStart=/opt/no_sql/redis/current/bin/redis-server /etc/redis/redis.conf
ExecStop=/opt/no_sql/redis/current/bin/redis-cli shutdown
Restart=always
User=redis
Group=redis

RuntimeDirectory=redis
RuntimeDirectoryMode=0755

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload

check_command_status "Redis用のdaemon-reloadに失敗しました。"

sudo systemctl enable redis

check_command_status "Redisの自動起動設定に失敗しました。"

sudo systemctl start redis

check_command_status "Redisの起動に失敗しました。"

redis-cli ping

check_command_status "RedisサーバへのPingに失敗しました。"

print_current_time

echo "Redisのインストールが完了しました。"

#----------------------------------------------------------#
# gitのインストール
#----------------------------------------------------------#
echo "gitのインストールを行います。"

print_current_time

cd /home/${GENERAL_USER_NAME}/src

curl ${CURL_RETRY_OPTION} -L https://github.com/git/git/archive/refs/tags/v${GIT_VERSION}.tar.gz -o git-${GIT_VERSION}.tar.gz

check_command_status "gitのダウンロードに失敗しました。"

tar zxvf ./git-${GIT_VERSION}.tar.gz

check_command_status "gitファイルの解凍に失敗しました。"

cd git-${GIT_VERSION}

change_dnf_package install "${GIT_REQUIRE_PACKAGE}" ${EXEC_USER_NAME}

check_command_status "gitの必須パッケージのインストールに失敗しました。"

# Makefileを作り直さないとmakeに失敗するので、configureファイルを作成してMakefileを作り直す
make configure

check_command_status "gitのconfigureファイルの作成に失敗しました。"

# 何故か、gccコマンドが見つからないエラーが出るので指定（フルパスじゃないとNGだった）
echo "./configure CC=/opt/gcc/current/bin/gcc --prefix=/opt/git/${GIT_VERSION}" > ./git_ccc

bash ./git_ccc

check_command_status "gitのconfigureに失敗しました。"

make all

check_command_status "gitのmakeに失敗しました。"

sudo make install

check_command_status "gitのmake installに失敗しました。"

sudo ln -s /opt/git/${GIT_VERSION} /opt/git/current

sudo sed -i -e 's@^\(export PATH=\)\(.\+\)\(\$PATH\)$@\1\2/opt/git/current/bin:\3@g' /etc/profile

source /etc/profile

check_command_status "gitの/etc/profileの反映に失敗しました。"

git config --global user.email "${SYSTEM_ADMINISTRATOR_MAIL_ADDRESS}"

git config --global user.name "${GENERAL_USER_NAME}"

git config --global alias.st status

git config --global alias.co checkout

git config --global alias.br branch

git config --global alias.cm commit

git config --global alias.di diff

git config --global alias.pl pull

git config --global alias.ps push

git config --global alias.cl clone

git config --global pull.ff only

print_current_time

echo "gitのインストールが完了しました。"

#----------------------------------------------------------#
# githubの公開鍵認証の設定
#----------------------------------------------------------#

echo "githubの公開鍵認証の設定を行います。"

print_current_time

cd /home/${GENERAL_USER_NAME}/.ssh

ssh-keygen -t ed25519 -P "" -f $GITHUB_SSH_KEY_FILE_NAME

check_command_status "github用のSSH鍵の作成に失敗しました。"

curl ${CURL_RETRY_OPTION} -u ${GITHUB_USER_NAME}:${GITHUB_PERSONAL_ACCESS_TOKEN} --data '{"title":"'"$(whoami)@$(hostname)"'","key":"'"$(cat ${GITHUB_SSH_KEY_FILE_NAME}.pub)"'"}' https://api.github.com/user/keys

check_command_status "github用のSSH鍵の登録に失敗しました。"

cat <<EOF | tee /home/${GENERAL_USER_NAME}/.ssh/config
Host GitHub
  User git
  Hostname github.com
  PreferredAuthentications publickey
  IdentityFile ~/.ssh/${GITHUB_SSH_KEY_FILE_NAME}
  StrictHostKeyChecking no
EOF

chmod 600 /home/${GENERAL_USER_NAME}/.ssh/config

ssh -T GitHub

# ここは、成功した時の戻り値が1
if [ "$?" -ne 1 ]; then
  echo "githubへのSSH接続に失敗しました。"
  exit 1
fi

print_current_time

echo "githubの公開鍵認証の設定が完了しました。"

#----------------------------------------------------------#
# final_magicのインストール
#----------------------------------------------------------#

echo "final_magicのインストールを行います。"

print_current_time

sudo mkdir -p /opt/final_magic

sudo chown -R ${GENERAL_USER_NAME}:${GENERAL_USER_NAME} /opt/final_magic

git clone GitHub:${GITHUB_USER_NAME}/final_magic.git /opt/final_magic

check_command_status "final_magicのgit cloneに失敗しました。"

print_current_time

echo "final_magicのインストールが完了しました。"

#----------------------------------------------------------#
# user_registration_formのインストール
#----------------------------------------------------------#
if [ "$IS_USER_REGISTRATION_FORM_INSTALL" -eq 1 ]; then
  echo "user_registration_formのインストールを行います。"

  print_current_time

  sudo mkdir -p ${APPLICATION_BASE_DIRECTORY}/user_registration_form

  sudo chown -R ${GENERAL_USER_NAME}:${GENERAL_USER_NAME} ${APPLICATION_BASE_DIRECTORY}

  git clone GitHub:${GITHUB_USER_NAME}/user_registration_form.git ${APPLICATION_BASE_DIRECTORY}/user_registration_form

  check_command_status "user_registration_formのgit cloneに失敗しました。"

  print_current_time

  echo "user_registration_formのインストールが完了しました。"
fi

#----------------------------------------------------------#
# google-api-php-clientのインストール
#----------------------------------------------------------#
echo "google-api-php-clientのインストールを行います。"

print_current_time

cd /home/${GENERAL_USER_NAME}/src

change_dnf_package install unzip ${EXEC_USER_NAME}

check_command_status "unzipコマンドのインストールに失敗しました。"

# PHP8.3用をダウンロード
curl ${CURL_RETRY_OPTION} -L https://github.com/googleapis/google-api-php-client/releases/download/v${GOOGLE_API_PHP_CLIENT_VERSION}/google-api-php-client--PHP8.3.zip -o google-api-php-client-${GOOGLE_API_PHP_CLIENT_VERSION}.zip

check_command_status "google-api-php-clientのダウンロードに失敗しました。"

unzip google-api-php-client-${GOOGLE_API_PHP_CLIENT_VERSION}.zip -d google-api-php-client-${GOOGLE_API_PHP_CLIENT_VERSION}

sudo mkdir -p /opt/google-api-php-client

sudo mv google-api-php-client-${GOOGLE_API_PHP_CLIENT_VERSION} /opt/google-api-php-client/${GOOGLE_API_PHP_CLIENT_VERSION}

sudo ln -s /opt/google-api-php-client/${GOOGLE_API_PHP_CLIENT_VERSION} /opt/google-api-php-client/current

sudo chown -R ${GENERAL_USER_NAME}:${GENERAL_USER_NAME} /opt/google-api-php-client

print_current_time

echo "google-api-php-clientのインストールが完了しました。"

#----------------------------------------------------------#
# PHPで前日のアクセスログの内容を毎日メール送信する為の設定
#----------------------------------------------------------#
echo "PHPで前日のアクセスログの内容を毎日メール送信する為の設定を行います。"

print_current_time

# 後で修正するのでコメントアウトしておく（後で手動で修正する）
echo '######comment_out_not_auto_edit! 00 01 * * * root /opt/php/current/bin/php {フルパスで実行したいPHPのソースファイルを指定} 2>&1' | sudo tee -a /etc/crontab

print_current_time

echo "PHPで前日のアクセスログの内容を毎日メール送信する為の設定が完了しました。"

#----------------------------------------------------------#
# 本番サーバへのアップ設定
#----------------------------------------------------------#
if [ "$IS_PRODUCTION_SERVER_ACCESS_SETTING" -eq 1 ]; then
  echo "本番サーバへのアップ設定を行います。"

  print_current_time

  cd /home/${GENERAL_USER_NAME}/.ssh

  ssh-keygen -t ed25519 -P "" -f $PRODUCTION_SSH_KEY_FILE_NAME

  check_command_status "本番サーバ用のSSH鍵の作成に失敗しました。"

  cat <<EOF | tee -a /home/${GENERAL_USER_NAME}/.ssh/config
Host ${PRODUCTION_HOST_NAME}
  User ${GENERAL_USER_NAME}
  Hostname ${PRODUCTION_HOST_NAME}
  Port ${PRODUCTION_SSH_PORT}
  PreferredAuthentications publickey
  IdentityFile ~/.ssh/${PRODUCTION_SSH_KEY_FILE_NAME}
  StrictHostKeyChecking no
EOF

  print_current_time

  echo "本番サーバへのアップ設定が完了しました。"
fi

#----------------------------------------------------------#
# rsyncコマンドのインストール
#----------------------------------------------------------#
echo "rsyncコマンドのインストールを行います。"

print_current_time

change_dnf_package install rsync ${EXEC_USER_NAME}

check_command_status "rsyncコマンドのインストールに失敗しました。"

print_current_time

echo "rsyncコマンドのインストールが完了しました。"

#----------------------------------------------------------#
# 本番サーバへのアップ手順設定
#----------------------------------------------------------#
if [ "$IS_PRODUCTION_SERVER_ACCESS_SETTING" -eq 1 ]; then
  echo "本番サーバへのアップ手順設定を行います。"

  print_current_time

  sudo mkdir -p ${APPLICATION_BASE_DIRECTORY}

  sudo chown -R ${GENERAL_USER_NAME}:${GENERAL_USER_NAME} ${APPLICATION_BASE_DIRECTORY}

  cat <<EOF | tee ${APPLICATION_BASE_DIRECTORY}/server_setting_info.conf
# SSHの秘密鍵ファイル
ssh_private_key_file=/home/${GENERAL_USER_NAME}/.ssh/${PRODUCTION_SSH_KEY_FILE_NAME}
# リモートへSSH接続時のポート番号
ssh_port=${PRODUCTION_SSH_PORT}
# リモート側のOSユーザー名
remote_user=${GENERAL_USER_NAME}
# リモート側のホスト名
remote_host=${PRODUCTION_HOST_NAME}
# ローカル側の基準ディレクトリ
local_base_dir=/home/${GENERAL_USER_NAME}/\$1/
# リモート側の基準ディレクトリ
remote_base_dir=${PRODUCTION_RSYNC_BASE_DIRECTORY}/
EOF

  cat <<EOF | tee ${APPLICATION_BASE_DIRECTORY}/diff.sh
#!/bin/sh

if [ \$# -ne 1 ]; then
  echo "指定された引数は\$#個です。" 1>&2
  echo "実行するには1個の引数が必要です。" 1>&2
  exit 1
fi

# サーバー設定情報を読み込む
source ./server_setting_info.conf

# 差分結果と、gitから取得するファイル情報を初期化する
rm -f ./diff_result
rm -rf \$local_base_dir

# gitから最新の情報を取得する
git clone ${GIT_REPOSITORY_DIRECTORY}/\$1.git \$local_base_dir

# .gitディレクトリを除外し、基準ディレクトリ名を除いたファイルパス情報のみに整形する
file_names=\`find \$local_base_dir -path "\${local_base_dir}.git" -prune -o -type f -print | sed "s@\${local_base_dir}@@"\`
for file_name in \$file_names
do
  # ファイル名を出力する
  echo \${1}/\${file_name} >> ./diff_result
  # ローカル側のファイルと、リモート側のファイルの差分を調べて出力する
  ssh -i \$ssh_private_key_file -p \$ssh_port \${remote_user}@\${remote_host} cat \${remote_base_dir}\${file_name} | diff - \${local_base_dir}\${file_name} 2>&1 >> ./diff_result
done
EOF

  chmod 755 ${APPLICATION_BASE_DIRECTORY}/diff.sh

  cat <<EOF | tee ${APPLICATION_BASE_DIRECTORY}/update.sh
#!/bin/sh

if [ \$# -ne 1 ]; then
  echo "指定された引数は\$#個です。" 1>&2
  echo "実行するには1個の引数が必要です。" 1>&2
  exit 1
fi

# サーバー設定情報を読み込む
source ./server_setting_info.conf

# ロールバックの為に、現在のリモート側の内容をバックアップする
ssh -i \$ssh_private_key_file -p \${ssh_port} \${remote_user}@\${remote_host} cp -r --parent \${remote_base_dir} /tmp/

# ローカル側の内容を、リモート側に送る
rsync --checksum -av --exclude-from=exclude_list -e "ssh -i \$ssh_private_key_file -p \${ssh_port}" --delete \$local_base_dir \${remote_user}@\${remote_host}:\${remote_base_dir}

# rsync後に行いたい処理を実行
. ./after.sh
EOF

  chmod 755 ${APPLICATION_BASE_DIRECTORY}/update.sh

  cat <<EOF | tee ${APPLICATION_BASE_DIRECTORY}/rollback.sh
#!/bin/sh

if [ \$# -ne 1 ]; then
  echo "指定された引数は\$#個です。" 1>&2
  echo "実行するには1個の引数が必要です。" 1>&2
  exit 1
fi

# サーバー設定情報を読み込む
source ./server_setting_info.conf

# バックアップしておいた内容を反映する
ssh -i \$ssh_private_key_file -p \${ssh_port} \${remote_user}@\${remote_host} cp -r /tmp\${remote_base_dir}* \$remote_base_dir
EOF

  chmod 755 ${APPLICATION_BASE_DIRECTORY}/rollback.sh

  cat <<EOF | tee ${APPLICATION_BASE_DIRECTORY}/exclude_list
.git
.gitignore
.well-known/acme-challenge/*
EOF

  cat <<EOF | tee ${APPLICATION_BASE_DIRECTORY}/after.sh
#!/bin/sh

# パーミッションの設定
ssh -i \$ssh_private_key_file -p \${ssh_port} \${remote_user}@\${remote_host} chmod -R 777 \${remote_base_dir}.well-known
EOF

  chmod 755 ${APPLICATION_BASE_DIRECTORY}/after.sh

  print_current_time

  echo "本番サーバへのアップ手順設定が完了しました。"
fi

#---------------------------------------------------------------------#
# Let's Encryptの導入
# DNSの正引きの設定を終えてからじゃないとcertbotでエラーになるので注意
# @see https://techwiki.u-ff.com/centos/certbot/migration
#---------------------------------------------------------------------#
if [ "$IS_LETS_ENCRYPT" -eq 1 ]; then
  echo "Let's Encryptの導入を行います。"

  print_current_time

  # certbotを https://github.com/certbot からソースをダウンロードしてインストールすることも可能だが、certbotコマンド実行時にpythonエラーが発生して修正出来なかったのでパッケージからインストール
  sudo dnf install certbot python3-certbot-nginx

  sudo cp /opt/nginx/current/conf.d/http.conf /opt/nginx/current/conf.d/http.conf.org

  cat <<EOF | sudo tee /opt/nginx/current/conf.d/http.conf
server {
  listen ${HTTP_PORT};
  server_name ${HOST_NAME};
  root ${DOCUMENT_ROOT};

  # 既に同じドメインで運用中のWebサーバがある場合だと、ドキュメントルートを変えないと上手くいかない？ので変更している
  location ^~ /.well-known/acme-challenge/ {
    root /opt/challenge;
    default_type "text/plain";
  }

  index index.php index.html;

  location / {
    try_files \$uri \$uri/ /index.php\$is_args\$args;
  }

  location ~ \.php$ {
    try_files \$uri =404;
    include /opt/nginx/current/conf/fastcgi_params;
    fastcgi_pass unix:/opt/php/current/tmp/php-fpm.sock;
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    fastcgi_param PHP_ENV ${ENVIRONMENT_FULL};
  }
}
EOF

  sudo systemctl restart nginx

  check_command_status "Let's Encrypt certbot用のnginxの再起動に失敗しました。"

  sudo mkdir -p /opt/challenge/.well-known/acme-challenge

  sudo chmod -R 777 /opt/challenge

  sudo rm -rf /var/cache/dnf/*

  sudo dnf clean all

  sudo certbot certonly --preferred-chain "ISRG Root X1" --webroot -w /opt/challenge -d ${HOST_NAME} --email ${SYSTEM_ADMINISTRATOR_MAIL_ADDRESS} --agree-tos -n --force-renewal --rsa-key-size ${RSA_KEY_SIZE}

  check_command_status "certbotの実行に失敗しました。"

  # PFSのためのDHパラメータの生成
  sudo mkdir -p /opt/nginx/current/ssl

  /opt/openssl/current/bin/openssl dhparam ${RSA_KEY_SIZE} | sudo tee /opt/nginx/current/ssl/dh${RSA_KEY_SIZE}.pem

  sudo nft add rule ip my_nft4_table TCP tcp dport ${HTTPS_PORT} update @httpv4_dos_counter { ip saddr limit rate over 20/minute burst 1 packets } log prefix \"HTTPV4 Attacked:\" drop

  sudo nft add rule ip my_nft4_table TCP tcp dport ${HTTPS_PORT} accept

  sudo nft add rule ip6 my_nft6_table TCPV6 tcp dport ${HTTPS_PORT} update @httpv6_dos_counter { ip6 saddr limit rate over 20/minute burst 1 packets } log prefix \"HTTPV6 Attacked:\" drop

  sudo nft add rule ip6 my_nft6_table TCPV6 tcp dport ${HTTPS_PORT} accept

  sudo cp /opt/nginx/current/conf.d/http.conf /opt/nginx/current/conf.d/http.conf2.org

  cat <<EOF | sudo tee /opt/nginx/current/conf.d/http.conf
server {
  # IPv4とIPv6の両方でHTTPリクエストを受け付ける。
  listen *:${HTTP_PORT};
  listen [::]:${HTTP_PORT};
  server_name ${HOST_NAME};

  # HTTPからのアクセスをHTTPSへリダイレクトする。
  return 301 https://\$host\$request_uri;
}
EOF

  cat <<EOF | sudo tee /opt/nginx/current/conf.d/https.conf
server {
  listen ${HTTPS_PORT} ssl default_server;
  listen [::]:${HTTPS_PORT} ssl default_server;
  http2 on;

  server_name ${HOST_NAME};

  ssl_certificate     /etc/letsencrypt/live/${HOST_NAME}/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/${HOST_NAME}/privkey.pem;

  ssl_session_timeout 5m;
  ssl_session_cache shared:ssl:10m;
  ssl_session_tickets off;

  ssl_dhparam /opt/nginx/current/ssl/dh${RSA_KEY_SIZE}.pem;

  ssl_protocols TLSv1.2 TLSv1.3;
  ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305;
  ssl_prefer_server_ciphers on;
  ssl_ecdh_curve secp384r1;

  # 31536000は365日
  add_header Strict-Transport-Security "max-age=31536000;";

  root ${DOCUMENT_ROOT};

  location ^~ /.well-known/acme-challenge {
    root /opt/challenge;
    default_type "text/plain";
  }

  index index.php index.html;

  location / {
    try_files \$uri \$uri/ /index.php\$is_args\$args;
  }

  location ^~ /config/ {
    return 404;
  }

  location ~ \.php$ {
    try_files \$uri =404;
    include /opt/nginx/current/conf/fastcgi_params;
    fastcgi_pass unix:/opt/php/current/tmp/php-fpm.sock;
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    fastcgi_param PHP_ENV ${ENVIRONMENT_FULL};
  }
}
EOF

  sudo systemctl restart nginx

  check_command_status "Let's Encrypt用のnginxの再起動に失敗しました。"

  systemctl stop certbot-renew.timer

  systemctl disable certbot-renew.timer

  # 後で修正するのでコメントアウトしておく
  echo "######comment_out! 00 03 1-31/5 * * root /usr/bin/certbot renew -q --preferred-chain \"ISRG Root X1\" --rsa-key-size ${RSA_KEY_SIZE} --deploy-hook \"/usr/bin/systemctl restart nginx\" > /etc/letsencrypt/certbot.log" | sudo tee -a /etc/crontab

  print_current_time

  echo "Let's Encryptの導入が完了しました。"
fi

#----------------------------------------------------------#
# dnfの設定
#----------------------------------------------------------#
echo "dnfの設定を行います。"

print_current_time

sudo cp /etc/dnf/dnf.conf /etc/dnf/dnf.conf.org

check_command_status "dnf設定ファイルのバックアップに失敗しました。"

sudo sed -i -e 's/^keepcache.*=.*/keepcache=1/g' /etc/dnf/dnf.conf

change_dnf_package install dnf-automatic ${EXEC_USER_NAME}

check_command_status "dnf-automaticのインストールに失敗しました。"

sudo cp /etc/dnf/automatic.conf /etc/dnf/automatic.conf.org

check_command_status "dnf-automatic設定ファイルのバックアップに失敗しました。"

sudo sed -i -e 's/^download_updates.*=.*/download_updates = no/g' /etc/dnf/automatic.conf

sudo sed -i -e 's/^apply_updates.*=.*/apply_updates = no/g' /etc/dnf/automatic.conf

sudo sed -i -e 's/^emit_via.*=.*/emit_via = email/g' /etc/dnf/automatic.conf

sudo sed -i -e 's/^email_to.*=.*/email_to = '${SYSTEM_ADMINISTRATOR_MAIL_ADDRESS}'/g' /etc/dnf/automatic.conf

# リポジトリデータのダウンロードとメール通知のみ行う
sudo systemctl start dnf-automatic-notifyonly.timer

check_command_status "dnf-automatic-notifyonly.timerの起動に失敗しました。"

sudo systemctl enable dnf-automatic-notifyonly.timer

check_command_status "dnf-automatic-notifyonly.timerの自動起動の設定に失敗しました。"

print_current_time

echo "dnfの設定が完了しました。"
