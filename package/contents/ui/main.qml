/**
 * IP Address Display Plasmoid
 * Purpose: Displays local and public IP addresses with country flags in Plasma panel
 * Operation: Fetches and displays IP information with automatic updates
 * Usage: Helps users monitor their network connectivity and location
 * Interactions: Responds to user clicks and system network changes
 */

import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.plasma5support 2.0 as P5Support
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.20 as Kirigami
import "../translations/translations.js" as Translations

/**
 * Main Plasmoid Container
 * Purpose: Root container managing the entire widget's state and appearance
 * Operation: Coordinates data fetching, display updates, and user interactions
 * Usage: Provides the foundation for all widget components
 * Interactions: Manages communication between UI and data components
 */
PlasmoidItem {
    id: root

    /**
     * Core Properties
     * Purpose: Define essential state variables for the widget
     * Operation: Maintain current state of IPs, loading states, and display modes
     * Usage: Referenced throughout the widget for state management
     * Interactions: Updated by various functions and user actions
     */
    readonly property string currentLocale: Qt.locale().name.split("_")[0]
    property bool isPublicMode: false
    property bool isLoadingIP: false
    property bool isLoadingCountry: false
    property string localIP: Translations.getTranslation("loading", currentLocale)
    property string publicIP: ""
    property string publicIP_OLD: ""
    property string countryCode: ""
    property bool showingLocalIP: true
    readonly property bool debugMode: false
    readonly property string flagsPath: "../images/pays/"
    property bool isResuming: false

    /**
    * Country Names Mapping
    * Purpose: Maps country codes to their full names
    * Operation: Used for tooltip display when hovering over flags
    */
    readonly property var countryNames: ({
        "af": "Afghanistan",
        "ax": "Åland Islands",
        "al": "Albania",
        "dz": "Algeria",
        "as": "American Samoa",
        "ad": "Andorra",
        "ao": "Angola",
        "ai": "Anguilla",
        "aq": "Antarctica",
        "ag": "Antigua and Barbuda",
        "ar": "Argentina",
        "am": "Armenia",
        "aw": "Aruba",
        "au": "Australia",
        "at": "Austria",
        "az": "Azerbaijan",
        "bs": "Bahamas",
        "bh": "Bahrain",
        "bd": "Bangladesh",
        "bb": "Barbados",
        "by": "Belarus",
        "be": "Belgium",
        "bz": "Belize",
        "bj": "Benin",
        "bm": "Bermuda",
        "bt": "Bhutan",
        "bo": "Bolivia",
        "ba": "Bosnia and Herzegovina",
        "bw": "Botswana",
        "br": "Brazil",
        "bn": "Brunei",
        "bg": "Bulgaria",
        "bf": "Burkina Faso",
        "bi": "Burundi",
        "kh": "Cambodia",
        "cm": "Cameroon",
        "ca": "Canada",
        "cv": "Cape Verde",
        "ky": "Cayman Islands",
        "cf": "Central African Republic",
        "td": "Chad",
        "cl": "Chile",
        "cn": "China",
        "co": "Colombia",
        "km": "Comoros",
        "cg": "Congo",
        "cd": "Congo, Democratic Republic",
        "ck": "Cook Islands",
        "cr": "Costa Rica",
        "ci": "Côte d'Ivoire",
        "hr": "Croatia",
        "cu": "Cuba",
        "cy": "Cyprus",
        "cz": "Czech Republic",
        "dk": "Denmark",
        "dj": "Djibouti",
        "dm": "Dominica",
        "do": "Dominican Republic",
        "ec": "Ecuador",
        "eg": "Egypt",
        "sv": "El Salvador",
        "gq": "Equatorial Guinea",
        "er": "Eritrea",
        "ee": "Estonia",
        "et": "Ethiopia",
        "fk": "Falkland Islands",
        "fo": "Faroe Islands",
        "fj": "Fiji",
        "fi": "Finland",
        "fr": "France",
        "gf": "French Guiana",
        "pf": "French Polynesia",
        "ga": "Gabon",
        "gm": "Gambia",
        "ge": "Georgia",
        "de": "Germany",
        "gh": "Ghana",
        "gi": "Gibraltar",
        "gr": "Greece",
        "gl": "Greenland",
        "gd": "Grenada",
        "gp": "Guadeloupe",
        "gu": "Guam",
        "gt": "Guatemala",
        "gg": "Guernsey",
        "gn": "Guinea",
        "gw": "Guinea-Bissau",
        "gy": "Guyana",
        "ht": "Haiti",
        "hn": "Honduras",
        "hk": "Hong Kong",
        "hu": "Hungary",
        "is": "Iceland",
        "in": "India",
        "id": "Indonesia",
        "ir": "Iran",
        "iq": "Iraq",
        "ie": "Ireland",
        "im": "Isle of Man",
        "il": "Israel",
        "it": "Italy",
        "jm": "Jamaica",
        "jp": "Japan",
        "je": "Jersey",
        "jo": "Jordan",
        "kz": "Kazakhstan",
        "ke": "Kenya",
        "ki": "Kiribati",
        "kp": "North Korea",
        "kr": "South Korea",
        "kw": "Kuwait",
        "kg": "Kyrgyzstan",
        "la": "Laos",
        "lv": "Latvia",
        "lb": "Lebanon",
        "ls": "Lesotho",
        "lr": "Liberia",
        "ly": "Libya",
        "li": "Liechtenstein",
        "lt": "Lithuania",
        "lu": "Luxembourg",
        "mo": "Macao",
        "mk": "North Macedonia",
        "mg": "Madagascar",
        "mw": "Malawi",
        "my": "Malaysia",
        "mv": "Maldives",
        "ml": "Mali",
        "mt": "Malta",
        "mh": "Marshall Islands",
        "mq": "Martinique",
        "mr": "Mauritania",
        "mu": "Mauritius",
        "yt": "Mayotte",
        "mx": "Mexico",
        "fm": "Micronesia",
        "md": "Moldova",
        "mc": "Monaco",
        "mn": "Mongolia",
        "me": "Montenegro",
        "ms": "Montserrat",
        "ma": "Morocco",
        "mz": "Mozambique",
        "mm": "Myanmar",
        "na": "Namibia",
        "nr": "Nauru",
        "np": "Nepal",
        "nl": "Netherlands",
        "nc": "New Caledonia",
        "nz": "New Zealand",
        "ni": "Nicaragua",
        "ne": "Niger",
        "ng": "Nigeria",
        "nu": "Niue",
        "nf": "Norfolk Island",
        "mp": "Northern Mariana Islands",
        "no": "Norway",
        "om": "Oman",
        "pk": "Pakistan",
        "pw": "Palau",
        "ps": "Palestine",
        "pa": "Panama",
        "pg": "Papua New Guinea",
        "py": "Paraguay",
        "pe": "Peru",
        "ph": "Philippines",
        "pn": "Pitcairn",
        "pl": "Poland",
        "pt": "Portugal",
        "pr": "Puerto Rico",
        "qa": "Qatar",
        "re": "Réunion",
        "ro": "Romania",
        "ru": "Russia",
        "rw": "Rwanda",
        "sh": "Saint Helena",
        "kn": "Saint Kitts and Nevis",
        "lc": "Saint Lucia",
        "pm": "Saint Pierre and Miquelon",
        "vc": "Saint Vincent and the Grenadines",
        "ws": "Samoa",
        "sm": "San Marino",
        "st": "São Tomé and Príncipe",
        "sa": "Saudi Arabia",
        "sn": "Senegal",
        "rs": "Serbia",
        "sc": "Seychelles",
        "sl": "Sierra Leone",
        "sg": "Singapore",
        "sx": "Sint Maarten",
        "sk": "Slovakia",
        "si": "Slovenia",
        "sb": "Solomon Islands",
        "so": "Somalia",
        "za": "South Africa",
        "ss": "South Sudan",
        "es": "Spain",
        "lk": "Sri Lanka",
        "sd": "Sudan",
        "sr": "Suriname",
        "sj": "Svalbard and Jan Mayen",
        "sz": "Eswatini",
        "se": "Sweden",
        "ch": "Switzerland",
        "sy": "Syria",
        "tw": "Taiwan",
        "tj": "Tajikistan",
        "tz": "Tanzania",
        "th": "Thailand",
        "tl": "Timor-Leste",
        "tg": "Togo",
        "tk": "Tokelau",
        "to": "Tonga",
        "tt": "Trinidad and Tobago",
        "tn": "Tunisia",
        "tr": "Turkey",
        "tm": "Turkmenistan",
        "tc": "Turks and Caicos Islands",
        "tv": "Tuvalu",
        "ug": "Uganda",
        "ua": "Ukraine",
        "ae": "United Arab Emirates",
        "gb": "United Kingdom",
        "us": "United States",
        "um": "United States Minor Outlying Islands",
        "uy": "Uruguay",
        "uz": "Uzbekistan",
        "vu": "Vanuatu",
        "va": "Vatican City",
        "ve": "Venezuela",
        "vn": "Vietnam",
        "vg": "Virgin Islands (British)",
        "vi": "Virgin Islands (U.S.)",
        "wf": "Wallis and Futuna",
        "eh": "Western Sahara",
        "ye": "Yemen",
        "zm": "Zambia",
        "zw": "Zimbabwe"
    })


    /**
     * Layout Settings
     * Purpose: Control widget dimensions and layout behavior
     * Operation: Manages widget sizing based on content
     * Usage: Ensures proper display in Plasma panel
     * Interactions: Adapts to panel position and content changes
     */
    Layout.fillWidth: false
    Layout.fillHeight: false
    Layout.preferredWidth: contentLayout.implicitWidth
    Layout.preferredHeight: contentLayout.implicitHeight

    /**
     * Main Layout Structure
     * Purpose: Organizes visual elements of the widget
     * Operation: Arranges IP information and flag in a structured layout
     * Usage: Creates the visual hierarchy of the widget
     * Interactions: Updates based on content and state changes
     */
    ColumnLayout {
        id: contentLayout
        anchors.fill: parent
        spacing: 5

        RowLayout {
            id: contentRow
            Layout.fillWidth: true
            spacing: 5

            // Debug Information Display
            QQC2.Label {
                id: debugLabel
                text: {
                    let debugInfo = [
                        "Country: " + (countryCode || "none"),
                        "Public: " + !showingLocalIP,
                        "LoadingIP: " + isLoadingIP,
                        "LoadingCountry: " + isLoadingCountry,
                        "IP: " + (showingLocalIP ? localIP : publicIP)
                    ].join(" | ")
                    return debugInfo
                }
                visible: debugMode && !showingLocalIP
                color: "#FF0000"
                font.pointSize: 8
                Layout.alignment: Qt.AlignVCenter
            }

            // Container for IP information and flag
            RowLayout {
                id: ipAndFlagRow
                spacing: 5
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true

                // Adjust the layoutDirection based on flagPosition
                // 0: Flag on the right (default), 1: Flag on the left
                layoutDirection: plasmoid.configuration.flagPosition === 1 ? Qt.RightToLeft : Qt.LeftToRight

                // IP Information Display
                ColumnLayout {
                    id: ipInfoColumn
                    spacing: 0
                    Layout.alignment: Qt.AlignHCenter
                    visible: !plasmoid.configuration.showFlagOnly || showingLocalIP

                    QQC2.Label {
                        id: ipTypeLabel
                        text: showingLocalIP ?
                            Translations.getTranslation("localIP", currentLocale) :
                            Translations.getTranslation("publicIP", currentLocale)
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
                                return "#FF0000"
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

                // Flag Display Component
                Item {
                    id: flagContainer
                    Layout.preferredWidth: 17
                    Layout.preferredHeight: 17
                    Layout.alignment: Qt.AlignVCenter

                    Image {
                        id: flagImage
                        anchors.fill: parent
                        source: {
                            if (countryCode && !debugMode) {
                                return flagsPath + countryCode.toLowerCase() + ".svg"
                            }
                            return ""
                        }
                        visible: !debugMode && shouldShowFlag()
                        fillMode: Image.PreserveAspectFit
                        smooth: true

                        QQC2.ToolTip {
                            text: countryNames[countryCode.toLowerCase()] || countryCode
                            visible: flagMouseArea.containsMouse
                            delay: 500
                        }
                    }

                    MouseArea {
                        id: flagMouseArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true  // Enable hover detection
                        onClicked: toggleIPDisplay()
                    }
                }
            }
        }
    }

    /**
     * Command Execution Component
     * Purpose: Handles shell command execution for IP and country data
     * Operation: Executes commands and processes their output
     * Usage: Retrieves network information from system
     * Interactions: Provides data to update widget state
     */
    P5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        onNewData: {
            var stdout = data["stdout"]
            var stderr = data["stderr"]
            if (debugMode) {
                console.log("📡 Commande:", sourceName)
                console.log("📤 Stdout:", stdout)
                console.log("📥 Stderr:", stderr)
            }
            exited(sourceName, stdout, stderr)
            disconnectSource(sourceName)
        }
        
        function exec(cmd) {
            connectSource(cmd)
        }
        
        signal exited(string cmd, string stdout, string stderr)
    }

    P5Support.DataSource {
        id: pmSource
        engine: "powermanagement"
        connectedSources: ["powerdevil"]
        
        onSourceAdded: {
            disconnectSource(source);
            connectSource(source);
        }
        
        onDataChanged: {
            if (data["powerdevil"] && data["powerdevil"]["Is Resuming"] === true) {
                if (debugMode) console.log("💻 Sortie de veille détectée")
                isResuming = true
                // Force une mise à jour complète
                updateData()
            }
        }
    }

    Component.onCompleted: {
        if (debugMode) {
            console.log("🎬 Démarrage widget")
        }
        updateData()
    }

    /**
     * Data Retrieval Functions
     * Purpose: Fetch IP and location information
     * Operation: Execute system commands to get network data
     * Usage: Called periodically and on user interaction
     * Interactions: Update widget state with retrieved data
     */
    function getLocalIP() {
        if (debugMode) console.log("🏠 Demande IP locale")
        executable.exec("ip -4 addr show scope global | grep inet | awk '{print $2}' | cut -d/ -f1 | head -n1")
    }

    function getPublicIP() {
        if (!isLoadingIP) {
            if (debugMode) console.log("🌐 Demande IP publique")
            isLoadingIP = true
            executable.exec("curl -s --max-time 5 https://api.ipify.org")
        }
    }

    function getCountryCode() {
        if (!isLoadingCountry && publicIP) {
            if (debugMode) console.log("🌍 Demande code pays pour IP:", publicIP)
            isLoadingCountry = true
            executable.exec("curl -s --max-time 5 https://ipapi.co/" + publicIP + "/country")
        }
    }

    /**
     * Data Management
     * Purpose: Process command outputs and update widget state
     * Operation: Handles responses from various data sources
     * Usage: Maintains consistency between data and display
     * Interactions: Triggers UI updates based on new data
     */
    Connections {
        target: executable
        function onExited(cmd, stdout, stderr) {
            if (cmd.indexOf("ip -4 addr") !== -1) {
                localIP = stdout.trim()
                if (debugMode) console.log("🏠 IP locale reçue:", localIP)
            } 
            else if (cmd.indexOf("ipify.org") !== -1) {
                isLoadingIP = false
                if (stdout.trim() !== "") {
                    var newIP = stdout.trim()
                    // Vérifie si l'IP a changé
                    if (newIP !== publicIP) {
                        if (debugMode) console.log("🔄 Changement d'IP détecté:", publicIP, "->", newIP)
                        publicIP = newIP
                        countryCode = ""  // Reset le code pays
                        getCountryCode()  // Demande le nouveau code pays
                    }
                } else {
                    publicIP = ""
                    countryCode = ""
                    if (debugMode) console.log("❌ Pas d'IP publique reçue")
                }
            }
            else if (cmd.indexOf("ipapi.co") !== -1) {
                isLoadingCountry = false
                var newCountry = stdout.trim()
                if (newCountry.length === 2) {
                    countryCode = newCountry
                    if (debugMode) console.log("🌍 Code pays reçu:", countryCode)
                } else {
                    countryCode = ""
                    if (debugMode) console.log("❌ Code pays invalide reçu")
                }
            }

            updateDisplay()
        }
    }

    /**
     * Update Timer
     * Purpose: Periodically refresh IP information
     * Operation: Triggers data update every 5 seconds
     * Usage: Keeps displayed information current
     * Interactions: Initiates data retrieval cycle
     */
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            if (showingLocalIP) {
                getLocalIP()
            } else {
                // Vérifie d'abord l'IP publique actuelle
                executable.exec("curl -s --max-time 5 https://api.ipify.org")
            }
        }
    }

    /**
     * Utility Functions
     * Purpose: Provide helper functions for widget operation
     * Operation: Handle various widget states and updates
     * Usage: Called by different widget components
     * Interactions: Coordinate between UI and data components
     */
    function shouldShowFlag() {
        return (plasmoid.configuration.showFlagOnly || plasmoid.configuration.showFlag) 
                && countryCode.length === 2
                && !showingLocalIP
    }

    function updateData() {
        if (showingLocalIP) {
            getLocalIP()
        } else if (!publicIP) {
            getPublicIP()
        }
    }

    function toggleIPDisplay() {
        showingLocalIP = !showingLocalIP
        if (debugMode) {
            console.log("🔄 Changement mode:", showingLocalIP ? "Local" : "Public")
        }
        updateData()
    }

    function updateDisplay() {
        if (debugMode) {
            console.log("🔄 Rafraîchissement widget")
            console.log("📊 État:", JSON.stringify({
                showingLocalIP: showingLocalIP,
                localIP: localIP,
                publicIP: publicIP,
                countryCode: countryCode,
                isLoadingIP: isLoadingIP,
                isLoadingCountry: isLoadingCountry
            }, null, 2))
        }

        contentLayout.Layout.preferredWidth = -1
        contentLayout.Layout.preferredHeight = -1
        Qt.callLater(function() {
            contentLayout.Layout.preferredWidth = contentLayout.implicitWidth
            contentLayout.Layout.preferredHeight = contentLayout.implicitHeight
        })
    }

    /**
     * Configuration Handler
     * Purpose: Respond to widget configuration changes
     * Operation: Updates display when settings change
     * Usage: Maintains widget appearance per user preferences
     * Interactions: Triggers display updates on config changes
     */
    Connections {
        target: plasmoid.configuration
        function onShowFlagOnlyChanged() { updateDisplay() }
        function onShowFlagChanged() { updateDisplay() }
        function onShowTypeLabelChanged() { updateDisplay() }
    }
}