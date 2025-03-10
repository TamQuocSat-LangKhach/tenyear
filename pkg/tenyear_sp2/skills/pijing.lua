local pijing = fk.CreateSkill {
  name = "pijing"
}

Fk:loadTranslationTable{
  ['pijing'] = '辟境',
  ['#pijing-choose'] = '辟境：你可以令包括你的任意名角色获得技能〖自牧〗直到下次发动〖辟境〗<br>（锁定技，当你受到伤害后，有〖自牧〗的角色各摸一张牌，然后你失去〖自牧〗）',
  ['zimu'] = '自牧',
  [':pijing'] = '结束阶段，你可选择包含你的任意名角色，这些角色获得〖自牧〗直到下次发动〖辟境〗。',
  ['$pijing1'] = '群寇来袭，愿和将军同御外侮。',
  ['$pijing2'] = '天下不宁，愿与阁下共守此州。',
}

pijing:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(pijing.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "choose_players_skill",
      prompt = "#pijing-choose",
      cancelable = true,
      extra_data = {
        targets = table.map(room.alive_players, Util.IdMapper),
        num = 99,
        min_num = 0,
        pattern = "",
      },
      no_indicate = true
    })
    if success and dat then
      local tos = table.simpleClone(dat.targets)
      table.insertIfNeed(tos, player.id)
      room:sortPlayersByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local cost_data = event:getCostData(self)
    local tos = table.simpleClone(cost_data.tos)
    for _, p in ipairs(room:getAlivePlayers()) do
      if p:hasSkill("zimu", true) then
        room:handleAddLoseSkills(p, "-zimu", nil, true, false)
      end
    end
    for _, id in ipairs(tos) do
      room:handleAddLoseSkills(room:getPlayerById(id), "zimu", nil, true, false)
    end
  end,
})

return pijing
