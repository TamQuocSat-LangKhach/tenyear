local ty__sitian = fk.CreateSkill {
  name = "ty__sitian"
}

Fk:loadTranslationTable{
  ['ty__sitian'] = '司天',
  ['sitian1'] = '烈日',
  ['sitian2'] = '雷电',
  ['sitian3'] = '大浪',
  ['sitian4'] = '暴雨',
  ['sitian5'] = '大雾',
  ['#ty__sitian-choice'] = '司天：选择执行的一项',
  ['#sitian-choose'] = '暴雨：令一名角色弃置所有手牌，若其没有手牌则改为失去1点体力。',
  ['@@lw_dawu'] = '雾',
  ['#sitian_trigger'] = '司天',
  [':ty__sitian'] = '出牌阶段，你可以弃置两张不同花色的手牌，然后改变天气（从两个选项中选择一项）：<br>烈日：对其他角色各造成1点火焰伤害；<br>雷电：所有其他角色各进行一次【闪电】判定；<br>大浪：所有其他角色弃置装备区所有牌（没有装备则失去1点体力）；<br>暴雨：弃置一名角色所有手牌（没有手牌则失去1点体力）；<br>大雾：所有其他角色使用的下一张基本牌无效。',
  ['$ty__sitian1'] = '观众朋友大家好，欢迎收看天气预报！',
  ['$ty__sitian2'] = '这一喷嚏，不知要掀起多少狂风暴雨。',
}

ty__sitian:addEffect('active', {
  anim_type = "offensive",
  card_num = 2,
  target_num = 0,
  can_use = function(self, player)
    return player:getHandcardNum() > 1
  end,
  card_filter = function(self, player, to_select, selected)
    if player:prohibitDiscard(Fk:getCardById(to_select)) then
      return false
    end

    if Fk:currentRoom():getCardArea(to_select) == Player.Hand and #selected < 2 then
      if #selected == 1 then
        return Fk:getCardById(to_select).suit ~= Fk:getCardById(selected[1]).suit
      end
      return true
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, ty__sitian.name, player, player)
    local choices = table.random({"sitian1", "sitian2", "sitian3", "sitian4", "sitian5"}, 2)
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = ty__sitian.name,
      prompt = "#ty__sitian-choice",
      detailed = true
    })
    local targets = room:getOtherPlayers(player)
    if choice ~= "sitian4" then
      room:doIndicate(player.id, table.map(targets, Util.IdMapper))
    end
    if choice == "sitian1" then
      for _, p in ipairs(targets) do
        if not p.dead then
          room:damage{
            from = player,
            to = p,
            damage = 1,
            damageType = fk.FireDamage,
            skillName = ty__sitian.name
          }
        end
      end
    end
    if choice == "sitian2" then
      for _, p in ipairs(targets) do
        if not p.dead then
          local judge = {
            who = p,
            reason = "lightning",
            pattern = ".|2~9|spade",
          }
          room:judge(judge)
          local result = judge.card
          if result.suit == Card.Spade and result.number >= 2 and result.number <= 9 then
            room:damage{
              to = p,
              damage = 3,
              card = effect.card,
              damageType = fk.ThunderDamage,
              skillName = ty__sitian.name,
            }
          end
        end
      end
    end
    if choice == "sitian3" then
      for _, p in ipairs(targets) do
        if not p.dead then
          if #p.player_cards[Player.Equip] > 0 then
            p:throwAllCards("e")
          else
            room:loseHp(p, 1, ty__sitian.name)
          end
        end
      end
    end
    if choice == "sitian4" then
      local tos = room:askToChoosePlayers(player, {
        targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
        min_num = 1,
        max_num = 1,
        prompt = "#sitian-choose",
        skill_name = ty__sitian.name,
        cancelable = true
      })
      local to
      if #tos > 0 then
        to = room:getPlayerById(tos[1])
        if not to:isKongcheng() then
          to:throwAllCards("h")
        else
          room:loseHp(to, 1, ty__sitian.name)
        end
      end
    end
    if choice == "sitian5" then
      for _, p in ipairs(targets) do
        if not p.dead then
          room:setPlayerMark(p, "@@lw_dawu", 1)
        end
      end
    end
  end,
})

ty__sitian:addEffect(fk.PreCardEffect, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target and target:getMark("@@lw_dawu") > 0 and data.card.type == Card.TypeBasic
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(target, "@@lw_dawu", 0)
    return true
  end,
})

return ty__sitian
