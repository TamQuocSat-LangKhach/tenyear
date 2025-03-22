local zhenfeng = fk.CreateSkill {
  name = "zhenfengf",
}

Fk:loadTranslationTable{
  ["zhenfengf"] = "镇锋",
  [":zhenfengf"] = "每回合限一次，一名其他角色于其回合内使用牌时，若其手牌数不大于体力值，你可以猜测其手牌中与此牌类别相同的牌数。"..
  "若你猜对，你摸X张牌并视为对其使用一张【杀】（X为你连续猜对次数且最多为5）；若猜错且差值大于1，则视为其对你使用一张【杀】。",

  ["#zhenfengf-invoke"] = "镇锋：是否发动“镇锋”，猜测 %dest 手牌？",
  ["#zhenfengf-choice"] = "镇锋：猜测 %dest 手牌中的%arg数",
  ["@zhenfengf"] = "镇锋",

  ["$zhenfengf1"] = "河西诸贼作乱，吾当驱万里之远。",
  ["$zhenfengf2"] = "可折诸葛之锋而御者，独我其谁！",
}

zhenfeng:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@zhenfengf", 0)
end)

zhenfeng:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhenfeng.name) and target ~= player and player.room.current == target and
      target:getHandcardNum() <= target.hp and not target.dead and
      player:usedSkillTimes(zhenfeng.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = zhenfeng.name,
      prompt = "#zhenfengf-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    for i = 0, target:getHandcardNum(), 1 do
      table.insert(choices, tostring(i))
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = zhenfeng.name,
      prompt = "#zhenfengf-choice::"..target.id..":"..data.card:getTypeString()
    })
    local n = #table.filter(target:getCardIds("h"), function(id)
      return Fk:getCardById(id).type == data.card.type
    end)
    if tonumber(choice) == n then
      room:addPlayerMark(player, "@zhenfengf", 1)
      player:drawCards(math.min(player:getMark("@zhenfengf"), 5), zhenfeng.name)
      if not player.dead and not target.dead then
        room:useVirtualCard("slash", nil, player, target, zhenfeng.name, true)
      end
    else
      room:setPlayerMark(player, "@zhenfengf", 0)
      if math.abs(tonumber(choice) - n) > 1 then
        room:useVirtualCard("slash", nil, target, player, zhenfeng.name, true)
      end
    end
  end,
})

return zhenfeng
