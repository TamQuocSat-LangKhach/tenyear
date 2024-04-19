// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import Fk.Pages
import Fk.RoomElement

GraphicsBox {
  id: root
  property string prompt
  property var cards: []
  property var result: []
  property var areaNames: []
  property int padding: 25

  title.text: luatr(prompt !== "" ? prompt : "Please arrange cards")
  width: body.width + padding * 2
  height: title.height + body.height + padding * 2

  ColumnLayout {
    id: body
    x: padding
    y: parent.height - padding - height
    spacing: 10

    Repeater {
      id: areaRepeater
      model: [cards.length, cards.length, cards.length]

      Row {
        spacing: 5

        property int areaCapacity: modelData
        property string areaName: index < areaNames.length ? qsTr(areaNames[index]) : ""

        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          color: "#6B5D42"
          width: 20
          height: 100
          radius: 5

          Text {
            anchors.fill: parent
            width: 20
            height: 100
            text: areaName
            color: "white"
            font.family: fontLibian.name
            font.pixelSize: 18
            style: Text.Outline
            wrapMode: Text.WordWrap
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
          }
        }

        Repeater {
          id: cardRepeater
          model: areaCapacity

          Rectangle {
            color: "#1D1E19"
            width: 93
            height: 130

            Text {
              anchors.centerIn: parent
              text: areaName
              color: "#59574D"
              width: parent.width * 0.8
              wrapMode: Text.WordWrap
            }
          }
        }
        property alias cardRepeater: cardRepeater
      }
    }

    MetroButton {
      Layout.alignment: Qt.AlignHCenter
      id: buttonConfirm
      text: Backend.translate("OK")
      width: 120
      height: 35

      onClicked: {
        close();
        roomScene.state = "notactive";
        const reply = JSON.stringify(getResult());
        ClientInstance.replyToServer("", reply);
      }
    }
  }

  Repeater {
    id: cardItem
    model: cards

    CardItem {
      x: index
      y: -1
      cid: modelData.cid
      name: modelData.name
      suit: modelData.suit
      number: modelData.number
      draggable: true
      onReleased: arrangeCards();
    }
  }

  function arrangeCards() {
    result = new Array(3);
    let i;
    for (i = 0; i < result.length; i++){
      result[i] = [];
    }

    let card, j, area, cards, stay;
    for (i = 0; i < cardItem.count; i++) {
      card = cardItem.itemAt(i);

      stay = true;
      for (j = areaRepeater.count - 1; j >= 0; j--) {
        area = areaRepeater.itemAt(j);
        cards = result[j];
        if (card.y >= area.y) {
          cards.push(card);
          stay = false;
          break;
        }
      }

      if (stay) {
        for (j = 0; j < areaRepeater.count; j++) {
          result[j].push(card);
          break;
        }
      }
    }
    for(i = 0; i < result.length; i++)
      result[i].sort((a, b) => a.x - b.x);



    let box, pos, pile;
    for (j = 0; j < areaRepeater.count; j++) {
      pile = areaRepeater.itemAt(j);
      if (pile.y === 0){
        pile.y = j * 150
      }
      for (i = 0; i < result[j].length; i++) {
        box = pile.cardRepeater.itemAt(i);
        pos = mapFromItem(pile, box.x, box.y);
        card = result[j][i];
        card.origX = pos.x;
        card.origY = pos.y;
        card.goBack(true);
      }
    }

    var n1 = 0;
    var n2 = 0;
    for (i = 0; i < result[1].length; i++) {
      n1 = n1 + result[1][i].number;
    }
    for (i = 0; i < result[2].length; i++) {
      n2 = n2 + result[2][i].number;
    }
    buttonConfirm.enabled = n1 == n2;
  }

  function getResult() {
    const ret = [];
    result.forEach(t => {
      const t2 = [];
      t.forEach(v => t2.push(v.cid));
      ret.push(t2);
    });
    return ret;
  }
  
  function loadData(data) {
    const d = data;

    prompt = "#yanjiao-distribute";

    cards = d[0].map(cid => {
      return lcall("GetCardData", cid);
    });

    areaNames = [luatr("Top"), luatr(d[1]), luatr(d[2])];
    
    arrangeCards();

  }
}
