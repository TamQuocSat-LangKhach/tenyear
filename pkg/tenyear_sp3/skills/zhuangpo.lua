local zhuangpo = fk.CreateSkill {
  name = "zhuangpo"
}

Fk:loadTranslationTable{
  ['zhuangpo'] = '壮魄',
  ['#zhuangpo'] = '壮魄：你可将牌面信息中有【杀】字的牌当【决斗】使用',
  ['#zhuangpo_buff'] = '壮魄',
  ['@zhengqing_qing'] = '擎',
  ['#zhuangpo-choice'] = '壮魄：你可移去至少一枚“擎”标记，令 %dest 弃置等量的牌',
  [':zhuangpo'] = '你可将牌面信息中有【杀】字的牌当【决斗】使用。若你拥有“擎”，则此【决斗】指定目标后，你可以移去任意个“擎”，然后令其弃置等量的牌；若此【决斗】指定了有“擎”的角色为目标，则此牌伤害+1。',
  ['$zhuangpo1'] = '腹吞龙虎，气撼山河！',
  ['$zhuangpo2'] = '神魄凝威，魍魉辟易！'
}

-- ViewAsSkill
zhuangpo:addEffect('viewas', {
  anim_type = "offensive",
  prompt = "#zhuangpo",
  pattern = "duel",
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and (
      Fk:getCardById(to_select).trueName == "slash" or
      string.find(Fk:translate(":" .. Fk:getCardById(to_select).name, "zh_CN"), "【杀】")
    )
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("duel")
    c.skillName = zhuangpo.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = function(self, player)
    return not player:isNude()
  end,
})

-- TriggerSkill
zhuangpo:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhuangpo) and
      table.contains(data.card.skillNames, zhuangpo.name) and
      (player:getMark("@zhengqing_qing") > 0 or
      (data.firstTarget and
      table.find(AimGroup:getAllTargets(data.tos), function(p)
        return player.room:getPlayerById(p):getMark("@zhengqing_qing") > 0
      end)))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("@zhengqing_qing") > 0 and room:getPlayerById(data.to):isAlive() then
      local choices = {}
      for i = 1, player:getMark("@zhengqing_qing") do
        table.insert(choices, tostring(i))
      end
      table.insert(choices, "Cancel")

      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = zhengqing.name,
        prompt = "#zhuangpo-choice::" .. data.to
      })
      if choice == "Cancel" then
        return (data.firstTarget and
          table.find(AimGroup:getAllTargets(data.tos), function(p)
            return room:getPlayerById(p):getMark("@zhengqing_qing") > 0
          end))
      else
        event:setCostData(self, tonumber(choice))
      end
    end

    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if (event:getCostData(self) or 0) > 0 then
      local discardNum = event:getCostData(self)
      event:setCostData(self, nil)
      room:removePlayerMark(player, "@zhengqing_qing", discardNum)
      room:askToDiscard(room:getPlayerById(data.to), {
        min_num = discardNum,
        max_num = discardNum,
        include_equip = true,
        skill_name = zhuangpo.name,
        cancelable = false
      })
    end

    if data.firstTarget and table.find(AimGroup:getAllTargets(data.tos), function(p)
      return room:getPlayerById(p):getMark("@zhengqing_qing") > 0
    end) then
      data.additionalDamage = (data.additionalDamage or 0) + 1
      data.extra_data = data.extra_data or {}
      data.extra_data.zhengqingBuff = true
    end
  end,
  can_refresh = function(self, event, target, player, data)
    return (data.extra_data or {}).zhengqingBuff
  end,
  on_refresh = function(self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + 1
  end,
})

return zhuangpo
