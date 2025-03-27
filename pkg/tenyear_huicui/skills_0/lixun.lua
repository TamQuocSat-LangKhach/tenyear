local lixun = fk.CreateSkill {
  name = "lixun"
}

Fk:loadTranslationTable{
  ['lixun'] = '利熏',
  ['@lisu_zhu'] = '珠',
  [':lixun'] = '锁定技，当你受到伤害时，你防止此伤害，然后获得等同于伤害值的“珠”标记。出牌阶段开始时，你进行一次判定，若结果点数小于“珠”数，你弃置等同于“珠”数的手牌，若弃牌数不足，则失去不足数量的体力值。',
  ['$lixun1'] = '利欲熏心，财权保命。',
  ['$lixun2'] = '利益当前，岂不心动？',
}

lixun:addEffect(fk.DamageInflicted, {
  mute = true,
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lixun.name) 
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(lixun.name)
    room:notifySkillInvoked(player, lixun.name, "defensive")
    room:addPlayerMark(player, "@lisu_zhu", data.damage)
    return true
  end,
})

lixun:addEffect(fk.EventPhaseStart, {
  mute = true,
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player.phase == Player.Play and player:hasSkill(lixun.name) 
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(lixun.name)
    room:notifySkillInvoked(player, lixun.name, "negative")
    local pattern = ".|A~"..(player:getMark("@lisu_zhu") - 1)
    if player:getMark("@lisu_zhu") <= 1 then
      pattern = "."
    end
    local judge = {
      who = player,
      reason = lixun.name,
      pattern = pattern,
    }
    room:judge(judge)
    local n = player:getMark("@lisu_zhu")
    if judge.card.number < n then
      local cards = room:askToDiscard(player, { 
        min_num = n, 
        max_num = n, 
        include_equip = false,
        skill_name = lixun.name,
        cancelable = false
      })
      if #cards < n then
        room:loseHp(player, n - #cards)
      end
    end
  end,
})

return lixun
