module Main exposing (..)

import Browser
import Html exposing (Html, div, h1, img, text)
import Html.Attributes exposing (class, src)



---- MODEL ----


type CityId
    = Int


type Site
    = MainSite
    | CitySite CityId


type City
    = String


type alias Settings =
    { city : Maybe City
    , lowerPrice : Int
    , upperPrice : Int
    }


type alias Model =
    { site : Site
    , settings : Settings
    }


init : ( Model, Cmd Msg )
init =
    ( { site = MainSite
      , settings =
            { city = Nothing
            , lowerPrice = 1000
            , upperPrice = 10000
            }
      }
    , Cmd.none
    )



---- UPDATE ----


type Msg
    = NoOp
    | GetCities


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
    div []
        [ img [ src "/logo.svg" ] []
        , h1 [] [ text "Your Elm App is working!" ]
        ]



---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = always Sub.none
        }



-- on load get cities
-- on load load first city
-- fill the citie's homes
