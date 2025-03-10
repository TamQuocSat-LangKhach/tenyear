local humei = fk.CreateSkill {
  name = "humei"
}

Fk:loadTranslationTable{
  ['humei'] = '狐魅',
  ['#humei'] = '狐魅：令一名体力值不大于%arg的角色执行一项',
  ['@humei-phase'] = '狐魅',
  ['humei1-phase'] = '摸一张牌',
  ['humei2-phase'] = '交给你一张牌',
  ['humei3-phase'] = '回复1点体力',
  ['#humei-give'] = '狐魅：请交给 %src 一张牌',
  ['#humei_trigger'] = '狐魅',
  [':humei'] = '出牌阶段每项限一次，你可以选择一项，令一名体力值不大于X的角色执行（X为你本阶段造成伤害点数）：1.摸一张牌；2.交给你一张牌；3.回复1点体力。',
  ['$humei1'] = '尔为靴下之臣，当行顺我之事。',
  ['$humei2'] = '妾身一笑，可倾将军之城否？'
}

-- Active Skill
humei:addEffect('active', {
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = function(self, player)
    return "#humei:::"..player:getMark("@humei-phase")
  end,
  interaction = function(self, player)
    local choices = {}
    for i = 1, 3 do
      if player:getMark("humei"..i.."-phase") == 0 then
        table.insert(choices, "humei"..i.."-phase")
      end
    end
    return UI.ComboBox { choices = choices }
  end,
  can_use = function(self, player)
    for i = 1, 3 do
      if player:getMark("humei"..i.."-phase") == 0 then
        return true
      end
    end
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    local target = Fk:currentRoom():getPlayerById(to_select)
    if #selected == 0 and target.hp <= player:getMark("@humei-phase") then
      if self.interaction.data == "humei1-phase" then
        return true
      elseif self.interaction.data == "humei2-phase" then
        return not target:isNude()
      elseif self.interaction.data == "humei3-phase" then
        return target:isWounded()
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(player, self.interaction.data, 1)
    if self.interaction.data == "humei1-phase" then
      target:drawCards(1, humei.name)
    elseif self.interaction.data == "humei2-phase" then
      local card = room:askToCards(target, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = humei.name,
        prompt = "#humei-give:"..player.id,
      })
      room:obtainCard(player, card[1], false, fk.ReasonGive, target.id)
    elseif self.interaction.data == "humei3-phase" then
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = humei.name
      }
    end
  end,
})

-- Trigger Skill
humei:addEffect(fk.Damage, {
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(humei) and player.phase == Player.Play
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room  = player.room
    room:notifySkillInvoked(player, humei.name, "special")
    player:broadcastSkillInvoke(humei.name)
    room:addPlayerMark(player, "@humei-phase", data.damage)
  end,
})

return humei
