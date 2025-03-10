local songci_skel = fk.CreateSkill {
  name = "ty__songci"
}

Fk:loadTranslationTable{
  ['ty__songci'] = '颂词',
  ['#songci-active'] = '颂词：选择1名角色',
  ['ty__songci_discard'] = '弃两张牌',
  ['#ty__songci_trigger'] = '颂词',
  [':ty__songci'] = '①出牌阶段，你可以选择一名角色（每名角色每局游戏限一次），若该角色的手牌数：不大于体力值，其摸两张牌；大于体力值，其弃置两张牌。②弃牌阶段结束时，若你对所有存活角色均发动过“颂词”，你摸一张牌。',
  ['$ty__songci1'] = '将军德才兼备，大汉之栋梁也！',
  ['$ty__songci2'] = '汝窃国奸贼，人人得而诛之！',
  ['$ty__songci3'] = '义军盟主，众望所归！',
}

-- Active Skill Effect
songci_skel:addEffect('active', {
  anim_type = "control",
  mute = true,
  prompt = "#songci-active",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    local mark = player:getTableMark(songci_skel.name)
    return table.find(Fk:currentRoom().alive_players, function(p) return not table.contains(mark, p.id) end)
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    local mark = player:getTableMark(songci_skel.name)
    return #selected == 0 and not table.contains(mark, to_select)
  end,
  target_tip = function(self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    if not selectable then return end
    local p = Fk:currentRoom():getPlayerById(to_select)
    if p:getHandcardNum() > p.hp then
      return { {content = "ty__songci_discard", type = "warning"} }
    else
      return { {content = "draw2", type = "normal"} }
    end
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local player = room:getPlayerById(effect.from)
    room:addTableMark(player, songci_skel.name, target.id)
    if #target.player_cards[Player.Hand] <= target.hp then
      room:notifySkillInvoked(player, songci_skel.name, "support")
      player:broadcastSkillInvoke(songci_skel.name, 1)
      target:drawCards(2, songci_skel.name)
    else
      room:notifySkillInvoked(player, songci_skel.name, "control")
      player:broadcastSkillInvoke(songci_skel.name, 2)
      room:askToDiscard(target, {
        min_num = 2,
        max_num = 2,
        include_equip = true,
        skill_name = songci_skel.name,
        cancelable = false,
      })
    end
  end,
})

-- Trigger Skill Effect
songci_skel:addEffect(fk.EventPhaseEnd, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    local mark = player:getTableMark("ty__songci")
    return target == player and player:hasSkill(songci_skel) and player.phase == Player.Discard
      and table.every(player.room.alive_players, function (p) return table.contains(mark, p.id) end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, songci_skel.name, "drawcard")
    player:broadcastSkillInvoke(songci_skel.name, 3)
    player:drawCards(1, songci_skel.name)
  end,
})

return songci_skel
