local fuli = fk.CreateSkill {
  name = "ty_ex__fuli"
}

Fk:loadTranslationTable{
  ['ty_ex__fuli'] = '伏枥',
  [':ty_ex__fuli'] = '限定技，当你处于濒死状态时，你可以将体力回复至X点且手牌摸至X张（X为全场势力数），然后〖当先〗中失去体力的效果改为可选。若X不小于3，你翻面。',
  ['$ty_ex__fuli1'] = '匡扶汉室，死而后已！',
  ['$ty_ex__fuli2'] = '一息尚存，不忘君恩！',
}

fuli:addEffect(fk.AskForPeaches, {
  anim_type = "defensive",
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fuli.name) and player.dying and player:usedSkillTimes(fuli.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, fuli.name, 1)
    local kingdoms = {}
    for _, p in ipairs(room:getAlivePlayers()) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    room:recover({
      who = player,
      num = math.min(#kingdoms, player.maxHp) - player.hp,
      recoverBy = player,
      skillName = fuli.name
    })
    if player:getHandcardNum() < #kingdoms then
      player:drawCards(#kingdoms - player:getHandcardNum())
    end
    if #kingdoms > 2 then
      player:turnOver()
    end
  end,
})

return fuli
