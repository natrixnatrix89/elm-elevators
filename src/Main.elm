module Main exposing (..)

import App exposing (..)
import DataTypes exposing (Model)
import Html exposing (program)


main : Program Never Model Msg
main =
    program { view = view, init = init, update = update, subscriptions = subscriptions }
