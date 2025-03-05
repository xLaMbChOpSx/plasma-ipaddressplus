/**
 * IP Address+ Display Plasmoid
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
import "../data/countries.js" as Countries

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

    property int ipMode: 1 //Localv4 = 1, Localv6 = 3, Publicv4 = 4, Publicv6 = 5, VPN = 6
    readonly property string currentLocale: Qt.locale().name.split("_")[0]
    property bool isLoadingPublicIPv4: false
    property bool isLoadingPublicIPv6: false
    property bool isLoadingVPNIP: false
    property bool isLoadingCountryv4: false
    property bool isLoadingCountryv6: false
    property string localIP: Translations.getTranslation("loading", currentLocale)
    property string localIPv6: ""
    property string vpnIP: ""
    property string vpnIP_OLD: ""
    property string publicIP: ""
    property string publicIP_OLD: ""
    property string publicIPv6: ""
    property string publicIPv6_OLD: ""
    property string countryCodev4: ""
    property string countryCodev6: ""
    property int displayedIP: 1
    readonly property bool debugMode: false
    readonly property string flagsPath: "../images/pays/"
    property bool isResuming: false
    property string customPrefix: plasmoid.configuration.customPrefix
    property string selectedInterface: plasmoid.configuration.selectedInterface

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
                        "Public Country v4: " + (countryCodev4 || "none"),
                        "Current IP Mode: " + getIPMode(ipMode),
                        "LoadingPublicIPv4: " + isLoadingPublicIPv4,
                        "LoadingVPNIP: " + isLoadingVPNIP,
                        "LoadingCountryv4: " + isLoadingCountryv4,
                        "Local IP: " + localIP,
                        "Pubilc IP: " + publicIP,
                        "VPN IP: " + vpnIP
                    ].join(" | ")
                    return debugInfo
                }
                visible: false//debugMode && ipMode !== 1
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
                    visible: !plasmoid.configuration.showFlagOnly || ipMode === 1

                    QQC2.Label {
                        id: ipTypeLabel
                        text: switch(ipMode) {
                            case 1:
                                Translations.getTranslation("localIP", currentLocale);
                                break;
                            case 2:
                                Translations.getTranslation("localIPv6", currentLocale);
                                break;
                            case 3:
                                Translations.getTranslation("publicIP", currentLocale);
                                break;
                            case 4:
                                Translations.getTranslation("publicIPv6", currentLocale);
                                break;
                            case 5:
                                Translations.getTranslation("vpnIP", currentLocale);
                                break;
                        }
                        font.pointSize: Math.round(Kirigami.Theme.defaultFont.pointSize * 0.8)
                        Layout.alignment: Qt.AlignHCenter
                        color: plasmoid.configuration.textColor != "" && String(plasmoid.configuration.textColor) !== "#00000000" 
                            ? plasmoid.configuration.textColor 
                            : Kirigami.Theme.textColor
                        visible: plasmoid.configuration.showTypeLabel
                    }


                    QQC2.Label {
                        id: ipAddressLabel
                        text: {
                            let ipText;
                            switch (ipMode) {
                                case 1: //LOCALv4
                                ipText = localIP ? localIP : plasmoid.configuration.noIPMessage;
                                    break;
                                case 2: //LOCALv6
                                    ipText = localIPv6 ? localIPv6 : plasmoid.configuration.noIPMessage;
                                    break;
                                case 3: //PUBLICv4
                                ipText = publicIP ? publicIP : plasmoid.configuration.noIPMessage;
                                    break;
                                case 4: //PUBLICv6
                                    ipText = publicIPv6 ? publicIPv6 : plasmoid.configuration.noIPMessage;
                                    break;
                                case 5: //VPN
                                    ipText = vpnIP ? vpnIP : plasmoid.configuration.noIPMessage;
                                    break;
                            }

                            return customPrefix ? (customPrefix + " " + ipText) : ipText;
                        }
                        Layout.alignment: Qt.AlignHCenter
                        color: {
                            if ((!localIP && displayedIP === 1) || (!publicIP && displayedIP === 3)) {
                                return plasmoid.configuration.disconnectedTextColor;
                            }
                            return plasmoid.configuration.textColor !== "" && String(plasmoid.configuration.textColor) !== "#00000000"
                                ? plasmoid.configuration.textColor 
                                : Kirigami.Theme.textColor;
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
                            if ((ipMode === 3 && countryCodev4 && !debugMode) || (ipMode === 4 && countryCodev6 && !debugMode)) {
                                return (ipMode ===3 ? flagsPath + countryCodev4.toLowerCase() + ".svg" : flagsPath + countryCodev6.toLowerCase() + ".svg")
                            }
                            return ""
                        }
                        visible: !debugMode && shouldShowFlag()
                        fillMode: Image.PreserveAspectFit
                        smooth: true

                        QQC2.ToolTip {
                            text: if (ipMode === 3) {
                                      Countries.getCountryName(countryCodev4);
                                  } else if (ipMode === 4) {
                                      Countries.getCountryName(countryCodev6);
                                  } else {
                                      ""
                                  }

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
                console.log("📡 Command:", sourceName)
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
                if (debugMode) console.log("💻 Wake from sleep detected")
                isResuming = true
                // Force a complete update
                updateData()
            }
        }
    }

    Component.onCompleted: {
        if (debugMode) {
            console.log("🎬 Widget startup")
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
    function getLocalIPv4() {
        if (debugMode) console.log("🏠 Requesting local IPv4 for interface:", selectedInterface)
        if (selectedInterface) {
            executable.exec("ip -4 addr show " + selectedInterface + " scope global | grep inet | awk '{print $2}' | cut -d/ -f1 | head -n1")
        } else {
            executable.exec("ip -4 addr show scope global | grep inet | awk '{print $2}' | cut -d/ -f1 | head -n1")
        }
    }

    function getLocalIPv6() {
        if (debugMode) console.log("🏠 Requesting local IPv6 for interface:", selectedInterface)
        if (selectedInterface) {
            executable.exec("ip -6 addr show " + selectedInterface + " scope link | grep inet6 | awk '{print $2}' | cut -d/ -f1 | head -n1")
        } else {
            executable.exec("ip -6 addr show scope link | grep inet6 | awk '{print $2}' | cut -d/ -f1 | head -n1")
        }
    }

    function getPublicIPv4() {
        if (!isLoadingPublicIPv4) {
            if (debugMode) console.log("🌐 Requesting public IP")
            isLoadingPublicIPv4 = true
            executable.exec("curl -s --max-time 5 https://api.ipify.org")
        }
    }

    function getPublicIPv6() {
        if (!isLoadingPublicIPv6) {
            if (debugMode) console.log("🌐 Requesting public IPv6")
            isLoadingPublicIPv6 = true
            executable.exec("ip -6 addr show scope global | grep inet6 | awk '{print $2}' | cut -d/ -f1 | head -n1")
        }
    }

    function getVPNIP() {
        if (!isLoadingVPNIP) {
            if (debugMode) console.log("🌐 Requesting VPN IP")
            isLoadingVPNIP = true
            executable.exec("ifconfig tun0 | grep 'inet ' | awk '{print $2}' || ifconfig vpn0 | grep 'inet ' | awk '{print $2}'")
        }
    }

    function getCountryCode(target) {
        if (target === 3) { //Publicv4
            if (!isLoadingCountryv4 && (publicIP)) {
                if (debugMode) console.log("🌍 Requesting country code for IPv4:", publicIP)
                isLoadingCountryv4 = true
            executable.exec("curl -s --max-time 5 https://ipapi.co/" + publicIP + "/country")
            }
        }
        else { //Publicv6
            if (!isLoadingCountryv6 && (publicIPv6)) {
                if (debugMode) console.log("🌍 Requesting country code for IPv6:", publicIPv6)
                isLoadingCountryv6 = true
                executable.exec("curl -s --max-time 5 https://ipapi.co/" + publicIPv6 + "/country")
            }
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
            if (cmd.indexOf("grep inet | awk '{print $2}' | cut -d/ -f1 | head -n1") !== -1) {
                localIP = stdout.trim()
                if (debugMode) console.log("🏠 Local IPv4 received:", localIP)
            }
            else if (cmd.indexOf("ip -6 addr show scope link") !== -1) {
                localIPv6 = stdout.trim()
                if (debugMode) console.log("🏠 Local IPv6 received:", localIPv6)
            }
            else if (cmd.indexOf("ip -6 addr show scope global") !== -1 ) {
                publicIPv6 = stdout.trim()
                if (debugMode) console.log("🏠 Public IPv6 received:", publicIPv6)

                isLoadingPublicIPv6 = false
                if (stdout.trim() !== "") {
                    var newIPv6 = stdout.trim()
                    // Check if IP has changed
                    if (newIPv6 !== publicIPv6) {
                        if (debugMode) console.log("🔄 IPv6 change detected:", publicIPv6, "->", newIPv6)
                        publicIPv6 = newIPv6
                        countryCodev6 = ""  // Reset country code
                        getCountryCode(4) // Request new country code
                    }
                } else {
                    publicIPv6 = ""
                    countryCodev6 = ""
                    if (debugMode) console.log("❌ No public IPv6 received")
                }
            }
            else if (cmd.indexOf("tun") !== -1) {
                isLoadingVPNIP = false;
                if (stdout.trim() !== "") {
                    var newVpnIP = stdout.trim()
                    if (newVpnIP.indexOf("error") === -1) {
                        if (debugMode) console.log("🏠 VPN IP received:", vpnIP)
                        if (newVpnIP !== vpnIP) {
                            if (debugMode) console.log("🔄 IP change detected:", vpnIP, "->", newVpnIP)
                            vpnIP = newVpnIP
                        }
                    } else {
                        if (debugMode) console.log("❌ No VPN IP received")
                        newVpnIP = ""
                        vpnIP = ""
                    }
                } else {
                    vpnIP = ""
                    if (debugMode) console.log("❌ No VPN IP received")
                }
            } 
            else if (cmd.indexOf("ipify.org") !== -1) {
                isLoadingPublicIPv4 = false
                if (stdout.trim() !== "") {
                    var newIPv4 = stdout.trim()
                    // Check if IP has changed
                    if (newIPv4 !== publicIP) {
                        if (debugMode) console.log("🔄 IP change detected:", publicIP, "->", newIPv4)
                        publicIP = newIPv4
                        countryCodev4 = ""  // Reset country code
                        getCountryCode(3) // Request new country code
                    }
                } else {
                    publicIP = ""
                    countryCodev4 = ""
                    if (debugMode) console.log("❌ No public IP received")
                }
            }
            else if (cmd.indexOf("ipapi.co") !== -1) {
                if (isLoadingCountryv4) {
                    isLoadingCountryv4 = false
                    var newCountryv4 = stdout.trim()
                    if (newCountryv4.length === 2) {
                        countryCodev4 = newCountryv4
                        if (debugMode) console.log("🌍 Country code received:", countryCodev4)
                    } else {
                        countryCodev4 = ""
                        if (debugMode) console.log("❌ Invalid country code received")
                    }
                } else {
                    if (debugMode) console.log("❌ Unexpected country code response")
                }
                if (isLoadingCountryv6) {
                    isLoadingCountryv6 = false
                    var newCountryv6 = stdout.trim()
                    if (newCountryv6.length === 2) {
                        countryCodev6 = newCountryv6
                        if (debugMode) console.log("🌍 Country code received:", countryCodev6)
                    } else {
                        countryCodev6 = ""
                    if (debugMode) console.log("❌ Invalid country code received")
                    }
                } else {
                    if (debugMode) console.log("❌ Unexpected country code response")
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
            updateData()
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
        return ((plasmoid.configuration.showFlagOnly || plasmoid.configuration.showFlag)
                && countryCodev4.length === 2 && ipMode === 3) || ((plasmoid.configuration.showFlagOnly || plasmoid.configuration.showFlag)
        && countryCodev6.length === 2 && ipMode === 4);
    }

    function updateData() {
        switch (ipMode) {
            case 1: //LOCALv4
                getLocalIPv4();
                break;
            case 2: //LOCALv6
                getLocalIPv6();
                break;
            case 3: //PUBLICv4
                getPublicIPv4();
                break;
            case 4: //PUBLICv6
                getPublicIPv6();
                break;
            case 5: //VPN
                getVPNIP();
                break;
        }
    }

    function toggleIPDisplay() {
        var oldIPMode = ipMode;
        switch (ipMode) {
            case 1:
                ipMode = 2;
                break;
            case 2:
                ipMode = 3;
                break;
            case 3:
                ipMode = 4;
                break;
            case 4:
                ipMode = 5;
                break;
            case 5:
                ipMode = 1;
                break;
        }

        if (debugMode) {
            console.log("🔄 Mode change:", getIPMode(oldIPMode), " --> ", getIPMode(ipMode))
        }
        updateData()
    }

    function getIPMode(currentMode) {
        switch (currentMode) {
            case 1:
                return "Local v4"
            case 2:
                return "Local v6"
            case 3:
                return "Public v4"
            case 4:
                return "Public v6"
            case 5:
                return "VPN"
        }
    }

    function updateDisplay() {
        if (debugMode) {
            console.log("🔄 Refreshing widget")
            console.log("📊 State:", JSON.stringify({
                currentIPMode: getIPMode(ipMode),
                localIP: localIP,
                localIPv6: localIPv6,
                publicIP: publicIP,
                publicIPv6: publicIPv6,
                vpnIP: vpnIP,
                countryCodev4: countryCodev4,
                isLoadingPublicIPv4: isLoadingPublicIPv4,
                isLoadingVPNIP: isLoadingVPNIP,
                isLoadingCountryv4: isLoadingCountryv4
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