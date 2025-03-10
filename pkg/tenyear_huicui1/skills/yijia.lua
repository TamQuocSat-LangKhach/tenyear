local yijia = fk.CreateSkill {
  name = "yijia"
}

Fk:loadTranslationTable{
  ['yijia'] = '移驾',
  ['#yijia-invoke'] = '移驾：你可以将场上一张装备移至 %dest 的装备区（替换原装备）',
  ['#yijia-choose'] = '移驾：选择被移动装备的角色',
  ['#yijia-move'] = '移驾：选择移动给 %dest 的装备',
  [':yijia'] = '你距离1以内的角色受到伤害后，你可以将场上一张装备牌移动至其装备区（替换原装备），若其因此脱离了一名角色的攻击范围，你摸一张牌。',
  ['$yijia1'] = '曹侯忠心可鉴，可暂居其檐下。',
  ['$yijia2'] = '今东都糜败，陛下当移驾许昌。',
}

yijia:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player)
    return player:hasSkill(yijia.name) and not target.dead and player:distanceTo(target) <= 1 and
      table.find(player.room:getOtherPlayers(target), function(p)
        return table.find(p:getCardIds("e"), function(id)
          return #target:getAvailableEquipSlots(Fk:getCardById(id).sub_type) > 0
        end)
      end)
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(target), function(p)
      return table.find(p:getCardIds("e"), function(id)
        return #target:getAvailableEquipSlots(Fk:getCardById(id).sub_type) > 0
      end)
    end), Util.IdMapper)
    while room:askToSkillInvoke(player, {skill_name = yijia.name, prompt = "#yijia-invoke::"..target.id}) do
      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        skill_name = yijia.name,
        prompt = "#yijia-choose",
      })
      if #to > 0 then
        event:setCostData(self, to[1])
        return true
      end
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self))
    local cards = table.filter(to:getCardIds("e"), function(id)
      return #target:getAvailableEquipSlots(Fk:getCardById(id).sub_type) > 0
    end)
    local id = room:askToChooseCards(player, {
      target = to,
      min = 1,
      max = 1,
      flag = {card_data = {{to.general, cards}}},
      skill_name = yijia.name,
      prompt = "#yijia-move::"..target.id
    })[1]
    local orig = table.filter(room.alive_players, function(p) return p:inMyAttackRange(target) end)
    room:moveCardIntoEquip(target, id, yijia.name, true, player)
    if player.dead or #orig == 0 then return end
    if table.find(orig, function(p) return not p:inMyAttackRange(target) end) then
      player:drawCards(1, yijia.name)
    end
  end,
})

return yijia
