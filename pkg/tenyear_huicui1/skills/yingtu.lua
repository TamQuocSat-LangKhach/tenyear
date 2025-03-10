local yingtu = fk.CreateSkill {
  name = "yingtu"
}

Fk:loadTranslationTable{
  ['yingtu'] = '营图',
  ['#yingtu-invoke'] = '营图：你可以获得 %dest 的一张牌',
  ['#yingtu-invoke-multi'] = '营图：你可以获得上家或下家的一张牌',
  ['#yingtu-choose'] = '营图：选择一张牌交给 %dest，若为装备牌则其使用之',
  [':yingtu'] = '每回合限一次，当一名角色于其摸牌阶段外获得牌后，若其是你的上家或下家，你可以获得该角色的一张牌，然后交给你的下家或上家一张牌。若以此法给出的牌为装备牌，获得牌的角色使用之。',
  ['$yingtu1'] = '不过略施小计，聊戏莽夫耳。',
  ['$yingtu2'] = '栖虎狼之侧，安能不图存身？',
}

yingtu:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(yingtu.name) and player:usedSkillTimes(yingtu.name) == 0 then
      for _, move in ipairs(data) do
        if move.to ~= nil and move.toArea == Card.PlayerHand then
          local p = player.room:getPlayerById(move.to)
          if p.phase ~= Player.Draw and (p:getNextAlive() == player or player:getNextAlive() == p) and not p:isNude() then
            return true
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, move in ipairs(data) do
      if move.to ~= nil and move.toArea == Card.PlayerHand then
        local p = player.room:getPlayerById(move.to)
        if p.phase ~= Player.Draw and (p:getNextAlive() == player or player:getNextAlive() == p) and not p:isNude() then
          table.insertIfNeed(targets, move.to)
        end
      end
    end
    if #targets == 1 then
      if room:askToSkillInvoke(player, {skill_name = yingtu.name, prompt = "#yingtu-invoke::"..targets[1]}) then
        room:doIndicate(player.id, targets)
        event:setCostData(self, targets[1])
        return true
      end
    elseif #targets > 1 then
      local tos = room:askToChoosePlayers(player, {targets = targets, min_num = 1, max_num = 1, prompt = "#yingtu-invoke-multi", skill_name = yingtu.name})
      if #tos > 0 then
        event:setCostData(self, tos[1])
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = room:getPlayerById(event:getCostData(self))
    local lastplayer = (player:getNextAlive() == from)
    local card = room:askToChooseCard(player, {target = from, flag = "he", skill_name = yingtu.name})
    room:obtainCard(player.id, card, false, fk.ReasonPrey)
    if player.dead or player:isNude() then return false end
    local to = player:getNextAlive()
    if lastplayer then
      to = player:getLastAlive()
    end
    if to == nil or to == player then return false end
    local id = room:askToCards(player, {min_num = 1, max_num = 1, include_equip = true, skill_name = yingtu.name, prompt = "#yingtu-choose::"..to.id})[1]
    room:obtainCard(to, id, false, fk.ReasonGive)
    local card = Fk:getCardById(id)
    if card.type == Card.TypeEquip and not to.dead and table.contains(to:getCardIds("h"), id) and not to:isProhibited(to, card) then
      room:useCard({
        from = to.id,
        tos = {{to.id}},
        card = card,
      })
    end
  end,
})

return yingtu
