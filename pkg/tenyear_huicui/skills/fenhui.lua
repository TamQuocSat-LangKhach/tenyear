local fenhui = fk.CreateSkill {
  name = "fenhui",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["fenhui"] = "奋恚",
  [":fenhui"] = "限定技，出牌阶段，你可以令一名其他角色获得X枚“恨”（X为你对其使用牌的次数且至多为5），你摸等量的牌。当其受到伤害时，"..
  "其移去一枚“恨”，此伤害+1；当其死亡时，若其有“恨”，你减1点体力上限，〖守执〗改为非锁定技并获得〖兴门〗。",

  ["#fenhui"] = "奋恚：令一名角色获得“恨”标记，你摸等量牌",
  ["fenhui_count"] = "奋恚 %arg",
  ["@fenhui_hatred"] = "恨",

  ["$fenhui1"] = "国仇家恨，不共戴天！",
  ["$fenhui2"] = "手中虽无青龙吟，心有长刀仍啸月。",
}

fenhui:addEffect("active", {
  anim_type = "offensive",
  prompt = "#fenhui",
  target_tip = function(self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    if not selectable then return end
    local n = player:getTableMark("fenhui_count")[tostring(to_select.id)] or 0
    return { {content = "fenhui_count:::"..math.min(n, 5), type = "normal"} }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(fenhui.name, Player.HistoryGame) == 0 and
      player:getMark("fenhui_count") ~= 0
  end,
  card_num = 0,
  target_num = 1,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and
      player:getTableMark("fenhui_count")[tostring(to_select.id)] ~= nil
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local n = math.min(player:getTableMark("fenhui_count")[tostring(target.id)], 5)
    room:setPlayerMark(target, "@fenhui_hatred", n)
    room:addTableMark(player, "fenhui_target", target.id)
    for _, p in ipairs(room.alive_players) do
      room:setPlayerMark(p, "fenhui_count", 0)
    end
    player:drawCards(n, fenhui.name)
  end,
})

fenhui:addEffect(fk.DamageInflicted, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player == target and player:getMark("@fenhui_hatred") > 0
  end,
  on_use = function (self, event, target, player, data)
    player.room:removePlayerMark(player, "@fenhui_hatred")
    data:changeDamage(1)
  end,
})

fenhui:addEffect(fk.Death, {
  anim_type = "special",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return table.contains(player:getTableMark("fenhui_target"), target.id) and target:getMark("@fenhui_hatred") > 0 and
      not player.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if player.dead then return false end
    if player:hasSkill("shouzhi", true) then
      room:handleAddLoseSkills(player, "-shouzhi|shouzhiEX", nil, false, true)
    end
    room:handleAddLoseSkills(player, "xingmen")
  end,
})

fenhui:addEffect(fk.TargetSpecified, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(fenhui.name, true) and
      data.to ~= player and not data.to.dead and
      player:usedSkillTimes(fenhui.name, Player.HistoryGame) == 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("fenhui_count")
    mark[tostring(data.to.id)] = (mark[tostring(data.to.id)] or 0) + 1
    room:setPlayerMark(player, "fenhui_count", mark)
  end,
})

fenhui:addAcquireEffect(function (self, player, is_start)
  if not is_start then
    local room = player.room
    local mark = {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
      local use = e.data
      if use.from == player then
        for _, p in ipairs(use.tos) do
          if p ~= player then
            mark[tostring(p.id)] = (mark[tostring(p.id)] or 0) + 1
          end
        end
      end
    end, Player.HistoryGame)
    room:setPlayerMark(player, "fenhui_count", mark)
  end
end)

return fenhui
