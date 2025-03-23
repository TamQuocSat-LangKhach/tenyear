local jiexing = fk.CreateSkill {
  name = "jiexing"
}

Fk:loadTranslationTable{
  ['jiexing'] = '节行',
  ['@@jiexing-inhand-turn'] = '节行',
  [':jiexing'] = '当你的体力值变化后，你可以摸一张牌，此牌于本回合内不计入手牌上限。',
  ['$jiexing1'] = '女子有节，安能贰其行？',
  ['$jiexing2'] = '坐受雨露，皆为君恩。',
}

jiexing:addEffect(fk.HpChanged, {
  anim_type = "drawcard",
  on_use = function(self, event, target, player, data)
    player:drawCards(1, jiexing.name, nil, "@@jiexing-inhand-turn")
  end,
})

local jiexing_maxcards_spec = {
  exclude_from = function(self, player, card)
    return card:getMark("@@jiexing-inhand-turn") > 0
  end,
}

jiexing:addEffect('maxcards', jiexing_maxcards_spec)

return jiexing
