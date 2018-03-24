assertValid = require 'assertValid'
valido = require 'valido'
noop = require 'noop'

Route = require './Route'
utils = require './utils'

matchAll = /./
BREAK = Symbol()

Matcher = valido.get 'function|string|regexp'
Pattern = valido.get 'string|regexp?'

configTypes = valido
  name: 'string?'
  prefix: 'string?'

class Router
  constructor: (config = {}) ->
    assertValid config, configTypes
    @name = config.name if config.name

    if prefix = config.prefix
      unless /^\/.+\/$/.test prefix
        throw Error '`prefix` must begin and end with /'
      @prefix = prefix
      @_prefixRE = new RegExp '^' + prefix
    else
      @prefix = '/'
      @_prefixRE = matchAll

    @_match = noop.true
    @_routes = []
    @_blacklist = noop.false
    @

  match: (value) ->

    if @_match isnt noop.true
      throw Error 'Cannot call `match` more than once per context'

    assertValid value, Matcher
    @_match = utils.createMatcher value
    return this

  blacklist: (fn) ->

    if @_blacklist isnt noop.false
      throw Error 'Cannot call `blacklist` more than once per context'

    assertValid fn, 'function'
    @_blacklist = fn
    return this

  listen: (arg) ->

    # Both verb and path are omitted.
    if arguments.length is 1
      assertValid arg, ['function', Route, Router]
      @_routes.push arg
      return this

    # The verb and path both exist.
    if arguments.length is 3
      [verb, path, fn] = arguments

    # The verb or path has been omitted.
    else if typeof arguments[0] is 'string'
      if /^[A-Z\|]$/.test arguments[0]
      then [path, fn] = arguments
      else [verb, fn] = arguments

    # Regular expressions can be used for both verb and path.
    else if arguments[0] instanceof RegExp
      if /^[A-Z\|]$/.test arguments[0]
      then [path, fn] = arguments
      else [verb, fn] = arguments

    assertValid verb, Pattern
    assertValid path, Pattern
    assertValid fn, 'function'

    route = new Route {verb}

    if path
    then route.match path, fn
    else route._responder = fn

    @_routes.push route
    return route

  beforeAll: (fn) ->
    assertValid fn, 'function'
    @_beforeAll ?= []
    @_beforeAll.push fn
    return this

  afterAll: (fn) ->
    assertValid fn, 'function'
    @_afterAll ?= []
    @_afterAll.push fn
    return this

  extend: (prefix, plugins) ->

    if arguments.length is 1
      plugins = prefix
      prefix = ''

    if Array.isArray plugins
      for plugin in plugins
        @extend prefix, plugin

    else
      assertValid plugins, 'function'
      plugins.call router = new Router {prefix}
      @_routes.push router

    return this

  bind: -> @_exec.bind this

  _match: (req, path) ->
    if @_prefixRE.test path
      return @_match req, path

  _exec: (req, res) ->

    {prefix} = this
    if req.prefix
      prefix = req.prefix + prefix.slice 1

    {path} = req
    if prefix isnt '/'
      req.prefix = prefix
      path = path.slice prefix.length - 1

    if val = @_blacklist req, path
      return val if val isnt true
      return 403

    {next} = req
    req.next = noop
    req.BREAK = BREAK

    beforeAll = @_beforeAll

    for route in @_routes

      unless isFunction = typeof route is 'function'
        continue unless route._match req, path

      if beforeAll
        await execAll beforeAll, req, res
        beforeAll = null

      if isFunction
      then val = await route req, res
      else val = await route._exec req, res

      break if val is BREAK

    res.val = val
    if @_afterAll
      await execAll @_afterAll, req, res

    req.next = next
    return val

module.exports = Router

# Verb shortcuts
['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD']
  .forEach (verb) ->
    Router::[verb] = ->
      @listen verb, ...arguments
    return

#
# Helpers
#

execAll = (fns, req, res) ->
  for fn in fns
    if val = await fn req, res
      break if val is BREAK
