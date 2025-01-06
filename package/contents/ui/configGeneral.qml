import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.plasma5support 2.0 as P5Support
import "../translations/translations.js" as Translations

// Formulaire principal pour les paramètres du widget
Kirigami.FormLayout {
    id: page

    // Propriété pour déterminer la locale actuelle
    property string currentLocale: {
        var locale = Qt.locale().name.split("_")[0];
        return Translations.translations.hasOwnProperty(locale) ? locale : "en";
    }

    // Alias pour lier les propriétés de configuration aux éléments UI
    property alias cfg_showFlag: showFlag.checked
    property alias cfg_textColor: colorPicker.chosenColor
    property alias cfg_showTypeLabel: showTypeLabel.checked
    property alias cfg_showFlagOnly: showFlagOnly.checked
    property alias cfg_flagPosition: flagPosition.currentIndex
    property alias cfg_selectedInterface: networkInterfaceComboBox.currentText
    property alias cfg_customPrefix: customPrefixField.text

    // Composant pour exécuter des commandes shell
    P5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        onNewData: {
            var stdout = data["stdout"]
            exited(sourceName, stdout)
            disconnectSource(sourceName)
        }

        function exec(cmd) {
            connectSource(cmd)
        }

        signal exited(string cmd, string stdout)
    }

    // Liste des interfaces réseau
    property var networkInterfaces: []

    Component.onCompleted: {
        // Obtenir la liste des interfaces réseau
        executable.exec("ip -o link show | awk -F': ' '{print $2}'")
    }

    Connections {
        target: executable
        function onExited(cmd, stdout) {
            if (cmd.indexOf("ip -o link") !== -1) {
                // Filtrer et nettoyer la liste des interfaces
                networkInterfaces = stdout.trim().split("\n")
                    .filter(iface => !iface.startsWith("lo")) // Exclure l'interface loopback
            }
        }
    }

    QQC2.ComboBox {
        id: flagPosition
        Kirigami.FormData.label: Translations.getTranslation("flagPosition", currentLocale)
        model: [
            Translations.getTranslation("flagRight", currentLocale),
            Translations.getTranslation("flagLeft", currentLocale)
        ]
        enabled: showFlag.checked || showFlagOnly.checked
    }

    // Case à cocher pour afficher le drapeau du pays
    QQC2.CheckBox {
        id: showFlag
        Kirigami.FormData.label: Translations.getTranslation("showCountryFlag", currentLocale)
        text: ""
        enabled: !showFlagOnly.checked  // Désactivé si "Afficher uniquement le drapeau" est coché
    }

    // Case à cocher pour afficher le type d'IP (local/public)
    QQC2.CheckBox {
        id: showTypeLabel
        Kirigami.FormData.label: Translations.getTranslation("showIPType", currentLocale)
        text: ""
        enabled: !showFlagOnly.checked  // Désactivé si "Afficher uniquement le drapeau" est coché
    }

    // Case à cocher pour afficher uniquement le drapeau
    QQC2.CheckBox {
        id: showFlagOnly
        Kirigami.FormData.label: Translations.getTranslation("showFlagOnly", currentLocale)
        text: ""
        onCheckedChanged: {
            if (checked) {
                // Si coché, force l'affichage du drapeau et désactive l'affichage du type d'IP
                showFlag.checked = true
                showTypeLabel.checked = false
            } else {
                // Si décoché, réactive les options par défaut
                showFlag.checked = true
                showTypeLabel.checked = true
            }
        }
    }

    // Sélecteur de couleur pour le texte
    RowLayout {
        Kirigami.FormData.label: Translations.getTranslation("textColor", currentLocale)

        ColorPicker {
            id: colorPicker
        }
    }

    QQC2.ComboBox {
        id: networkInterfaceComboBox
        Kirigami.FormData.label: Translations.getTranslation("networkInterface", currentLocale)
        model: networkInterfaces
        Layout.fillWidth: true
    }

    QQC2.TextField {
        id: customPrefixField
        Kirigami.FormData.label: Translations.getTranslation("customPrefix", currentLocale)
        placeholderText: Translations.getTranslation("customPrefixPlaceholder", currentLocale)
        Layout.fillWidth: true
    }
}