local zuojian = fk.CreateSkill {
  name = "zuojian"
}

Fk:loadTranslationTable{
  ['zuojian'] = '佐谏',
  ['zuojian1'] = '装备区牌数大于你的角色各摸一张牌',
  ['zuojian2'] = '你弃置装备区牌数小于你的角色各一张手牌',
  ['@zuojian-phase'] = '佐谏',
  [':zuojian'] = '出牌阶段结束时，若你此阶段使用的牌数大于等于你的体力值，你可以选择一项：1.令装备区牌数大于你的角色摸一张牌；2.弃置装备区牌数小于你的每名角色各一张手牌。',
  ['$zuojian1'] = '关羽者，刘备之枭将，宜除之。',
  ['$zuojian2'] = '主公虽非赵简子，然某可为周舍。',
}

zuojian:addEffect(fk.EventPhaseEnd, {
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(zuojian.name) and player.phase == Player.Play and
      player:getMark("zuojian-phase") >= player.hp and
      (#table.filter(player.room:getOtherPlayers(player), function(p)
        return #p.player_cards[Player.Equip] > #player.player_cards[Player.Equip]
      end) > 0 or
      #table.filter(player.room:getOtherPlayers(player), function(p)
        return #p.player_cards[Player.Equip] < #player.player_cards[Player.Equip] and not p:isKongcheng()
      end) > 0)
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local choices = {}
    local targets1 = table.filter(player.room:getOtherPlayers(player), function(p)
      return #p.player_cards[Player.Equip] > #player.player_cards[Player.Equip]
    end)
    local targets2 = table.filter(player.room:getOtherPlayers(player), function(p)
      return #p.player_cards[Player.Equip] < #player.player_cards[Player.Equip] and not p:isKongcheng()
    end)

    if #targets1 > 0 then
      table.insert(choices, "zuojian1")
    end

    if #targets2 > 0 then
      table.insert(choices, "zuojian2")
    end

    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = zuojian.name
    })

    if choice == "zuojian1" then
      room:doIndicate(player.id, table.map(targets1, Util.IdMapper))
      for _, p in ipairs(targets1) do
        p:drawCards(1, zuojian.name)
      end
    end

    if choice == "zuojian2" then
      room:doIndicate(player.id, table.map(targets2, Util.IdMapper))
      for _, p in ipairs(targets2) do
        local id = room:askToChooseCard(player, {
          target = p,
          flag = "h",
          skill_name = zuojian.name
        })
        room:throwCard({id}, zuojian.name, p, player)
      end
    end
  end,

  can_refresh = function(self, event, target, player)
    if target == player and player.phase == Player.Play then
      if event == fk.CardUsing then
        return target == player
      else
        return data == skill and player.room:getBanner("RoundCount")
      end
    end
  end,

  on_refresh = function(self, event, target, player)
    local room = player.room

    if event == fk.CardUsing then
      room:addPlayerMark(player, "zuojian-phase", 1)

      if player:hasSkill(zuojian.name, true) then
        room:addPlayerMark(player, "@zuojian-phase", 1)
      end

    else
      local events = room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
        local use = e.data[1]
        return use.from == player.id
      end, Player.HistoryPhase)

      room:addPlayerMark(player, "zuojian-phase", #events)
      room:addPlayerMark(player, "@zuojian-phase", #events)
    end
  end,
})

return zuojian
