local youxu = fk.CreateSkill {
  name = "youxu",
}

Fk:loadTranslationTable{
  ["youxu"] = "忧恤",
  [":youxu"] = "一名角色回合结束时，若其手牌数大于体力值，你可以展示其一张手牌并交给另一名角色，若获得牌的角色体力值全场最低，其回复1点体力。",

  ["#youxu-invoke"] = "忧恤：你可以展示 %dest 的一张手牌，然后交给另一名角色",
  ["#youxu-choose"] = "忧恤：将 %arg 交给另一名角色",

  ["$youxu1"] = "积富之家，当恤众急。",
  ["$youxu2"] = "周忧济难，请君恤之。",
}

youxu:addEffect(fk.TurnEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(youxu.name) and target:getHandcardNum() > target.hp and not target.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = youxu.name,
      prompt = "#youxu-invoke::" .. target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = room:askToChooseCard(player, {
      target = target,
      flag = "h",
      skill_name = youxu.name,
    })
    target:showCards(id)
    if player.dead or target.dead or not table.contains(target:getCardIds("h"), id) then return end
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(target, false),
      min_num = 1,
      max_num = 1,
      prompt = "#youxu-choose:::" .. Fk:getCardById(id):toLogString(),
      skill_name = youxu.name,
      cancelable = false,
    })[1]
    room:moveCardTo(id, Card.PlayerHand, to, fk.ReasonGive, youxu.name, nil, true, player)
    if not to.dead and to:isWounded() and
      table.every(room:getOtherPlayers(to, false), function (p)
        return p.hp >= to.hp
      end) then
      room:recover{
        who = to,
        num = 1,
        recoverBy = player,
        skillName = youxu.name,
      }
    end
  end,
})

return youxu
