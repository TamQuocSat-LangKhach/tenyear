local anzhi = fk.CreateSkill {
  name = "anzhi"
}

Fk:loadTranslationTable{
  ['anzhi'] = '暗织',
  ['#anzhi-active'] = '发动暗织，进行判定',
  ['#anzhi-choose'] = '暗织：你可以令一名非当前回合角色获得本回合进入弃牌堆的两张牌',
  ['#anzhi-cards'] = '暗织：选择2张卡牌令%dest获得',
  ['#anzhi_trigger'] = '暗织',
  ['#anzhi-invoke'] = '是否使用暗织，进行判定',
  [':anzhi'] = '出牌阶段，或当你受到伤害后，你可以判定，若结果为：红色，重置〖霞泪〗；黑色，你可以令一名非当前回合角色获得本回合进入弃牌堆的两张牌，且你本回合不能再发动此技能。',
  ['$anzhi1'] = '深闱行彩线，唯手熟尔。',
  ['$anzhi2'] = '星月独照人，何谓之暗？',
}

anzhi:addEffect('active', {
  anim_type = "support",
  prompt = "#anzhi-active",
  card_num = 0,
  target_num = 0,
  can_use = Util.TrueFunc,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local judge = {
      who = player,
      reason = anzhi.name,
      pattern = ".",
    }
    room:judge(judge)
    if judge.card.color == Card.Red then
      room:setPlayerMark(player, "xialei-turn", 0)
    elseif judge.card.color == Card.Black then
      room:invalidateSkill(player, anzhi.name, "-turn")
      local ids = {}
      room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              table.insertIfNeed(ids, info.cardId)
            end
          end
        end
        return false
      end, Player.HistoryTurn)
      ids = table.filter(ids, function (id) return room:getCardArea(id) == Card.DiscardPile end)
      if #ids == 0 then return end
      local to = room:askToChoosePlayers(player, {
        targets = table.map(table.filter(room.alive_players, function(p)
          return p ~= room.current
        end), Util.IdMapper),
        min_num = 1,
        max_num = 1,
        prompt = "#anzhi-choose",
        skill_name = anzhi.name,
      })
      if #to > 0 then
        local get = {}
        if #ids > 2 then
          get = room:askToChooseCards(player, {
            min_card_num = 2,
            max_card_num = 2,
            expand_pile = { "pile_discard", ids },
            skill_name = anzhi.name,
            prompt = "#anzhi-cards::" .. to[1]:getId(),
          })
        else
          get = ids
        end
        if #get > 0 then
          room:moveCards({
            ids = get,
            to = to[1],
            toArea = Card.PlayerHand,
            moveReason = fk.ReasonJustMove,
            proposer = player.id,
            skillName = anzhi.name,
            moveVisible = false,
            visiblePlayers = {player.id},
          })
        end
      end
    end
  end,
})

anzhi:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(anzhi.name)
  end,
  on_cost = function(self, event, target, player, data)
    return room:askToSkillInvoke(player, {
      skill_name = anzhi.name,
      prompt = "#anzhi-invoke"
    })
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(anzhi.name)
    anzhi:onUse(player.room, {
      from = player.id,
      cards = {},
      tos = {},
    })
  end,
})

return anzhi
