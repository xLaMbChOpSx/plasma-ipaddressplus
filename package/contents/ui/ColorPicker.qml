/*
 * Copyright (C) 2014 Martin Yrjölä <martin.yrjola@gmail.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License or version 3 or any later version
 * accepted by the membership of KDE e.V. (or its successor approved
 * by the membership of KDE e.V.), which shall act as a proxy
 * defined in Section 14 of version 3 of the license.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>
 */

// Import necessary Qt modules
import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs as QtDialogs
import Qt.labs.platform
import org.kde.kirigami 2.20 as Kirigami

// Main component for the color picker
Item {
    id: colorPicker

    // Property to store the chosen color
    property alias chosenColor: colorDialog.color

    // Set the size of the color picker
    width: childrenRect.width
    height: childrenRect.height
    Layout.alignment: Qt.AlignVCenter

    // Rectangle to display the chosen color
    Rectangle {
        color: chosenColor != "" && String(chosenColor) !== "#00000000"
            ? chosenColor 
            : Kirigami.Theme.textColor
        radius: width / 2
        height: 20
        width: height
        opacity: enabled ? 1 : 0.5
        border {
            width: mouseArea.containsMouse ? 3 : 1
            color: Qt.darker(color, 1.5)
        }

        // Color dialog for selecting a new color
        ColorDialog {
            id: colorDialog
        }
    }

    // Mouse area to handle clicks on the color picker
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            colorDialog.open()
        }
    }
}