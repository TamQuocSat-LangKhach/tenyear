local quanmou = fk.CreateSkill {
  name = "quanmou"
}

Fk:loadTranslationTable{
  ['quanmou'] = '权谋',
  ['#quanmou-Yang'] = '发动 权谋（阳），选择攻击范围内的一名角色',
  ['#quanmou-Yin'] = '发动 权谋（阴），选择攻击范围内的一名角色',
  ['#quanmou-give'] = '权谋：选择一张牌交给 %dest ',
  ['@quanmou-phase'] = '权谋',
  ['#quanmou_delay'] = '权谋',
  ['#quanmou-damage'] = '权谋：你可以选择1-3名角色，对这些角色各造成1点伤害',
  ['#quanmou_switch'] = '权谋',
  [':quanmou'] = '转换技，游戏开始时可自选阴阳状态，出牌阶段每名角色限一次，你可以令攻击范围内的一名其他角色交给你一张牌，阳：防止你此阶段下次对其造成的伤害；阴：你此阶段下次对其造成伤害后，可以对至多三名该角色外的其他角色各造成1点伤害。',
  ['$quanmou1'] = '洛水为誓，皇天为证，吾意不在刀兵。',
  ['$quanmou2'] = '以谋代战，攻形不以力，攻心不以勇。',
}

-- 主动技能效果
quanmou:addEffect('active', {
  anim_type = "switch",
  switch_skill_name = "quanmou",
  card_num = 0,
  target_num = 1,
  prompt = function (self, player)
    return self:getSwitchSkillState("quanmou", false) == fk.SwitchYang and "#quanmou-Yang" or "#quanmou-Yin"
  end,
  can_use = Util.TrueFunc,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected == 0 and not table.contains(player:getTableMark("quanmou_targets-phase"), to_select) then
      local target = Fk:currentRoom():getPlayerById(to_select)
      return not target:isNude() and player:inMyAttackRange(target)
    end
  end,
  on_use = function(self, room, effect, player)
    local target = room:getPlayerById(effect.tos[1])
    room:addTableMark(player, "quanmou_targets-phase", target.id)

    setTYMouSwitchSkillState(player, "simayi", quanmou.name)
    local switch_state = player:getSwitchSkillState(quanmou.name, true, true)

    local card = room:askToCards(target, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      pattern = ".",
      prompt = "#quanmou-give::" .. player.id,
      skill_name = quanmou.name
    })
    room:obtainCard(player.id, card[1], false, fk.ReasonGive, target.id)
    if player.dead or target.dead then return false end
    room:setPlayerMark(target, "@quanmou-phase", switch_state)
    local mark_name = "quanmou_" .. switch_state .. "-phase"
    room:addTableMark(player, mark_name, target.id)
  end,
})

-- 触发技能效果（延迟）
quanmou:addEffect(fk.DamageCaused, {
  mute = true,
  can_trigger = function(self, event, player, data)
    if player.dead or player.phase ~= Player.Play or not player:isSelf() then return false end
    local target = Fk:currentRoom():getPlayerById(data.to.id)
    return table.contains(player:getTableMark("quanmou_yang-phase"), target.id)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, player, data)
    local room = player.room
    room:doIndicate(player.id, {data.to.id})
    room:setPlayerMark(data.to, "@quanmou-phase", 0)
    room:removeTableMark(player, "quanmou_yang-phase", data.to.id)
    room:notifySkillInvoked(player, quanmou.name, "defensive")
    if player:getSwitchSkillState(quanmou.name, false) == fk.SwitchYang then
      player:broadcastSkillInvoke(quanmou.name)
    end
  end,
})

-- 触发技能效果（延迟）
quanmou:addEffect(fk.Damage, {
  mute = true,
  can_trigger = function(self, event, player, data)
    if player.dead or player.phase ~= Player.Play or not player:isSelf() then return false end
    local target = Fk:currentRoom():getPlayerById(data.to.id)
    return table.contains(player:getTableMark("quanmou_yin-phase"), target.id)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, player, data)
    local room = player.room
    room:doIndicate(player.id, {data.to.id})
    room:setPlayerMark(data.to, "@quanmou-phase", 0)
    room:removeTableMark(player, "quanmou_yin-phase", data.to.id)
    room:notifySkillInvoked(player, quanmou.name, "offensive")
    if player:getSwitchSkillState(quanmou.name, false) == fk.SwitchYin then
      player:broadcastSkillInvoke(quanmou.name)
    end
    local targets = table.filter(room.alive_players, function (p)
      return p ~= player and p ~= data.to
    end)
    if #targets == 0 then return false end
    targets = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 3,
      prompt = "#quanmou-damage",
      skill_name = quanmou.name,
      targets = table.map(targets, Util.IdMapper)
    })
    if #targets == 0 then return false end
    room:sortPlayersByAction(targets)
    for _, id in ipairs(targets) do
      local p = room:getPlayerById(id)
      if not p.dead then
        room:damage{
          from = player,
          to = p,
          damage = 1,
          skillName = quanmou.name,
        }
      end
    end
  end,
})

-- 触发技能效果（切换状态）
quanmou:addEffect(fk.GameStart, {
  mute = true,
  can_trigger = function(self, event, player)
    return player:hasSkill(quanmou.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, player)
    setTYMouSwitchSkillState(player, "simayi", quanmou.name,
      room:askToChoice(player, {
        choices = { "tymou_switch:::"..quanmou.name..":yang", "tymou_switch:::"..quanmou.name..":yin" },
        prompt = "#tymou_switch-transer:::"..quanmou.name,
        skill_name = quanmou.name
      }) == "tymou_switch:::"..quanmou.name..":yin")
  end,
})

return quanmou
