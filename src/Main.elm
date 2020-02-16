module Main exposing (..)

import Browser
import Html exposing (Html, a, div, h1, i, img, input, nav, text)
import Html.Attributes exposing (class, src)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode exposing (Decoder, field, string)


type CityId
    = Int


type Site
    = MainSite
    | CitySite CityId


type alias City =
    String


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
    , cities : List String
    }


citiesDecoder : Decoder (List String)
citiesDecoder =
    Json.Decode.list string


getCities : Cmd Msg
getCities =
    Http.get
        { url = "http://localhost:8081/cities"
        , expect = Http.expectJson GotCities citiesDecoder
        }



-- getHomes: Settings -> Cmd Msg
-- getHomes settings =


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
      , cities = []
      }
    , Cmd.batch [ getCities ]
    )



---- UPDATE ----


type Msg
    = NoOp
    | GetCities
    | GotCities (Result Http.Error (List String))
    | BurgerClicked
    | SettingsClicked
    | SetCity String


toogleOpenSettings : Model -> Model
toogleOpenSettings model =
    let
        settings =
            model.settings

        newSettings =
            { settings | open = not model.settings.open }
    in
    { model | settings = newSettings, menuOpen = False }


toogleOpenMenu : Model -> Model
toogleOpenMenu model =
    let
        settings =
            model.settings

        newSettings =
            { settings | open = False }
    in
    { model | menuOpen = not model.menuOpen, settings = newSettings }


setCity : Model -> String -> Model
setCity model city =
    let
        settings =
            model.settings

        newSettings =
            { settings | city = Just city }
    in
    { model | settings = newSettings }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotCities (Ok cities) ->
            ( { model | cities = cities }, Cmd.none )

        BurgerClicked ->
            ( toogleOpenMenu model, Cmd.none )

        SettingsClicked ->
            ( toogleOpenSettings model, Cmd.none )

        SetCity city ->
            ( setCity model city, Cmd.none )

        _ ->
            ( model, Cmd.none )



---- VIEW ----


settingsView : Model -> Html Msg
settingsView model =
    let
        options =
            List.map
                (\c -> Html.option [] [ text c ])
                model.cities

        withPlaceholder =
            [ Html.option [ Html.Attributes.disabled True, Html.Attributes.selected True ] [ text "Select City" ] ] ++ options
    in
    if model.settings.open then
        div [ class "box animated slideInDown" ]
            [ div [ class "field is-horizontal" ]
                [ div [ class "field-label is-normal" ] [ Html.label [ class "label" ] [ text "City" ] ]
                , div [ class "field-body" ]
                    [ div [ class "control" ]
                        [ div [ class "select" ]
                            [ Html.select [ onInput SetCity, Html.Attributes.placeholder "asd" ]
                                withPlaceholder
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
    if model.loading then
        Html.progress [ class "progress is-small is-primary" ] []

    else
        div [] []


homeView : Model -> Html Msg
homeView _ =
    div [] []


view : Model -> Html Msg
view model =
    div []
        [ menuBar model
        , progressBar model
        , settingsView model
        , homeView model
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
