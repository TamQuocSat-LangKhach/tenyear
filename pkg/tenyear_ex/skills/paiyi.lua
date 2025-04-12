local paiyi = fk.CreateSkill {
  name = "ty_ex__paiyi",
}

Fk:loadTranslationTable{
  ["ty_ex__paiyi"] = "排异",
  [":ty_ex__paiyi"] = "出牌阶段各限一次，你可以移去一张“权”并选择一项：1.令一名角色摸X张牌；2.对至多X名角色各造成1点伤害"..
  "（X为“权”数且至少为1）。",

  ["#ty_ex__paiyi_draw"] = "排异：移去一张“权”，令一名角色摸%arg张牌",
  ["#ty_ex__paiyi_damage"] = "排异：移去一张“权”，对至多%arg名角色造成伤害",

  ["$ty_ex__paiyi1"] = "蜀川三千里，皆由我一言决之。",
  ["$ty_ex__paiyi2"] = "顺我者封侯拜将，逆我者斧钺加身。",
}

paiyi:addEffect("active", {
  anim_type = "offensive",
  expand_pile = "zhonghui_quan",
  prompt = function(self, player, selected_cards, selected_targets)
    local n = math.max(#player:getPile("zhonghui_quan") - 1, 1)
    if self.interaction.data == "draw_card" then
      return "#ty_ex__paiyi_draw:::"..n
    else
      return "#ty_ex__paiyi_damage:::"..n
    end
  end,
  card_num = 1,
  min_target_num = 1,
  max_target_num = function(self, player)
    if self.interaction.data == "draw_card" then
      return 1
    else
      return math.max(#player:getPile("zhonghui_quan") - 1, 1)
    end
  end,
  interaction = function(self, player)
    local choices = {}
    if player:getMark("ty_ex__paiyi_draw-phase") == 0 then
      table.insert(choices, "draw_card")
    end
    if player:getMark("ty_ex__paiyi_damage-phase") == 0 then
      table.insert(choices, "Damage")
    end
    return UI.ComboBox { choices = choices, all_choices = {"draw_card", "Damage"} }
  end,
  can_use = function(self, player)
    return #player:getPile("zhonghui_quan") > 0 and
      (player:getMark("ty_ex__paiyi_draw-phase") == 0 or player:getMark("ty_ex__paiyi_damage-phase") == 0)
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getPile("zhonghui_quan"), to_select)
  end,
  target_filter = function(self, player, to_select, selected)
    if self.interaction.data == "draw_card" then
      return #selected == 0
    else
      return #selected < math.max(#player:getPile("zhonghui_quan") - 1, 1)
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:moveCards({
      from = player,
      ids = effect.cards,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
      skillName = paiyi.name,
    })
    if player.dead then return end
    if self.interaction.data == "draw_card" then
      room:setPlayerMark(player, "ty_ex__paiyi_draw-phase", 1)
      local target = effect.tos[1]
      if not target.dead then
        target:drawCards(math.max(#player:getPile("zhonghui_quan"), 1), paiyi.name)
      end
    else
      room:setPlayerMark(player, "ty_ex__paiyi_damage-phase", 1)
      local tos = table.simpleClone(effect.tos)
      room:sortByAction(tos)
      for _, p in ipairs(tos) do
        if not p.dead then
          room:damage{
            from = player,
            to = p,
            damage = 1,
            skillName = paiyi.name,
          }
        end
      end
    end
  end,
})

return paiyi
