local youzhan = fk.CreateSkill {
  name = "youzhan"
}

Fk:loadTranslationTable{
  ['youzhan'] = '诱战',
  ['@@youzhan-inhand-turn'] = '诱战',
  ['@youzhan-turn'] = '诱战',
  [':youzhan'] = '锁定技，其他角色在你的回合失去牌后，你摸一张牌且此牌本回合不计入手牌上限，其本回合下次受到的伤害+1。结束阶段，若这些角色本回合未受到过伤害，其摸X张牌（X为其本回合失去牌的次数，至多为3）。',
  ['$youzhan1'] = '本将军在此！贼仲达何在？',
  ['$youzhan2'] = '以身为饵，诱老贼出营。',
  ['$youzhan3'] = '呔！尔等之胆略尚不如蜀地小儿。',
  ['$youzhan4'] = '我等引兵叫阵，魏狗必衔尾而来。',
}

youzhan:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    local room = player.room
    if player:hasSkill(youzhan.name) and room.current == player then
      for _, move in ipairs(data) do
        if move.from and move.from ~= player.id then
          local from_player = room:getPlayerById(move.from)
          if from_player and not from_player.dead then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                return true
              end
            end
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local numMap = {}
    for _, move in ipairs(data) do
      if move.from and move.from ~= player.id then
        numMap[move.from] = (numMap[move.from] or 0) + #table.filter(move.moveInfo, function(info)
          return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip
        end)
      end
    end
    for pid, num in pairs(numMap) do
      if not player:hasSkill(youzhan.name) then break end
      local from = room:getPlayerById(pid)
      if not from.dead then
        event:setCostData(skill, {tos = {pid}})
        skill:doCost(event, from, player, num)
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, youzhan.name, nil, "@@youzhan-inhand-turn")
    if not target.dead then
      room:addPlayerMark(target, "@youzhan-turn", 1)
      room:addPlayerMark(target, "youzhan-turn", 1)
    end
  end,
})

youzhan:addEffect(fk.DamageInflicted, {
  mute = true,
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if target == player then
      return player:getMark("youzhan-turn") > 0 and player:getMark("@youzhan-turn") > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if room.current then
      room.current:broadcastSkillInvoke("youzhan")
      room:notifySkillInvoked(room.current, "youzhan", "offensive", {player.id})
      room:doIndicate(room.current.id, {player.id})
    end
    data.damage = data.damage + player:getMark("@youzhan-turn")
    room:setPlayerMark(player, "@youzhan-turn", 0)
  end,
})

youzhan:addEffect(fk.EventPhaseStart, {
  mute = true,
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player.phase == Player.Finish and table.find(player.room.alive_players, function(p) return p:getMark("@youzhan-turn") > 0 end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("youzhan")
    room:notifySkillInvoked(player, "youzhan", "drawcard")
    for _, p in ipairs(room:getAlivePlayers()) do
      if p:getMark("youzhan-turn") > 0 and
        #room.logic:getActualDamageEvents(1, function(e) return e.data[1].to == p end) == 0 then
        room:doIndicate(player.id, {p.id})
        p:drawCards(math.min(p:getMark("youzhan-turn"), 3), "youzhan")
      end
    end
  end,
})

youzhan:addEffect('maxcards', {
  exclude_from = function(self, player, card)
    return card:getMark("@@youzhan-inhand-turn") > 0
  end,
})

return youzhan
