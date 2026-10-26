/*
    SPDX-FileCopyrightText: 2026 Nicolas POELAERT <claude@nspt.fr>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_displayedText: displayedText.currentIndex
    property alias cfg_showWindowOutlines: showWindowOutlines.checked
    property alias cfg_showWindowIcons: showWindowIcons.checked
    property alias cfg_wheelEnabled: wheelEnabled.checked
    property alias cfg_keepAboveFullScreen: keepAboveFullScreen.checked

    Kirigami.FormLayout {
        QQC2.ComboBox {
            id: displayedText
            Kirigami.FormData.label: i18n("Text:")
            model: [i18n("Desktop number"), i18n("Desktop name"), i18n("No text")]
        }

        QQC2.CheckBox {
            id: showWindowOutlines
            Kirigami.FormData.label: i18n("Windows:")
            text: i18n("Show window outlines")
        }

        QQC2.CheckBox {
            id: showWindowIcons
            text: i18n("Show application icons on window outlines")
            enabled: showWindowOutlines.checked
        }

        QQC2.CheckBox {
            id: wheelEnabled
            Kirigami.FormData.label: i18n("Navigation:")
            text: i18n("Switch desktops with the mouse wheel")
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC2.CheckBox {
            id: keepAboveFullScreen
            Kirigami.FormData.label: i18n("On the desktop:")
            text: i18n("Stay on top of fullscreen windows")
        }

        QQC2.Label {
            Layout.fillWidth: true
            text: i18n("Only applies when the widget is placed on the desktop, not in a panel.")
            font: Kirigami.Theme.smallFont
            wrapMode: Text.Wrap
        }
    }
}
