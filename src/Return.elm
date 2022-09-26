module Return exposing
    ( Return, ReturnF
    , map, map2, map3, map4, map5, andMap, mapWith, mapCmd, mapBoth, dropCmd
    , piper, pipel, zero, piperK, pipelK
    , singleton, andThen, andThenK
    , return, command, effect_
    , sequence, flatten, sequenceMaybe, traverseMaybe
    )

{-|


## Type

Modeling the `update` tuple as a Monad similar to `Writer`

@docs Return, ReturnF


## Mapping

@docs map, map2, map3, map4, map5, andMap, mapWith, mapCmd, mapBoth, dropCmd


## Piping

@docs piper, pipel, zero, piperK, pipelK


## Basics

@docs singleton, andThen, andThenK


## Write `Cmd`s

@docs return, command, effect_


## Fancy non-sense

@docs sequence, flatten, sequenceMaybe, traverseMaybe

-}

import Respond exposing (..)
import Tuple


{-| -}
type alias Return msg model =
    ( model, Cmd msg )


{-| -}
type alias ReturnF msg model =
    Return msg model -> Return msg model


{-| -}
piper : List (ReturnF msg model) -> ReturnF msg model
piper =
    List.foldr (<<) zero


{-| -}
pipel : List (ReturnF msg model) -> ReturnF msg model
pipel =
    List.foldl (>>) zero


{-| -}
zero : ReturnF msg model
zero =
    identity


{-| Transform the `Model`, the `Cmd` will be left untouched
-}
map : (a -> b) -> Return msg a -> Return msg b
map f ( model, cmd ) =
    ( f model, cmd )


{-| Transform the `Model` of and add a new `Cmd` to the queue
-}
mapWith : (a -> b) -> Cmd msg -> Return msg a -> Return msg b
mapWith f cmd ret =
    andMap ret ( f, cmd )


{-| Map an `Return` into a `Return` containing a `Model` function
-}
andMap : Return msg a -> Return msg (a -> b) -> Return msg b
andMap ( model, cmd_ ) ( f, cmd ) =
    ( f model, Cmd.batch [ cmd, cmd_ ] )


{-| Map over both the model and the msg type of the `Return`.
This is useful for easily embedding a `Return` in a Union Type.
For example

    import Foo

    type Msg = Foo Foo.Msg
    type Model = FooModel Foo.Model

    ...

    update : Msg -> Model -> Return Msg Model
    update msg model =
       case msg of
          Foo foo -> Foo.update foo model.foo
            |> mapBoth Foo FooModel

-}
mapBoth : (a -> b) -> (c -> d) -> Return a c -> Return b d
mapBoth f f_ ( model, cmd ) =
    ( f_ model, Cmd.map f cmd )


{-| Combine 2 `Return`s with a function

    map2
        (\modelA modelB -> { modelA | foo = modelB.foo })
        retA
        retB

-}
map2 :
    (a -> b -> c)
    -> Return msg a
    -> Return msg b
    -> Return msg c
map2 f ( x, cmda ) ( y, cmdb ) =
    ( f x y, Cmd.batch [ cmda, cmdb ] )


{-| -}
map3 :
    (a -> b -> c -> d)
    -> Return msg a
    -> Return msg b
    -> Return msg c
    -> Return msg d
map3 f ( x, cmda ) ( y, cmdb ) ( z, cmdc ) =
    ( f x y z, Cmd.batch [ cmda, cmdb, cmdc ] )


{-| -}
map4 :
    (a -> b -> c -> d -> e)
    -> Return msg a
    -> Return msg b
    -> Return msg c
    -> Return msg d
    -> Return msg e
map4 f ( w, cmda ) ( x, cmdb ) ( y, cmdc ) ( z, cmdd ) =
    ( f w x y z, Cmd.batch [ cmda, cmdb, cmdc, cmdd ] )


{-| -}
map5 :
    (a -> b -> c -> d -> e -> f)
    -> Return msg a
    -> Return msg b
    -> Return msg c
    -> Return msg d
    -> Return msg e
    -> Return msg f
map5 f ( v, cmda ) ( w, cmdb ) ( x, cmdc ) ( y, cmdd ) ( z, cmde ) =
    ( f v w x y z, Cmd.batch [ cmda, cmdb, cmdc, cmdd, cmde ] )


{-| Create a `Return` from a given `Model`
-}
singleton : model -> Return msg model
singleton a =
    ( a, Cmd.none )


{-|

    foo : Model -> Return Msg Model
    foo ({ bar } as model) =
        -- forking logic
        if
            bar < 10
            -- that side effects may be added
        then
            ( model, getAjaxThing )
            -- that the model may be updated

        else
            ( { model | bar = model.bar - 2 }, Cmd.none )

They are now chainable with `andThen`...

    resulting : Return msg { model | bar : Int }
    resulting =
        myReturn
            |> andThen foo
            |> andThen foo
            |> andThen foo

Here we changed up `foo` three times, but we can use any function of
type `(a -> Return msg b)`.

Commands will be accumulated automatically as is the case with all
functions in this library.

-}
andThen : (a -> Return msg b) -> Return msg a -> Return msg b
andThen f ( model, cmd ) =
    let
        ( model_, cmd_ ) =
            f model
    in
    ( model_, Cmd.batch [ cmd, cmd_ ] )


{-| Construct a new `Return` from parts
-}
return : model -> Cmd msg -> Return msg model
return a b =
    identity ( a, b )


{-| Add a `Cmd` to a `Return`, the `Model` is uneffected
-}
command : Cmd msg -> ReturnF msg model
command cmd ( model, cmd_ ) =
    ( model, Cmd.batch [ cmd, cmd_ ] )


{-| Add a `Cmd` to a `Return` based on its `Model`, the `Model` will not be effected
-}
effect_ : Respond msg model -> ReturnF msg model
effect_ f ( model, cmd ) =
    ( model, Cmd.batch [ cmd, f model ] )


{-| Map on the `Cmd`.
-}
mapCmd : (a -> b) -> Return a model -> Return b model
mapCmd f ( model, cmd ) =
    ( model, Cmd.map f cmd )


{-| Drop the current `Cmd` and replace with an empty thunk
-}
dropCmd : ReturnF msg model
dropCmd =
    singleton << Tuple.first


{-| -}
sequence : List (Return msg model) -> Return msg (List model)
sequence =
    let
        f ( model, cmd ) ( models, cmds ) =
            ( model :: models, Cmd.batch [ cmd, cmds ] )
    in
    List.foldr f ( [], Cmd.none )


{-| -}
sequenceMaybe : Maybe (Return msg model) -> Return msg (Maybe model)
sequenceMaybe =
    Maybe.map (map Just) >> Maybe.withDefault (singleton Nothing)


traverseMaybe : (a -> Return msg model) -> Maybe a -> Return msg (Maybe model)
traverseMaybe f =
    Maybe.map f >> sequenceMaybe


{-| -}
flatten : Return msg (Return msg model) -> Return msg model
flatten =
    andThen identity


{-| Kleisli composition
-}
andThenK : (a -> Return x b) -> (b -> Return x c) -> (a -> Return x c)
andThenK x y a =
    x a |> andThen y


{-| Compose updaters from the left
-}
pipelK : List (a -> Return x a) -> (a -> Return x a)
pipelK =
    List.foldl andThenK singleton


{-| Compose updaters from the right
-}
piperK : List (a -> Return x a) -> (a -> Return x a)
piperK =
    List.foldr andThenK singleton
