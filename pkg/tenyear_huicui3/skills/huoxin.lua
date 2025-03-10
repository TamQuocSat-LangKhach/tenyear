local huoxin = fk.CreateSkill {
  name = "mu__huoxin"
}

Fk:loadTranslationTable{
  ['mu__huoxin'] = '惑心',
  ['#mu__huoxin-choose'] = '是否发动 惑心，选择一名其他角色，展示其一张手牌标记为“筝”',
  ['yunzheng'] = '韵筝',
  ['@@yunzheng-inhand'] = '筝',
  ['@yunzheng'] = '筝',
  ['#yunzheng-prey'] = '惑心：是否获得%dest展示的%arg',
  [':mu__huoxin'] = '当你使用不为装备牌的牌时，你可以展示一名其他角色的一张手牌并标记为“筝”，若此牌与你使用的牌花色相同或已被标记，你可以获得之。',
  ['$mu__huoxin1'] = '闻君精通音律，与我合奏一曲如何？',
  ['$mu__huoxin2'] = '知君有心意，此筝寄我情。',
}

huoxin:addEffect(fk.CardUsing, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(huoxin.name) and data.card.type ~= Card.TypeEquip and
      table.find(player.room.alive_players, function (p)
        return p ~= player and not p:isKongcheng()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = room:askToChoosePlayers(player, {
      targets = table.map(table.filter(room.alive_players, function (p)
        return p ~= player and not p:isKongcheng()
      end), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      skill_name = huoxin.name,
      prompt = "#mu__huoxin-choose",
    })
    if #targets > 0 then
      event:setCostData(self, targets)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self)[1])
    local id = room:askToChooseCard(player, {
      target = to,
      flag = "h",
      skill_name = huoxin.name,
    })
    to:showCards({id})
    local card = Fk:getCardById(id)
    local toObtain = true
    if card:getMark("yunzheng") == 0 then
      toObtain = false
      room:setCardMark(card, "yunzheng", 1)
      room:setCardMark(card, "@@yunzheng-inhand", 1)
      room:addPlayerMark(to, "@yunzheng")
    end
    if (toObtain or (card.suit == data.card.suit and card.suit ~= Card.NoSuit)) and
      room:askToSkillInvoke(player, {
        skill_name = huoxin.name,
        prompt = "#yunzheng-prey::" .. to.id .. ":" .. card:toLogString(),
      }) then
      room:obtainCard(player, id, true, fk.ReasonPrey, player.id, huoxin.name)
    end
  end,
})

return huoxin
