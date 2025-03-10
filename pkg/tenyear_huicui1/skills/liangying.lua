local liangying = fk.CreateSkill {
  name = "liangying"
}

Fk:loadTranslationTable{
  ['liangying'] = '粮营',
  ['@cangchu'] = '粮',
  ['#liangying-choose'] = '粮营：选择至多 %arg 名角色并摸等量张牌，然后交给这些角色各一张手牌',
  ['#liangying-give'] = '粮营：交给 %dest 一张手牌',
  [':liangying'] = '弃牌阶段开始时，你可以摸选择至多X名角色并摸等量张牌，然后交给其中每名其他角色各一张手牌（X为“粮”的数量）。',
  ['$liangying1'] = '酒气上涌，精神倍长。',
  ['$liangying2'] = '仲简在此，谁敢来犯？',
}

liangying:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player)
    return player:hasSkill(liangying.name) and target == player and player.phase == Player.Discard and player:getMark("@cangchu") > 0
  end,
  on_cost = function (self, event, target, player)
    local room = player.room
    local n = player:getMark("@cangchu")
    local tos = player.room:askToChoosePlayers(player, {
      targets = table.map(player.room.alive_players, Util.IdMapper),
      min_num = 1,
      max_num = n,
      prompt = "#liangying-choose:::"..n,
      skill_name = liangying.name,
      cancelable = true
    })
    if #tos > 0 then
      event:setCostData(self, tos)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local tos = event:getCostData(self)
    room:sortPlayersByAction(tos)
    player:drawCards(#tos, liangying.name)
    for _, pid in ipairs(tos) do
      if player:isKongcheng() then break end
      local p = room:getPlayerById(pid)
      if not p.dead and p ~= player then
        local card = room:askToCards(player, {
          min_num = 1,
          max_num = 1,
          include_equip = false,
          skill_name = liangying.name,
          cancelable = false,
          prompt = "#liangying-give::"..pid
        })
        if #card > 0 then
          room:obtainCard(p, card[1], false, fk.ReasonGive)
        end
      end
    end
  end,
})

return liangying
