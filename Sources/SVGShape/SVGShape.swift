
import SwiftUI

public struct SVGShape: Shape {
    private var polygons: [[CGPoint]] = []
    
    public init(points: [[CGPoint]]) {
        polygons = points
    }

    private func error(_ s: String) -> DecodingError {
        return DecodingError.dataCorrupted(.init(codingPath: .init(), debugDescription: s))
    }
    
    // See: https://www.w3.org/TR/SVG2/shapes.html
    public init(document: XMLDocument) throws {
        polygons = []
        let ns = try document.nodes(forXPath: "//polygon")
        for n in ns {
            var polypoints: [CGPoint] = []
            guard let e = n as? XMLElement else { throw error("Found non-element polygon") }
            guard let a = e.attribute(forName: "points") else { throw error("No points found for polygon") }
            guard let v = a.stringValue else { throw error("No value found for polygon points") }
            for m in v.matches(of: /(?<x>\d+(\.\d+)?),(?<y>\d+(\.\d+)?)/) {
                let o = m.output
                let x = (String(o.x) as NSString).floatValue
                let y = (String(o.y) as NSString).floatValue
                let p = CGPoint(x: CGFloat(x), y: CGFloat(y))
                polypoints.append(p)
            }
            polygons.append(polypoints)
        }
    }
    
    public init(string: String) throws {
        let x = try XMLDocument(xmlString: string)
        try self.init(document: x)
    }

    public func path(in rect: CGRect) -> Path {
        var paths = Path()
        for g in polygons {
            let subpath = Path { path in
                for (i,p) in g.enumerated() {
                    if(i < 1) {
                        path.move(to: p)
                    } else {
                        path.addLine(to: p)
                    }
                }
            }
            paths.addPath(subpath)
        }
        
        let br = paths.boundingRect
        let sX = rect.width / br.width
        let sY = rect.height / br.height
        let s = min(sX, sY)

        // TODO: Use a single transform
        let path2 = paths.transform(.identity.scaledBy(x: s, y: s)).path(in: rect)

        let br2 = path2.boundingRect
        let deltaX = rect.midX - br2.midX
        let deltaY = rect.midY - br2.midY
        return path2.transform(CGAffineTransform(translationX: deltaX, y: deltaY)).path(in: rect)
    }
}

#Preview {
    VStack {
        let svgString
            = """
                <svg height="210" width="500">
                    <polygon points="90,10 40,198 190,78 10,78 160,198" />
                    <polygon points="1110,10 1040,198 1190,78 1010,78 1160,198" />
                    <polygon points="1110,210 1040,398 1190,278 1010,278 1160,398" />
                    <polygon points="420,10 500,210 370,250 323,234" />
                    <polygon points="200,210 140,398 290,278 110,278 260,398" />
                    <polygon points="600,200 650,125 650,175 700,100" fill="none" stroke="black" />
                </svg>
            """
        try! SVGShape(string: svgString)
    }
}
