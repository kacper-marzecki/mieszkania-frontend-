port module Main exposing (..)

import Browser
import Cities exposing (City, citiesDecoder)
import Home exposing (Home)
import Html exposing (Html, a, div, h1, i, img, input, nav, text)
import Html.Attributes exposing (attribute, class, src, title)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode exposing (Decoder, field, string)
import Json.Encode as E
import Process
import Task
import Utils exposing (isNothing)



-- PORTS


port copyToClipboard : E.Value -> Cmd msg


port favouriteHome : E.Value -> Cmd msg


port openLink : E.Value -> Cmd msg


port removeFavouriteHome : E.Value -> Cmd msg


port showSnackbar : (E.Value -> msg) -> Sub msg


port getFavouriteHomes : () -> Cmd msg


port returnFavouriteHomes : (E.Value -> msg) -> Sub msg


port scrollToTheTop : () -> Cmd msg


type Site
    = MainSite
    | FavouriteHomesSite


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
    , page : Int
    , homesPage : Maybe (Page Home)
    , favouriteHomes : List Home
    , errors : List String
    , shareApiEnabled : Bool
    , backendApi : String
    , bottomNotification : Maybe String
    }


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


getCities : Model -> Cmd Msg
getCities model =
    Http.get
        { url = model.backendApi ++ "/cities"
        , expect = Http.expectJson GotCities citiesDecoder
        }


buildHomeUrl : Model -> Int -> Maybe String
buildHomeUrl model page =
    case model.settings.city of
        Nothing ->
            Nothing

        Just city ->
            let
                url =
                    model.backendApi
                        ++ "/home/"
                        ++ city
                        ++ "?lowerPrice="
                        ++ String.fromInt model.settings.lowerPrice
                        ++ "&upperPrice="
                        ++ String.fromInt model.settings.upperPrice
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


init : ProgramFlags -> ( Model, Cmd Msg )
init flags =
    let
        model =
            { site = MainSite
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
            , favouriteHomes = []
            , shareApiEnabled = flags.shareApiEnabled
            , backendApi = flags.backendApi
            , bottomNotification = Nothing
            }
    in
    ( model
    , Cmd.batch [ getCities model, getFavouriteHomes () ]
    )



---- UPDATE ----


type Msg
    = NoOp
    | OpenLink String
    | OpenFavourites
    | OpenMainSite
    | GetCities
    | GotCities (Result Http.Error (List String))
    | GetHomes Int
    | GotHomes (Result Http.Error (Page Home))
    | GetFavouriteHomes
    | GotFavouriteHomes (Result Json.Decode.Error (List Home))
    | AddFavouriteHome Home
    | RemoveFavouriteHome Home
    | BurgerClicked
    | SettingsClicked
    | SetCity String
    | SetLowerPrice String
    | SetUpperPrice String
    | CopyToClipboard String
    | ShowBottomNotification (Result Json.Decode.Error String)
    | HideBottomNotification
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


encodeHome : Home -> E.Value
encodeHome home =
    E.object
        [ ( "id", E.int home.id )
        , ( "added", E.string home.added )
        , ( "link", E.string home.link )
        , ( "description", E.string home.description )
        , ( "price", E.int home.price )
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OpenLink link ->
            ( model, openLink (E.string link) )

        OpenMainSite ->
            let
                settings =
                    model.settings

                openSettings =
                    { settings | open = True }
            in
            ( { model | settings = openSettings, menuOpen = False, site = MainSite }, getCities model )

        OpenFavourites ->
            let
                closedMenu =
                    toogleOpenMenu model
            in
            ( { closedMenu | site = FavouriteHomesSite }, getFavouriteHomes () )

        CopyToClipboard string ->
            ( model, copyToClipboard (E.string string) )

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
            case buildHomeUrl model pageNumber of
                Just url ->
                    ( { model | page = pageNumber }, Cmd.batch [ getHomesCmd url, scrollToTheTop () ] )

                Nothing ->
                    update (Error "Invalid search parameters") model

        GotHomes (Ok homePage) ->
            ( { model | homesPage = Just homePage }, Cmd.none )

        GotFavouriteHomes (Ok homes) ->
            ( { model | favouriteHomes = homes, loading = False }, Cmd.none )

        AddFavouriteHome home ->
            ( model, favouriteHome (encodeHome home) )

        RemoveFavouriteHome home ->
            ( model, removeFavouriteHome (encodeHome home) )

        ShowBottomNotification resultNotification ->
            case resultNotification of
                Ok notification ->
                    ( { model | bottomNotification = Just notification }, Task.perform (\a -> HideBottomNotification) (Process.sleep 3000) )

                _ ->
                    ( model, Cmd.none )

        HideBottomNotification ->
            ( { model | bottomNotification = Nothing }, Cmd.none )

        GetFavouriteHomes ->
            ( model, getFavouriteHomes () )

        Error err ->
            ( { model | errors = [ err ] }, Cmd.none )

        _ ->
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
        div [ class "box animated fadeIn" ]
            [ div [ class "columns" ]
                [ div [ class "column" ]
                    [ div [ class "field is-horizontal " ]
                        [ div [ class "field-body" ]
                            [ div [ class "field has-addons" ]
                                [ div [ class "control " ]
                                    [ a [ class "button is-static" ] [ text "City" ]
                                    ]
                                , div [ class "control is-expanded" ]
                                    [ div [ class "select is-fullwidth" ]
                                        [ Html.select [ onInput SetCity ]
                                            withPlaceholder
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                , div [ class "column" ]
                    [ div [ class "field has-addons" ]
                        [ div [ class "control" ]
                            [ a [ class "button is-static" ] [ text "Lower Price limit" ]
                            ]
                        , div [ class "control is-expanded" ]
                            [ div [ class "select is-fullwidth" ]
                                [ Html.select [ onInput SetLowerPrice ]
                                    (prices model.settings.lowerPrice)
                                ]
                            ]
                        ]
                    ]
                , div [ class "column" ]
                    [ div [ class "field has-addons" ]
                        [ div [ class "control" ]
                            [ a [ class "button is-static" ] [ text "Upper price limit" ]
                            ]
                        , div [ class "control is-expanded" ]
                            [ div [ class "select is-fullwidth" ]
                                [ Html.select [ onInput SetUpperPrice ]
                                    (prices model.settings.upperPrice)
                                ]
                            ]
                        ]
                    ]
                , div [ class "column" ]
                    [ div [ class "field is-expanded" ]
                        [ div [ class "control" ]
                            [ Html.button [ class "button is-primary is-fullwidth ", onClick (GetHomes 0), Html.Attributes.disabled (isNothing model.settings.city) ] [ text "Search" ]
                            ]
                        ]
                    ]
                ]
            ]

    else
        div [] []


menuBar : Model -> Html Msg
menuBar model =
    nav [ class "navbar is-primary m-b-md" ]
        [ div [ class "navbar-brand" ]
            [ Html.a [ class "navbar-item", Html.Attributes.href "#", onClick OpenMainSite ]
                [ i [ class "fas fa-home" ] []
                ]
            , a [ onClick SettingsClicked, class " navbar-item ", Html.Attributes.classList [ ( "hidden", not (model.site == MainSite) ) ] ]
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
        , div [ Html.Attributes.id "navbar-id", Html.Attributes.classList [ ( "navbar-menu", True ), ( "is-active animated ", model.menuOpen ) ] ]
            [ div [ class "navbar-start" ]
                [ a [ class "navbar-item", onClick OpenFavourites ] [ text "Saved favourites" ]
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


type FavouriteOption
    = FavouriteAdd
    | FavouriteRemove
    | FavouriteDisabled


homeTileView : Bool -> FavouriteOption -> Home -> Html Msg
homeTileView isShareApiEnabled favouriteElementOption home =
    let
        imgUrl =
            if String.contains "gumtree" home.link then
                "/gumtree.png"

            else if String.contains "otodom" home.link then
                "/otodom.png"

            else
                "/olx.png"

        ( shareTitle, shareAction ) =
            if isShareApiEnabled then
                ( "ShareApiEnabled", CopyToClipboard home.link )

            else
                ( "Copy Link", CopyToClipboard home.link )

        favouriteElementIcon =
            case favouriteElementOption of
                FavouriteAdd ->
                    a [ class "level-item", onClick (AddFavouriteHome home) ]
                        [ Html.span [ class "icon has-text-grey-lighter fas fa-heart", title "Favourite" ]
                            []
                        ]

                FavouriteRemove ->
                    a [ class "level-item", onClick (RemoveFavouriteHome home) ]
                        [ Html.span [ class "has-text-danger icon  fas fa-heart", title "Remove Favourite" ]
                            []
                        ]

                FavouriteDisabled ->
                    a [] []
    in
    Html.article [ class "media" ]
        [ Html.figure [ class "media-left" ]
            [ Html.p [ class "image is-64x64 " ]
                [ img [ src imgUrl, class "is-marginless is-rounded" ] []
                ]
            ]
        , div [ class "media-content", Html.Attributes.style "overflow-x" "unset" ]
            [ div [ class "content " ]
                [ a [ class "has-text-black has-text-weight-light", onClick (OpenLink home.link) ] [ text home.description ]
                ]
            , Html.nav [ class "level is-mobile" ]
                [ div [ class "level-left" ]
                    [ div [ class "level-item", onClick shareAction ]
                        [ Html.span [ class "has-text-primary" ]
                            [ text (String.fromInt home.price ++ " PLN")
                            ]
                        ]
                    ]
                , div
                    [ class "level-right" ]
                    [ a [ class "level-item", onClick shareAction ]
                        [ Html.span [ class "icon has-text-primary", title shareTitle ]
                            [ i [ class "fas fa-share-alt" ] []
                            ]
                        ]
                    , favouriteElementIcon
                    ]
                ]
            ]
        ]


homesPageView : Page Home -> Bool -> List Home -> Html Msg
homesPageView page isShareApiEnabled favouriteHomes =
    let
        favouriteAction =
            \home ->
                if List.member home favouriteHomes then
                    FavouriteRemove

                else
                    FavouriteAdd

        homes =
            List.map (\home -> homeTileView isShareApiEnabled (favouriteAction home) home)
                page.content
    in
    div [ class "container is-fluid p-l-md", Html.Attributes.style "flex-direction" "column-reverse" ]
        (homes
            ++ [ div [ class "pagination is-centered is-rounded m-t-sm m-b-sm", Html.Attributes.attribute "role" "navigation" ]
                    [ Html.button [ class "pagination-previous", Html.Attributes.disabled (page.number == 0), onClick (GetHomes (page.number - 1)) ] [ text "Previous" ]
                    , Html.ul [ class "pagination-list" ]
                        [ Html.li []
                            [ a [ class "pagination-link" ] [ text (String.fromInt (page.number + 1)) ]
                            ]
                        ]
                    , Html.button [ class "pagination-next", Html.Attributes.style "margin-right" "15px", Html.Attributes.disabled (page.number + 1 == page.totalPages), onClick (GetHomes (page.number + 1)) ] [ text "Next" ]
                    ]
               ]
        )


homesView : Model -> Html Msg
homesView model =
    case model.homesPage of
        Just page ->
            homesPageView page model.shareApiEnabled model.favouriteHomes

        Nothing ->
            div [] []


footerView : Model -> Html Msg
footerView model =
    Html.footer [ class "footer p-b-md p-t-md" ]
        [ div [ class "content has-text-centered " ]
            [ Html.p [] [ text "FubarSoft 2020" ]
            , case model.bottomNotification of
                Just note ->
                    div [ Html.Attributes.id "snackbar", class "show" ]
                        [ text note
                        ]

                _ ->
                    div [] []
            ]
        ]


favouriteView : Model -> Html Msg
favouriteView model =
    div [ class "container is-fluid p-l-md" ]
        (List.map (homeTileView model.shareApiEnabled FavouriteRemove)
            model.favouriteHomes
        )


view : Model -> Html Msg
view model =
    let
        mainView =
            case model.site of
                MainSite ->
                    div []
                        [ settingsView model
                        , homesView model
                        ]

                FavouriteHomesSite ->
                    favouriteView model

        mainContent =
            div [ class "main-content" ]
                [ menuBar model
                , progressBar model
                , mainView
                ]
    in
    div [ class "root" ]
        [ mainContent
        , footerView model
        ]



---- PROGRAM ----


type alias ProgramFlags =
    { shareApiEnabled : Bool
    , backendApi : String
    }


main : Program ProgramFlags Model Msg
main =
    Browser.element
        { view = view
        , init = init
        , update = update
        , subscriptions =
            always
                (Sub.batch
                    [ showSnackbar (\v -> ShowBottomNotification (Json.Decode.decodeValue Json.Decode.string v))
                    , returnFavouriteHomes (\v -> GotFavouriteHomes (Json.Decode.decodeValue homesDecoder v))
                    ]
                )
        }



-- on load get cities
-- on load load first city
-- fill the citie's homes
