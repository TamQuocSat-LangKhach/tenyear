local mengjiez = fk.CreateSkill {
  name = "mengjiez",
}

Fk:loadTranslationTable{
  ["mengjiez"] = "梦解",
  [":mengjiez"] = "一名角色的回合结束时，若其本回合完成了其属性对应内容，你执行对应效果。<br>"..
  "武勇：造成伤害；对一名其他角色造成1点伤害<br>"..
  "刚硬：回复体力或手牌数大于体力值；令一名角色回复1点体力<br>"..
  "多谋：摸牌阶段外摸牌；摸两张牌<br>"..
  "果决：弃置或获得其他角色的牌；弃置一名其他角色区域内的至多两张牌<br>"..
  "仁智：交给其他角色牌；令一名其他角色将手牌摸至体力上限（至多摸五张）",

  ["#mengjiez1-invoke"] = "梦解：对一名其他角色造成1点伤害",
  ["#mengjiez2-invoke"] = "梦解：令一名角色回复1点体力",
  ["#mengjiez4-invoke"] = "梦解：弃置一名其他角色区域内至多两张牌",
  ["#mengjiez5-invoke"] = "梦解：令一名其他角色将手牌摸至体力上限（至多摸五张）",

  ["$mengjiez1"] = "唇舌之语，难言虚实之境。",
  ["$mengjiez2"] = "解梦之术，如镜中观花尔。",
}

local U = require "packages/utility/utility"

mengjiez:addEffect(fk.TurnEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(mengjiez.name) and target:getMark("tongguan_info") ~= 0 then
      local room = player.room
      local mark = target:getMark("tongguan_info")
      if mark == "tg_wuyong" then
        return #room.logic:getActualDamageEvents(1, function(e)
          return e.data.from == target
        end) > 0
      elseif mark == "tg_gangying" then
        if target:getHandcardNum() > target.hp then return true end
        return #room.logic:getEventsOfScope(GameEvent.Recover, 1, function(e)
          return e.data.who == target
        end, Player.HistoryTurn) > 0
      elseif mark == "tg_duomou" then
        local phase_events = room.logic:getEventsOfScope(GameEvent.Phase, 1, function (e)
          return e.data.phase == Player.Draw
        end, Player.HistoryTurn)
        return #room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
          if not table.find(phase_events, function (phase_event)
            return e.id > phase_event.id and e.id < phase_event.end_id
          end) then
            for _, move in ipairs(e.data) do
              if move.to == target and move.moveReason == fk.ReasonDraw then
                return true
              end
            end
          end
        end, Player.HistoryTurn) > 0
      elseif mark == "tg_guojue" then
        return #room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
          for _, move in ipairs(e.data) do
            if move.from ~= target and move.proposer == target and
              (move.moveReason == fk.ReasonDiscard or move.moveReason == fk.ReasonPrey) and
              table.find(move.moveInfo, function(info)
                return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip
              end) then
              return true
            end
          end
        end, Player.HistoryTurn) > 0
      elseif mark == "tg_renzhi" then
        return #room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
          for _, move in ipairs(e.data) do
            if (move.from == target or move.proposer == target) and move.to and
              move.to ~= move.from and move.moveReason == fk.ReasonGive then
              return true
            end
          end
        end, Player.HistoryTurn) > 0
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = target:getMark("tongguan_info")
    if mark == "tg_duomou" then
      player:drawCards(2, mengjiez.name)
    else
      local targets = room:getOtherPlayers(player, false)
      local prompt = "#mengjiez1-invoke"
      if mark == "tg_gangying" then
        targets = table.filter(room.alive_players, function (p)
          return p:isWounded()
        end)
        prompt = "#mengjiez2-invoke"
      elseif mark == "tg_guojue"  then
        prompt = "#mengjiez4-invoke"
        targets = table.filter(room:getOtherPlayers(player, false), function (p)
          return not p:isAllNude()
        end)
      elseif mark == "tg_renzhi" then
        prompt = "#mengjiez5-invoke"
        targets = table.filter(room:getOtherPlayers(player, false), function (p)
          return p:getHandcardNum() < p.maxHp
        end)
      end
      if #targets == 0 then return false end
      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        skill_name = mengjiez.name,
        prompt = prompt,
        cancelable = false,
      })[1]
      if mark == "tg_wuyong" then
        room:damage{
          from = player,
          to = to,
          damage = 1,
          skillName = mengjiez.name,
        }
      elseif mark == "tg_gangying" then
        room:recover{
          who = to,
          num = 1,
          recoverBy = player,
          skillName = mengjiez.name
        }
      elseif mark == "tg_guojue" then
        local cards = room:askToChooseCards(player, {
          target = to,
          min = 1,
          max = 2,
          flag = "hej",
          skill_name = mengjiez.name,
        })
        room:throwCard(cards, mengjiez.name, to, player)
      elseif mark == "tg_renzhi" then
        to:drawCards(math.min(5, to.maxHp - to:getHandcardNum()), mengjiez.name)
      end
    end
    U.showPrivateMark(target, ":tongguan")
  end,
})

mengjiez:addLoseEffect(function (self, player, is_death)
  local room = player.room
  if table.every(room.alive_players, function (p)
    return not p:hasSkill(mengjiez.name, true)
  end) then
    for _, p in ipairs(room.alive_players) do
      room:setPlayerMark(p, "@[private]:tongguan", 0)
    end
  end
end)

return mengjiez
