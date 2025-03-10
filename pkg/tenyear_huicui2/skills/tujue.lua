local tujue = fk.CreateSkill {
  name = "tujue"
}

Fk:loadTranslationTable{
  ['tujue'] = '途绝',
  ['#tujue-choose'] = '途绝：你可以将所有牌交给一名其他角色，然后回复等量的体力值并摸等量的牌',
  [':tujue'] = '限定技，当你处于濒死状态时，你可以将所有牌交给一名其他角色，然后你回复等量的体力值并摸等量的牌。',
  ['$tujue1'] = '归蜀无路，孤臣泪尽江北。',
  ['$tujue2'] = '受吾主殊遇，安能降吴！',
}

tujue:addEffect(fk.AskForPeaches, {
  anim_type = "defensive",
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tujue.name) and player.dying and not player:isNude() and
      player:usedSkillTimes(tujue.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askToChoosePlayers(player, {
      targets = table.map(player.room:getOtherPlayers(player, false), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#tujue-choose",
      skill_name = tujue.name
    })
    if #to > 0 then
      event:setCostData(skill, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getCardIds("he")
    room:moveCardTo(cards, Card.PlayerHand, room:getPlayerById(event:getCostData(skill).tos[1]), fk.ReasonGive, tujue.name, nil, false, player.id)
    if player.dead then return end
    room:recover({
      who = player,
      num = math.min(#cards, player.maxHp - player.hp),
      recoverBy = player,
      skillName = tujue.name
    })
    if player.dead then return end
    player:drawCards(#cards, tujue.name)
  end,
})

return tujue
