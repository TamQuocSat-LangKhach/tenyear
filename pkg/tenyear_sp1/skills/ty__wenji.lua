local ty__wenji = fk.CreateSkill{
  name = "ty__wenji"
}

Fk:loadTranslationTable{
  ['ty__wenji'] = '问计',
  ['#ty__wenji-choose'] = '问计：你可以令一名其他角色交给你一张牌',
  ['#ty__wenji-give'] = '问计：你需交给 %dest 一张牌',
  ['@ty__wenji-turn'] = '问计',
  [':ty__wenji'] = '出牌阶段开始时，你可以令一名其他角色交给你一张牌，你于本回合内使用与该牌类别相同的牌不能被其他角色响应。',
  ['$ty__wenji1'] = '琦，愿听先生教诲。',
  ['$ty__wenji2'] = '先生，此计可有破解之法？'
}

ty__wenji:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(ty__wenji.name) and player.phase == Player.Play and
      table.find(player.room:getOtherPlayers(player), function(p) return not p:isNude() end)
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
        return not p:isNude()
      end), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#ty__wenji-choose",
      skill_name = ty__wenji.name
    })
    if #to > 0 then
      event:setCostData(skill, to[1].id)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(skill))
    local card = room:askToCards(to, {
      min_num = 1,
      max_num = 1,
      skill_name = ty__wenji.name,
      prompt = "#ty__wenji-give::" .. player.id
    })
    room:addTableMarkIfNeed(player, "@ty__wenji-turn", Fk:getCardById(card[1]):getTypeString() .. "_char")
    room:obtainCard(player, card[1], false, fk.ReasonGive, to.id)
  end,
})

ty__wenji:addEffect(fk.CardUsing, {
  name = "#ty__wenji_record",
  mute = true,
  can_trigger = function(self, event, target, player)
    if target == player then
      local mark = player:getTableMark("@ty__wenji-turn")
      return table.contains(mark, data.card:getTypeString() .. "_char")
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    data.disresponsiveList = data.disresponsiveList or {}
    for _, p in ipairs(player.room:getOtherPlayers(player)) do
      table.insertIfNeed(data.disresponsiveList, p.id)
    end
  end,
})

return ty__wenji
