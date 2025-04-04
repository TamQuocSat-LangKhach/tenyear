local zhiren = fk.CreateSkill {
  name = "zhiren",
}

Fk:loadTranslationTable{
  ["zhiren"] = "织纴",
  [":zhiren"] = "你的回合内，当你使用本回合的第一张非转化牌时，若X：不小于1，你观看牌堆顶X张牌并以任意顺序放回牌堆顶或牌堆底；"..
  "不小于2，你可以弃置场上一张装备牌和一张延时锦囊牌；不小于3，你回复1点体力；不小于4，你摸三张牌（X为此牌牌名字数）。",

  ["#zhiren1-choose"] = "织纴：你可以弃置场上一张装备牌",
  ["#zhiren2-choose"] = "织纴：你可以弃置场上一张延时锦囊牌",

  ["$zhiren1"] = "穿针引线，栩栩如生。",
  ["$zhiren2"] = "纺绩织纴，布帛可成。",
}

zhiren:addEffect(fk.CardUsing, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(zhiren.name) and not data.card:isVirtual() and
      (player.room.current == player or player:getMark("@@yaner") > 0) and
      player:usedSkillTimes(zhiren.name, Player.HistoryTurn) == 0 then
      local use_events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        return use.from == player and not use.card:isVirtual()
      end, Player.HistoryTurn)
      return #use_events == 1 and use_events[1].data == data
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = Fk:translate(data.card.trueName, "zh_CN"):len()
    room:askToGuanxing(player, {
      cards = room:getNCards(n),
      skill_name = zhiren.name,
    })
    if n > 1 then
      local targets = table.filter(room.alive_players, function(p)
        return #p:getCardIds("e") > 0
      end)
      if #targets > 0 then
        local to = room:askToChoosePlayers(player, {
          targets = targets,
          min_num = 1,
          max_num = 1,
          prompt = "#zhiren1-choose",
          skill_name = zhiren.name,
        })
        if #to > 0 then
          local id = room:askToChooseCard(player, {
            target = to[1],
            flag = "e",
            skill_name = zhiren.name,
          })
          room:throwCard(id, zhiren.name, to[1], player)
          if player.dead then return end
        end
      end
      targets = table.filter(room.alive_players, function(p)
        return #p:getCardIds("j") > 0
      end)
      if #targets > 0 then
        local to = room:askToChoosePlayers(player, {
          targets = targets,
          min_num = 1,
          max_num = 1,
          prompt = "#zhiren2-choose",
          skill_name = zhiren.name,
        })
        if #to > 0 then
          local id = room:askToChooseCard(player, {
            target = to[1],
            flag = "j",
            skill_name = zhiren.name,
          })
          room:throwCard(id, zhiren.name, to[1], player)
          if player.dead then return end
        end
      end
    end
    if n > 2 then
      if player:isWounded() then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = zhiren.name
        }
        if player.dead then return end
      end
    end
    if n > 3 then
      player:drawCards(3, zhiren.name)
    end
  end,
})

zhiren:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@@yaner", 0)
end)

return zhiren
