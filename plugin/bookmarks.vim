vim9script

if v:version < 900 || exists("g:loaded_vim_bookmarks")
    finish
endif

g:loaded_vim_bookmarks = 1

import autoload "bookmarks.vim"

command -nargs=0 BookmarksCleanCache bookmarks.CleanCache()

if exists("*fzf#run") && exists("*fzf#wrap")

  def B(bang: bool)
    if bang | bookmarks.CleanCache() | endif
    var Frun = fzf#run
    var Fwrap = fzf#wrap
    Frun(Fwrap({
      source: bookmarks.CompleteList(),
      sink: (q: string) => {
        var url = matchstr(q, '\[\((\zshttp[s]\=://.*\..*\ze)\)\]')
        bookmarks.OpenBookmark(url)
      } }))
  enddef

  command -bang -nargs=0 Bookmarks B(<bang>false)

else
  def B(q: string, bang: bool)
    if bang | bookmarks.CleanCache() | endif
    var url = matchstr(q, '\[\((\zshttp[s]\=://.*\..*\ze)\)\]')
    bookmarks.OpenBookmark(url)
  enddef

  command -bang -nargs=1 -complete=customlist,bookmarks.CompleteList Bookmarks B(<q-args>, <bang>false)
endif

