/****************************************************************************
**
** Copyright (C) 2016 The Qt Company Ltd.
** Contact: http://www.qt.io/licensing/
**
** This file is part of the examples of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:BSD$
** You may use this file under the terms of the BSD license as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of The Qt Company Ltd nor the names of its
**     contributors may be used to endorse or promote products derived
**     from this software without specific prior written permission.
**
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
**
** $QT_END_LICENSE$
**
****************************************************************************/

import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.3
import QtLocation 5.12
import QtPositioning 5.5
import FPSText 1.0

ApplicationWindow {
    id: appWindow
    visible: true
    height: 800
    width: 800
    property var map;
    property var routeModel;
    property var route: undefined

    menuBar: mainMenu
    property int dumpPathRequester: 0

    property var vecBrewer12 : [
                    Qt.rgba( 141.0 / 255.0, 211.0 / 255.0, 199.0 / 255.0, 255.0 / 255.0),
                    Qt.rgba( 255.0 / 255.0, 255.0 / 255.0, 179.0 / 255.0, 255.0 / 255.0),
                    Qt.rgba( 190.0 / 255.0, 186.0 / 255.0, 218.0 / 255.0 , 255.0 / 255.0),
                    Qt.rgba( 251.0 / 255.0, 128.0 / 255.0, 114.0 / 255.0 , 255.0 / 255.0),
                    Qt.rgba( 128.0 / 255.0, 177.0 / 255.0, 211.0 / 255.0 , 255.0 / 255.0),
                    Qt.rgba( 253.0 / 255.0, 180.0 / 255.0, 98.0 / 255.0 , 255.0 / 255.0),
                    Qt.rgba( 179.0 / 255.0, 222.0 / 255.0, 105.0 / 255.0 , 255.0 / 255.0),
                    Qt.rgba( 252.0 / 255.0, 205.0 / 255.0, 229.0 / 255.0 , 255.0 / 255.0),
                    Qt.rgba( 217.0 / 255.0, 217.0 / 255.0, 217.0 / 255.0 , 255.0 / 255.0),
                    Qt.rgba( 188.0 / 255.0, 128.0 / 255.0, 189.0 / 255.0 , 255.0 / 255.0),
                    Qt.rgba( 204.0 / 255.0, 235.0 / 255.0, 197.0 / 255.0 , 255.0 / 255.0),
                    Qt.rgba( 255.0 / 255.0, 237.0 / 255.0, 111.0 / 255.0 , 255.0 / 255.0) ]


    FPSText{
        id: fps_text
        timeWindow: 350
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: 64
        height: 32
        z: 300
        Text {
            anchors.centerIn: parent
            text: fps_text.fps.toFixed(2)
        }
    }

    ExclusiveGroup {
        id: routingModeGroup

        Action {
            id: carRoutingAction
            text: "Car"
            checkable: true
            checked: true
            onTriggered: map.updateRoute()
        }

        Action {
            id: pedestrianRoutingAction
            text: "Pedestrian"
            checkable: true
            onTriggered: map.updateRoute()
        }
    }

    MenuBar {
        id: mainMenu

        Menu {
            title: "Map Provider"
            id : mapMenu
        }

        Menu {
            title: "Routing Provider"
            id : routingMenu
        }

        Menu {
            title: "Routing Mode"
            id : routingModeMenu
            MenuItem {
                action: carRoutingAction
            }
            MenuItem {
                action: pedestrianRoutingAction
            }
        }

        Menu {
            title: "Options"
            id: optionsMenu
            MenuItem {
                text: "Dump Info"
                onTriggered: appWindow.dumpPathRequester = appWindow.dumpPathRequester + 1
            }
            MenuItem {
                id: showSegs
                text: "Show Segments"
                checkable: true
                checked: false
                onToggled: {

                }
            }
        }
    }

    Item {
        id : mainContainer
        anchors.fill: parent

        SplitView {
            anchors.fill: parent
            resizing: true
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                id: mapContainer

                Button {
                    id: instructionPanelToggler
                    z : mapContainer.z + 1
                    width: 48
                    height: 96
                    checkable: true
                    checked: true
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    style: ButtonStyle {
                        background: BorderImage {
                            source: instructionPanelToggler.checked ? "qrc:///close.png" : "qrc:///open.png"
                        }
                    }
                }
            }

            Rectangle {
                color: 'plum'
                opacity: 0.3
                visible: instructionPanelToggler.checked
                id: instructionsContainer
                Layout.preferredWidth: 350
                Layout.minimumWidth: 250
                Layout.fillWidth: true
                Layout.fillHeight: true

                Text {
                    id : instructionTitle
                    anchors.bottom: parent.bottom
                    text: parent.width + 'x' + parent.height
                }

                ListView {
                    id: routeDirections
                    interactive: true
                    model: routeInfoModel
                    anchors.fill: parent

                    delegate:  Text {
                        text: (type === "header") ? header : index + ": " +instruction + " (" + distance + ")"
                    }
                }
                Rectangle {
                    id: scrollbar
                    anchors.right: routeDirections.right
                    y: routeDirections.visibleArea.yPosition * routeDirections.height
                    width: 10
                    height: routeDirections.visibleArea.heightRatio * routeDirections.height
                    color: "black"
                }
            }
        }
    }

    PluginManager { id: pluginManager }

    Component.onCompleted: {
        // Do not access plugins here, first access has to be made by initializePluginParameters
    }

    function initializePluginParameters(pluginParameters)
    {
        var parameters = new Array()
        for (var prop in pluginParameters){
            var parameter = Qt.createQmlObject('import QtLocation 5.6; PluginParameter{ name: "'+ prop + '"; value: "' + pluginParameters[prop]+'"}',appWindow)
            parameters.push(parameter)
        }
//        var pogl = Qt.createQmlObject('import QtLocation 5.6; PluginParameter{ name: "mapboxgl.mapping.use_fbo"; value: false}',appWindow)
//        parameters.push(pogl)

        pluginManager.setPluginParameters(parameters)
        pluginManager.populateRoutingMenu(appWindow, routingMenu, mapComponent)
        pluginManager.populateMapMenu(appWindow, mapMenu, mapComponent)
    }

    function updateMenuCheckboxes(pluginName, mapTypeName)
    {
        for (var i = 0; i < mapMenu.items.length; i++)
            for (var j = 0; j < mapMenu.items[i].items.length; j++)
                mapMenu.items[i].items[j].checked = (mapMenu.items[i].title === pluginName
                                                     && mapMenu.items[i].items[j].text === mapTypeName)
    }

    function createMap(plugin, mapTypeName) {
        var zl = 5.5;
        var center = QtPositioning.coordinate(55.5, 11.5)//(50.849019, 4.352350)
        var availableMapTypes;
        if (map) {
            zl = map.zoomLevel
            center = map.center
            if (map.plugin.name !== plugin.name) {
                map.destroy()
            } else {
                availableMapTypes = map.supportedMapTypes
                for (var i = 0; i< availableMapTypes.length; i++)
                    if (availableMapTypes[i].name === mapTypeName) {
                        map.activeMapType = availableMapTypes[i]
                        break;
                    }
                map.forceActiveFocus()
                updateMenuCheckboxes(plugin.name, mapTypeName)
                return
            }
        }

        map = mapComponent.createObject(mapContainer)
        map.plugin = plugin;
        availableMapTypes = map.supportedMapTypes
        for (var i = 0; i< availableMapTypes.length; i++)
            if (availableMapTypes[i].name === mapTypeName) {
                map.activeMapType = availableMapTypes[i]
                break;
            }
        map.zoomLevel = zl
        map.center = center
        map.forceActiveFocus()
        updateMenuCheckboxes(plugin.name, mapTypeName)
    }

    function createRouteModel() {
        routeModel = routeModelComponent.createObject(appWindow)
    }

    Component {
        MapQuickItem {
            id: middleMarker
            sourceItem: Image {
                id: greenMarker
                source: "qrc:///grayMarker.png"
            }
            coordinate : QtPositioning.coordinate(52.43205,13.5334313)
            visible: true
            opacity: 1.0
            anchorPoint.x: greenMarker.width/2
            anchorPoint.y: greenMarker.height
            MouseArea  {
                id: endMarkerMouseArea
                drag.target: parent
                anchors.fill: parent
            }

            onCoordinateChanged: {
                updateRoute()
            }
        }
    }

    ListModel {
        id: middleMarkerModel
        onRowsInserted: dataHasChanged()
        onRowsRemoved: dataHasChanged()

        ListElement { // TQtC Berlin, Rudower Chaussee
            latitude: 52.43205
            longitude: 13.5334313
        }

        function dataHasChanged() {
            console.log("middleMarkerModel data changed")
            map.updateRoute()
        }
    }

    Component {
        id: mapComponent

        Map {
            id: mapElement
            width: mapContainer.width
            height: mapContainer.height

            function updateRoute() {
                console.log("updateRoute()")
                var startCrd = startMarker.coordinate
                var endCrd = endMarker.coordinate
                routeQuery.clearWaypoints()
                routeQuery.travelModes = ((carRoutingAction.checked) ? RouteQuery.CarTravel : RouteQuery.PedestrianTravel)
                routeQuery.addWaypoint(startCrd)
                for (var i = 0; i < middleMarkerModel.count; i++) {
                    var modelData = middleMarkerModel.get(i)
                    routeQuery.addWaypoint(QtPositioning.coordinate(modelData.latitude, modelData.longitude))
                }
                routeQuery.addWaypoint(endCrd)
                debugRouteQuery(routeQuery)
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton
                onDoubleClicked: {
                    var crd = mapElement.toCoordinate(Qt.point(mouseX, mouseY))
                    middleMarkerModel.append({ latitude: crd.latitude, longitude: crd.longitude})
                }
            }

            MapQuickItem {
                id: startMarker
                sourceItem: Image {
                    id: redMarker
                    source: "qrc:///redMarker.png"
                }
                coordinate : QtPositioning.coordinate(59.9485, 10.7686)
                visible: true
                opacity: 1.0
                anchorPoint.x: redMarker.width/2
                anchorPoint.y: redMarker.height
                MouseArea  {
                    id: startMarkerMouseArea
                    drag.target: parent
                    anchors.fill: parent
                }

                onCoordinateChanged: {
                    updateRoute()
                }
            }

            MapQuickItem {
                id: endMarker
                sourceItem: Image {
                    id: greenMarker
                    source: "qrc:///greenMarker.png"
                }
                coordinate : QtPositioning.coordinate(51.34335, 12.37949) // Leipzig Richard Wagner Strasse
                visible: true
                opacity: 1.0
                anchorPoint.x: greenMarker.width/2
                anchorPoint.y: greenMarker.height
                MouseArea  {
                    id: endMarkerMouseArea
                    drag.target: parent
                    anchors.fill: parent
                }

                onCoordinateChanged: {
                    updateRoute()
                }
            }

            MouseArea {
                id: mapMouseArea

                onClicked: {
                    //console.log("pos: " + map.toCoordinate(Qt.point(mouse.x, mouse.y)))
                }
            }

            MapItemView {
                id: middleMarkerView
                model: middleMarkerModel
                delegate: MapQuickItem {
                    id: midMarker
                    sourceItem: Image {
                        id: grayMarker
                        source: "qrc:///grayMarker.png"
                    }
                    coordinate : QtPositioning.coordinate(latitude, longitude)
                    anchorPoint.x: grayMarker.width/2
                    anchorPoint.y: grayMarker.height
                    MouseArea  {
                        id: middleMarkerMouseArea
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        anchors.fill: parent
                        onDoubleClicked: {
                            if (mouse.button & Qt.RightButton)
                                return
                            middleMarkerModel.remove(index)
                        }
                    }
                }
            }

//            MapItemView {
//                id: routeView
//                model: routeModel
//                delegate: Component {
//                    MapRoute {
//                        route: routeData
//                        line.color: 'blue'
//                        line.width: 7
//                        property int dumpPathRequester: appWindow.dumpPathRequester
////                        opacity: (index === 0) ? 1.0 : 0.3

//                        onDumpPathRequesterChanged: {
//                            if (index === 0) {
//                                dumpPath(path)
//                            }
//                        }

////                        onRouteChanged: {
////                            dumpPath(path)
////                        }
//                    }
//                }
//            }


            MapItemView {
                id: routeSegmentsView
                model: routeModel
                visible: showSegs.checked
                delegate: Component {
                    MapItemView {
                        id: segsView
                        property var route: routeData
                        model: route.segments
                        Component.onCompleted: {
                            console.log(route)
                            console.log(route.distance)
                            console.log(route.segments)
                        }
                        delegate: MapPolyline {
                            path: modelData.path
                            line.color: vecBrewer12[index % 12 ]
                            line.width: 7
                        }
                    }
                }
            }

            MapItemView {
                id: routeView
                visible: !showSegs.checked
                model: routeModel
                delegate: Component {
                    MapItemView {
                        id: legView
                        property var route: routeData
                        model: route.legs
                        Component.onCompleted: {
                            console.log(route)
                            console.log(route.distance)
                            console.log(route.legs)
                        }

                        delegate: MapRoute {
                            Component.onCompleted: {
                                console.log(modelData)
                            }

                            route: modelData
                            //line.color: 'blue'
                            line.color: vecBrewer12[index % 12 ]
                            line.width: 7
                            property int dumpPathRequester: appWindow.dumpPathRequester
//                            opacity: (index === 0) ? 1.0 : 0.3

                            onDumpPathRequesterChanged: {
                                if (index === 0) {
                                    dumpPath(path)
                                }
                            }
                        }
                    }
                }
            }

        }
    }

    property var foobar: [1,2,3]

    function dumpPath(p) {
        console.log("==== WAYPOINTS ====")
        for (var i= 0; i < routeQuery.waypoints.length; i++) {
            var c = routeQuery.waypoints[i]
            console.log("QtPositioning.coordinate(" + c.latitude + " , "  + c.longitude + ")")
        }

        console.log("==== PATH ====")
        for (var i = 0; i < p.length; i++) {
            var c = p[i]
            console.log("QtPositioning.coordinate(" + c.latitude + " , "  + c.longitude + ")")
        }
    }

    Component {
        id: routeModelComponent
        RouteModel {
            id: rModel
            autoUpdate: true
            query: routeQuery
            Component.onCompleted: {
                rModel.routesChanged.connect(routeInfoModel.updateRoute)
                if (map)
                    map.updateRoute()
            }
            onModelReset: {
                route = get(0)
                console.log("ROUTES: ",rModel.count)
            }
        }
    }

    RouteQuery {
        id: routeQuery
        numberAlternativeRoutes: 0
    }

    function formatTime(sec)
    {
        var value = sec
        var seconds = value % 60
        value /= 60
        value = (value > 1) ? Math.round(value) : 0
        var minutes = value % 60
        value /= 60
        value = (value > 1) ? Math.round(value) : 0
        var hours = value
        if (hours > 0) value = hours + "h:"+ minutes + "m"
        else value = minutes + "min"
        return value
    }

    function formatDistance(meters)
    {
        var dist = Math.round(meters)
        if (dist > 1000 ){
            if (dist > 100000){
                dist = Math.round(dist / 1000)
            }
            else{
                dist = Math.round(dist / 100)
                dist = dist / 10
            }
            dist = dist + " km"
        }
        else{
            dist = dist + " m"
        }
        return dist
    }

    function debugRouteQuery(q) {
        console.log(q)
        console.log("QUERY WAYPOINTS")
        var wpts = q.waypoints
        for (var i = 0; i < wpts.length; i++)
            console.log(wpts[i])
    }

    ListModel {
        id: routeInfoModel
        property string totalTravelTime
        property string totalDistance

        function updateRoute()  {
            routeInfoModel.clear()
            if (routeModel.count > 0) {
                var currentTime = new Date();
                var route = routeModel.get(0)
                var legs = route.legs
                if (!legs.length) {
                    routeInfoModel.append({
                        "type" : "header",
                        "header": "\n=== FULL ROUTE ===\n"
                    });
                    for (var i = 0; i < route.segments.length; i++) {
                        routeInfoModel.append({
                            "type" : "instruction",
                            "instruction": routeModel.get(0).segments[i].maneuver.instructionText,
                            "distance": formatDistance(routeModel.get(0).segments[i].maneuver.distanceToNextInstruction)
                        });

                        var keys = route.segments[i].maneuver.extendedAttributes.keys()
                        //var keys = Object.keys(routeModel.get(0).segments[i].maneuver.extendedAttributes)
                        for (var j = 0; j< keys.length; j++)
                            console.log(keys[j], route.segments[i].maneuver.extendedAttributes[keys[j]])
                    }
                    var afterTime = new Date();
                    console.log("== DURATION: ", (afterTime - currentTime) / 1000);
                } else {
                    debugRouteQuery(route.routeQuery)
                    for (var j = 0; j < legs.length; j++) {
                        var leg = legs[j]
                        routeInfoModel.append({
                            "type" : "header",
                            "header": "\n=== LEG "+ leg.legIndex +" ===\n"
                        });
                        for (var i = 0; i < leg.segments.length; i++) {
                            routeInfoModel.append({
                                "type" : "instruction",
                                "instruction": leg.segments[i].maneuver.instructionText,
                                "distance": formatDistance(leg.segments[i].maneuver.distanceToNextInstruction)
                            });
                        }
                    }
                }
            }
            totalTravelTime = routeModel.count === 0 ? "" : formatTime(routeModel.get(0).travelTime)
            totalDistance = routeModel.count === 0 ? "" : formatDistance(routeModel.get(0).distance)
        }
    }
}
