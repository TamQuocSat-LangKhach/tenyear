local fumou = fk.CreateSkill {
  name = "fumouj",
  tags = { Skill.Switch },
}

Fk:loadTranslationTable{
  ["fumouj"] = "覆谋",
  [":fumouj"] = "转换技，游戏开始时可自选阴阳状态。出牌阶段限一次，你可以观看一名其他角色的所有手牌，展示其中至多一半的牌（向上取整），"..
  "阳：令另一名其他角色获得这些牌，你与失去牌的角色各摸等量张牌。阴：令其按你选择的顺序依次使用这些牌（无距离限制且不能被响应）。",

  ["#fumouj-yang"] = "覆谋：观看一名其他角色的手牌，并将其中一半的牌交给另一名其他角色",
  ["#fumouj-yin"] = "覆谋：观看一名其他角色的手牌，令其依次使用其中一半的牌",
  ["#fumouj-show"] = "覆谋：展示 %dest 的至多%arg张手牌",
  ["#fumouj-choose"] = "覆谋：选择一名其他角色，令其获得 %dest 展示的这些牌",
  ["#fumouj-use"] = "覆谋：请使用 %arg（无距离限制且不能被响应）",

  ["$fumouj1"] = "恩仇付浊酒，荡平劫波，且做英雄吼。",
  ["$fumouj2"] = "人无恒敌，亦无恒友，唯有恒利。",
}

local U = require "packages/utility/utility"

fumou:addEffect("active", {
  anim_type = "switch",
  card_num = 0,
  target_num = 1,
  prompt = function (self, player)
    return "#fumouj-"..player:getSwitchSkillState(fumou.name, false, true)
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(fumou.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected, selected_cards)
    return to_select ~= player and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    U.SetSwitchSkillState(player, fumou.name, player:getSwitchSkillState(fumou.name, false))
    local cards = target:getCardIds("h")
    local x = (#cards + 1) // 2
    cards = room:askToChooseCards(player, {
      min = 1,
      max = x,
      target = target,
      skill_name = fumou.name,
      prompt = "#fumouj-show::" .. target.id .. ":" .. x,
      flag = { card_data = { { target.general, cards } } }
    })
    target:showCards(cards)
    room:delay(1000)

    if player:getSwitchSkillState(fumou.name, true) == fk.SwitchYang then
      local targets = room:getOtherPlayers(target, false)
      table.removeOne(targets, player)
      if #targets == 0 then return end
      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#fumouj-choose::" .. target.id,
        skill_name = fumou.name,
        cancelable = false,
      })[1]
      room:obtainCard(to, cards, true, fk.ReasonPrey, to, fumou.name)
      x = #cards
      if not player.dead then
        player:drawCards(x, fumou.name)
      end
      if not target.dead then
        target:drawCards(x, fumou.name)
      end
    else
      local card
      for _, id in ipairs(cards) do
        if target.dead then break end
        if table.contains(target:getCardIds("h"), id) then
          card = Fk:getCardById(id)
          if target:canUse(card, {bypass_distances = true, bypass_times = true}) then
            local use = room:askToUseRealCard(target, {
              pattern = {id},
              skill_name = fumou.name,
              prompt = "#fumouj-use:::" .. card:toLogString(),
              extra_data = {
                bypass_times = true,
                bypass_distances = true,
              },
              cancelable = false,
              skip = true,
            })
            if use then
              use.disresponsiveList = table.simpleClone(room.players)
              room:useCard(use)
            end
          end
        end
      end
    end
  end,
})

fumou:addEffect(fk.GameStart, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(fumou.name, true)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = { "tymou_switch:::fumou:yang", "tymou_switch:::fumou:yin" },
      skill_name = fumou.name,
      prompt = "#tymou_switch-choice:::fumou",
    })
    choice = choice:endsWith("yang") and fk.SwitchYang or fk.SwitchYin
    U.SetSwitchSkillState(player, fumou.name, choice)
  end,
})

return fumou
