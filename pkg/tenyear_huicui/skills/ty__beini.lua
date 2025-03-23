local ty__beini = fk.CreateSkill {
  name = "ty__beini"
}

Fk:loadTranslationTable{
  ['ty__beini'] = '悖逆',
  ['#ty__beini'] = '悖逆：你可以将手牌调整至体力上限，然后视为一名角色对另一名角色使用【杀】',
  ['#ty__beini-choose'] = '悖逆：选择两名角色，视为前者对后者使用【杀】，这些角色本回合非锁定技失效',
  ['@@ty__beini-turn'] = '悖逆',
  [':ty__beini'] = '出牌阶段限一次，你可以将手牌数调整至体力上限，然后令一名角色视为对另一名角色使用一张【杀】；这两名角色的非锁定技本回合失效。',
  ['$ty__beini1'] = '臣等忠心耿耿，陛下何故谋反？',
  ['$ty__beini2'] = '公等养汝，正拟今日，复何疑？'
}

ty__beini:addEffect('active', {
  anim_type = "offensive",
  card_num = 0,
  target_num = 0,
  prompt = "#ty__beini",
  can_use = function(self, player)
    return player:usedSkillTimes(ty__beini.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local n = player:getHandcardNum() - player.maxHp
    if n > 0 then
      room:askToDiscard(player, {
        min_num = n,
        max_num = n,
        include_equip = false,
        skill_name = ty__beini.name,
        cancelable = false
      })
    else
      player:drawCards(-n, ty__beini.name)
    end
    if player.dead or #room.alive_players < 2 then return end
    local targets = room:askToChoosePlayers(player, {
      min_num = 2,
      max_num = 2,
      prompt = "#ty__beini-choose",
      skill_name = ty__beini.name,
      cancelable = false,
      targets = table.map(room.alive_players, Util.IdMapper)
    })
    if #targets == 2 then
      local target1 = room:getPlayerById(targets[1])
      local target2 = room:getPlayerById(targets[2])
      room:doIndicate(player.id, {target1.id})
      room:setPlayerMark(target1, "@@ty__beini-turn", 1)
      room:setPlayerMark(target2, "@@ty__beini-turn", 1)
      room:addPlayerMark(target1, MarkEnum.UncompulsoryInvalidity .. "-turn")
      room:addPlayerMark(target2, MarkEnum.UncompulsoryInvalidity .. "-turn")
      room:useVirtualCard("slash", nil, target1, target2, ty__beini.name, true)
    end
  end,
})

return ty__beini
