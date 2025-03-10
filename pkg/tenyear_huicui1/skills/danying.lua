local danying = fk.CreateSkill {
  name = "danying"
}

Fk:loadTranslationTable{
  ['danying'] = '胆迎',
  ['#danying_delay'] = '胆迎',
  [':danying'] = '每回合限一次，你可展示手牌中的『安』，然后视为使用或打出一张【杀】或【闪】。若如此做，本回合你下次成为牌的目标后，使用者弃置你一张牌。',
  ['$danying1'] = '早就想会会你常山赵子龙了。',
  ['$danying2'] = '赵子龙是吧？兜鍪给你打掉。',
}

danying:addEffect('viewas', {
  pattern = "slash,jink",
  interaction = function()
    local names = {}
    local pat = Fk.currentResponsePattern
    local slash = Fk:cloneCard("slash")
    if pat == nil and slash.skill:canUse(player, slash) then
      table.insert(names, "slash")
    else
      if Exppattern:Parse(pat):matchExp("slash") then
        table.insert(names, "slash")
      end
      if Exppattern:Parse(pat):matchExp("jink") then
        table.insert(names, "jink")
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names} --FIXME: 体验很不好！
  end,
  view_as = function(self, player, cards)
    if self.interaction.data == nil then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = danying.name
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    local cid = player:getMark(miyun.name)
    if table.contains(player.player_cards[player.Hand], cid) then
      player:showCards({cid})
    end
  end,
  enabled_at_play = function(self, player)
    if player:usedSkillTimes(danying.name) > 0 or not table.contains(player.player_cards[player.Hand], player:getMark(miyun.name)) then
      return false
    end
    local slash = Fk:cloneCard("slash")
    return slash.skill:canUse(player, slash)
  end,
  enabled_at_response = function(self, player)
    if player:usedSkillTimes(danying.name) > 0 or not table.contains(player.player_cards[player.Hand], player:getMark(miyun.name)) then
      return false
    end
    local pat = Fk.currentResponsePattern
    return pat and Exppattern:Parse(pat):matchExp(self.pattern)
  end,
})

danying:addEffect(fk.TargetConfirmed, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes(danying.name) > 0 and player:usedSkillTimes("#danying_delay") == 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = room:getPlayerById(data.from)
    if not from.dead and not player.dead and not player:isNude() then
      local cid = room:askToChooseCard(from, {target = player, flag = "he", skill_name = danying.name})
      room:throwCard({cid}, danying.name, player, from)
    end
  end,
})

return danying
