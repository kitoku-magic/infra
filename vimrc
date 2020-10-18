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
