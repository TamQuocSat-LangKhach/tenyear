local anzhi = fk.CreateSkill {
  name = "anzhi",
}

Fk:loadTranslationTable{
  ["anzhi"] = "暗织",
  [":anzhi"] = "出牌阶段，或当你受到伤害后，你可以判定，若结果为：红色，重置〖霞泪〗；黑色，你可以令一名非当前回合角色获得本回合"..
  "进入弃牌堆的两张牌，然后此技能本回合失效。",

  ["#anzhi"] = "暗织：进行判定，红色重置“霞泪”，黑色可以令一名角色获得牌",
  ["#anzhi-choose"] = "暗织：你可以令一名非当前回合角色获得本回合进入弃牌堆的两张牌",
  ["#anzhi-give"] = "暗织：选择两张牌令 %dest 获得",

  ["$anzhi1"] = "深闱行彩线，唯手熟尔。",
  ["$anzhi2"] = "星月独照人，何谓之暗？",
}

anzhi:addEffect("active", {
  anim_type = "support",
  prompt = "#anzhi",
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local judge = {
      who = player,
      reason = anzhi.name,
      pattern = ".|.|^nosuit",
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
      end, Player.HistoryTurn)
      ids = table.filter(ids, function (id)
        return table.contains(room.discard_pile, id)
      end)
      if #ids == 0 then return end
      local targets = room:getOtherPlayers(room.current, false)
      if #targets == 0 then return end
      local to = room:askToChoosePlayers(player, {
        targets = room:getOtherPlayers(room.current, false),
        min_num = 1,
        max_num = 1,
        prompt = "#anzhi-choose",
        skill_name = anzhi.name,
      })
      if #to > 0 then
        to = to[1]
        if #ids > 2 then
          ids = room:askToChooseCards(player, {
            target = to,
            min = 2,
            max = 2,
            flag = { card_data = {{ "pile_discard", ids }} },
            skill_name = anzhi.name,
            prompt = "#anzhi-give::"..to.id,
          })
        end
        room:moveCards({
          ids = ids,
          to = to,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonJustMove,
          proposer = player,
          skillName = anzhi.name,
          moveVisible = true,
        })
      end
    end
  end,
})

anzhi:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(anzhi.name)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = anzhi.name,
      prompt = "#anzhi",
      cancelable = true,
      skip = true,
    })
    if success and dat then
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local skill = Fk.skills[anzhi.name]
    skill:onUse(player.room, {
      from = player,
    })
  end,
})

return anzhi
