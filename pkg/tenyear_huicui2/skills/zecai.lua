local zecai = fk.CreateSkill {
  name = "zecai"
}

Fk:loadTranslationTable{
  ['zecai'] = '择才',
  ['@@zecai_extra'] = '择才 额外回合',
  ['#zecai-choose'] = '你可以发动择才，令一名其他角色获得〖集智〗直到下轮结束',
  [':zecai'] = '限定技，一轮结束时，你可令一名其他角色获得〖集智〗直到下一轮结束，若其是本轮使用锦囊牌数唯一最多的角色，其执行一个额外的回合。',
  ['$zecai1'] = '诸葛良才，可为我佳婿。',
  ['$zecai2'] = '梧桐亭亭，必引凤而栖。',
}

zecai:addEffect(fk.RoundEnd, {
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player)
    return player:hasSkill(zecai.name) and player:usedSkillTimes(zecai.name, Player.HistoryGame) < 1
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local player_table = {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
      local use = e.data[1]
      if use.card.type == Card.TypeTrick then
        local from = use.from
        player_table[from] = (player_table[from] or 0) + 1
      end
    end, Player.HistoryRound)
    local max_time, max_pid = 0, nil
    for pid, time in pairs(player_table) do
      if time > max_time then
        max_pid, max_time = pid, time
      elseif time == max_time then
        max_pid = 0
      end
    end
    local max_p = nil
    if max_pid ~= 0 then
      max_p = room:getPlayerById(max_pid)
    end
    if max_p and not max_p.dead then
      room:setPlayerMark(max_p, "@@zecai_extra", 1)
    end
    local to = room:askToChoosePlayers(player, {
      targets = table.map(player.room:getOtherPlayers(player, false), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#zecai-choose",
      skill_name = zecai.name,
      cancelable = true
    })
    if max_p and not max_p.dead then
      room:setPlayerMark(max_p, "@@zecai_extra", 0)
    end
    if #to > 0 then
      event:setCostData(self, {to[1], max_pid})
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local tar = room:getPlayerById(event:getCostData(self)[1])
    if not tar:hasSkill("ex__jizhi", true) then
      room:addPlayerMark(tar, "zecai_tmpjizhi")
      room:handleAddLoseSkills(tar, "ex__jizhi", nil, true, false)
    end
    if event:getCostData(self)[1] == event:getCostData(self)[2] then
      tar:gainAnExtraTurn()
    end
  end,
  can_refresh = function(self, event, target, player)
    return player:getMark("zecai_tmpjizhi") > 0
  end,
  on_refresh = function(self, event, target, player)
    local room = player.room
    room:setPlayerMark(player, "zecai_tmpjizhi", 0)
    room:handleAddLoseSkills(player, "-ex__jizhi", nil, true, false)
  end,
})

return zecai
