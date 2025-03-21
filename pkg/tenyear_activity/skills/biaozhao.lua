local biaozhao = fk.CreateSkill {
  name = "biaozhao"
}

Fk:loadTranslationTable{
  ["biaozhao"] = "表召",
  ["biaozhao_message"] = "表",
  ["#biaozhao-cost"] = "你可以发动表召，选择一张牌作为表置于武将牌上",
  ["#biaozhao-choose"] = "表召：选择一名角色，令其回复1点体力并补充手牌",
  ["#biaozhao-target"] = "表召：选择一名角色，令其获得你的“表”%arg",
  [":biaozhao"] = "结束阶段，你可将一张牌置于武将牌上，称为“表”。当一张与“表”花色点数均相同的牌移至弃牌堆后，若此牌是其他角色弃置的牌，则其获得“表”，否则你移去“表”并失去1点体力。准备阶段，你移去“表”，令一名角色回复1点体力，其将手牌摸至与手牌最多的角色相同（至多摸五张）。",
  ["$biaozhao1"] = "此人有祸患之像，望丞相慎之。",
  ["$biaozhao2"] = "孙策宜加贵宠，须召还京邑！",
}

biaozhao:addEffect(fk.EventPhaseStart, {
  mute = true,
  derived_piles = "biaozhao_message",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(biaozhao.name) then return false end
    return (player.phase == Player.Finish and #player:getPile("biaozhao_message") == 0) or
      (player.phase == Player.Start and #player:getPile("biaozhao_message") > 0)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart and player.phase == Player.Finish then
      local cards = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = biaozhao.name,
        cancelable = true,
        pattern = ".",
        prompt = "#biaozhao-cost"
      })
      if #cards > 0 then
        event:setCostData(self, cards)
        return true
      end
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:notifySkillInvoked(player, biaozhao.name, "support")
      player:broadcastSkillInvoke(biaozhao.name)
      if player.phase == Player.Finish then
        player:addToPile("biaozhao_message", event:getCostData(self), true, biaozhao.name)
      else
        room:moveCards({
          from = player.id,
          ids = player:getPile("biaozhao_message"),
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonPutIntoDiscardPile,
          skillName = biaozhao.name,
        })
        local targets = room:askToChoosePlayers(player, {
          targets = table.map(room.alive_players, Util.IdMapper),
          min_num = 1,
          max_num = 1,
          prompt = "#biaozhao-choose",
          skill_name = biaozhao.name
        })
        if #targets > 0 then
          local to = room:getPlayerById(targets[1])
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
              room:drawCards(to, math.min(5, x), biaozhao.name)
            end
          end
        end
      end
    end
  end,
})

biaozhao:addEffect(fk.AfterCardsMove, {
  mute = true,
  derived_piles = "biaozhao_message",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(biaozhao.name) then return false end
    local pile = Fk:getCardById(player:getPile("biaozhao_message")[1])
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          local card = Fk:getCardById(info.cardId)
          if card:compareNumberWith(pile) and card:compareSuitWith(pile) then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, biaozhao.name, "negative")
    player:broadcastSkillInvoke(biaozhao.name)
    local pile = Fk:getCardById(player:getPile("biaozhao_message")[1])
    local targets = {}
    for _, move in ipairs(data) do
      if move.moveReason == fk.ReasonDiscard and move.toArea == Card.DiscardPile and move.from ~= nil and
        not room:getPlayerById(move.from).dead then
        for _, info in ipairs(move.moveInfo) do
          local card = Fk:getCardById(info.cardId)
          if card:compareNumberWith(pile) and card:compareSuitWith(pile) then
            table.insertIfNeed(targets, move.from)
          end
        end
      end
    end
    if #targets > 1 then
      targets = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#biaozhao-target:::" .. pile:toLogString(),
        skill_name = biaozhao.name
      })
    end
    if #targets > 0 then
      room:obtainCard(targets[1], pile, false, fk.ReasonPrey)
    else
      room:moveCards({
        from = player.id,
        ids = {pile.id},
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = biaozhao.name,
      })
      if not player.dead then
        room:loseHp(player, 1, biaozhao.name)
      end
    end
  end,
})

return biaozhao
