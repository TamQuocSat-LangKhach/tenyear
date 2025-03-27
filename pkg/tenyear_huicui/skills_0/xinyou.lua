local xinyou = fk.CreateSkill {
  name = "xinyou"
}

Fk:loadTranslationTable{
  ['xinyou'] = '心幽',
  ['#xinyou_record'] = '心幽',
  [':xinyou'] = '出牌阶段限一次，你可以回复体力至体力上限并将手牌摸至体力上限。若你因此摸超过两张牌，结束阶段你失去1点体力；若你因此回复体力，结束阶段你弃置一张牌。',
  ['$xinyou1'] = '我有幽月一斛，可醉十里春风。',
  ['$xinyou2'] = '心在方外，故而不闻市井之声。',
}

xinyou:addEffect('active', {
  anim_type = "drawcard",
  can_use = function(self, player)
    return (player:isWounded() or player:getHandcardNum() < player.maxHp) and player:usedSkillTimes(xinyou.name, Player.HistoryPhase) == 0
  end,
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if player:isWounded() then
      room:recover({
        who = player,
        num = player:getLostHp(),
        recoverBy = player,
        skillName = xinyou.name
      })
      room:addPlayerMark(player, "xinyou_recover-turn", 1)
    end
    local n = player.maxHp - player:getHandcardNum()
    if n > 0 then
      player:drawCards(n, xinyou.name)
      if n > 2 then
        room:addPlayerMark(player, "xinyou_draw-turn", 1)
      end
    end
  end
})

xinyou:addEffect(fk.EventPhaseStart, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xinyou) and player.phase == Player.Finish and
      ((player:getMark("xinyou_recover-turn") > 0 and not player:isNude()) or player:getMark("xinyou_draw-turn") > 0)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("xinyou_recover-turn") > 0 then
      room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = "xinyou",
        cancelable = false,
      })
    end
    if player:getMark("xinyou_draw-turn") > 0 then
      room:loseHp(player, 1, "xinyou")
    end
  end,
})

return xinyou
