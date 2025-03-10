local jieling = fk.CreateSkill {
  name = "jieling"
}

Fk:loadTranslationTable{
  ['jieling'] = '介绫',
  ['#jieling-active'] = '发动 介绫，将两张花色不同的手牌当【杀】使用（无距离和次数限制）',
  ['@jieling-phase'] = '介绫',
  ['#jieling_delay'] = '介eling',
  ['@shengdu'] = '生妒',
  [':jieling'] = '出牌阶段每种花色限一次，你可以将两张花色不同的手牌当无距离和次数限制的【杀】使用。若此【杀】：造成伤害，其失去1点体力；没造成伤害，其获得一个“生妒”标记。',
  ['$jieling1'] = '来人，送冯氏上路！',
  ['$jieling2'] = '我有一求，请姐姐赴之。',
}

jieling:addEffect('active', {
  anim_type = "offensive",
  prompt = "#jieling-active",
  card_num = 2,
  min_target_num = 1,
  can_use = function(self, player)
    return #player:getTableMark("@jieling-phase") < 3
  end,
  card_filter = function(self, player, to_select, selected)
    if Fk:currentRoom():getCardArea(to_select) ~= Player.Equip then
      local card = Fk:getCardById(to_select)
      if card.suit == Card.NoSuit then return false end
      local record = player:getTableMark("@jieling-phase")
      if table.contains(record, card:getSuitString(true)) then return false end
      if #selected == 0 then
        return true
      elseif #selected == 1 then
        if card.suit ~= Fk:getCardById(selected[1]).suit then
          local slash = Fk:cloneCard("slash")
          slash.skillName = jieling.name
          slash:addSubcard(selected[1])
          slash:addSubcard(to_select)
          return not player:prohibitUse(slash)
        end
      else
        return false
      end
    end
  end,
  target_filter = function(self, player, to_select, selected, cards)
    if to_select == player.id then return false end
    local slash = Fk:cloneCard("slash")
    slash.skillName = jieling.name
    slash:addSubcards(cards)
    return #selected < slash.skill:getMaxTargetNum(player, slash) and
      not player:isProhibited(Fk:currentRoom():getPlayerById(to_select), slash)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local use = {
      from = player.id,
      tos = table.map(effect.tos, function (id)
        return {id}
      end),
      card = Fk:cloneCard("slash"),
      extra_data = {jielingUser = player.id},
      extraUse = true,
    }
    local record = player:getTableMark("@jieling-phase")
    for _, cid in ipairs(effect.cards) do
      use.card:addSubcard(cid)
      local suit = Fk:getCardById(cid):getSuitString(true)
      table.insertIfNeed(record, suit)
    end
    room:setPlayerMark(player, "@jieling-phase", record)
    use.card.skillName = jieling.name
    room:useCard(use)
  end,
})

jieling:addEffect(fk.CardUseFinished, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if not player.dead and data.extra_data and data.extra_data.jielingUser == player.id then
      local room = player.room
      local targets = TargetGroup:getRealTargets(data.tos)
      for _, pid in ipairs(targets) do
        if not room:getPlayerById(pid).dead then
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("jieling")
    local targets = TargetGroup:getRealTargets(data.tos)
    targets = table.filter(targets, function (pid)
      return not room:getPlayerById(pid).dead
    end)
    room:doIndicate(player.id, targets)
    for _, id in ipairs(targets) do
      local to = room:getPlayerById(id)
      if not to.dead then
        if data.damageDealt and data.damageDealt[id] then
          room:loseHp(to, 1, "jieling")
        elseif not table.every(room.alive_players, function (p)
            return not p:hasSkill(shengdu, true)
          end) then
          room:addPlayerMark(to, "@shengdu")
        end
      end
    end
  end,
})

return jieling
