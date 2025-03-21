local ty_ex__qieting = fk.CreateSkill {
  name = "ty_ex__qieting"
}

Fk:loadTranslationTable{
  ['ty_ex__qieting'] = '窃听',
  ['#ty_ex__qieting-move'] = '窃听：你可以将 %src 装备区里的一张牌置入你的装备区',
  [':ty_ex__qieting'] = '其他角色的回合结束时，若其本回合：没有造成过伤害，你可以将其装备区里的一张牌置入你的装备区；没有对其他角色使用过牌，你摸一张牌。',
  ['$ty_ex__qieting1'] = '谋略未定，窃听以察先机。',
  ['$ty_ex__qieting2'] = '所见相同，何必畏我？'
}

ty_ex__qieting:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(ty_ex__qieting.name) and target ~= player and target.phase == Player.Finish
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choices = {}
    if #player.room.logic:getEventsOfScope(GameEvent.Damage, 1, function(e)
      local damage = e.data[1]
      return damage.from and damage.from == target
    end, Player.HistoryTurn) == 0 then
      if target:canMoveCardsInBoardTo(player, "e") and room:askToSkillInvoke(player, {skill_name = ty_ex__qieting.name, prompt = "#ty_ex__qieting-move:"..target.id}) then
        table.insert(choices, "move")
      end
    end
    if #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
      local use = e.data[1]
      if use.from == target.id and use.tos then
        if table.find(TargetGroup:getRealTargets(use.tos), function(pid) return pid ~= target.id end) then
          return true
        end
      end
      return false
    end, Player.HistoryTurn) == 0 then
      table.insert(choices, "draw")
    end
    if #choices > 0 then
      event:setCostData(self, choices)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if table.contains(event:getCostData(self), "move") then
      room:askToMoveCardInBoard(player, {target_one = target, target_two = player, skill_name = ty_ex__qieting.name, flag = "e", move_from = target})
    end
    if not player.dead and table.contains(event:getCostData(self), "draw") then
      player:drawCards(1, ty_ex__qieting.name)
    end
  end,
})

return ty_ex__qieting
