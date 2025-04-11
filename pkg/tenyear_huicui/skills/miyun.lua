local miyun = fk.CreateSkill {
  name = "miyun",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["miyun"] = "密运",
  [":miyun"] = "锁定技，每轮开始时，你展示并获得一名其他角色的一张牌，称为『安』；每轮结束时，你将包括『安』在内的任意张手牌"..
  "交给一名其他角色，然后你将手牌摸至体力上限。不以此法失去『安』时，你失去1点体力。",

  ["#miyun-choose"] = "密运：选择一名角色，获得其一张牌作为『安』",
  ["#miyun-give"] = "密运：选择包含『安』在内的任意张手牌交给一名角色",
  ["@@miyun_safe-inhand-round"] = "安",

  ["$miyun1"] = "不要大张旗鼓，要神不知鬼不觉。",
  ["$miyun2"] = "小阿斗，跟本将军走一趟吧。",
}

miyun:addEffect(fk.RoundStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(miyun.name) and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return not p:isNude()
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return not p:isNude()
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#miyun-choose",
      skill_name = miyun.name,
      cancelable = false,
    })[1]
    local card = room:askToChooseCard(player, {
      target = to,
      flag = "he",
      skill_name = miyun.name
    })
    room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, miyun.name, nil, true, player, "@@miyun_safe-inhand-round")
  end
})

miyun:addEffect(fk.RoundEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(miyun.name) and
      table.find(player:getCardIds("h"), function (id)
        return Fk:getCardById(id):getMark("@@miyun_safe-inhand-round") > 0
      end) and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "miyun_active",
      prompt = "#miyun-give",
      cancelable = false,
    })
    if not (success and dat) then
      dat = {}
      dat.cards = table.filter(player:getCardIds("h"), function (id)
        return Fk:getCardById(id):getMark("@@miyun_safe-inhand-round") > 0
      end)
      dat.targets = {room:getOtherPlayers(player, false)[1]}
    end
    room:moveCardTo(dat.cards, Card.PlayerHand, dat.targets[1], fk.ReasonGive, miyun.name, nil, false, player)
    if not player.dead and player.maxHp > player:getHandcardNum() then
      room:drawCards(player, player.maxHp - player:getHandcardNum(), miyun.name)
    end
  end
})

miyun:addEffect(fk.AfterCardsMove, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(miyun.name) then
      for _, move in ipairs(data) do
        if move.from == player and move.skillName ~= miyun.name and
          move.extra_data and move.extra_data.miyun_lose and move.extra_data.miyun_lose[1] == player.id then
          for _, info in ipairs(move.moveInfo) do
            if move.extra_data.miyun_lose[2] == info.cardId then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1, miyun.name)
  end,
})

miyun:addEffect(fk.BeforeCardsMove, {
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(miyun.name, true)
  end,
  on_refresh = function (self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand and
            Fk:getCardById(info.cardId):getMark("@@miyun_safe-inhand-round") > 0 then
            move.extra_data = move.extra_data or {}
            move.extra_data.miyun_lose = {player.id, info.cardId}
            break
          end
        end
      end
    end
  end,
})

miyun:addLoseEffect(function (self, player, is_death)
  for _, id in ipairs(player:getCardIds("h")) do
    player.room:setCardMark(Fk:getCardById(id), "@@miyun_safe-inhand-round", 0)
  end
end)

return miyun
