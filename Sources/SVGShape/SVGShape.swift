
import SwiftUI

struct SVGShape: Shape {
    var document: XMLDocument
    let fallback = Path()
    
    init(document: XMLDocument) {
        self.document = document
    }
    
    init(string: String) throws {
        guard let x = try? XMLDocument(xmlString: string) else { throw DecodingError.dataCorrupted(.init(codingPath: .init(), debugDescription: "Oops!")) }
        self.init(document: x)
    }

    func path(in rect: CGRect) -> Path {
        var paths = Path()
        guard let ns = try? document.nodes(forXPath: "//polygon") else { return fallback }
        for n in ns {
            guard let e = n as? XMLElement else { return fallback }
            guard let a = e.attribute(forName: "points") else { return fallback }
            guard let v = a.stringValue else { return fallback }
            let subpath = Path { path in
                for (i,m) in v.matches(of: /(?<x>\d+(\.\d+)?),(?<y>\d+(\.\d+)?)/).enumerated() {
                    let o = m.output
                    let x = (String(o.x) as NSString).floatValue
                    let y = (String(o.y) as NSString).floatValue
                    let p = CGPoint(x: CGFloat(x), y: CGFloat(y))
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
              <polygon points="90,10 40,198 190,78 10,78 160,198" style="fill:lime;stroke:purple;stroke-width:5;fill-rule:nonzero;"/>
              <polygon points="1110,10 1040,198 1190,78 1010,78 1160,198" style="fill:lime;stroke:purple;stroke-width:5;fill-rule:nonzero;"/>
              Sorry, your browser does not support inline SVG.
            </svg>
        """
        SVGShape(string: svgString)
    }
}

