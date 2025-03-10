local ty_ex__chengxiang = fk.CreateSkill {
  name = "ty_ex__chengxiang"
}

Fk:loadTranslationTable{
  ['ty_ex__chengxiang'] = '称象',
  [':ty_ex__chengxiang'] = '当你受到伤害后，你可以亮出牌堆顶的四张牌，然后获得其中的任意张点数之和小于等于13的牌。若获得的牌点数之和为13，你复原武将牌。',
  ['$ty_ex__chengxiang1'] = '冲有一法，可得其重。',
  ['$ty_ex__chengxiang2'] = '待我细细算来。',
}

ty_ex__chengxiang:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and target:hasSkill(skill.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(4)
    room:moveCards({
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonPut,
      skillName = ty_ex__chengxiang.name,
      proposer = player.id,
    })
    local get = room:askToArrangeCards(player, {
      skill_name = ty_ex__chengxiang.name,
      card_map = {cards},
      prompt = "#chengxiang-choose",
      box_size = 0,
      max_limit = {4, 4},
      min_limit = {0, 1},
      pattern = ".",
      poxi_type = "chengxiang_count",
      default_choice = {{}, {cards[1]}}
    })[2]
    room:moveCardTo(get, Player.Hand, player, fk.ReasonJustMove, ty_ex__chengxiang.name, "", true, player.id)
    if not player.dead then
      local n = 0
      for _, id in ipairs(get) do
        n = n + Fk:getCardById(id).number
      end
      if n == 13 then
        player:reset()
      end
    end
    cards = table.filter(cards, function(id) return room:getCardArea(id) == Card.Processing end)
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
      })
    end
  end
})

return ty_ex__chengxiang
