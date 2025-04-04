local xiangshuz = fk.CreateSkill {
  name = "xiangshuz",
}

Fk:loadTranslationTable{
  ["xiangshuz"] = "相鼠",
  [":xiangshuz"] = "其他角色出牌阶段开始时，若其手牌数不小于体力值，你可以声明一个0~5的数字（若你弃置一张手牌，则数字不公布）。"..
  "此阶段结束时，若其手牌数与你声明的数：相差1以内，你获得其一张牌；相等，你对其造成1点伤害。",

  ["#xiangshuz-invoke"] = "相鼠：猜测 %dest 此阶段结束时手牌数，若相差1以内，获得其一张牌；相等，再对其造成1点伤害",
  ["#xiangshuz-choice"] = "相鼠：猜测 %dest 此阶段结束时的手牌数",
  ["#xiangshuz-discard"] = "相鼠：你可以弃置一张手牌令你猜测的数值不公布",
  ["@xiangshuz-phase"] = "相鼠",

  ["$xiangshuz1"] = "要财还是要命，选一个吧！",
  ["$xiangshuz2"] = "有什么好东西，都给我交出来！",
}

xiangshuz:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(xiangshuz.name) and target.phase == Player.Play and
      target:getHandcardNum() >= target.hp
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = xiangshuz.name,
      prompt = "#xiangshuz-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    for i = 0, 5, 1 do
      table.insert(choices, tostring(i))
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = xiangshuz.name,
      prompt = "#xiangshuz-choice::"..target.id,
    })
    if player:isKongcheng() or #room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = xiangshuz.name,
      cancelable = true,
      prompt = "#xiangshuz-discard",
    }) == 0 then
      room:setPlayerMark(player, "@xiangshuz-phase", choice)
      room:sendLog{
        type = "#Choice",
        from = player.id,
        arg = choice,
        toast = true,
      }
    end
    if not target.dead then
      room:setPlayerMark(player, "xiangshuz-phase", choice)
    end
  end,
})

xiangshuz:addEffect(fk.EventPhaseEnd, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target ~= player and target.phase == Player.Play and
      player:getMark("xiangshuz-phase") ~= 0 and not player.dead
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n1 = target:getHandcardNum()
    local n2 = tonumber(player:getMark("xiangshuz-phase"))
    if math.abs(n1 - n2) < 2 and not target:isNude() then
      local id = room:askToChooseCard(player, {
        target = target,
        flag = "he",
        skill_name = xiangshuz.name,
      })
      room:obtainCard(player, id, false, fk.ReasonPrey, player, xiangshuz.name)
    end
    if n1 == n2 and not target.dead then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = xiangshuz.name,
      }
    end
  end,
})

return xiangshuz
