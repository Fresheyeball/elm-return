module Infix exposing (..)

{-|

Elm is getting less functional, here is some relief
@docs (<$>), (<*>), (>>=)

Infix order may not work correctly
https://github.com/elm-lang/elm-compiler/issues/1096
-}

import Return exposing (Return)


-- infixl 4 <$>
{-| map as an infix, like normal -}
(<$>) : (a -> b) -> Return msg a -> Return msg b
(<$>) = Return.map


-- infixl 5 <*>
{-| apply as an infix, like normal -}
(<*>) : Return msg (a -> b) -> Return msg a -> Return msg b
(<*>) = flip Return.andMap


-- infixl 1 >>=
{-| bind as an infix, like normal -}
(>>=) : Return msg a -> (a -> Return msg b) -> Return msg b
(>>=) = flip Return.andThen
