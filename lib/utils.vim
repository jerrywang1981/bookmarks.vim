vim9script

export def GetOS(): string
  var os: string = ""
  if has("win64") || has("win32") || has("win16")
    os = 'Windows'
  else
    os = substitute(system('uname'), '\n', '', '')
  endif
  return os
enddef
