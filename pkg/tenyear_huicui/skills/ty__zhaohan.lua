local ty__zhaohan = fk.CreateSkill {
  name = "ty__zhaohan"
}

Fk:loadTranslationTable{
  ['ty__zhaohan'] = '昭汉',
  ['#ty__zhaohan_delay'] = '昭汉',
  ['#zhaohan-choose'] = '昭汉：选择一名没有手牌的角色交给其两张手牌，或点“取消”则你弃置两张牌',
  ['#zhaohan-give'] = '昭汉：选择两张手牌交给 %dest',
  ['#zhaohan-discard'] = '昭汉：弃置两张手牌',
  [':ty__zhaohan'] = '摸牌阶段，你可以多摸两张牌，然后选择一项：1.交给一名没有手牌的角色两张手牌；2.弃置两张手牌。',
  ['$ty__zhaohan1'] = '此心昭昭，惟愿汉明。',
  ['$ty__zhaohan2'] = '天曰昭德！天曰昭汉！'
}

ty__zhaohan:addEffect(fk.DrawNCards, {
  anim_type = "drawcard",
  on_use = function(self, event, target, player, data)
    data.n = data.n + 2
  end,
})

ty__zhaohan:addEffect(fk.EventPhaseEnd, {
  name = "#ty__zhaohan_delay",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and player:usedSkillTimes(ty__zhaohan.name, Player.HistoryPhase) > 0 and not player:isKongcheng()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p)
      return p:isKongcheng() 
    end), Util.IdMapper)

    if #targets > 0 then
      targets = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#zhaohan-choose",
        skill_name = ty__zhaohan.name,
        cancelable = true,
        no_indicate = true
      })
    end

    if #targets > 0 then
      local cards = player:getCardIds(Player.Hand)
      if #cards > 2 then
        cards = room:askToCards(player, {
          min_num = 2,
          max_num = 2,
          include_equip = false,
          skill_name = ty__zhaohan.name,
          cancelable = false,
          prompt = "#zhaohan-give::" .. targets[1]
        })
      end

      if #cards > 0 then
        room:moveCardTo(cards, Player.Hand, room:getPlayerById(targets[1]), fk.ReasonGive, ty__zhaohan.name, nil, false, player.id)
      end
    else
      room:askToDiscard(player, {
        min_num = 2,
        max_num = 2,
        include_equip = false,
        skill_name = ty__zhaohan.name,
        cancelable = false,
        prompt = "#zhaohan-discard"
      })
    end
  end,
})

return ty__zhaohan
