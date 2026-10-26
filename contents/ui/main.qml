/*
    SPDX-FileCopyrightText: 2026 Nicolas POELAERT <claude@nspt.fr>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import org.kde.layershell as LayerShell
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.workspace.dbus as DBus
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager
import org.kde.kcmutils as KCM

PlasmoidItem {
    id: root

    readonly property bool horizontal: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
    // Sitting on the desktop rather than in a panel
    readonly property bool onDesktop: Plasmoid.formFactor === PlasmaCore.Types.Planar

    readonly property alias virtualDesktopInfo: virtualDesktopInfo
    readonly property alias activityInfo: activityInfo
    readonly property int count: Math.max(1, virtualDesktopInfo.numberOfDesktops)
    readonly property int currentIndex: virtualDesktopInfo.desktopIds.indexOf(virtualDesktopInfo.currentDesktop)

    // Geometry of the screen holding the widget: windows are drawn relative to it
    readonly property rect screenGeometry: Plasmoid.containment.screenGeometry
    readonly property real screenRatio: screenGeometry.width > 0 && screenGeometry.height > 0
                                        ? screenGeometry.height / screenGeometry.width : 9 / 16

    // Whether a fullscreen window is shown on the current desktop of this screen
    property bool fullScreenActive: false

    preferredRepresentation: fullRepresentation

    TaskManager.VirtualDesktopInfo {
        id: virtualDesktopInfo
    }

    TaskManager.ActivityInfo {
        id: activityInfo
    }

    // Look at every visible window rather than only the active one: after switching
    // desktops, a fullscreen window does not always get the focus back.
    TaskManager.TasksModel {
        id: screenTasks
        filterByScreen: true
        screenGeometry: root.screenGeometry
        filterByVirtualDesktop: true
        virtualDesktop: virtualDesktopInfo.currentDesktop
        filterByActivity: true
        activity: activityInfo.currentActivity
        filterMinimized: true
        groupMode: TaskManager.TasksModel.GroupDisabled

        function updateFullScreen() {
            let found = false;
            for (let i = 0; i < count && !found; ++i) {
                found = data(index(i, 0), TaskManager.AbstractTasksModel.IsFullScreen) === true;
            }
            root.fullScreenActive = found;
        }

        onCountChanged: updateFullScreen()
        onDataChanged: updateFullScreen()
        onModelReset: updateFullScreen()
    }

    function kwinCall(path, iface, member, args) {
        DBus.SessionBus.asyncCall({
            service: "org.kde.KWin",
            path: path,
            iface: iface,
            member: member,
            arguments: args,
        });
    }

    // VirtualDesktopInfo is read-only from QML, so desktops are driven through KWin's D-Bus API
    function activate(index) {
        if (index >= 0 && index < count && index !== currentIndex) {
            // KWin numbers desktops from 1
            kwinCall("/KWin", "org.kde.KWin", "setCurrentDesktop", [new DBus.int32(index + 1)]);
        }
    }

    function step(delta) {
        let next = currentIndex + delta;
        if (virtualDesktopInfo.navigationWrappingAround) {
            next = (next + count) % count;
        }
        activate(next);
    }

    function addDesktop() {
        kwinCall("/VirtualDesktopManager", "org.kde.KWin.VirtualDesktopManager", "createDesktop",
                 [new DBus.uint32(count), new DBus.string(i18n("Desktop %1", count + 1))]);
    }

    function removeLastDesktop() {
        const ids = virtualDesktopInfo.desktopIds;
        kwinCall("/VirtualDesktopManager", "org.kde.KWin.VirtualDesktopManager", "removeDesktop",
                 [new DBus.string(ids[ids.length - 1])]);
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Add Virtual Desktop")
            icon.name: "list-add"
            onTriggered: root.addDesktop()
        },
        PlasmaCore.Action {
            text: i18n("Remove Last Virtual Desktop")
            icon.name: "list-remove"
            enabled: virtualDesktopInfo.numberOfDesktops > 1
            onTriggered: root.removeLastDesktop()
        },
        PlasmaCore.Action {
            text: i18n("Configure Virtual Desktops…")
            icon.name: "preferences-desktop-virtual"
            onTriggered: KCM.KCMLauncher.openSystemSettings("kcm_kwin_virtualdesktops")
        }
    ]

    fullRepresentation: Item {
        id: full

        readonly property int spacing: Kirigami.Units.smallSpacing

        // Natural size of a tile, following the screen's aspect ratio
        readonly property real naturalTileWidth: root.horizontal ? height / root.screenRatio : width
        readonly property real naturalTileHeight: root.horizontal ? height : width * root.screenRatio
        readonly property real length: root.count * (root.horizontal ? naturalTileWidth : naturalTileHeight)
                                       + (root.count - 1) * spacing

        // On the desktop the user picks the size: shrink tiles so they all fit
        readonly property real tileHeight: root.horizontal ? height
            : Math.floor(Math.min(naturalTileHeight, (height - (root.count - 1) * spacing) / root.count))
        readonly property real tileWidth: root.horizontal ? Math.floor(naturalTileWidth)
            : Math.floor(tileHeight / root.screenRatio)

        Layout.fillWidth: !root.horizontal
        Layout.fillHeight: root.horizontal
        Layout.minimumWidth: root.horizontal ? length : Kirigami.Units.gridUnit
        Layout.preferredWidth: root.horizontal ? length : Kirigami.Units.gridUnit * 5
        Layout.maximumWidth: root.horizontal ? length : Infinity
        Layout.minimumHeight: root.horizontal ? Kirigami.Units.gridUnit : length
        Layout.preferredHeight: root.horizontal ? Kirigami.Units.gridUnit * 2 : length
        Layout.maximumHeight: root.horizontal ? Infinity : (root.onDesktop ? Infinity : length)

        Pager {
            anchors.fill: parent
            pagerRoot: root
            tileWidth: full.tileWidth
            tileHeight: full.tileHeight
            spacing: full.spacing
        }

        // Desktop widgets live below every window, including fullscreen ones. While a
        // fullscreen window is shown, a copy of the pager is put in a layer-shell surface
        // on the overlay layer, at the exact place the widget occupies on the desktop.
        readonly property bool keepAbove: root.onDesktop && Plasmoid.configuration.keepAboveFullScreen
                                          && root.fullScreenActive && width > 0 && height > 0

        onKeepAboveChanged: {
            if (keepAbove) {
                // The layer surface is created again on every show and takes the window's
                // screen at that moment: set it each time so it cannot drift to another one.
                overlay.screen = overlay.targetScreen;
                overlay.updateOrigin();
            }
            overlay.visible = keepAbove;
        }

        Window {
            id: overlay

            // Widget position on its screen, captured right before showing the surface
            property point origin

            // Screen holding the widget. The desktop window does not expose its screen to QML,
            // so it is looked up from the containment's geometry.
            readonly property var targetScreen: {
                const screens = Qt.application.screens;
                for (let i = 0; i < screens.length; ++i) {
                    if (screens[i].virtualX === root.screenGeometry.x
                            && screens[i].virtualY === root.screenGeometry.y) {
                        return screens[i];
                    }
                }
                return screens[0];
            }

            // The desktop window covers its whole screen, so the widget's position in that
            // window is its position on the screen. Global coordinates are not reliable on
            // Wayland, especially on screens that do not start at 0,0.
            function updateOrigin() {
                const pos = full.mapToItem(null, 0, 0);
                origin = Qt.point(Math.round(pos.x), Math.round(pos.y));
            }

            LayerShell.Window.scope: "verticalpager"
            LayerShell.Window.layer: LayerShell.Window.LayerOverlay
            LayerShell.Window.anchors: LayerShell.Window.AnchorTop | LayerShell.Window.AnchorLeft
            LayerShell.Window.margins.left: origin.x
            LayerShell.Window.margins.top: origin.y
            LayerShell.Window.exclusionZone: -1
            LayerShell.Window.keyboardInteractivity: LayerShell.Window.KeyboardInteractivityNone
            LayerShell.Window.activateOnShow: false
            // Stay on the window's screen instead of following whichever screen is active
            LayerShell.Window.wantsToBeOnActiveScreen: false

            flags: Qt.FramelessWindowHint | Qt.WindowDoesNotAcceptFocus
            color: "transparent"
            width: Math.max(1, full.width)
            height: Math.max(1, full.height)
            visible: false

            // Keep the widget readable over fullscreen content
            Rectangle {
                anchors.fill: parent
                radius: Kirigami.Units.cornerRadius
                color: Qt.alpha(Kirigami.Theme.backgroundColor, 0.85)
            }

            Pager {
                anchors.fill: parent
                pagerRoot: root
                tileWidth: full.tileWidth
                tileHeight: full.tileHeight
                spacing: full.spacing
            }
        }
    }
}
