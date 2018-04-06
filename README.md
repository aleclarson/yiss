# yiss v0.1.0

Aww yiss. HTTP routing with finesse.

```js
let Router = require('yiss')

let api = new Router({
  name: 'My API', // For debugging (useful if you have many routers)
  prefix: '/v1/', // Only match requests whose paths begin with this
})
```

## Tutorial

The `Router` class can be very flexible. I recommend you read this
entire section to understand what's available to you.

Let's start with the basics.

Before we declare a route, let's learn how to match a route,
so we can have a better idea of how the `Router` works.

```js
// Bind the router with (req, res) => {}
let run = api.bind()

// The return value depends on which route handled the request.
let result = run(req, res)
```

When a route is found that matches the request path, the `req` and `res`
are passed to it. If the route returns a truthy value, the `run` function
assumes the request has been handled, and the truthy value is returned
by the `run` function. If the route returns a falsy value, the `run`
function continues its search for a route. If the `run` function never
finds a suitable route, it returns `undefined`.

Now, what to do with the `run` function's return value? I recommend using
[slush](https://github.com/aleclarson/slush) as your HTTP server, which
will inspect the return value and send a proper response. Of course,
you can do all that on your own, if you wish. :)

### Declaring routes

Next, you'll learn the API for declaring routes.

```js
api.GET('/', (req, res) => true)
```

Remember, you can return a falsy value to indicate an unhandled request.

If you want to exit the current router, your route should return
`req.BREAK`. This tells the router to skip any remaining routes.

&nbsp;

#### Named parameters

Beyond static paths, you can also declare named parameters that
will be parsed from the path.

Named parameters never match `/`, `.`, or `-` characters.

Their values are exposed via the `req.params` object.

```js
api.GET('/users/:userId/groups/:groupId', (req, res) => {
  console.log(req.params.userId)
  console.log(req.params.groupId)
  return true
})
```

&nbsp;

You can customize the `RegExp` used to match a named parameter
by providing a pattern wrapped with parentheses.

Remember to use `\\` when escaping characters.

```js
api.GET('/users/:userId(\\d+)', (req, res) => {
  console.log(parseInt(req.params.userId)) // should not be NaN
  return true
})
```

&nbsp;

In very special cases, you may need the full power of a `RegExp`
literal, which is supported.

```js
// Matches /123 and /123..456
api.GET(/\/([0-9]+)(?:\.\.([0-9]+))?/g, (req, res) => {
  console.log(req.params[0])
  console.log(req.params[1])
  return true
})
```

&nbsp;

Shortcut methods exist for the following HTTP methods:
`DELETE`, `GET`, `HEAD`, `PATCH`, `POST`, `PUT`

If you need another HTTP method, use the `listen` method.

```js
api.listen('TRACE', (req, res) => true)
```

&nbsp;

You can even listen for multiple HTTP methods.

```js
api.listen('GET|HEAD', (req, res) => true)
```

&nbsp;

#### Omitting the path argument

Omit the path argument to run a function for every GET request.

This is most useful when nesting routers, which you will learn
about later in this tutorial.

```js
api.GET((req, res) => {
  // Do something for every GET request.
  return true
})
```

&nbsp;

Use the `listen` method to run a function for every request,
no matter which HTTP method is used.

The return value works just like in a route, so you can return
a truthy value to stop the router early.

```js
api.listen((req, res) => {
  // Do something for every request.
})
```

Any listeners to add via the `listen` method are called in
the order they are added. They live in the same array as
your `GET`

&nbsp;

#### Advanced methods

The `Router` class has more to offer beyond simple route matching.

&nbsp;

Use `beforeAll` to run a function *before* any routes are called.

```js
api.beforeAll((req, res) => {})
```

Likewise, use `afterAll` to run a function *after* any routes are called.

```js
api.afterAll((req, res) => {})
```

The return values of `beforeAll` and `afterAll` callbacks are ignored.

&nbsp;

Use `match` to perform advanced request matching.

Returning a falsy value will exit the current router.

The `path` argument is stripped of any prefixes declared by
the current router or any of its parent routers.

The `req.path` property will always be the original path.

The `match` method is most useful when you want to skip
the remaining routes if the request does not match.
If you only want to skip one route, simply perform
the matching within that route, and return a falsy
value to skip to the next route.

```js
api.match((req, path) => !!req.query.token)
```

&nbsp;

The `blacklist` method is similar to `match`, except a
truthy value triggers a `403 Forbidden` response.

```js
api.blacklist((req, path) => !!req.query.token)
```

&nbsp;

**More documentation will be added at a later date!**

