local ty__juanxia = fk.CreateSkill {
  name = "ty__juanxia"
}

Fk:loadTranslationTable{
  ['ty__juanxia'] = '狷狭',
  ['#ty__juanxia-choose'] = '狷狭：选择一名其他角色，视为对其使用至多三张仅指定唯一目标的普通锦囊',
  ['ty__juanxia_active'] = '狷狭',
  ['#ty__juanxia-invoke'] = '狷狭：你可以视为对 %dest 使用一张锦囊（第%arg张，至多3张）',
  ['@ty__juanxia'] = '狷狭',
  ['#ty__juanxia_delay'] = '狷狭',
  ['#ty__juanxia-slash'] = '狷狭：你可以视为对 %src 使用【杀】（第%arg2张，至多%arg张）',
  [':ty__juanxia'] = '结束阶段，你可以选择一名其他角色，视为依次使用至多三张牌名各不相同的仅指定唯一目标的普通锦囊牌（无距离限制）。若如此做，该角色的下一个结束阶段开始时，其可以视为对你使用等量张【杀】。',
  ['$ty__juanxia1'] = '放之海内，知我者少、同我者无，可谓高处胜寒。',
  ['$ty__juanxia2'] = '满堂朱紫，能文者不武，为将者少谋，唯吾兼备。',
}

ty__juanxia:addEffect(fk.EventPhaseEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty__juanxia.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#ty__juanxia-choose",
      skill_name = ty__juanxia.name,
      cancelable = true
    })
    if #tos > 0 then
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self).tos[1])
    local x = 0
    local all = table.filter(U.getUniversalCards(room, "t"), function(id)
      local trick = Fk:getCardById(id)
      return not trick.multiple_targets and trick.skill:getMinTargetNum() > 0
    end)
    for i = 1, 3 do
      local names = table.filter(all, function (id)
        local card = Fk:cloneCard(Fk:getCardById(id).name)
        card.skillName = ty__juanxia.name
        return player:canUseTo(card, to, {bypass_distances = true})
      end)
      if #names == 0 then break end
      local _, dat = room:askToUseActiveSkill(player, {
        skill_name = "ty__juanxia_active",
        prompt = "#ty__juanxia-invoke::" .. to.id..":"..i,
        cancelable = true,
        extra_data = {ty__juanxia_names = names, ty__juanxia_target = to.id}
      })
      if not dat then break end
      table.removeOne(all, dat.cards[1])
      local card = Fk:cloneCard(Fk:getCardById(dat.cards[1]).name)
      x = x + 1
      card.skillName = ty__juanxia.name
      local tos = dat.targets
      if #tos == 0 then table.insert(tos, to.id) end
      room:useCard{
        from = player.id,
        tos = table.map(dat.targets, function(id) return {id} end),
        card = card,
      }
      if player.dead or to.dead then return end
    end
    if x == 0 then return end
    room:setPlayerMark(to, "@ty__juanxia", x)
    room:setPlayerMark(to, "ty__juanxia_src", player.id)
  end,

  can_refresh = function(self, event, target, player, data)
    return player == target and (player:getMark("@ty__juanxia") > 0 or player:getMark("ty__juanxia_src") > 0)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@ty__juanxia", 0)
    room:setPlayerMark(player, "ty__juanxia_src", 0)
  end,
})

local ty__juanxia_delay = fk.CreateTriggerSkill{
  name = "#ty__juanxia_delay",
  events = {fk.TurnEnd},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and not target.dead and target:getMark("@ty__juanxia") > 0 and
      target:getMark("ty__juanxia_src") == player.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = target:getMark("@ty__juanxia")
    for i = 1, n, 1 do
      local slash = Fk:cloneCard("slash")
      slash.skillName = "ty__juanxia"
      if target:canUseTo(slash, player, { bypass_times = true, bypass_distances = true }) and
        room:askToSkillInvoke(target, {
          skill_name = self.name,
          prompt = "#ty__juanxia-slash:"..player.id.."::"..n..":"..i
        }) then
        room:useCard{
          from = target.id,
          tos = { {player.id} },
          card = slash,
          extraUse = true,
        }
      else
        break
      end
      if player.dead or target.dead then break end
    end
  end
}

ty__juanxia:addEffect(fk.TurnEnd, {
  name = "#ty__juanxia_delay",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and not target.dead and target:getMark("@ty__juanxia") > 0 and
      target:getMark("ty__juanxia_src") == player.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = target:getMark("@ty__juanxia")
    for i = 1, n, 1 do
      local slash = Fk:cloneCard("slash")
      slash.skillName = "ty__juanxia"
      if target:canUseTo(slash, player, { bypass_times = true, bypass_distances = true }) and
        room:askToSkillInvoke(target, {
          skill_name = self.name,
          prompt = "#ty__juanxia-slash:"..player.id.."::"..n..":"..i
        }) then
        room:useCard{
          from = target.id,
          tos = { {player.id} },
          card = slash,
          extraUse = true,
        }
      else
        break
      end
      if player.dead or target.dead then break end
    end
  end
})

return ty__juanxia
