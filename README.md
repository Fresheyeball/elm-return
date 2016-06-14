# Return

When writing Elm code you unavoidably have to interact with types like this:

```elm
(model, Cmd msg)
```

This library makes that a Type:

```elm
type alias Return msg model = (model, Cmd msg)
```

You can interact with `Return` in terms of the `Model`, and trust that `Cmd`s
get tracked and batched together automatically. Letting you focus on composing
transformations on `Return` without manually shuffling around `Cmd`. 
