local ty_ex__xianzhou = fk.CreateSkill {
  name = "ty_ex__xianzhou"
}

Fk:loadTranslationTable{
  ['ty_ex__xianzhou'] = '献州',
  ['#ty_ex__xianzhou-choose'] = '献州：对 %dest 攻击范围内至多 %arg 名角色各造成1点伤害',
  [':ty_ex__xianzhou'] = '限定技，出牌阶段，你可以将装备区里的所有牌交给一名其他角色，然后你回复X点体力，并对其攻击范围内的至多X名角色各造成1点伤害（X为你交给其的牌数）。',
  ['$ty_ex__xianzhou1'] = '举州请降，高枕无忧。',
  ['$ty_ex__xianzhou2'] = '州固可贵，然不及我儿安危。',
}

ty_ex__xianzhou:addEffect('active', {
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(ty_ex__xianzhou.name, Player.HistoryGame) == 0 and #player.player_cards[Player.Equip] > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local n = #player:getCardIds("e")
    room:obtainCard(target, player:getCardIds(Player.Equip), false, fk.ReasonGive, player.id)
    if not player.dead and player:isWounded() then
      room:recover({
        who = player,
        num = math.min(n, player:getLostHp()),
        recoverBy = player,
        skillName = ty_ex__xianzhou.name
      })
    end
    if player.dead or target.dead then return end
    local targets = table.filter(room:getOtherPlayers(target), function(p) return target:inMyAttackRange(p) end)
    if #targets > 0 then
      local tos = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = n,
        prompt = "#ty_ex__xianzhou-choose::" .. target.id .. ":" .. n,
        skill_name = ty_ex__xianzhou.name,
      })
      if #tos > 0 then
        for _, p in ipairs(tos) do
          room:damage{
            from = player,
            to = p,
            damage = 1,
            skillName = ty_ex__xianzhou.name,
          }
        end
      end
    end
  end,
})

return ty_ex__xianzhou
