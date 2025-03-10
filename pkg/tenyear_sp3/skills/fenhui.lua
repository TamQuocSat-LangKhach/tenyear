local fenhui = fk.CreateSkill {
  name = "fenhui"
}

Fk:loadTranslationTable{
  ['fenhui'] = '奋恚',
  ['#fenhui-active'] = '发动 奋恚，令一名角色获得“恨”标记',
  ['fenhui_count'] = '奋恚 %arg',
  ['@fenhui_hatred'] = '恨',
  ['#fenhui_delay'] = '奋恚',
  ['xingmen'] = '兴门',
  [':fenhui'] = '限定技，出牌阶段，你可以令一名其他角色获得X枚“恨”（X为你对其使用过牌的次数且至多为5），你摸等量的牌。当其受到伤害时，其弃1枚“恨”且伤害值+1；当其死亡时，若其有“恨”，你减1点体力上限，失去〖守执〗，获得〖守执〗和〖兴门〗。',
  ['$fenhui1'] = '国仇家恨，不共戴天！',
  ['$fenhui2'] = '手中虽无青龙吟，心有长刀仍啸月。',
}

-- Active Skill
fenhui:addEffect('active', {
  anim_type = "offensive",
  frequency = Skill.Limited,
  prompt = "#fenhui-active",
  target_tip = function(self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    if not selectable then return end
    local x = math.min(Fk:currentRoom():getPlayerById(to_select):getMark("fenhui_count"), 5)
    return { {content = "fenhui_count:::".. tostring(x), type = "normal"} }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(fenhui.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id
      and Fk:currentRoom():getPlayerById(to_select):getMark("fenhui_count") > 0
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local n = math.min(target:getMark("fenhui_count"), 5)
    room:setPlayerMark(target, "@fenhui_hatred", n)
    room:setPlayerMark(player, "fenhui_target", target.id)
    for _, p in ipairs(room.alive_players) do
      room:setPlayerMark(p, "fenhui_count", 0)
    end
    player:drawCards(n, fenhui.name)
  end,
})

-- Trigger Skill
fenhui:addEffect(fk.DamageInflicted | fk.Death, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player.dead then return false end
    if event == fk.DamageInflicted then
      return player == target and player:getMark("@fenhui_hatred") > 0
    elseif event == fk.Death then
      return player:getMark("fenhui_target") == target.id and target:getMark("@fenhui_hatred") > 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    if event == fk.DamageInflicted then
      player.room:removePlayerMark(player, "@fenhui_hatred")
      data.damage = data.damage + 1
    elseif event == fk.Death then
      local room = player.room
      room:notifySkillInvoked(player, "fenhui")
      player:broadcastSkillInvoke("fenhui")
      room:changeMaxHp(player, -1)
      if player.dead then return false end
      local skills = "xingmen"
      if player:hasSkill(shouzhi, true) then
        skills = "-shouzhi|shouzhiEX|" .. skills
      end
      room:handleAddLoseSkills(player, skills, nil, true, false)
    end
  end,
  can_refresh = function(self, event, target, player, data)
    if event == fk.TargetSpecified then
      return player == target and player.id ~= data.to and player:hasSkill(fenhui, true) and
        player:usedSkillTimes("fenhui", Player.HistoryGame) == 0
    elseif event == fk.BuryVictim then
      return player:getMark("@fenhui_hatred") > 0 and table.every(player.room.alive_players, function (p)
        return p:getMark("fenhui_target") ~= player.id
      end)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetSpecified then
      local to = room:getPlayerById(data.to)
      if not to.dead then
        room:addPlayerMark(to, "fenhui_count")
      end
    else
      room:setPlayerMark(player, "@fenhui_hatred", 0)
    end
  end,
})

return fenhui
