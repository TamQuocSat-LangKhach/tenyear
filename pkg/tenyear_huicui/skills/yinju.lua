local yinju = fk.CreateSkill {
  name = "yinju"
}

Fk:loadTranslationTable{
  ['yinju'] = '引裾',
  ['@@yinju-turn'] = '引裾',
  ['#yinju_trigger'] = '引裾',
  [':yinju'] = '限定技，出牌阶段，你可以选择一名其他角色。本回合：1.当你对其造成伤害时，改为令其回复等量的体力；2.当你使用牌指定该角色为目标后，你与其各摸一张牌。',
  ['$yinju1'] = '据理直谏，吾人臣本分。',
  ['$yinju2'] = '迁徙之计，危涉万民。',
}

-- 主动技能部分
yinju:addEffect('active', {
  anim_type = "support",
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(yinju.name, Player.HistoryGame) == 0
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 1,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id
  end,
  on_use = function(self, room, use)
    local to = room:getPlayerById(use.tos[1])
    room:setPlayerMark(to, "@@yinju-turn", 1)
  end,
})

-- 触发技能部分
yinju:addEffect(fk.DamageCaused, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(yinju.name) and target == player then
      return data.to ~= player and data.to:getMark("@@yinju-turn") > 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("yinju")
    if event == fk.DamageCaused then
      if data.to:isWounded() then
        room:recover { num = data.damage, skillName = yinju.name, who = data.to , recoverBy = player}
      end
      return true
    end
  end,
})

yinju:addEffect(fk.TargetSpecified, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(yinju.name) and target == player then
      local to = player.room:getPlayerById(data.to)
      return to ~= player and to:getMark("@@yinju-turn") > 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("yinju")
    local to = room:getPlayerById(data.to)
    player:drawCards(1, yinju.name)
    if not to.dead then
      to:drawCards(1, yinju.name)
    end
  end,
})

return yinju
