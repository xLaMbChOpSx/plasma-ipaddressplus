import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.19 as Kirigami
import "../translations/translations.js" as Translations

Kirigami.FormLayout {
    id: page

    property string currentLocale: {
        var locale = Qt.locale().name.split("_")[0];
        return Translations.translations.hasOwnProperty(locale) ? locale : "en";
    }
    property alias cfg_showFlag: showFlag.checked
    property alias cfg_textColor: colorPicker.chosenColor
    property alias cfg_showTypeLabel: showTypeLabel.checked

    QQC2.CheckBox {
        id: showFlag
        Kirigami.FormData.label: Translations.getTranslation("showCountryFlag", currentLocale)
        text: ""
    }

    QQC2.CheckBox {
        id: showTypeLabel
        Kirigami.FormData.label: Translations.getTranslation("showIPType", currentLocale)
        text: ""
    }

    RowLayout {
        Kirigami.FormData.label: Translations.getTranslation("textColor", currentLocale)

        ColorPicker {
            id: colorPicker
        }
    }
}