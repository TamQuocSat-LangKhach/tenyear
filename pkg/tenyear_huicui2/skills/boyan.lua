local boyan = fk.CreateSkill {
  name = "boyan"
}

Fk:loadTranslationTable{
  ['boyan'] = '驳言',
  ['@@boyan-turn'] = '驳言',
  [':boyan'] = '出牌阶段限一次，你可以选择一名其他角色，该角色将手牌摸至体力上限（最多摸至5张），其本回合不能使用或打出手牌。',
  ['$boyan1'] = '黑白颠倒，汝言谬矣！',
  ['$boyan2'] = '魏王高论，实为无知之言。',
}

boyan:addEffect('active', {
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(boyan.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local n = math.min(target.maxHp, 5) - target:getHandcardNum()
    if n > 0 then
      target:drawCards(n, boyan.name)
    end
    room:setPlayerMark(target, "@@boyan-turn", 1)
  end,
})

boyan:addEffect('prohibit', {
  name = "#boyan_prohibit",
  prohibit_use = function(self, player, card)
    if player:getMark("@@boyan-turn") > 0 then
      local cardlist = Card:getIdList(card)
      return #cardlist > 0 and table.every(cardlist, function(id)
        return table.contains(player:getCardIds(Player.Hand), id)
      end)
    end
  end,
  prohibit_response = function(self, player, card)
    if player:getMark("@@boyan-turn") > 0 then
      local cardlist = Card:getIdList(card)
      return #cardlist > 0 and table.every(cardlist, function(id)
        return table.contains(player:getCardIds(Player.Hand), id)
      end)
    end
  end,
})

return boyan
