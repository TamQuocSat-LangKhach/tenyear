local zecai = fk.CreateSkill {
  name = "zecai",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["zecai"] = "择才",
  [":zecai"] = "限定技，一轮结束时，你可以令一名其他角色获得〖集智〗直到下一轮结束，若其是本轮使用锦囊牌数唯一最多的角色，其执行一个额外的回合。",

  ["#zecai-choose"] = "择才：你可以令一名角色获得“集智”直到下轮结束",
  ["#zecai_tip"] = "获得额外回合",

  ["$zecai1"] = "诸葛良才，可为我佳婿。",
  ["$zecai2"] = "梧桐亭亭，必引凤而栖。",
}

Fk:addTargetTip{
  name = "zecai",
  target_tip = function(self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    if not selectable then return end
    if to_select.id == player:getMark("zecai-tmp") then
      return "#zecai_tip"
    end
  end,
}

zecai:addEffect(fk.RoundEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zecai.name) and player:usedSkillTimes(zecai.name, Player.HistoryGame) == 0 and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local dat = {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
      local use = e.data
      if use.card.type == Card.TypeTrick then
        dat[use.from] = (dat[use.from] or 0) + 1
      end
    end, Player.HistoryRound)
    local max_n, max_p = 0, nil
    for p, n in pairs(dat) do
      if n > max_n then
        max_p, max_n = p, n
      elseif n == max_n then
        max_p = nil
      end
    end
    if max_p then
      room:setPlayerMark(player, "zecai-tmp", max_p.id)
    end
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#zecai-choose",
      skill_name = zecai.name,
      cancelable = true,
      target_tip_name = zecai.name,
    })
    room:setPlayerMark(player, "zecai-tmp", 0)
    if #to > 0 then
      event:setCostData(self, {tos = to, choice = to[1] == max_p})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    if not to:hasSkill("ex__jizhi", true) then
      room:addPlayerMark(to, "zecai_tmp")
      room:handleAddLoseSkills(to, "ex__jizhi")
    end
    if event:getCostData(self).choice then
      to:gainAnExtraTurn()
    end
  end,

  can_refresh = function(self, event, target, player, data)
    return player:getMark("zecai_tmp") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "zecai_tmp", 0)
    room:handleAddLoseSkills(player, "-ex__jizhi")
  end,
})

return zecai
