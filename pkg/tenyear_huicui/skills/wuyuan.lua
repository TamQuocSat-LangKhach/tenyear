local wuyuan = fk.CreateSkill {
  name = "ty__wuyuan",
}

Fk:loadTranslationTable{
  ["ty__wuyuan"] = "武缘",
  [":ty__wuyuan"] = "出牌阶段限一次，你可以将一张【杀】交给一名其他角色，然后你回复1点体力并与其各摸一张牌；若此【杀】为："..
  "红色，其回复1点体力；属性【杀】，其多摸一张牌。",

  ["#ty__wuyuan"] = "武缘：将一张【杀】交给一名角色，你回复1点体力并与其各摸一张牌",

  ["$ty__wuyuan1"] = "生为关氏之妇，虽死亦不悔。",
  ["$ty__wuyuan2"] = "我夫关长生，乃盖世之英雄。",
}

wuyuan:addEffect("active", {
  anim_type = "support",
  prompt = "#ty__wuyuan",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(wuyuan.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).trueName == "slash"
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local card = Fk:getCardById(effect.cards[1])
    room:moveCardTo(card, Card.PlayerHand, target, fk.ReasonGive, wuyuan.name, nil, true, player)
    if not player.dead and player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = wuyuan.name,
      }
    end
    if not player.dead then
      player:drawCards(1, wuyuan.name)
    end
    if not target.dead then
      if card.color == Card.Red and target:isWounded() then
        room:recover{
          who = target,
          num = 1,
          recoverBy = player,
          skillName = wuyuan.name,
        }
      end
      if not target.dead then
        local n = card.name ~= "slash" and 2 or 1
        target:drawCards(n, wuyuan.name)
      end
    end
  end,
})

return wuyuan
