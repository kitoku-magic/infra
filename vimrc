"新しい行を開始したときに、新しい行のインデントを現在行と同じ量にする
set autoindent
"見やすい色を表示するようにVimに背景色を教える
set background=light
"バックスペースキーの動作を決定する
set backspace=2
"バックアップを取る
set backup
"バックアップファイルの拡張子
set backupext=.vimbak
"Cプログラムファイルの自動インデントを始める
set cindent
"クリップボードの動作設定（コンパイルオプションで+clipboardになっている必要がある）
set clipboard=unnamed,autoselect
"ファイルを保存していない場合に、ファイルの保存を確認するダイアログを出す
set confirm
"検索結果をハイライトする
set hlsearch
"検索で、大文字小文字を区別しない
set ignorecase
"インクリメンタルサーチを行う
set incsearch
"タブ文字、行末など不可視文字を表示する
set list
"listで表示される文字のフォーマットを指定する。行末文字は「半スペ」、タブ文字は「^ 」、行末のスペースは「-」
set listchars=eol:\ ,tab:^\ ,trail:-
"行番号を表示する
"set number
"自動インデントの各段階に使われる空白の数
set shiftwidth=2
"ファイル内の <Tab> が対応する空白の数
set tabstop=2
"viminfoファイルの設定
set viminfo=
"補完候補を表示する
set wildmenu
"検索をファイルの末尾まで検索したら、ファイルの先頭へループしない
set nowrapscan

"挿入モードで貼り付けを行う時にペーストモードに切り替える
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

"挿入モードから抜ける時にペーストモードを解除する
autocmd InsertLeave * set nopaste

"autocmd FileType php set tags=/opt/final_magic/.tags
