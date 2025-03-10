local qiusuo = fk.CreateSkill {
  name = "qiusuo"
}

Fk:loadTranslationTable{
  ['qiusuo'] = '求索',
  [':qiusuo'] = '当你造成或受到伤害后，你可以从牌堆或弃牌堆中随机获得一张【铁索连环】。',
  ['$qiusuo1'] = '驾八龙之婉婉兮，载云旗之委蛇。',
  ['$qiusuo2'] = '路漫漫其修远兮，吾将上下而求索。',
}

qiusuo:addEffect(fk.Damage, {
  anim_type = "drawcard",
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ironChain = room:getCardsFromPileByRule("iron_chain", 1, "allPiles")
    if #ironChain > 0 then
      room:obtainCard(player, ironChain, true, fk.ReasonPrey, player.id, qiusuo.name)
    end
  end,
})

qiusuo:addEffect(fk.Damaged, {
  anim_type = "drawcard",
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ironChain = room:getCardsFromPileByRule("iron_chain", 1, "allPiles")
    if #ironChain > 0 then
      room:obtainCard(player, ironChain, true, fk.ReasonPrey, player.id, qiusuo.name)
    end
  end,
})

return qiusuo
