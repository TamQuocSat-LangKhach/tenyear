local choujue = fk.CreateSkill {
  name = "choujue",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["choujue"] = "仇决",
  [":choujue"] = "觉醒技，每名角色的回合结束时，若你的手牌数和体力值相差3或更多，你减1点体力上限并获得〖背水〗，然后修改〖膂力〗为"..
  "“每名其他角色的回合限一次（在自己的回合限两次）”。",

  ["$choujue1"] = "家仇未报，怎可独安？",
  ["$choujue2"] = "逆臣之军，不足畏惧！",
}

choujue:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(choujue.name) and player:usedSkillTimes(choujue.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return math.abs(player:getHandcardNum() - player.hp) > 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if player.dead then return end
    room:handleAddLoseSkills(player, "beishui")
  end,
})

return choujue
