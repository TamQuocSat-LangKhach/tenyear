local qianlong = fk.CreateSkill {
  name = "qianlong"
}

Fk:loadTranslationTable{
  ['qianlong'] = '潜龙',
  [':qianlong'] = '当你受到伤害后，你可以展示牌堆顶的三张牌并获得其中至多X张牌（X为你已损失的体力值），然后将剩余的牌置于牌堆底。',
  ['$qianlong1'] = '鸟栖于林，龙潜于渊。',
  ['$qianlong2'] = '游鱼惊钓，潜龙飞天。',
}

qianlong:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and target:hasSkill(skill.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = U.turnOverCardsFromDrawPile(player, 3, skill.name)
    local result = room:askToGuanxing(player, {
      cards = cards,
      bottom_limit = {0, 3},
      top_limit = {0, player:getLostHp()},
      skill_name = skill.name,
      skip = true,
      area_names = {"Bottom", "toObtain"}
    })
    if #result.bottom > 0 then
      room:moveCardTo(result.bottom, Player.Hand, player, fk.ReasonJustMove, skill.name, "", true, player.id)
    end
    U.returnCardsToDrawPile(player, result.top, skill.name, false, false)
  end,
})

return qianlong
