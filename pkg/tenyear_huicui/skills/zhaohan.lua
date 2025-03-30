local zhaohan = fk.CreateSkill {
  name = "ty__zhaohan",
}

Fk:loadTranslationTable{
  ["ty__zhaohan"] = "昭汉",
  [":ty__zhaohan"] = "摸牌阶段，你可以多摸两张牌，然后选择一项：1.交给一名没有手牌的角色两张手牌；2.弃置两张手牌。",

  ["#ty__zhaohan-give"] = "昭汉：将两张手牌交给一名没有手牌的角色，或点“取消”则你弃置两张牌",

  ["$ty__zhaohan1"] = "此心昭昭，惟愿汉明。",
  ["$ty__zhaohan2"] = "天曰昭德！天曰昭汉！"
}

zhaohan:addEffect(fk.DrawNCards, {
  anim_type = "drawcard",
  on_use = function(self, event, target, player, data)
    data.n = data.n + 2
  end,
})

zhaohan:addEffect(fk.AfterDrawNCards, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes(zhaohan.name, Player.HistoryPhase) > 0 and
      not player.dead and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return p:isKongcheng()
    end)
    if #targets > 0 and player:getHandcardNum() > 1 then
      local to, cards = room:askToChooseCardsAndPlayers(player, {
        min_card_num = 2,
        max_card_num = 2,
        min_num = 1,
        max_num = 1,
        targets = targets,
        pattern = ".|.|.|hand",
        skill_name = zhaohan.name,
        prompt = "#ty__zhaohan-give",
        cancelable = true,
      })
      if #to > 0 and #cards > 0 then
        room:moveCardTo(cards, Player.Hand, to[1], fk.ReasonGive, zhaohan.name, nil, false, player)
        return
      end
    end
    room:askToDiscard(player, {
      min_num = 2,
      max_num = 2,
      include_equip = false,
      skill_name = zhaohan.name,
      cancelable = false,
    })
  end,
})

return zhaohan
