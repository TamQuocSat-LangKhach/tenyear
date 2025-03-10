local tuxing = fk.CreateSkill {
  name = "tuxing"
}

Fk:loadTranslationTable{
  ['tuxing'] = '图兴',
  ['@@tuxing_damage'] = '图兴加伤',
  [':tuxing'] = '锁定技，①当你废除一个装备栏时，你加1点体力上限并回复1点体力。②当你首次废除所有装备栏后，你减4点体力上限，然后你本局游戏接下来造成的伤害+1。',
  ['$tuxing1'] = '国之兴亡，休戚相关。',
  ['$tuxing2'] = '兴业安民，宏图可绘。',
}

tuxing:addEffect(fk.AreaAborted, {
  mute = true,
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(tuxing.name) then
      local slots = data.slots
      for i = 3, 7 do
        if slots[tostring(i)] then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(tuxing.name)
    room:notifySkillInvoked(player, tuxing.name, "defensive")
    room:changeMaxHp(player, 1)
    if player:isWounded() and not player.dead then
      room:recover({ who = player, num = 1, recoverBy = player, skillName = tuxing.name })
    end
    if #player:getAvailableEquipSlots() == 0 and player:getMark("@@tuxing_damage") == 0 and player:hasSkill(tuxing.name) then
      room:notifySkillInvoked(player, tuxing.name, "big")
      room:addPlayerMark(player, "@@tuxing_damage")
      room:changeMaxHp(player, -4)
    end
  end,
})

tuxing:addEffect(fk.DamageCaused, {
  mute = true,
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@tuxing_damage") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, tuxing.name, "offensive")
    data.damage = data.damage + 1
  end,
})

return tuxing
