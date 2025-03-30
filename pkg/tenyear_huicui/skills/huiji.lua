local huiji = fk.CreateSkill {
  name = "huiji",
}

Fk:loadTranslationTable{
  ["huiji"] = "惠济",
  [":huiji"] = "出牌阶段限一次，你可以令一名角色摸两张牌或使用牌堆中的一张随机装备牌。然后若其手牌数不小于存活角色数，其视为使用一张【五谷丰登】"..
  "（改为从该角色的手牌中挑选）。",

  ["#huiji"] = "惠济：令一名角色执行一项，然后若其手牌数不小于存活角色数，视为使用一张从其手牌挑选牌的【五谷丰登】。",
  ["huiji_equip"] = "使用装备",

  ["$huiji1"] = "云鬓释远，彩衣婀娜。",
  ["$huiji2"] = "明眸善睐，瑰姿艳逸。",
}

huiji:addEffect("active", {
  anim_type = "control",
  prompt = "#huiji",
  target_num = 1,
  card_num = 0,
  interaction =  UI.ComboBox{ choices = {"draw2", "huiji_equip"} },
  can_use = function(self, player)
    return player:usedSkillTimes(huiji.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    if self.interaction.data == "draw2" then
      target:drawCards(2, huiji.name)
    else
      local cards = {}
      for i = 1, #room.draw_pile do
        local card = Fk:getCardById(room.draw_pile[i])
        if card.type == Card.TypeEquip and target:canUseTo(card, target) then
          table.insertIfNeed(cards, card)
        end
      end
      if #cards > 0 then
        room:useCard{
          from = target,
          tos = {target},
          card = table.random(cards),
        }
      end
    end
    if target.dead or target:getHandcardNum() < #room.alive_players then return end
    local card = Fk:cloneCard("amazing_grace")
    card.skillName = huiji.name
    if target:prohibitUse(card) then return end
    local targets = table.filter(room.alive_players, function (p)
      return not target:isProhibited(p, card)
    end)
    if #targets == 0 then return end
    room:useCard{
      from = target,
      tos = targets,
      card = card,
      extra_data = {
        orig_cards = target:getCardIds("h"),
      }
    }
  end,
})

return huiji
