local lishi = fk.CreateSkill {
  name = "lishi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["lishi"] = "立世",
  [":lishi"] = "锁定技，结束阶段，若你没有“凛”，你受到1点雷电伤害；若你有“凛”，你移去任意枚“凛”，选择等量项令所有其他角色执行：<br>"..
  "1.下个准备阶段和结束阶段非锁定技失效；<br>"..
  "2.下个判定阶段，需选择【闪电】【乐不思蜀】【兵粮寸断】中两个进行判定；<br>"..
  "3.下个摸牌阶段，若摸到的牌颜色均相同，则全部弃置；<br>"..
  "4.下个出牌阶段，每种类型的牌只能使用一张；<br>"..
  "5.下个弃牌阶段，你获得其弃置的牌。",

  ["#lishi-choice"] = "立世：选择至多%arg项，移去等量“凛”，令所有其他角色下个阶段执行对应效果",
  ["lishi_start"] = "准备阶段和判定阶段：非锁定技失效",
  ["lishi_judge"] = "判定阶段：选择两种延时锦囊进行判定",
  ["lishi_draw"] = "摸牌阶段：摸到的牌颜色相同则弃置",
  ["lishi_play"] = "出牌阶段：每种类别手牌只能使用一张",
  ["lishi_discard"] = "弃牌阶段：你获得其弃置的牌",
  ["@lishi"] = "立世",
  ["#lishi_judge-choice"] = "立世：请选择两种延时锦囊进行判定",

  ["$lishi1"] = "",
  ["$lishi2"] = "",
}

local function setLishiMark(player)
  local mark = player:getTableMark(lishi.name)
  local str = ""
  for _, choice in ipairs(mark) do
    str = str.." "..Fk:translate("lishi_"..choice)[1]
  end
  player.room:setPlayerMark(player, "@lishi", #mark > 0 and str or 0)
end

lishi:addEffect(fk.EventPhaseStart, {
  priority = 2,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lishi.name) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(lishi.name)
    if player:getMark("@zhonghui_piercing") == 0 then
      room:notifySkillInvoked(player, lishi.name, "negative")
      room:damage{
        from = player,
        to = player,
        damage = 1,
        damageType = fk.ThunderDamage,
        skillName = lishi.name,
      }
    else
      local phases = {"start", "judge", "draw", "play", "discard"}
      local choices = room:askToChoices(player, {
        choices = table.map(phases, function(phase)
          return "lishi_"..phase
        end),
        min_num = 1,
        max_num = player:getMark("@zhonghui_piercing"),
        skill_name = lishi.name,
        prompt = "#lishi-choice:::"..player:getMark("@zhonghui_piercing"),
        cancelable = false,
      })
      choices = table.map(choices, function(choice)
        return string.split(choice, "_")[2]
      end)
      room:notifySkillInvoked(player, lishi.name, "offensive", room:getOtherPlayers(player))
      room:doIndicate(player, room:getOtherPlayers(player, false))
      for _, p in ipairs(room:getOtherPlayers(player, false)) do
        local mark = p:getTableMark(lishi.name)
        table.insertTableIfNeed(mark, choices)
        room:setPlayerMark(p, lishi.name, mark)
        if table.contains(choices, "start") then
          room:setPlayerMark(p, "lishi_start", {"start", "finish"})
        end
        if table.contains(choices, "discard") then
          room:addTableMarkIfNeed(p, "lishi_discard", player.id)
        end
        setLishiMark(p)
      end
    end
  end,
})

lishi:addEffect(fk.EventPhaseStart, {
  priority = 2,
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    if target == player then
      local room = player.room
      if player.phase == Player.Start then
        return room:removeTableMark(player, "lishi_start", "start")
      elseif player.phase == Player.Judge then
        return room:removeTableMark(player, lishi.name, "judge")
      elseif player.phase == Player.Play then
        return room:removeTableMark(player, lishi.name, "play")
      elseif player.phase == Player.Finish then
        if room:removeTableMark(player, "lishi_start", "finish") then
          room:removeTableMark(player, lishi.name, "start")
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    setLishiMark(player)
    if player.phase == Player.Start then
      room:setPlayerMark(player, "lishi_invalidity-phase", 1)
    elseif player.phase == Player.Judge then
      local choices = room:askToChoices(player, {
        choices = {"lightning", "indulgence", "supply_shortage"},
        min_num = 2,
        max_num = 2,
        skill_name = lishi.name,
        prompt = "#lishi_judge-choice",
        cancelable = false,
      })
      if table.contains(choices, "lightning") then
        local judge = {
          who = player,
          reason = "lightning",
          pattern = ".|2~9|spade",
        }
        room:judge(judge)
        if judge:matchPattern() then
          room:damage{
            to = player,
            damage = 3,
            damageType = Fk:getDamageNature(fk.ThunderDamage) and fk.ThunderDamage or fk.NormalDamage,
            skillName = "lightning_skill",
          }
        end
      end
      if player.dead then return end
      if table.contains(choices, "indulgence") then
        local judge = {
          who = player,
          reason = "indulgence",
          pattern = ".|.|spade,club,diamond",
        }
        room:judge(judge)
        if judge:matchPattern() then
          player:skip(Player.Play)
        end
      end
      if player.dead then return end
      if table.contains(choices, "supply_shortage") then
        local judge = {
          who = player,
          reason = "supply_shortage",
          pattern = ".|.|spade,heart,diamond",
        }
        room:judge(judge)
        if judge:matchPattern() then
          player:skip(Player.Draw)
        end
      end
    elseif player.phase == Player.Play then
      room:setPlayerMark(player, "lishi_play-phase", 1)
    elseif player.phase == Player.Finish then
      room:setPlayerMark(player, "lishi_invalidity-phase", 1)
    end
  end,
})

lishi:addEffect("invalidity", {
  invalidity_func = function(self, from, skill)
    return from:getMark("lishi_invalidity-phase") > 0 and
      not skill:hasTag(Skill.Compulsory, false) and skill:isPlayerSkill(from)
  end
})

lishi:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("lishi_play-phase") ~= 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:addTableMark(player, "lishi_play_record-phase", data.card.type)
  end,
})
lishi:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return card and table.contains(player:getTableMark("lishi_play_record-phase"), card.type)
  end,
})

lishi:addEffect(fk.EventPhaseEnd, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    if target == player then
      local room = player.room
      if player.phase == Player.Draw then
        return room:removeTableMark(player, lishi.name, "draw")
      elseif player.phase == Player.Discard then
        return room:removeTableMark(player, lishi.name, "discard")
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    setLishiMark(player)
    if player.phase == Player.Draw then
      local cards = {}
      room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.to == player and move.moveReason == fk.ReasonDraw then
            for _, info in ipairs(move.moveInfo) do
              table.insertIfNeed(cards, info.cardId)
            end
          end
        end
      end, Player.HistoryPhase)
      if table.every(cards, function (id)
        return Fk:getCardById(id).color == Fk:getCardById(cards[1]).color
      end) then
        cards = table.filter(cards, function (id)
          return table.contains(player:getCardIds("h"), id) and not player:prohibitDiscard(id)
        end)
        if #cards > 0 then
          room:throwCard(cards, lishi.name, player, player)
        end
      end
    elseif player.phase == Player.Discard then
      local src = player:getTableMark("lishi_discard")
      room:setPlayerMark(player, "lishi_discard", 0)
      src = table.map(src, Util.Id2PlayerMapper)
      src = table.filter(src, function(p)
        return not p.dead
      end)
      if #src == 0 then return end
      src = src[1]
      local cards = {}
      room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.from == player and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              if table.contains(room.discard_pile, info.cardId) then
              table.insertIfNeed(cards, info.cardId)
              end
            end
          end
        end
      end, Player.HistoryPhase)
      if #cards > 0 then
        room:obtainCard(src, cards, true, fk.ReasonJustMove, src, lishi.name)
      end
    end
  end,
})

return lishi
