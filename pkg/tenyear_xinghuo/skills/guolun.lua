local guolun = fk.CreateSkill {
  name = "guolun",
}

Fk:loadTranslationTable{
  ["guolun"] = "过论",
  [":guolun"] = "出牌阶段限一次，你可以展示一名其他角色的一张手牌，然后你可以展示一张手牌，交换这两张牌，展示牌点数小的角色摸一张牌。",

  ["#guolun"] = "过论：展示一名角色的一张手牌，然后你可以展示一张手牌与其交换",
  ["#guolun-card"] = "过论：你可以展示一张牌并交换双方的牌，点数小的角色摸一张牌（对方点数为%arg）",

  ["$guolun1"] = "品过是非，讨评好坏。",
  ["$guolun2"] = "若有天下太平时，必讨四海之内才。",
}

guolun:addEffect("active", {
  anim_type = "control",
  prompt = "#guolun",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(guolun.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local id1 = room:askToChooseCard(player, {
      target = target,
      flag = "h",
      skill_name = guolun.name
    })
    target:showCards(id1)
    if not target.dead and not player:isNude() and table.contains(target:getCardIds("h"), id1) then
      local n1 = Fk:getCardById(id1).number
      local card = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = guolun.name,
        cancelable = true,
        prompt = "#guolun-card:::"..n1
      })
      if #card > 0 then
        local id2 = card[1]
        player:showCards(id2)
        local n2 = Fk:getCardById(id2).number
        if player.dead or target.dead or
          not table.contains(player:getCardIds("h"), id2) or
          not table.contains(target:getCardIds("h"), id1) then return end
        room:swapCards(player, {
          {player, {id2}},
          {target, {id1}},
        }, guolun.name)
        if n2 > n1 and not target.dead then
          target:drawCards(1, guolun.name)
        elseif n1 > n2 and not player.dead then
          player:drawCards(1, guolun.name)
        end
      end
    end
  end,
})

return guolun
