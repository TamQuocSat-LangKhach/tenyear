local liying = fk.CreateSkill {
  name = "liying"
}

Fk:loadTranslationTable{
  ['liying'] = '俐影',
  ['#liying1-invoke'] = '俐影：你可以将其中任意张牌交给一名其他角色，然后摸一张牌',
  ['ruiji_wang'] = '妄',
  ['#liying2-invoke'] = '俐影：你可以将其中任意张牌交给一名其他角色，然后摸一张牌并增加一张“妄”',
  ['wangyuan'] = '妄缘',
  [':liying'] = '每回合限一次，当你于摸牌阶段外获得牌后，你可以将其中任意张牌交给一名其他角色，然后你摸一张牌。若此时是你的回合内，再增加一张“妄”。',
  ['$liying1'] = '飞影略白鹭，日暮栖君怀。',
  ['$liying2'] = '妾影婆娑，摇曳君心。',
}

liying:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(liying.name) and player.phase ~= Player.Draw and player:usedSkillTimes(liying.name, Player.HistoryTurn) == 0 then
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Player.Hand then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local ids = {}
    for _, move in ipairs(data) do
      if move.to == player.id and move.toArea == Player.Hand then
        for _, info in ipairs(move.moveInfo) do
          table.insertIfNeed(ids, info.cardId)
        end
      end
    end
    local prompt = "#liying1-invoke"
    if player.phase ~= Player.NotActive and #player:getPile("ruiji_wang") < #room.players then
      prompt = "#liying2-invoke"
    end
    local tos, cards = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 999,
      targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
      min_target_num = 1,
      max_target_num = 1,
      pattern = tostring(Exppattern{ id = ids }),
      prompt = prompt,
      skill_name = liying.name,
    })
    if #tos > 0 and #cards > 0 then
      event:setCostData(self, {tos, cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ret = event:getCostData(self)
    room:obtainCard(ret[1][1], ret[2], false, fk.ReasonGive, player.id)
    if not player.dead then
      player:drawCards(1, liying.name)
      if not player.dead and player.phase ~= Player.NotActive and #player:getPile("ruiji_wang") < #room.players then
        local skill = Fk.skills["wangyuan"]
        skill:use(event, target, player, data)
      end
    end
  end,
})

return liying
