import QtQuick 2.7
import QtQuick.Shapes 1.0

Shape {
    id: e1
    vendorExtensionsEnabled: false
    width: 32
    height: 32
    visible: true
    property color color : Qt.rgba(1,0,1,1.0)

    transform: Scale {
        origin.y: e1.height * 0.5
        yScale: -1
    }

    ShapePath {
        id: c_sp1
        strokeWidth: -1
        fillColor: color

        property real half: e1.width * 0.5
        property real quarter: e1.width * 0.25
        property point center: Qt.point(e1.x + e1.width * 0.5 , e1.y + e1.height * 0.5)


        property point top: Qt.point(center.x, center.y - half )
        property point bottomLeft: Qt.point(center.x - half, center.y + half )
        property point bottomRight: Qt.point(center.x + half, center.y + half )

        startX: center.x;
        startY: center.y + half

        PathLine { x: c_sp1.bottomLeft.x; y: c_sp1.bottomLeft.y }
        PathLine { x: c_sp1.top.x; y: c_sp1.top.y }
        PathLine { x: c_sp1.bottomRight.x; y: c_sp1.bottomRight.y }
        PathLine { x: c_sp1.center.x; y: c_sp1.center.y + c_sp1.half }
    }
}
