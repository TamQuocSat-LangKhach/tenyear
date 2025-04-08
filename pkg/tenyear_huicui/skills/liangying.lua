local liangying = fk.CreateSkill {
  name = "liangying",
}

Fk:loadTranslationTable{
  ["liangying"] = "粮营",
  [":liangying"] = "弃牌阶段开始时，你可以选择至多X名角色并摸等量张牌，然后交给其中每名其他角色各一张手牌（X为“粮”的数量）。",

  ["#liangying-choose"] = "粮营：选择至多 %arg 名角色并摸等量张牌，然后交给这些角色各一张手牌",
  ["#liangying-give"] = "粮营：交给这些角色各一张手牌",

  ["$liangying1"] = "酒气上涌，精神倍长。",
  ["$liangying2"] = "仲简在此，谁敢来犯？",
}

liangying:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(liangying.name) and player.phase == Player.Discard and
      player:getMark("@cangchu") > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local n = player:getMark("@cangchu")
    local tos = room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 1,
      max_num = n,
      prompt = "#liangying-choose:::"..n,
      skill_name = liangying.name,
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
    player:drawCards(#tos, liangying.name)
    if player.dead or player:isKongcheng() then return end
    tos = table.filter(tos, function(p)
      return not p.dead and p ~= player
    end)
    if #tos == 0 then return end
    local n = math.min(player:getHandcardNum(), #tos)
    room:askToYiji(player, {
      min_num = n,
      max_num = n,
      skill_name = liangying.name,
      targets = tos,
      cards = player:getCardIds("h"),
      prompt = "#liangying-give",
      single_max = 1,
    })
  end,
})

return liangying
