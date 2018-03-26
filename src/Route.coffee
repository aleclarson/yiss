PathMatcher = require './PathMatcher'
assertValid = require 'assertValid'
sliceArray = require 'sliceArray'
isValid = require 'isValid'
valido = require 'valido'
noop = require 'noop'

RouteConfig = valido
  verb: Pattern

class Route
  constructor: (config) ->
    assertValid config, RouteConfig
    @_verb = new RegExp '^(' + config.verb + ')$'
    @_matcher = noop.true
    @_responder = null
    @

  query: (arg) ->
    if arguments.length > 1
      arg = sliceArray arguments

    if @_queryType isnt undefined
      throw Error 'Cannot call `query` more than once per route'

    @_queryType = valido arg
    @_queryType.strict = true
    return

  body: (arg) ->
    if arguments.length > 1
      arg = sliceArray arguments

    if @_body isnt undefined
      throw Error 'Cannot call `body` more than once per route'

    @_body = arg

    # Passing `true` means the body must exist, but can be any type.
    if arg isnt true
      @_bodyType = validateBody arg

      # Shapes cannot have unknown properties.
      if isValid arg, 'object'
        @_bodyType.strict = true
        return

  listen: (responder) ->
    if @_responder
      if Array.isArray @_responder
      then @_responder.push responder
      else @_responder = [@_responder, responder]
    else @_responder = responder
    return this

  match: (path, responder) ->

    if @_matcher isnt noop.true
      throw Error 'The matcher is already set'

    if typeof path is 'function'
      @_matcher = path
    else
      @_matcher = PathMatcher.create path
      @_path =
        if typeof path is 'string'
        then path
        else path.source

    @listen responder if responder
    return this

  _match: (req, path) ->
    if @_verb.test req.method
      return @_matcher req, path

  _exec: (req, res) ->

    if oops = @_validateQuery req.query
      return {error: oops 'query'}

    if @_body and !req.body

      # Read the body.
      req.body = await req.readBody
        json: @_body is 'object' or isValid @_body, 'object'

      if req.body is null
        return {error: 'Missing body'}

      # Validate the body.
      if @_bodyType

        if @_bodyType.name is 'string'
          req.body = req.body.toString()

        else if oops = @_bodyType.assert req.body
          return {error: oops 'body'}

    if Array.isArray @_responder
      for fn in @_responder
        return val if val = await fn req, res

    else if fn = @_responder
      return val if val = await fn req, res

  _validateQuery: (query) ->
    if type = @_queryType
      return type.assert query

module.exports = Route

validateBody = (type) ->

  if valido.is type
    return type

  if isValid type, 'object|array|function'
    return valido type

  if isValid type, 'string'
    return valido.get type
