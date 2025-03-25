local shiju = fk.CreateSkill {
  name = "shiju",
  attached_skill_name = "shiju&",
}

Fk:loadTranslationTable{
  ["shiju"] = "势举",
  [":shiju"] = "一名角色的出牌阶段限一次，其可以将一张牌交给你（若为你，则改为选择你的一张牌，若为你装备区里的牌你获得之），若此牌为装备牌，"..
  "你可以使用之，并令其攻击范围于此回合内+X（X为你装备区里的牌数），若替换了原有装备，你与其各摸两张牌。",

  ["#shiju_self"] = "势举：选择你的一张牌，若为装备牌则使用之并获得收益",
  ["#shiju-use"] = "势举：你可以使用%arg，令 %dest 增加攻击范围",
  ["@shiju-turn"] = "势举 范围+",

  ["$shiju1"] = "借力为己用，可攀青云直上。",
  ["$shiju2"] = "应势而动，事半而功倍。",
}

shiju:addEffect("active", {
  anim_type = "support",
  prompt = "#shiju_self",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(shiju.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local id = effect.cards[1]
    if table.contains(player:getCardIds("e"), id) then
      room:moveCardTo(effect.cards, Player.Hand, player, fk.ReasonPrey, shiju.name, nil, false, player)
    end
    if player.dead or not table.contains(player:getCardIds("h"), id) then return end

    local card = Fk:getCardById(id)
    if card.type ~= Card.TypeEquip or
      not player:canUseTo(card, player) or
      not room:askToSkillInvoke(player, {
        skill_name = shiju.name,
        prompt = "#shiju-use::"..player.id..":"..card:toLogString(),
      }) then return end
    local draw = not player:hasEmptyEquipSlot(card.sub_type)
    room:useCard({
      from = player,
      tos = {player},
      card = card,
    })
    if not player.dead then
      room:addPlayerMark(player, "@shiju-turn", #player:getCardIds("e"))
      if draw then
        player:drawCards(2, shiju.name)
        if not player.dead then
          player:drawCards(2, shiju.name)
        end
      end
    end
  end,
})

shiju:addEffect("atkrange", {
  correct_func = function (self, from, to)
    return from:getMark("@shiju-turn")
  end,
})

return shiju
