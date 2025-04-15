local quxian = fk.CreateSkill {
  name = "quxian",
}

Fk:loadTranslationTable{
  ["quxian"] = "驱险",
  [":quxian"] = "出牌阶段开始时，你可以选择一名角色，攻击范围内含有有其的其他角色依次可以对其使用一张【杀】。"..
  "若其未以此法受到过伤害，未使用【杀】的角色各失去X点体力（X为以此法使用【杀】的角色数）。",

  ["#quxian-choose"] = "驱险：选择一名角色，攻击范围含有其的其他角色可以对其使用【杀】",
  ["#quxian-use"] = "驱险：你可以对 %dest 使用【杀】",
}

quxian:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(quxian.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = quxian.name,
      prompt = "#quxian-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local targets = table.filter(room:getAlivePlayers(), function (p)
      return p ~= player and p:inMyAttackRange(to)
    end)
    if #targets == 0 then return end
    room:delay(1500)
    room:doIndicate(player, targets)
    local to_loseHp = {}
    local no_damage = true
    for _, p in ipairs(targets) do
      if not p.dead then
        local use = room:askToUseCard(p, {
          skill_name = quxian.name,
          pattern = "slash",
          prompt = "#quxian-use::"..to.id,
          extra_data = {
            bypass_times = true,
            exclusive_targets = {to.id},
          }
        })
        if use then
          use.extraUse = true
          room:useCard(use)
          if use.damageDealt and use.damageDealt[to] then
            no_damage = false
          end
        else
          table.insert(to_loseHp, p)
        end
      end
    end
    if no_damage then
      local x = #targets - #to_loseHp
      if x > 0 then
        for _, p in ipairs(to_loseHp) do
          if not p.dead then
            room:loseHp(p, x, quxian.name)
          end
        end
      end
    end
  end,
})

return quxian
