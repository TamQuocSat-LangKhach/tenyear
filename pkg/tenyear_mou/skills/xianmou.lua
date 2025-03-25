local xianmou = fk.CreateSkill {
  name = "xianmou",
  tags = { Skill.Switch },
}

Fk:loadTranslationTable{
  ["xianmou"] = "先谋",
  [":xianmou"] = "转换技，游戏开始时可自选阴阳状态。一名角色的回合结束时，若你本回合失去过牌，你可以：阳，观看牌堆顶五张牌并获得其中至多X张牌，"..
  "若获得牌数少于X，则你获得〖遗计〗直到你下次发动本项；阴，观看一名角色的手牌并弃置其中至多X张牌，若弃置牌数等于X，你进行一次【闪电】判定"..
  "（X为你本回合失去过的牌数）。",

  ["#xianmou_yang-invoke"] = "先谋：你可以观看牌堆顶五张牌，获得其中至多%arg张",
  ["#xianmou_yin-invoke"] = "先谋：你可以观看一名角色手牌，弃置其中至多%arg张",
  ["#xianmou_yang-choose"] = "先谋：你可以获得其中至多%arg张牌，若获得牌数少于%arg，则获得“遗计”",
  ["#xianmou_yin-choose"] = "先谋：你可弃置其中至多%arg张牌，若弃置牌数等于%arg，则进行【闪电】判定",

  ["$xianmou1"] = "绸缪于未雨，手握胜机，雨落何妨高歌？",
  ["$xianmou2"] = "此帆济沧海，彼岸日边，任他风雨飘摇！",
}

local U = require "packages/utility/utility"

xianmou:addEffect(fk.TurnEnd, {
  anim_type = "switch",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(xianmou.name) and
      #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.from == player and
            not (move.to == player and (move.toArea == Card.PlayerHand or move.toArea == Card.PlayerEquip)) then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                return true
              end
            end
          end
        end
      end, Player.HistoryTurn) > 0 then
      if player:getSwitchSkillState(xianmou.name) == fk.SwitchYang then
        return true
      else
        return table.find(player.room.alive_players, function(p)
          return not p:isKongcheng()
        end)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local sum = 0
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.from == player and
          not (move.to == player and (move.toArea == Card.PlayerHand or move.toArea == Card.PlayerEquip)) then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              sum = sum + 1
            end
          end
        end
      end
    end, Player.HistoryTurn)
    if player:getSwitchSkillState(xianmou.name) == fk.SwitchYang then
      if room:askToSkillInvoke(player, {
        skill_name = xianmou.name,
        prompt = "#xianmou_yang-invoke:::"..sum,
      }) then
        event:setCostData(self, {choice = sum})
        return true
      end
    else
      local targets = table.filter(room.alive_players, function(p)
        return not p:isKongcheng()
      end)
      local to = room:askToChoosePlayers(player, {
        skill_name = xianmou.name,
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#xianmou_yin-invoke:::"..sum,
      })
      if #to > 0 then
        event:setCostData(self, {tos = to, choice = sum})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    U.SetSwitchSkillState(player, xianmou.name, player:getSwitchSkillState(xianmou.name, false))
    local sum = event:getCostData(self).choice
    if player:getSwitchSkillState(xianmou.name, true) == fk.SwitchYang then
      if player:getMark("xianmou_yiji") > 0 then
        room:setPlayerMark(player, "xianmou_yiji", 0)
        room:handleAddLoseSkills(player, "-ex__yiji")
      end
      local ids = room:getNCards(5)
      local cards = room:askToChooseCards(player, {
        target = player,
        min = 0,
        max = sum,
        flag = { card_data = {{ "Top", ids }} },
        skill_name = xianmou.name,
        prompt = "#xianmou_yang-choose:::" .. sum,
      })
      if #cards > 0 then
        room:obtainCard(player, cards, false, fk.ReasonJustMove, player, xianmou.name)
        if player.dead then return end
      end
      if #cards < sum and not player:hasSkill("ex__yiji", true) then
        room:setPlayerMark(player, "xianmou_yiji", 1)
        room:handleAddLoseSkills(player, "ex__yiji")
      end
    else
      local to = event:getCostData(self).tos[1]
      local cards = {}
      if to == player then
        cards = room:askToDiscard(player, {
          min_num = 1,
          max_num = sum,
          include_equip = false,
          skill_name = xianmou.name,
          prompt = "#xianmou_yin-choose:::" .. sum,
          cancelable = true,
          skip = true,
        })
      else
        cards = room:askToChooseCards(player, {
          target = to,
          min = 0,
          max = sum,
          flag = { card_data = {{ to.general, to:getCardIds("h") }} },
          skill_name = xianmou.name,
          prompt = "#xianmou_yin-choose:::"..sum,
        })
      end
      if #cards > 0 then
        room:throwCard(cards, xianmou.name, to, player)
        if player.dead then return end
      end
      if #cards == sum then
        local judge = {
          who = player,
          reason = "lightning",
          pattern = ".|2~9|spade",
        }
        room:judge(judge)
        if judge:matchPattern() and not player.dead then
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
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xianmou.name, true)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = { "tymou_switch:::xianmou:yang", "tymou_switch:::xianmou:yin" },
      skill_name = xianmou.name,
      prompt = "#tymou_switch-choice:::xianmou",
    })
    choice = choice:endsWith("yang") and fk.SwitchYang or fk.SwitchYin
    U.SetSwitchSkillState(player, xianmou.name, choice)
  end,
})

return xianmou
