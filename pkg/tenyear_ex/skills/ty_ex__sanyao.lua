local ty_ex__sanyao = fk.CreateSkill {
  name = "ty_ex__sanyao"
}

Fk:loadTranslationTable{
  ['ty_ex__sany__sanyao'] = '散谣',
  ['#ty_ex__sanyao'] = '散谣：弃置任意张牌，对等量名体力值最多的其他角色各造成1点伤害',
  [':ty_ex__sanyao'] = '出牌阶段限一次，你可以弃置任意张牌，然后对体力值最多的等量名其他角色造成1点伤害。',
  ['$ty_ex__sanyao1'] = '蜚短流长，以基所毁，敌军自溃。',
  ['$ty_ex__sanyao2'] = '群言谣混，积是成非！',
}

ty_ex__sanyao:addEffect('active', {
  anim_type = "offensive",
  min_card_num = 1,
  min_target_num = 1,
  prompt = "#ty_ex__sanyao",
  can_use = function(self, player)
    return player:usedSkillTimes(ty_ex__sanyao.name) == 0 and not player:isNude()
  end,
  card_filter = function (self, player, to_select, selected)
    return not player:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected < #selected_cards then
      local target = Fk:currentRoom():getPlayerById(to_select)
      return table.every(Fk:currentRoom().alive_players, function(p) return p.hp <= target.hp end)
    end
  end,
  feasible = function(self, player, selected, selected_cards)
    return #selected == #selected_cards
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, ty_ex__sanyao.name, player, player)
    local targets = table.simpleClone(effect.tos)
    room:sortPlayersByAction(targets)
    for _, id in ipairs(targets) do
      local p = room:getPlayerById(id)
      if not p.dead then
        room:damage{
          from = player,
          to = p,
          num = 1,
          skill_name = ty_ex__sanyao.name,
        }
      end
    end
  end
})

return ty_ex__sanyao
