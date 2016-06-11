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
x : Return Msg Model
x = y >>| \model -> tell (doThing model.baz)
       >| foo model.baa
      >>| bar >> singleton
        |> map (\model -> {model | baa = 4})
```

Without static piping, we are forced to use more language features, and the intention of our code is arguably less clear or sequential.

```elm
x' : Return Msg Model
x' = case y of
  (model, cmd) ->
    let
      (model', cmd') = foo model.baa
      (model'') = bar model'
    in {model'' | baa = 4} ! [cmd, doThing model.baz, cmd']
```

Give the following types for these examples

```elm
type alias Model = { baz : String, baa : Int }
y : Return Msg Model
doThing : String -> Cmd Msg
foo : Int -> Return Msg Model
bar : Model -> Model
```
