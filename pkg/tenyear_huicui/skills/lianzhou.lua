local lianzhou = fk.CreateSkill {
  name = "lianzhou",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["lianzhou"] = "连舟",
  [":lianzhou"] = "锁定技，准备阶段，将你的武将牌横置，然后横置任意名体力值等于你的角色。",

  ["#lianzhou-choose"] = "连舟：你可以横置任意名体力值等于你的角色",

  ["$lianzhou1"] = "操练水军，以应东吴。",
  ["$lianzhou2"] = "连锁环舟，方能共济。",
}

lianzhou:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lianzhou.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not player.chained then
      player:setChainState(true)
    end
    local targets = table.filter(room.alive_players, function(p)
      return p.hp == player.hp and not p.chained
    end)
    if #targets == 0 then return end
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 10,
      prompt = "#lianzhou-choose",
      skill_name = lianzhou.name,
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      for _, p in ipairs(tos) do
        if not p.dead and not p.chained then
          p:setChainState(true)
        end
      end
    end
  end,
})

return lianzhou
