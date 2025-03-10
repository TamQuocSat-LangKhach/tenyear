local shejian = fk.CreateSkill {
  name = "shejian"
}

Fk:loadTranslationTable{
  ['shejian'] = '舌剑',
  ['#shejian-card'] = '舌剑：你可以弃置至少两张手牌，弃置 %dest 等量的牌或对其造成1点伤害',
  ['damage1'] = '造成1点伤害',
  ['#shejian-choice'] = '舌剑：选择对 %dest 执行的一项',
  [':shejian'] = '每回合限两次，当你成为其他角色使用牌的唯一目标后，你可以弃置至少两张手牌，然后弃置其等量的牌或对其造成1点伤害。',
  ['$shejian1'] = '伤人的，可不止刀剑！',
  ['$shejian2'] = '死公！云等道？',
}

shejian:addEffect(fk.TargetConfirmed, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and data.from ~= player.id and #AimGroup:getAllTargets(data.tos) == 1 and
      #player:getCardIds("he") > 1 and player:usedSkillTimes(skill.name, Player.HistoryTurn) < 2
  end,
  on_cost = function(self, event, target, player, data)
    local cards = room:askToDiscard(player, {
      min_num = 2,
      max_num = 999,
      include_equip = false,
      skill_name = skill.name,
      cancelable = true,
      pattern = ".|.|.|hand",
      prompt = "#shejian-card::" .. data.from
    })
    if #cards > 1 then
      event:setCostData(skill, cards)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = room:getPlayerById(data.from)
    local n = #event:getCostData(skill)
    room:throwCard(event:getCostData(skill), skill.name, player, player)
    if not (player.dead or from.dead) then
      room:doIndicate(player.id, {data.from})
      local choices = {"damage1"}
      if #from:getCardIds("he") >= n then
        table.insert(choices, 1, "discard_skill")
      end
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = skill.name,
        prompt = "#shejian-choice::" .. data.from
      })
      if choice == "discard_skill" then
        local cards = room:askToChooseCards(player, {
          min = n,
          max = n,
          target = from,
          flag = "he",
          skill_name = skill.name
        })
        room:throwCard(cards, skill.name, from, player)
      else
        room:damage{
          from = player,
          to = from,
          damage = 1,
          skillName = skill.name
        }
      end
    end
  end,
})

return shejian
