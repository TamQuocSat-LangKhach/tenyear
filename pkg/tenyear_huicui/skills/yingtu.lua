local yingtu = fk.CreateSkill {
  name = "yingtu",
}

Fk:loadTranslationTable{
  ["yingtu"] = "营图",
  [":yingtu"] = "每回合限一次，当一名角色于其摸牌阶段外获得牌后，若其是你的上家或下家，你可以获得该角色的一张牌，然后交给你的下家或上家一张牌。"..
  "若以此法给出的牌为装备牌，获得牌的角色使用之。",

  ["#yingtu-invoke"] = "营图：你可以获得 %dest 的一张牌",
  ["#yingtu-invoke-multi"] = "营图：你可以获得上家或下家的一张牌",
  ["#yingtu-choose"] = "营图：选择一张牌交给 %dest，若为装备牌则其使用之",

  ["$yingtu1"] = "不过略施小计，聊戏莽夫耳。",
  ["$yingtu2"] = "栖虎狼之侧，安能不图存身？",
}

yingtu:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(yingtu.name) and player:usedSkillTimes(yingtu.name, Player.HistoryTurn) == 0 then
      for _, move in ipairs(data) do
        if move.to ~= nil and move.toArea == Card.PlayerHand then
          if move.to.phase ~= Player.Draw and
            (move.to:getNextAlive() == player or player:getNextAlive() == move.to) and
            not move.to:isNude() and not move.to.dead then
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
        if move.to.phase ~= Player.Draw and
          (move.to:getNextAlive() == player or player:getNextAlive() == move.to) and
          not move.to:isNude() and not move.to.dead then
          table.insertIfNeed(targets, move.to)
        end
      end
    end
    if #targets == 1 then
      if room:askToSkillInvoke(player, {
        skill_name = yingtu.name,
        prompt = "#yingtu-invoke::"..targets[1].id,
      }) then
        event:setCostData(self, {tos = targets})
        return true
      end
    elseif #targets > 1 then
      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#yingtu-invoke-multi",
        skill_name = yingtu.name,
      })
      if #to > 0 then
        event:setCostData(self, {tos = to})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = event:getCostData(self).tos[1]
    local lastplayer = (player:getNextAlive() == from)
    local card = room:askToChooseCard(player, {
      target = from,
      flag = "he",
      skill_name = yingtu.name,
    })
    room:obtainCard(player, card, false, fk.ReasonPrey, player, yingtu.name)
    if player.dead or player:isNude() then return end
    local to = player:getNextAlive()
    if lastplayer then
      to = player:getLastAlive()
    end
    if to == nil or to == player then return end
    local id = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = yingtu.name,
      prompt = "#yingtu-choose::"..to.id,
      cancelable = false,
    })[1]
    room:obtainCard(to, id, false, fk.ReasonGive, player, yingtu.name)
    card = Fk:getCardById(id)
    if card.type == Card.TypeEquip and not to.dead and table.contains(to:getCardIds("h"), id) and
      to:canUseTo(card, to) then
      room:useCard({
        from = to,
        tos = {to},
        card = card,
      })
    end
  end,
})

return yingtu
