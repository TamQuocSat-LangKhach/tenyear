local xiaowu = fk.CreateSkill {
  name = "xiaowu",
}

Fk:loadTranslationTable{
  ["xiaowu"] = "绡舞",
  [":xiaowu"] = "出牌阶段限一次，你可以从你的上家或下家起选择任意名座位连续的其他角色，每名角色依次选择一项：1.令你摸一张牌；"..
  "2.自己摸一张牌。若令你摸牌的选择人数较多，你获得一个“沙”标记；若自己摸牌的选择人数较多，你对这些角色各造成1点伤害。",

  ["#xiaowu"] = "绡舞：从上家或下家开始选择座次连续的其他角色，每名角色依次选择令你摸牌或自己摸牌",
  ["#xiawu_draw"] = "绡舞：点“确定”%src 摸一张牌，或点“取消”自己摸一张牌",
  ["@xiaowu_sand"] = "沙",

  ["$xiaowu1"] = "繁星临云袖，明月耀舞衣。",
  ["$xiaowu2"] = "逐舞飘轻袖，传歌共绕梁。",
}

xiaowu:addEffect("active", {
  anim_type = "offensive",
  prompt = "#xiaowu",
  card_num = 0,
  min_target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(xiaowu.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if to_select == player or to_select:isRemoved() then return end
    if #selected == 0 then
      return to_select == player:getNextAlive() or to_select:getNextAlive() == player
    else
      return table.contains(selected, to_select:getNextAlive()) or table.contains(selected, to_select:getLastAlive())
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local x, to_damage = 0, {}
    for _, p in ipairs(effect.tos) do
      if not p.dead then
        if player.dead then
          p:drawCards(1, xiaowu.name)
        else
          if room:askToSkillInvoke(p, {
            skill_name = xiaowu.name,
            prompt = "#xiawu_draw:"..player.id,
          }) then
            player:drawCards(1, xiaowu.name)
            x = x + 1
          else
            p:drawCards(1, xiaowu.name)
            table.insert(to_damage, p)
          end
        end
      end
    end
    if not player.dead then
      if x > #to_damage then
        room:addPlayerMark(player, "@xiaowu_sand")
      elseif x < #to_damage then
        room:sortByAction(to_damage)
        for _, p in ipairs(to_damage) do
          if not p.dead then
            room:damage{
              from = player,
              to = p,
              damage = 1,
              skillName = xiaowu.name,
            }
          end
        end
      end
    end
  end,
})

return xiaowu
