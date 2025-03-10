local deshao = fk.CreateSkill {
  name = "deshao"
}

Fk:loadTranslationTable{
  ['deshao'] = '德劭',
  ['#deshao-invoke'] = '德劭：你可以摸一张牌，然后若 %dest 手牌数不少于你，你弃置其一张牌',
  [':deshao'] = '每回合限两次，当你成为其他角色使用黑色牌的目标后，你可以摸一张牌，然后若其手牌数大于等于你，你弃置其一张牌。',
  ['$deshao1'] = '名德远播，朝野俱瞻。',
  ['$deshao2'] = '增修德信，以诚服人。',
}

deshao:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(deshao.name) and data.card.color == Card.Black and
      data.from ~= player.id and player:usedSkillTimes(deshao.name, Player.HistoryTurn) < 2
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = deshao.name,
      prompt = "#deshao-invoke::"..data.from
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, deshao.name)
    local from = room:getPlayerById(data.from)
    if from:getHandcardNum() >= player:getHandcardNum() then
      local id = room:askToChooseCard(player, {
        target = from,
        flag = "he",
        skill_name = deshao.name
      })
      room:throwCard(id, deshao.name, from, player)
    end
  end,
})

return deshao
