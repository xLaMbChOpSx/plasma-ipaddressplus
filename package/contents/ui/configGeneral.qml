import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.19 as Kirigami
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
}