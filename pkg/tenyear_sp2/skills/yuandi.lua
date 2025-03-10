local yuandi = fk.CreateSkill {
  name = "yuandi"
}

Fk:loadTranslationTable{
  ['yuandi'] = '元嫡',
  ['#yuandi-invoke'] = '元嫡：你可以弃置 %dest 的一张手牌或与其各摸一张牌',
  ['yuandi_draw'] = '你与其各摸一张牌',
  ['yuandi_discard'] = '弃置其一张手牌',
  [':yuandi'] = '其他角色于其出牌阶段使用第一张牌时，若此牌没有指定除其以外的角色为目标，你可以选择一项：1.弃置其一张手牌；2.你与其各摸一张牌。',
  ['$yuandi1'] = '此生与君为好，共结连理。',
  ['$yuandi2'] = '结发元嫡，其情唯衷孙郎。',
}

yuandi:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(yuandi.name) and target ~= player and target.phase == Player.Play and target:getMark("yuandi-phase") == 0 then
      player.room:addPlayerMark(target, "yuandi-phase", 1)
      if data.tos then
        for _, id in ipairs(TargetGroup:getRealTargets(data.tos)) do
          if id ~= target.id then
            return
          end
        end
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {skill_name = yuandi.name, prompt = "#yuandi-invoke::"..target.id})
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"yuandi_draw"}
    if not target:isKongcheng() then
      table.insert(choices, 1, "yuandi_discard")
    end
    local choice = room:askToChoice(player, {choices = choices, skill_name = yuandi.name})
    if choice == "yuandi_discard" then
      local id = room:askToChooseCard(player, {target = target, flag = "h", skill_name = yuandi.name})
      room:throwCard({id}, yuandi.name, target, player)
    else
      player:drawCards(1, yuandi.name)
      target:drawCards(1, yuandi.name)
    end
  end,
})

return yuandi
