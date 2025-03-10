local zhuangrong = fk.CreateSkill {
  name = "zhuangrong"
}

Fk:loadTranslationTable{
  ['zhuangrong'] = '妆戎',
  [':zhuangrong'] = '觉醒技，一名角色的回合结束时，若你的手牌数或体力值为1，你减1点体力上限并将体力值回复至体力上限，然后将手牌摸至体力上限。若如此做，你获得技能〖神威〗和〖无双〗。',
  ['$zhuangrong1'] = '锋镝鸣手中，锐戟映秋霜。',
  ['$zhuangrong2'] = '红妆非我愿，学武觅封侯。',
}

zhuangrong:addEffect(fk.TurnEnd, {
  frequency = Skill.Wake,
  can_trigger = function(self, event, target, player)
    return player:hasSkill(zhuangrong) and player:usedSkillTimes(zhuangrong.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player)
    return player:getHandcardNum() == 1 or player.hp == 1
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:changeMaxHp(player, -1)
    if player:isWounded() then
      room:recover({
        who = player,
        num = player:getLostHp(),
        recoverBy = player,
        skillName = zhuangrong.name
      })
    end
    local n = player.maxHp - #player.player_cards[Player.Hand]
    if n > 0 then
      player:drawCards(n, zhuangrong.name)
    end
    room:handleAddLoseSkills(player, "shenwei|wushuang", nil, true, false)
  end,
})

return zhuangrong
