module Loadable exposing
    ( Loadable(..), expectUpdate, fromResult
    , isLoading, isStale, hasValue, hasError
    , map, mapError, toValue, toError
    , FromGraphql, FromHttp
    )

{-| This module helps you model values loaded, for example, from a database over Http/GraphQL.

These three definitions are the bread and butter of the module:

1.  Add a loadable to your model-definition.
2.  Request some data, and update your loadable to expect it.
3.  Receive a result, and transform it into a loadable, that then goes into your model.

The next logical step is to model your views according to the model. For example with `mdgriffith/elm-ui`:

```elm
viewProductList : Loadable.FromHttp (List Product) -> Element Msg
viewProductList products =
    let
        viewErrorAndRetry =
             Loadable.toError products
                |> Maybe.map (viewErrorAndRetryOverlay getProductsCmd)
                |> Maybe.withDefault Element.none

        viewLoading =
            if Loadable.isLoading products then
                viewLoadingIndicator
            else
                Element.none

        productElements =
             Loadable.toValue products
                |> Maybe.map (List.indexedMap viewProductListItem)
                |> Maybe.withDefault []
    in
    Element.column
        [ Element.inFront viewErrorAndRetry,
        , Element.inFront viewLoading
        ]
        productElements
```

@docs Loadable, expectUpdate, fromResult


# Queries

@docs isLoading, isStale, hasValue, hasError


# Conversion

@docs map, mapError, toValue, toError


# Aliases

Use these aliases to tidy up your model-definition

@docs FromGraphql, FromHttp

-}

import Graphql.Http
import Http


{-| A representation of data-loading. This would usually go into your model.
-}
type Loadable error value
    = Idle
    | Loading
    | Success value
    | Failure error
    | Reloading value
    | ReloadFailure error value


{-| Update your loadable to expect a new value. Use this when you expect a new value to arrive soon.
-}
expectUpdate : Loadable error value -> Loadable error value
expectUpdate loadable =
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


{-| Convert a result into a loadable. Use this when a new value arrives, and your loadable is expecting the update.
-}
fromResult : Result error value -> Loadable error value
fromResult result =
    case result of
        Ok value ->
            Success value

        Err error ->
            Failure error



-- Queries


{-| Is the loadable expecting a new value?
-}
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


{-| Does the loadable contain a stale value?
Staleness implies a reload is underway or failed, in which case the value from the most recent load is available.
-}
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


{-| Is any value, stale or otherwise, contained within the loadable?
-}
hasValue : Loadable error value -> Bool
hasValue =
    (/=) Nothing << toValue


{-| Has the loadable failed on the latest load or reload?
-}
hasError : Loadable error value -> Bool
hasError =
    (/=) Nothing << toError



-- Conversion


{-| Transform the value of a loadable.
-}
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


{-| Transform the error of a loadable.
-}
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


{-| Extract the value of a loadable, should there be one.
-}
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


{-| Extract the error of a loadable, should there be one.
-}
toError : Loadable error value -> Maybe error
toError loadable =
    case loadable of
        Failure error ->
            Just error

        ReloadFailure error _ ->
            Just error

        _ ->
            Nothing



-- Aliases


{-| data over GraphQL is a good use-case for loadables.
-}
type alias FromGraphql value =
    Loadable (Graphql.Http.Error value) value


{-| data over Http is a good use-case for loadables.
-}
type alias FromHttp value =
    Loadable Http.Error value
