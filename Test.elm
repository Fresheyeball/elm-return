module Test exposing (..)

import Return exposing (..)


type Foo
    = Foos
    | Baz


type Msg
    = Foo Foo
    | Bar


type alias Model =
    { baz : String, baa : Int }


murf : String -> String
murf =
    Debug.crash ""


doOtherThing : Cmd Msg
doOtherThing =
    Debug.crash ""


doThing : String -> Cmd Msg
doThing =
    Debug.crash ""

foo : Model -> Return Msg Model
foo = Debug.crash ""


y : Return Msg Model
y =
    singleton { baz = "baz", baa = 3 }



-- x : Return Msg Model


-- x = y >>| \model -> tell (doThing model.baz)
--         -- |> ask
--       -- >>| Cmd.map Foo
--       --  >| singleton (foo model)
--         |> reader (Cmd.map Foo)
x = y >>| \model -> tell (doThing model.baz)
       >| foo model.baa
      -- >>| singleton


-- >| singleton model
