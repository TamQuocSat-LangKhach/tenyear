local xiangshuz = fk.CreateSkill {
  name = "xiangshuz"
}

Fk:loadTranslationTable{
  ['xiangshuz'] = '相鼠',
  ['#xiangshuz-invoke'] = '相鼠：猜测 %dest 此阶段结束时手牌数，若相差1以内，获得其一张牌；相等，再对其造成1点伤害',
  ['#xiangshuz-choice'] = '相鼠：猜测 %dest 此阶段结束时的手牌数',
  ['#xiangshuz-discard'] = '相鼠：你可以弃置一张手牌令你猜测的数值不公布',
  [':xiangshuz'] = '其他角色出牌阶段开始时，若其手牌数不小于体力值，你可以声明一个0~5的数字（若你弃置一张手牌，则数字不公布）。此阶段结束时，若其手牌数与你声明的数：相差1以内，你获得其一张牌；相等，你对其造成1点伤害。',
  ['$xiangshuz1'] = '要财还是要命，选一个吧！',
  ['$xiangshuz2'] = '有什么好东西，都给我交出来！',
}

xiangshuz:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(xiangshuz.name) and target.phase == Player.Play then
      return target:getHandcardNum() >= target.hp
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {skill_name = xiangshuz.name, prompt = "#xiangshuz-invoke::"..target.id})
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local choices = {}
    for i = 0, 5, 1 do
      table.insert(choices, tostring(i))
    end
    local choice = room:askToChoice(player, {choices = choices, skill_name = xiangshuz.name, prompt = "#xiangshuz-choice::"..target.id})
    local mark = xiangshuz.name
    if player:isKongcheng() or #room:askToDiscard(player, {min_num = 1, max_num = 1, include_equip = false, skill_name = xiangshuz.name, cancelable = true, pattern = ".", prompt = "#xiangshuz-discard"}) == 0 then
      mark = "@"..xiangshuz.name
    end
    room:setPlayerMark(target, mark, choice)
  end,
})

xiangshuz:addEffect(fk.EventPhaseEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(xiangshuz.name) and target.phase == Player.Play then
      return player:usedSkillTimes(xiangshuz.name, Player.HistoryPhase) > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local n1 = target:getHandcardNum()
    local n2 = math.max(tonumber(target:getMark(xiangshuz.name)), tonumber(target:getMark("@"..xiangshuz.name)))
    room:setPlayerMark(target, xiangshuz.name, 0)
    room:setPlayerMark(target, "@"..xiangshuz.name, 0)
    if math.abs(n1 - n2) < 2 and not target:isNude() then
      local id = room:askToChooseCard(player, {target = target, flag = "he", skill_name = xiangshuz.name})
      room:obtainCard(player.id, id, false, fk.ReasonPrey)
    end
    if n1 == n2 then
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
