local shimou = fk.CreateSkill {
  name = "shimou",
  tags = { Skill.Switch },
}

Fk:loadTranslationTable{
  ["shimou"] = "势谋",
  [":shimou"] = "转换技，游戏开始时可自选阴阳状态。出牌阶段限一次，你可以选择一名：阳：手牌数全场最少的角色；阴：手牌数全场最多的角色，"..
  "其将手牌调整至体力上限（至多摸五张），然后你选择一张普通锦囊牌牌名和一个目标，视为其使用之。若因此摸牌，你可以为此牌额外指定一个目标；"..
  "若因此弃牌，你可以令此牌额外结算一次。",

  ["#shimou-yang"] = "势谋：令一名手牌数全场最少的角色将手牌调整至体力上限，然后视为使用你指定目标的锦囊牌",
  ["#shimou-yin"] = "势谋：令一名手牌数全场最多的角色将手牌调整至体力上限，然后视为使用你指定目标的锦囊牌",
  ["#shimou-use"] = "势谋：选择 %dest 视为使用的牌和至多%arg个目标",
  ["#shimou-extra"] = "势谋：是否令此牌额外结算一次？",

  ["$shimou1"] = "",
  ["$shimou2"] = "",
}

local U = require "packages/utility/utility"

shimou:addEffect("active", {
  anim_type = "switch",
  card_num = 0,
  target_num = 1,
  prompt = function (self, player)
    return "#shimou-"..player:getSwitchSkillState(shimou.name, false, true)
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(shimou.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected, selected_cards)
    if #selected == 0 then
      if player:getSwitchSkillState(shimou.name, false) == fk.SwitchYang then
        return table.every(Fk:currentRoom().alive_players, function (p)
          return p:getHandcardNum() >= to_select:getHandcardNum()
        end)
      else
        return table.every(Fk:currentRoom().alive_players, function (p)
          return p:getHandcardNum() <= to_select:getHandcardNum()
        end)
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    U.SetSwitchSkillState(player, shimou.name, player:getSwitchSkillState(shimou.name, false))
    local n = target:getHandcardNum() - target.maxHp
    if n < 0 then
      target:drawCards(math.min(5, -n), shimou.name)
    elseif n > 0 then
      room:askToDiscard(target, {
        min_num = n,
        max_num = n,
        include_equip = false,
        skill_name = shimou.name,
        cancelable = false,
      })
    end
    if player.dead or target.dead then return end
    if room:getBanner(shimou.name) == nil then
      local cards = {}
      for _, id in ipairs(U.prepareUniversalCards(room)) do
        local card = Fk:getCardById(id)
        if card:isCommonTrick() and not card.is_passive and card.name ~= "collateral" then
          table.insert(cards, id)
        end
      end
      room:setBanner(shimou.name, cards)
    end
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "shimou_active",
      prompt = "#shimou-use::"..target.id..":"..(n > 0 and 1 or 2),
      cancelable = true,
      extra_data = {
        shimou_target = target.id,
        n = n > 0 and 1 or 2,
      }
    })
    if not (success and dat) then
      dat = {}
      for _, id in ipairs(room:getBanner(shimou.name)) do
        local card = Fk:cloneCard(Fk:getCardById(id).name)
        card.skillName = shimou.name
        for _, p in ipairs(room.alive_players) do
          if card.skill:modTargetFilter(target, p, {}, card, {bypass_distances = true, bypass_times = true}) then
            dat.cards = {id}
            dat.targets = {p}
            break
          end
        end
      end
      if not dat.cards then return end
    end
    local yes = n > 0 and
      room:askToSkillInvoke(player, {
        skill_name = shimou.name,
        prompt = "#shimou-extra",
      })
    local card = Fk:cloneCard(Fk:getCardById(dat.cards[1]).name)
    card.skillName = shimou.name
    room:useCard({
      from = target,
      tos = dat.targets,
      card = card,
      extraUse = true,
    })
    if yes and not target.dead then
      local targets = table.filter(dat.targets, function (p)
        return not p.dead and not target:isProhibited(p, card)
      end)
      if #targets > 0 then
        room:useCard({
          from = target,
          tos = targets,
          card = card,
          extraUse = true,
        })
      end
    end
  end,
})

shimou:addEffect(fk.GameStart, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shimou.name, true)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = { "tymou_switch:::shimou:yang", "tymou_switch:::shimou:yin" },
      skill_name = shimou.name,
      prompt = "#tymou_switch-choice:::shimou",
    })
    choice = choice:endsWith("yang") and fk.SwitchYang or fk.SwitchYin
    U.SetSwitchSkillState(player, shimou.name, choice)
  end,
})

return shimou
