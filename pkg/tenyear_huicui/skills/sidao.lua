local sidao = fk.CreateSkill {
  name = "sidao",
}

Fk:loadTranslationTable{
  ["sidao"] = "伺盗",
  [":sidao"] = "每阶段限一次，当你于出牌阶段内对一名其他角色连续使用两张牌后，你可以将一张手牌当【顺手牵羊】对其使用。",

  ["#sidao-invoke"] = "伺盗：你可将一张手牌当【顺手牵羊】对其中一名角色使用",

  ["$sidao1"] = "连发伺动，顺手可得。",
  ["$sidao2"] = "伺机而动，此地可窃。",
}

sidao:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(sidao.name) and player.phase == Player.Play and
      #player:getHandlyIds() > 0 and
      player:usedSkillTimes(sidao.name, Player.HistoryPhase) == 0 then
      local room = player.room
      local tos
      if #room.logic:getEventsByRule(GameEvent.UseCard, 2, function (e)
        local use = e.data
        if use.from == player then
          tos = use.tos
          return true
        end
      end, nil, Player.HistoryPhase) < 2 then return end
      if not tos then return end
      local targets = table.filter(data.tos, function (p)
        return table.contains(tos, p) and not p.dead and p ~= player and
          player:canUseTo(Fk:cloneCard("snatch"), p, {bypass_distances = true})
      end)
      if #targets > 0 then
        event:setCostData(self, {extra_data = targets})
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = event:getCostData(self).extra_data
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "sidao_viewas",
      prompt = "#sidao-invoke",
      cancelable = true,
      extra_data = {
        bypass_distances = true,
        bypass_times = true,
        exclusive_targets = table.map(targets, Util.IdMapper),
      },
    })
    if success and dat then
      event:setCostData(self, {extra_data = dat})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local dat = event:getCostData(self).extra_data
    player.room:useVirtualCard("snatch", dat.cards, player, dat.targets, sidao.name)
  end,
})

return sidao
