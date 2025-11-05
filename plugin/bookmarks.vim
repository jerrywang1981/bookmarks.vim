vim9script

if v:version < 900 || exists("g:loaded_vim_bookmarks")
    finish
endif

g:loaded_vim_bookmarks = 1

import autoload "bookmarks.vim"

def Bk(q: string, bang: bool)
  if bang | bookmarks.CleanCache() | endif
  var url = matchstr(q, '\[\((\zshttp[s]\=://.*\..*\ze)\)\]')
  bookmarks.OpenBookmark(url)
enddef

def Bfzf(bang: bool)
  if bang | bookmarks.CleanCache() | endif
  if !exists("*fzf#run") || !exists("*fzf#wrap")
    echom "fzf plugin was not installed"
    return
  endif
  var Frun = fzf#run
  var Fwrap = fzf#wrap
  Frun(Fwrap({
    source: bookmarks.CompleteList(),
    sink: (q: string) => {
      var url = matchstr(q, '\[\((\zshttp[s]\=://.*\..*\ze)\)\]')
      bookmarks.OpenBookmark(url)
    } }))
enddef

command -nargs=0 BookmarksCleanCache bookmarks.CleanCache()
command -bang -nargs=1 -complete=customlist,bookmarks.CompleteList Bookmarks Bk(<q-args>, <bang>false)
command -bang -nargs=0 BookmarksFzf Bfzf(<bang>false)
