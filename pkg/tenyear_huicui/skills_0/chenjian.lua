local chenjian = fk.CreateSkill {
  name = "chenjian"
}

Fk:loadTranslationTable{
  ['chenjian'] = '陈见',
  ['@chenjian'] = '陈见',
  ['chenjian1'] = '弃一张牌，令一名角色获得此花色的牌',
  ['chenjian2'] = '使用其中一张牌',
  ['#chenjian-choose'] = '陈见：弃置一张牌并选择一名角色，令其获得与之相同花色的牌（可获得的花色:%arg）',
  ['#chenjian-use'] = '陈见：使用其中一张牌',
  [':chenjian'] = '准备阶段，你可以亮出牌堆顶的三张牌，执行任意项：1.弃置一张牌，令一名角色获得其中此牌花色的牌；2.使用其中一张牌。若两项均执行，则本局游戏你发动〖陈见〗亮出牌数+1（最多五张），然后你重铸所有手牌。',
  ['$chenjian1'] = '国有其弊，上书当陈。',
  ['$chenjian2'] = '食君之禄，怎可默言。',
}

chenjian:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chenjian.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = room:getNCards(3 + player:getMark("@chenjian"))
    room:moveCards({
      ids = ids,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = chenjian.name,
      proposer = player.id,
    })
    local confirmed = {}
    while not player.dead and #ids > 0 and #confirmed < 2 do
      local choices = {}
      local canDiscardIds = table.filter(player:getCardIds("he"), function (id)
        return not player:prohibitDiscard(Fk:getCardById(id))
      end)
      if not table.contains(confirmed, "chenjian1") and #canDiscardIds > 0 then
        table.insert(choices, "chenjian1")
      end
      if not table.contains(confirmed, "chenjian2") and 
        table.find(ids, function(id) return U.getDefaultTargets(player, Fk:getCardById(id), true, false) end) then
        table.insert(choices, "chenjian2")
      end
      table.insert(choices, "Cancel")
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = chenjian.name,
        all_choices = {"chenjian1", "chenjian2", "Cancel"},
      })
      if choice == "Cancel" then
        break
      else
        table.insertIfNeed(confirmed, choice)
        if choice == "chenjian1" then
          local suits = {}
          for _, id in ipairs(ids) do
            table.insertIfNeed(suits, Fk:translate(Fk:getCardById(id):getSuitString(true)))
          end
          local to, card =  room:askToChooseCardsAndPlayers(player, {
            min_card_num = 1,
            max_card_num = 1,
            targets = table.map(player.room.alive_players, Util.IdMapper),
            pattern = tostring(Exppattern{ id = canDiscardIds }),
            prompt = "#chenjian-choose:::"..table.concat(suits, ","),
            skill_name = chenjian.name,
          })
          if #to > 0 and card then
            local suit = Fk:getCardById(card).suit
            room:throwCard({card}, chenjian.name, player, player)
            local to_get = {}
            for i = #ids, 1, -1 do
              if Fk:getCardById(ids[i]).suit == suit then
                table.insert(to_get, ids[i])
                table.remove(ids, i)
              end
            end
            if #to_get > 0 and not room:getPlayerById(to[1]).dead then
              room:obtainCard(to[1], to_get, true, fk.ReasonPrey, to[1], chenjian.name)
            end
          end
        elseif choice == "chenjian2" then
          room:askToUseRealCard(player, {
            pattern = ids,
            skill_name = chenjian.name,
            prompt = "#chenjian-use",
            extra_data = { expand_pile = ids },
          })
        end
      end
      ids = table.filter(ids, function(id) return room:getCardArea(id) == Card.Processing end)
    end
    if #ids > 0 then
      room:moveCards({
        ids = ids,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = chenjian.name,
      })
    end
    if #confirmed > 1 and not player.dead then
      if player:getMark("@chenjian") < 2 then
        room:addPlayerMark(player, "@chenjian", 1)
      end
      if not player:isKongcheng() then
        room:recastCard(player:getCardIds("h"), player, chenjian.name)
      end
    end
  end,
})

return chenjian
