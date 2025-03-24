local minghui = fk.CreateSkill {
  name = "minghui",
}

Fk:loadTranslationTable{
  ["minghui"] = "明慧",
  [":minghui"] = "一名角色的回合结束时，若你是手牌数最小的角色，你可以视为使用一张【杀】（无距离限制）。若你是手牌数最大的角色，"..
  "你可以将手牌弃置至不为全场最多，令一名角色回复1点体力。",

  ["#minghui-slash"] = "明慧：你可以视为使用【杀】",
  ["#minghui-discard"] = "明慧：你可以弃置至少%arg张手牌，然后令一名角色回复1点体力",
  ["#minghui-recover"] = "明慧：选择一名角色，令其回复1点体力",

  ["$minghui1"] = "大智若愚，女子之锦绣常隐于华服。",
  ["$minghui2"] = "知者不惑，心有明镜以照人。",
}

minghui:addEffect(fk.TurnEnd, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(minghui.name) then
      if table.every(player.room.alive_players, function (p)
        return p:getHandcardNum() >= player:getHandcardNum()
      end) then
        return player:canUse(Fk:cloneCard("slash"), {bypass_distances = true, bypass_times = true})
      end
      if table.every(player.room.alive_players, function (p)
        return p:getHandcardNum() <= player:getHandcardNum()
      end) then
        return not player:isKongcheng()
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if table.every(player.room.alive_players, function (p)
      return p:getHandcardNum() >= player:getHandcardNum()
    end) and
      player:canUse(Fk:cloneCard("slash"), {bypass_distances = true, bypass_times = true}) then
      local use = room:askToUseVirtualCard(player, {
        name = "slash",
        skill_name = minghui.name,
        prompt = "#minghui-slash",
        cancelable = true,
        extra_data = {
          bypass_distances = true,
          bypass_times = true,
          extraUse = true,
        },
        skip = true,
      })
      if use then
        event:setCostData(self, {choice = "slash", extra_data = use})
        return true
      end
    end
    if table.every(player.room.alive_players, function (p)
      return p:getHandcardNum() <= player:getHandcardNum()
    end) and not player:isKongcheng() then
      local n = player:getHandcardNum()
      repeat
        n = n - 1
      until table.find(player.room.alive_players, function (p)
        return p:getHandcardNum() > n
      end)
      n = player:getHandcardNum() - n
      local cards = room:askToDiscard(player, {
        min_num = n,
        max_num = 999,
        include_equip = false,
        skill_name = minghui.name,
        prompt = "#minghui-discard:::"..n,
        cancelable = true,
        skip = true,
      })
      if #cards > 0 then
        event:setCostData(self, {choice = "discard", cards = cards})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    if choice == "slash" then
      room:useCard(event:getCostData(self).extra_data)
    else
      room:throwCard(event:getCostData(self).cards, minghui.name, player, player)
      if player.dead then return end
      local targets = table.filter(room.alive_players, function (p)
        return p:isWounded()
      end)
      if #targets > 0 then
        local to = room:askToChoosePlayers(player, {
          skill_name = minghui.name,
          min_num = 1,
          max_num = 1,
          targets = targets,
          prompt = "#minghui-recover",
          cancelable = false,
        })[1]
        room:recover{
          who = to,
          num = 1,
          recoverBy = player,
          skillName = minghui.name,
        }
      end
    end
  end,
})

return minghui
