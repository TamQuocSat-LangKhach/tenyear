local guanyue = fk.CreateSkill {
  name = "guanyue"
}

Fk:loadTranslationTable{
  ['guanyue'] = '观月',
  ['prey'] = '获得',
  [':guanyue'] = '结束阶段，你可以观看牌堆顶的两张牌，然后获得其中一张，将另一张置于牌堆顶。',
}

guanyue:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(guanyue.name) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local result = room:askToGuanxing(player, {
      cards = room:getNCards(2),
      top_limit = {1, 2},
      bottom_limit = {1, 1},
      skill_name = guanyue.name,
      skip = true,
      area_names = {"Top", "prey"}
    })
    if #result.top > 0 then
      room:sendLog{
        type = "#GuanxingResult",
        from = player.id,
        arg = 1,
        arg2 = 0,
      }
    end
    if #result.bottom > 0 then
      room:obtainCard(player.id, result.bottom[1], false, fk.ReasonJustMove)
    end
  end,
})

return guanyue
