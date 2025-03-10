local tanban = fk.CreateSkill {
  name = "tanban"
}

Fk:loadTranslationTable{
  ['tanban'] = '檀板',
  ['#tanban-invoke'] = '檀板：你可以改变手牌区里所有“檀板”牌和非“檀板”牌的标记状态',
  ['@@tanban-inhand'] = '檀板',
  [':tanban'] = '游戏开始时，你的初始手牌增加“檀板”标记且不计入手牌上限。摸牌阶段结束时，你可以交换手牌区里的“檀板”牌和非“檀板”牌的标记。',
  ['$tanban1'] = '将军，妾身奏得如何？',
  ['$tanban2'] = '将军还想再听一曲？',
}

tanban:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(tanban) or player:isKongcheng() then return false end
    return true
  end,
  on_cost = function(self, event, target, player)
    return event == fk.GameStart or player.room:askToSkillInvoke(player, { skill_name = tanban.name, prompt = "#tanban-invoke" })
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    if event == fk.GameStart then
      local cards = player:getCardIds(Player.Hand)
      for _, id in ipairs(cards) do
        room:setCardMark(Fk:getCardById(id), "@@tanban-inhand", 1)
      end
    end
  end,
})

tanban:addEffect(fk.EventPhaseEnd, {
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(tanban) or player:isKongcheng() then return false end
    return target == player and player.phase == Player.Draw
  end,
  on_cost = function(self, event, target, player)
    return player.room:askToSkillInvoke(player, { skill_name = tanban.name, prompt = "#tanban-invoke" })
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    for _, id in ipairs(player.player_cards[Player.Hand]) do
      room:setCardMark(Fk:getCardById(id), "@@tanban-inhand", Fk:getCardById(id):getMark("@@tanban-inhand") > 0 and 0 or 1)
    end
  end,
})

tanban:addEffect('maxcards', {
  exclude_from = function(self, player, card)
    return player:hasSkill(tanban) and card:getMark("@@tanban-inhand") > 0
  end,
})

function tanban:on_lose(player)
  local room = player.room
  for _, id in ipairs(player:getCardIds(Player.Hand)) do
    room:setCardMark(Fk:getCardById(id), "@@tanban-inhand", 0)
  end
end

return tanban
