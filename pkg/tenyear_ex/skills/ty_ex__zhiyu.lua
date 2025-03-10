local ty_ex__zhiyu = fk.CreateSkill {
  name = "ty_ex__zhiyu"
}

Fk:loadTranslationTable{
  ['ty_ex__zhiyu'] = '智愚',
  [':ty_ex__zhiyu'] = '当你受到伤害后，你可以摸一张牌，然后展示所有手牌且伤害来源弃置一张手牌。若你以此法展示的牌颜色均相同，你获得其弃置的牌且下回合奇策发动次数+1。',
  ['$ty_ex__zhiyu1'] = '经达权变，大智若愚。',
  ['$ty_ex__zhiyu2'] = '微末伎俩，让阁下见笑了。',
}

ty_ex__zhiyu:addEffect(fk.Damaged, {
  on_use = function(self, event, target, player)
    local room = player.room
    player:drawCards(1, skill.name)
    local cards = player:getCardIds("h")
    player:showCards(cards)
    local throw
    if data.from and not data.from.dead and not data.from:isKongcheng() then
      throw = room:askToDiscard(data.from, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = skill.name,
        cancelable = false,
      })[1]
    end
    if not player.dead and table.every(cards, function(id) return #cards == 0 or Fk:getCardById(id).color == Fk:getCardById(cards[1]).color end) then
      if throw and room:getCardArea(throw) == Card.DiscardPile then
        room:obtainCard(player, throw, true, fk.ReasonPrey)
      end
      room:addPlayerMark(player, "ty_ex__zhiyu")
    end
  end,
})

ty_ex__zhiyu:addEffect({fk.TurnStart, fk.AfterSkillEffect}, {
  can_refresh = function (skill, event, target, player, data)
    if event == fk.TurnStart then
      return player == target and player:getMark("ty_ex__zhiyu") > 0
    else
      return player == target and player:getMark("ty_ex__zhiyu-turn") > 0 and data.name == "qice"
    end
  end,
  on_refresh = function (skill, event, target, player)
    local room = player.room
    if event == fk.TurnStart then
      room:setPlayerMark(player, "ty_ex__zhiyu-turn", player:getMark("ty_ex__zhiyu"))
      room:setPlayerMark(player, "ty_ex__zhiyu", 0)
    else
      room:removePlayerMark(player, "ty_ex__zhiyu-turn")
      player:addSkillUseHistory("qice", -1)
    end
  end,
})

return ty_ex__zhiyu
