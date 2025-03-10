local yingshij = fk.CreateSkill {
  name = "yingshij"
}

Fk:loadTranslationTable{
  ['yingshij'] = '应时',
  ['#yingshij-invoke'] = '是否对%dest发动 应时',
  ['#yingshij-choose'] = '是否发动 应时，选择一名目标角色',
  ['#yingshij-discard'] = '应时：弃置%arg张牌，令%src的“应时”本回合失效，或者取消令此牌对你额外结算一次',
  ['#yingshij_delay'] = '应时',
  [':yingshij'] = '当你不因此技能使用普通锦囊牌指定第一个目标后，你可以令一名目标角色选择：1.当此牌结算后，你视为对其使用相同牌名的牌；2.弃置X张牌（X为你装备区里的牌数），然后此技能于当前回合内无效。',
  ['$yingshij1'] = '今君失道寡助，何不审时以降？',
  ['$yingshij2'] = '君既掷刀于地，可保富贵无虞。',
}

-- 主技能
yingshij:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(yingshij.name) and
      data.firstTarget and
      data.card:isCommonTrick() and
      not table.contains(data.card.skillNames, yingshij.name) and
      table.find(AimGroup:getAllTargets(data.tos), function(pId) return player.room:getPlayerById(pId):isAlive() end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = AimGroup:getAllTargets(data.tos)
    if #targets == 1 then
      if room:askToSkillInvoke(player, {skill_name=yingshij.name, prompt="#yingshij-invoke::" .. targets[1]}) then
        room:doIndicate(player.id, targets)
        event:setCostData(self, targets)
        return true
      end
    else
      local targets = room:askToChoosePlayers(player, {
        targets=targets,
        min_num=1,
        max_num=1,
        prompt="#yingshij-choose",
        skill_name=yingshij.name,
        cancelable=true})
      if #targets > 0 then
        event:setCostData(self, targets)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self)[1])
    local equipNum = #player:getCardIds(Player.Equip)
    if equipNum > 0 and #room:askToDiscard(to, {
      min_num=equipNum,
      max_num=equipNum,
      include_equip=true,
      skill_name=yingshij.name,
      cancelable=true,
      prompt="#yingshij-discard:" .. player.id .. "::" .. tostring(equipNum) .. ":" .. data.card:toLogString()}) > 0 then
      room:invalidateSkill(player, yingshij.name, "-turn")
    else
      data.extra_data = data.extra_data or {}
      data.extra_data.yingshij = {
        from = player.id,
        to = to.id,
        subTargets = data.subTargets
      }
    end
  end,
})

-- 延迟技能
yingshij:addEffect(fk.CardUseFinished, {
  name = "#yingshij_delay",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if data.extra_data and data.extra_data.yingshij and not player.dead then
      local use = table.simpleClone(data.extra_data.yingshij)
      if use.from == player.id then
        local card = Fk:cloneCard(data.card.name)
        card.skillName = "yingshij"
        if player:prohibitUse(card) then return false end
        use.card = card
        local room = player.room
        local to = room:getPlayerById(use.to)
        if not to.dead and U.canTransferTarget(to, use, false) then
          local tos = {use.to}
          if use.subTargets then
            table.insertTable(tos, use.subTargets)
          end
          event:setCostData(self, {
            from = player.id,
            tos = table.map(tos, function(pid) return { pid } end),
            card = card,
            extraUse = true
          })
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:useCard(table.simpleClone(event:getCostData(self)))
  end,
})

return yingshij
