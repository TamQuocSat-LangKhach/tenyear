local zhangrong = fk.CreateSkill {
  name = "zhangrong",
}

Fk:loadTranslationTable{
  ["zhangrong"] = "掌戎",
  [":zhangrong"] = "准备阶段，你可以选择一项：1.令至多X名体力值不小于你的角色各失去1点体力；2.令至多X名手牌数不小于你的角色各弃置一张手牌"..
  "（X为你的体力值）。然后你摸选择角色数量的牌，这些角色依次执行选项。本回合结束时，若这些角色中有存活且本回合未受到伤害的角色，你失去1点体力。",

  ["#zhangrong-invoke"] = "掌戎：选择至多%arg名角色各失去1点体力或各弃置一张手牌",
  ["zhangrong1"] = "失去体力",
  ["zhangrong2"] = "弃置手牌",

  ["$zhangrong1"] = "尔欲行大事，问过吾掌中兵刃否？",
  ["$zhangrong2"] = "西凉铁骑曳城，天下高楼可摧！",
}

zhangrong:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhangrong.name) and player.phase == Player.Start and player.hp > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = player.room:askToUseActiveSkill(player, {
      skill_name = "zhangrong_active",
      prompt = "#zhangrong-invoke:::"..player.hp,
      cancelable = true,
    })
    if success and dat then
      local tos = dat.targets
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos, choice = dat.interaction})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = event:getCostData(self).tos
    local choice = event:getCostData(self).choice
    room:setPlayerMark(player, "zhangrong-turn", table.map(targets, Util.IdMapper))
    player:drawCards(#targets, zhangrong.name)
    for _, p in ipairs(targets) do
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
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and not player.dead and player:getMark("zhangrong-turn") ~= 0 then
      local ids = table.filter(player:getMark("zhangrong-turn"), function (id)
        return not player.room:getPlayerById(id).dead
      end)
      player.room.logic:getActualDamageEvents(1, function(e)
        table.removeOne(ids, e.data.to.id)
        return #ids == 0
      end)
      return #ids > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1, zhangrong.name)
  end,
})

return zhangrong
