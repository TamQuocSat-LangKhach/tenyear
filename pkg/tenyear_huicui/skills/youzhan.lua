local youzhan = fk.CreateSkill {
  name = "youzhan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["youzhan"] = "诱战",
  [":youzhan"] = "锁定技，其他角色在你的回合失去牌后，你摸一张牌且此牌本回合不计入手牌上限，其本回合下次受到的伤害+1。"..
  "结束阶段，若这些角色本回合未受到过伤害，其摸X张牌（X为其本回合失去牌的次数，至多为3）。",

  ["@@youzhan-inhand-turn"] = "诱战",
  ["@youzhan-turn"] = "诱战",

  ["$youzhan1"] = "本将军在此！贼仲达何在？",
  ["$youzhan2"] = "以身为饵，诱老贼出营。",
  ["$youzhan3"] = "呔！尔等之胆略尚不如蜀地小儿。",
  ["$youzhan4"] = "我等引兵叫阵，魏狗必衔尾而来。",
}

youzhan:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(youzhan.name) and player.room.current == player then
      for _, move in ipairs(data) do
        if move.from and move.from ~= player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local targets = {}
    for _, move in ipairs(data) do
      if move.from and move.from ~= player then
        table.insertIfNeed(targets, move.from)
      end
    end
    player.room:sortByAction(targets)
    for _, p in pairs(targets) do
      if not player:hasSkill(youzhan.name) then break end
        event:setCostData(self, {tos = {p}})
        self:doCost(event, nil, player, data)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    player:drawCards(1, youzhan.name, nil, "@@youzhan-inhand-turn")
    if not to.dead then
      room:addPlayerMark(to, "@youzhan-turn", 1)
      room:addPlayerMark(to, "youzhan-turn", 1)
    end
  end,
})

youzhan:addEffect(fk.DamageInflicted, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player.room.current == player and target:getMark("@youzhan-turn") > 0
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(target:getMark("@youzhan-turn"))
    player.room:setPlayerMark(target, "@youzhan-turn", 0)
  end,
})

youzhan:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player.phase == Player.Finish and
      table.find(player.room.alive_players, function(p)
        return p:getMark("@youzhan-turn") > 0
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      if p:getMark("youzhan-turn") > 0 and
        #room.logic:getActualDamageEvents(1, function(e)
          return e.data.to == p
        end) == 0 then
        p:drawCards(math.min(p:getMark("youzhan-turn"), 3), youzhan.name)
      end
    end
  end,
})

youzhan:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return card:getMark("@@youzhan-inhand-turn") > 0
  end,
})

return youzhan
