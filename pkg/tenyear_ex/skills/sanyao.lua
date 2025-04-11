local sanyao = fk.CreateSkill {
  name = "ty_ex__sanyao",
}

Fk:loadTranslationTable{
  ["ty_ex__sany__sanyao"] = "散谣",
  [":ty_ex__sanyao"] = "出牌阶段限一次，你可以弃置任意张牌，然后对体力值最多的等量名其他角色造成1点伤害。",

  ["#ty_ex__sanyao"] = "散谣：弃置任意张牌，对等量名体力值最多的角色造成伤害",

  ["$ty_ex__sanyao1"] = "蜚短流长，以基所毁，敌军自溃。",
  ["$ty_ex__sanyao2"] = "群言谣混，积是成非！",
}

sanyao:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ty_ex__sanyao",
  min_card_num = 1,
  min_target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(sanyao.name) == 0
  end,
  card_filter = function (self, player, to_select, selected)
    return not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected < #selected_cards and to_select ~= player and
      table.every(Fk:currentRoom().alive_players, function(p)
        return p.hp <= to_select.hp
      end)
  end,
  feasible = function(self, player, selected, selected_cards)
    return #selected == #selected_cards and #selected > 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:throwCard(effect.cards, sanyao.name, player, player)
    local targets = table.simpleClone(effect.tos)
    room:sortByAction(targets)
    for _, p in ipairs(targets) do
      if not p.dead then
        room:damage{
          from = player,
          to = p,
          damage = 1,
          skill_name = sanyao.name,
        }
      end
    end
  end,
})

return sanyao
