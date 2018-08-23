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
import QtLocation 5.6
import QtPositioning 5.5

Item {
    id: manager

    // these properties are for caching purposes
    property var pluginNames : {}
    property var geoservicePlugins : {}
    property var geoservicePluginsDict : {}
    property var mappingPluginsDict : {}
    property var routingPluginsDict : {}
    property var dummyMapsDict : { "invalid" : undefined }
    property var pluginParameters

    function availablePluginNames()
    {
        if (typeof manager.pluginArray === "undefined") {
            // Initializing the plugin Array
            var plugin = Qt.createQmlObject ('import QtLocation 5.6; Plugin {}', manager)
            var arr = new Array()
            var allowed = ["osm","mapbox","here","esri","mapboxgl","openaccess"]
            for (var i = 0; i<plugin.availableServiceProviders.length; i++) {
                if (allowed.indexOf(plugin.availableServiceProviders[i]) >= 0 ) {
                    var tempPlugin
                    tempPlugin = Qt.createQmlObject ('import QtLocation 5.6; Plugin {name: "' + plugin.availableServiceProviders[i]+ '"}', manager)
                    if (tempPlugin.supportsMapping())
                        arr.push(tempPlugin.name)
                }
            }
            arr.sort()
            manager.pluginNames = arr;
            return arr
        } else  {
            return manager.pluginNames
        }
    }

    function setPluginParameters(pluginParams) {
        if (! manager.pluginParameters) {
            manager.pluginParameters = pluginParams
            updatePlugins()
        }
    }

    function getPlugins() {
        if (typeof manager.geoservicePlugins === "undefined") {
            updatePlugins()
        }
        return manager.geoservicePlugins
    }
    function getPluginsDict() {
        if (typeof manager.geoservicePlugins === "undefined") {
            updatePlugins()
        }
        return manager.geoservicePluginsDict
    }

    function getRoutingPlugins() {
        if (!manager.routingPluginsDict)
            updatePlugins()
        return manager.routingPluginsDict
    }

    function getMappingPlugins() {
        if (!manager.mappingPluginsDict)
            updatePlugins()
        return manager.mappingPluginsDict
    }

    function updatePlugins()
    {
        // Does this require to explicitly destroy current plugins?
        manager.geoservicePlugins = new Array()
        manager.geoservicePluginsDict = new Object()
        manager.mappingPluginsDict = new Object()
        manager.routingPluginsDict = new Object()

        var plugin_names = availablePluginNames()
        for (var i = 0; i < plugin_names.length; i++) {
            var plugin
            if (manager.pluginParameters && manager.pluginParameters.length > 0)
                plugin = Qt.createQmlObject ('import QtLocation 5.6; Plugin{ name:"' + plugin_names[i] + '"; parameters: manager.pluginParameters}', manager)
            else
                plugin = Qt.createQmlObject ('import QtLocation 5.6; Plugin{ name:"' + plugin_names[i] + '"}', manager)

            manager.geoservicePlugins.push(plugin)
            manager.geoservicePluginsDict[plugin_names[i]] = plugin

            if (plugin.supportsMapping(Plugin.AnyMappingFeatures))
                manager.mappingPluginsDict[plugin_names[i]] = plugin

            if (plugin.supportsRouting(Plugin.AnyRoutingFeatures))
                manager.routingPluginsDict[plugin_names[i]] = plugin
        }
    }

    function initializeDummyMaps(appWindow, mapMenu,  mapComponent)
    {
        var plugin_dict = getMappingPlugins();

        for (var key in plugin_dict) {
            if ( !(key in manager.dummyMapsDict)) {
                var dummyMap = Qt.createQmlObject ('import QtLocation 5.6; Map { visible: false }', manager)
                dummyMap.plugin = plugin_dict[key]
                dummyMapsDict[key] = dummyMap

                dummyMap.supportedMapTypesChanged.connect( ( function(appWindow, mapMenu,  mapComponent) {
                    return function() {
                        try {
                            Qt.callLater(populateMapMenu, appWindow, mapMenu, mapComponent) // Available on 5.8+
                        }
                        catch(err) {
                            populateMapMenu(appWindow, mapMenu, mapComponent)
                        }
                };})(appWindow, mapMenu,  mapComponent)    )
            }
        }
    }

    function populateMapMenu(appWindow, mapMenu,  mapComponent)
    {
        var plugin_dict = getMappingPlugins();

        // clear menu
        mapMenu.clear()
        var created = (appWindow.map != undefined);
        initializeDummyMaps(appWindow, mapMenu,  mapComponent)

        for (var key in plugin_dict) {
            if (! (key in manager.dummyMapsDict))
                continue

            var dummyMap = dummyMapsDict[key]
            var available_map_types = dummyMap.supportedMapTypes
            if (available_map_types.length > 0) {
                if (!created) {
//                    if (key == "osm") {
//                        appWindow.createMap(plugin_dict[key], available_map_types[0].name)
//                        created = true
//                    }
                    appWindow.createMap(plugin_dict[key], available_map_types[0].name)
                    created = true
                }

                var providerMenu = mapMenu.addMenu(key)
                for (var j = 0; j < available_map_types.length; j++) {
                    var menuMapItem = providerMenu.addItem(available_map_types[j].name)
                    menuMapItem.checkable = true;
                    menuMapItem.checked = (created
                                           && (appWindow.map.plugin.name == key)
                                           && (appWindow.map.activeMapType.name == available_map_types[j].name))
                    menuMapItem.triggered.connect(  ( function(plugin, mapTypeName) {
                        return function() {
                            appWindow.createMap(plugin, mapTypeName)
                    };})(plugin_dict[key], available_map_types[j].name)    )
                }
            }
        }
    }

    function populateRoutingMenu(appWindow, routingMenu,  mapComponent)
    {
        if (!appWindow.routeModel)
            appWindow.createRouteModel()

        routingMenu.clear()
        var plugin_dict = getRoutingPlugins();
        var pluginSet = (appWindow.routeModel.plugin && (appWindow.routeModel.plugin != undefined))
        for (var key in plugin_dict) {
            var pluginItem = routingMenu.addItem(key)
            if (!pluginSet && (key == "mapbox")) {
                appWindow.routeModel.plugin = plugin_dict[key]
                pluginSet = true
            }

            pluginItem.checkable = true;
            pluginItem.checked = (pluginSet && (appWindow.routeModel.plugin.name == key))
            pluginItem.triggered.connect(  ( function(appWindow, plugin, routingMenu) {
                return function() {
                    appWindow.routeModel.plugin = plugin
                    appWindow.routeModel.update()
                    for (var i = 0; i <  routingMenu.items.length; i++) {
                        if (routingMenu.items[i].text == plugin.name)
                            routingMenu.items[i].checked = true
                        else
                            routingMenu.items[i].checked = false
                    }
            };})(appWindow, plugin_dict[key], routingMenu)    )
        }
    }
}
