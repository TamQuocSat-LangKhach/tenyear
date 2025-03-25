local mouli = fk.CreateSkill {
  name = "ty__mouli",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["ty__mouli"] = "谋立",
  [":ty__mouli"] = "觉醒技，回合结束时，若你因〖集筹〗给出的牌名不同的牌超过5种，你加1点体力上限并回复1点体力，获得〖自缚〗。",

  ["$ty__mouli1"] = "君上暗弱，以致受制于强臣。",
  ["$ty__mouli2"] = "吾闻楚王彪有智勇，可迎之于许都。",
}

mouli:addEffect(fk.TurnEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(mouli.name) and
      player:usedSkillTimes(mouli.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #player:getTableMark("@$jichouw") > 5
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if player.dead then return false end
    if player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = mouli.name,
      }
      if player.dead then return false end
    end
    room:handleAddLoseSkills(player, "ty__zifu")
  end,
})

return mouli
