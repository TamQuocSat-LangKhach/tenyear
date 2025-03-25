local shiju_active = fk.CreateSkill {
  name = "shiju&",
}

Fk:loadTranslationTable{
  ["shiju&"] = "势举",
  [":shiju&"] = "出牌阶段限一次，你可以将一张牌交给谋蒋济，若此牌为装备牌，其可以使用之，并令你攻击范围于此回合内+X（X为其装备区里的牌数），"..
  "若替换了原有装备，你与其各摸两张牌。",

  ["#shiju&"] = "势举：将一张牌交给“势举”角色，若为装备，其可以使用之并令你攻击范围增加，若替换原装备则双方摸牌",
}

shiju_active:addEffect("active", {
  mute = true,
  prompt = "#shiju&",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return table.find(Fk:currentRoom().alive_players, function(p)
      return p ~= player and p:hasSkill("shiju") and not table.contains(player:getTableMark("shiju_targets-phase"), p.id)
    end)
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and to_select:hasSkill("shiju") and
      not table.contains(player:getTableMark("shiju_targets-phase"), to_select.id)
  end,

  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    target:broadcastSkillInvoke("shiju")
    room:addTableMarkIfNeed(player, "shiju_targets-phase", target.id)
    local id = effect.cards[1]
    room:moveCardTo(id, Player.Hand, target, fk.ReasonGive, "shiju", nil, false, player)
    if target.dead or not table.contains(target:getCardIds("h"), id) then return end

    local card = Fk:getCardById(id)
    if card.type ~= Card.TypeEquip or
      not target:canUseTo(card, target) or
      not room:askToSkillInvoke(target, {
        skill_name = "shiju",
        prompt = "#shiju_self-use::"..player.id..":"..card:toLogString(),
      }) then return end
    local draw = not target:hasEmptyEquipSlot(card.sub_type)
    room:useCard({
      from = target,
      tos = {target},
      card = card,
    })
    if not target.dead then
      if not player.dead then
        room:addPlayerMark(player, "@shiju-turn", #target:getCardIds("e"))
      end
      if draw then
        if not target.dead then
          target:drawCards(2, "shiju")
        end
        if not player.dead then
          player:drawCards(2, "shiju")
        end
      end
    end
  end,
})

return shiju_active
