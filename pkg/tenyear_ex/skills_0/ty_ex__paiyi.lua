local ty_ex__paiyi = fk.CreateSkill {
  name = "ty_ex__paiyi"
}

Fk:loadTranslationTable{
  ['ty_ex__paiyi'] = '排异',
  ['ty_ex__paiyi_draw'] = '摸牌',
  ['#ty_ex__paiyi_draw'] = '排异：令一名角色摸%arg张牌',
  ['#ty_ex__paiyi_damage'] = '排异：对至多%arg名角色各造成1点伤害',
  ['ty_ex__paiyi_damage'] = '伤害',
  [':ty_ex__paiyi'] = '出牌阶段各限一次，你可移去一张“权”并选择一项：1.令一名角色摸X张牌；2.对至多X名角色各造成1点伤害（X为“权”数且至少为1）。',
  ['$ty_ex__paiyi1'] = '蜀川三千里，皆由我一言决之!',
  ['$ty_ex__paiyi2'] = '顺我者，封侯拜将!，逆我者，斧钺加身!',
}

ty_ex__paiyi:addEffect('active', {
  name = "ty_ex__paiyi",
  anim_type = "control",
  expand_pile = "zhonghui_quan",
  card_num = 1,
  min_target_num = 1,
  max_target_num = function(self)
    return self.interaction.data == "ty_ex__paiyi_draw" and 1 or #self.player:getPile("zhonghui_quan") - 1
  end,
  prompt = function(self, player, selected_cards, selected_targets)
    if self.interaction.data == "ty_ex__paiyi_draw" then
      return "#ty_ex__paiyi_draw:::" .. (#player:getPile("zhonghui_quan") - 1)
    else
      return "#ty_ex__paiyi_damage:::" .. (#player:getPile("zhonghui_quan") - 1)
    end
  end,
  interaction = function(self, player)
    local choiceList = {}
    if player:getMark("ty_ex__paiyi_draw-phase") == 0 then
      table.insert(choiceList, "ty_ex__paiyi_draw")
    end
    if player:getMark("ty_ex__paiyi_damage-phase") == 0 then 
      table.insert(choiceList, "ty_ex__paiyi_damage")
    end
    return UI.ComboBox { choices = choiceList }
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 or (self.interaction.data == "ty_ex__paiyi_damage" and #selected < #player:getPile("zhonghui_quan") - 1)
  end,
  can_use = function(self, player)
    return #player:getPile("zhonghui_quan") > 0 and
      (player:getMark("ty_ex__paiyi_draw-phase") == 0 or player:getMark("ty_ex__paiyi_damage-phase") == 0)
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and player:getPileNameOfId(to_select) == "zhonghui_quan"
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:moveCards({
      from = player.id,
      ids = effect.cards,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
      skillName = ty_ex__paiyi.name,
    })
    room:setPlayerMark(player, self.interaction.data .. "-phase", 1)
    if self.interaction.data == "ty_ex__paiyi_draw" then
      local target = room:getPlayerById(effect.tos[1])
      if not target.dead then
        target:drawCards(math.max(#player:getPile("zhonghui_quan"), 1), ty_ex__paiyi.name)
      end
    else
      local tos = table.simpleClone(effect.tos)
      room:sortPlayersByAction(tos)
      for _, id in ipairs(tos) do
        local p = room:getPlayerById(id)
        if not p.dead then
          room:damage{
            from = player,
            to = p,
            damage = 1,
            skillName = ty_ex__paiyi.name
          }
        end
      end
    end
  end,
})

return ty_ex__paiyi
