# infra
インフラ関係の内容を扱うリポジトリです。

ファイルの内容は、以下の通りです。
- vimrc（vimで用いる設定ファイルです）
- auto_install（環境構築の自動化を目的とした、シェルスクリプトが書かれています）

# auto_installについて
Rocky Linux9をminimal installした直後に実行して、任意の環境構築を自動で行う為のスクリプトです。

Rocky Linux8は未確認（9とバージョンが記載されている箇所だけ直せば動くかもしれません）です。

また、よく似ているAlmaLinuxでも殆ど修正無しで動くかもしれませんが、未確認です。

## 各ファイルの説明
- auto_install_start.sh  
↓  
実行開始のファイルです。  
また、rootユーザーとして処理を行う箇所が書かれています。  

- auto_install_start_by_{GENERAL_USER_NAME}.sh  
↓  
{GENERAL_USER_NAME}ユーザーとして処理を行う箇所のファイルです。  
上記の、auto_install_start.shから呼ばれます。  

- auto_install_start_functions.sh  
↓  
共通関数が定義してあるファイルです。  
auto_install_start.shとauto_install_start_by_{GENERAL_USER_NAME}.shから呼ばれます。  

- auto_install_start_init.sh  
↓  
起動条件のチェックなど、初期処理が定義してあるファイルです。  
auto_install_start.shとauto_install_start_by_{GENERAL_USER_NAME}.shから呼ばれます。  

- parameter_{ENVIRONMENT}.conf  
↓  
実行環境毎に異なるパラメータ値を定義するファイルです。  
auto_install_start.shとauto_install_start_by_{GENERAL_USER_NAME}.shから呼ばれます。  

## 実行方法
1. SSH接続に使う公開鍵と秘密鍵を作り、parameter_{ENVIRONMENT}.conf内の、「SSH_PUBLIC_KEY」変数に、作成した公開鍵の内容を設定する。  
2. parameter_{ENVIRONMENT}.confの{ENVIRONMENT}の箇所や、ファイル内の他の項目の内容も、インストール対象の環境に応じて変更する。  
3. auto_install_start_by_{GENERAL_USER_NAME}.shの{GENERAL_USER_NAME}の箇所を、インストール対象の環境に応じて変更する。  
4. Githubの二段階認証が有効の場合、以下URLの手順で、「Personal access tokens」を取得（スコープは、write:public_keyのみチェック）して、
parameter_{ENVIRONMENT}.conf内の、「GITHUB_PERSONAL_ACCESS_TOKEN」変数に、作成したアクセストークンの内容を設定する。  
https://howpon.com/5308  
5. 実行対象のサーバーにSCPなどを用いて、上記の5ファイルを設置（5ファイル全てを必ず同じディレクトリ内に置く）する。  
6. swapパーティションが存在しない環境の場合は、以下URLの内容を参考にswapfileを作成する。  
https://manual.sakura.ad.jp/vps/os-packages/add-swapfile.html  
7. rootユーザーで以下コマンドの、自動インストールシェルスクリプトを実行する（timeコマンドは任意）。  
```time bash auto_install_start.sh {ENVIRONMENT}```  
（実行確認を２回行う対話処理を外した場合は、以下も可能）  
```time bash auto_install_start.sh {ENVIRONMENT} > /root/install.log 2>&1 &```  
8. 実行が終了したら、auto_install_start.shのファイル末尾に書かれている事や、環境に応じた手動での修正を行う。  

# 免責事項
実行対象のサーバーに大きな変更（カーネルのバージョンアップも含む）が発生しますので、  

実行の際に実行確認も表示されますが、細心の注意を払ってください。  

また、自己責任でお願いします。  

また、実際の業務でも使う事を意識して作っていますが、  

当然、業務によって仕様なども違いますので、  

参考程度にして下さい。
