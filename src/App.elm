module App exposing (..)

import Html exposing (Html, Attribute, text, div, span, i)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Html.Lazy exposing (lazy, lazy2, lazy3)
import Html.Keyed
import AnimationFrame
import Time exposing (Time, minute)
import List exposing (range)
import Set exposing (Set)
import Spawner
import DataTypes exposing (..)
import Simulator exposing (advance)


elevatorY : Time -> Elevator -> Float
elevatorY time elevator =
    case elevator.state of
        Moving _ eta floor ->
            Debug.crash "Acceleration formulas haven't been implemented yet"

        _ ->
            floorHeight * (toFloat elevator.sourceFloor)


hs : ( String, String )
hs =
    ( "height", (toString floorHeight) ++ "px" )


ws : ( String, String )
ws =
    ( "width", (toString elevatorWidth) ++ "px" )


heightStyle : Attribute Msg
heightStyle =
    style [ hs ]


init : ( Model, Cmd Msg )
init =
    let
        floors =
            range 0 4
                |> List.map (\f -> Floor f Set.empty)

        ( nextPerson, seed ) =
            Spawner.step 0 (List.length floors) Spawner.seed
    in
        ( Model
            floors
            (range 0 4
                |> List.map (\e -> Elevator e ((e - 1) % (List.length floors)) [] Idle)
            )
            []
            0
            nextPerson
            seed
            Running
        , Cmd.none
        )


type Msg
    = Tick Time
    | Jump


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick diff ->
            ( advance model diff
            , Cmd.none
            )

        Jump ->
            ( Debug.log "model" (advance model (2 * minute))
            , Cmd.none
            )


elevatorTransforms : Int -> Float -> Float -> Attribute Msg
elevatorTransforms nr elevation wh =
    style
        [ ws
        , ( "transform"
          , "translate3d("
                ++ (toString <| round <| (toFloat nr) * elevatorWidth * 1.5 + 200)
                ++ "px, "
                ++ (toString <| round <| wh - elevation - floorHeight)
                ++ "px, 0px)"
          )
        ]


renderButtonsPressed : Floors -> Floors -> Html Msg
renderButtonsPressed =
    lazy2
        (\floors pressed ->
            floors
                |> List.map
                    (\f ->
                        let
                            c : String
                            c =
                                if List.member f pressed then
                                    " activated"
                                else
                                    ""
                        in
                            span [ class <| "buttonpress" ++ c ] [ text <| toString f.number ]
                    )
                |> span [ class "buttonindicator" ]
        )


elevatorDoors : Float -> Html Msg
elevatorDoors =
    lazy
        (\offset ->
            div
                [ class "doors"
                , style
                    [ ( "transform"
                      , "translate3d("
                            ++ (toString <| round offset)
                            ++ "px, 0px, 0px)"
                      )
                    ]
                ]
                []
        )


doorOffset : Time -> Elevator -> Float
doorOffset time el =
    case el.state of
        DoorsOpening eta ->
            elevatorWidth
                * (eta - time)
                / doorOpenDuration

        DoorsClosing eta ->
            elevatorWidth
                * (1 - (eta - time) / doorOpenDuration)

        PeopleEntering _ ->
            elevatorWidth

        _ ->
            0


renderElevator : Floors -> Time -> Float -> Elevator -> Html Msg
renderElevator floors time wh el =
    lazyElevator
        ( doorOffset time el, elevatorY time el, wh )
        floors
        el


shownFloorNumber : Elevation -> String
shownFloorNumber elev =
    elev
        / floorHeight
        |> toString


lazyElevator : ( Float, Elevation, Float ) -> Floors -> Elevator -> Html Msg
lazyElevator =
    lazy3
        (\( doorOffset, elevation, wh ) floors e ->
            div [ class "elevator movable", elevatorTransforms e.number elevation wh ]
                [ span [ class "directionindicator directionindicatorup" ] [ i [ class "fa fa-arrow-circle-up up activated" ] [] ]
                , span [ class "floorindicator" ] [ text <| shownFloorNumber elevation ]
                , span [ class "directionindicator directionindicatordown" ] [ i [ class "fa fa-arrow-circle-down down activated" ] [] ]
                , renderButtonsPressed floors e.buttonsPressed
                , elevatorDoors doorOffset
                ]
        )


renderElevators : Floors -> Time -> List Elevator -> Float -> Html Msg
renderElevators floors time elevators wh =
    elevators
        |> List.map (renderElevator floors time wh)
        |> div [ class "elevators" ]


renderFloor : Int -> Floor -> Html Msg
renderFloor floorCount floor =
    div [ class "floor", style [ ( "top", toString ((toFloat (floorCount - floor.number - 1)) * floorHeight) ++ "px" ) ] ]
        [ span [ class "floornumber" ] [ text <| toString floor.number ]
        , span [ class "buttonindicator" ]
            [ i [ class "fa fa-arrow-circle-up up" ] []
            , text " "
            , i [ class "fa fa-arrow-circle-down down" ] []
            ]
        ]


renderFloors : Floors -> Html Msg
renderFloors =
    lazy
        (\f ->
            f
                |> List.map (renderFloor (List.length f))
                |> div [ class "floors" ]
        )


personPosition : Time -> List Elevator -> Person -> ( Float, Elevation )
personPosition time elevators p =
    case p.state of
        Waiting pos floor ->
            ( 90 + (toFloat pos) * peopleSpacing
            , ((toFloat <| List.length elevators) - (toFloat floor)) * floorHeight - 19
            )

        _ ->
            ( 10, 10 )


lazyPerson : ( Float, Elevation ) -> Gender -> Html Msg
lazyPerson =
    lazy2
        (\( x, y ) gender ->
            i
                [ class <|
                    "movable fa user fa-"
                        ++ case gender of
                            Male ->
                                "male"

                            Female ->
                                "female"
                , style
                    [ ( "transform"
                      , "translate3d("
                            ++ toString x
                            ++ "px, "
                            ++ toString y
                            ++ "px, 0px)"
                      )
                    ]
                ]
                []
        )


renderPerson : Time -> List Elevator -> Person -> ( String, Html Msg )
renderPerson time elevators person =
    ( person.born
    , lazyPerson
        (personPosition time elevators person)
        person.gender
    )


renderPeople : Time -> List Elevator -> People -> Html Msg
renderPeople time elevators people =
    people
        |> List.map (renderPerson time elevators)
        |> Html.Keyed.node "div" [ class "people" ]


worldAttributes : Float -> List (Attribute Msg)
worldAttributes height =
    [ class "innerworld", style [ ( "height", toString height ++ "px" ) ] ]


view : Model -> Html Msg
view model =
    let
        totalHeight =
            (toFloat <| List.length model.floors) * floorHeight
    in
        div [ class "container" ]
            [ div [ class "world" ]
                [ div (worldAttributes totalHeight)
                    [ renderFloors model.floors
                    , renderElevators model.floors model.time model.elevators totalHeight
                    , renderPeople model.time model.elevators model.people
                    ]
                ]
            , div [ class "timer", onClick Jump ] [ text "Jump 2 minutes ahead" ]
            ]


isOnFloor : FloorNumber -> Person -> Bool
isOnFloor floor person =
    case person.state of
        Waiting _ nr ->
            nr == floor

        _ ->
            False


isButtonPushed : (Int -> Int -> Bool) -> Floor -> People -> Bool
isButtonPushed cmp floor people =
    people
        |> List.filter (isOnFloor floor.number)
        |> List.map .target
        |> List.any (cmp floor.number)


upPushed : Floor -> People -> Bool
upPushed =
    isButtonPushed (<)


downPushed : Floor -> People -> Bool
downPushed =
    isButtonPushed (>)


subscriptions : Model -> Sub Msg
subscriptions model =
    AnimationFrame.diffs Tick
