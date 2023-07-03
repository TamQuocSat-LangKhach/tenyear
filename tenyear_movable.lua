local extension = Package("tenyear_movable")
extension.extensionName = "tenyear"

Fk:loadTranslationTable{
  ["tenyear_movable"] = "十周年活动",
}
local longwang = General(extension, "longwang", "god", 3)
local ty__longgong = fk.CreateTriggerSkill{
  name = "ty__longgong",
  anim_type = "negative",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
     return target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and data.from ~= nil
  end,
  on_cost = function(self, event, target, player, data)
      return player.room:askForSkillInvoke(player, self.name, nil, "#longgong-invoke::"..data.from.id)
  end,
  on_use = function(self, event, target, player, data)
        local room = player.room
    local cards = {}
    repeat
      local id = table.random(room.draw_pile)
      if Fk:getCardById(id).type == Card.TypeEquip then
        if #cards == 0 then
          table.insertIfNeed(cards, id)
        end
      end
    until #cards == 1
    room:moveCards({
            ids = cards,
            to = data.from.id,
            toArea = Card.PlayerHand,
            moveReason = fk.ReasonJustMove,
            proposer = data.from.id,
            skillName = self.name,
    })
    return true 
  end,
}
local ty__sitian = fk.CreateActiveSkill{
  name = "ty__sitian",
  anim_type = "support",
  card_num = 2,
  target_num = 0,
  can_use = function(self, player)
    return not player:isNude()
  end,
  card_filter = function(self, to_select, selected)
    if #selected == 1 then 
      return Fk:currentRoom():getCardArea(to_select) ~= Player.Equip and Fk:getCardById(to_select).suit ~= Fk:getCardById(selected[1]).suit
    elseif #selected == 2 then
      return false
    end
    return Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
        local choices = {"sitian1", "sitian2", "sitian3", "sitian4", "sitian5"}
    for i = 1, 3, 1 do
      table.removeOne(choices, table.random(choices))
    end
     local choice = room:askForChoice(player, choices, self.name)
     local targets = room:getOtherPlayers(player, true) 
    if choice == "sitian1" then 
      table.forEach(targets, function(p)
         if not p.dead then room:damage{ from = player, to = p, damage = 1, damageType = fk.FireDamage, skillName = self.name } end
      end)
    end
    if choice == "sitian2" then
       table.forEach(targets, function(p)
          if not p.dead then
            local judge = {
              who = p,
              reason = "lightning",
              pattern = ".|2~9|spade",
            }
             room:judge(judge)
              local result = judge.card
             if result.suit == Card.Spade and result.number >= 2 and result.number <= 9 then
               room:damage{
                 to = p,
                 damage = 3,
                 card = effect.card,
                 damageType = fk.ThunderDamage,
                  skillName = self.name,
               }
             end
          end
       end)
    end
    if choice == "sitian3" then
       table.forEach(targets, function(p)
          if not p.dead and #p.player_cards[Player.Equip] > 0 then
             p:throwAllCards("e") 
          else
             room:loseHp(p, 1, self.name)
          end
       end)
    end
    if choice == "sitian4" then
       local tos = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p) return p.id end), 1, 1, "#sitian-choose", self.name, true)
      local to
      if #tos > 0 then
        to = room:getPlayerById(tos[1])
        if not to:isKongcheng() then
           to:throwAllCards("h") 
        else
           room:loseHp(to, 1, self.name)
        end
      end
    end
    if choice == "sitian5" then
       table.forEach(targets, function(p)
          if not p.dead then
             room:setPlayerMark(p, "@lw_dawu", 1)
          end
       end)
    end
  end,
}
local sitian__dawu = fk.CreateTriggerSkill{
  name = "#sitian__dawu",
  anim_type = "defensive",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and data.card.type == Card.TypeBasic and data.card.name ~= "nullification" then
      if target:getMark("@lw_dawu") >0 then 
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(target, "@lw_dawu", 0)
    data.tos ={}
    return true
  end,
}
ty__sitian:addRelatedSkill(sitian__dawu)
longwang:addSkill(ty__longgong)
longwang:addSkill(ty__sitian)
Fk:loadTranslationTable{
  ["longwang"] = "敖广",
  ["ty__longgong"] = "龙宫",
  [":ty__longgong"] = "每回合限一次，当你受到伤害时，你可以防止此伤害，改为令伤害来源随机获得牌堆中的一张装备牌。",
  ["ty__sitian"] = "司天",
  [":ty__sitian"] = "出牌阶段，你可以弃置两张不同花色的手牌，然后改变天气（从两个选项中选择一项），烈日：对其他角色各造成1点火焰伤害；雷电：令其他角色各进行一次闪电判定；大浪：弃置其他角色装备区所有牌（没装备的需要失去1点体力）；暴雨：弃置一名角色所有手牌（没手牌的需要失去1点体力）；大雾：其他角色使用的下张基本牌无效。",
  ["#longgong-invoke"] = "龙宫：是否令%dest 随机获得牌堆中的一张装备牌，然后防止此伤害。",
  ["#sitian-choose"] = "暴雨：令一名角色弃置所有手牌，若其没有手牌则改为失去一点体力。",
  ["@lw_dawu"] = "大雾",
  ["sitian1"] = "烈日",
  ["sitian2"] = "雷电",
  ["sitian3"] = "大浪",
  ["sitian4"] = "暴雨",
  ["sitian5"] = "大雾",
  
  ["$ty__longgong1"] = "停手，大哥!给东西能换条命不?",
  ["$ty__longgong2"] = "冤家宜解不宜结",
  ["$ty__longgong3"] = "莫要伤了和气",
  ["$ty__sitian1"] = "观众朋友大家好，欢迎收看天气预报！",
  ["$ty__sitian2"] = "这一喷嚏，不知要掀起多少狂风暴雨。",
  ["~longwang"] = "三年之期已到，哥们要回家啦…",
}

return extension
