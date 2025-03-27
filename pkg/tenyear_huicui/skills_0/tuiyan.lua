local tuiyan = fk.CreateSkill {
  name = "tuiyan"
}

Fk:loadTranslationTable{
  ['tuiyan'] = '推演',
  [':tuiyan'] = '出牌阶段开始时，你可以观看牌堆顶的三张牌。',
  ['$tuiyan1'] = '鸟语略知，万物略懂。',
  ['$tuiyan2'] = '玄妙之舒巧，推微而知晓。',
}

tuiyan:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tuiyan.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    U.viewCards(player, player.room:getNCards(3), tuiyan.name)
  end,
})

return tuiyan
