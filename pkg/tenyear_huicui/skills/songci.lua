local songci = fk.CreateSkill {
  name = "ty__songci",
}

Fk:loadTranslationTable{
  ["ty__songci"] = "颂词",
  [":ty__songci"] = "出牌阶段，你可以选择一项（每名角色限一次）：1.令一名手牌数不大于体力值的角色摸两张牌；2.令一名手牌数大于体力值的角色"..
  "弃置两张牌。弃牌阶段结束时，若你对所有存活角色均发动过“颂词”，你摸一张牌。",

  ["#ty__songci"] = "颂词：令一名手牌数小于体力值的角色摸两张牌，或令一名手牌数大于体力值的角色弃两张牌",

  ["$ty__songci1"] = "义军盟主，众望所归！",
  ["$ty__songci2"] = "汝阉人之后，本无懿德！",
}

songci:addEffect("active", {
  anim_type = "control",
  prompt = "#ty__songci",
  mute = true,
  card_num = 0,
  target_num = 1,
  can_use = Util.TrueFunc,
  card_filter = Util.FalseFunc,
  target_tip = function (self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    if table.contains(player:getTableMark(songci.name), to_select.id) then
      return nil
    elseif to_select:getHandcardNum() < to_select.hp then
      return { {content = "draw" , type = "normal"} }
    elseif to_select:getHandcardNum() > to_select.hp then
      return { {content = "discard", type = "warning"} }
    end
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and not table.contains(player:getTableMark(songci.name), to_select.id)
      and to_select:getHandcardNum() ~= to_select.hp
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMark(player, songci.name, target.id)
    if target:getHandcardNum() < target.hp then
      player:broadcastSkillInvoke(songci.name, 1)
      target:drawCards(2, songci.name)
    else
      player:broadcastSkillInvoke(songci.name, 2)
      room:askToDiscard(target, {
        min_num = 2,
        max_num = 2,
        include_equip = true,
        skill_name = songci.name,
        cancelable = false,
      })
    end
  end,
})
songci:addEffect(fk.EventPhaseEnd, {
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(songci.name) and player.phase == Player.Discard and
      table.every(player.room.alive_players, function (p)
        return table.contains(player:getTableMark(songci.name), p.id)
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player.room:notifySkillInvoked(player, songci.name, "drawcard")
    player:broadcastSkillInvoke(songci.name, 1)
    player:drawCards(1, songci.name)
  end,
})

return songci
