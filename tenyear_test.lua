local extension = Package("tenyear_test")
extension.extensionName = "tenyear"

Fk:loadTranslationTable{
  ["tenyear_test"] = "十周年-测试服",
}

--嵇康 曹不兴

local sunhuan = General(extension, "sunhuan", "wu", 4)
local niji = fk.CreateTriggerSkill{
  name = "niji",
  anim_type = "drawcard",
  events = {fk.TargetConfirmed, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if event == fk.TargetConfirmed then
      return target == player and player:hasSkill(self.name) and data.firstTarget and data.card.type ~= Card.TypeEquip
    elseif event == fk.EventPhaseStart then
      return target.phase == Player.Finish and not player:isKongcheng() and
        table.find(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id):getMark("@@niji-inhand") > 0 end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.TargetConfirmed then
      return player.room:askForSkillInvoke(player, self.name, nil, "#niji-invoke")
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetConfirmed then
      local id = player:drawCards(1, self.name)[1]
      if room:getCardOwner(id) == player and room:getCardArea(id) == Card.PlayerHand then
        room:setCardMark(Fk:getCardById(id), "@@niji-inhand", 1)
      end
    else
      local cards = table.filter(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id):getMark("@@niji-inhand") > 0 end)
      if player:hasSkill(self.name) and #cards >= player.hp then
        local pattern = "^(jink,nullification)|.|.|.|.|.|"..table.concat(cards, ",")
        local use = room:askForUseCard(player, "", pattern, "#niji-use", true)
        if use then
          room:useCard(use)
        end
      end
      if not player.dead then
        cards = table.filter(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id):getMark("@@niji-inhand") > 0 end)
        room:throwCard(cards, self.name, player, player)
      end
    end
  end,

  refresh_events = {fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return not player:isKongcheng()
  end,
  on_refresh = function(self, event, target, player, data)
    for _, id in ipairs(player.player_cards[Player.Hand]) do
      player.room:setCardMark(Fk:getCardById(id), "@@niji-inhand", 0)
    end
  end,
}
sunhuan:addSkill(niji)
Fk:loadTranslationTable{
  ["sunhuan"] = "孙桓",
  ["niji"] = "逆击",
  [":niji"] = "当你成为非装备牌的目标后，你可以摸一张牌，本回合结束阶段弃置这些牌。若将要弃置的牌数不小于你的体力值，你可以先使用其中一张牌。",
  ["@@niji-inhand"] = "逆击",
  ["#niji-invoke"] = "逆击：你可以摸一张牌，本回合结束阶段弃置之",
  ["#niji-use"] = "逆击：即将弃置所有“逆击”牌，你可以先使用其中一张牌",
}

local peiyuanshao = General(extension, "peiyuanshao", "qun", 4)
local moyu = fk.CreateActiveSkill{
  name = "moyu",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:getMark("@@moyu-turn") == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and target ~= Self and target:getMark("moyu-turn") == 0 and not target:isAllNude()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local id = room:askForCardChosen(player, target, "hej", self.name)
    room:obtainCard(player.id, id, false, fk.ReasonPrey)
    if target.dead then return end
    room:setPlayerMark(target, "moyu-turn", 1)
    local use = room:askForUseCard(target, "slash", "slash", "#moyu-slash::"..player.id..":"..player:usedSkillTimes(self.name), true,
      {must_targets = {player.id}, bypass_times = true})
    if use then
      use.additionalDamage = (use.additionalDamage or 0) + player:usedSkillTimes(self.name) - 1
      room:useCard(use)
      if not player.dead and use.damageDealt and use.damageDealt[player.id] then
        room:setPlayerMark(player, "@@moyu-turn", 1)
      end
    end
  end,
}
peiyuanshao:addSkill(moyu)
Fk:loadTranslationTable{
  ["peiyuanshao"] = "裴元绍",
  ["moyu"] = "没欲",
  [":moyu"] = "出牌阶段每名角色限一次，你可以获得一名其他角色区域内的一张牌，然后该角色可以对你使用一张伤害值为X的【杀】"..
  "（X为本回合本技能发动次数），若此【杀】对你造成了伤害，本技能于本回合失效。",
  ["#moyu-slash"] = "没欲：你可以对 %dest 使用一张【杀】，伤害基数为%arg",
  ["@@moyu-turn"] = "没欲失效",
}

local dongwan = General(extension, "dongwan", "qun", 3, 3, General.Female)
local shengdu = fk.CreateTriggerSkill{
  name = "shengdu",
  anim_type = "drawcard",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.from == Player.RoundStart
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local p = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p)
      return p.id end), 1, 1, "#shengdu-choose", self.name, true)
    if #p > 0 then
      self.cost_data = p[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player.room:getPlayerById(self.cost_data), self.name, 1)
  end,

  refresh_events = {fk.AfterDrawNCards},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target:getMark(self.name) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local n = target:getMark(self.name)
    player.room:setPlayerMark(target, self.name, 0)
    for i = 1, n, 1 do
      player:drawCards(data.n, self.name)  --yes! do n times!
    end
  end,
}
local jieling = fk.CreateActiveSkill{
  name = "jieling",
  anim_type = "offensive",
  card_num = 2,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    if Fk:currentRoom():getCardArea(to_select) ~= Player.Equip then
      if #selected == 0 then
        return true
      elseif #selected == 1 then
        return Fk:getCardById(to_select).color ~= Fk:getCardById(selected[1]).color
      else
        return false
      end
    end
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and not Self:isProhibited(Fk:currentRoom():getPlayerById(to_select), Fk:cloneCard("slash"))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:useVirtualCard("slash", effect.cards, player, target, self.name, true)
  end,
}
local jieling_record = fk.CreateTriggerSkill{
  name = "#jieling_record",

  refresh_events = {fk.Damage, fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card and table.contains(data.card.skillNames, "jieling")
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.Damage then
      data.card.extra_data = data.card.extra_data or {}
      table.insert(data.card.extra_data, "jieling")
    else
      local room = player.room
      for _, p in ipairs(TargetGroup:getRealTargets(data.tos)) do
        local to = room:getPlayerById(p)
        if data.card.extra_data and table.contains(data.card.extra_data, "jieling") then
          room:loseHp(to, 1, self.name)
        else
          room:addPlayerMark(to, "shengdu", 1)
        end
      end
    end
  end,
}
jieling:addRelatedSkill(jieling_record)
dongwan:addSkill(shengdu)
dongwan:addSkill(jieling)
Fk:loadTranslationTable{
  ["dongwan"] = "董绾",
  ["shengdu"] = "生妒",
  [":shengdu"] = "回合开始时，你可以选择一名其他角色，该角色下个摸牌阶段摸牌后，你摸等量的牌。",
  ["jieling"] = "介绫",
  [":jieling"] = "出牌阶段限一次，你可以将两张颜色不同的手牌当无距离和次数限制的【杀】使用。"..
  "若此【杀】：造成伤害，则目标角色失去1点体力；没造成伤害，则你对目标角色发动一次〖生妒〗。",
  ["#shengdu-choose"] = "生妒：选择一名角色，其下次摸牌阶段摸牌后，你摸等量的牌",
}

--袁胤 高翔

--孙綝 孙瑜 郤正 乐綝
Fk:loadTranslationTable{
  ["sunchen"] = "孙綝",
  ["zigu"] = "自固",
  [":zigu"] = "出牌阶段限一次，你可以弃置一张牌，然后获得场上一张装备牌。若你没有因此获得其他角色的牌，你摸一张牌。",
  ["zuowei"] = "作威",
  [":zuowei"] = "当你于回合内使用牌时，若你当前手牌数：大于X，你可以令此牌不可响应；等于X，你可以对一名其他角色造成1点伤害；小于X，"..
  "你可以摸两张牌并令本回合此技能失效。（X为你装备区内的牌数且至少为1）",
}

Fk:loadTranslationTable{
  ["sunyu"] = "孙瑜",
  ["quanshou"] = "劝守",
  [":quanshou"] = "一名角色回合开始时，若其手牌数小于其体力上限，你可以令其选择一项：1.将手牌摸至体力上限（至多摸五张），然后"..
  "本回合出牌阶段使用【杀】次数上限-1；2.本回合使用的牌被抵消后你摸一张牌。",
  ["shexue"] = "设学",
  [":shexue"] = "出牌阶段开始时，你可以将一张牌当上回合的角色出牌阶段使用的最后一张基本牌或普通锦囊牌使用；"..
  "出牌阶段结束时，你可以令下回合的角色于其出牌阶段开始时可以将一张牌当你本阶段使用的最后一张基本牌或普通锦囊牌使用。",
}

local xizheng = General(extension, "xizheng", "shu", 3)
local danyi = fk.CreateTriggerSkill{
  name = "danyi",
  anim_type = "drawcard",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and data.firstTarget then
      local room = player.room
      local events = room.logic.event_recorder[GameEvent.UseCard]
      if #events < 2 then return end
      for i = #events - 1, 1, -1 do
        local use = events[i].data[1]
        if use.from == player.id then
          if use.tos then
            if #TargetGroup:getRealTargets(use.tos) ~= #TargetGroup:getRealTargets(data.tos) then return false end
            for _, id in ipairs(TargetGroup:getRealTargets(use.tos)) do
              if not table.contains(TargetGroup:getRealTargets(data.tos), id) then
                return false
              end
            end
            for _, id in ipairs(TargetGroup:getRealTargets(data.tos)) do
              if not table.contains(TargetGroup:getRealTargets(use.tos), id) then
                return false
              end
            end
            return true
          else
            return false
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(#TargetGroup:getRealTargets(data.tos), self.name)
  end,
}
local wencan = fk.CreateActiveSkill{
  name = "wencan",
  anim_type = "control",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 2,
  prompt = "#wencan",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    if #selected > 1 or to_select == Self.id then return false end
    local target = Fk:currentRoom():getPlayerById(to_select)
    if #selected == 0 then
      return target.hp ~= Self.hp
    elseif #selected == 1 then
      return target.hp ~= Self.hp and target.hp ~= Fk:currentRoom():getPlayerById(selected[1]).hp
    else
      return false
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    for _, id in ipairs(effect.tos) do
      local p = room:getPlayerById(id)
      if not p.dead then
        if #p:getCardIds("he") < 2 or not room:askForUseActiveSkill(p, "wencan_active", "#wencan-discard:"..player.id, true) then
          room:setPlayerMark(p, "@@wencan-turn", 1)
        end
      end
    end
  end,
}
local wencan_active = fk.CreateActiveSkill{
  name = "wencan_active",
  mute = true,
  card_num = 2,
  target_num = 0,
  card_filter = function(self, to_select, selected)
    local card = Fk:getCardById(to_select)
    if not Self:prohibitDiscard(card) and card.suit ~= Card.NoSuit then
      if #selected == 0 then
        return true
      elseif #selected == 1 then
        return card.suit ~= Fk:getCardById(selected[1]).suit
      else
        return false
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, "wencan", player, player)
  end,
}
local wencan_targetmod = fk.CreateTargetModSkill{
  name = "#wencan_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return player:usedSkillTimes("wencan", Player.HistoryTurn) > 0 and scope == Player.HistoryPhase and to:getMark("@@wencan-turn") > 0
  end,
}
Fk:addSkill(wencan_active)
wencan:addRelatedSkill(wencan_targetmod)
xizheng:addSkill(danyi)
xizheng:addSkill(wencan)
Fk:loadTranslationTable{
  ["xizheng"] = "郤正",
  ["danyi"] = "耽意",
  [":danyi"] = "你使用牌指定目标后，若此牌目标与你使用的上一张牌完全相同，你可以摸X张牌（X为此牌目标数）。",
  ["wencan"] = "文灿",
  [":wencan"] = "出牌阶段限一次，你可以选择至多两名体力值不同且均与你不同的角色，这些角色依次选择一项：1.弃置两张花色不同的牌；"..
  "2.本回合你对其使用牌无次数限制。",
  ["#wencan"] = "文灿：选择至多两名体力值不同且均与你不同的角色，其弃牌或你对其使用牌无次数限制",
  ["@@wencan-turn"] = "文灿",
  ["wencan_active"] = "文灿",
  ["#wencan-discard"] = "文灿：弃置两张不同花色的牌，否则 %src 本回合对你使用牌无次数限制",
}

Fk:loadTranslationTable{
  ["yuechen"] = "乐綝",
  ["porui"] = "破锐",
  [":porui"] = "每轮限一次，其他角色的结束阶段，你可以弃置一张基本牌并选择一名此回合内失去过牌的另一名其他角色，你视为对该角色依次使用X+1张【杀】，"..
  "然后你交给其X张手牌（X为你的体力值，不足则全给）。",
  ["gonghu"] = "共护",
  [":gonghu"] = "锁定技，当你于回合外失去基本牌后，〖破锐〗最后增加描述“若其没有因此受到伤害，你回复1点体力”；当你于回合外造成或受到伤害后，"..
  "你删除〖破锐〗中交给牌的效果。若以上两个效果均已触发，则你本局游戏使用红色基本牌无法响应，使用红色普通锦囊牌可以额外指定一个目标。",
}

local zhangmancheng = General(extension, "ty__zhangmancheng", "qun", 4)
local lvecheng = fk.CreateActiveSkill{
  name = "lvecheng",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(target, "@@lvecheng-turn", player.id)
  end,
}
local lvecheng_targetmod = fk.CreateTargetModSkill{
  name = "#lvecheng_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return to:getMark("@@lvecheng-turn") ~= 0 and to:getMark("@@lvecheng-turn") == player.id and
      card.trueName == "slash" and scope == Player.HistoryPhase
  end,
}
local lvecheng_trigger = fk.CreateTriggerSkill{
  name = "#lvecheng_trigger",
  mute = true,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@@lvecheng-turn") ~= 0 and player:getMark("@@lvecheng-turn") == target.id and
      target.phase == Player.Finish and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastSkillInvoke("lvecheng")
    room:notifySkillInvoked(target, "lvecheng", "negative")
    room:doIndicate(player.id, {target.id})
    player:showCards(player.player_cards[Player.Hand])
    while table.find(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id).trueName == "slash" end)
      and not player.dead and not target.dead do
      local use = room:askForUseCard(player, "slash", "slash|.|.|hand", "#lvecheng-slash::"..target.id, true,
        {must_targets = {target.id}, bypass_distances = true, bypass_times = true})
      if use then
        room:useCard(use)
      else
        break
      end
    end
  end,
}
local zhongji = fk.CreateTriggerSkill{
  name = "zhongji",
  anim_type = "drawcard",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player:getHandcardNum() < player.maxHp then
      return player:isKongcheng() or
        not table.find(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id).suit == data.card.suit end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil,
      "#zhongji-invoke:::"..(player.maxHp - player:getHandcardNum())..":"..player:usedSkillTimes(self.name, Player.HistoryTurn))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(player.maxHp - player:getHandcardNum(), self.name)
    local n = player:usedSkillTimes(self.name, Player.HistoryTurn) - 1
    if n == 0 then return end
    if #player:getCardIds{Player.Hand, Player.Equip} <= n then
      player:throwAllCards("he")
    else
      room:askForDiscard(player, n, n, true, self.name, false)
    end
  end,
}
lvecheng:addRelatedSkill(lvecheng_targetmod)
lvecheng:addRelatedSkill(lvecheng_trigger)
zhangmancheng:addSkill(lvecheng)
zhangmancheng:addSkill(zhongji)
Fk:loadTranslationTable{
  ["ty__zhangmancheng"] = "张曼成",
  ["lvecheng"] = "掠城",
  [":lvecheng"] = "出牌阶段限一次，你可以指定一名其他角色，本回合你对其使用【杀】无次数限制。若如此做，此回合结束阶段，其展示手牌：若其中有【杀】，"..
  "其可以依次对你使用手牌中所有的【杀】。",
  ["zhongji"] = "螽集",
  [":zhongji"] = "当你使用牌时，若你没有该花色的手牌，你可将手牌摸至体力上限并弃置X张牌（X为本回合发动此技能的次数）。",
  ["@@lvecheng-turn"] = "掠城",
  ["#lvecheng-slash"] = "掠城：你可以依次对 %dest 使用手牌中所有【杀】！",
  ["#zhongji-invoke"] = "螽集：你可以摸%arg张牌，然后弃置%arg2张牌",
}

-- 城孙权

local wuban = General(extension, "ty__wuban", "shu", 4)
local youzhan = fk.CreateTriggerSkill{
  name = "youzhan",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player.phase ~= Player.NotActive then
      for _, move in ipairs(data) do
        if move.from and move.from ~= player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if move.from and move.from ~= player.id then
        local yes = false
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            yes = true
          end
        end
        if yes then
          room:broadcastSkillInvoke(self.name)
          room:notifySkillInvoked(player, self.name, "drawcard")
          player:drawCards(1, self.name)
          local to = room:getPlayerById(move.from)
          if not to.dead then
            room:addPlayerMark(to, "@youzhan-turn", 1)
            room:addPlayerMark(to, "youzhan-turn", 1)
          end
        end
      end
    end
  end,

  refresh_events = {fk.Damaged},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("youzhan-turn") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "youzhan_fail-turn", 1)
  end,
}
local youzhan_trigger = fk.CreateTriggerSkill{
  name = "#youzhan_trigger",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:getMark("youzhan-turn") > 0 then
      if event == fk.DamageInflicted then
        return target == player and player:getMark("@youzhan-turn") > 0
      else
        return target.phase == Player.Finish and player:getMark("youzhan_fail-turn") == 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastSkillInvoke("youzhan")
    if event == fk.DamageInflicted then
      if room.current then
        room:notifySkillInvoked(room.current, "youzhan", "offensive")
        room:doIndicate(room.current.id, {player.id})
      end
      data.damage = data.damage + player:getMark("@youzhan-turn")
      room:setPlayerMark(player, "@youzhan-turn", 0)
    else
      room:notifySkillInvoked(target, "youzhan", "drawcard")
      room:doIndicate(target.id, {player.id})
      player:drawCards(player:getMark("youzhan-turn"), "youzhan")
    end
  end,
}
youzhan:addRelatedSkill(youzhan_trigger)
wuban:addSkill(youzhan)
Fk:loadTranslationTable{
  ["ty__wuban"] = "吴班",
  ["youzhan"] = "诱战",
  [":youzhan"] = "锁定技，其他角色在你的回合失去牌后，你摸一张牌，其本回合下次受到的伤害+1。结束阶段，若这些角色本回合未受到过伤害，其摸X张牌"..
  "（X为其本回合失去牌的次数）。",
  ["@youzhan-turn"] = "诱战",
}

local wangjun = General(extension, "ty__wangjun", "qun", 4)
wangjun.subkingdom = "jin"
local mianyao = fk.CreateTriggerSkill{
  name = "mianyao",
  anim_type = "drawcard",
  events = {fk.EventPhaseEnd, fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.EventPhaseEnd then
        return player:hasSkill(self.name) and player.phase == player.Draw and not player:isKongcheng()
      else
        return player:getMark("mianyao-turn") > 0 and data.to == Player.NotActive
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseEnd then
      local room = player.room
      local ids = table.filter(player:getCardIds("h"), function(id)
        return table.every(player:getCardIds("h"), function(id2)
          return Fk:getCardById(id).number <= Fk:getCardById(id2).number end) end)
      local cards = room:askForCard(player, 1, 1, false, self.name, true, ".|.|.|.|.|.|"..table.concat(ids, ","), "#mianyao-invoke")
      if #cards > 0 then
        self.cost_data = cards
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.EventPhaseEnd then
      local room = player.room
      player:showCards(self.cost_data)
      if player.dead then return end
      room:setPlayerMark(player, "mianyao-turn", Fk:getCardById(self.cost_data[1]).number)
      room:moveCards({
        ids = self.cost_data,
        from = player.id,
        fromArea = Player.Hand,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
        drawPilePosition = math.random(1, #room.draw_pile),
      })
    else
      player:drawCards(player:getMark("mianyao-turn"), self.name)
    end
  end,
}
local changqu = fk.CreateActiveSkill{
  name = "changqu",
  anim_type = "control",
  card_num = 0,
  min_target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    if to_select == Self.id then return false end
    local target = Fk:currentRoom():getPlayerById(to_select)
    if #selected == 0 then
      return target:getNextAlive() == Self or Self:getNextAlive() == target
    else
      if table.contains(selected, Self:getNextAlive().id) then
        if Fk:currentRoom():getPlayerById(selected[#selected]):getNextAlive() == target then
          return true
        end
      end
      if Fk:currentRoom():getPlayerById(selected[1]):getNextAlive() == Self then
        if target:getNextAlive().id == selected[#selected] then
          return true
        end
      end
    end
  end,
  feasible = function(self, selected, selected_cards)
    if #selected > 0 then
      local p1 = Fk:currentRoom():getPlayerById(selected[1])
      if not (p1:getNextAlive() == Self or Self:getNextAlive() == p1) then return false end
      if #selected == 1 then return true end
      if p1:getNextAlive() == Self then
        for i = 1, #selected - 1, 1 do
          if Fk:currentRoom():getPlayerById(selected[i+1]):getNextAlive() ~= Fk:currentRoom():getPlayerById(selected[i]) then
            return false
          end
        end
        return true
      end
      if Self:getNextAlive() == p1 then
        for i = 1, #selected - 1, 1 do
          if Fk:currentRoom():getPlayerById(selected[i]):getNextAlive() ~= Fk:currentRoom():getPlayerById(selected[i+1]) then
            return false
          end
        end
        return true
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local n = 0
    for _, id in ipairs(effect.tos) do
      local target = room:getPlayerById(id)
      if not target.dead then
        room:setPlayerMark(target, "@@battleship", 1)
        local cards = {}
        local x = math.max(n, 1)
        if target:getHandcardNum() >= x then
          cards = room:askForCard(target, x, x, false, self.name, true, ".", "#changqu-card:"..player.id.."::"..x)
        end
        if #cards > 0 then
          local dummy = Fk:cloneCard("dilu")
          dummy:addSubcards(cards)
          room:obtainCard(player, dummy, false, fk.ReasonGive)
          n = n + 1
        else
          room:doIndicate(player.id, {target.id})
          if not target.chained then
            target:setChainState(true)
          end
          room:setPlayerMark(target, "@changqu", x)
          room:setPlayerMark(target, "@@battleship", 0)
          break
        end
        room:setPlayerMark(target, "@@battleship", 0)
      end
      if player.dead then return end
    end
  end,
}
local changqu_trigger = fk.CreateTriggerSkill{
  name = "#changqu_trigger",
  mute = true,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@changqu") > 0 and data.damageType ~= fk.NormalDamage
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + player:getMark("@changqu")
    player.room:setPlayerMark(player, "@changqu", 0)
  end,
}
changqu:addRelatedSkill(changqu_trigger)
wangjun:addSkill(mianyao)
wangjun:addSkill(changqu)
Fk:loadTranslationTable{
  ["ty__wangjun"] = "王濬",
  ["mianyao"] = "免徭",
  [":mianyao"] = "摸牌阶段结束时，你可以展示手牌中点数最小的一张牌并将之置于牌堆随机位置，若如此做，本回合结束时，你摸此牌点数张牌。",
  ["changqu"] = "长驱",
  [":changqu"] = "出牌阶段限一次，你可以<font color='red'>开一艘战舰</font>，从你的上家或下家开始选择任意名座次连续的其他角色，第一个目标角色获得战舰标记。"..
  "获得战舰标记的角色选择一项：1.交给你X张手牌，然后将战舰标记移动至下一个目标；2.下次受到的属性伤害+X，然后横置武将牌（X为本次选择1的次数，至少为1）。",
  ["#mianyao-invoke"] = "免徭：你可以将点数最小的手牌洗入牌堆，回合结束时摸其点数的牌",
  ["@@battleship"] = "战舰",
  ["#changqu-card"] = "长驱：交给 %src %arg张手牌以使战舰驶向下一名角色",
  ["@changqu"] = "长驱",
}

local dongxie = General(extension, "dongxie", "qun", 4, 4, General.Female)
local jiaoxia = fk.CreateTriggerSkill{
  name = "jiaoxia",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == player.Play
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#jiaoxia-invoke")
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@jiaoxia-phase", 1)
  end,

  refresh_events = {fk.AfterCardTargetDeclared},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.trueName == "slash"
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local yes = false
    for _, id in ipairs(TargetGroup:getRealTargets(data.tos)) do
      local p = room:getPlayerById(id)
      if p:getMark("jiaoxia-phase") == 0 then
        room:setPlayerMark(p, "jiaoxia-phase", 1)
        yes = true
      end
    end
    if yes then
      player:addCardUseHistory(data.card.trueName, -1)
    end
  end,
}
local jiaoxia_filter = fk.CreateFilterSkill{
  name = "#jiaoxia_filter",
  anim_type = "offensive",
  card_filter = function(self, card, player)
    return player:getMark("@@jiaoxia-phase") > 0 and not table.contains(player:getCardIds("ej"), card.id)
  end,
  view_as = function(self, card)
    local c = Fk:cloneCard("slash", card.suit, card.number)
    c.skillName = "jiaoxia"
    return c
  end,
}
local jiaoxia_trigger = fk.CreateTriggerSkill{
  name = "#jiaoxia_trigger",
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if target == player and table.contains(data.card.skillNames, "jiaoxia") and not player.dead then
      local c = Fk:getCardById(data.card:getEffectiveId())
      local card = Fk:cloneCard(c.name)
      return (card.type == Card.TypeBasic or card:isCommonTrick()) and not player:prohibitUse(card) and card.skill:canUse(player, card)
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local name = Fk:getCardById(data.card:getEffectiveId()).name
    room:setPlayerMark(player, "jiaoxia-tmp", name)
    local success, dat = room:askForUseActiveSkill(player, "jiaoxia_viewas", "#jiaoxia-use:::"..name, true)
    room:setPlayerMark(player, "jiaoxia-tmp", 0)
    if success then
      local card = Fk:cloneCard(name)
      room:useCard{
        from = player.id,
        tos = table.map(dat.targets, function(id) return {id} end),
        card = card,
        skillName = "jiaoxia_viewas",
        extraUse = true,
      }
    end
  end,
}
local jiaoxia_viewas = fk.CreateViewAsSkill{
  name = "jiaoxia_viewas",
  card_filter = function(self, to_select, selected)
    return false
  end,
  view_as = function(self, cards)
    if Self:getMark("jiaoxia-tmp") == 0 then return end
    local card = Fk:cloneCard(Self:getMark("jiaoxia-tmp"))
    card.skillName = self.name
    return card
  end,
}
local jiaoxia_targetmod = fk.CreateTargetModSkill{
  name = "#jiaoxia_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return card and scope == Player.HistoryPhase and table.contains(card.skillNames, "jiaoxia_viewas")
  end,
}
local humei = fk.CreateActiveSkill{
  name = "humei",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = function(self)
    return "#humei:::"..Self:getMark("humei-phase")
  end,
  interaction = function(self)
    local choices = {}
    for i = 1, 3, 1 do
      if Self:getMark("humei"..i.."-phase") == 0 then
        table.insert(choices, "humei"..i.."-phase")
      end
    end
    return UI.ComboBox { choices = choices }
  end,
  can_use = function(self, player)
    for i = 1, 3, 1 do
      if player:getMark("humei"..i.."-phase") == 0 then
        return true
      end
    end
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    local target = Fk:currentRoom():getPlayerById(to_select)
    if #selected == 0 and target.hp <= Self:getMark("humei-phase") then
      if self.interaction.data == "humei1-phase" then
        return true
      elseif self.interaction.data == "humei2-phase" then
        return not target:isNude()
      elseif self.interaction.data == "humei3-phase" then
        return target:isWounded()
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(player, self.interaction.data, 1)
    if self.interaction.data == "humei1-phase" then
      target:drawCards(1, self.name)
    elseif self.interaction.data == "humei2-phase" then
      local card = room:askForCard(target, 1, 1, true, self.name, false, ".", "#humei-give:"..player.id)
      room:obtainCard(player, card[1], false, fk.ReasonGive)
    elseif self.interaction.data == "humei3-phase" then
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name
      }
    end
  end,
}
local humei_record = fk.CreateTriggerSkill{
  name = "#humei_record",

  refresh_events = {fk.Damage, fk.EventAcquireSkill},
  can_refresh = function(self, event, target, player, data)
    if target == player and player.phase == Player.Play then
      if event == fk.Damage then
        return true
      else
        return data.name == "humei"
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damage then
      room:addPlayerMark(player, "humei-phase", 1)
    else
      local events = room.logic:getEventsOfScope(GameEvent.ChangeHp, 999, function(e)
        local damage = e.data[5]
        if damage and player == damage.from then
          room:addPlayerMark(player, "humei-phase", 1)
        end
      end, Player.HistoryPhase)
    end
  end,
}
Fk:addSkill(jiaoxia_viewas)
jiaoxia:addRelatedSkill(jiaoxia_filter)
jiaoxia:addRelatedSkill(jiaoxia_targetmod)
jiaoxia:addRelatedSkill(jiaoxia_trigger)
humei:addRelatedSkill(humei_record)
dongxie:addSkill(jiaoxia)
dongxie:addSkill(humei)
Fk:loadTranslationTable{
  ["dongxie"] = "董翓",
  ["jiaoxia"] = "狡黠",
  [":jiaoxia"] = "出牌阶段开始时，你可以令本阶段你的手牌均视为【杀】。若你以此法使用的【杀】造成了伤害，此【杀】结算后你视为使用原牌名的牌。"..
  "出牌阶段，你对每名角色使用第一张【杀】无次数限制。",
  ["humei"] = "狐魅",
  [":humei"] = "出牌阶段每项限一次，你可以选择一项，令一名体力值不大于X的角色执行：1.摸一张牌；2.交给你一张牌；3.回复1点体力"..
  "（X为你本阶段造成伤害次数）。",
  ["#jiaoxia-invoke"] = "狡黠：你可以令本阶段你的手牌均视为【杀】，且结算后你视为使用原本牌名的牌！",
  ["@@jiaoxia-phase"] = "狡黠",
  ["#jiaoxia_filter"] = "狡黠",
  ["jiaoxia_viewas"] = "狡黠",
  ["#jiaoxia-use"] = "狡黠：请视为使用【%arg】",
  ["#humei"] = "狐魅：令一名体力值不大于%arg的角色执行一项",
  ["humei1-phase"] = "摸一张牌",
  ["humei2-phase"] = "交给你一张牌",
  ["humei3-phase"] = "回复1点体力",
  ["#humei-give"] = "狐魅：请交给 %src 一张牌",
}

Fk:loadTranslationTable{
  ["tianshangyi"] = "田尚衣",
  ["posuo"] = "婆娑",
  [":posuo"] = "出牌阶段每种花色限一次，若你本阶段未对其他角色造成过伤害，你可以将一张手牌当本局游戏所用牌堆中此花色的伤害牌使用。",
  ["xiaoren"] = "绡刃",
  [":xiaoren"] = "每回合限一次，当你造成伤害后，你可以判定，若结果为：红色，你可以令一名角色回复1点体力；黑色，你对受伤角色的上家或下家造成1点"..
  "伤害，然后你可以对同一方向的下一名角色重复此流程，直到有角色死亡或此角色为你。",
}

--马铁 车胄 韩嵩 诸葛梦雪 诸葛若雪 孙翎鸾

return extension
