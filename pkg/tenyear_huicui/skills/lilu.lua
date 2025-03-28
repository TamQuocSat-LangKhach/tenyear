local lilu = fk.CreateSkill {
  name = "lilu",
}

Fk:loadTranslationTable{
  ["lilu"] = "礼赂",
  [":lilu"] = "摸牌阶段，你可以放弃摸牌，改为将手牌摸至体力上限（最多摸至5张），并将至少一张手牌交给一名其他角色；若你交出的牌数大于上次"..
  "以此法交出的牌数，你增加1点体力上限并回复1点体力。",

  ["#lilu-invoke"] = "礼赂：你可以放弃摸牌，改为将手牌摸至体力上限，然后将任意张手牌交给一名其他角色",
  ["@lilu"] = "礼赂",
  ["#lilu-give"] = "礼赂：将至少一张手牌交给一名其他角色，若大于%arg，你加1点体力上限并回复1点体力",

  ["$lilu1"] = "乱狱滋丰，以礼赂之。",
  ["$lilu2"] = "微薄之礼，聊表敬意！"
}

lilu:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lilu.name) and player.phase == Player.Draw
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = lilu.name,
      prompt = "#lilu-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.phase_end = true
    local n = math.min(player.maxHp, 5) - player:getHandcardNum()
    if n > 0 then
      player:drawCards(n, lilu.name)
      if player.dead or player:isKongcheng() then return end
    end
    if #room:getOtherPlayers(player, false) == 0 then return end
    local x = player:getMark("@lilu")
    local to, cards = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 999,
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      pattern = ".|.|.|hand",
      skill_name = lilu.name,
      prompt = "#lilu-give:::"..x,
      cancelable = false,
    })
    room:moveCardTo(cards, Card.PlayerHand, to[1], fk.ReasonGive, lilu.name, nil, false, player)
    if player.dead then return end
    room:setPlayerMark(player, "@lilu", #cards)
    if #cards > x then
      room:changeMaxHp(player, 1)
      if player:isAlive() and player:isWounded() then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = lilu.name,
        }
      end
    end
  end,
})

return lilu
