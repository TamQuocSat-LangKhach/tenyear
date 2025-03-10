local zhangrong = fk.CreateSkill {
  name = "zhangrong"
}

Fk:loadTranslationTable{
  ['zhangrong'] = '掌戎',
  ['zhangrong_active'] = '掌戎',
  ['#zhangrong-invoke'] = '掌戎：选择角色各失去1点体力或各弃置一张手牌',
  ['zhangrong1'] = '失去体力',
  ['zhangrong2'] = '弃置手牌',
  [':zhangrong'] = '准备阶段，你可以选择一项：1.令至多X名体力值不小于你的角色各失去1点体力；2.令至多X名手牌数不小于你的角色各弃置一张手牌（X为你的体力值）。这些角色执行你选择的选项前，你摸选择角色数量的牌。本回合结束时，若这些角色中有存活且本回合未受到伤害的角色，你失去1点体力',
  ['$zhangrong1'] = '尔欲行大事，问过吾掌中兵刃否？',
  ['$zhangrong2'] = '西凉铁骑曳城，天下高楼可摧！',
}

zhangrong:addEffect(fk.EventPhaseStart, {
  global = false,
  can_trigger = function(self, event, target, player)
    return target == player and player.phase == Player.Start and player:hasSkill(zhangrong.name) and player.hp > 0
  end,
  on_cost = function(self, event, target, player)
    local _, dat = player.room:askToUseActiveSkill(player, {
      skill_name = "zhangrong_active",
      prompt = "#zhangrong-invoke",
      cancelable = true,
    })
    if dat then
      local tos = dat.targets
      player.room:sortPlayersByAction(tos)
      event:setCostData(self, {tos = tos, choice = dat.interaction})
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local targets = event:getCostData(self).tos
    room:setPlayerMark(player, "zhangrong-turn", targets)
    local choice = event:getCostData(self).choice
    player:drawCards(#targets, zhangrong.name)
    for _, id in ipairs(targets) do
      local p = room:getPlayerById(id)
      if not p.dead then
        if choice == "zhangrong1" then
          room:loseHp(p, 1, zhangrong.name)
        elseif choice == "zhangrong2" then
          room:askToDiscard(p, {
            min_num = 1,
            max_num = 1,
            include_equip = false,
            skill_name = zhangrong.name,
            cancelable = false,
          })
        end
      end
    end
  end,
})

zhangrong:addEffect(fk.TurnEnd, {
  global = false,
  can_trigger = function(self, event, target, player)
    if target == player and not player.dead and player:getMark("zhangrong-turn") ~= 0 then
      local playerIds = table.filter(player:getMark("zhangrong-turn"), function (pid)
        return not player.room:getPlayerById(pid).dead
      end)
      player.room.logic:getActualDamageEvents(1, function(e)
        table.removeOne(playerIds, e.data[1].to.id)
        return #playerIds == 0
      end)
      return #playerIds > 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    local room = player.room
    player:broadcastSkillInvoke("zhangrong")
    room:notifySkillInvoked(player, "zhangrong", "negative")
    room:loseHp(player, 1, zhangrong.name)
  end,
})

return zhangrong
