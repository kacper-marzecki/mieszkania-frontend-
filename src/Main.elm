module Main exposing (..)

import Browser
import Html exposing (Html, a, div, h1, i, img, input, nav, text)
import Html.Attributes exposing (class, src)
import Html.Events exposing (onClick)
import Http
import Json.Decode exposing (Decoder, field, string)



---- MODEL ----


getRandomCatGif : Cmd Msg
getRandomCatGif =
    Http.get
        { url = "https://api.giphy.com/v1/gifs/random?api_key=dc6zaTOxFJmzC&tag=cat"
        , expect = Http.expectJson GotGif gifDecoder
        }


gifDecoder : Decoder String
gifDecoder =
    field "data" (field "image_url" string)


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
    , open : Bool
    }


type alias Model =
    { site : Site
    , loading : Bool
    , menuOpen : Bool
    , settings : Settings
    , test : String
    }


init : ( Model, Cmd Msg )
init =
    ( { site = MainSite
      , menuOpen = False
      , loading = False
      , settings =
            { city = Nothing
            , lowerPrice = 1000
            , upperPrice = 10000
            , open = False
            }
      , test = "asd"
      }
    , Cmd.none
    )



---- UPDATE ----


type Msg
    = NoOp
    | GetCities
    | GetGif
    | GotGif (Result Http.Error String)
    | BurgerClicked
    | SettingsClicked


toogleOpenSettings : Model -> Model
toogleOpenSettings model =
    let
        settings =
            model.settings

        newSettings =
            { settings | open = not model.settings.open }
    in
    { model | settings = newSettings }


toogleOpenMenu : Model -> Model
toogleOpenMenu model =
    { model | menuOpen = not model.menuOpen }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotGif (Ok gif) ->
            ( { model | test = gif }, Cmd.none )

        BurgerClicked ->
            ( toogleOpenMenu model, Cmd.none )

        SettingsClicked ->
            ( toogleOpenSettings model, Cmd.none )

        GetGif ->
            ( model, getRandomCatGif )

        _ ->
            ( model, Cmd.none )



---- VIEW ----


settingsView : Settings -> Html msg
settingsView settingsModel =
    if not settingsModel.open then
        div [ class "box animated slideInDown" ]
            [ div [ class "field is-horizontal" ]
                [ div [ class "field-label is-normal" ] [ Html.label [ class "label" ] [ text "City" ] ]
                , div [ class "field-body" ]
                    [ div [ class "control" ]
                        [ div [ class "select" ]
                            [ Html.select []
                                [ Html.option [] [ text "DUPA" ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]

    else
        div [] []


menuBar : Model -> Html Msg
menuBar model =
    nav [ class "navbar" ]
        [ div [ class "navbar-brand" ]
            [ Html.a [ class "navbar-item", Html.Attributes.href "#" ]
                [ i [ class "fas fa-home" ] []
                ]
            , a [ onClick SettingsClicked, class " navbar-item " ]
                [ i [ class "fas fa-cog" ] []
                ]
            , a
                [ class "navbar-burger burger"
                , Html.Attributes.attribute "data-target" "navbar-id"
                , Html.Attributes.attribute "role" "button"
                , onClick BurgerClicked
                ]
                [ Html.span [] [], Html.span [] [], Html.span [] [] ]
            ]
        , div [ Html.Attributes.id "navbar-id", Html.Attributes.classList [ ( "navbar-menu", True ), ( "is-active animated slideInDown", model.menuOpen ) ] ]
            [ div [ class "navbar-start" ]
                [ a [ class "navbar-item" ] [ text "item uno" ]
                , a [ class "navbar-item" ] [ text "item duo" ]
                , a [ class "navbar-item" ] [ text "item tre" ]
                ]
            , div [ class "navbar-end" ] []
            ]
        ]


progressBar : Model -> Html Msg
progressBar model =
    -- <progress class="progress is-small is-primary" max="100">15%</progress>
    if model.loading then
        Html.progress [ class "progress is-small is-primary" ] []

    else
        div [] []


view : Model -> Html Msg
view model =
    div []
        [ menuBar model
        , progressBar model
        , settingsView model.settings
        , img [ src "/logo.svg" ] []
        , img [ src model.test ] []
        , h1 [] [ text model.test ]
        , Html.button [ onClick GetGif ] [ text "Asd" ]
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
