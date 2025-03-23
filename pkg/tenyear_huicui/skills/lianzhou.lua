local lianzhou = fk.CreateSkill {
  name = "lianzhou"
}

Fk:loadTranslationTable{
  ['lianzhou'] = '连舟',
  ['#lianzhou-choose'] = '连舟：你可以横置任意名体力值等于你的角色',
  [':lianzhou'] = '锁定技，准备阶段，将你的武将牌横置，然后横置任意名体力值等于你的角色。',
  ['$lianzhou1'] = '操练水军，以应东吴。',
  ['$lianzhou2'] = '连锁环舟，方能共济。',
}

lianzhou:addEffect(fk.EventPhaseStart, {
  anim_type = "special",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lianzhou.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not player.chained then
      player:setChainState(true)
    end
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return p.hp == player.hp and not p.chained
    end), Util.IdMapper)

    if #targets == 0 then return end

    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 999,
      prompt = "#lianzhou-choose",
      skill_name = lianzhou.name,
      cancelable = true
    })
    if #tos > 0 then
      table.forEach(tos, function(p) room:getPlayerById(p):setChainState(true) end)
    end
  end,
})

return lianzhou
