local yanjiao = fk.CreateSkill {
  name = "yanjiao",
}

Fk:loadTranslationTable{
  ["yanjiao"] = "严教",
  [":yanjiao"] = "出牌阶段限一次，你可以选择一名其他角色并亮出牌堆顶的四张牌，然后令该角色将这些牌分成点数之和相等的两组牌分配给你与其，"..
  "剩余未分组的牌置入弃牌堆。若未分组的牌超过一张，你本回合手牌上限-1。",

  ["#yanjiao"]= "严教：对一名其他角色发动“严教”",
  ["#yanjiao-distribute"] = "严教：请分成点数之和相等的两组",
  ["Only Watch"] = "仅观看",

  ["$yanjiao1"] = "会虽童稚，勤见规诲。",
  ["$yanjiao2"] = "性矜严教，明于教训。",
}

yanjiao:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@yanjiao", 0)
end)

Fk:addMiniGame{
  name = "yanjiao",
  qml_path = "packages/tenyear/qml/YanjiaoBox",
  default_choice = function(player, data)
    return {}
  end,
  update_func = function(player, data)
    local room = player.room
    if #data == 1 and data[1] == "confirm" then
      for _, p in ipairs(room:getOtherPlayers(player, false)) do
        p:doNotify("UpdateMiniGame", "")
      end
    else
      local dat = table.concat(data, ",")
      for _, p in ipairs(room:getOtherPlayers(player, false)) do
        p:doNotify("UpdateMiniGame", dat)
      end
    end
  end,
}

yanjiao:addEffect("active", {
  anim_type = "support",
  prompt = "#yanjiao",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(yanjiao.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local n = 4 + player:getMark("@yanjiao")
    room:setPlayerMark(player, "@yanjiao", 0)
    local cards = room:getNCards(n)
    room:turnOverCardsFromDrawPile(player, cards, yanjiao.name)
    local data_table = {}
    for _, p in ipairs(room.players) do
      data_table[p.id] = {
        cards,
        player.general,
        target.general,
        p == target,
      }
    end
    room:askToMiniGame(room.players, {
      skill_name = yanjiao.name,
      game_type = "yanjiao",
      data_table = data_table
    })
    local cardmap = json.decode(target.client_reply)
    local rest, pile1, pile2 = cards, {}, {}
    if #cardmap == 3 then
      rest, pile1, pile2 = cardmap[1], cardmap[2], cardmap[3]
    end
    local moveInfos = {}
    if #pile1 > 0 then
      table.insert(moveInfos, {
        ids = pile1,
        to = player,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = target,
        skillName = yanjiao.name,
        moveVisible = true,
      })
    end
    if #pile2 > 0 then
      table.insert(moveInfos, {
        ids = pile2,
        to = target,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = target,
        skillName = yanjiao.name,
        moveVisible = true,
      })
    end
    if #rest > 0 then
      table.insert(moveInfos, {
        ids = rest,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonJustMove,
        proposer = target,
        skillName = yanjiao.name,
      })
      if #rest > 1 then
        room:addPlayerMark(player, MarkEnum.MinusMaxCardsInTurn, 1)
      end
    end
    room:moveCards(table.unpack(moveInfos))
  end,
})

return yanjiao
