/*
    SPDX-FileCopyrightText: 2026 Nicolas POELAERT <claude@nspt.fr>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.plasma.plasmoid

// The column (or row, in horizontal panels) of desktop tiles. Shared between the
// widget itself and the overlay surface shown above fullscreen windows.
Item {
    id: pager

    required property var pagerRoot
    required property real tileWidth
    required property real tileHeight
    required property int spacing

    Grid {
        anchors.centerIn: parent
        columns: pager.pagerRoot.horizontal ? pager.pagerRoot.count : 1
        spacing: pager.spacing

        Repeater {
            model: pager.pagerRoot.virtualDesktopInfo.desktopIds

            DesktopTile {
                required property var modelData
                required property int index

                width: pager.tileWidth
                height: pager.tileHeight
                desktopId: modelData
                number: index + 1
                desktopName: pager.pagerRoot.virtualDesktopInfo.desktopNames[index] ?? ""
                current: index === pager.pagerRoot.currentIndex
                activity: pager.pagerRoot.activityInfo.currentActivity
                screenGeometry: pager.pagerRoot.screenGeometry
                onActivated: pager.pagerRoot.activate(index)
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        enabled: Plasmoid.configuration.wheelEnabled

        property int wheelDelta: 0

        onWheel: wheel => {
            wheelDelta += wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x;
            while (wheelDelta >= 120) {
                wheelDelta -= 120;
                pager.pagerRoot.step(-1);
            }
            while (wheelDelta <= -120) {
                wheelDelta += 120;
                pager.pagerRoot.step(1);
            }
        }
    }
}
