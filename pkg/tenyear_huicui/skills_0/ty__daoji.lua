local ty__daoji = fk.CreateSkill {
  name = "ty__daoji"
}

Fk:loadTranslationTable{
  ['ty__daoji'] = '盗戟',
  ['ty__daoji_prohibit'] = '令其本回合不能出杀',
  ['ty__daoji_prey'] = '获得其使用的武器牌',
  ['#ty__daoji-choice'] = '盗戟：可选择获得%dest使用的%arg或令其本回合不能出杀',
  ['@@ty__daoji_prohibit-turn'] = '盗戟 不能出杀',
  [':ty__daoji'] = '当其他角色本局游戏第一次使用武器牌时，你可以选择一项：1.获得此武器牌；2.其本回合不能使用或打出【杀】。',
  ['$ty__daoji1'] = '典韦勇猛，盗戟可除。',
  ['$ty__daoji2'] = '你的，就是我的。',
}

-- TriggerSkill
ty__daoji:addEffect(fk.CardUsing, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(ty__daoji.name) and data.extra_data and data.extra_data.ty__daoji_triggerable
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {"ty__daoji_prohibit", "Cancel"}
    if room:getCardArea(data.card:getEffectiveId()) == Card.Processing then
      table.insert(choices, 1, "ty__daoji_prey")
    end
    event:setCostData(self, room:askToChoice(player, {
      choices = choices,
      skill_name = ty__daoji.name,
      prompt = "#ty__daoji-choice::" .. target.id .. ":" .. data.card:toLogString()
    }))
    return event:getCostData(self) ~= "Cancel"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event:getCostData(self) == "ty__daoji_prey" then
      if room:getCardArea(data.card:getEffectiveId()) == Card.Processing then
        room:obtainCard(player.id, data.card, true)
      end
    elseif event:getCostData(self) == "ty__daoji_prohibit" then
      room:addPlayerMark(target, "@@ty__daoji_prohibit-turn")
    end
  end,
})

-- RefreshEffect
ty__daoji:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("ty__daoji_used_weapon") == 0 and data.card.sub_type == Card.SubtypeWeapon
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "ty__daoji_used_weapon", 1)
    data.extra_data = data.extra_data or {}
    data.extra_data.ty__daoji_triggerable = true
  end,
})

-- ProhibitSkill
local ty__daoji_prohibit = fk.CreateProhibitSkill{
  name = "#ty__daoji_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("@@ty__daoji_prohibit-turn") > 0 and card.trueName == "slash"
  end,
  prohibit_response = function(self, player, card)
    return player:getMark("@@ty__daoji_prohibit-turn") > 0 and card.trueName == "slash"
  end,
}

return ty__daoji
