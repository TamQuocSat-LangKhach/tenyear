local qixin = fk.CreateSkill {
  name = "qixinl",
}

Fk:loadTranslationTable{
  ["qixinl"] = "契心",
  [":qixinl"] = "每回合限两次，当你不因此技能使用基本牌/一次摸两张牌时，你可以摸两张牌/使用一张基本牌。",

  ["#qixinl-draw"] = "契心：你可以摸两张牌",
  ["#qixinl-use"] = "契心：你可以使用一张基本牌",

  ["$qixinl1"] = "姐妹称心，有灵犀栖心田。",
  ["$qixinl2"] = "暮雪纷纷落，心同往，不患无乡。",
}

qixin:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(qixin.name) and player:usedSkillTimes(qixin.name, Player.HistoryTurn) < 2 then
      for _, move in ipairs(data) do
        if move.to == player and move.moveReason == fk.ReasonDraw and move.skillName ~= qixin.name and
          #move.moveInfo > 1 then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local use = room:askToPlayCard(player, {
      skill_name = qixin.name,
      pattern = ".|.|.|.|.|basic",
      prompt = "#qixinl-use",
      cancelable = true,
      extra_data = {
        bypass_times = true,
        qixinl = true,
        extraUse = true,
      },
      skip = true,
    })
    if use then
      use.extraUse = true
      event:setCostData(self, {extra_data = use})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:useCard(event:getCostData(self).extra_data)
  end,
})

qixin:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qixin.name) and
      data.card.type == Card.TypeBasic and not (data.extra_data and data.extra_data.qixinl) and
      player:usedSkillTimes(qixin.name, Player.HistoryTurn) < 2
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, qixin.name)
  end,
})

return qixin
