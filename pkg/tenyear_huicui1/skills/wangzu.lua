local wangzu = fk.CreateSkill {
  name = "wangzu"
}

Fk:loadTranslationTable{
  ['wangzu'] = '望族',
  ['#wangzu1-invoke'] = '望族：你可以弃置一张手牌，令此伤害-1',
  ['#wangzu2-invoke'] = '望族：你可以随机弃置一张手牌，令此伤害-1',
  [':wangzu'] = '每回合限一次，当你受到其他角色造成的伤害时，你可以随机弃置一张手牌令此伤害-1，若你所在的阵营存活人数全场最多，则改为选择一张手牌弃置。',
  ['$wangzu1'] = '名门望族，显贵荣达。',
  ['$wangzu2'] = '能人辈出，仕宦显达。',
}

wangzu:addEffect(fk.DamageInflicted, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wangzu.name) and data.from and data.from ~= player and not player:isKongcheng() and
      player:usedSkillTimes(wangzu.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local nums = {0, 0, 0}
    for _, p in ipairs(room.alive_players) do
      if p.role == "lord" or p.role == "loyalist" then
        nums[1] = nums[1] + 1
      elseif p.role == "rebel" then
        nums[2] = nums[2] + 1
      else
        nums[3] = nums[3] + 1
      end
    end
    local n = math.max(table.unpack(nums))
    if ((player.role == "lord" or player.role == "loyalist") and n == nums[1]) or
      (player.role == "rebel" and n == nums[2]) or (player.role == "renegade" and n == nums[3]) then
      local card = player.room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = wangzu.name,
        cancelable = true,
        pattern = ".",
        prompt = "#wangzu1-invoke"
      })
      if #card > 0 then
        event:setCostData(self, card)
        return true
      end
    else
      local cards = table.filter(player:getCardIds("h"), function(id) return not player:prohibitDiscard(Fk:getCardById(id)) end)
      if #cards == 0 then return end
      if room:askToSkillInvoke(player, {
        skill_name = wangzu.name,
        prompt = "#wangzu2-invoke"
      }) then
        event:setCostData(self, table.random(cards, 1))
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:throwCard(event:getCostData(self), wangzu.name, player, player)
    data.damage = data.damage - 1
  end,
})

return wangzu
