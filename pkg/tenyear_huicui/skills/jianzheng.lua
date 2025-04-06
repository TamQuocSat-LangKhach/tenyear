local jianzheng = fk.CreateSkill {
  name = "jianzheng",
}

Fk:loadTranslationTable{
  ["jianzheng"] = "谏诤",
  [":jianzheng"] = "出牌阶段限一次，你可以观看一名其他角色的手牌，然后若其中有你可以使用的牌，你可以获得并使用其中一张，"..
  "若指定了其为目标，则横置你与其武将牌，然后其观看你的手牌。",

  ["#jianzheng"] = "谏诤：观看一名其他角色的手牌，且可以获得并使用其中一张",
  ["#jianzheng-choose"] = "谏诤：你可以获得并使用其中一张牌",
  ["#jianzheng-use"] = "谏诤：请使用%arg",

  ["$jianzheng1"] = "将军今出洛阳，恐难再回。",
  ["$jianzheng2"] = "贼示弱于外，必包藏祸心。",
}

local U = require "packages/utility/utility"

Fk:addPoxiMethod{
  name = "jianzheng",
  prompt = "#jianzheng-choose",
  card_filter = function(to_select, selected, data, extra_data)
    return #selected == 0 and table.contains(extra_data.jianzheng_cards, to_select)
  end,
  feasible = function(selected, data)
    return #selected == 1
  end,
}

jianzheng:addEffect("active", {
  anim_type = "control",
  prompt = "#jianzheng",
  target_num = 1,
  card_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(jianzheng.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local cards = table.filter(target:getCardIds("h"), function (id)
      return #Fk:getCardById(id):getDefaultTarget(player, {bypass_times = true}) > 0
    end)
    local result = room:askToPoxi(player, {
      poxi_type = jianzheng.name,
      data = { { target.general, target:getCardIds("h") } },
      extra_data = {
        jianzheng_cards = cards,
      },
      cancelable = true,
    })
    if #result > 0 then
      local id = result[1]
      local yes = false
      room:obtainCard(player, id, false, fk.ReasonPrey, player, jianzheng.name)
      local card = Fk:getCardById(id)
      if not player.dead and table.contains(player:getCardIds("h"), id) and
        #card:getDefaultTarget(player, {bypass_times = true}) > 0 then
        local use = room:askToUseRealCard(player, {
          pattern = {id},
          skill_name = jianzheng.name,
          prompt = "#jianzheng-use:::"..card:toLogString(),
          extra_data = {
            bypass_times = true,
            extraUse = true,
          },
          cancelable = false,
        })
        if use and table.contains(use.tos, target) then
          yes = true
        end
        if yes then
          if not player.dead and not player.chained then
            player:setChainState(true)
          end
          if not target.dead and not target.chained then
            target:setChainState(true)
          end
          if not player.dead and not target.dead and not player:isKongcheng() then
            U.viewCards(target, player:getCardIds("h"), jianzheng.name, "$ViewCardsFrom:"..player.id)
          end
        end
      end
    end
  end,
})

return jianzheng
