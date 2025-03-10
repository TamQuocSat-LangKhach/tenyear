local zhuili = fk.CreateSkill {
  name = "zhuili"
}

Fk:loadTranslationTable{
  ['zhuili'] = '惴栗',
  ['piaoping'] = '漂萍',
  ['tuoxian'] = '托献',
  [':zhuili'] = '锁定技，当你成为其他角色使用黑色牌的目标后，若此时〖漂萍〗状态为：阳，令〖托献〗可使用次数+1，然后若〖托献〗可使用次数超过3，此技能本回合失效；阴，令〖漂萍〗状态转换为阳。',
  ['$zhuili1'] = '近况艰难，何不忧愁？',
  ['$zhuili2'] = '形势如此，惴惕难当。',
}

zhuili:addEffect(fk.TargetConfirmed, {
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhuili) and data.card.color == Card.Black and data.from ~= player.id and
      player:hasSkill(piaoping, true) and player:getMark("zhuili_invalid-turn") == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getSwitchSkillState("piaoping", false) == fk.SwitchYang then
      room:addPlayerMark(player, "tuoxian", 1)
      if player:getMark("tuoxian") - player:usedSkillTimes("tuoxian", Player.HistoryGame) > 2 then
        room:setPlayerMark(player, "zhuili_invalid-turn", 1)
      end
    else
      room:setPlayerMark(player, MarkEnum.SwithSkillPreName.."piaoping", fk.SwitchYang)
      player:setSkillUseHistory("piaoping", player:usedSkillTimes("piaoping", Player.HistoryTurn), Player.HistoryTurn)
    end
  end,
})

return zhuili
