local beini = fk.CreateSkill {
  name = "ty__beini",
}

Fk:loadTranslationTable{
  ["ty__beini"] = "悖逆",
  [":ty__beini"] = "出牌阶段限一次，你可以将手牌数调整至体力上限，然后令一名角色视为对另一名角色使用一张【杀】；这两名角色的非锁定技本回合失效。",

  ["#ty__beini"] = "悖逆：你可以将手牌调整至体力上限，然后视为一名角色对另一名角色使用【杀】",
  ["#ty__beini-choose"] = "悖逆：选择两名角色，视为前者对后者使用【杀】，这些角色本回合非锁定技失效",
  ["@@ty__beini-turn"] = "悖逆",

  ["$ty__beini1"] = "臣等忠心耿耿，陛下何故谋反？",
  ["$ty__beini2"] = "公等养汝，正拟今日，复何疑？"
}

beini:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ty__beini",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(beini.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local n = player:getHandcardNum() - player.maxHp
    if n > 0 then
      room:askToDiscard(player, {
        min_num = n,
        max_num = n,
        include_equip = false,
        skill_name = beini.name,
        cancelable = false
      })
    else
      player:drawCards(-n, beini.name)
    end
    if player.dead or #room.alive_players < 2 then return end
    local targets = room:askToChoosePlayers(player, {
      min_num = 2,
      max_num = 2,
      prompt = "#ty__beini-choose",
      skill_name = beini.name,
      targets = room.alive_players,
      cancelable = false,
      no_indicate = true,
    })
    if #targets == 2 then
      room:doIndicate(player, {targets[1]})
      room:setPlayerMark(targets[1], "@@ty__beini-turn", 1)
      room:setPlayerMark(targets[2], "@@ty__beini-turn", 1)
      room:addPlayerMark(targets[1], MarkEnum.UncompulsoryInvalidity .. "-turn")
      room:addPlayerMark(targets[2], MarkEnum.UncompulsoryInvalidity .. "-turn")
      room:useVirtualCard("slash", nil, targets[1], targets[2], beini.name, true)
    end
  end,
})

return beini
