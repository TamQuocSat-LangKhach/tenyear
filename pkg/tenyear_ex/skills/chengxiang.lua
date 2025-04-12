local chengxiang = fk.CreateSkill {
  name = "ty_ex__chengxiang",
}

Fk:loadTranslationTable{
  ["ty_ex__chengxiang"] = "称象",
  [":ty_ex__chengxiang"] = "当你受到伤害后，你可以亮出牌堆顶的四张牌，获得其中任意张点数之和不大于13的牌。若获得的牌点数之和为13，"..
  "你复原武将牌。",

  ["$ty_ex__chengxiang1"] = "冲有一法，可得其重。",
  ["$ty_ex__chengxiang2"] = "待我细细算来。",
}

chengxiang:addEffect(fk.Damaged, {
  anim_type = "masochism",
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(4)
    room:turnOverCardsFromDrawPile(player, cards, chengxiang.name)
    local get = room:askToArrangeCards(player, {
      skill_name = chengxiang.name,
      card_map = {cards},
      prompt = "#chengxiang-choose",
      box_size = 0,
      max_limit = {4, 4},
      min_limit = {0, 1},
      poxi_type = "chengxiang",
      default_choice = {{}, {cards[1]}}
    })[2]
    room:moveCardTo(get, Player.Hand, player, fk.ReasonJustMove, chengxiang.name, nil, true, player)
    room:cleanProcessingArea(cards)
    if not player.dead then
      local n = 0
      for _, id in ipairs(get) do
        n = n + Fk:getCardById(id).number
      end
      if n == 13 then
        player:reset()
      end
    end
  end,
})

return chengxiang
