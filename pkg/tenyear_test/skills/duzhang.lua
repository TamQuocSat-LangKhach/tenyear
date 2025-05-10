local duzhang = fk.CreateSkill {
  name = "duzhang",
}

Fk:loadTranslationTable{
  ["duzhang"] = "独仗",
  [":duzhang"] = "每回合限一次，当你使用黑色牌指定唯一目标后或成为黑色牌的唯一目标后，你可以摸一张牌并获得一枚“凛”。"..
  "你的手牌上限+X（X为你的“凛”数）",

  ["$duzhang1"] = "",
  ["$duzhang2"] = "",
}

local spec = {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(duzhang.name) and
      data:isOnlyTarget(data.to) and data.card.color == Card.Black and
      player:usedSkillTimes(duzhang.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, duzhang.name)
    if not player.dead then
      room:addPlayerMark(player, "@zhonghui_piercing", 1)
    end
  end,
}

duzhang:addEffect(fk.TargetSpecified, spec)
duzhang:addEffect(fk.TargetConfirmed, spec)

duzhang:addEffect("maxcards", {
  correct_func = function(self, player)
    if player:hasSkill(duzhang.name) then
      return player:getMark("@zhonghui_piercing")
    end
  end,
})

return duzhang
