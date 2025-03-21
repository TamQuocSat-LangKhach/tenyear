local junbing = fk.CreateSkill {
  name = "ty_ex__junbing"
}

Fk:loadTranslationTable{
  ['ty_ex__junbing'] = '郡兵',
  ['#ty_ex__junbing-invoke'] = '郡兵：可以摸一张牌并将所有手牌交给 %dest',
  ['#ty_ex__junbing-give'] = '郡兵：可以将 %arg 张牌交给 %dest',
  [':ty_ex__junbing'] = '一名角色的结束阶段，若其手牌数小于体力值，该角色可以摸一张牌并将所有手牌交给你，然后你可以将等量的牌交给该角色。',
  ['$ty_ex__junbing1'] = '待补充',
  ['$ty_ex__junbing2'] = '待补充',
}

junbing:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(junbing.name) and target.phase == Player.Finish and target:getHandcardNum() < target.hp
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(target, {
      skill_name = junbing.name,
      prompt = "#ty_ex__junbing-invoke::" .. player.id
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:drawCards(target, 1, junbing.name)
    if target == player or target.dead or player.dead or target:isKongcheng() then return false end
    local cards = target:getCardIds(Player.Hand)
    room:obtainCard(player.id, cards, false, fk.ReasonGive)
    local n = #cards
    if target.dead or player.dead or #player:getCardIds("he") < n then return end
    cards = room:askToCards(player, {
      min_num = n,
      max_num = n,
      include_equip = true,
      skill_name = junbing.name,
      cancelable = true,
      pattern = ".",
      prompt = "#ty_ex__junbing-give::" .. target.id .. ":" .. n
    })
    if #cards == n then
      room:obtainCard(target.id, cards, false, fk.ReasonGive)
    end
  end,
})

return junbing
