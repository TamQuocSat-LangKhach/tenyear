local minghui = fk.CreateSkill {
  name = "minghui"
}

Fk:loadTranslationTable{
  ['minghui'] = '明慧',
  ['#minghui-slash'] = '明慧：你可以视为使用【杀】',
  ['#minghui-discard'] = '明慧：你可以弃置至少%arg张手牌，然后令一名角色回复1点体力',
  ['#minghui-recover'] = '明慧：选择一名角色，令其回复1点体力',
  [':minghui'] = '一名角色的回合结束时，若你是手牌数最小的角色，你可视为使用一张【杀】（无距离关系的限制）。若你是手牌数最大的角色，你可将手牌弃置至不为全场最多，令一名角色回复1点体力。',
  ['$minghui1'] = '大智若愚，女子之锦绣常隐于华服。',
  ['$minghui2'] = '知者不惑，心有明镜以照人。',
}

minghui:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player)
    if player:hasSkill(minghui.name) then
      local x = player:getHandcardNum()
      if x == 0 then return true end
      local minghui_max, minghui_min, all_kongcheng = true, true, true
      local y = 0
      for _, p in ipairs(player.room.alive_players) do
        if p ~= player then
          y = p:getHandcardNum()
          if y > 0 then
            all_kongcheng = false
          end
          if x > y then
            minghui_min = false
          elseif x < y then
            minghui_max = false
          end
        end
      end
      return (minghui_max and not all_kongcheng) or minghui_min
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    local room = player.room
    local x = player:getHandcardNum()
    if table.every(room.alive_players, function (p)
      return p:getHandcardNum() >= x
    end) then
      if U.askForUseVirtualCard(room, player, "slash", {}, minghui.name, "#minghui-slash", true, true, true, true) then
        if player.dead then return false end
        x = player:getHandcardNum()
      end
    end
    if player:isKongcheng() or #room.alive_players < 2 then return false end
    local y, z = 0, 0
    for _, p in ipairs(room.alive_players) do
      if player ~= p then
        y = p:getHandcardNum()
        if y > x then return false end
        if y > z then
          z = y
        end
      end
    end
    if z == 0 then return false end
    y = x-z+1
    local discards = room:askToDiscard(player, {
      min_num = y,
      max_num = x,
      include_equip = false,
      skill_name = minghui.name,
      cancelable = true,
      pattern = ".",
      prompt = "#minghui-discard:::" .. tostring(y),
    })
    if #discards > 0 and not player.dead then
      local targets = table.map(table.filter(room.alive_players, function (p)
        return p:isWounded()
      end), Util.IdMapper)
      if #targets > 0 then
        targets = room:askToChoosePlayers(player, {
          targets = targets,
          min_num = 1,
          max_num = 1,
          prompt = "#minghui-recover",
          skill_name = minghui.name,
        })
        room:recover({
          who = room:getPlayerById(targets[1]),
          num = 1,
          recoverBy = player,
          skillName = minghui.name,
        })
      end
    end
  end,
})

return minghui
