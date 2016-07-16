module Return exposing (..)

{-|
## Type
Modeling the `update` tuple as a Monad similar to `Writer`
@docs Return, ReturnF

## Mapping
@docs map, map2, map3, map4, map5, andMap, mapWith, mapCmd, mapBoth

## Piping
@docs piper, pipel, zero

## Basics
@docs singleton, andThen, (>>>), (<<<)

## Write `Cmd`s
@docs return, command, effect

## Fancy non-sense
@docs sequence, flatten
-}

import Respond exposing (..)


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


{-|
Transform the `Model` the `Cmd` will be left untouched
-}
map : (a -> b) -> Return msg a -> Return msg b
map f ( model, cmd ) =
    ( f model, cmd )


{-|
Transform the `Model` of and add a new `Cmd` to the queue
-}
mapWith : (a -> b) -> Cmd msg -> Return msg a -> Return msg b
mapWith f cmd' ( model, cmd ) =
    f model ! [ cmd', cmd ]


{-|
Map an `Return` into a `Return` containing a `Model` function
-}
andMap : Return msg (a -> b) -> Return msg a -> Return msg b
andMap ( f, cmd ) ( model, cmd' ) =
    f model ! [ cmd, cmd' ]


{-|
Map over both the model and the msg type of the `Return`.
This is useful for easily embedding a `Return` in a Union Type.
For example

```elm
import Foo

type Msg = Foo Foo.Msg
type Model = FooModel Foo.Model

...

update : Msg -> Model -> Return Msg Model
update msg model =
   case msg of
     Foo foo -> Foo.update foo model.foo
      |> mapBoth Foo FooModel
```
-}
mapBoth : (a -> b) -> (c -> d) -> Return a c -> Return b d
mapBoth f f' ( model, cmd ) =
    ( f' model, Cmd.map f cmd )


{-|
Combine 2 `Return`s with a function

```elm
map2
  (\modelA modelB -> { modelA | foo = modelB.foo })
  retA
  retB
```
-}
map2 :
    (a -> b -> c)
    -> Return msg a
    -> Return msg b
    -> Return msg c
map2 f ( x, cmd ) ( y, cmd' ) =
    f x y ! [ cmd, cmd' ]


{-| -}
map3 :
    (a -> b -> c -> d)
    -> Return msg a
    -> Return msg b
    -> Return msg c
    -> Return msg d
map3 f ( x, cmd ) ( y, cmd' ) ( z, cmd'' ) =
    f x y z ! [ cmd, cmd', cmd'' ]


{-| -}
map4 :
    (a -> b -> c -> d -> e)
    -> Return msg a
    -> Return msg b
    -> Return msg c
    -> Return msg d
    -> Return msg e
map4 f ( w, cmda ) ( x, cmdb ) ( y, cmdc ) ( z, cmdd ) =
    f w x y z ! [ cmda, cmdb, cmdc, cmdd ]


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
    f v w x y z ! [ cmda, cmdb, cmdc, cmdd, cmde ]


{-|
Create a `Return` from a given `Model`
-}
singleton : model -> Return msg model
singleton =
    flip (,) Cmd.none


{-|
Chain together expressions from `Model` to `Return`.

```elm
-- arbitrary function to demonstrate
foo : Model -> Return Msg Model
foo ({bar} as model) =
  -- forking logic
  if bar < 10
  -- that side effects may be added
  then (model, getAjaxThing)
  -- that the model may be updated
  else ({model | bar = model.bar - 2 }, Cmd.none)
```

They are now chainable with `andThen`...

```elm
resulting : Return msg { model | bar : Int }
resulting =
  myReturn `andThen` foo
           `andThen` foo
           `andThen` foo
```

Here we changed up `foo` three times, but we can use any function of
type `(a -> Return msg b)`.

Commands will be accumulated automatically as is the case with all
functions in this library.
-}
andThen : Return msg a -> (a -> Return msg b) -> Return msg b
andThen ( model, cmd ) f =
    let
        ( model', cmd' ) =
            f model
    in
        model' ! [ cmd, cmd' ]


{-|
Construct a new `Return` from parts
-}
return : model -> Cmd msg -> Return msg model
return =
    curry identity


{-|

Go point free with `andThen` chaining. Looking at the example from `andThen`

```elm
resulting : Return msg { model | bar : Int }
resulting =
  myReturn `andThen` foo
           `andThen` foo
           `andThen` foo
```

this code roughly becomes:

```elm
doFoo3Times : { model | bar : Int } -> Return msg { model | bar : Int }
doFoo3Times =
  foo >>> foo >>> foo
```
-}
(<<<) : (b -> Return msg c) -> (a -> Return msg b) -> a -> Return msg c
(<<<) f f' model =
    f' model `andThen` f


{-| -}
(>>>) : (a -> Return msg b) -> (b -> Return msg c) -> a -> Return msg c
(>>>) =
    flip (<<<)


{-|
Add a `Cmd` to a `Return`, the `Model` is uneffected
-}
command : Cmd msg -> ReturnF msg model
command cmd ( model, cmd' ) =
    model ! [ cmd, cmd' ]


{-|
Add a `Cmd` to a `Return` based on its `Model`, the `Model` will not be effected
-}
effect : Respond msg model -> ReturnF msg model
effect f ( model, cmd ) =
    model ! [ cmd, f model ]


{-|
Map on the `Cmd`.
-}
mapCmd : (Cmd a -> Cmd b) -> Return a model -> Return b model
mapCmd f ( model, cmd ) =
    ( model, f cmd )


{-| -}
sequence : List (Return msg model) -> Return msg (List model)
sequence =
    let
        f ( model, cmd ) ( models, cmds ) =
            ( model :: models, Cmd.batch [ cmd, cmds ] )
    in
        List.foldr f ( [], Cmd.none )


{-| -}
flatten : Return msg (Return msg model) -> Return msg model
flatten =
    flip andThen identity
