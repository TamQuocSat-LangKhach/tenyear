local liji = fk.CreateSkill {
  name = "liji",
  dynamic_desc = function (self, player, lang)
    return "liji_inner:"..player:getMark("liji_times-turn")
  end,
}

Fk:loadTranslationTable{
  ["liji"] = "力激",
  [":liji"] = "出牌阶段限零次，你可以弃置一张牌，对一名其他角色造成1点伤害。你的回合内，本回合进入弃牌堆的牌每次达到8的倍数张时"..
  "（存活人数小于5时改为4的倍数），此技能使用次数+1。",

  [":liji_inner"] = "出牌阶段限{1}次，你可以弃置一张牌，对一名其他角色造成1点伤害。你的回合内，本回合进入弃牌堆的牌每次达到8的倍数张时"..
  "（存活人数小于5时改为4的倍数），此技能使用次数+1。",

  ["#liji"] = "力激：弃一张牌，对一名角色造成1点伤害！",

  ["$liji1"] = "破敌搴旗，未尝负败！",
  ["$liiji2"] = "鸷猛壮烈，万人不敌！",
}

liji:addEffect("active", {
  anim_type = "offensive",
  prompt = "#liji",
  card_num = 1,
  target_num = 1,
  times = function(self, player)
    if player.phase == Player.Play then
      return player:getMark("liji_times-turn") - player:usedSkillTimes(liji.name, Player.HistoryPhase)
    end
    return -1
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(liji.name, Player.HistoryPhase) < player:getMark("liji_times-turn")
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:throwCard(effect.cards, liji.name, player, player)
    if not target.dead then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = liji.name,
      }
    end
  end,
})

liji:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    if player.room.current == player and player:hasSkill(liji.name, true) then
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          return true
        end
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local n = 0
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        n = n + #move.moveInfo
      end
    end
    local factor = #room.alive_players < 5 and 4 or 8
    local x = ((player:getMark("liji-turn") + n) // factor) - (player:getMark("liji-turn") // factor)
    if x > 0 then
      room:addPlayerMark(player, "liji_times-turn", x)
    end
    room:addPlayerMark(player, "liji-turn", n)
  end,
})

return liji
