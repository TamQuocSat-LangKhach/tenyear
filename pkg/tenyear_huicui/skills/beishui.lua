local beishui = fk.CreateSkill {
  name = "beishui",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["beishui"] = "背水",
  [":beishui"] = "觉醒技，准备阶段，若你的手牌数或体力值小于2，你减1点体力上限并获得〖清剿〗，然后修改〖膂力〗为“当你造成或受到伤害后”。",

  ["$beishui1"] = "某若退却半步，诸将可立斩之！",
  ["$beishui2"] = "效淮阴之举，力敌数千！"
}

beishui:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(beishui.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(beishui.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:getHandcardNum() < 2 or player.hp < 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if player.dead then return end
    room:handleAddLoseSkills(player, "qingjiao")
  end
})

return beishui
