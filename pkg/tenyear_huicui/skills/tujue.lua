local tujue = fk.CreateSkill {
  name = "tujue",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["tujue"] = "途绝",
  [":tujue"] = "限定技，当你处于濒死状态时，你可以将所有牌交给一名其他角色，然后你回复等量的体力并摸等量的牌。",

  ["#tujue-choose"] = "途绝：你可以将所有牌交给一名角色，回复等量体力并摸等量牌",

  ["$tujue1"] = "归蜀无路，孤臣泪尽江北。",
  ["$tujue2"] = "受吾主殊遇，安能降吴！",
}

tujue:addEffect(fk.AskForPeaches, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tujue.name) and
      player.dying and not player:isNude() and
      player:usedSkillTimes(tujue.name, Player.HistoryGame) == 0 and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#tujue-choose",
      skill_name = tujue.name
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getCardIds("he")
    room:moveCardTo(cards, Card.PlayerHand, event:getCostData(self).tos[1], fk.ReasonGive, tujue.name, nil, false, player)
    if player.dead then return end
    room:recover{
      who = player,
      num = #cards,
      recoverBy = player,
      skillName = tujue.name
    }
    if player.dead then return end
    player:drawCards(#cards, tujue.name)
  end,
})

return tujue
