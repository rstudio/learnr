# Disable all html tags

Method to disable all html tags to not allow users to interact with the
html.

## Usage

``` r
disable_all_tags(ele)
```

## Arguments

- ele:

  html tag element

## Value

An htmltools HTML object with appended `class = "disabled"` and
`disabled` attributes on all tags.

## Examples

``` r
# add an href to all a tags
disable_all_tags(
  htmltools::tagList(
    htmltools::a(),
    htmltools::a()
  )
)
#> <a class="disabled" disabled></a>
#> <a class="disabled" disabled></a>
```
