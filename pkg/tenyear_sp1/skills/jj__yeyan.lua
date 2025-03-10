local jj__yeyan = fk.CreateSkill {
  name = "jj__yeyan&"
}

Fk:loadTranslationTable{
  ['jj__yeyan&'] = '业炎',
  ['@@dragon_mark'] = '龙印',
  ['@@phoenix_mark'] = '凤印',
  [':jj__yeyan&'] = '限定技，出牌阶段，你可以移去“龙印”和“凤印”并指定一至三名角色，你分别对这些角色造成至多共计3点火焰伤害；若你对一名角色分配2点或更多的火焰伤害，你须先弃置四张不同花色的手牌并失去3点体力。',
}

jj__yeyan:addEffect('active', {
  anim_type = "offensive",
  min_target_num = 1,
  max_target_num = 3,
  min_card_num = 0,
  max_card_num = 4,
  frequency = Skill.Limited,
  prompt = function(self, player, cards)
    local yeyan_type = skill.interaction.data
    if yeyan_type == "great_yeyan" then
      return "#yeyan-great-active"
    elseif yeyan_type == "middle_yeyan" then
      if #cards ~= 4 then
        return "#yeyan-middle-active"
      else
        return "#yeyan-middle-choose"
      end
    else
      return "#yeyan-small-active"
    end
  end,
  interaction = function()
    return UI.ComboBox {
      choices = {"small_yeyan", "middle_yeyan", "great_yeyan"}
    }
  end,
  target_tip = function(self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    if not selectable then return end
    if #selected == 0 then
      return { {content = skill.interaction.data, type = "normal"} }
    else
      if to_select == selected[1] then
        return { {content = skill.interaction.data, type = "warning"} }
      elseif table.contains(selected, to_select) then
        return { {content = "small_yeyan", type = "warning"} }
      else
        return { {content = "small_yeyan", type = "normal"} }
      end
    end
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(jj__yeyan.name, Player.HistoryGame) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    if skill.interaction.data == "small_yeyan" or #selected > 3 or
      Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerHand then return false end
    local card = Fk:getCardById(to_select)
    return not player:prohibitDiscard(card) and card.suit ~= Card.NoSuit and
      table.every(selected, function (id) return card.suit ~= Fk:getCardById(id).suit end)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if skill.interaction.data == "small_yeyan" then
      return #selected_cards == 0 and #selected < 3
    elseif skill.interaction.data == "middle_yeyan" then
      return #selected_cards == 4 and #selected < 2
    else
      return #selected_cards == 4 and #selected == 0
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    doJianjieMarkChange (room, player, "@@dragon_mark", false, player)
    doJianjieMarkChange (room, player, "@@phoenix_mark", false, player)
    local first = room:getPlayerById(effect.tos[1])
    local max_damage = 1
    if skill.interaction.data == "middle_yeyan" then
      max_damage = 2
    elseif skill.interaction.data == "great_yeyan" then
      max_damage = 3
    end
    room:sortPlayersByAction(effect.tos)
    if #effect.cards > 0 then
      room:throwCard(effect.cards, jj__yeyan.name, player, player)
    end
    if max_damage > 1 and not player.dead then
      room:loseHp(player, 3, jj__yeyan.name)
    end
    for _, pid in ipairs(effect.tos) do
      local to = room:getPlayerById(pid)
      if not to.dead then
        room:damage{
          from = player,
          to = to,
          damage = (pid == first.id) and max_damage or 1,
          damageType = fk.FireDamage,
          skillName = jj__yeyan.name,
        }
      end
    end
  end,
})

return jj__yeyan
