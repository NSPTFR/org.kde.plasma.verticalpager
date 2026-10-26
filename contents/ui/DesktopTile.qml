/*
    SPDX-FileCopyrightText: 2026 Nicolas POELAERT <claude@nspt.fr>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager

// A miniature of one virtual desktop, with outlines of its windows
Item {
    id: tile

    required property var desktopId
    required property int number
    required property string desktopName
    required property bool current
    required property string activity
    required property rect screenGeometry

    signal activated()

    readonly property int displayedText: Plasmoid.configuration.displayedText
    readonly property real windowScale: screenGeometry.width > 0 ? width / screenGeometry.width : 0

    function windowTitles() {
        const titles = [];
        for (let i = 0; i < windows.count; ++i) {
            titles.push("• " + windows.data(windows.index(i, 0), Qt.DisplayRole));
        }
        return titles.length > 0 ? titles.join("\n") : i18n("No windows");
    }

    TaskManager.TasksModel {
        id: windows
        filterByVirtualDesktop: true
        virtualDesktop: tile.desktopId
        filterByActivity: true
        activity: tile.activity
        filterByScreen: true
        screenGeometry: tile.screenGeometry
        filterMinimized: true
        groupMode: TaskManager.TasksModel.GroupDisabled
    }

    Rectangle {
        anchors.fill: parent
        radius: Kirigami.Units.cornerRadius
        color: tile.current ? Qt.alpha(Kirigami.Theme.highlightColor, 0.3)
             : mouseArea.containsMouse ? Qt.alpha(Kirigami.Theme.textColor, 0.15)
             : Qt.alpha(Kirigami.Theme.textColor, 0.05)
        border.width: tile.current ? 2 : 1
        border.color: tile.current ? Kirigami.Theme.highlightColor : Qt.alpha(Kirigami.Theme.textColor, 0.3)

        Behavior on color {
            ColorAnimation { duration: Kirigami.Units.shortDuration }
        }
    }

    Item {
        anchors.fill: parent
        anchors.margins: 1
        clip: true
        visible: Plasmoid.configuration.showWindowOutlines

        Repeater {
            model: windows

            delegate: Rectangle {
                id: windowOutline

                required property var model
                readonly property rect geometry: model.Geometry

                x: Math.round((geometry.x - tile.screenGeometry.x) * tile.windowScale)
                y: Math.round((geometry.y - tile.screenGeometry.y) * tile.windowScale)
                width: Math.max(2, Math.round(geometry.width * tile.windowScale))
                height: Math.max(2, Math.round(geometry.height * tile.windowScale))
                // Topmost windows are drawn last
                z: model.StackingOrder
                visible: !model.SkipPager

                radius: 2
                color: model.IsActive ? Qt.alpha(Kirigami.Theme.highlightColor, 0.5)
                                      : Qt.alpha(Kirigami.Theme.backgroundColor, 0.8)
                border.width: 1
                border.color: model.IsActive ? Kirigami.Theme.highlightColor : Qt.alpha(Kirigami.Theme.textColor, 0.5)

                Kirigami.Icon {
                    readonly property int size: Math.min(Kirigami.Units.iconSizes.medium,
                                                         Math.floor(Math.min(parent.width, parent.height) * 0.6))
                    anchors.centerIn: parent
                    width: size
                    height: size
                    visible: Plasmoid.configuration.showWindowIcons && size >= 8
                    source: windowOutline.model.decoration
                    active: false
                }
            }
        }
    }

    PlasmaComponents.Label {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        visible: tile.displayedText !== 2
        text: tile.displayedText === 1 ? tile.desktopName : tile.number
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        fontSizeMode: Text.Fit
        minimumPixelSize: 6
        font.pixelSize: Math.max(8, Math.min(height, Kirigami.Units.gridUnit * 1.5))
        font.bold: tile.current
        elide: Text.ElideRight
        // Stay readable above window outlines
        style: Text.Outline
        styleColor: Qt.alpha(Kirigami.Theme.backgroundColor, 0.7)
    }

    PlasmaCore.ToolTipArea {
        anchors.fill: parent
        mainText: tile.desktopName
        subText: containsMouse ? tile.windowTitles() : ""

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: tile.activated()
        }
    }
}
