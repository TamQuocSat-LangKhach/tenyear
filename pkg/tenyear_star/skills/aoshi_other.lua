local aoshi_other = fk.CreateSkill {
  name = "aoshi_other&"
}

Fk:loadTranslationTable{
  ['aoshi_other&'] = '傲势',
  ['#aoshi-active'] = '发动 傲势，选择一张手牌交给一名拥有“傲势”的角色',
  ['zongshiy'] = '纵势',
  ['#zongshiy-active'] = '发动 纵势，选择展示一张基本牌或普通锦囊牌',
  [':aoshi_other&'] = '出牌阶段限一次，你可将一张手牌交给星袁绍，然后其可以发动一次〖纵势〗。',
}

aoshi_other:addEffect('active', {
  anim_type = "support",
  prompt = "#aoshi-active",
  mute = true,
  can_use = function(self, player)
    if player.kingdom ~= "qun" then return false end
    local targetRecorded = player:getTableMark("aoshi_sources-phase")
    return table.find(Fk:currentRoom().alive_players, function(p)
      return p ~= player and p:hasSkill(aoshi.name) and not table.contains(targetRecorded, p.id)
    end)
  end,
  card_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected < 1 and Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerEquip
  end,
  target_num = 1,
  target_filter = function(self, player, to_select, selected)
    return
      #selected == 0 and to_select ~= player.id and
      Fk:currentRoom():getPlayerById(to_select):hasSkill(aoshi.name) and
      not table.contains(player:getTableMark("aoshi_sources-phase"), to_select)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:notifySkillInvoked(player, aoshi.name)
    target:broadcastSkillInvoke(aoshi.name)
    room:addTableMarkIfNeed(player, "aoshi_sources-phase", target.id)
    room:moveCardTo(effect.cards, Player.Hand, target, fk.ReasonGive, skill.name, nil, false, player.id)
    if target.dead then return end
    room:askToUseActiveSkill(target, {
      cancelable = true,
      prompt = "#zongshiy-active",
      skill_name = "zongshiy"
    })
  end,
})

return aoshi_other
