local youxu = fk.CreateSkill {
  name = "youxu"
}

Fk:loadTranslationTable{
  ['youxu'] = '忧恤',
  ['#youxu-invoke'] = '忧恤：你可以展示 %dest 的一张手牌，然后交给另一名角色',
  ['#youxu-choose'] = '忧恤：将 %arg 交给另一名角色',
  [':youxu'] = '一名角色回合结束时，若其手牌数大于体力值，你可以展示其一张手牌然后交给另一名角色。若获得牌的角色体力值全场最低，其回复1点体力。',
  ['$youxu1'] = '积富之家，当恤众急。',
  ['$youxu2'] = '周忧济难，请君恤之。',
}

youxu:addEffect(fk.TurnEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(youxu.name) and target:getHandcardNum() > target.hp and not target.dead
  end,
  on_cost = function(self, event, target, player, data)
    event:setCostData(player, {tos = {target.id}})
    return player.room:askToSkillInvoke(player, {
      skill_name = youxu.name,
      prompt = "#youxu-invoke::" .. target.id
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = room:askToChooseCard(player, {
      target = target,
      flag = "h",
      skill_name = youxu.name
    })
    target:showCards({id})
    local targets = table.map(room:getOtherPlayers(target), Util.IdMapper)
    if #targets == 0 then return end
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#youxu-choose:::" .. Fk:getCardById(id):toLogString(),
      skill_name = youxu.name
    })
    local to = room:getPlayerById(tos[1])
    room:moveCardTo(id, Card.PlayerHand, to, fk.ReasonGive, youxu.name, nil, true, player.id)
    if not to.dead and to:isWounded() and table.every(room:getOtherPlayers(to), function (p) return p.hp >= to.hp end) then
      room:recover({
        who = to,
        num = 1,
        recoverBy = player,
        skillName = youxu.name
      })
    end
  end,
})

return youxu
