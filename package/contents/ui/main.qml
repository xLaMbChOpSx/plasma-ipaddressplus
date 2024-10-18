import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.plasma5support 2.0 as P5Support
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.20 as Kirigami
import "../translations/translations.js" as Translations

PlasmoidItem {
    id: root

    property string currentLocale: {
        var locale = Qt.locale().name.split("_")[0];
        return Translations.translations.hasOwnProperty(locale) ? locale : "en";
    }
    property string localIP: Translations.getTranslation("loading", currentLocale)
    property string publicIP: ""
    property string countryCode: ""
    property bool showingLocalIP: true

    Layout.preferredWidth: contentLayout.implicitWidth
    Layout.preferredHeight: contentLayout.implicitHeight
    Layout.minimumWidth: Layout.preferredWidth
    Layout.minimumHeight: Layout.preferredHeight

    ColumnLayout {
        id: contentLayout
        anchors.fill: parent
        spacing: 5

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 5
            
            Item {
                id: flagContainer
                Layout.preferredWidth: 17
                Layout.preferredHeight: 17

                Image {
                    id: flagImage
                    anchors.fill: parent
                    source: countryCode && shouldShowFlag() ? 
                        "https://flagcdn.com/w320/" + countryCode.toLowerCase() + ".png" : ""
                    visible: shouldShowFlag()
                    fillMode: Image.PreserveAspectFit
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: toggleIPDisplay()
                }
            }

            ColumnLayout {
                id: ipInfoColumn
                spacing: 0
                Layout.alignment: Qt.AlignHCenter
                visible: !plasmoid.configuration.showFlagOnly || showingLocalIP

                QQC2.Label {
                    id: ipTypeLabel
                    text: showingLocalIP ? Translations.getTranslation("localIP", currentLocale) : Translations.getTranslation("publicIP", currentLocale)
                    font.pointSize: Math.round(Kirigami.Theme.defaultFont.pointSize * 0.8)
                    Layout.alignment: Qt.AlignHCenter
                    color: plasmoid.configuration.textColor || PlasmaCore.ColorScope.textColor
                    visible: plasmoid.configuration.showTypeLabel
                }

                QQC2.Label {
                    id: ipAddressLabel
                    text: showingLocalIP ? localIP : 
                        (publicIP !== "" ? publicIP : Translations.getTranslation("notConnected", currentLocale))
                    Layout.alignment: Qt.AlignHCenter
                    color: {
                        if (publicIP === "" && !showingLocalIP) {
                            return "#FF0000" // Rouge en hexadécimal
                        } else {
                            return plasmoid.configuration.textColor || PlasmaCore.ColorScope.textColor
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: toggleIPDisplay()
                }
            }
        }
    }

    P5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: {
            var stdout = data["stdout"]
            var stderr = data["stderr"]
            exited(sourceName, stdout, stderr)
            disconnectSource(sourceName)
        }
        function exec(cmd) {
            connectSource(cmd)
        }
        signal exited(string cmd, string stdout, string stderr)
    }

    Component.onCompleted: {
        getLocalIP()
        getPublicIP()
    }

    function getLocalIP() {
        executable.exec("ip -4 addr show scope global | grep inet | awk '{print $2}' | cut -d/ -f1 | head -n1")
    }

    function getPublicIP() {
        executable.exec("curl -s https://api.ipify.org")
    }

    function getCountryCode() {
        executable.exec("curl -s https://ipapi.co/" + publicIP + "/country")
    }

    Connections {
        target: executable
        function onExited(cmd, stdout, stderr) {
            if (cmd.indexOf("ip -4 addr") !== -1) {
                localIP = stdout.trim()
            } else if (cmd.indexOf("ipify.org") !== -1) {
                if (stderr === "") {
                    publicIP = stdout.trim()
                    if (publicIP !== "") {
                        getCountryCode()
                    }
                } else {
                    publicIP = ""
                    countryCode = ""
                }
            } else if (cmd.indexOf("ipapi.co") !== -1) {
                countryCode = stdout.trim()
            }
            updateDisplay()
        }
    }

    Timer {
        interval: 60000 // Mise à jour toutes les 60 secondes
        running: true
        repeat: true
        onTriggered: {
            getLocalIP()
            getPublicIP()
        }
    }

    function shouldShowFlag() {
        // Le drapeau ne doit être affiché que si :
        // - "Afficher uniquement le drapeau" est activé ou "Afficher le drapeau" est activé
        // - Le pays est identifié (countryCode n'est pas vide)
        // - L'affichage actuel est l'IP publique (showingLocalIP est faux)
        return (plasmoid.configuration.showFlagOnly || plasmoid.configuration.showFlag) 
               && countryCode !== ""
               && !showingLocalIP
    }

    function toggleIPDisplay() {
        // Cas spécial : si "Afficher uniquement le drapeau" est activé et que l'IP publique est affichée
        if (plasmoid.configuration.showFlagOnly && !showingLocalIP) {
            showingLocalIP = true
            getLocalIP()
        } else {
            showingLocalIP = !showingLocalIP
            if (!showingLocalIP) {
                getPublicIP()
            } else {
                getLocalIP()
            }
        }
        updateDisplay()
    }

    function updateDisplay() {
        // Vérifier les états des cases à cocher
        var showFlagOnly = plasmoid.configuration.showFlagOnly
        var showFlag = plasmoid.configuration.showFlag
        var showType = plasmoid.configuration.showTypeLabel

        // Définir la visibilité du drapeau
        flagImage.visible = shouldShowFlag()

        // Définir la visibilité des informations IP
        ipInfoColumn.visible = !showFlagOnly || showingLocalIP

        // Définir la visibilité du type d'IP
        ipTypeLabel.visible = showType && (!showFlagOnly || showingLocalIP)

        // Actualiser le texte de l'IP en fonction de l'état
        if (showFlagOnly && !showingLocalIP) {
            ipAddressLabel.text = ""
        } else {
            ipAddressLabel.text = showingLocalIP ? localIP :
                (publicIP !== "" ? publicIP : Translations.getTranslation("notConnected", currentLocale))
        }

        // Rafraîchir l'affichage
        contentLayout.forceLayout()
    }

    // Connexions pour surveiller les changements de configuration
    Connections {
        target: plasmoid.configuration
        onShowFlagOnlyChanged: updateDisplay()
        onShowFlagChanged: updateDisplay()
        onShowTypeLabelChanged: updateDisplay()
    }
}