local shuaijie = fk.CreateSkill {
  name = "shuaijie",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["shuaijie"] = "衰劫",
  [":shuaijie"] = "限定技，出牌阶段，若你体力值与装备区里的牌均大于“私掠”角色或“私掠”角色已死亡，你可以减1点体力上限，然后选择一项：<br>"..
  "1.获得“私掠”角色至多3张牌；2.从牌堆获得三张类型不同的牌。然后“私掠”角色改为你。",

  ["#shuaijie"] = "衰劫：你可以减1点体力上限，执行效果并将“私掠”角色改为你！",
  ["shuaijie1"] = "获得%dest至多三张牌",
  ["shuaijie2"] = "从牌堆获得三张类型不同的牌",

  ["$shuaijie1"] = "弱肉强食，实乃天地至理。",
  ["$shuaijie2"] = "恃强凌弱，方为我辈本色！",
}

shuaijie:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#shuaijie",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    if player:usedSkillTimes(shuaijie.name, Player.HistoryGame) == 0 and player:getMark("silue") ~= 0 then
      local to = Fk:currentRoom():getPlayerById(player:getMark("silue"))
      return to.dead or (player.hp > to.hp and #player:getCardIds("e") > #to:getCardIds("e"))
    end
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    room:changeMaxHp(player, -1)
    if player.dead then return end
    local to = room:getPlayerById(player:getMark("silue"))
    local choices = {"shuaijie2"}
    if not to.dead and not to:isNude() then
      table.insert(choices, 1, "shuaijie1::"..to.id)
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = shuaijie.name,
    })
    if choice:startsWith("shuaijie1") then
      room:doIndicate(player, {to})
      local cards = room:askToChooseCards(player, {
        target = to,
        min = 1,
        max = 3,
        flag = "he",
        skill_name = shuaijie.name,
      })
      room:obtainCard(player, cards, false, fk.ReasonPrey, player, shuaijie.name)
    else
      local cards = {}
      local types = {"basic", "trick", "equip"}
      while #types > 0 do
        local pattern = table.random(types)
        table.removeOne(types, pattern)
        table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|"..pattern))
      end
      if #cards > 0 then
        room:obtainCard(player, cards, false, fk.ReasonJustMove, player, shuaijie.name)
      end
    end
    if not player.dead and player:hasSkill("silue", true) then
      room:setPlayerMark(player, "silue", player.id)
      room:setPlayerMark(player, "@silue", player.general)
    end
  end,
})

return shuaijie
