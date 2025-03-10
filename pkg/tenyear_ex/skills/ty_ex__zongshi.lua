local ty_ex__zongshi = fk.CreateSkill {
  name = "ty_ex__zongshi"
}

Fk:loadTranslationTable{
  ['ty_ex__zongshi'] = '宗室',
  [':ty_ex__zongshi'] = '锁定技，①你的手牌上限+X（X为全场势力数）；<br>②你的回合外，若你的手牌数不小于手牌上限，延时锦囊牌和无色牌对你无效。',
  ['$ty_ex__zongshi1'] = '汉室江山，气数未尽！',
  ['$ty_ex__zongshi2'] = '我刘氏一族，皆海内之俊杰也！',
}

ty_ex__zongshi:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player == target and player.phase == Player.NotActive and player:hasSkill(ty_ex__zongshi) and
      (data.card.color == Card.NoColor or data.card.sub_type == Card.SubtypeDelayedTrick) and
      player:getHandcardNum() >= player:getMaxCards()
  end,
  on_use = function(self, event, target, player, data)
    table.insertIfNeed(data.nullifiedTargets, player.id)
  end
})

ty_ex__zongshi:addEffect('maxcards', {
  name = "#ty_ex__zongshi_maxcards",
  correct_func = function(self, player)
    if player:hasSkill(ty_ex__zongshi) then
      local kingdoms = {}
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        table.insertIfNeed(kingdoms, p.kingdom)
      end
      return #kingdoms
    end
    return 0
  end,
})

return ty_ex__zongshi
