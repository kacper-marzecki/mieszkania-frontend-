module Main exposing (..)

import Browser
import Html exposing (Html, a, div, h1, i, img, input, nav, text)
import Html.Attributes exposing (class, src)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode exposing (Decoder, field, string)



-- UTILS


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


type alias Home =
    { id : Int
    , added : String
    , link : String
    , description : String
    , price : Int
    }


type alias Model =
    { site : Site
    , loading : Bool
    , menuOpen : Bool
    , settings : Settings
    , cities : List String
    , page : Int
    , homesPage : Maybe (Page Home)
    , errors : List String
    }


citiesDecoder : Decoder (List String)
citiesDecoder =
    Json.Decode.list string


type alias Page a =
    { content : List a
    , totalPages : Int
    , totalElements : Int
    , number : Int
    }


pageDecoder : Decoder a -> Decoder (Page a)
pageDecoder contentDecoder =
    Json.Decode.map4 Page
        (Json.Decode.field "content" (Json.Decode.list contentDecoder))
        (Json.Decode.field "totalPages" Json.Decode.int)
        (Json.Decode.field "totalElements" Json.Decode.int)
        (Json.Decode.field "number" Json.Decode.int)


getCities : Cmd Msg
getCities =
    Http.get
        { url = "http://localhost:8081/cities"
        , expect = Http.expectJson GotCities citiesDecoder
        }


buildHomeUrl : Settings -> Int -> Maybe String
buildHomeUrl settings page =
    case settings.city of
        Nothing ->
            Nothing

        Just city ->
            let
                url =
                    "http://localhost:8081/home/"
                        ++ city
                        ++ "?lowerPrice="
                        ++ String.fromInt settings.lowerPrice
                        ++ "&upperPrice="
                        ++ String.fromInt settings.upperPrice
                        ++ "&page="
                        ++ String.fromInt page
            in
            Just url


homeDecoder : Decoder Home
homeDecoder =
    Json.Decode.map5 Home
        (Json.Decode.field "id" Json.Decode.int)
        (Json.Decode.field "added" Json.Decode.string)
        (Json.Decode.field "link" Json.Decode.string)
        (Json.Decode.field "description" Json.Decode.string)
        (Json.Decode.field "price" Json.Decode.int)


homesDecoder : Decoder (List Home)
homesDecoder =
    Json.Decode.list homeDecoder


getHomesCmd : String -> Cmd Msg
getHomesCmd url =
    Http.get
        { url = url
        , expect = Http.expectJson GotHomes (pageDecoder homeDecoder)
        }


init : ( Model, Cmd Msg )
init =
    ( { site = MainSite
      , menuOpen = False
      , loading = True
      , settings =
            { city = Nothing
            , lowerPrice = 1000
            , upperPrice = 10000
            , open = False
            }
      , cities = []
      , page = 0
      , errors = []
      , homesPage = Nothing
      }
    , Cmd.batch [ getCities ]
    )



---- UPDATE ----


type Msg
    = NoOp
    | GetCities
    | GotCities (Result Http.Error (List String))
    | GetHomes Int
    | GotHomes (Result Http.Error (Page Home))
    | BurgerClicked
    | SettingsClicked
    | SetCity String
    | SetLowerPrice String
    | SetUpperPrice String
    | Error String


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


setLowerPrice : Model -> String -> Model
setLowerPrice model price =
    let
        lowerPrice =
            Maybe.withDefault model.settings.lowerPrice (String.toInt price)

        upperPrice =
            if lowerPrice > model.settings.upperPrice then
                lowerPrice

            else
                model.settings.upperPrice

        settings =
            model.settings

        newSettings =
            { settings | lowerPrice = lowerPrice, upperPrice = upperPrice }
    in
    { model | settings = newSettings }


setUpperPrice : Model -> String -> Model
setUpperPrice model price =
    let
        upperPrice =
            Maybe.withDefault model.settings.upperPrice (String.toInt price)

        lowerPrice =
            if upperPrice < model.settings.lowerPrice then
                upperPrice

            else
                model.settings.lowerPrice

        settings =
            model.settings

        newSettings =
            { settings | upperPrice = upperPrice, lowerPrice = lowerPrice }
    in
    { model | settings = newSettings }


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
            ( { model | cities = cities, loading = False }, Cmd.none )

        BurgerClicked ->
            ( toogleOpenMenu model, Cmd.none )

        SettingsClicked ->
            ( toogleOpenSettings model, Cmd.none )

        SetCity city ->
            ( setCity model city, Cmd.none )

        SetUpperPrice price ->
            ( setUpperPrice model price, Cmd.none )

        SetLowerPrice price ->
            ( setLowerPrice model price, Cmd.none )

        GetHomes pageNumber ->
            case buildHomeUrl model.settings pageNumber of
                Just url ->
                    Debug.log url
                        ( { model | page = pageNumber }, getHomesCmd url )

                Nothing ->
                    update (Error "Invalid search parameters") model

        GotHomes (Ok homePage) ->
            ( { model | homesPage = Just homePage }, Cmd.none )

        Error err ->
            ( { model | errors = [ err ] }, Cmd.none )

        _ ->
            Debug.log "catch-all update"
                ( model, Cmd.none )



---- VIEW ----


settingsView : Model -> Html Msg
settingsView model =
    let
        prices : Int -> List (Html Msg)
        prices targetPrice =
            List.range 4 40
                |> List.map (\n -> 250 * n)
                |> List.map (\n -> Html.option [ Html.Attributes.selected (targetPrice == n) ] [ text (String.fromInt n) ])

        options =
            List.map
                (\c -> Html.option [] [ text c ])
                model.cities

        withPlaceholder =
            [ Html.option [ Html.Attributes.disabled True, Html.Attributes.selected True ] [ text "Select City" ] ] ++ options
    in
    if model.settings.open then
        div [ class "box animated slideInDown" ]
            [ div [ class "columns" ]
                [ div [ class "column" ] []
                , div [ class "column" ]
                    [ div [ class "field is-horizontal " ]
                        [ div [ class "field-body" ]
                            [ div [ class "field has-addons" ]
                                [ div [ class "control" ]
                                    [ a [ class "button is-static" ] [ text "City" ]
                                    ]
                                , div [ class "control" ]
                                    [ div [ class "select" ]
                                        [ Html.select [ onInput SetCity ]
                                            withPlaceholder
                                        ]
                                    ]
                                ]
                            , div [ class "field has-addons" ]
                                [ div [ class "control" ]
                                    [ a [ class "button is-static" ] [ text "Lower Price limit" ]
                                    ]
                                , div [ class "control" ]
                                    [ div [ class "select" ]
                                        [ Html.select [ onInput SetLowerPrice ]
                                            (prices model.settings.lowerPrice)
                                        ]
                                    ]
                                ]
                            , div [ class "field has-addons" ]
                                [ div [ class "control" ]
                                    [ a [ class "button is-static" ] [ text "Upper price limit" ]
                                    ]
                                , div [ class "control" ]
                                    [ div [ class "select" ]
                                        [ Html.select [ onInput SetUpperPrice ]
                                            (prices model.settings.upperPrice)
                                        ]
                                    ]
                                ]
                            , div [ class "field " ]
                                [ div [ class "control" ]
                                    [ Html.button [ class "button is-primary", onClick (GetHomes 1), Html.Attributes.disabled (isNothing model.settings.city) ] [ text "Search" ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                , div [ class "column" ] []
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


homeTileView : Home -> Html Msg
homeTileView home =
    Html.article [ class "media" ]
        [ Html.figure [ class "media-left" ]
            [ Html.p [ class "image is-64x64" ]
                [ img [ src "https://bulma.io/images/placeholders/128x128.png" ] []
                ]
            ]
        , div [ class "media-content" ]
            [ Html.p [ class "is-size 3" ] [ text home.description ]
            ]
        ]


pageView : Page Home -> Html Msg
pageView page =
    div [ class "container is-fluid" ]
        (List.map homeTileView page.content
            ++ [ div [ class "pagination is-rounded", Html.Attributes.attribute "role" "navigation" ]
                    [ Html.button [ class "pagination-previous", Html.Attributes.disabled (page.number == 0), onClick (GetHomes (page.number - 1)) ] [ text "Previous" ]
                    , Html.button [ class "pagination-next", Html.Attributes.style "margin-right" "15px", onClick (GetHomes (page.number + 1)) ] [ text "Next" ]
                    , Html.ul [ class "pagination-list" ] []
                    ]
               ]
        )


homesView : Model -> Html Msg
homesView model =
    case model.homesPage of
        Just page ->
            pageView page

        Nothing ->
            div [] []


footerView : Html Msg
footerView =
    Html.footer [ class "footer" ]
        [ div [ class "content has-text-centered" ]
            [ Html.p [] [ text "FubarSoft 2020" ]
            ]
        ]


view : Model -> Html Msg
view model =
    let
        mainContent =
            div [ class "main-content" ]
                [ menuBar model
                , progressBar model
                , settingsView model
                , homesView model
                ]
    in
    div [ class "root" ]
        [ mainContent
        , footerView
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
