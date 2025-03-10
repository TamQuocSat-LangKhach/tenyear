local pingliao = fk.CreateSkill {
  name = "pingliao"
}

Fk:loadTranslationTable{
  ['pingliao'] = '平辽',
  ['#pingliao-ask'] = '平辽：%src 使用了一张【杀】，你可以打出一张红色基本牌',
  ['@@pingliao-turn'] = '平辽',
  [':pingliao'] = '锁定技，当你使用【杀】时，不公开指定的目标，你攻击范围内的角色依次选择是否打出一张红色基本牌，若此【杀】的目标未打出基本牌，其本回合无法使用或打出手牌；若有至少一名非目标打出基本牌，你摸两张牌且此阶段使用【杀】的次数上限+1。',
  ['$pingliao1'] = '烽烟起大荒，戎军远役，问不臣者谁？',
  ['$pingliao2'] = '挥斥千军之贲，长驱万里之远。',
}

pingliao:addEffect(fk.CardUsing, {
  anim_type = "control",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(pingliao.name) and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getAlivePlayers(), function (p)
      return player:inMyAttackRange(p)
    end)
    room:doIndicate(player.id, table.map(targets, Util.IdMapper))
    local tos = TargetGroup:getRealTargets(data.tos)
    local drawcard = false
    local targets2 = {}
    for _, p in ipairs(targets) do
      local card = room:askToResponse(p, {
        skill_name = pingliao.name,
        pattern = ".|.|heart,diamond|.|.|basic",
        prompt = "#pingliao-ask:" .. player.id,
        cancelable = true
      })
      if card then
        room:responseCard{
          from = p.id,
          card = card.cardId
        }
        if not table.contains(tos, p.id) then
          drawcard = true
        end
      elseif table.contains(tos, p.id) then
        table.insert(targets2, p)
      end
    end
    for _, p in ipairs(targets2) do
      room:setPlayerMark(p, "@@pingliao-turn", 1)
    end
    if player.dead then return false end
    if drawcard then
      player:drawCards(2, pingliao.name)
      room:addPlayerMark(player, MarkEnum.SlashResidue .. "-phase")
    end
  end,
  can_refresh = function (self, event, target, player, data)
    return player == target and player:hasSkill(pingliao.name) and data.card.trueName == "slash"
  end,
  on_refresh = function (self, event, target, player, data)
    data.noIndicate = true
  end,
})

pingliao:addEffect(fk.PreCardUse, {
  prohibit_use = function(self, player, card)
    if player:getMark("@@pingliao-turn") > 0 then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds(Player.Hand), id)
      end)
    end
  end,
  prohibit_response = function(self, player, card)
    if player:getMark("@@pingliao-turn") > 0 then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds(Player.Hand), id)
      end)
    end
  end,
})

return pingliao
