local ty__kuangfu = fk.CreateSkill {
  name = "ty__kuangfu"
}

Fk:loadTranslationTable{
  ['ty__kuangfu'] = '狂斧',
  ['#ty__kuangfu-active'] = '发动 狂斧，选择一名角色，弃置其一张装备牌',
  ['#ty__kuangfu-slash'] = '狂斧：选择视为使用【杀】的目标',
  [':ty__kuangfu'] = '出牌阶段限一次，你可以弃置场上的一张装备牌，视为使用一张【杀】（此【杀】无距离限制且不计次数）。若你弃置的不是你的牌且此【杀】未造成伤害，你弃置两张手牌；若弃置的是你的牌且此【杀】造成伤害，你摸两张牌。',
  ['$ty__kuangfu1'] = '大斧到处，片甲不留！',
  ['$ty__kuangfu2'] = '你可接得住我一斧？',
}

ty__kuangfu:addEffect('active', {
  prompt = "#ty__kuangfu-active",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(ty__kuangfu.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and #Fk:currentRoom():getPlayerById(to_select).player_cards[Player.Equip] > 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local id = room:askToChooseCard(player, {
      target = target,
      flag = "e",
      skill_name = ty__kuangfu.name
    })
    room:throwCard({id}, ty__kuangfu.name, target, player)
    if player.dead then return end
    local targets = {}
    local slash = Fk:cloneCard("slash")
    slash.skillName = ty__kuangfu.name
    if player:prohibitUse(slash) then return end
    for _, p in ipairs(room.alive_players) do
      if p ~= player and not player:isProhibited(p, slash) then
        table.insert(targets, p.id)
      end
    end
    if #targets == 0 then return end
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#ty__kuangfu-slash",
      skill_name = ty__kuangfu.name,
      cancelable = false
    })
    local use = {
      from = player.id,
      tos = { to },
      card = slash,
      extraUse = true,
    }
    room:useCard(use)
    if player.dead then return end
    if effect.from == effect.tos[1] and use.damageDealt then
      room:drawCards(player, 2, ty__kuangfu.name)
    elseif effect.from ~= effect.tos[1] and not use.damageDealt then
      room:askToDiscard(player, {
        min_num = 2,
        max_num = 2,
        include_equip = false,
        skill_name = ty__kuangfu.name,
        cancelable = false
      })
    end
  end,
})

return ty__kuangfu
