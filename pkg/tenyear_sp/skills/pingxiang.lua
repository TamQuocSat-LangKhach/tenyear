local pingxiang = fk.CreateSkill {
  name = "pingxiang",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["pingxiang"] = "平襄",
  [":pingxiang"] = "限定技，出牌阶段，若你的体力上限大于9，你可以减9点体力上限。若如此做，你失去技能〖九伐〗且本局游戏内你的手牌上限等于"..
  "体力上限，然后你可以视为使用至多九张火【杀】。",

  ["#pingxiang"] = "平襄：你可以减9点体力上限，视为使用至多九张火【杀】！",
  ["#pingxiang-slash"] = "平襄：你可以视为使用火【杀】（第%arg张，共9张）！",

  ["$pingxiang1"] = "策马纵慷慨，捐躯抗虎豺。",
  ["$pingxiang2"] = "解甲事仇雠，竭力挽狂澜。",
}

pingxiang:addEffect("active", {
  anim_type = "offensive",
  prompt = "#pingxiang",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player.maxHp > 9 and player:usedSkillTimes(pingxiang.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    room:changeMaxHp(player, -9)
    if player.dead then return end
    room:handleAddLoseSkills(player, "-jiufa")
    for i = 1, 9 do
      if player.dead or not room:askToUseVirtualCard(player, {
        name = "fire__slash",
        skill_name = pingxiang.name,
        prompt = "#pingxiang-slash:::" .. i,
        cancelable = true,
        extra_data = {
          bypass_times = true,
          extraUse = true,
        },
      }) then
        break
      end
    end
  end,
})

pingxiang:addEffect("maxcards", {
  fixed_func = function(self, player)
    if player:usedSkillTimes(pingxiang.name, Player.HistoryGame) > 0 then
      return player.maxHp
    end
  end
})

return pingxiang
