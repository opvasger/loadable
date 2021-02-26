# Elm Loadable

Intuitive data-loading in Elm!

This project is an extension of the ideas from a very cool [project](https://package.elm-lang.org/packages/krisajenkins/remotedata/latest)/[blog](http://blog.jenkster.com/2016/06/how-elm-slays-a-ui-antipattern.html)/[talk](https://www.youtube.com/watch?v=NLcRzOyrH08)!

User-interfaces (that I like) usually view initial-loads and reloads differently. Stale information can be viewed in cases where you are reloading a value or failed to.

```elm
type Loadable error value
    = Idle
    | Loading
    | Success value
    | Failure error
    | Reloading value -- you can view the stale value while loading
    | ReloadFailure error value -- you can view the stale value + reload error
```

There's some quality-of-life stuff in here too, in case you're working with `elm/http` or `dillonkearns/elm-graphql`.
