module Loadable exposing
    ( FromGraphql
    , FromHttp
    , Loadable(..)
    , fromResult
    , hasError
    , hasValue
    , isLoading
    , isStale
    , load
    , map
    , mapError
    , toError
    , toValue
    )

import Graphql.Http
import Http


type Loadable error value
    = Idle
    | Loading
    | Success value
    | Failure error
    | Reloading value
    | ReloadFailure error value



-- Queries


isLoading : Loadable error value -> Bool
isLoading loadable =
    case loadable of
        Loading ->
            True

        Reloading _ ->
            True

        Success _ ->
            False

        ReloadFailure _ _ ->
            False

        Failure _ ->
            False

        Idle ->
            False


isStale : Loadable error value -> Bool
isStale loadable =
    case loadable of
        Reloading _ ->
            True

        ReloadFailure _ _ ->
            True

        Loading ->
            False

        Success _ ->
            False

        Failure _ ->
            False

        Idle ->
            False


hasValue : Loadable error value -> Bool
hasValue =
    (/=) Nothing << toValue


hasError : Loadable error value -> Bool
hasError =
    (/=) Nothing << toError



-- Mutation


load : Loadable error value -> Loadable error value
load loadable =
    case loadable of
        Success value ->
            Reloading value

        ReloadFailure _ stale ->
            Reloading stale

        Failure _ ->
            Loading

        Idle ->
            Loading

        Loading ->
            loadable

        Reloading _ ->
            loadable


map : (value -> otherValue) -> Loadable error value -> Loadable error otherValue
map fromValue loadable =
    case loadable of
        Idle ->
            Idle

        Loading ->
            Loading

        Success value ->
            Success (fromValue value)

        Failure error ->
            Failure error

        Reloading stale ->
            Reloading (fromValue stale)

        ReloadFailure error stale ->
            ReloadFailure error (fromValue stale)


mapError : (error -> otherError) -> Loadable error value -> Loadable otherError value
mapError fromError loadable =
    case loadable of
        Idle ->
            Idle

        Loading ->
            Loading

        Success value ->
            Success value

        Failure error ->
            Failure (fromError error)

        Reloading stale ->
            Reloading stale

        ReloadFailure error stale ->
            ReloadFailure (fromError error) stale



-- Conversion


toValue : Loadable error value -> Maybe value
toValue loadable =
    case loadable of
        Success value ->
            Just value

        ReloadFailure _ stale ->
            Just stale

        Reloading stale ->
            Just stale

        _ ->
            Nothing


toError : Loadable error value -> Maybe error
toError loadable =
    case loadable of
        Failure error ->
            Just error

        ReloadFailure error _ ->
            Just error

        _ ->
            Nothing


fromResult : Result error value -> Loadable error value
fromResult result =
    case result of
        Ok value ->
            Success value

        Err error ->
            Failure error



-- FromGraphql


type alias FromGraphql value =
    Loadable (Graphql.Http.Error value) value



-- FromHttp


type alias FromHttp value =
    Loadable Http.Error value
