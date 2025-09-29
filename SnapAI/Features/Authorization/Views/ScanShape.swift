//
//  ScanShape.swift
//  SnapAI
//
//  Created by Isa Melsov on 24/9/25.
//

import SwiftUI

struct MyIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.size.width
        let height = rect.size.height
        path.move(to: CGPoint(x: 0.04368*width, y: 0.8957*height))
        path.addCurve(to: CGPoint(x: 0.09989*width, y: 0.95192*height), control1: CGPoint(x: 0.04368*width, y: 0.92674*height), control2: CGPoint(x: 0.06885*width, y: 0.95191*height))
        path.addLine(to: CGPoint(x: 0.13016*width, y: 0.95192*height))
        path.addCurve(to: CGPoint(x: 0.15178*width, y: 0.97354*height), control1: CGPoint(x: 0.1421*width, y: 0.95192*height), control2: CGPoint(x: 0.15178*width, y: 0.96159*height))
        path.addCurve(to: CGPoint(x: 0.13016*width, y: 0.99516*height), control1: CGPoint(x: 0.15178*width, y: 0.98547*height), control2: CGPoint(x: 0.1421*width, y: 0.99516*height))
        path.addLine(to: CGPoint(x: 0.09989*width, y: 0.99516*height))
        path.addCurve(to: CGPoint(x: 0.00044*width, y: 0.8957*height), control1: CGPoint(x: 0.04497*width, y: 0.99515*height), control2: CGPoint(x: 0.00044*width, y: 0.95062*height))
        path.addLine(to: CGPoint(x: 0.00044*width, y: 0.86544*height))
        path.addCurve(to: CGPoint(x: 0.02206*width, y: 0.84382*height), control1: CGPoint(x: 0.00044*width, y: 0.85349*height), control2: CGPoint(x: 0.01012*width, y: 0.84382*height))
        path.addCurve(to: CGPoint(x: 0.04368*width, y: 0.86544*height), control1: CGPoint(x: 0.034*width, y: 0.84382*height), control2: CGPoint(x: 0.04368*width, y: 0.85349*height))
        path.addLine(to: CGPoint(x: 0.04368*width, y: 0.8957*height))
        path.closeSubpath()
        path.move(to: CGPoint(x: 0.99494*width, y: 0.8957*height))
        path.addCurve(to: CGPoint(x: 0.89549*width, y: 0.99516*height), control1: CGPoint(x: 0.99494*width, y: 0.95062*height), control2: CGPoint(x: 0.95042*width, y: 0.99516*height))
        path.addLine(to: CGPoint(x: 0.86523*width, y: 0.99516*height))
        path.addCurve(to: CGPoint(x: 0.84361*width, y: 0.97354*height), control1: CGPoint(x: 0.85329*width, y: 0.99516*height), control2: CGPoint(x: 0.84361*width, y: 0.98547*height))
        path.addCurve(to: CGPoint(x: 0.86523*width, y: 0.95192*height), control1: CGPoint(x: 0.84361*width, y: 0.96159*height), control2: CGPoint(x: 0.85329*width, y: 0.95192*height))
        path.addLine(to: CGPoint(x: 0.89549*width, y: 0.95192*height))
        path.addCurve(to: CGPoint(x: 0.95171*width, y: 0.8957*height), control1: CGPoint(x: 0.92654*width, y: 0.95192*height), control2: CGPoint(x: 0.95171*width, y: 0.92675*height))
        path.addLine(to: CGPoint(x: 0.95171*width, y: 0.86544*height))
        path.addCurve(to: CGPoint(x: 0.97332*width, y: 0.84382*height), control1: CGPoint(x: 0.95171*width, y: 0.85349*height), control2: CGPoint(x: 0.96139*width, y: 0.84382*height))
        path.addCurve(to: CGPoint(x: 0.99494*width, y: 0.86544*height), control1: CGPoint(x: 0.98527*width, y: 0.84382*height), control2: CGPoint(x: 0.99494*width, y: 0.85349*height))
        path.addLine(to: CGPoint(x: 0.99494*width, y: 0.8957*height))
        path.closeSubpath()
        path.move(to: CGPoint(x: 0.15178*width, y: 0.02227*height))
        path.addCurve(to: CGPoint(x: 0.13016*width, y: 0.04388*height), control1: CGPoint(x: 0.15178*width, y: 0.0342*height), control2: CGPoint(x: 0.1421*width, y: 0.04388*height))
        path.addLine(to: CGPoint(x: 0.09989*width, y: 0.04388*height))
        path.addCurve(to: CGPoint(x: 0.04368*width, y: 0.1001*height), control1: CGPoint(x: 0.06885*width, y: 0.04388*height), control2: CGPoint(x: 0.04368*width, y: 0.06905*height))
        path.addLine(to: CGPoint(x: 0.04368*width, y: 0.13037*height))
        path.addCurve(to: CGPoint(x: 0.02206*width, y: 0.15199*height), control1: CGPoint(x: 0.04368*width, y: 0.14231*height), control2: CGPoint(x: 0.034*width, y: 0.15199*height))
        path.addCurve(to: CGPoint(x: 0.00044*width, y: 0.13037*height), control1: CGPoint(x: 0.01012*width, y: 0.15199*height), control2: CGPoint(x: 0.00044*width, y: 0.14231*height))
        path.addLine(to: CGPoint(x: 0.00044*width, y: 0.1001*height))
        path.addCurve(to: CGPoint(x: 0.09989*width, y: 0.00065*height), control1: CGPoint(x: 0.00044*width, y: 0.04517*height), control2: CGPoint(x: 0.04497*width, y: 0.00065*height))
        path.addLine(to: CGPoint(x: 0.13016*width, y: 0.00065*height))
        path.addCurve(to: CGPoint(x: 0.15178*width, y: 0.02227*height), control1: CGPoint(x: 0.1421*width, y: 0.00065*height), control2: CGPoint(x: 0.15178*width, y: 0.01033*height))
        path.closeSubpath()
        path.move(to: CGPoint(x: 0.89549*width, y: 0.00065*height))
        path.addCurve(to: CGPoint(x: 0.99494*width, y: 0.1001*height), control1: CGPoint(x: 0.95042*width, y: 0.00065*height), control2: CGPoint(x: 0.99494*width, y: 0.04517*height))
        path.addLine(to: CGPoint(x: 0.99494*width, y: 0.13037*height))
        path.addCurve(to: CGPoint(x: 0.97332*width, y: 0.15199*height), control1: CGPoint(x: 0.99494*width, y: 0.14231*height), control2: CGPoint(x: 0.98527*width, y: 0.15199*height))
        path.addCurve(to: CGPoint(x: 0.95171*width, y: 0.13037*height), control1: CGPoint(x: 0.96139*width, y: 0.15199*height), control2: CGPoint(x: 0.95171*width, y: 0.14231*height))
        path.addLine(to: CGPoint(x: 0.95171*width, y: 0.1001*height))
        path.addCurve(to: CGPoint(x: 0.89549*width, y: 0.04388*height), control1: CGPoint(x: 0.95171*width, y: 0.06905*height), control2: CGPoint(x: 0.92654*width, y: 0.04388*height))
        path.addLine(to: CGPoint(x: 0.86523*width, y: 0.04388*height))
        path.addCurve(to: CGPoint(x: 0.84361*width, y: 0.02227*height), control1: CGPoint(x: 0.85329*width, y: 0.04388*height), control2: CGPoint(x: 0.84361*width, y: 0.0342*height))
        path.addCurve(to: CGPoint(x: 0.86523*width, y: 0.00065*height), control1: CGPoint(x: 0.84361*width, y: 0.01033*height), control2: CGPoint(x: 0.85329*width, y: 0.00065*height))
        path.addLine(to: CGPoint(x: 0.89549*width, y: 0.00065*height))
        path.closeSubpath()
        return path
    }
}
