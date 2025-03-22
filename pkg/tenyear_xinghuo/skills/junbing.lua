local junbing = fk.CreateSkill {
  name = "ty_ex__junbing",
}

Fk:loadTranslationTable{
  ["ty_ex__junbing"] = "郡兵",
  [":ty_ex__junbing"] = "一名角色的结束阶段，若其手牌数小于体力值，该角色可以摸一张牌并将所有手牌交给你，然后你可以将等量的牌交给其。",

  ["#ty_ex__junbing-self"] = "郡兵：你可以摸一张牌",
  ["#ty_ex__junbing-invoke"] = "郡兵：你可以发动 %src 的“郡兵”，摸一张牌，然后与其交换手牌",
  ["#ty_ex__junbing-give"] = "郡兵：你可以将%arg张牌交给 %dest",

  ["$ty_ex__junbing1"] = "",
  ["$ty_ex__junbing2"] = "",
}

junbing:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(junbing.name) and target.phase == Player.Finish and
      target:getHandcardNum() < target.hp and not target.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(target, {
      skill_name = junbing.name,
      prompt = target == player and "#ty_ex__junbing-self" or "#ty_ex__junbing-invoke:"..player.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    target:drawCards(1, junbing.name)
    if target == player or target.dead or player.dead or target:isKongcheng() then return false end
    local cards = table.simpleClone(target:getCardIds("h"))
    room:moveCardTo(cards, Player.Hand, player, fk.ReasonGive, junbing.name, nil, false, target)
    if target.dead or player.dead or player:isNude() then return end
    local n = math.min(#cards, #player:getCardIds("he"))
    cards = room:askToCards(player, {
      min_num = n,
      max_num = n,
      include_equip = true,
      skill_name = junbing.name,
      cancelable = true,
      prompt = "#ty_ex__junbing-give::"..target.id..":"..n,
    })
    if #cards > 0 then
      room:moveCardTo(cards, Player.Hand, target, fk.ReasonGive, junbing.name, nil, false, player)
    end
  end,
})

return junbing
