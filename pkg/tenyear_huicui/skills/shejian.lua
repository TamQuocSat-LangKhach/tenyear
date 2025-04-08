local shejian = fk.CreateSkill {
  name = "shejian",
}

Fk:loadTranslationTable{
  ["shejian"] = "舌剑",
  [":shejian"] = "每回合限两次，当你成为其他角色使用牌的唯一目标后，你可以弃置至少两张手牌，然后弃置其等量的牌或对其造成1点伤害。",

  ["#shejian-invoke"] = "舌剑：你可以弃置至少两张手牌，弃置 %dest 等量的牌或对其造成1点伤害",
  ["#shejian-choice"] = "舌剑：选择对 %dest 执行的一项",

  ["$shejian1"] = "伤人的，可不止刀剑！",
  ["$shejian2"] = "死公！云等道？",
}

shejian:addEffect(fk.TargetConfirmed, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shejian.name) and
      data.from ~= player and data:isOnlyTarget(player) and player:getHandcardNum() > 1 and
      player:usedSkillTimes(shejian.name, Player.HistoryTurn) < 2
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToDiscard(player, {
      min_num = 2,
      max_num = 999,
      include_equip = false,
      skill_name = shejian.name,
      cancelable = true,
      prompt = "#shejian-invoke::"..data.from.id,
      skip = true,
    })
    if #cards > 1 then
      event:setCostData(self, {tos = {data.from}, cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = #event:getCostData(self).cards
    room:throwCard(event:getCostData(self).cards, shejian.name, player, player)
    if player.dead or data.from.dead then return end
    local choices = {"damage1"}
    if #data.from:getCardIds("he") >= n then
      table.insert(choices, 1, "discard_skill")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = shejian.name,
      prompt = "#shejian-choice::" .. data.from.id,
    })
    if choice == "discard_skill" then
      local cards = room:askToChooseCards(player, {
        min = n,
        max = n,
        target = data.from,
        flag = "he",
        skill_name = shejian.name
      })
      room:throwCard(cards, shejian.name, data.from, player)
    else
      room:damage{
        from = player,
        to = data.from,
        damage = 1,
        skillName = shejian.name
      }
    end
  end,
})

return shejian
