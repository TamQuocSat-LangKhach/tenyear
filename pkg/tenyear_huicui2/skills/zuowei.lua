local zuowei = fk.CreateSkill {
  name = "zuowei"
}

Fk:loadTranslationTable{
  ['zuowei'] = '作威',
  ['#zuowei-invoke'] = '作威：你可以令此%arg不可响应',
  ['#zuowei-damage'] = '作威：你可以对一名其他角色造成1点伤害',
  ['#zuowei-draw'] = '作威：你可以摸两张牌，然后本回合此项无效',
  [':zuowei'] = '当你于回合内使用牌时，若你当前手牌数：大于X，你可以令此牌不可响应；等于X，你可以对一名其他角色造成1点伤害；小于X，你可以摸两张牌并令本回合此选项失效（X为你装备区内的牌数且至少为1）。',
  ['$zuowei1'] = '不顺我意者，当填在野之壑。',
  ['$zuowei2'] = '吾令不从者，当膏霜锋之锷。',
}

zuowei:addEffect(fk.CardUsing, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(zuowei.name) and player.phase ~= Player.NotActive then
      local n = player:getHandcardNum() - math.max(#player:getCardIds("e"), 1)
      if n > 0 then
        return data.card.trueName == "slash" or data.card:isCommonTrick()
      elseif n == 0 then
        return true
      elseif n < 0 then
        return player:getMark(zuowei.name .. "-turn") == 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local n = player:getHandcardNum() - math.max(#player:getCardIds("e"), 1)
    if n > 0 then
      if player.room:askToSkillInvoke(player, {
        skill_name = zuowei.name,
        prompt = "#zuowei-invoke:::" .. data.card:toLogString()
      }) then
        event:setCostData(skill, { choice = "disresponsive" })
        return true
      end
    elseif n == 0 then
      local to = player.room:askToChoosePlayers(player, {
        targets = table.map(player.room:getOtherPlayers(player, false), Util.IdMapper),
        min_num = 1,
        max_num = 1,
        prompt = "#zuowei-damage",
        skill_name = zuowei.name
      })
      if #to > 0 then
        event:setCostData(skill, { tos = to, choice = "damage" })
        return true
      end
    elseif n < 0 then
      if player.room:askToSkillInvoke(player, {
        skill_name = zuowei.name,
        prompt = "#zuowei-draw"
      }) then
        event:setCostData(skill, { choice = "draw" })
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(zuowei.name)
    local cost_data = event:getCostData(skill)
    local choice = cost_data.choice
    if choice == "disresponsive" then
      room:notifySkillInvoked(player, zuowei.name, "offensive")
      data.disresponsiveList = table.map(room.alive_players, Util.IdMapper)
    elseif choice == "damage" then
      room:notifySkillInvoked(player, zuowei.name, "offensive")
      room:damage{
        from = player,
        to = room:getPlayerById(cost_data.tos[1]),
        damage = 1,
        skillName = zuowei.name,
      }
    elseif choice == "draw" then
      room:notifySkillInvoked(player, zuowei.name, "drawcard")
      room:setPlayerMark(player, zuowei.name .. "-turn", 1)
      player:drawCards(2, zuowei.name)
    end
  end,
})

return zuowei
