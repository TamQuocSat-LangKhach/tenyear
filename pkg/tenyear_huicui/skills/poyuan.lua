local poyuan = fk.CreateSkill {
  name = "poyuan",
}

Fk:loadTranslationTable{
  ["poyuan"] = "破垣",
  [":poyuan"] = "游戏开始时或回合开始时，若你的装备区里没有<a href=':ty__catapult'>【霹雳车】</a>，你可以将【霹雳车】置入装备区；"..
  "若有，你可以弃置一名其他角色至多两张牌。",

  ["#poyuan-choose"] = "破垣：你可以弃置一名其他角色至多两张牌",
  ["#poyuan-invoke"] = "破垣：你可以装备【霹雳车】",

  ["$poyuan1"] = "砲石飞空，坚垣难存。",
  ["$poyuan2"] = "声若霹雳，人马俱摧。",
}

local U = require "packages/utility/utility"

poyuan:addEffect(fk.GameStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(poyuan.name) then
      local catapult = table.find(U.prepareDeriveCards(player.room, {{ "ty__catapult", Card.Diamond, 9 }}, poyuan.name), function (id)
        return player.room:getCardArea(id) == Card.Void
      end)
      return catapult and player:canMoveCardIntoEquip(catapult)
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = poyuan.name,
      prompt = "#poyuan-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local catapult = table.find(U.prepareDeriveCards(room, {{"ty__catapult", Card.Diamond, 9}}, poyuan.name), function (id)
      return player.room:getCardArea(id) == Card.Void
    end)
    if catapult then
      room:setCardMark(Fk:getCardById(catapult), MarkEnum.DestructOutMyEquip, 1)
      room:moveCardIntoEquip(player, catapult, poyuan.name, true, player)
    end
  end,
})

poyuan:addEffect(fk.TurnStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(poyuan.name) then
      if table.find(player:getEquipments(Card.SubtypeTreasure), function(id)
        return Fk:getCardById(id).name == "ty__catapult"
      end) then
        return table.find(player.room:getOtherPlayers(player, false), function(p)
          return not p:isNude()
        end)
      else
        local catapult = table.find(U.prepareDeriveCards(player.room, {{"ty__catapult", Card.Diamond, 9}}, poyuan.name), function (id)
          return player.room:getCardArea(id) == Card.Void
        end)
        return catapult and player:canMoveCardIntoEquip(catapult)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if table.find(player:getEquipments(Card.SubtypeTreasure), function(id)
      return Fk:getCardById(id).name == "ty__catapult"
    end) then
      local targets = table.filter(room:getOtherPlayers(player, false), function(p)
        return not p:isNude()
      end)
      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#poyuan-choose",
        skill_name = poyuan.name,
        cancelable = true,
      })
      if #to > 0 then
        event:setCostData(self, {tos = to})
        return true
      end
    elseif room:askToSkillInvoke(player, {
        skill_name = poyuan.name,
        prompt = "#poyuan-invoke",
      }) then
      event:setCostData(self, nil)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event:getCostData(self) ~= nil then
      local to = event:getCostData(self).tos[1]
      local cards = room:askToChooseCards(player, {
        target = to,
        min = 1,
        max = 2,
        flag = "he",
        skill_name = poyuan.name,
      })
      room:throwCard(cards, poyuan.name, to, player)
    else
      local catapult = table.find(U.prepareDeriveCards(room, {{"ty__catapult", Card.Diamond, 9}}, poyuan.name), function (id)
        return player.room:getCardArea(id) == Card.Void
      end)
      if catapult then
        room:setCardMark(Fk:getCardById(catapult), MarkEnum.DestructOutMyEquip, 1)
        room:moveCardIntoEquip(player, catapult, poyuan.name, true, player)
      end
    end
  end,
})

return poyuan
