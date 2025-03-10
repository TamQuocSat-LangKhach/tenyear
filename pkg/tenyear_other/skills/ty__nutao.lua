local ty__nutao = fk.CreateSkill {
  name = "ty__nutao"
}

Fk:loadTranslationTable{
  ['ty__nutao'] = '怒涛',
  ['@ty__nutao-phase'] = '怒涛',
  [':ty__nutao'] = '锁定技，当你使用锦囊牌指定目标后，你随机对一名其他目标角色造成1点雷电伤害；当你于出牌阶段造成雷电伤害后，你本阶段使用【杀】次数上限+1。',
}

ty__nutao:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(ty__nutao.name) then
      return data.card.type == Card.TypeTrick and data.firstTarget and
        table.find(AimGroup:getAllTargets(data.tos), function(id) return id ~= player.id end)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(AimGroup:getAllTargets(data.tos), function(id)
      return id ~= player.id and not room:getPlayerById(id).dead end)
    local to = room:getPlayerById(table.random(targets))
    room:doIndicate(player.id, {to.id})
    room:damage{
      from = player,
      to = to,
      damage = 1,
      damageType = fk.ThunderDamage,
      skillName = ty__nutao.name,
    }
  end,
})

ty__nutao:addEffect(fk.Damage, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(ty__nutao.name) then
      return player.phase == Player.Play and data.damageType == fk.ThunderDamage
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "@ty__nutao-phase", 1)
  end,
})

ty__nutao:addEffect('targetmod', {
  residue_func = function(self, player, skill, scope, card, to)
    if card and card.trueName == "slash" and player:getMark("@ty__nutao-phase") > 0 and scope == Player.HistoryPhase then
      return player:getMark("@ty__nutao-phase")
    end
  end,
})

return ty__nutao
