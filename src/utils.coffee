
exports.createMatcher = (path) ->
  regex =
    if typeof path is 'string'
    then pathRegex path
    else path

  unless /^\^\\\//.test regex.source
    throw Error '`path` must begin with ^/'

  return (req, path) ->
    if m = regex.exec path
      if m.length > 1
        req.params = buildParams m, regex.params
      return true

#
# Helpers
#

buildParams = (values, names) ->
  params = Object.create null
  for i in [1 .. values.length]
    params[names[i - 1] or i - 1] = values[i]
  params

paramRE = /:([^./\(-]+)(\([^\)]+\))?/g
pathRegex = (path) ->
  parts = ['^']
  params = []

  i = 0
  loop
    m = paramRE.exec path

    j = if m then m.index else path.length
    parts.push sanitize(path.slice i, j) if i < j

    break unless m
    i = j + m[0].length
    parts.push m[2] or '([^./-]+)'
    params.push m[1]

  parts.push '$'
  regex = new RegExp parts.join ''
  regex.params = params
  regex

sanitize = (part) ->
  part.replace /\./g, '\\.'
