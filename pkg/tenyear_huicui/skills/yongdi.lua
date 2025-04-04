local yongdi = fk.CreateSkill {
  name = "ty__yongdi",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["ty__yongdi"] = "拥嫡",
  [":ty__yongdi"] = "限定技，出牌阶段，你可以选择一名男性角色：若其体力值全场最少，其回复1点体力；体力上限全场最少，其加1点体力上限；"..
  "手牌数全场最少，其摸体力上限张牌（最多摸五张）。",

  ["#ty__yongdi"] = "拥嫡：选择一名男性角色，根据其体力值/体力上限/手牌数为全场最少的项执行效果",
  ["#ty__yongdi_maxHp"] = "加体力上限",

  ["$ty__yongdi1"] = "废长立幼，实乃取祸之道也。",
  ["$ty__yongdi2"] = "长幼有序，不可紊乱。",
}

yongdi:addEffect("active", {
  anim_type = "support",
  prompt = "#ty__yongdi",
  target_tip = function (self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    if not selectable then return end
    local ret = {}
    if table.every(Fk:currentRoom().alive_players, function(p)
      return p.hp >= to_select.hp
    end) and to_select:isWounded() then
      table.insert(ret, {
        content = "heal_hp",
        type = "normal",
      })
    end
    if table.every(Fk:currentRoom().alive_players, function(p)
      return p.maxHp >= to_select.maxHp
    end) then
      table.insert(ret, {
        content = "#ty__yongdi_maxHp",
        type = "normal",
      })
    end
    if table.every(Fk:currentRoom().alive_players, function(p)
      return p:getHandcardNum() >= to_select:getHandcardNum()
    end) then
      table.insert(ret, {
        content = "draw_card",
        type = "normal",
      })
    end
    return ret
  end,
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(yongdi.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select:isMale()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    if table.every(room.alive_players, function(p)
      return p.hp >= target.hp
    end) and target:isWounded() then
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = yongdi.name,
      }
      if target.dead then return end
    end
    if table.every(room.alive_players, function(p)
      return p.maxHp >= target.maxHp
    end) then
      room:changeMaxHp(target, 1)
      if target.dead then return end
    end
    if table.every(room.alive_players, function(p)
      return p:getHandcardNum() >= target:getHandcardNum()
    end) then
      target:drawCards(math.min(target.maxHp, 5), yongdi.name)
    end
  end
})

return yongdi
