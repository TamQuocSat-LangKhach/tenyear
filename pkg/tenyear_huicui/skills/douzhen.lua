local douzhen = fk.CreateSkill {
  name = "douzhen",
  tags = { Skill.Switch, Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["douzhen"] = "斗阵",
  [":douzhen"] = "转换技，锁定技，你的回合内，阳：你的黑色基本牌视为【决斗】，且使用时获得目标一张牌；阴：你的红色基本牌视为【杀】，"..
  "且使用时无次数限制。",

  ["$douzhen1"] = "擂鼓击柝，庆我兄弟凯旋。",
  ["$douzhen2"] = "匹夫，欺我江东无人乎？",
}

douzhen:addEffect(fk.CardUsing, {
  anim_type = "switch",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(douzhen.name) and
      table.contains(data.card.skillNames, douzhen.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.card.trueName == "duel" then
      room:doIndicate(player, data.tos)
      local targets = table.simpleClone(data.tos)
      for _, p in ipairs(targets) do
        if player.dead then return end
        if not p.dead and not p:isNude() then
          local c = room:askToChooseCard(player, {
            target = p,
            flag = "he",
            skill_name = douzhen.name,
          })
          room:obtainCard(player, c, false, fk.ReasonPrey, player, douzhen.name)
        end
      end
    end
  end,
})

douzhen:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card.trueName == "slash" and table.contains(data.card.skillNames, douzhen.name)
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

douzhen:addEffect("filter", {
  mute = true,
  card_filter = function(self, card, player)
    if player:hasSkill(douzhen.name) and Fk:currentRoom().current == player and
      card.type == Card.TypeBasic and table.contains(player:getCardIds("h"), card.id) then
      if player:getSwitchSkillState(douzhen.name, false) == fk.SwitchYang then
        return card.color == Card.Black
      else
        return card.color == Card.Red
      end
    end
  end,
  view_as = function(self, player, card)
    local name = "slash"
    if player:getSwitchSkillState(douzhen.name, false) == fk.SwitchYang then
      name = "duel"
    end
    local c = Fk:cloneCard(name, card.suit, card.number)
    c.skillName = douzhen.name
    return c
  end,
})

douzhen:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, douzhen.name) and card.trueName == "slash"
  end,
})

return douzhen
