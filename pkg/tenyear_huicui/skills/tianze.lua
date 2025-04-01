local tianze = fk.CreateSkill {
  name = "tianze",
}

Fk:loadTranslationTable{
  ["tianze"] = "天则",
  [":tianze"] = "当其他角色于其出牌阶段内使用第一张黑色牌结算结束后，你可以弃置一张黑色牌，对其造成1点伤害；当其他角色的黑色判定牌生效后，"..
  "你摸一张牌。",

  ["#tianze-invoke"] = "天则：你可以弃置一张黑色牌，对 %dest 造成1点伤害",

  ["$tianze1"] = "观天则，以断人事。",
  ["$tianze2"] = "乾元用九，乃见天则。",
}

tianze:addEffect(fk.FinishJudge, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(tianze.name) and target ~= player and data.card.color == Card.Black
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, tianze.name)
  end,
})

tianze:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(tianze.name) and target ~= player and
      target.phase == Player.Play and data.card.color == Card.Black and
      not target.dead and not player:isNude() then
      if target.dead or target.phase ~= Player.Play or player:isNude() then return false end
      local use_events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        return use.from == target and use.card.color == Card.Black
      end, Player.HistoryPhase)
      return #use_events == 1 and use_events[1].data == data
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      skill_name = tianze.name,
      min_num = 1,
      max_num = 1,
      include_equip = true,
      pattern = ".|.|spade,club",
      prompt = "#tianze-invoke::"..target.id,
      cancelable = true,
    })
    if #card > 0 then
      event:setCostData(self, {tos = {target}, cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, tianze.name, player, player)
    if not target.dead then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = tianze.name,
      }
    end
  end,
})

return tianze
