// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import Fk.RoomElement

ColumnLayout {
  id: root
  anchors.fill: parent
  property var extra_data: ({ name: "", data: {}})
  signal finish()

  BigGlowText {
    Layout.fillWidth: true
    Layout.preferredHeight: childrenRect.height + 4

    text: luatr(extra_data.name)
  }

  GridView {
    cellWidth: 93 + 4
    cellHeight: 130 + 4
    Layout.preferredWidth: root.width - root.width % 97
    Layout.fillHeight: true
    Layout.alignment: Qt.AlignHCenter
    clip: true

    model: extra_data.data

    delegate: CardItem {
      id: cardItem
      autoBack: false
      Component.onCompleted: {
        let data = lcall("GetCardData", modelData[0]);
        data.virt_name = modelData[1]
        setData(data);
      }
    }
  }
}
