local choutao = fk.CreateSkill {
  name = "choutao"
}

Fk:loadTranslationTable{
  ['choutao'] = '仇讨',
  ['#choutao-invoke'] = '仇讨：你可以弃置 %dest 一张牌令此【杀】不能被响应；若为你则此【杀】不计次',
  [':choutao'] = '当你使用【杀】指定目标后，或你成为【杀】的目标后，你可以弃置此【杀】使用者的一张牌，令此【杀】所有目标角色不能响应此【杀】。若使用者为你，此【杀】不计入次数。',
  ['$choutao1'] = '大恨深仇，此剑讨之！',
  ['$choutao2'] = '是非恩怨，此役决之！'
}

choutao:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(choutao.name) and data.card.trueName == "slash"
      and not player.room:getPlayerById(data.from):isNude()
      and (event == fk.TargetConfirmed or data.firstTarget)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = choutao.name,
      prompt = "#choutao-invoke::" .. data.from
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = room:getPlayerById(data.from)
    local id = room:askToChooseCard(player, {
      target = from,
      flag = "he",
      skill_name = choutao.name
    })
    room:throwCard({id}, choutao.name, from, player)
    if data.from == player.id and not data.extraUse then
      data.extraUse = true
      player:addCardUseHistory(data.card.trueName, -1)
    end
    data.disresponsiveList = table.map(room.alive_players, Util.IdMapper)
  end,
})

choutao:addEffect(fk.TargetConfirmed, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(choutao.name) and data.card.trueName == "slash"
      and not player.room:getPlayerById(data.from):isNude()
      and (event == fk.TargetConfirmed or data.firstTarget)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = choutao.name,
      prompt = "#choutao-invoke::" .. data.from
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = room:getPlayerById(data.from)
    local id = room:askToChooseCard(player, {
      target = from,
      flag = "he",
      skill_name = choutao.name
    })
    room:throwCard({id}, choutao.name, from, player)
    if data.from == player.id and not data.extraUse then
      data.extraUse = true
      player:addCardUseHistory(data.card.trueName, -1)
    end
    data.disresponsiveList = table.map(room.alive_players, Util.IdMapper)
  end,
})

return choutao
