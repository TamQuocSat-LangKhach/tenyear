local xionghuo = fk.CreateSkill {
  name = "xionghuo"
}

Fk:loadTranslationTable{
  ['xionghuo'] = '凶镬',
  ['#xionghuo-active'] = '发动 凶镬，将“暴戾”交给其他角色',
  ['@baoli'] = '暴戾',
  ['#xionghuo_record'] = '凶镬',
  [':xionghuo'] = '游戏开始时，你获得3个“暴戾”标记（标记上限为3）。出牌阶段，你可以交给一名其他角色一个“暴戾”标记，你对有此标记的其他角色造成的伤害+1，且其出牌阶段开始时，移去“暴戾”并随机执行一项：1.受到1点火焰伤害且本回合不能对你使用【杀】；2.流失1点体力且本回合手牌上限-1；3.你随机获得其两张牌。',
  ['$xionghuo1'] = '此镬加之于你，定有所伤！',
  ['$xionghuo2'] = '凶镬沿袭，怎会轻易无伤？',
}

-- Active Skill
xionghuo:addEffect('active', {
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#xionghuo-active",
  can_use = function(self, player)
    return player:getMark("@baoli") > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id and Fk:currentRoom():getPlayerById(to_select):getMark("@baoli") == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:removePlayerMark(player, "@baoli", 1)
    room:addPlayerMark(target, "@baoli", 1)
  end,
})

-- Trigger Skill
xionghuo:addEffect(fk.GameStart | fk.DamageCaused | fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(xionghuo.name) then
      if event == fk.GameStart then
        return player:getMark("@baoli") < 3
      elseif event == fk.DamageCaused then
        return target == player and data.to ~= player and data.to:getMark("@baoli") > 0
      else
        return target ~= player and target:getMark("@baoli") > 0 and target.phase == Player.Play
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(xionghuo.name)
    if event == fk.GameStart then
      room:setPlayerMark(player, "@baoli", 3)
    elseif event == fk.DamageCaused then
      room:doIndicate(player.id, {data.to.id})
      data.damage = data.damage + 1
    else
      room:doIndicate(player.id, {target.id})
      room:removePlayerMark(target, "@baoli", 1)
      local rand = math.random(1, target:isNude() and 2 or 3)
      if rand == 1 then
        room:damage {
          from = player,
          to = target,
          damage = 1,
          damageType = fk.FireDamage,
          skillName = xionghuo.name,
        }
        room:addTableMark(target, "xionghuo_prohibit-turn", player.id)
      elseif rand == 2 then
        room:loseHp(target, 1, xionghuo.name)
        room:addPlayerMark(target, "MinusMaxCards-turn", 1)
      else
        local cards = table.random(target:getCardIds{Player.Hand, Player.Equip}, 2)
        room:moveCardTo(cards, Player.Hand, player, fk.ReasonPrey, xionghuo.name, "", false, player.id)
      end
    end
  end,
})

-- Prohibit Skill
xionghuo:addEffect('prohibit', {
  is_prohibited = function(self, from, to, card)
    return card.trueName == "slash" and table.contains(from:getTableMark("xionghuo_prohibit-turn") ,to.id)
  end,
})

return xionghuo
