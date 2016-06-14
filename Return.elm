module Return exposing (..)

{-|
## Type
Modeling the `update` tuple as a Monad
@docs Return, ReturnF

## Mapping
@docs map, map2, map3, map4, map5, andMap, mapWith, mapCmd

## Basics
@docs singleton, andThen, (|<), (>|), (>>|), (|<<), (>>>), (<<<)

## Write `Cmd`s
@docs return, command, tell, pass, effect

## Read `Cmd`s
@docs ask, listen

## Fancy non-sense
@docs sequence, flatten
-}


{-| -}
type alias Return msg model =
    ( model, Cmd msg )


{-| -}
type alias ReturnF msg model =
    Return msg model -> Return msg model


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


infixl 6 >>|


{-| -}
(>>|) : Return msg a -> (a -> Return msg b) -> Return msg b
(>>|) =
    andThen


infixr 6 |<<


{-| -}
(|<<) : (a -> Return msg b) -> Return msg a -> Return msg b
(|<<) =
    flip andThen


infixl 7 >|


{-|
Same as `>>|` but the left hand `Model` is dropped
-}
(>|) : Return msg model -> Return msg model' -> Return msg model'
(>|) r r' =
    r `andThen` \_ -> r'


infixr 7 |<


{-|
Same as `>>|` but the right hand `Model` is dropped
-}
(|<) : Return msg model' -> Return msg model -> Return msg model'
(|<) =
    flip (>|)


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

getResult : { model | bar : Int } -> Return msg { model | bar : Int }
getResult =
  foo >>> foo >>> foo
-}
(<<<) : (b -> Return msg c) -> (a -> Return msg b) -> a -> Return msg c
(<<<) f f' model =
    f' model `andThen` f


{-| -}
(>>>) : (a -> Return msg b) -> (b -> Return msg c) -> a -> Return msg c
(>>>) =
    flip (<<<)


{-|
Construct a `Return` from a `Cmd`
-}
tell : Cmd msg -> Return msg ()
tell =
    (,) ()


{-|
Add a `Cmd` to a `Return`, the `Model` is uneffected
-}
command : Cmd msg -> Return msg model -> Return msg model
command cmd ( model, cmd' ) =
    model ! [ cmd, cmd' ]


{-|
Add a `Cmd` to a `Return` based on its `Model`, the `Model` will not be effected
-}
effect : (model -> Cmd msg) -> Return msg model -> Return msg model
effect f ( model, cmd ) =
    model ! [ cmd, f model ]


{-|
Included for completeness, unintuitive Haskell name, tell me what to call this.
-}
listen : Return msg a -> Return msg (Return msg a)
listen ( model, cmd ) =
    ( ( model, cmd ), cmd )


{-|
Included for completeness, unintuitive Haskell name, tell me what to call this.
-}
pass : Return msg ( model, Cmd msg -> Cmd msg' ) -> Return msg' model
pass ( ( x, f ), cmd ) =
    ( x, f cmd )


{-|
Map on the `Cmd`.
-}
mapCmd : (Cmd a -> Cmd b) -> Return a model -> Return b model
mapCmd f ( model, cmd ) =
    ( model, f cmd )


{-|
Included for completeness, unintuitive Haskell name, tell me what to call this.
-}
ask : Return msg model -> Return msg (Cmd msg)
ask ( _, cmd ) =
    ( cmd, cmd )


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
