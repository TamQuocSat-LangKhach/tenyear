local zhiyu = fk.CreateSkill {
  name = "ty_ex__zhiyu",
}

Fk:loadTranslationTable{
  ["ty_ex__zhiyu"] = "智愚",
  [":ty_ex__zhiyu"] = "当你受到伤害后，你可以摸一张牌，然后展示所有手牌且伤害来源弃置一张手牌。若你的手牌颜色均相同，你获得其弃置的牌且"..
  "下回合〖奇策〗可发动次数+1。",

  ["$ty_ex__zhiyu1"] = "经达权变，大智若愚。",
  ["$ty_ex__zhiyu2"] = "微末伎俩，让阁下见笑了。",
}

zhiyu:addEffect(fk.Damaged, {
  anim_type = "masochism",
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, zhiyu.name)
    if player.dead then return end
    local cards = player:getCardIds("h")
    if #cards > 0 then
      player:showCards(cards)
    end
    local card
    if data.from and not data.from.dead and not data.from:isKongcheng() then
      card = room:askToDiscard(data.from, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = zhiyu.name,
        cancelable = false,
      })
    end
    if player.dead then return end
    if #cards == 0 or
      table.every(cards, function(id)
        return Fk:getCardById(id).color == Fk:getCardById(cards[1]).color
      end) then
      room:addPlayerMark(player, zhiyu.name, 1)
      if card and #card > 0 and table.contains(room.discard_pile, card[1]) then
        room:obtainCard(player, card, true, fk.ReasonJustMove, player, zhiyu.name)
      end
    end
  end,
})

zhiyu:addEffect(fk.TurnStart, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("ty_ex__zhiyu") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "ty_ex__zhiyu-turn", player:getMark("ty_ex__zhiyu"))
    room:setPlayerMark(player, "ty_ex__zhiyu", 0)
  end,
})

zhiyu:addEffect(fk.AfterSkillEffect, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("ty_ex__zhiyu-turn") > 0 and data.skill.name == "qice"
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(player, "ty_ex__zhiyu-turn")
    player:addSkillUseHistory("qice", -1)
  end,
})

return zhiyu
