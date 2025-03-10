local zigu = fk.CreateSkill {
  name = "zigu"
}

Fk:loadTranslationTable{
  ['zigu'] = '自固',
  ['#zigu'] = '自固：你可以弃置一张牌，然后获得场上一张装备牌',
  ['#zigu-choose'] = '自固：选择一名角色，获得其场上一张装备牌',
  ['#zigu-prey'] = '自固：获得 %dest 场上一张装备牌',
  [':zigu'] = '出牌阶段限一次，你可以弃置一张牌，然后获得场上一张装备牌。若你没有因此获得其他角色的牌，你摸一张牌。',
  ['$zigu1'] = '卿有成材良木，可妆吾家江山。',
  ['$zigu2'] = '吾好锦衣玉食，卿家可愿割爱否？'
}

zigu:addEffect('active', {
  anim_type = "control",
  card_num = 1,
  target_num = 0,
  prompt = "#zigu",
  can_use = function(self, player)
    return player:usedSkillTimes(zigu.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(Fk:getCardById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, zigu.name, player, player)
    if player.dead then return end
    local targets = table.map(table.filter(room.alive_players, function(p)
      return #p:getCardIds("e") > 0
    end), Util.IdMapper)
    if #targets > 0 then
      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#zigu-choose",
        skill_name = zigu.name,
        cancelable = false
      })
      to = room:getPlayerById(to[1])
      local id = room:askToChooseCard(player, {
        target = to,
        flag = "e",
        skill_name = zigu.name,
        prompt = "#zigu-prey::" .. to.id
      })
      room:moveCardTo(Fk:getCardById(id), Card.PlayerHand, player, fk.ReasonPrey, zigu.name, nil, true, player.id)
      if not player.dead and to == player then
        player:drawCards(1, zigu.name)
      end
    else
      player:drawCards(1, zigu.name)
    end
  end,
})

return zigu
