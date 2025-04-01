local yinju = fk.CreateSkill {
  name = "yinju",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["yinju"] = "引裾",
  [":yinju"] = "限定技，出牌阶段，你可以选择一名其他角色。本回合：1.当你对其造成伤害时，改为令其回复等量的体力；"..
  "2.当你使用牌指定该角色为目标后，你与其各摸一张牌。",

  ["#yinju"] = "引裾：选择一名角色，本回合对其造成伤害改为令其回复体力，使用牌指定其为目标后双方各摸一张牌",
  ["@@yinju-turn"] = "引裾",

  ["$yinju1"] = "据理直谏，吾人臣本分。",
  ["$yinju2"] = "迁徙之计，危涉万民。",
}

yinju:addEffect("active", {
  anim_type = "support",
  prompt = "#yinju",
  can_use = function(self, player)
    return player:usedSkillTimes(yinju.name, Player.HistoryGame) == 0
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 1,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    room:setPlayerMark(effect.tos[1], "@@yinju-turn", effect.from.id)
  end,
})

yinju:addEffect(fk.DamageCaused, {
  anim_type = "support",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.to ~= player and data.to:getMark("@@yinju-turn") == player.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = data.damage
    data:preventDamage()
    if data.to:isWounded() then
      room:recover {
        num = n,
        skillName = yinju.name,
        who = data.to,
        recoverBy = player,
      }
    end
  end,
})

yinju:addEffect(fk.TargetSpecified, {
  anim_type = "support",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.to ~= player and data.to:getMark("@@yinju-turn") == player.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, yinju.name)
    if not data.to.dead then
      data.to:drawCards(1, yinju.name)
    end
  end,
})

return yinju
