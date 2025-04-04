local baoshu = fk.CreateSkill {
  name = "baoshu",
}

Fk:loadTranslationTable{
  ["baoshu"] = "宝梳",
  [":baoshu"] = "准备阶段，你可以选择至多X名角色（X为你的体力上限），这些角色各获得一个“梳”标记并重置武将牌，你每少选一名角色，"..
  "每名目标角色便多获得一个“梳”。有“梳”标记的角色摸牌阶段多摸其“梳”数量的牌，然后移去其所有“梳”。",

  ["#baoshu-choose"] = "宝梳：你可以令至多%arg名角色获得“梳”标记，重置其武将牌且其摸牌阶段多摸牌",
  ["@fengyu_shu"] = "梳",

  ["$baoshu1"] = "明镜映梳台，黛眉衬粉面。",
  ["$baoshu2"] = "头作扶摇髻，首枕千金梳。",
}

baoshu:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(baoshu.name) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      skill_name = baoshu.name,
      min_num = 1,
      max_num = player.maxHp,
      targets = room.alive_players,
      prompt = "#baoshu-choose:::"..player.maxHp,
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = event:getCostData(self).tos
    local x = player.maxHp - #tos + 1
    for _, p in ipairs(tos) do
      if not p.dead then
        room:addPlayerMark(p, "@fengyu_shu", x)
        if p.chained then
          p:setChainState(false)
        end
      end
    end
  end,
})

baoshu:addEffect(fk.DrawNCards, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@fengyu_shu") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.n = data.n + player:getMark("@fengyu_shu")
    player.room:setPlayerMark(player, "@fengyu_shu", 0)
  end,
})

return baoshu
