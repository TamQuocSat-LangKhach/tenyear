local choutao = fk.CreateSkill {
  name = "choutao",
}

Fk:loadTranslationTable{
  ["choutao"] = "仇讨",
  [":choutao"] = "当你使用【杀】指定目标后，或当你成为【杀】的目标后，你可以弃置此【杀】使用者的一张牌，令此【杀】不能被抵消。"..
  "若使用者为你，此【杀】不计入次数。",

  ["#choutao_self-invoke"] = "仇讨：你可以弃置一张牌，令此【杀】不能被响应且不计次数",
  ["#choutao-invoke"] = "仇讨：你可以弃置 %dest 一张牌令此【杀】不能被响应",

  ["$choutao1"] = "大恨深仇，此剑讨之！",
  ["$choutao2"] = "是非恩怨，此役决之！"
}

choutao:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(choutao.name) and data.firstTarget and
      data.card.trueName == "slash" and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = choutao.name,
      prompt = "#choutao_self-invoke",
      cancelable = true,
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, choutao.name, player, player)
    if not data.use.extraUse then
      data.use.extraUse = true
      player:addCardUseHistory(data.card.trueName, -1)
    end
    data.use.disresponsiveList = table.simpleClone(room.players)
  end,
})

choutao:addEffect(fk.TargetConfirmed, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(choutao.name) and
      data.card.trueName == "slash" and not data.from:isNude() and not data.from.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = choutao.name,
      prompt = "#choutao-invoke::" .. data.from.id,
    }) then
      event:setCostData(self, {tos = {data.from}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = room:askToChooseCard(player, {
      target = data.from,
      flag = "he",
      skill_name = choutao.name,
    })
    room:throwCard(id, choutao.name, data.from, player)
    data.use.disresponsiveList = table.simpleClone(room.players)
  end,
})

return choutao
