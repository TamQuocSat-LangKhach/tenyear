local yingmou = fk.CreateSkill {
  name = "yingmou",
  tags = { Skill.Switch },
}

Fk:loadTranslationTable{
  ["yingmou"] = "英谋",
  [":yingmou"] = "转换技，游戏开始时可自选阴阳状态。每回合限一次，当你对其他角色使用牌结算后，你可以选择其中一名目标角色，"..
  "阳：你将手牌摸至与其相同（至多摸五张），然后视为对其使用一张【火攻】；阴：令一名手牌最多的角色对其使用手牌中所有【杀】和伤害锦囊牌，"..
  "若没有则将手牌弃至与你相同。",

  ["#yingmou_yang-invoke"] = "英谋：选择一名角色，你将手牌补至与其相同，然后视为对其使用【火攻】",
  ["#yingmou_yin-invoke"] = "英谋：选择一名角色，然后令手牌最多的角色对其使用手牌中所有【杀】和伤害锦囊牌",
  ["#yingmou-choose"] = "英谋：选择手牌数最多的一名角色，其对 %dest 使用手牌中所有【杀】和伤害锦囊牌",

  ["#tymou_switch-choice"] = "%arg：选择阴阳状态",
  ["tymou_switch"] = "%arg（%arg2）",

  ["$yingmou1"] = "行计以险，纵略以奇，敌虽百万亦戏之如犬豕。",
  ["$yingmou2"] = "若生铸剑为犁之心，须有纵钺止戈之力。",
}

local U = require "packages/utility/utility"

yingmou:addEffect(fk.CardUseFinished, {
  anim_type = "switch",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yingmou.name) and data.tos and
      table.find(data.tos, function(p)
        return p ~= player and not p.dead
      end) and
      player:usedEffectTimes(yingmou.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = data.tos,
      min_num = 1,
      max_num = 1,
      skill_name = yingmou.name,
      cancelable = true,
      prompt = "#yingmou_"..player:getSwitchSkillState(yingmou.name, false, true).."-invoke",
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    U.SetSwitchSkillState(player, yingmou.name, player:getSwitchSkillState(yingmou.name, false))
    local to = event:getCostData(self).tos[1]
    if player:getSwitchSkillState(yingmou.name, true) == fk.SwitchYang then
      if player:getHandcardNum() < to:getHandcardNum() then
        player:drawCards(math.min(to:getHandcardNum() - player:getHandcardNum(), 5), yingmou.name)
      end
      if not player.dead and not to.dead and not to:isKongcheng() then
        room:useVirtualCard("fire_attack", nil, player, to, yingmou.name)
      end
    elseif player:getSwitchSkillState(yingmou.name, true) == fk.SwitchYin then
      local targets = table.filter(room.alive_players, function(p)
        return table.every(room.alive_players, function(p2)
          return p:getHandcardNum() >= p2:getHandcardNum()
        end)
      end)
      if targets[1]:isKongcheng() then return end
      local src
      if #targets == 1 then
        src = targets[1]
      else
        src = room:askToChoosePlayers(player, {
          targets = targets,
          min_num = 1,
          max_num = 1,
          skill_name = yingmou.name,
          cancelable = false,
          no_indicate = true,
          prompt = "#yingmou-choose::"..to.id,
        })[1]
      end
      local cards = table.filter(src:getCardIds("h"), function(id)
        return Fk:getCardById(id).is_damage_card
      end)
      if #cards > 0 then
        cards = table.reverse(cards)
        for i = #cards, 1, -1 do
          if src.dead or to.dead or to:isKongcheng() then
            break
          end
          if table.contains(src:getCardIds("h"), cards[i]) then
            local card = Fk:getCardById(cards[i])
            if src:canUseTo(card, to, { bypass_distances = true, bypass_times = true}) then
              room:useCard({
                from = src,
                tos = {to},
                card = card,
                extraUse = true,
              })
            end
          end
        end
      else
        local n = src:getHandcardNum() - player:getHandcardNum()
        if n > 0 then
          room:askToDiscard(src, {
            min_num = n,
            max_num = n,
            include_equip = false,
            skill_name = yingmou.name,
            cancelable = false
          })
        end
      end
    end
  end,
})

yingmou:addEffect(fk.GameStart, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yingmou.name, true)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = { "tymou_switch:::yingmou:yang", "tymou_switch:::yingmou:yin" },
      skill_name = yingmou.name,
      prompt = "#tymou_switch-choice:::yingmou",
    })
    choice = choice:endsWith("yang") and fk.SwitchYang or fk.SwitchYin
    U.SetSwitchSkillState(player, yingmou.name, choice)
  end,
})

return yingmou
