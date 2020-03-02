module Utils exposing (..)


isNothing : Maybe a -> Bool
isNothing m =
    case m of
        Just _ ->
            False

        Nothing ->
            True


isJust : Maybe a -> Bool
isJust m =
    not (isNothing m)
