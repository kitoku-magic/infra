#!/bin/bash

#----------------------------------------------------------#
# 【注意】
# 本スクリプトは、サーバー環境構築の効率化を目的にした
# 自動での環境構築スクリプトです。
# よって、実行対象のサーバー環境を大幅に変更する為
# 実行前には、改めて考え直して下さい。
#
# 対象OS：minimal installしたCentOS7系
# （6系はNG、8系は未確認です）
#----------------------------------------------------------#

#----------------------------------------------------------#
# 初期処理
#----------------------------------------------------------#
echo "自動インストールを開始します。"

# 共通関数を読み込む
source ./auto_install_start_functions.sh

# 初期処理
source ./auto_install_start_init.sh 1 "$#" "${1}" root

check_command_status "初期処理が失敗しました。"

# 各種パラメータ情報を読み込む
source ./parameter_"${1}".conf

# 処理を続けるか否かの確認（対話式）
echo "------------------------------------"
echo "処理を続けますか？"
echo "  続ける場合は yes と入力して下さい。"
read INPUT

if [ "$INPUT" != "yes" ]; then
  echo "処理を終了します。" 1>&2
  exit 1
fi

echo "------------------------------------"
echo "本当に 処理を続けますか？"
echo "  続ける場合は yes と入力して下さい。"
read INPUT

if [ "$INPUT" != "yes" ]; then
  echo "処理を終了します。" 1>&2
  exit 1
fi

print_current_time

echo "------------------------------------"
echo "本処理を開始します。"

#----------------------------------------------------------#
# rootのパスワードの設定
#----------------------------------------------------------#
echo "rootのパスワードを設定します。"

echo "$ROOT_PASSWORD" | passwd --stdin root

check_command_status "rootのパスワードが設定出来ませんでした。"

echo "rootのパスワードを設定しました。"

#----------------------------------------------------------#
# SELinuxの設定（無効化）
#----------------------------------------------------------#
echo "SELINUXを無効化します。"

cp /etc/selinux/config /etc/selinux/config.org

check_command_status "SELINUXの設定ファイルのバックアップに失敗しました。"

sed -i -e '/^SELINUX *=.*/s/^/# /g' /etc/selinux/config && echo 'SELINUX=disabled' >> /etc/selinux/config

check_command_status "SELINUXの設定ファイルの編集に失敗しました。"

setenforce 0

check_command_status "SELINUXを無効化出来ませんでした。"

echo "SELINUXを無効化しました。"

#----------------------------------------------------------#
# GRUBの設定（カーネルオプションの設定）
#----------------------------------------------------------#
echo "起動時のカーネルオプションを設定します。"

cp /etc/default/grub /etc/default/grub.org

check_command_status "GRUBの編集用設定ファイルのバックアップに失敗しました。"

sed -i -e '/^GRUB_CMDLINE_LINUX *=.*/s/^/# /g' /etc/default/grub && echo "GRUB_CMDLINE_LINUX=${GRUB_KERNEL_OPTION}" >> /etc/default/grub

check_command_status "GRUBの編集用設定ファイルの修正に失敗しました。"

cp $GRUB_CONFIG_FILE_NAME ${GRUB_CONFIG_FILE_NAME}.org

check_command_status "GRUBの設定ファイルのバックアップに失敗しました。"

grub2-mkconfig -o $GRUB_CONFIG_FILE_NAME

check_command_status "起動時のカーネルオプションが設定出来ませんでした。"

echo "起動時のカーネルオプションを設定しました。"

#----------------------------------------------------------#
# ネットワークとホスト名の設定（IPv6の有効化）
#----------------------------------------------------------#
echo "ネットワークとホスト名の設定を行います。"

cp /etc/sysconfig/network-scripts/ifcfg-${NETWORK_DEVICE_NAME} /etc/sysconfig/network-scripts/ifcfg-${NETWORK_DEVICE_NAME}.org

check_command_status "ネットワークインタフェース設定ファイルのバックアップに失敗しました。"

CONNECTION_AUTOCONNECT_KEY='connection.autoconnect'
IPV4_METHOD_KEY='ipv4.method'
IPV4_ADDRESSES_KEY='ipv4.addresses'
IPV4_GATEWAY_KEY='ipv4.gateway'
IPV4_DNS_KEY='ipv4.dns'
IPV4_DNS_OPTIONS_KEY='ipv4.dns-options'
IPV4_IGNORE_AUTO_DNS_KEY='ipv4.ignore-auto-dns'
IPV4_DNS_SEARCH_KEY='ipv4.dns-search'

declare -a IPV4_KEY_SETTINGS=(
  ${CONNECTION_AUTOCONNECT_KEY}
  ${IPV4_METHOD_KEY}
  ${IPV4_ADDRESSES_KEY}
  ${IPV4_GATEWAY_KEY}
  ${IPV4_DNS_KEY}
  ${IPV4_DNS_OPTIONS_KEY}
  ${IPV4_IGNORE_AUTO_DNS_KEY}
  ${IPV4_DNS_SEARCH_KEY}
)

# bashのver4から使える様になった、連想配列を定義
declare -A IPV4_SETTINGS

IPV4_SETTINGS[${CONNECTION_AUTOCONNECT_KEY}]='yes'
IPV4_SETTINGS[${IPV4_METHOD_KEY}]='manual'
IPV4_SETTINGS[${IPV4_ADDRESSES_KEY}]=$IPV4_ADDRESS
IPV4_SETTINGS[${IPV4_GATEWAY_KEY}]=$IPV4_GATEWAY
IPV4_SETTINGS[${IPV4_DNS_KEY}]=$IPV4_DNS_LIST
IPV4_SETTINGS[${IPV4_DNS_OPTIONS_KEY}]='single-request-reopen'
IPV4_SETTINGS[${IPV4_IGNORE_AUTO_DNS_KEY}]='yes'
IPV4_SETTINGS[${IPV4_DNS_SEARCH_KEY}]=$IPV4_DNS_SEARCH

for k in ${IPV4_KEY_SETTINGS[@]}
do
  if [ "${IPV4_SETTINGS[$k]}" != "" ]; then
    nmcli connection modify $NETWORK_CONNECTION_NAME $k ${IPV4_SETTINGS[$k]}

    check_command_status "${k}の設定に失敗しました。"
  fi
done

nmcli general hostname $HOST_NAME

check_command_status "ホスト名の設定に失敗しました。"

cp /etc/sysconfig/network /etc/sysconfig/network.org

check_command_status "/etc/sysconfig/networkのバックアップに失敗しました。"

echo 'NOZEROCONF=yes' | tee -a /etc/sysconfig/network

cp /etc/hosts /etc/hosts.org

check_command_status "hosts設定ファイルのバックアップに失敗しました。"

sed -i -e "/^127\.0\.0\.1.\+/s/$/ ${HOST_NAME}/g" /etc/hosts

if [ "$IS_IPV6_SETTING" -eq 1 ]; then
  sed -i -e "/^::1.\+/s/$/ ${HOST_NAME}/g" /etc/hosts
fi

IPV6_METHOD_KEY='ipv6.method'
IPV6_ADDRESSES_KEY='ipv6.addresses'
IPV6_GATEWAY_KEY='ipv6.gateway'
IPV6_DNS_KEY='ipv6.dns'
IPV6_IGNORE_AUTO_DNS_KEY='ipv6.ignore-auto-dns'

declare -a IPV6_KEY_SETTINGS=(
  ${IPV6_METHOD_KEY}
  ${IPV6_ADDRESSES_KEY}
  ${IPV6_GATEWAY_KEY}
  ${IPV6_DNS_KEY}
  ${IPV6_IGNORE_AUTO_DNS_KEY}
)

declare -A IPV6_SETTINGS

IPV6_SETTINGS[${IPV6_METHOD_KEY}]=$IPV6_METHOD
IPV6_SETTINGS[${IPV6_ADDRESSES_KEY}]=$IPV6_ADDRESS
IPV6_SETTINGS[${IPV6_GATEWAY_KEY}]=$IPV6_GATEWAY
IPV6_SETTINGS[${IPV6_DNS_KEY}]=$IPV6_DNS
IPV6_SETTINGS[${IPV6_IGNORE_AUTO_DNS_KEY}]=$IPV6_IGNORE_AUTO_DNS

for k in ${IPV6_KEY_SETTINGS[@]}
do
  if [ "${IPV6_SETTINGS[$k]}" != "" ]; then
    nmcli connection modify $NETWORK_CONNECTION_NAME $k ${IPV6_SETTINGS[$k]}

    check_command_status "${k}の設定に失敗しました。"
  fi
done

cp /etc/sysctl.conf /etc/sysctl.conf.org

check_command_status "カーネルパラメータの設定ファイルのバックアップに失敗しました。"

sed -i -e '/^net\.ipv6\.conf\.all\.disable_ipv6.*/s/^/# /g' /etc/sysctl.conf && echo "net.ipv6.conf.all.disable_ipv6 = ${NET_IPV6_CONF_ALL_DISABLE_IPV6}" >> /etc/sysctl.conf

check_command_status "カーネルパラメータのIPV6のall設定に失敗しました。"

sed -i -e '/^net\.ipv6\.conf\.default\.disable_ipv6.*/s/^/# /g' /etc/sysctl.conf && echo "net.ipv6.conf.default.disable_ipv6 = ${NET_IPV6_CONF_DEFAULT_DISABLE_IPV6}" >> /etc/sysctl.conf

check_command_status "カーネルパラメータのIPV6のdefault設定に失敗しました。"

sysctl -p

check_command_status "カーネルパラメータの反映に失敗しました。"

# 後で戻す
nmcli connection modify $NETWORK_CONNECTION_NAME ${IPV4_DNS_KEY} "${IPV4_DNS} 8.8.8.8 8.8.4.4"

systemctl restart network.service

check_command_status "networkの再起動に失敗しました。"

systemctl restart NetworkManager.service

check_command_status "NetworkManagerの再起動に失敗しました。"

echo "ネットワークとホスト名の設定が完了しました。"

#----------------------------------------------------------#
# 不要なパッケージのアンインストール
#----------------------------------------------------------#
echo "不要なYUMパッケージのアンインストールを行います。"

echo 'retries=60' >> /etc/yum.conf

echo 'timeout=600' >> /etc/yum.conf

echo 'include_only=.jp' >> /etc/yum/pluginconf.d/fastestmirror.conf

change_yum_package remove "${YUM_REMOVE_PACKAGE}"

check_command_status "不要なYUMパッケージのアンインストールに失敗しました。"

echo "不要なYUMパッケージのアンインストールが完了しました。"

#----------------------------------------------------------#
# YUMリポジトリの追加
#----------------------------------------------------------#
echo "YUMリポジトリの追加を行います。"

change_yum_package install "${ADD_YUM_REPOSITORY}"

check_command_status "YUMリポジトリの追加に失敗しました。"

if [ -f /etc/yum.repos.d/epel.repo ]; then
  cp /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo.org

  sed -i -e '/^metalink=http.\+?repo=epel-7&.\+/s/^/#/g' /etc/yum.repos.d/epel.repo

  check_command_status "EPELリポジトリのmetalink行の編集に失敗しました。"

  sed -i -e 's@^#\(baseurl=http://\)\(.\+\)\(\.fedoraproject.\+\$basearch\)$@\1dl\3@g' /etc/yum.repos.d/epel.repo

  check_command_status "EPELリポジトリのbaseurl行の編集に失敗しました。"
fi

echo "YUMリポジトリの追加が完了しました。"

#----------------------------------------------------------#
# システムのアップデート
#----------------------------------------------------------#
echo "YUMパッケージのアップデートを行います。"

print_current_time

change_yum_package update

check_command_status "YUMパッケージのアップデートに失敗しました。"

print_current_time

echo "YUMパッケージのアップデートが完了しました。"

#----------------------------------------------------------#
# 時刻の設定と同期
#----------------------------------------------------------#
echo "時刻の同期設定を行います。"

change_yum_package install chrony

systemctl restart chronyd

cp /etc/chrony.conf /etc/chrony.conf.org

check_command_status "時刻設定ファイルのバックアップに失敗しました。"

sed -i -e '/^server .*/s/^/# /g' /etc/chrony.conf

for NTP_SERVER_NAME in ${NTP_SERVER_NAME_LIST[@]}
do
  echo "server ${NTP_SERVER_NAME} iburst" >> /etc/chrony.conf
done

echo "allow $CHRONY_ALLOW_NETWORK_ADDRESS" >> /etc/chrony.conf

check_command_status "時刻設定ファイルの修正に失敗しました。"

chronyc makestep

check_command_status "時刻の手動での同期に失敗しました。"

systemctl restart chronyd

check_command_status "時刻の同期設定に失敗しました。"

systemctl enable chronyd

check_command_status "時刻の同期モジュールの自動起動設定に失敗しました。"

echo "時刻の同期設定が完了しました。"

#----------------------------------------------------------#
# ユーザーの追加とパスワードの設定
#----------------------------------------------------------#
echo "一般ユーザーの追加とパスワードの設定を行います。"

useradd $GENERAL_USER_NAME

check_command_status "一般ユーザーの新規作成に失敗しました。"

echo "$GENERAL_USER_PASSWORD" | passwd --stdin $GENERAL_USER_NAME

check_command_status "一般ユーザーのパスワードが設定出来ませんでした。"

gpasswd -a $GENERAL_USER_NAME wheel

check_command_status "一般ユーザーのwheelグループへの追加に失敗しました。"

echo "ユーザーの追加とパスワードの設定が完了しました。"

#----------------------------------------------------------#
# suの設定
#----------------------------------------------------------#
echo "suの権限設定を行います。"

cp /etc/pam.d/su /etc/pam.d/su.org

check_command_status "PAM設定ファイルのバックアップに失敗しました。"

sed -i -e '/^auth\s\+required\s\+pam_wheel\.so\s\+use_uid/s/^/# /g' /etc/pam.d/su && echo 'auth           required        pam_wheel.so use_uid' >> /etc/pam.d/su

check_command_status "pamの権限設定に失敗しました。"

cp /etc/sudoers /etc/sudoers.org

check_command_status "sudo設定ファイルのバックアップに失敗しました。"

sed -i -e '/^Defaults\s\+requiretty/s/^/# /g' /etc/sudoers && \

sed -i -e '/^%wheel\s\+.*/s/^/# /g' /etc/sudoers && \

echo 'Defaults    requiretty' >> /etc/sudoers && \

echo 'Defaults:%wheel    !requiretty' >> /etc/sudoers && \

# 一時的にパスワード入力を不要にする為の設定
echo '%wheel    ALL=(ALL)    NOPASSWD: ALL' >> /etc/sudoers

check_command_status "sudoの権限設定に失敗しました。"

echo "suの権限設定が完了しました。"

#----------------------------------------------------------#
# 一般ユーザーの処理
#----------------------------------------------------------#
echo "ユーザー${GENERAL_USER_NAME}の処理を開始します。"

cp ./auto_install_start_init.sh /home/$GENERAL_USER_NAME/auto_install_start_init.sh
cp ./parameter_${1}.conf /home/$GENERAL_USER_NAME/parameter_${1}.conf
cp ./auto_install_start_functions.sh /home/$GENERAL_USER_NAME/auto_install_start_functions.sh
cp ./auto_install_start_by_${GENERAL_USER_NAME}.sh /home/$GENERAL_USER_NAME/auto_install_start_by_${GENERAL_USER_NAME}.sh

su - $GENERAL_USER_NAME -c "script -c 'source /home/$GENERAL_USER_NAME/auto_install_start_by_${GENERAL_USER_NAME}.sh ${1} $GENERAL_USER_NAME'"

check_command_status "ユーザー${GENERAL_USER_NAME}の処理が失敗しました。"

rm -rf /home/$GENERAL_USER_NAME/auto_install_start_init.sh
rm -rf /home/$GENERAL_USER_NAME/parameter_${1}.conf
rm -rf /home/$GENERAL_USER_NAME/auto_install_start_functions.sh
rm -rf /home/$GENERAL_USER_NAME/auto_install_start_by_${GENERAL_USER_NAME}.sh
rm -rf /home/$GENERAL_USER_NAME/typescript

nmcli connection modify $NETWORK_CONNECTION_NAME ${IPV4_DNS_KEY} "${IPV4_DNS_LIST}"

# crontabのコメントアウトを外す
sed -i -e 's/^######comment_out! \(.*\)/\1/g' /etc/crontab

check_command_status "/etc/crontabのコメントアウトに失敗しました。"

# パスワード入力を必要にする為の再設定
sed -i -e '/^%wheel\s\+.*/s/^/# /g' /etc/sudoers && \
echo '%wheel  ALL=(ALL)       ALL' >> /etc/sudoers

# 手動で、全てのユーザー毎に「crontab -l」を実行して、/etc/crontabに移す。移したら「crontab -r」を実行する

# バックアップファイル（.org）を、任意の場所に移動する（特にifcfg-ファイル等、そのままにしておくと読み込まれて問題が起きる為）

echo "全ての処理が完了しました。変更を反映させる為に再起動して下さい。"

print_current_time
