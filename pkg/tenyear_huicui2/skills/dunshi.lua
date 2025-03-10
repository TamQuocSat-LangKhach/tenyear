local dunshi = fk.CreateSkill {
  name = "dunshi"
}

Fk:loadTranslationTable{
  ['dunshi'] = '遁世',
  ['@$dunshi'] = '遁世',
  ['#dunshi_record'] = '遁世',
  ['dunshi1'] = '防止此伤害，选择1个“仁义礼智信”的技能令其获得',
  ['dunshi2'] = '减1点体力上限并摸X张牌',
  ['dunshi3'] = '删除你本次视为使用的牌名',
  ['#dunshi-chooseskill'] = '遁世：选择令%dest获得的技能',
  [':dunshi'] = '每回合限一次，你可视为使用或打出一张【杀】，【闪】，【桃】或【酒】。然后当前回合角色本回合下次造成伤害时，你选择两项：<br>1.防止此伤害，选择1个包含“仁义礼智信”的技能令其获得；<br>2.减1点体力上限并摸X张牌（X为你选择3的次数）；<br>3.删除你本次视为使用的牌名。',
  ['$dunshi1'] = '失路青山隐，藏名白水游。',
  ['$dunshi2'] = '隐居青松畔，遁走孤竹丘。',
}

dunshi:addEffect('viewas', {
  name = "dunshi",
  pattern = "slash,jink,peach,analeptic",
  interaction = function(player)
    local all_names, names = {"slash", "jink", "peach", "analeptic"}, {}
    local mark = player:getMark("dunshi")
    for _, name in ipairs(all_names) do
      if type(mark) ~= "table" or not table.contains(mark, name) then
        local to_use = Fk:cloneCard(name)
        if ((Fk.currentResponsePattern == nil and to_use.skill:canUse(player, to_use) and not player:prohibitUse(to_use)) or
          (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(to_use))) then
          table.insertIfNeed(names, name)
        end
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    if not self.interaction.data then return nil end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = dunshi.name
    return card
  end,
  before_use = function(self, player, use)
    player.room:setPlayerMark(player, "dunshi_name-turn", use.card.trueName)
  end,
  enabled_at_play = function(self, player)
    if player:usedSkillTimes(dunshi.name, Player.HistoryTurn) > 0 then return false end
    local names = {"slash", "jink", "peach", "analeptic"}
    local mark = player:getMark("dunshi")
    for _, name in ipairs(names) do
      if type(mark) ~= "table" or not table.contains(mark, name) then
        local to_use = Fk:cloneCard(name)
        if to_use.skill:canUse(player, to_use) and not player:prohibitUse(to_use) then
          return true
        end
      end
    end
  end,
  enabled_at_response = function(self, player, response)
    if player:usedSkillTimes(dunshi.name, Player.HistoryTurn) > 0 then return false end
    local names = {"slash", "jink", "peach", "analeptic"}
    local mark = player:getMark("dunshi")
    for _, name in ipairs(names) do
      if type(mark) ~= "table" or not table.contains(mark, name) then
        local to_use = Fk:cloneCard(name)
        if (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(to_use)) then
          return true
        end
      end
    end
  end,
  on_acquire = function(self, player)
    player.room:setPlayerMark(player, "@$dunshi", {"slash", "jink", "peach", "analeptic"})
    player.room:setPlayerMark(player, "dunshi", 0)
  end,
  on_lose = function(self, player)
    player.room:setPlayerMark(player, "@$dunshi", 0)
    player.room:setPlayerMark(player, "dunshi", 0)
  end
})

dunshi:addEffect(fk.DamageCaused, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    if player:usedSkillTimes(dunshi.name, Player.HistoryTurn) > 0 and target and target == player.room.current then
      if target:getMark("dunshi-turn") == 0 then
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player.room:setPlayerMark(target, "dunshi-turn", 1)
    local choices = {"dunshi1", "dunshi2", "dunshi3"}
    for i = 1, 2, 1 do
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = dunshi.name
      })
      table.removeOne(choices, choice)
      if choice == "dunshi1" then
        local skills = {}
        for _, general in ipairs(Fk:getAllGenerals()) do
          for _, skill in ipairs(general.skills) do
            local str = Fk:translate(skill.name, "zh_CN")
            if not target:hasSkill(skill,true) and
              (string.find(str, "仁") or string.find(str, "义") or string.find(str, "礼") or string.find(str, "智") or string.find(str, "信")) then
              table.insertIfNeed(skills, skill.name)
            end
          end
        end
        if #skills > 0 then
          local skill = room:askToChoice(player, {
            choices = table.random(skills, math.min(3, #skills)),
            skill_name = dunshi.name,
            prompt = "#dunshi-chooseskill::"..target.id
          })
          room:handleAddLoseSkills(target, skill, nil, true, false)
        end
      elseif choice == "dunshi2" then
        room:changeMaxHp(player, -1)
        if not player.dead and player:getMark("dunshi") ~= 0 then
          player:drawCards(#player:getMark("dunshi"), dunshi.name)
        end
      elseif choice == "dunshi3" then
        room:addTableMark(player, "dunshi", player:getMark("dunshi_name-turn"))

        local UImark = player:getMark("@$dunshi")
        if type(UImark) == "table" then
          table.removeOne(UImark, player:getMark("dunshi_name-turn"))
          room:setPlayerMark(player, "@$dunshi", #UImark > 0 and UImark or 0)
        end
      end
    end
    if not table.contains(choices, "dunshi1") then
      return true
    end
  end,
})

return dunshi
