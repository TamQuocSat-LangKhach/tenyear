local xianzhou = fk.CreateSkill {
  name = "ty_ex__xianzhou",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["ty_ex__xianzhou"] = "献州",
  [":ty_ex__xianzhou"] = "限定技，出牌阶段，你可以将装备区里的所有牌交给一名其他角色，然后你回复X点体力，并对其攻击范围内至多X名角色"..
  "各造成1点伤害（X为你交给其的牌数）。",

  ["#ty_ex__xianzhou"] = "献州：将所有装备交给一名角色，你回复体力并对其攻击范围内的角色造成伤害",
  ["#ty_ex__xianzhou-choose"] = "献州：对 %dest 攻击范围内至多%arg名角色造成伤害",

  ["$ty_ex__xianzhou1"] = "举州请降，高枕无忧。",
  ["$ty_ex__xianzhou2"] = "州固可贵，然不及我儿安危。",
}

xianzhou:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ty_ex__xianzhou",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(xianzhou.name, Player.HistoryGame) == 0 and #player:getCardIds("e") > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local n = #player:getCardIds("e")
    room:obtainCard(target, player:getCardIds("e"), false, fk.ReasonGive, player, xianzhou.name)
    if not player.dead and player:isWounded() then
      room:recover{
        who = player,
        num = n,
        recoverBy = player,
        skillName = xianzhou.name,
      }
      if player.dead or target.dead then return end
    end
    local targets = table.filter(room:getOtherPlayers(target, false), function(p)
      return target:inMyAttackRange(p)
    end)
    if #targets > 0 then
      local tos = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = n,
        prompt = "#ty_ex__xianzhou-choose::"..target.id..":"..n,
        skill_name = xianzhou.name,
      })
      if #tos > 0 then
        room:sortByAction(tos)
        for _, p in ipairs(tos) do
          if not p.dead then
            room:damage{
              from = player,
              to = p,
              damage = 1,
              skillName = xianzhou.name,
            }
          end
        end
      end
    end
  end,
})

return xianzhou
