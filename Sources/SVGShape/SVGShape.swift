
import SwiftUI

struct SVGShape: Shape {
    private var polygons: [[CGPoint]]
    
    init(points: [[CGPoint]]) {
        polygons = points
    }

    static func error(_ s: String) -> DecodingError {
        return DecodingError.dataCorrupted(.init(codingPath: .init(), debugDescription: s))
    }
    
    init(document: XMLDocument) throws {
        polygons = []
        let ns = try document.nodes(forXPath: "//polygon")
        for n in ns {
            var polypoints: [CGPoint] = []
            guard let e = n as? XMLElement else { throw SVGShape.error("Found non-element polygon") }
            guard let a = e.attribute(forName: "points") else { throw SVGShape.error("No points found for polygon") }
            guard let v = a.stringValue else { throw SVGShape.error("No value found for polygon points") }
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
    
    init(string: String) throws {
        let x = try XMLDocument(xmlString: string)
        try self.init(document: x)
    }

    func path(in rect: CGRect) -> Path {
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
        let svgString = """
            <svg height="210" width="500">
              <polygon points="90,10 40,198 190,78 10,78 160,198" />
              <polygon points="1110,10 1040,198 1190,78 1010,78 1160,198" />
              <polygon points="1110,210 1040,398 1190,278 1010,278 1160,398" />
              Sorry, your browser does not support inline SVG.
            </svg>
        """
        try! SVGShape(string: svgString)
    }
}

