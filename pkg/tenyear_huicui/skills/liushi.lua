local liushi = fk.CreateSkill {
  name = "liushi",
}

Fk:loadTranslationTable{
  ["liushi"] = "流矢",
  [":liushi"] = "出牌阶段，你可以将一张<font color='red'>♥</font>牌置于牌堆顶，视为对一名角色使用一张【杀】（无距离次数限制）。"..
  "受到此【杀】伤害的角色手牌上限-1。",

  ["#liushi"] = "流矢：将一张<font color='red'>♥</font>牌置于牌堆顶，视为使用无距离次数限制的【杀】",
  ["@liushi"] = "流矢",

  ["$liushi1"] = "就你叫夏侯惇？",
  ["$liushi2"] = "兀那贼将，且吃我一箭！",
}

liushi:addEffect("active", {
  anim_type = "offensive",
  prompt = "#liushi",
  card_num = 1,
  target_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).suit == Card.Heart
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and not player:isProhibited(to_select, Fk:cloneCard("slash"))
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:moveCards({
      ids = effect.cards,
      from = player,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonPut,
      skillName = liushi.name,
      moveVisible = true,
    })
    if target.dead then return end
    local use = room:useVirtualCard("slash", nil, player, target, liushi.name, true)
    if use and use.damageDealt then
      for _, p in ipairs(room.alive_players) do
        if use.damageDealt[p] then
          room:addPlayerMark(target, "@liushi", 1)
        end
      end
    end
  end,
})

liushi:addEffect("maxcards", {
  correct_func = function(self, player)
    return -player:getMark("@liushi")
  end,
})

return liushi
