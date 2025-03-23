local ty__neifa = fk.CreateSkill {
  name = "ty__neifa"
}

Fk:loadTranslationTable{
  ['ty__neifa'] = '内伐',
  ['@ty__neifa-phase'] = '内伐',
  ['#ty__neifa_trigger'] = '内伐',
  ['orMinus'] = '或减少',
  ['#ty__neifa-choose'] = '内伐：你可以为%arg增加%arg2一个目标',
  [':ty__neifa'] = '出牌阶段开始时，你可以摸三张牌，然后弃置一张牌。若弃置的牌为：基本牌，你于此阶段内不能使用锦囊牌、使用【杀】次数上限+X且可增加一个目标（X为发动技能后手牌中的锦囊牌数且至多为5）；锦囊牌，你于此阶段内不能使用基本牌、使用普通锦囊牌时可增加或减少一个目标（目标数至少为一）。',
  ['$ty__neifa1'] = '同室操戈，胜者王、败者寇。',
  ['$ty__neifa2'] = '兄弟无能，吾当继袁氏大统。',
}

ty__neifa:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty__neifa.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(3, ty__neifa.name)
    if player.dead then return false end
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = ty__neifa.name,
      cancelable = false,
      pattern = ".",
      skip = true,
    })
    if #card == 0 then return false end
    local card_type = Fk:getCardById(card[1]).type
    room:throwCard(card, ty__neifa.name, player, player)
    if player.dead then return false end
    if card_type == Card.TypeBasic then
      local cards = table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id).type == Card.TypeTrick end)
      room:setPlayerMark(player, "@ty__neifa-phase", "basic")
      room:setPlayerMark(player, "ty__neifa-phase", math.min(#cards, 5))
    elseif Fk:getCardById(card[1]).type == Card.TypeTrick then
      room:setPlayerMark(player, "@ty__neifa-phase", "trick")
    end
  end,
})

ty__neifa:addEffect('targetmod', {
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("@ty__neifa-phase") == "basic" and scope == Player.HistoryPhase then
      return player:getMark("ty__neifa-phase")
    end
  end,
})

ty__neifa:addEffect('prohibit', {
  prohibit_use = function(self, player, card)
    return (player:getMark("@ty__neifa-phase") == "basic" and card.type == Card.TypeTrick) or
      (player:getMark("@ty__neifa-phase") == "trick" and card.type == Card.TypeBasic)
  end,
})

ty__neifa:addEffect(fk.AfterCardTargetDeclared, {
  can_trigger = function(self, event, target, player, data)
    if player == target then
      local mark = player:getMark("@ty__neifa-phase")
      if data.card:isCommonTrick() and mark == "trick" then
        return true
      elseif data.card.trueName == "slash" and mark == "basic" then
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(ty__neifa.name)
    local room = player.room
    local targets = room:getUseExtraTargets(data, true)
    local can_minus = ""
    if data.card:isCommonTrick() then
      if #TargetGroup:getRealTargets(data.tos) > 1 then
        can_minus = "orMinus"
        table.insertTable(targets, TargetGroup:getRealTargets(data.tos))
      end
    end
    if #targets == 0 then return false end
    targets = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#ty__neifa-choose:::"..data.card:toLogString() .. ":" .. can_minus,
      skill_name = ty__neifa.name,
      cancelable = true,
      no_indicate = false,
      target_tip_name = "addandcanceltarget_tip",
      extra_data = TargetGroup:getRealTargets(data.tos),
    })
    if #targets == 0 then return false end
    if table.contains(TargetGroup:getRealTargets(data.tos), targets[1]) then
      TargetGroup:removeTarget(data.tos, targets[1])
    else
      table.insert(data.tos, targets)
    end
  end,
})

return ty__neifa
