local miyi = fk.CreateSkill {
  name = "miyi",
}

Fk:loadTranslationTable{
  ["miyi"] = "蜜饴",
  [":miyi"] = "准备阶段，你可以选择一项令任意名角色执行：1.回复1点体力；2.你对其造成1点伤害。若如此做，结束阶段，这些角色执行另一项。",

  ["#miyi-invoke"] = "蜜饴：你可以令任意名角色执行你选择的效果，本回合结束阶段执行另一项",
  ["miyi1"] = "各回复1点体力",
  ["miyi2"] = "各受到你的1点伤害",
  ["@@miyi1-turn"] = "蜜饴:伤害",
  ["@@miyi2-turn"] = "蜜饴:回复",

  ["$miyi1"] = "百战黄沙苦，舒颜红袖甜。",
  ["$miyi2"] = "撷蜜凝饴糖，入喉润心颜。",
}

miyi:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Start and player:hasSkill(miyi.name)
  end,
  on_cost = function(self, event, target, player, data)
    local success, dat = player.room:askToUseActiveSkill(player, {
      skill_name = "miyi_active",
      prompt = "#miyi-invoke",
      cancelable = true,
    })
    if success and dat then
      event:setCostData(self, {tos = dat.targets, choice = dat.interaction})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = event:getCostData(self).tos
    room:sortByAction(targets)
    local choice = event:getCostData(self).choice
    for _, p in ipairs(targets) do
      if not p.dead then
        room:setPlayerMark(p, "@@"..choice.."-turn", 1)
        if choice == "miyi2" then
          room:damage{
            from = player,
            to = p,
            damage = 1,
            skillName = miyi.name,
          }
        elseif p:isWounded() then
          room:recover{
            who = p,
            num = 1,
            recoverBy = player,
            skillName = miyi.name,
          }
        end
      end
    end
  end,
})

miyi:addEffect(fk.EventPhaseStart, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and player.phase == Player.Finish and
      table.find(player.room.alive_players, function (p)
        return p:getMark("@@miyi1-turn") > 0 or p:getMark("@@miyi2-turn") > 0
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local tos = table.filter(room:getAlivePlayers(), function (p)
      return p:getMark("@@miyi1-turn") > 0 or p:getMark("@@miyi2-turn") > 0
    end)
    event:setCostData(self, {tos = tos})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      if not p.dead then
        if p:getMark("@@miyi2-turn") > 0 and p:isWounded() then
          room:recover{
            who = p,
            num = 1,
            recoverBy = player,
            skillName = miyi.name,
          }
        elseif p:getMark("@@miyi1-turn") > 0 then
          room:damage{
            from = player,
            to = p,
            damage = 1,
            skillName = miyi.name,
          }
        end
      end
    end
  end,
})

return miyi
