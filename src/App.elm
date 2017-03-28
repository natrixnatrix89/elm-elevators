module App exposing (..)

import Html exposing (Html, Attribute, text, div)
import Html.Attributes exposing (class, style)
import Html.Lazy exposing (lazy)
import AnimationFrame exposing (times)
import Time exposing (Time)
import List exposing (range)


floorHeight : Int
floorHeight =
    50


elevatorWidth : Int
elevatorWidth =
    40


hs =
    ( "height", (toString floorHeight) ++ "px" )


ws =
    ( "width", (toString elevatorWidth) ++ "px" )


heightStyle : Attribute Msg
heightStyle =
    style [ hs ]


elevatorStyle : ElevatorNumber -> Elevation -> Attribute Msg
elevatorStyle nr elev =
    style
        [ hs
        , ws
        , ( "transform", "translate3d(" ++ (toString <| (toFloat nr) * (toFloat elevatorWidth) * 1.5) ++ "px, " ++ (toString <| (round elev) * floorHeight) ++ "px, 0px)" )
        ]


type ElevatorState
    = Idle
    | DoorsClosing Time
    | PeopleEntering Time
    | DoorsOpening Time
    | MovingUp Time FloorNumber
    | MovingDown Time FloorNumber


type alias Elevation =
    Float


type alias Person =
    -- The floor number the person wants to go to
    FloorNumber


type alias People =
    List Person


type alias Floor =
    { number : FloorNumber
    , people : People
    }


type alias Floors =
    List Floor


type alias FloorNumber =
    Int


type alias ElevatorNumber =
    Int


type alias Elevator =
    { number : ElevatorNumber
    , payload : People
    , sourceFloor : FloorNumber
    , state : ElevatorState
    }


type alias Model =
    { floors : Floors
    , elevators : List Elevator
    , time : Time
    }


init : ( Model, Cmd Msg )
init =
    ( Model
        (range 0 6
            |> List.map (\f -> Floor f [ (f + 1) % 4, (f + 2) % 4 ])
        )
        (range 0 4
            |> List.map (\e -> Elevator e [ (e - 1) % 4 ] 0 Idle)
        )
        0
    , Cmd.none
    )


type Msg
    = Tick Time


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick time ->
            ( { model | time = time }
            , Cmd.none
            )


renderPerson : Person -> Html Msg
renderPerson =
    always <| div [ class "pers" ] [ text "😀" ]


renderElevator : Elevator -> Html Msg
renderElevator e =
    div [ class "elevator", elevatorStyle e.number (toFloat e.sourceFloor) ] []


renderElevators : Model -> Html Msg
renderElevators =
    .elevators
        >> lazy
            (div [ class "elevators" ]
                << List.map renderElevator
            )


renderFloor : Floor -> Html Msg
renderFloor floor =
    div [ class "floor", style [ ( "top", toString (floor.number) ++ "px" ) ] ]
        [ div [ class "number" ] [ text <| toString floor.number ]
        ]


renderFloors : Model -> Html Msg
renderFloors =
    .floors
        >> lazy
            -- >> (\f -> ( List.length f, f ))
            (div [ class "floors" ]
                << List.map (renderFloor)
             -- << List.reverse
            )


worldAttributes : Int -> List (Attribute Msg)
worldAttributes floorCount =
    [ class "innerworld", style [ ( "height", toString (floorHeight * floorCount) ++ "px" ) ] ]


view : Model -> Html Msg
view model =
    div [ class "container" ]
        [ div [ class "world" ]
            [ div (worldAttributes <| List.length model.floors)
                [ renderFloors model
                , renderElevators model
                ]
            ]
        ]


upPushed : Floor -> Bool
upPushed floor =
    List.any ((<) floor.number) floor.people


downPushed : Floor -> Bool
downPushed floor =
    List.any ((>) floor.number) floor.people



-- floorButtonsPushed : Floor -> Floors -> List ( FloorNumber, Bool )
-- floorButtonsPushed floor floors =
--     List.map (\f -> ( f.number, List.member f floor.people )) floors


subscriptions : Model -> Sub Msg
subscriptions model =
    times Tick
