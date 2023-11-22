# SVGShape

Turns an SVG into a shape!

Example:

```swift
#Preview {
    VStack {
        let data = """
            <svg height="210" width="500">
              <polygon points="90,10 40,198 190,78 10,78 160,198" style="fill:lime;stroke:purple;stroke-width:5;fill-rule:nonzero;"/>
              <polygon points="1110,10 1040,198 1190,78 1010,78 1160,198" style="fill:lime;stroke:purple;stroke-width:5;fill-rule:nonzero;"/>
              Sorry, your browser does not support inline SVG.
            </svg>
        """
        SVGShape(data: data)
    }
}
```

## Limitations

* Currently only supports polygon paths.
