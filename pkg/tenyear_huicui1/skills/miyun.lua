local miyun = fk.CreateSkill {
  name = "miyun"
}

Fk:loadTranslationTable{
  ['miyun'] = '密运',
  ['#miyun-choose'] = '密运：选择一名角色，获得其一张牌作为『安』',
  ['miyun_active'] = '密运',
  ['#miyun-give'] = '密运：选择包含『安』（%arg）在内的任意张手牌，交给一名角色',
  ['@miyun_safe'] = '安',
  ['@@miyun_safe'] = '安',
  [':miyun'] = '锁定技，每轮开始时，你展示并获得一名其他角色的一张牌，称为『安』；每轮结束时，你将包括『安』在内的任意张手牌交给一名其他角色，然后你将手牌摸至体力上限。你不以此法失去『安』时，你失去1点体力。',
  ['$miyun1'] = '不要大张旗鼓，要神不知鬼不觉。',
  ['$miyun2'] = '小阿斗，跟本将军走一趟吧。',
}

miyun:addEffect(fk.RoundStart, {
  global = false,
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(miyun.name) then return false end
    return not table.every(player.room.alive_players, function (p) return p == player or p:isNude() end)
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    if not player:hasSkill(miyun.name) then return false end

    local targets = table.filter(room.alive_players, function (p)
      return p ~= player and not p:isNude()
    end)

    if #targets == 0 then return false end

    room:notifySkillInvoked(player, miyun.name, "control")
    player:broadcastSkillInvoke(miyun.name)

    local tos = room:askToChoosePlayers(player, {
      targets = table.map(targets, Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#miyun-choose",
      skill_name = miyun.name,
      cancelable = false,
      no_indicate = true
    })

    local cid = room:askToChooseCard(player, {
      target = room:getPlayerById(tos[1]),
      flag = "he",
      skill_name = miyun.name
    })

    local move = {
      from = tos[1],
      ids = {cid},
      to = player.id,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonPrey,
      proposer = player.id,
      skillName = "miyun_prey",
    }

    room:moveCards(move)
  end
})

miyun:addEffect(fk.RoundEnd, {
  global = false,
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(miyun.name) then return false end
    return table.contains(player.player_cards[player.Hand], player:getMark(miyun.name)) and #player.room.alive_players > 1
  end,
  on_use = function(self, event, target, player)
    local room = player.room

    room:notifySkillInvoked(player, miyun.name, "drawcard")
    player:broadcastSkillInvoke(miyun.name)

    local cid = player:getMark(miyun.name)
    local card = Fk:getCardById(cid)

    local _, ret = room:askToUseActiveSkill(player, {
      skill_name = "miyun_active",
      prompt = "#miyun-give:::" .. card:toLogString(),
      cancelable = false
    })

    local to_give = {cid}
    local to = room:getOtherPlayers(to_give)[1].id

    if ret and #ret.cards > 0 and #ret.targets == 1 then
      to_give = ret.cards
      to = ret.targets[1]
    end

    local move = {
      from = player.id,
      ids = to_give,
      to = to,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonGive,
      proposer = player.id,
      skillName = "miyun_give",
      moveVisible = true
    }

    room:moveCards(move)

    if not player.dead then
      local x = player.maxHp - player:getHandcardNum()
      if x > 0 then
        room:drawCards(player, x, miyun.name)
      end
    end
  end
})

miyun:addEffect(fk.AfterCardsMove, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    local miyun_losehp = (data.extra_data or {}).miyun_losehp or {}
    return table.contains(miyun_losehp, player.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room

    room:notifySkillInvoked(player, miyun.name, "negative")
    room:loseHp(player, 1, miyun.name)
  end,
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local marked = {}

    for _, move in ipairs(data) do
      if move.from == player.id and (move.to ~= player.id or move.toArea ~= Card.PlayerHand) then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId

          if player:getMark(miyun.name) == info.cardId then
            room:setPlayerMark(player, miyun.name, 0)
            room:setPlayerMark(player, "@miyun_safe", 0)
            room:setCardMark(Fk:getCardById(info.cardId), "@@miyun_safe", 0)

            if move.skillName ~= "miyun_give" then
              data.extra_data = data.extra_data or {}
              local miyun_losehp = data.extra_data.miyun_losehp or {}
              table.insert(miyun_losehp, player.id)
              data.extra_data.miyun_losehp = miyun_losehp
            end
          end
        end
      elseif move.to == player.id and move.toArea == Card.PlayerHand and move.skillName == "miyun_prey" then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId

          if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player then
            table.insert(marked, id)
          end
        end
      end
    end

    if #marked > 0 then
      for _, id in ipairs(player.player_cards[player.Hand]) do
        room:setCardMark(Fk:getCardById(id), "@@miyun_safe", 0)
      end

      local card = Fk:getCardById(marked[1])
      room:setPlayerMark(player, miyun.name, card.id)

      local num = card.number
      if num > 0 then
        if num == 1 then
          num = "A"
        elseif num == 11 then
          num = "J"
        elseif num == 12 then
          num = "Q"
        elseif num == 13 then
          num = "K"
        end
      end

      room:setPlayerMark(player, "@miyun_safe", {card.name, card:getSuitString(true), num})
      room:setCardMark(card, "@@miyun_safe", 1)
    end
  end,
})

return miyun
