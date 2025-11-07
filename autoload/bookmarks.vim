vim9script

if v:version < 900
  finish
endif

import "../lib/utils.vim"
import "../lib/chrome.vim"

const os = utils.GetOS()

final cache: dict<any> = {}

# keys : chrome, firefox, safari
const parsers = { chrome: chrome.Parse, edge: chrome.Parse }

if !exists("g:vim_bookmarks_browsers")
  g:vim_bookmarks_browsers = ["chrome", "edge", "chromium"]
endif

const default_config: dict<dict<dict<any>>> = {
  Windows: {
    chrome: {
      fileName: "",
      file: [ "AppData", "Local", "Google", "Chrome", "User Data", "Default", "Bookmarks" ],
      type: "",
      parser: chrome.Parse
    },
    edge: {
      fileName: "",
      file: [ "AppData", "Local", "Microsoft", "Edge", "User Data", "Default", "Bookmarks" ],
      type: "chrome",
    }
  },
  Linux: {
    chromium: {
      file: [".config", "chromium", "Default", "Bookmarks"],
      type: "chrome"
    }
  },
  Darwin: {

  }
}

def GetMergedConfig(browser_name: string): dict<any>
  var config = deepcopy(default_config)

  if exists("g:vim_bookmarks_config")
    if has_key(g:vim_bookmarks_config, os)
        && has_key(g:vim_bookmarks_config[os], browser_name)
      extend(config[os][browser_name], g:vim_bookmarks_config[os][browser_name])
    endif
  endif

  if !has_key(config, os) | return {} | endif
  if !has_key(config[os], browser_name) | return {} | endif
  return config[os][browser_name]
enddef

def GetBookmarkFileName(cfg: dict<any>): string
  if empty(cfg) | return "" | endif
  if has_key(cfg, "fileName") && !empty(cfg["fileName"])
    if filereadable(cfg["fileName"])
      return cfg["fileName"]
    else
      echo "Bookmark file " .. cfg["fileName"] .. " is not readable"
      return ""
    endif
  endif

  if has_key(cfg, "file")
      && type(cfg["file"]) == type([])
    var filename = expand($HOME .. "/" .. join(cfg['file'], '/'))
    if filereadable(filename)
      return filename
    else
      echom "Bookmark file " .. filename .. " is not readable"
    endif
  endif
  echo "Please config either file or fileName in g:vim_bookmarks_config[" .. os .. "]"
  return ""
enddef

def GetBookmarkParser(cfg: dict<any>): func(string): list<dict<any>>
  if empty(cfg) | return null_function | endif

  if has_key(cfg, "parser")
    return cfg["parser"]
  elseif has_key(cfg, "type") && has_key(parsers, cfg["type"])
    return parsers[cfg["type"]]
  endif
  echo "Please config either parser(function) or type(string, e.g. chrome) in g:vim_bookmarks_config[" .. os .. "]"
  return null_function
enddef


export def GetBookmarks(...browsers: list<string>): list<dict<any>>
  var result: list<dict<any>>
  if browsers->len() == 0 | return result | endif
  for browser in browsers
    if has_key(cache, browser)
      extend(result, cache[browser])
      continue
    endif

    var cfg = GetMergedConfig(browser)
    var filename = GetBookmarkFileName(cfg)
    if empty(filename) | continue | endif
    var F = GetBookmarkParser(cfg)
    if F == v:null | continue | endif
    var data = call(F, [filename])
    data = map(data, (_, v) => extend(v, { browser: browser }))
    cache[browser] = data
    extend(result, data)
  endfor
  return result
enddef

export def CleanCache()
  for k in keys(cache)
    unlet cache[k]
  endfor
enddef

export def OpenBookmark(url: string)
  # if bang | CleanCache() | endif
  # var url = matchstr(q, '\[\((\zshttp[s]\=://.*\..*\ze)\)\]')
  if exists_compiled(":URLOpen") == 2
    :execute "URLOpen " .. url
  else
    @+ = url
    echom "The url was saved in clipboard: " .. url
  endif
enddef

export def CompleteList(...args: list<any>): list<string>
  var data = call(GetBookmarks, g:vim_bookmarks_browsers)
  return mapnew(data, (_, v) => v["browser"] .. ">>>" .. v["display"])
enddef
