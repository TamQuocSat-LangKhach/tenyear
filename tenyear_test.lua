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
      return target == player and player:hasSkill(self.name) and data.card.type ~= Card.TypeEquip
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
    player:broadcastSkillInvoke("lvecheng")
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
          player:broadcastSkillInvoke(self.name)
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
    if event == fk.DamageInflicted then
      if room.current then
        room.current:broadcastSkillInvoke("youzhan")
        room:notifySkillInvoked(room.current, "youzhan", "offensive")
        room:doIndicate(room.current.id, {player.id})
      end
      data.damage = data.damage + player:getMark("@youzhan-turn")
      room:setPlayerMark(player, "@youzhan-turn", 0)
    else
      target:broadcastSkillInvoke("youzhan")
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
