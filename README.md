# Return

When writing Elm code you unavoidably have to interact with types like this:

```elm
(model, Cmd msg)
```

So we make that a type:

```elm
type alias Response msg model = (model, Cmd msg)
```

As it turns out, `Response` is really Haskell's `Writer` since `Cmd msg` is a `Monoid`.
Basically this means the functions exposed in this library allow you to interact with `(model, Cmd msg)` using familiar functions like `map`, `map2`, and `andThen`, without having to worry about `Cmd`'s (unless you opt in) as they get `Cmd.batch`ed together automatically.

## Static piping


```elm


update : Msg -> Model -> Return Msg Model
update msg model =
  let
    update' : Msg -> Model -> Return Msg Model
    update' -- some function as you would expect in TEA
  in
    update' msg model
      >>| \model' -> tell getUser
       >| foo "foo" { model' | foo = 3 }
      >>| listen \(model'', cmd) ->
      >>| tell ([getOrganization model''])


```
