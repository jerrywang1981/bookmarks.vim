vim9script

def ReadUrlData(jsonData: dict<any>, folder: list<string>): list<dict<any>>
  var data: list<dict<any>>
  if has_key(jsonData, "type")
    var typ = jsonData["type"]
    var name: string
    if typ == "folder"
      name = get(jsonData, "name", "folder")
      if has_key(jsonData, "children") && jsonData["children"] -> len() > 0
        for i in jsonData["children"]
          extend(data, ReadUrlData(i, add(copy(folder), name)))
        endfor
      endif
    elseif typ == "url"
      name = get(jsonData, "name", "url")
      extend(data, [{
        ordinal: "",
        display: name .. " " .. join(folder, ">") .. " [(" .. jsonData["url"] .. ")]",
        # value: jsonData,
        name: name,
        url: jsonData["url"],
        folder: folder
      }])
    endif
  endif

  return data
enddef


export def Parse(filename: string): list<dict<any>>
  var data: list<dict<any>>
  var fileContent = readfile(filename)
  if empty(fileContent) | return data | endif
  var jsonData = json_decode(join(fileContent))
  if !has_key(jsonData, "roots") | return data | endif
  for k in keys(jsonData["roots"])
    extend(data, ReadUrlData(jsonData["roots"][k], []))
  endfor
  return data
enddef
