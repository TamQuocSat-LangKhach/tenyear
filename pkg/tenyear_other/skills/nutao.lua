local nutao = fk.CreateSkill {
  name = "ty__nutao",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty__nutao"] = "怒涛",
  [":ty__nutao"] = "锁定技，当你使用锦囊牌指定目标后，你随机对一名其他目标角色造成1点雷电伤害；当你于出牌阶段造成雷电伤害后，"..
  "你本阶段使用【杀】次数上限+1。",

  ["@ty__nutao-phase"] = "怒涛",

  ["$ty__nutao1"] = "波澜逆转，攻守皆可！",
  ["$ty__nutao2"] = "伍胥怒涛，奔流不灭！",
  ["$ty__nutao3"] = "波涛怒天，神力无边！",
  ["$ty__nutao4"] = "智勇深沉，一世之雄！",
}

nutao:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(nutao.name) and data.firstTarget and
      data.card.type == Card.TypeTrick and
      table.find(data.use.tos, function(p)
        return p ~= player and not p.dead
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local targets = table.filter(data.use.tos, function(p)
      return p ~= player and not p.dead
    end)
    event:setCostData(self, {tos = table.random(targets, 1)})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:damage{
      from = player,
      to = to,
      damage = 1,
      damageType = fk.ThunderDamage,
      skillName = nutao.name,
    }
  end,
})

nutao:addEffect(fk.Damage, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(nutao.name) and
      player.phase == Player.Play and data.damageType == fk.ThunderDamage
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@ty__nutao-phase", 1)
  end,
})

nutao:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope, card, to)
    if card and skill.trueName == "slash_skill" and player:getMark("@ty__nutao-phase") > 0 and scope == Player.HistoryPhase then
      return player:getMark("@ty__nutao-phase")
    end
  end,
})

return nutao
