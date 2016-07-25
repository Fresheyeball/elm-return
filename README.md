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


## Examples

Lets say we have a situation where we have a top level `update` function
and wish to embed a component's `update` function.

```elm
type Model = HomeMod Home.Model
           | AboutMod About.Model

type Msg = HomeMsg Home.Msg
         | AboutMsg About.Msg

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    let
        (updateModel, updateCmd) =
            case (model, msg) of
                (HomeMod model', HomeMsg msg') ->
                    let
                        (subModel, subCmd) =
                            Home.update msg' model'

                    in
                        (HomeMod subModel, Cmd.map HomeMsg subCmd)

                (AboutMod model', AboutMsg msg') ->
                    let
                        (subModel, subCmd) =
                            About.update msg' model'

                    in
                        (AboutMod subModel, Cmd.map AboutMsg subCmd)

                x ->
                    let
                        _ =
                            Debug.log "Stray found" x

                    in
                        (model, Cmd.none)

       transformed =
          Route.alwaysTranfromModelWithMe updateModel

    in
       transformed ! [ updateCmd
                     , alwaysDoMeCmd
                     , conditionallyDoSomething transformed ]
```

The code above is good, but it suffers in some areas. For example
we could forget to include `updateCmd` in the final `in` expression,
and those side effects are not lost. Or we could neglect to put the
final *third* version of the model, `transformed`, into `conditionallyDoSomething`.

Lets see how we can clean this up with `Return`.

```elm
type Model = HomeMod Home.Model
           | AboutMod About.Model

type Msg = HomeMsg Home.Msg
         | AboutMsg About.Msg

update : Msg -> Model -> Return Msg Model
update msg model =
    (case (model, msg) of
        (HomeMod model', HomeMsg msg') ->
            Home.update msg' model'
            |> mapBoth HomeMsg HomeMod

        (AboutMod model', AboutMsg msg') ->
            About.update msg' model'
            |> mapBoth AboutMsg AboutMod

        x ->
            let
                _ =
                    Debug.log "Stray found" x

            in
            singleton model)            
    |> command alwaysDoMeCmd
    |> map Route.alwaysTranfromModelWithMe
    |> effect conditionallyDoSomething
```

The cleaned up code is not only more succinct, and more imperative (in a good way),
but it doesn't suffer from the problems described above. There is no risk of mixing up
your terms or accidentally dropping a cmd.
