import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.Commons
import qs.Ui
import "kaomoji.js" as KaomojiSearch

Item {
  id: root

  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var shell: null
  property var manifest: null

  property bool opened: false
  property string filterText: ""
  property int selectedIndex: 0
  property bool cursorActive: false
  property var kaomoji: []
  property var filteredKaomoji: []
  property string selectedCategory: "All"

  readonly property var popularCategories: ["All", "Happy", "Love", "Bear", "Cat", "TableFlip", "Shrug", "Cool", "Wave", "Sad", "Angry", "Music"]

  property color background: Color.menu.background
  property color foreground: Color.foreground
  property color border: Color.menu.border
  property var borderSpec: Border.surfaceSpec("menu", "border", border, Math.max(1, Style.space(2)))
  property color scrim: Color.menu.scrim
  property color selectedBackground: Color.menu.selectedBackground
  property color selectedText: Color.menu.selectedText
  readonly property int cornerRadius: Style.cornerRadius
  property string fontFamily: Style.font.menuFamily
  property string kaomojiFont: "Noto Sans CJK JP, " + (Style.font.family || "sans-serif") + ", JetBrainsMono Nerd Font, sans-serif"
  property int contentMargin: Style.spacing.panelPadding
  property int headerHeight: Math.max(Style.space(34), Style.font.title + Style.spacing.controlPaddingY * 2)
  property int contentSpacing: Style.spacing.md
  property int cardWidth: Math.min(Style.space(660), panel.width - Style.gapsOut * 2)
  property int cardHeight: Math.min(Style.space(520), panel.height - Style.gapsOut * 2)

  readonly property int numColumns: 3
  property int columns: numColumns
  property int cellHeight: Style.space(58)

  function open(payloadJson) {
    root.opened = true
    root.filterText = ""
    root.selectedCategory = "All"
    root.selectedIndex = 0
    root.cursorActive = true
    root.rebuildDisplay()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function close() {
    root.opened = false
  }

  function dismiss() {
    root.opened = false
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide((root.manifest && root.manifest.id) || "omakaomoji")
  }

  function toggle() {
    if (root.opened) root.dismiss()
    else root.open("{}")
  }

  function loadKaomoji(raw) {
    root.kaomoji = KaomojiSearch.parseKaomoji(raw)
    if (root.opened) root.rebuildDisplay()
  }

  function rebuildDisplay() {
    var query = root.filterText
    if (!query && root.selectedCategory !== "All") {
      query = root.selectedCategory
    }
    var out = KaomojiSearch.filterKaomoji(root.kaomoji, query, 1000)
    root.filteredKaomoji = out

    displayModel.clear()
    for (var j = 0; j < out.length; j++) {
      var item = out[j]
      displayModel.append({
        k: item.k,
        cat: item.cat || "",
        tags: (item.tags || []).join(", "),
        index: j
      })
    }

    if (displayModel.count === 0) selectedIndex = 0
    else if (selectedIndex >= displayModel.count) selectedIndex = displayModel.count - 1
    else if (selectedIndex < 0) selectedIndex = 0
    cursorActive = displayModel.count > 0

    Qt.callLater(function() {
      if (displayModel.count > 0) resultGrid.positionViewAtIndex(root.selectedIndex, GridView.Contain)
    })
  }

  function select(delta) {
    if (displayModel.count === 0) return
    if (!cursorActive) {
      cursorActive = true
      selectedIndex = delta < 0 ? displayModel.count - 1 : 0
    } else {
      selectedIndex = (selectedIndex + delta + displayModel.count) % displayModel.count
    }
    resultGrid.positionViewAtIndex(selectedIndex, GridView.Contain)
  }

  function selectRow(delta) {
    if (displayModel.count === 0) return
    if (!cursorActive) {
      cursorActive = true
      selectedIndex = delta < 0 ? displayModel.count - 1 : 0
      resultGrid.positionViewAtIndex(selectedIndex, GridView.Contain)
      return
    }
    var newIndex = selectedIndex + delta * columns
    if (newIndex < 0) newIndex = 0
    if (newIndex >= displayModel.count) newIndex = displayModel.count - 1
    selectedIndex = newIndex
    resultGrid.positionViewAtIndex(selectedIndex, GridView.Contain)
  }

  function selectPage(delta) {
    if (displayModel.count === 0) return
    if (!cursorActive) {
      cursorActive = true
      selectedIndex = delta < 0 ? displayModel.count - 1 : 0
      resultGrid.positionViewAtIndex(selectedIndex, GridView.Contain)
      return
    }
    var visibleRows = Math.max(1, Math.floor(resultGrid.height / cellHeight))
    var newIndex = selectedIndex + delta * columns * visibleRows
    if (newIndex < 0) newIndex = 0
    if (newIndex >= displayModel.count) newIndex = displayModel.count - 1
    selectedIndex = newIndex
    resultGrid.positionViewAtIndex(selectedIndex, GridView.Contain)
  }

  function setFilter(nextFilter) {
    root.filterText = nextFilter
    root.selectedCategory = "All"
    root.selectedIndex = 0
    root.cursorActive = true
    root.rebuildDisplay()
  }

  function filterByCategory(cat) {
    root.selectedCategory = cat
    root.filterText = ""
    root.selectedIndex = 0
    root.cursorActive = true
    root.rebuildDisplay()
  }

  function activateIndex(index) {
    if (index < 0 || index >= displayModel.count) return
    var row = displayModel.get(index)
    root.applySelected(row.k)
  }

  function applySelected(k) {
    if (!k) return
    root.dismiss()
    var insertCmd = root.omarchyPath ? (root.omarchyPath + "/bin/omarchy-menu-emoji-insert") : "/usr/share/omarchy/bin/omarchy-menu-emoji-insert"
    Quickshell.execDetached([insertCmd, k])
  }

  ListModel { id: displayModel }

  Process {
    id: menuRegistrar
    running: true
    command: ["python3", Qt.resolvedUrl("register_menu.py").toString().replace("file://", "")]
  }

  FileView {
    path: Qt.resolvedUrl("kaomoji.json").toString().replace("file://", "")
    onLoaded: root.loadKaomoji(text())
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "omakaomoji"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
      anchors.fill: parent
      color: root.scrim
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.dismiss()
    }

    BorderSurface {
      id: card
      width: root.cardWidth
      height: root.cardHeight
      radius: root.cornerRadius
      anchors.centerIn: parent
      color: root.background
      borderSpec: root.borderSpec
      padding: root.contentMargin

      MouseArea { anchors.fill: parent; onClicked: {} }

      Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true

        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            if (root.filterText || root.selectedCategory !== "All") {
              root.setFilter("")
            } else {
              root.dismiss()
            }
            event.accepted = true
          } else if (Util.editsFilter(event, root.filterText)) {
            root.setFilter(Util.editedFilter(event, root.filterText))
            event.accepted = true
          } else if (event.key === Qt.Key_Left) {
            root.select(-1)
            event.accepted = true
          } else if (event.key === Qt.Key_Right) {
            root.select(1)
            event.accepted = true
          } else if (event.key === Qt.Key_Up) {
            root.selectRow(-1)
            event.accepted = true
          } else if (event.key === Qt.Key_Down) {
            root.selectRow(1)
            event.accepted = true
          } else if (event.key === Qt.Key_PageUp) {
            root.selectPage(-1)
            event.accepted = true
          } else if (event.key === Qt.Key_PageDown) {
            root.selectPage(1)
            event.accepted = true
          } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (root.cursorActive) root.activateIndex(root.selectedIndex)
            else if (displayModel.count > 0) root.cursorActive = true
            event.accepted = true
          } else if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32 && event.text.charCodeAt(0) !== 127) {
            root.setFilter(root.filterText + event.text)
            event.accepted = true
          }
        }
      }

      Column {
        anchors.fill: parent
        anchors.topMargin: card.contentTopInset
        anchors.rightMargin: card.contentRightInset
        anchors.bottomMargin: card.contentBottomInset
        anchors.leftMargin: card.contentLeftInset
        spacing: root.contentSpacing

        // Search Bar Header (Pure Omarchy menu style)
        Item {
          width: parent.width
          height: root.headerHeight

          Row {
            id: headerLeft
            anchors.left: parent.left
            anchors.right: headerRight.left
            anchors.rightMargin: Style.space(12)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(10)

            Text {
              id: headerIcon
              anchors.verticalCenter: parent.verticalCenter
              text: "(◕‿◕)"
              font.family: root.kaomojiFont
              font.pixelSize: Style.font.heading
              font.bold: true
              color: root.filterText ? root.selectedText : root.foreground
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              width: Math.max(0, headerLeft.width - headerIcon.implicitWidth - headerLeft.spacing)
              text: root.filterText || (root.selectedCategory !== "All" ? ("Category: " + root.selectedCategory) : "Search kaomoji…")
              color: root.foreground
              opacity: (root.filterText || root.selectedCategory !== "All") ? 1 : 0.58
              font.family: root.fontFamily
              font.pixelSize: Style.font.heading
              elide: Text.ElideRight
            }
          }

          Text {
            id: headerRight
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: displayModel.count + " kaomojis"
            font.family: root.fontFamily
            font.pixelSize: Style.font.base
            color: root.selectedText
            opacity: 0.85
          }
        }

        // Category Quick Filter Bar
        Flickable {
          width: parent.width
          height: Style.space(26)
          contentWidth: catRow.width
          clip: true
          boundsBehavior: Flickable.StopAtBounds

          Row {
            id: catRow
            spacing: Style.space(4)

            Repeater {
              model: root.popularCategories
              delegate: Rectangle {
                id: catPill
                required property string modelData
                readonly property bool isSelected: root.selectedCategory === modelData && !root.filterText
                readonly property bool isHovered: catMouse.containsMouse

                height: Style.space(24)
                width: catLabel.implicitWidth + Style.space(14)
                radius: root.cornerRadius
                color: isSelected ? root.selectedBackground : (isHovered ? Color.alpha(root.selectedBackground, 0.4) : "transparent")

                Behavior on color { ColorAnimation { duration: 80 } }

                Text {
                  id: catLabel
                  anchors.centerIn: parent
                  text: catPill.modelData
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.base
                  font.bold: catPill.isSelected
                  color: catPill.isSelected ? root.selectedText : root.foreground
                  opacity: catPill.isSelected ? 1 : 0.65
                }

                MouseArea {
                  id: catMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.filterByCategory(catPill.modelData)
                }
              }
            }
          }
        }

        // Grid View Area (Symmetrically filling 100% width)
        Item {
          id: gridArea
          width: parent.width
          height: parent.height - root.headerHeight - Style.space(26) - Style.space(20) - (root.contentSpacing * 3)

          GridView {
            id: resultGrid
            anchors.fill: parent
            model: displayModel
            clip: true
            cellWidth: Math.floor(gridArea.width / root.numColumns)
            cellHeight: root.cellHeight
            boundsBehavior: Flickable.StopAtBounds

            delegate: Item {
              id: cellItem
              required property int index
              required property string k
              required property string cat
              required property string tags

              readonly property bool hasCursor: root.cursorActive && index === root.selectedIndex
              readonly property bool isHovered: mouseArea.containsMouse

              width: resultGrid.cellWidth
              height: resultGrid.cellHeight

              Rectangle {
                id: cellBox
                anchors.fill: parent
                anchors.margins: Style.space(2)
                radius: root.cornerRadius
                color: cellItem.hasCursor ? root.selectedBackground : (cellItem.isHovered ? Color.alpha(root.selectedBackground, 0.4) : "transparent")

                Behavior on color { ColorAnimation { duration: 80 } }

                Column {
                  anchors.centerIn: parent
                  spacing: Style.space(2)
                  width: parent.width - Style.space(8)

                  Text {
                    text: cellItem.k
                    font.family: root.kaomojiFont
                    font.pixelSize: Style.font.title
                    width: parent.width
                    elide: Text.ElideRight
                    color: cellItem.hasCursor ? root.selectedText : root.foreground
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                  }

                  Text {
                    text: cellItem.cat
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    opacity: cellItem.hasCursor ? 0.85 : 0.45
                    width: parent.width
                    elide: Text.ElideRight
                    color: cellItem.hasCursor ? root.selectedText : root.foreground
                    horizontalAlignment: Text.AlignHCenter
                  }
                }
              }

              MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onContainsMouseChanged: if (containsMouse) {
                  root.cursorActive = true
                  root.selectedIndex = index
                }
                onClicked: {
                  root.cursorActive = true
                  root.selectedIndex = index
                  root.activateIndex(index)
                }
              }
            }
          }

          // Empty State
          Column {
            anchors.centerIn: parent
            spacing: Style.space(8)
            visible: displayModel.count === 0

            Text {
              text: "(・_・;)"
              color: root.selectedText
              font.family: root.kaomojiFont
              font.pixelSize: Style.space(28)
              horizontalAlignment: Text.AlignHCenter
              width: parent.width
            }

            Text {
              text: "No kaomoji found for “" + (root.filterText || root.selectedCategory) + "”"
              color: root.foreground
              opacity: 0.8
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
              horizontalAlignment: Text.AlignHCenter
              width: parent.width
            }

            Text {
              text: "Try searching for “hug”, “flip”, “bear”, or “smile”"
              color: root.foreground
              opacity: 0.5
              font.family: root.fontFamily
              font.pixelSize: Style.font.base
              horizontalAlignment: Text.AlignHCenter
              width: parent.width
            }
          }
        }

        // Bottom Footer Bar
        Row {
          width: parent.width
          height: Style.space(20)

          Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            visible: root.cursorActive && displayModel.count > 0 && root.selectedIndex < displayModel.count
            readonly property var currentItem: (root.selectedIndex >= 0 && root.selectedIndex < root.filteredKaomoji.length) ? root.filteredKaomoji[root.selectedIndex] : null

            text: currentItem ? (currentItem.k + "  •  " + currentItem.cat) : ""
            font.family: root.kaomojiFont
            font.pixelSize: Style.font.base
            color: root.selectedText
          }

          Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: "↑↓←→ Navigate   ↵ Paste   Esc Close"
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            color: root.foreground
            opacity: 0.45
          }
        }
      }
    }
  }
}
