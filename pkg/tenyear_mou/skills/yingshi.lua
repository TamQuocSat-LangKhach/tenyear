local yingshi = fk.CreateSkill {
  name = "yingshij",
}

Fk:loadTranslationTable{
  ["yingshij"] = "应时",
  [":yingshij"] = "当你使用普通锦囊牌指定目标后，你可以令其中一个目标选择一项：令此牌对其额外结算一次；弃置X张牌（X为你装备区内牌的数量），"..
  "然后此技能本回合失效。",

  ["#yingshij-invoke"] = "应时：是否对 %dest 发动“应时”，令其选择一项？",
  ["#yingshij-choose"] = "应时：选择一名目标角色发动“应时”，令其选择一项",
  ["#yingshij-discard"] = "应时：弃置%arg张牌令 %src 的“应时”本回合失效，或者点“取消”令此牌对你额外结算一次",

  ["$yingshij1"] = "今君失道寡助，何不审时以降？",
  ["$yingshij2"] = "君既掷刀于地，可保富贵无虞。",
}

yingshi:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yingshi.name) and
      data.card:isCommonTrick() and data.firstTarget and
      not table.contains(data.card.skillNames, yingshi.name) and
      table.find(data.use.tos, function(p)
        return not p.dead
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(data.use.tos, function(p)
      return not p.dead
    end)
    if #targets == 1 then
      if room:askToSkillInvoke(player, {
        skill_name = yingshi.name,
        prompt = "#yingshij-invoke::"..targets[1].id,
      }) then
        event:setCostData(self, {tos = targets})
        return true
      end
    else
      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#yingshij-choose",
        skill_name = yingshi.name,
        cancelable = true,
      })
      if #to > 0 then
        event:setCostData(self, {tos = to})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local n = #player:getCardIds("e")
    if n > 0 and #room:askToDiscard(to, {
      min_num = n,
      max_num = n,
      include_equip = true,
      skill_name = yingshi.name,
      cancelable = true,
      prompt="#yingshij-discard:"..player.id.."::"..n..":"..data.card:toLogString()
    }) > 0 then
      room:invalidateSkill(player, yingshi.name, "-turn")
    else
      data.extra_data = data.extra_data or {}
      data.extra_data.yingshij = {
        from = player,
        to = to,
        subTargets = data.subTargets,
      }
    end
  end,
})

yingshi:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if data.extra_data and data.extra_data.yingshij and not player.dead then
      local use = table.simpleClone(data.extra_data.yingshij)
      if use.from == player then
        local card = Fk:cloneCard(data.card.name)
        card.skillName = yingshi.name
        if player:prohibitUse(card) then return false end
        local to = use.to
        if not to.dead and card.skill:modTargetFilter(player, to, {}, card, {bypass_distances = true, bypass_times = true}) then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dat = data.extra_data.yingshij
    local card = Fk:cloneCard(data.card.name)
    card.skillName = yingshi.name
    room:useCard{
      from = player,
      tos = {dat.to},
      card = card,
      subTargets = dat.subTargets,
      extraUse = true,
    }
  end,
})

return yingshi
