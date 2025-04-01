local biaozhao = fk.CreateSkill {
  name = "biaozhao",
}

Fk:loadTranslationTable{
  ["biaozhao"] = "表召",
  [":biaozhao"] = "结束阶段，你可以将一张牌置于武将牌上，称为“表”。<br>当一张与“表”花色点数均相同的牌进入弃牌堆后，若此牌是其他角色弃置的牌，"..
  "则其获得“表”，否则你移去“表”并失去1点体力。<br>准备阶段，你移去“表”，令一名角色回复1点体力，其将手牌摸至与手牌最多的角色相同（至多摸五张）。",

  ["biaozhao_message"] = "表",
  ["#biaozhao-ask"] = "表召：你可以将一张牌置为“表”",
  ["#biaozhao-choose"] = "表召：令一名角色回复1点体力并摸牌",
  ["#biaozhao-target"] = "表召：令一名角色获得“表”%arg",

  ["$biaozhao1"] = "此人有祸患之像，望丞相慎之。",
  ["$biaozhao2"] = "孙策宜加贵宠，须召还京邑！",
}

biaozhao:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  derived_piles = "biaozhao_message",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(biaozhao.name) then
      if player.phase == Player.Finish then
        return #player:getPile("biaozhao_message") == 0 and not player:isNude()
      elseif player.phase == Player.Start then
        return #player:getPile("biaozhao_message") > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if player.phase == Player.Start then
      event:setCostData(self, nil)
      return true
    elseif player.phase == Player.Finish then
      local cards = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = biaozhao.name,
        cancelable = true,
        prompt = "#biaozhao-ask",
      })
      if #cards > 0 then
        event:setCostData(self, {cards = cards})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.phase == Player.Finish then
      player:addToPile("biaozhao_message", event:getCostData(self).cards, true, biaozhao.name)
    elseif event == fk.EventPhaseStart then
      room:moveCardTo(player:getPile("biaozhao_message"), Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, biaozhao.name)
      if player.dead then return end
      local to = room:askToChoosePlayers(player, {
        targets = room.alive_players,
        min_num = 1,
        max_num = 1,
        prompt = "#biaozhao-choose",
        skill_name = biaozhao.name,
      })
      if #to > 0 then
        to = to[1]
        if to:isWounded() then
          room:recover{
            who = to,
            num = 1,
            recoverBy = player,
            skillName = biaozhao.name,
          }
        end
        if not to.dead then
          local x = 0
          for _, p in ipairs(room.alive_players) do
            x = math.max(x, p:getHandcardNum())
          end
          x = x - to:getHandcardNum()
          if x > 0 then
            to:drawCards(math.min(5, x), biaozhao.name)
          end
        end
      end
    end
  end,
})

biaozhao:addEffect(fk.AfterCardsMove, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(biaozhao.name) and #player:getPile("biaozhao_message") > 0 then
      local biaozhao_card = Fk:getCardById(player:getPile("biaozhao_message")[1])
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            local card = Fk:getCardById(info.cardId)
            if card:compareNumberWith(biaozhao_card) and card:compareSuitWith(biaozhao_card) then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local biaozhao_card = Fk:getCardById(player:getPile("biaozhao_message")[1])
    local targets = {}
    for _, move in ipairs(data) do
      if move.moveReason == fk.ReasonDiscard and move.toArea == Card.DiscardPile and
        move.from ~= nil then
        for _, info in ipairs(move.moveInfo) do
          local card = Fk:getCardById(info.cardId)
          if card:compareNumberWith(biaozhao_card) and card:compareSuitWith(biaozhao_card) then
            table.insertIfNeed(targets, move.from)
          end
        end
      end
    end
    if #targets > 0 then
      if #targets > 1 then
        targets = room:askToChoosePlayers(player, {
          targets = targets,
          min_num = 1,
          max_num = 1,
          prompt = "#biaozhao-target:::"..biaozhao_card:toLogString(),
          skill_name = biaozhao.name,
          cancelable = false,
        })
      end
      room:obtainCard(targets[1], player:getPile("biaozhao_message"), false, fk.ReasonJustMove, targets[1], biaozhao.name)
    else
      room:moveCardTo(player:getPile("biaozhao_message"), Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, biaozhao.name)
      if not player.dead then
        room:loseHp(player, 1, biaozhao.name)
      end
    end
  end,
})

return biaozhao
