local lilu = fk.CreateSkill {
  name = "lilu"
}

Fk:loadTranslationTable{
  ['lilu'] = '礼赂',
  ['#lilu-invoke'] = '礼赂：你可以放弃摸牌，改为将手牌摸至体力上限，然后将至少一张手牌交给一名其他角色',
  ['@lilu'] = '礼赂',
  ['#lilu-card'] = '礼赂：将至少一张手牌交给一名其他角色，若大于%arg，你加1点体力上限并回复1点体力',
  [':lilu'] = '摸牌阶段，你可以放弃摸牌，改为将手牌摸至体力上限（最多摸至5张），并将至少一张手牌交给一名其他角色；若你交出的牌数大于上次以此法交出的牌数，你增加1点体力上限并回复1点体力。',
  ['$lilu1'] = '乱狱滋丰，以礼赂之。',
  ['$lilu2'] = '微薄之礼，聊表敬意！'
}

lilu:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(lilu.name) and player.phase == Player.Draw
  end,
  on_cost = function(self, event, target, player)
    return player.room:askToSkillInvoke(player, { skill_name = lilu.name, prompt = "#lilu-invoke" })
  end,
  on_use = function(self, event, target, player)
    local n = math.min(player.maxHp, 5) - player:getHandcardNum()
    if n > 0 then
      player:drawCards(n, lilu.name)
      if player.dead or player:isKongcheng() then return true end
    end
    local room = player.room
    local targets = room:getOtherPlayers(player, false)
    if #targets == 0 then return true end
    local x = player:getMark("@lilu")
    local tos, cards = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 999,
      targets = table.map(targets, Util.IdMapper),
      min_target_num = 1,
      max_target_num = 1,
      pattern = ".|.|.|hand",
      prompt = "#lilu-card:::" .. tostring(x),
      skill_name = lilu.name,
      cancelable = false,
      will_throw = true
    })
    local to = room:getPlayerById(tos[1])
    room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonGive, lilu.name, nil, false, player.id)
    if player.dead then return true end
    room:setPlayerMark(player, "@lilu", #cards)
    if #cards > x then
      room:changeMaxHp(player, 1)
      if player:isAlive() and player:isWounded() then
        room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = lilu.name
        })
      end
    end
    return true
  end,
})

return lilu
