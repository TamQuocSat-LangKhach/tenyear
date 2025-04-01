local nuchen = fk.CreateSkill {
  name = "nuchen",
}

Fk:loadTranslationTable{
  ["nuchen"] = "怒嗔",
  [":nuchen"] = "出牌阶段限一次，你可以展示一名其他角色的一张手牌，然后你选择一项：1.弃置任意张相同花色的牌，对其造成等量的伤害；"..
  "2.获得其手牌中所有此花色的牌。",

  ["#nuchen"] = "怒嗔：展示一名角色一张手牌，然后选择弃置同花色牌对其造成伤害或获得其手牌",
  ["#nuchen-card"] = "怒嗔：弃置任意张%arg牌对 %dest 造成等量伤害，或点“取消”获得其全部%arg手牌",

  ["$nuchen1"] = "触关某之逆鳞者，杀无赦！",
  ["$nuchen2"] = "天下碌碌之辈，安敢小觑关某？！",
}

nuchen:addEffect("active", {
  anim_type = "offensive",
  prompt = "#nuchen",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(nuchen.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local card = room:askToChooseCard(player, {
      target = target,
      flag = "h",
      skill_name = nuchen.name,
    })
    target:showCards(card)
    local suit = Fk:getCardById(card):getSuitString()
    if player.dead or suit == "nosuit" then return end
    local cards = room:askToDiscard(player, {
      min_num = 1,
      max_num = 999,
      include_equip = true,
      skill_name = nuchen.name,
      cancelable = true,
      pattern = ".|.|"..suit,
      prompt = "#nuchen-card::"..target.id..":"..suit,
    })
    if target.dead then return end
    if #cards > 0 then
      room:damage{
        from = player,
        to = target,
        damage = #cards,
        skillName = nuchen.name,
      }
    elseif not player.dead then
      local get = table.filter(target:getCardIds("h"), function(id)
        return Fk:getCardById(id):getSuitString() == suit
      end)
      room:moveCardTo(get, Player.Hand, player, fk.ReasonPrey, nuchen.name, nil, false, player)
    end
  end,
})

return nuchen
