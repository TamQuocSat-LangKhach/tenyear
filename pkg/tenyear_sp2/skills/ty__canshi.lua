local ty__canshi = fk.CreateSkill {
  name = "ty__canshi"
}

Fk:loadTranslationTable{
  ['ty__canshi'] = '残蚀',
  ['#ty__canshi-invoke'] = '残蚀：你可以多摸 %arg 张牌',
  ['#ty__canshi_delay'] = '残蚀',
  [':ty__canshi'] = '摸牌阶段，你可以多摸X张牌（X为已受伤的角色数），若如此做，当你于此回合内使用【杀】或普通锦囊牌时，你弃置一张牌。',
  ['$ty__canshi1'] = '天地不仁，当视苍生为刍狗！',
  ['$ty__canshi2'] = '真龙天子，焉能不择人而噬！',
}

ty__canshi:addEffect(fk.DrawNCards, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty__canshi.name) and table.find(player.room.alive_players, function (p)
      return p:isWounded() or (player:hasSkill("guiming") and p.kingdom == "wu" and p ~= player)
    end)
  end,
  on_cost = function(self, event, target, player, data)
    local n = 0
    for _, p in ipairs(player.room.alive_players) do
      if p:isWounded() or (player:hasSkill("guiming") and p.kingdom == "wu" and p ~= player) then
        n = n + 1
      end
    end
    if player.room:askToSkillInvoke(player, {
      skill_name = ty__canshi.name,
      prompt = "#ty__canshi-invoke:::"..n
    }) then
      event:setCostData(skill, n)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data.n = data.n + event:getCostData(skill)
  end,
})

ty__canshi:addEffect(fk.CardUsing, {
  name = "#ty__canshi_delay",
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      player:usedSkillTimes(ty__canshi.name) > 0 and not player:isNude()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = ty__canshi.name,
      cancelable = false
    })
  end,
})

return ty__canshi
