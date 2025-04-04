local dunshi = fk.CreateSkill {
  name = "dunshi",
  dynamic_desc = function (self, player)
    if #player:getTableMark(self.name) == 4 then
      return "dummyskill"
    elseif player:getMark(self.name) ~= 0 then
      local str = {}
      for _, name in ipairs({"slash", "jink", "peach", "analeptic"}) do
        if table.contains(player:getMark(self.name), name) then
          table.insert(str, "<s>【"..Fk:translate(name).."】</s>")
        else
          table.insert(str, "【"..Fk:translate(name).."】")
        end
      end
      return "dunshi_inner:"..table.concat(str, "")
    end
  end,
}

Fk:loadTranslationTable{
  ["dunshi"] = "遁世",
  [":dunshi"] = "每回合限一次，你可以视为使用或打出一张【杀】【闪】【桃】【酒】。然后当前回合角色本回合下次造成伤害时，你选择两项：<br>"..
  "1.防止此伤害，选择一个包含“仁义礼智信”的技能令其获得；<br>2.减1点体力上限并摸X张牌（X为你已删除的牌名数）；<br>3.删除你本次视为使用的牌名。",

  [":dunshi_inner"] = "每回合限一次，你可以视为使用或打出一张{1}。然后当前回合角色本回合下次造成伤害时，你选择两项：<br>"..
  "1.防止此伤害，选择一个包含“仁义礼智信”的技能令其获得；<br>2.减1点体力上限并摸X张牌（X为你已删除的牌名数）；<br>3.删除你本次视为使用的牌名。",

  ["#dunshi"] = "遁世：视为使用基本牌，当前回合角色下次造成伤害时执行选项",
  ["dunshi1"] = "防止此伤害，选择一个“仁义礼智信”的技能令%dest获得",
  ["dunshi2"] = "减1点体力上限并摸%arg张牌",
  ["dunshi3"] = "删除你本次视为使用的牌名【%arg】",
  ["#dunshi-choice"] = "遁世：选择令 %dest 获得的技能",

  ["$dunshi1"] = "失路青山隐，藏名白水游。",
  ["$dunshi2"] = "隐居青松畔，遁走孤竹丘。",
}

local U = require "packages/utility/utility"

dunshi:addEffect("viewas", {
  pattern = "slash,jink,peach,analeptic",
  prompt = "#dunshi",
  interaction = function(self, player)
    local all_names = table.filter({"slash", "jink", "peach", "analeptic"}, function (name)
      return not table.contains(player:getTableMark(dunshi.name), name)
    end)
    local names = player:getViewAsCardNames(dunshi.name, all_names)
    if #names == 0 then return end
    return U.CardNameBox {choices = names, all_choices = all_names }
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    if not self.interaction.data then return nil end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = dunshi.name
    return card
  end,
  before_use = function(self, player, use)
    player.room:setPlayerMark(player, "dunshi_record-turn", {player.room.current.id, use.card.trueName})
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(dunshi.name, Player.HistoryTurn) == 0 and
      #player:getTableMark(dunshi.name) < 4
  end,
  enabled_at_response = function(self, player, response)
    return player:usedSkillTimes(dunshi.name, Player.HistoryTurn) == 0 and
      #player:getViewAsCardNames(dunshi.name, table.filter({"slash", "jink", "peach", "analeptic"}, function (name)
        return not table.contains(player:getTableMark(dunshi.name), name)
      end)) > 0
  end,
})

dunshi:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, dunshi.name, 0)
end)

dunshi:addEffect(fk.DamageCaused, {
  anim_type = "special",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:getMark("dunshi_record-turn") ~= 0 and target and
      player:getMark("dunshi_record-turn")[1] == target.id
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local name = player:getMark("dunshi_record-turn")[2]
    room:setPlayerMark(player, "dunshi_record-turn", 0)
    local choices = {"dunshi1::"..target.id, "dunshi2:::"..#player:getTableMark(dunshi.name), "dunshi3:::"..name}
    for _ = 1, 2 do
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = dunshi.name,
      })
      table.removeOne(choices, choice)
      if choice:startsWith("dunshi1") then
        data:preventDamage()
        local skills = {}
        for _, general in ipairs(Fk:getAllGenerals()) do
          for _, skill in ipairs(general:getSkillNameList()) do
            local str = Fk:translate(skill, "zh_CN")
            if not target:hasSkill(skill, true) and
              table.find({"仁", "义", "礼", "智", "信"}, function (s)
                return string.find(str, s) ~= nil
              end) then
              table.insertIfNeed(skills, skill)
            end
          end
        end
        if #skills > 0 then
          local skill = room:askToChoice(player, {
            choices = table.random(skills, 3),
            skill_name = dunshi.name,
            prompt = "#dunshi-choice::"..target.id,
          })
          room:handleAddLoseSkills(target, skill)
        end
      elseif choice:startsWith("dunshi2") then
        room:changeMaxHp(player, -1)
        if not player.dead and player:getMark(dunshi.name) ~= 0 then
          player:drawCards(#player:getTableMark(dunshi.name), dunshi.name)
        end
      elseif choice:startsWith("dunshi3") then
        room:addTableMark(player, dunshi.name, name)
      end
    end
  end,
})

return dunshi
