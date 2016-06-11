module Return exposing (..)

{-|
## Type
Modeling the `update` tuple as a Monad
@docs Return

## Basics
@docs map, map2, map3, map4, map5, andMap, singleton, andThen, (|<), (>|), (>>|), (|<<)

## Write `Cmd`s
@docs writer, tell, listen, pass, censor

## Read `Cmd`s
@docs reader, ask

## State
@docs get, put
-}


{-| -}
type alias Return msg model =
    ( model, Cmd msg )


{-| -}
map : (a -> b) -> Return msg a -> Return msg b
map f ( model, cmd ) =
    ( f model, cmd )


{-| -}
andMap : Return msg (a -> b) -> Return msg a -> Return msg b
andMap ( f, cmd ) ( a, cmd' ) =
    f a ! [ cmd, cmd' ]


{-| -}
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


{-| -}
singleton : model -> Return msg model
singleton =
    flip (,) Cmd.none


{-| -}
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
{-| -}
(>|) : Return msg model -> Return msg model' -> Return msg model'
(>|) r r' =
    r `andThen` \_ -> r'

infixr 7 |<
{-| -}
(|<) : Return msg model' -> Return msg model -> Return msg model'
(|<) =
    flip (>|)

{-| -}
writer : ( model, Cmd msg ) -> Return msg model
writer =
    identity


{-| -}
tell : Cmd msg -> Return msg ()
tell =
    (,) ()


{-| -}
listen : Return msg a -> Return msg (Return msg a)
listen ( model, cmd ) =
    ( ( model, cmd ), cmd )


{-| -}
pass : Return msg ( model, Cmd msg -> Cmd msg' ) -> Return msg' model
pass ( ( x, f ), cmd ) =
    ( x, f cmd )


{-| -}
censor : (Cmd msg -> Cmd msg') -> Return msg model -> Return msg' model
censor f ( model, cmd ) =
    ( model, f cmd )


{-| -}
ask : Return msg model -> Return msg (Cmd msg)
ask ( _, cmd ) =
    ( cmd, cmd )


{-| -}
reader : (Cmd msg -> Cmd msg') -> Return msg model -> Return msg' model
reader =
    censor





{-| -}
get : Cmd msg -> Return msg (Cmd msg)
get cmd =
    ( cmd, cmd )


{-| -}
put : Cmd msg -> model -> Return msg ()
put cmd _ =
    ( (), cmd )
