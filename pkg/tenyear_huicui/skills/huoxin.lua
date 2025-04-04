local huoxin = fk.CreateSkill {
  name = "mu__huoxin"
}

Fk:loadTranslationTable{
  ["mu__huoxin"] = "惑心",
  [":mu__huoxin"] = "当你使用非装备牌时，你可以展示一名其他角色的一张手牌并标记为“筝”，若此牌与你使用的牌花色相同或已被标记，你可以获得之。",

  ["#mu__huoxin-choose"] = "惑心：你可以选择一名角色，展示其一张手牌标记为“筝”",
  ["#yunzheng-prey"] = "惑心：是否获得 %dest 展示的%arg？",

  ["$mu__huoxin1"] = "闻君精通音律，与我合奏一曲如何？",
  ["$mu__huoxin2"] = "知君有心意，此筝寄我情。",
}

huoxin:addEffect(fk.CardUsing, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(huoxin.name) and
      data.card.type ~= Card.TypeEquip and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return not p:isKongcheng()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return not p:isKongcheng()
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      skill_name = huoxin.name,
      prompt = "#mu__huoxin-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local id = room:askToChooseCard(player, {
      target = to,
      flag = "h",
      skill_name = huoxin.name,
    })
    to:showCards(id)
    if to.dead or not table.contains(to:getCardIds("h"), id) then return end
    local card = Fk:getCardById(id)
    local yes = true
    if card:getMark("yunzheng") == 0 then
      yes = false
      room:setCardMark(card, "yunzheng", 1)
      if table.find(room.alive_players, function (p)
        return p:hasSkill("yunzheng", true)
      end) then
        room:setCardMark(card, "@@yunzheng-inhand", 1)
        room:addPlayerMark(to, "@yunzheng")
      end
    end
    if not player.dead and (yes or card:compareSuitWith(data.card)) and
      room:askToSkillInvoke(player, {
        skill_name = huoxin.name,
        prompt = "#yunzheng-prey::"..to.id..":"..card:toLogString(),
      }) then
      room:obtainCard(player, id, true, fk.ReasonPrey, player, huoxin.name)
    end
  end,
})

return huoxin
