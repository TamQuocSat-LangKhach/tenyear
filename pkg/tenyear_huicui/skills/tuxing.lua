local tuxing = fk.CreateSkill {
  name = "tuxing",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["tuxing"] = "图兴",
  [":tuxing"] = "锁定技，当你废除一个装备栏时，你加1点体力上限并回复1点体力。当你首次废除所有装备栏后，你减4点体力上限，你本局游戏造成的伤害+1。",

  ["@@tuxing"] = "图兴",

  ["$tuxing1"] = "国之兴亡，休戚相关。",
  ["$tuxing2"] = "兴业安民，宏图可绘。",
}

tuxing:addEffect(fk.AreaAborted, {
  anim_type = "support",
  trigger_times = function(self, event, target, player, data)
    local n = 0
    for _, value in pairs(data.slots) do
      n = n + value
    end
    return n
  end,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tuxing.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if player:isWounded() and not player.dead then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = tuxing.name,
      }
    end
    if #player:getAvailableEquipSlots() == 0 and player:getMark("@@tuxing") == 0 and player:hasSkill(tuxing.name) then
      room:notifySkillInvoked(player, tuxing.name, "big")
      room:addPlayerMark(player, "@@tuxing")
      room:changeMaxHp(player, -4)
    end
  end,
})

tuxing:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@tuxing") > 0
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

return tuxing
