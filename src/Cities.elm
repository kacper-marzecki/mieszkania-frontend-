module Cities exposing (..)

import Json.Decode exposing (Decoder, string)



-- MODEL

type alias City =
    String



-- DECODERS

citiesDecoder : Decoder (List String)
citiesDecoder =
    Json.Decode.list string
