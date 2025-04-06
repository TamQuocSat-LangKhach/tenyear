local cansi = fk.CreateSkill {
  name = "cansi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["cansi"] = "残肆",
  [":cansi"] = "锁定技，准备阶段，你选择一名其他角色，你与其各回复1点体力，然后依次视为对其使用【杀】【决斗】和【火攻】，"..
  "其每因此受到1点伤害，你摸两张牌。",

  ["#cansi-choose"] = "残肆：选择一名角色，令其回复1点体力，然后依次视为对其使用【杀】【决斗】【火攻】",

  ["$cansi1"] = "君不入地狱，谁入地狱？",
  ["$cansi2"] = "众生皆苦，唯渡众生于极乐。",
}

cansi:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(cansi.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = cansi.name,
      }
      if player.dead then return end
    end
    if #room:getOtherPlayers(player, false) == 0 then return end
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      prompt = "#cansi-choose",
      skill_name = cansi.name,
      cancelable = false,
    })[1]
    if to:isWounded() then
      room:recover{
        who = to,
        num = 1,
        recoverBy = player,
        skillName = cansi.name,
      }
    end
    for _, name in ipairs({"slash", "duel", "fire_attack"}) do
      if player.dead or to.dead then break end
      local card = Fk:cloneCard(name)
      card.skillName = cansi.name
      if player:canUseTo(card, to, { bypass_times = true, bypass_distances = true }) then
        room:useCard{
          from = player,
          tos = {to},
          card = card,
          extraUse = true,
          extra_data = {
            cansi_source = player.id,
            cansi_target = to.id,
          }
        }
      end
    end
  end,
})

cansi:addEffect(fk.Damaged, {
  anim_type = "drawcard",
  is_delay_effect = true,
  trigger_times = function(self, event, target, player, data)
    return data.damage
  end,
  can_trigger = function(self, event, target, player, data)
    if data.card and table.contains(data.card.skillNames, cansi.name) and not player.dead then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if use_event then
        local use = use_event.data
        return use.card == data.card and use.extra_data and
          use.extra_data.cansi_source == player.id and
          use.extra_data.cansi_target == target.id
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, cansi.name)
  end,
})

return cansi
