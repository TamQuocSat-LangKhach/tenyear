local shawu = fk.CreateSkill {
  name = "shawu",
}

Fk:loadTranslationTable{
  ["shawu"] = "沙舞",
  [":shawu"] = "当你使用【杀】指定目标后，你可以弃置两张手牌或1枚“沙”标记对目标角色造成1点伤害。若你弃置的是“沙”标记，你摸两张牌。",

  ["#shawu-invoke"] = "沙舞：弃两张手牌，或直接点“确定”弃置一枚“沙”标记，对 %dest 造成1点伤害",
}

shawu:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shawu.name) and data.card.trueName == "slash" and
      (player:getMark("@xiaowu_sand") > 0 or player:getHandcardNum() > 1) and
      not data.to.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "discard_skill",
      prompt = "#shawu-invoke::"..data.to.id,
      extra_data = {
        num = 1,
        min_num = player:getMark("@xiaowu_sand") > 0 and 0 or 2,
        include_equip = true,
        skillName = shawu.name,
        pattern = ".|.|.|hand",
      },
      skip = true,
    })
    if success and dat then
      event:setCostData(self, {tos = {data.to}, cards = dat.cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local draw2 = false
    if #event:getCostData(self).cards > 1 then
      room:throwCard(event:getCostData(self).cards, shawu.name, player, player)
    else
      room:removePlayerMark(player, "@xiaowu_sand")
      draw2 = true
    end
    if not data.to.dead then
      room:damage{
        from = player,
        to = data.to,
        damage = 1,
        skillName = shawu.name,
      }
    end
    if draw2 and not player.dead then
      player:drawCards(2, shawu.name)
    end
  end,
})

return shawu
