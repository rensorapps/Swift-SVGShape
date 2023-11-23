# SVGShape

Turns an SVG into a shape!

Example:

```swift
#Preview {
    VStack {
        let svgString = """
            <svg height="210" width="500">
                <polygon points="90,10 40,198 190,78 10,78 160,198" />
                <polygon points="1110,10 1040,198 1190,78 1010,78 1160,198" />
                <polygon points="1110,210 1040,398 1190,278 1010,278 1160,398" />
                <polygon points="420,10 500,210 370,250 323,234" />
                <polygon points="200,210 140,398 290,278 110,278 260,398" />
                <polygon points="600,200 650,125 650,175 700,100" fill="none" stroke="black" />
            </svg>
        """
        SVGShape(string: svgString)
    }
}
```

![image](https://github.com/rensorapps/Swift-SVGShape/assets/92299/06a17c71-0f93-4555-b577-e9a3b677fafa)

## Package Dependency


```swift
let package = Package(
    ...
    products: ...
    dependencies: [
        .package(url: "https://github.com/rensorapps/Swift-SVGShape.git", from: "v0.1") // CHOOSE THE BEST TAG FOR YOU!
    ],
    targets: [
        .target(
            ...
            dependencies: [
                .product(name: "SVGShape", package: "SVGShape")
        ...
```


## Limitations

* Currently only supports polygon and curves - (S,C not currently supported)

