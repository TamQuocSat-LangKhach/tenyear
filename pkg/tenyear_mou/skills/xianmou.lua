local xianmou = fk.CreateSkill {
  name = "xianmou"
}

Fk:loadTranslationTable{
  ['xianmou'] = '先谋',
  ['#xianmou_yang-invoke'] = '先谋：你可观看牌堆顶五张牌并可获得其中至多%arg张',
  ['#xianmou_yin-invoke'] = '先谋：你可选择一名角色，观看其手牌并可弃置其中至多%arg张',
  ['#xianmou_yang-choose'] = '你可获得其中至多%arg张牌，若获得牌数少于%arg，则获得“遗计”',
  ['#xianmou_yin-choose'] = '你可弃置其中至多%arg张牌，若弃置牌数等于%arg，则你判定【闪电】',
  [':xianmou'] = '转换技，游戏开始时可自选阴阳状态。一名角色的回合结束时，若X大于0，你可以：阳，观看牌堆顶五张牌并可获得其中至多X张牌，若获得牌数少于X，则你获得〖遗计〗直到你下次发动本项；阴，观看一名角色的手牌并可弃置其中至多X张牌，若弃置牌数等于X，则你进行一次【闪电】判定（X为你本回合失去过的牌数）。',
  ['$xianmou1'] = '绸缪于未雨，手握胜机，雨落何妨高歌？',
  ['$xianmou2'] = '此帆济沧海，彼岸日边，任他风雨飘摇！',
}

xianmou:addEffect(fk.TurnEnd, {
  anim_type = "switch",
  switch_skill_name = "xianmou",
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(xianmou) and
      #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if
            move.from == player.id and
            not (move.to == player.id and (move.toArea == Card.PlayerHand or move.toArea == Card.PlayerEquip))
          then
            return
              table.find(
                move.moveInfo,
                function(info) return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip end
              ) ~= nil
          end
        end

        return false
      end, Player.HistoryTurn) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local sum = 0
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if
          move.from == player.id and
          not (move.to == player.id and (move.toArea == Card.PlayerHand or move.toArea == Card.PlayerEquip))
        then
          sum = sum + #table.filter(
            move.moveInfo,
            function(info) return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip end
          )

          if sum > 4 then
            return true
          end
        end
      end

      return false
    end, Player.HistoryTurn)

    if player:getSwitchSkillState(xianmou.name) == fk.SwitchYang then
      if not room:askToSkillInvoke(player, { skill_name = xianmou.name, prompt = "#xianmou_yang-invoke:::" .. sum }) then
        return false
      end

      event:setCostData(self, sum)
    else
      local targets = table.filter(room.alive_players, function(p) return not p:isKongcheng() end)
      if #targets == 0 then
        return false
      end

      local tos = room:askToChoosePlayers(player, { targets = Util.map(targets, Util.IdMapper), min_num = 1, max_num = 1, prompt = "#xianmou_yin-invoke:::" .. sum })
      if #tos == 0 then
        return false
      end

      event:setCostData(self, { tos[1], sum })
    end

    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room

    setTYMouSwitchSkillState(player, "guojia", xianmou.name)
    if player:getSwitchSkillState(xianmou.name, true) == fk.SwitchYang then
      if player:getMark("xianmou_yiji") > 0 then
        room:setPlayerMark(player, "xianmou_yiji", 0)
        if player:hasSkill("ex__yiji", true) then
          room:handleAddLoseSkills(player, "-ex__yiji")
        end
      end
      local ids = room:getNCards(5)
      local sum = event:getCostData(self)
      local cards, choice = U.askforChooseCardsAndChoice(
        player,
        ids,
        { "OK" },
        xianmou.name,
        "#xianmou_yang-choose:::" .. sum,
        { "Cancel" },
        1,
        sum
      )

      if #cards > 0 then
        room:obtainCard(player, cards, false, fk.ReasonPrey, player.id, xianmou.name)
      end
      if #cards < sum and not player:hasSkill("ex__yiji", true) then
        room:setPlayerMark(player, "xianmou_yiji", 1)
        room:handleAddLoseSkills(player, "ex__yiji")
      end
    else
      local toId, sum = table.unpack(event:getCostData(self))
      local to = room:getPlayerById(toId)
      if to:isKongcheng() then
        return false
      end

      local cards, choice = U.askforChooseCardsAndChoice(
        player,
        player == to and
        table.filter(to:getCardIds("h"), function(id) return not player:prohibitDiscard(id) end) or
        to:getCardIds("h"),
        { "OK" },
        xianmou.name,
        "#xianmou_yin-choose:::" .. sum,
        { "Cancel" },
        1,
        sum,
        to:getCardIds("h")
      )

      if choice == "Cancel" then
        return false
      end

      room:throwCard(cards, xianmou.name, to, player)
      if #cards == sum then
        local judge = {
          who = player,
          reason = "lightning",
          pattern = ".|2~9|spade",
        }
        room:judge(judge)
        if judge.card.suit == Card.Spade and judge.card.number > 1 and judge.card.number < 10 then
          room:damage{
            to = player,
            damage = 3,
            damageType = fk.ThunderDamage,
            skillName = xianmou.name,
          }
        end
      end
    end
  end,
})

xianmou:addEffect(fk.GameStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xianmou)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    setTYMouSwitchSkillState(player, "guojia", xianmou.name,
      room:askToChoice(player, { choices = { "tymou_switch:::xianmou:yang", "tymou_switch:::xianmou:yin" }, skill_name = xianmou.name, prompt = "#tymou_switch-transer:::xianmou"}) == "tymou_switch:::xianmou:yin")
  end,
})

return xianmou
