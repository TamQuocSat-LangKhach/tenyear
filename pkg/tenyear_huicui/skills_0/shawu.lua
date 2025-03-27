local shawu = fk.CreateSkill {
  name = "shawu"
}

Fk:loadTranslationTable{
  ['shawu'] = '沙舞',
  ['@xiaowu_sand'] = '沙',
  ['shawu_select'] = '沙舞',
  ['#shawu-invoke'] = '沙舞：你可选择两张手牌弃置，或直接点确定弃置沙标记。来对%dest造成1点伤害',
  [':shawu'] = '当你使用【杀】指定目标后，你可以弃置两张手牌或1枚“沙”标记对目标角色造成1点伤害。若你弃置的是“沙”标记，你摸两张牌。',
}

shawu:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shawu.name) and data.card.trueName == "slash" and
      (player:getMark("@xiaowu_sand") > 0 or player:getHandcardNum() > 1) and not player.room:getPlayerById(data.to).dead
  end,
  on_cost = function(self, event, target, player, data)
    local _, ret = player.room:askToUseActiveSkill(player, {
      skill_name = "shawu_select",
      prompt = "#shawu-invoke::" .. data.to,
      cancelable = true,
    })
    if ret then
      event:setCostData(self, ret.cards)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = player.room:getPlayerById(data.to)
    local draw2 = false
    if #event:getCostData(self) > 1 then
      room:throwCard(event:getCostData(self), shawu.name, player, player)
    else
      room:removePlayerMark(player, "@xiaowu_sand")
      draw2 = true
    end
    if not to.dead then
      room:damage{ from = player, to = to, damage = 1, skillName = shawu.name }
    end
    if draw2 and not player.dead then
      player:drawCards(2, shawu.name)
    end
  end,
})

return shawu
