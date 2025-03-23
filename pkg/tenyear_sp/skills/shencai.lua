local shencai = fk.CreateSkill {
  name = "shencai",
}

Fk:loadTranslationTable{
  ["shencai"] = "神裁",
  [":shencai"] = "出牌阶段限一次，你可以令一名其他角色进行判定，你获得判定牌。若判定牌包含以下内容，其获得（已有标记则改为修改）对应标记：<br>"..
  "体力：“笞”标记，每次受到伤害后失去等量体力；<br>"..
  "武器：“杖”标记，无法响应【杀】；<br>"..
  "打出：“徒”标记，以此法外失去手牌后随机弃置一张手牌；<br>"..
  "距离：“流”标记，结束阶段将武将牌翻面；<br>"..
  "若判定牌不包含以上内容，该角色获得一个“死”标记且手牌上限减少其身上“死”标记个数，然后你获得其区域内一张牌。"..
  "“死”标记个数大于场上存活人数的角色回合结束时，其立即死亡。",

  ["#shencai"] = "神裁：令一名角色进行判定",
  ["@@shencai_chi"] = "笞",
  ["@@shencai_zhang"] = "杖",
  ["@@shencai_tu"] = "徒",
  ["@@shencai_liu"] = "流",
  ["@shencai_si"] = "死",

  ["$shencai1"] = "我有三千炼狱，待汝万世轮回！",
  ["$shencai2"] = "纵汝王侯将相，亦须俯首待裁！",
}

shencai:addEffect("active", {
  anim_type = "offensive",
  prompt = "#shencai",
  card_num = 0,
  target_num = 1,
  times = function(self, player)
    return player.phase == Player.Play and 1 + player:getMark("xunshi") - player:usedEffectTimes(shencai.name, Player.HistoryPhase) or -1
  end,
  can_use = function(self, player)
    return player:usedEffectTimes(shencai.name, Player.HistoryPhase) < 1 + player:getMark("xunshi")
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local data = {
      who = target,
      reason = shencai.name,
      pattern = ".",
      extra_data = {
        shencaiSource = player,
      }
    }
    room:judge(data)
    if target.dead then return end
    local result = {}
    if string.find(Fk:translate(":"..data.card.name, "zh_CN"), "体力") then
      table.insert(result, "@@shencai_chi")
    end
    if string.find(Fk:translate(":"..data.card.name, "zh_CN"), "武器") then
      table.insert(result, "@@shencai_zhang")
    end
    if string.find(Fk:translate(":"..data.card.name, "zh_CN"), "打出") then
      table.insert(result, "@@shencai_tu")
    end
    if string.find(Fk:translate(":"..data.card.name, "zh_CN"), "距离") then
      table.insert(result, "@@shencai_liu")
    end
    if #result == 0 then
      table.insert(result, "@shencai_si")
    end
    if result[1] ~= "@shencai_si" then
      for _, mark in ipairs({"@@shencai_chi", "@@shencai_zhang", "@@shencai_tu", "@@shencai_liu"}) do
        room:setPlayerMark(target, mark, 0)
      end
    end
    for _, mark in ipairs(result) do
      room:addPlayerMark(target, mark, 1)
      if mark == "@shencai_si" and not target:isNude() and not player.dead and not target.dead then
        local card = room:askToChooseCard(player, {
          target = target,
          flag = "he",
          skill_name = shencai.name,
        })
        room:obtainCard(player, card, false, fk.ReasonPrey, player, shencai.name)
      end
    end
  end,
})

shencai:addEffect(fk.FinishJudge, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return data.extra_data and data.extra_data.shencaiSource == player and
      player.room:getCardArea(data.card) == Card.Processing and not player.dead
  end,
  on_use = function (self, event, target, player, data)
    player.room:obtainCard(player, data.card, true, fk.ReasonJustMove)
  end,
})

shencai:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "xunshi", 0)
end)

shencai:addEffect(fk.Damaged, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:getMark("@@shencai_chi") > 0 and not player.dead
  end,
  on_use = function (self, event, target, player, data)
    player.room:loseHp(player, data.damage, shencai.name)
  end,
})

shencai:addEffect(fk.TargetConfirmed, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and data.card.trueName == "slash" and player:getMark("@@shencai_zhang") > 0 and not player.dead
  end,
  on_use = function (self, event, target, player, data)
    data.disresponsive = true
  end,
})

shencai:addEffect(fk.AfterCardsMove, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    if player:getMark("@@shencai_tu") > 0 and not player:isKongcheng() and not player.dead then
      for _, move in ipairs(data) do
        if move.skillName ~= shencai.name and move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local cards = table.filter(player:getCardIds("h"), function (id)
      return not player:prohibitDiscard(id)
    end)
    if #cards > 0 then
      player.room:throwCard(table.random(cards), shencai.name, player, player)
    end
  end,
})

shencai:addEffect(fk.EventPhaseStart, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:getMark("@@shencai_liu") > 0 and player.phase == Player.Finish and not player.dead
  end,
  on_use = function (self, event, target, player, data)
    player:turnOver()
  end,
})

shencai:addEffect(fk.TurnEnd, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:getMark("@shencai_si") > #player.room.alive_players and not player.dead
  end,
  on_use = function (self, event, target, player, data)
    player.room:killPlayer({who = player})
  end,
})

shencai:addEffect("maxcards", {
  correct_func = function(self, player)
    return -player:getMark("@shencai_si")
  end,
})

return shencai
