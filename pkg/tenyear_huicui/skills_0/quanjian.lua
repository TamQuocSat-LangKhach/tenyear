local quanjian = fk.CreateSkill {
  name = "quanjian"
}

Fk:loadTranslationTable{
  ['quanjian'] = '劝谏',
  ['#quanjian'] = '令一名其他角色执行造成伤害或调整手牌，若其不执行本回合下次受伤值+1',
  ['quanjian1'] = '造成伤害',
  ['#quanjian-choose'] = '劝谏：选择一名其攻击范围内的角色',
  ['#quanjian-damage'] = '劝谏：是否对 %src 造成1点伤害，若选否，本回合你下次受伤害+1',
  ['#quanjian-draw'] = '劝谏：是否将手牌调整至手牌上限(至多摸至5张)，且本回合不能用手牌',
  ['@@quanjian_prohibit-turn'] = '劝谏:封手牌',
  ['@quanjian_damage-turn'] = '劝谏:受伤+',
  [':quanjian'] = '出牌阶段每项限一次，你选择以下一项令一名其他角色选择是否执行：1.对一名其攻击范围内你指定的角色造成1点伤害。2.将手牌调整至手牌上限（最多摸到5张），其不能使用手牌直到回合结束。若其不执行，则其本回合下次受到的伤害+1。',
  ['$quanjian1'] = '陛下宜后镇，臣请为先锋！',
  ['$quanjian2'] = '吴人悍战，陛下万不可涉险！',
}

quanjian:addEffect('active', {
  anim_type = "control",
  prompt = "#quanjian",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:getMark("quanjian1-phase") == 0 or player:getMark("quanjian2-phase") == 0
  end,
  interaction = function(self)
    local choices = {}
    for i = 1, 2 do
      if self.player:getMark("quanjian"..i.."-phase") == 0 then
        table.insert(choices, "quanjian"..i)
      end
    end
    return UI.ComboBox { choices = choices }
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected == 0 and to_select ~= self.player.id then
      if self.interaction.data == "quanjian1" then
        return true
      else
        for _, p in ipairs(Fk:currentRoom().alive_players) do
          if Fk:currentRoom():getPlayerById(to_select):inMyAttackRange(p) then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local choice = self.interaction.data
    room:setPlayerMark(player, choice.."-phase", 1)
    if choice == "quanjian1" then
      local targets = table.filter(room.alive_players, function(p) return target:inMyAttackRange(p) end)
      if #targets > 0 then
        local tos = room:askToChoosePlayers(player, {
          targets = table.map(targets, Util.IdMapper),
          min_num = 1,
          max_num = 1,
          prompt = "#quanjian-choose",
          skill_name = quanjian.name,
          cancelable = false,
        })
        local victim = tos[1]
        if room:askToSkillInvoke(target, {
          skill_name = quanjian.name,
          prompt = "#quanjian-damage:"..victim
        }) then
          room:doIndicate(target.id, {victim})
          room:damage{
            from = target,
            to = room:getPlayerById(victim),
            damage = 1,
            skillName = quanjian.name,
          }
          return
        end
      end
    else
      local n = target:getMaxCards()
      if room:askToSkillInvoke(target, {
        skill_name = quanjian.name,
        prompt = "#quanjian-draw"
      }) then
        if target:getHandcardNum() > n then
          n = target:getHandcardNum() - n
          room:askToDiscard(target, {
            min_num = n,
            max_num = n,
            include_equip = false,
            skill_name = quanjian.name,
            cancelable = false,
          })
        elseif target:getHandcardNum() < math.min(n, 5) then
          target:drawCards(math.min(n, 5) - target:getHandcardNum())
        end
        if not target.dead then
          room:setPlayerMark(target, "@@quanjian_prohibit-turn", 1)
        end
        return
      end
    end
    room:addPlayerMark(target, "@quanjian_damage-turn", 1)
  end,
})

quanjian:addEffect('prohibit', {
  name = "#quanjian_prohibit",
  prohibit_use = function(self, player, card)
    if player:getMark("@@quanjian_prohibit-turn") > 0 then
      local subcards = Card:getIdList(card)
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player.player_cards[Player.Hand], id)
      end)
    end
  end,
})

quanjian:addEffect('trigger', {
  name = "#quanjian_record",
  anim_type = "offensive",

  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target:getMark("@quanjian_damage-turn") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.damage = data.damage + target:getMark("@quanjian_damage-turn")
    player.room:setPlayerMark(target, "@quanjian_damage-turn", 0)
  end,
})

return quanjian
