local yuanyu = fk.CreateSkill {
  name = "yuanyu"
}

Fk:loadTranslationTable{
  ['yuanyu'] = '怨语',
  ['#yuanyu'] = '怨语：你可以摸一张牌，然后放置一张手牌作为“怨”',
  ['#yuanyu_resent'] = '怨',
  ['#yuanyu-choose'] = '怨语：选择作为“怨”的一张手牌以及作为目标的一名其他角色',
  ['@@yuanyu'] = '怨语',
  ['#yuanyu_trigger'] = '怨语',
  ['#yuanyu-push'] = '怨语：选择一张手牌作为%src的“怨”',
  ['@[yuanyu_resent]'] = '怨',
  [':yuanyu'] = '出牌阶段限一次，你可以摸一张牌并将一张手牌置于武将牌上，称为“怨”。然后选择一名其他角色，你与其的弃牌阶段开始时，该角色每次造成1点伤害后也须放置一张“怨”直到你触发〖夕颜〗。',
  ['$yuanyu1'] = '此生最恨者，吴垣孙氏人。',
  ['$yuanyu2'] = '愿为宫外柳，不做建章卿。',
}

yuanyu:addEffect('active', {
  anim_type = "control",
  prompt = "#yuanyu",
  derived_piles = "#yuanyu_resent",
  can_use = function(self, player)
    return player:usedSkillTimes(yuanyu.name, Player.HistoryPhase) < 1 + player:getMark("yuanyu_extra_times-phase")
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:drawCards(player, 1, yuanyu.name)
    if player.dead or player:isKongcheng() then return end
    local targets = room:getOtherPlayers(player, false)
    if #targets == 0 then return end
    local tar, card = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      targets = table.map(targets, Util.IdMapper),
      pattern = ".|.|.|hand",
      prompt = "#yuanyu-choose",
      skill_name = yuanyu.name,
      cancelable = false
    })
    if #tar > 0 and card then
      local targetRecorded = player:getTableMark("yuanyu_targets")
      if not table.contains(targetRecorded, tar[1]) then
        table.insert(targetRecorded, tar[1])
        room:setPlayerMark(player, "yuanyu_targets", targetRecorded)
        room:addPlayerMark(room:getPlayerById(tar[1]), "@@yuanyu")
      end
      player:addToPile("#yuanyu_resent", card, true, yuanyu.name)
    end
  end,
})

yuanyu:addEffect(fk.Damage, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(yuanyu) then
      return target and not target:isKongcheng() and table.contains(player:getTableMark("yuanyu_targets"), target.id)
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("yuanyu")
    if not to.dead and not to:isKongcheng() and table.contains(targetRecorded, to.id) then
      local card = room:askToCards(to, {
        min_num = 1,
        max_num = 1,
        pattern = ".|.|.|hand",
        prompt = "#yuanyu-push:" .. player.id,
        skill_name = yuanyu.name
      })
      player:addToPile("#yuanyu_resent", card[1], true, yuanyu.name)
    end
  end,
})

yuanyu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(yuanyu) then
      if target.phase == Player.Discard then
        if target == player then
          return table.find(player:getTableMark("yuanyu_targets"), function (pid)
            local p = player.room:getPlayerById(pid)
            return not p:isKongcheng() and not p.dead end)
        else
          return not target:isKongcheng() and table.contains(player:getTableMark("yuanyu_targets"), target.id)
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("yuanyu")
    local tos = {}
    if event == fk.EventPhaseStart and target == player then
      local targetRecorded = player:getMark("yuanyu_targets")
      tos = table.filter(room:getAlivePlayers(), function (p) return table.contains(targetRecorded, p.id) end)
    else
      table.insert(tos, target)
    end
    room:doIndicate(player.id, table.map(tos, Util.IdMapper))
    for _, to in ipairs(tos) do
      if player.dead then break end
      local targetRecorded = player:getMark("yuanyu_targets")
      if targetRecorded == 0 then break end
      if not to.dead and not to:isKongcheng() and table.contains(targetRecorded, to.id) then
        local card = room:askToCards(to, {
          min_num = 1,
          max_num = 1,
          pattern = ".|.|.|hand",
          prompt = "#yuanyu-push:" .. player.id,
          skill_name = yuanyu.name
        })
        player:addToPile("#yuanyu_resent", card[1], true, yuanyu.name)
      end
    end
  end,
})

yuanyu:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return #player:getTableMark("@[yuanyu_resent]") ~= #player:getPile("#yuanyu_resent")
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      local cards = player:getPile("#yuanyu_resent")
      room:setPlayerMark(player, "@[yuanyu_resent]", #cards > 0 and cards or 0)
      return false
    end
  end,
})

yuanyu:addEffect(fk.EventLoseSkill, {
  can_refresh = function(self, event, target, player, data)
    if data ~= yuanyu then return false end
    return player == target and type(player:getMark("yuanyu_targets")) == "table"
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local targets = player:getMark("yuanyu_targets")
    if type(targets) == "table" then
      for _, pid in ipairs(targets) do
        room:removePlayerMark(room:getPlayerById(pid), "@@yuanyu")
      end
    end
    room:setPlayerMark(player, "yuanyu_targets", 0)
  end,
})

yuanyu:addEffect(fk.Death, {
  can_refresh = function(self, event, target, player, data)
    return player == target and type(player:getMark("yuanyu_targets")) == "table"
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local targets = player:getMark("yuanyu_targets")
    if type(targets) == "table" then
      for _, pid in ipairs(targets) do
        room:removePlayerMark(room:getPlayerById(pid), "@@yuanyu")
      end
    end
    room:setPlayerMark(player, "yuanyu_targets", 0)
  end,
})

return yuanyu
