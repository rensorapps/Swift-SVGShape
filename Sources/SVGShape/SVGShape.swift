
import SwiftUI

// From: https://www.hackingwithswift.com/example-code/language/how-to-make-array-access-safer-using-a-custom-subscript
extension Array {
    public subscript(index: Int, default defaultValue: @autoclosure () -> Element) -> Element {
        guard index >= 0, index < endIndex else {
            return defaultValue()
        }
        return self[index]
    }
    
    public func get(_ index: Int) throws -> Element {
        guard index >= 0, index < endIndex else {
            throw NSError() // TODO: Better error type
        }
        return self[index]
    }
    
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

func / (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
    return CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
}

extension CGPoint {
    func rotated(_ angle: Angle) -> CGPoint {
        let a = CGFloat(angle.radians)
        let rotatedX = self.x * cos(a) - self.y * sin(a)
        let rotatedY = self.x * sin(a) + self.y * cos(a)
        return CGPoint(x: rotatedX, y: rotatedY)
    }
    
    func scaled(_ factor: CGFloat) -> CGPoint {
        return CGPoint(x: self.x * factor, y: self.y * factor)
    }
    
    func scaled(_ factor: CGPoint) -> CGPoint {
        let scaledX = self.x * factor.x
        let scaledY = self.y * factor.y
        return CGPoint(x: scaledX, y: scaledY)
    }
    
    var magnitude: CGFloat {
        sqrt(pow(self.x,2) + pow(self.y,2))
    }
    
    var angle: Angle {
        Angle(radians: atan(self.y/self.x))
    }
    
    var unit: CGPoint {
        self.scaled(1/self.magnitude)
    }
}

public struct SVGShape: Shape {
    private var polygons: [[CGPoint]] = []
    private var paths: [[Command]] = []
    private var circles: [SVGCircle] = []
    
    public enum Command: Sendable {
        case moveTo(CGPoint)                        // MoveTo: M, m
        case lineTo(CGPoint)                        // LineTo: L, l, H, h, V, v
        case cubicCurve(CGPoint,
                        ctrl1: CGPoint,
                        ctrl2: CGPoint)             // Cubic Bézier Curve: C, c, S, s
        case quadraticCurve(CGPoint, CGPoint)       // Quadratic Bézier Curve: Q, q, T, t
        case ellipticalCurve(
            CGPoint, CGPoint,
            CGFloat, CGFloat,
            Angle,
            Bool, Bool)                             // Elliptical Arc Curve: A, a
        case closePath                              // ClosePath: Z, z
    }
    
    public struct SVGCircle: Sendable {
        var point: CGPoint
        var radius: CGFloat
    }
    
    private static func error(_ s: String) -> DecodingError {
        return DecodingError.dataCorrupted(.init(codingPath: .init(), debugDescription: s))
    }
    
    private static func parseCircle(_ n: XMLNode) throws -> SVGCircle {
        guard let e = n as? XMLElement else { throw error("Found non-element circle") }
        
        guard let cx = e.attribute(forName: "cx"),
              let sx = cx.stringValue
          else { throw error("No x found for circle") }
        let x = CGFloat((sx as NSString).floatValue)
        
        guard let cy = e.attribute(forName: "cy"),
              let sy = cy.stringValue
          else { throw error("No y found for circle") }
        let y = CGFloat((sy as NSString).floatValue)

        guard let cr = e.attribute(forName: "r"),
              let sr = cr.stringValue
          else { throw error("No r found for circle") }
        let r = CGFloat((sr as NSString).floatValue)

        return SVGCircle(point: CGPoint(x: x, y: y), radius: r)
    }
    
    private static func parsePolygon(_ n: XMLNode) throws -> [CGPoint] {
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
        return polypoints
    }
    
    public static func parseArgs(_ s: Substring) throws -> [CGFloat] {
        // Regex from: https://stackoverflow.com/a/23872060
        let ms = s.matches(of: /\s*(?<n>[+-]?((\d+(\.\d*)?)|(\.\d+)))\s*/)
        return ms.map { m in
            let f = CGFloat((m.output.n as NSString).floatValue)
            return f
        }
    }

    // From: https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/d
    private static func parsePath(_ n: XMLNode) throws -> [Command] {
        var commands: [Command] = []
        
        guard let e = n as? XMLElement else { throw error("Found non-element path") }
        guard let a = e.attribute(forName: "d") else { throw error("No commands found for path") }
        guard let v = a.stringValue else { throw error("No value found for path commands") }

        var pos = CGPoint(x: 0, y: 0)
        var lastCurvePoint: CGPoint?
        
        // TODO: Z has no arguments, so this regex groups the following command like: zm
        for m in v.matches(of: /(?<c>[MLHVCSQTAZ])(?<a>[^MLHVCSQTAZ]*)/.ignoresCase()) {
            let o = m.output
            let a = try Self.parseArgs(o.a)
            
            switch o.c {
                
            case "M":
                for an in a.chunked(into: 2) {
                    pos.x = an[0] // TODO: Check bounds
                    pos.y = an[1]
                    commands.append(.moveTo(pos))
                }
                lastCurvePoint = nil
            case "m":
                for an in a.chunked(into: 2) {
                    pos.x += an[0]
                    pos.y += an[1]
                    commands.append(.moveTo(pos))
                }
                lastCurvePoint = nil
                
            case "L":
                for an in a.chunked(into: 2) {
                    pos.x = an[0]
                    pos.y = an[1]
                    commands.append(.lineTo(pos))
                }
                lastCurvePoint = nil
            case "l":
                for an in a.chunked(into: 2) {
                    pos.x += an[0]
                    pos.y += an[1]
                    commands.append(.lineTo(pos))
                }
                lastCurvePoint = nil
            case "H":
                for an in a {
                    pos.x = an
                    commands.append(.lineTo(pos))
                }
                lastCurvePoint = nil
            case "h":
                for an in a {
                    pos.x += an
                    commands.append(.lineTo(pos))
                }
                lastCurvePoint = nil
            case "V":
                for an in a {
                    pos.y = an
                    commands.append(.lineTo(pos))
                }
                lastCurvePoint = nil
            case "v":
                for an in a {
                    pos.y += an
                    commands.append(.lineTo(pos))
                }
                lastCurvePoint = nil
                
            // TODO: Actually implement curves
//            case "C":
//                for an in a.chunked(into: 6) {
//                    do {
//                        let x = try an.get(4)
//                        let y = try an.get(5)
//                        pos.x = x
//                        pos.y = y
//                        commands.append(.lineTo(pos))
//                    } catch {}
//                }
            case "c":
                for an in a.chunked(into: 6) {
                    do {
                        let dx1 = try an.get(0) + pos.x
                        let dy1 = try an.get(1) + pos.y
                        let dx2 = try an.get(2) + pos.x
                        let dy2 = try an.get(3) + pos.y
                        let x   = try an.get(4)
                        let y   = try an.get(5)
                        // TODO: Something more robust with this
                        lastCurvePoint = CGPoint(x: dx2, y: dy2)
                        pos.x += x
                        pos.y += y
                        commands.append(
                            .cubicCurve(pos,
                                ctrl1: CGPoint(x: dx1, y: dy1),
                                ctrl2: CGPoint(x: dx2, y: dy2)))
                    } catch { print("OOB - c: \(an) \(a)") }
                }
//            case "S":
//                pos.x = a[4] // TODO: Check bounds
//                pos.y = a[5]
//                commands.append(.lineTo(pos))
            case "s":
                for an in a.chunked(into: 4) {
                    do {
                        let dx2 = try pos.x + an.get(0)
                        let dy2 = try pos.y + an.get(1)
                        var dx1 = pos.x
                        var dy1 = pos.y
                        let x = try an.get(2)
                        let y = try an.get(3)
                        
                        if let lastCurvePoint {
                            let dx = pos.x - lastCurvePoint.x
                            let dy = pos.y - lastCurvePoint.y
                            dx1 = pos.x + dx
                            dy1 = pos.y + dy
                        }
                        
                        // TODO: Something more robust with this
                        lastCurvePoint = CGPoint(x: dx2, y: dy2)
                        
                        pos.x += x
                        pos.y += y
                        commands.append(
                            .cubicCurve(pos,
                                ctrl1: CGPoint(x: dx1, y: dy1),
                                ctrl2: CGPoint(x: dx2, y: dy2)))
                    } catch { print("OOB - s: \(an)") }
                }
                
            // case A
            case "a":
                for an in a.chunked(into: 7) {
                    print(an) // TODO
                    do {
                        let rx       = try an.get(0)
                        let ry       = try an.get(1)
                        let angle    = try Angle(degrees: an.get(2))
                        let largeArc = try an.get(3) == 1
                        let sweep    = try an.get(4) == 1
                        let x        = try an.get(5)
                        let y        = try an.get(6)
                        let previous = pos
                        pos.x += x
                        pos.y += y
                        
                        commands.append(
                            Command.ellipticalCurve(previous, pos, rx, ry, angle, largeArc, sweep))
                        
                    } catch { print("OOB - a: \(an)") }
                }
                
            case "z":
                // TODO: Move back to start position
                commands.append(.closePath)
                lastCurvePoint = nil
            case "Z":
                commands.append(.closePath)
                lastCurvePoint = nil

            default:
                print("Unrecognized path command \(o.c)")
                lastCurvePoint = nil
            }
        }

        return commands
    }
    
    private static func drawPolygon() { // -> Path
    }
    
    private static func drawCircle() {
    }
    
    private static func drawPath()  {
    }
    
    /// Skips parsing and just sets data directly
    public init(polygonPoints: [[CGPoint]], pathCommands: [[Command]]) {
        polygons = polygonPoints
        paths = pathCommands
    }
    
    // See: https://www.w3.org/TR/SVG2/shapes.html
    public init(document: XMLDocument) throws {
        let polyNodes = try document.nodes(forXPath: "//polygon")
        for n in polyNodes {
            if let p = try? Self.parsePolygon(n) {
                polygons.append(p) // TODO: Error logging?
            }
        }
        let pathNodes = try document.nodes(forXPath: "//path")
        for n in pathNodes {
            if let p = try? Self.parsePath(n) {
                paths.append(p)
            }
        }
        let circleNodes = try document.nodes(forXPath: "//circle")
        for c in circleNodes {
            if let p = try? Self.parseCircle(c) {
                circles.append(p)
            }
        }
    }
    
    public init(string: String) throws {
        let x = try XMLDocument(xmlString: string)
        try self.init(document: x)
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        for g in polygons {
            let subpath = Path { t in
                for (i,p) in g.enumerated() {
                    if(i < 1) {
                        t.move(to: p)
                    } else {
                        t.addLine(to: p)
                    }
                }
            }
            path.addPath(subpath)
        }
        
        for h in paths {
            let subpath = Path { p in
                for c in h {
                    switch c {
                    case .moveTo(let a):
                        p.move(to: a)
                    case .lineTo(let a):
                        p.addLine(to: a)
                    case .cubicCurve(let a, let c1, let c2):
                        p.addCurve(to: a, control1: c1, control2: c2)
                    case .ellipticalCurve(let p1, let p2, let ra, let rb, let theta, let large, let sweep):
                        
                        print((p1,p2,ra,rb,theta,large,sweep))
                        /*
                         Draw an Arc curve from the current point to a point for which coordinates are those of the current point shifted by dx along the x-axis and dy along the y-axis. The center of the ellipse used to draw the arc is determined automatically based on the other parameters of the command:

                         See: https://www.w3.org/TR/SVG/paths.html#PathDataEllipticalArcCommands
                         
                         rx and ry are the two radii of the ellipse;
                         angle represents a rotation (in degrees) of the ellipse relative to the x-axis;
                         large-arc-flag and sweep-flag allows to chose which arc must be drawn as 4 possible arcs can be drawn out of the other parameters.
                         large-arc-flag allows a choice of large arc (1) or small arc (0),
                         sweep-flag allows a choice of a clockwise arc (1) or counterclockwise arc (0)
                         */

                        // translate p1 to the origin and find where p2 ends up
                        let p2_translated = p2 - p1
                        
                        // rotate the ellipse back to zero
                        let p2_rotated = p2_translated.rotated(-theta)
                        
                        // scale by minor and major axes
                        let p2_scaled = p2_rotated.scaled(CGPoint(x:1/ra, y: 1/rb))
                        
                        // find the mid-point
                        let mid_scaled = p2_scaled / 2
                        
                        // unit perpendicular
                        let up = p2_scaled.rotated(Angle(degrees: large ? 90 : -90)).unit
                        
                        // scale up with trig calculation to find c
                        let c_scaled = mid_scaled + up.scaled(sqrt(1 - pow(mid_scaled.magnitude,2)))
                        
                        let a_angle = (CGPoint(x: 0, y: 0) - c_scaled).angle
                        let b_angle = (p2_scaled - c_scaled).angle
                        
                        // Draw a circle passing through the points,
                        // then reverse everything back into an ellipse
                        if large {
                            p.addArc(
                                center: c_scaled, radius: 1,
                                startAngle: a_angle, endAngle: b_angle,
                                clockwise: sweep,
                                transform:
                                    // unscale
                                    // unrotate
                                    // untranslate
                                    .identity
                                    .translatedBy(x: p1.x, y: p1.y)
                                    //.rotated(by: theta.radians)
                                    //.scaledBy(x: ra, y: rb)
                            )
                        }
                    case .closePath:
                        p.closeSubpath()
                    default:
                        print("Unrecognised command: \(c)")
                    }
                }
            }
            path.addPath(subpath)
        }
        
        for c in circles {
            let subpath = Path { p in
                p.addArc(center: c.point, radius: c.radius, startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 360), clockwise: true)
            }
            path.addPath(subpath)
        }
        
        let br = path.boundingRect
        let sX = rect.width / br.width
        let sY = rect.height / br.height
        let s = min(sX, sY)

        // TODO: Use a single transform
        let path2 = path.transform(.identity.scaledBy(x: s, y: s)).path(in: rect)

        let br2 = path2.boundingRect
        let deltaX = rect.midX - br2.midX
        let deltaY = rect.midY - br2.midY
        return path2.transform(CGAffineTransform(translationX: deltaX, y: deltaY)).path(in: rect)
    }
}

#Preview {
    VStack {
        /*
         let rx       = try an.get(0)
         let ry       = try an.get(1)
         let angle    = try Angle(degrees: an.get(2))
         
         let largeArc = try an.get(3) == 1
         let sweep    = try an.get(4) == 1
         
         let x        = try an.get(5)
         let y        = try an.get(6)
         */
        let svgString
            = """
               <svg height="210" width="500">
                   <circle cx="0" cy="0" r="0.01" />
                   <circle cx="0" cy="1" r="0.01" />
                    
                   <path d="M 0 0
                    
                            a 1 1  0
                              1 0
                              0 1
                    
                            z" />
               </svg>
            """
        try! SVGShape(string: svgString)
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

#Preview {
    VStack {
        let svgString
            = """
              <svg xmlns="http://www.w3.org/2000/svg" enable-background="new 0 0 85 95" viewBox="0 0 85 95">
                <g fill="#102954">
                    <path d="m79.9 31.8c2.6-6.3 2.6-19.1-.8-28.9-.9-1.8-3.6-1.2-3.7.7v.7c-.6 9.4-4 14.5-9.1 17-.8.4-2.1.4-3-.2-6-3.8-13.2-6-20.9-6s-14.8 2.3-20.9 6c-.8.5-1.8.6-2.6.2-5.2-1.9-8.8-7.6-9.4-17.1v-.7c0-1.9-2.8-2.5-3.6-.7-3.4 10-3.3 22.8-.8 29 1.3 3.1 1.3 6.6.2 9.8-1.4 4-2.1 8.5-2 13 .5 20.6 18 38.2 38.7 38.5 21.8.4 39.5-17.1 39.5-39 0-4.4-.7-8.5-2-12.4-1-3.2-.9-6.8.4-9.9zm-38 52.1c-15.8-.4-28.9-13.3-29.1-29.2-.4-16.9 13.4-30.7 30.2-30.3 15.9.2 28.9 13.3 29.2 29.2.3 16.8-13.4 30.5-30.3 30.3z"/>
                    <path d="m47 50.9-7-10.8c-1.1-1.8-3.4-2.3-5.2-1.2-1.1.7-1.8 1.9-1.8 3.2 0 .7.2 1.4.6 2l4.7 7.4c.4.6.2 1.3-.1 1.8l-7.4 8.1c-1.4 1.5-1.3 3.9.2 5.3.7.6 1.7.9 2.6.9 1.1 0 2-.5 2.7-1.2l5.5-6.4c.5-.5 1.2-.5 1.5.1l3.9 5.6c.2.5.6.8 1.1 1.1 1.3.9 3 .9 4.3.1 1.1-.7 1.8-1.9 1.8-3.2 0-.7-.2-1.4-.6-2z"/>
                </g>
            </svg>
            """
        try! SVGShape(string: svgString)
    }
}

#Preview {
    VStack {
        let svgString
            = """
                <svg xmlns="http://www.w3.org/2000/svg" enable-background="new 0 0 85 95" viewBox="0 0 85 95">
                  <g fill="#102954">
                    <path
                      d="m79.9 31.8c2.6-6.3 2.6-19.1-.8-28.9-.9-1.8-3.6-1.2-3.7.7v.7c-.6 9.4-4 14.5-9.1 17-.8.4-2.1.4-3-.2-6-3.8-13.2-6-20.9-6s-14.8 2.3-20.9 6c-.8.5-1.8.6-2.6.2-5.2-1.9-8.8-7.6-9.4-17.1v-.7c0-1.9-2.8-2.5-3.6-.7-3.4 10-3.3 22.8-.8 29 1.3 3.1 1.3 6.6.2 9.8-1.4 4-2.1 8.5-2 13 .5 20.6 18 38.2 38.7 38.5 21.8.4 39.5-17.1 39.5-39 0-4.4-.7-8.5-2-12.4-1-3.2-.9-6.8.4-9.9zm-38 52.1c-15.8-.4-28.9-13.3-29.1-29.2-.4-16.9 13.4-30.7 30.2-30.3 15.9.2 28.9 13.3 29.2 29.2.3 16.8-13.4 30.5-30.3 30.3z" />
                    <circle cx="42.73" cy="53.95" r="28" />
                  </g>
                </svg>
            """
        try! SVGShape(string: svgString)
    }
}

#Preview {
    VStack {
        let svgString
            = """
                <svg viewBox='0 0 102 102' xmlns='http://www.w3.org/2000/svg'>
                  <path d='M24,58a28,28,0,1,1,55,0l21,4a50,50,0,1,0-97,1z' fill='#17b'/>
                  <path d='M92,81c-24,3-44,10-56,18c5,2,10,3,15,3c17,0,32-8,41-21M95,76l3-7h-17c-29,0-55,5-69,13c3,4,6,8,10,10c15-9,42-16,73-16M71,62c10,0,20,1,28,4l1-4c-12-4-29-7-48-7c-20,0-37,3-49,8l3,10c15-7,40-12,65-11' fill='#d33'/>
                </svg>
            """
        try! SVGShape(string: svgString)
    }
}
