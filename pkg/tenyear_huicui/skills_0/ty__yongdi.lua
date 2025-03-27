local ty__yongdi = fk.CreateSkill {
  name = "ty__yongdi"
}

Fk:loadTranslationTable{
  ['ty__yongdi'] = '拥嫡',
  [':ty__yongdi'] = '限定技，出牌阶段，你可选择一名男性角色：若其体力值全场最少，其回复1点体力；体力上限全场最少，其加1点体力上限；手牌数全场最少，其摸体力上限张牌（最多摸五张）。',
  ['$ty__yongdi1'] = '废长立幼，实乃取祸之道也。',
  ['$ty__yongdi2'] = '长幼有序，不可紊乱。',
}

ty__yongdi:addEffect('active', {
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(ty__yongdi.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getPlayerById(to_select).gender == General.Male
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    if table.every(room.alive_players, function(p) return p.hp >= target.hp end) and target:isWounded() then
      room:recover({
        who = target,
        num = 1,
        recoverBy = player,
        skillName = ty__yongdi.name
      })
    end
    if table.every(room.alive_players, function(p) return p.maxHp >= target.maxHp end) then
      room:changeMaxHp(target, 1)
    end
    if table.every(room.alive_players, function(p) return p:getHandcardNum() >= target:getHandcardNum() end) then
      target:drawCards(math.min(target.maxHp, 5), ty__yongdi.name)
    end
  end
})

return ty__yongdi
