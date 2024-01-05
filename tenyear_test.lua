local extension = Package("tenyear_test")
extension.extensionName = "tenyear"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["tenyear_test"] = "十周年-测试服",
  ["tymou"] = "新服谋",
}

local caiyong = General(extension, "mu__caiyong", "qun", 3)
local jiaowei = fk.CreateTriggerSkill{
  name = "jiaowei",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.GameStart, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.GameStart then
        return not player:isKongcheng()
      else
        return target == player and data.from and data.from:getHandcardNum() <= player:getMark("@jiaowei")
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.GameStart then
      local room = player.room
      local cards = player:getCardIds("h")
      for _, id in ipairs(cards) do
        room:setCardMark(Fk:getCardById(id), "@@jiaowei-inhand", 1)
      end
      room:setPlayerMark(player, "@jiaowei", #cards)
    else
      return true
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player:getMark("@jiaowei") > 0 then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@jiaowei", #table.filter(player:getCardIds("h"), function(id)
      return Fk:getCardById(id):getMark("@@jiaowei-inhand") > 0 end))
  end,
}
local jiaowei_maxcards = fk.CreateMaxCardsSkill{
  name = "#jiaowei_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@jiaowei-inhand") > 0
  end,
}
local feibaic = fk.CreateTriggerSkill{
  name = "feibaic",
  anim_type = "drawcard",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
      local room = player.room
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, false)
      if turn_event == nil then return false end
      local end_id = math.max(turn_event.id, player:getMark("feibaic-turn"))  --截至上次发动技能的事件id
      local yes = true
      if #U.getEventsByRule(room, GameEvent.UseCard, 2, function(e)
        local use = e.data[1]
        if e.id <= room.logic:getCurrentEvent().id then  --插入其他使用事件，eg.闪
          if use.from == player.id then
            return true
          else
            yes = false
            return false
          end
        end
      end, end_id) < 2 then return end
      return yes
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, false)
    if turn_event == nil then return false end
    local end_id = math.max(turn_event.id, player:getMark("feibaic-turn"))
    local n, event_record = 0, 0
    U.getEventsByRule(room, GameEvent.UseCard, 2, function(e)
      local use = e.data[1]
      if use.from == player.id then
        if event_record == 0 then
          event_record = e.id
        end
        n = n + #Fk:translate(use.card.trueName) / 3
      end
    end, end_id)
    room:setPlayerMark(player, "feibaic-turn", event_record)  --记录上次发动技能的事件id
    local cards = {}
    for _, id in ipairs(room.draw_pile) do
      local card = Fk:getCardById(id)
      if #Fk:translate(card.trueName) / 3 == n then
        table.insertIfNeed(cards, id)
      end
    end
    if #cards > 0 then
      room:moveCards({
        ids = {table.random(cards)},
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
    end
    if player:getMark("@jiaowei") <= n then
      player:setSkillUseHistory(self.name, 0, Player.HistoryTurn)
    end
  end,
}
jiaowei:addRelatedSkill(jiaowei_maxcards)
caiyong:addSkill(jiaowei)
caiyong:addSkill(feibaic)
Fk:loadTranslationTable{
  ["mu__caiyong"] = "乐蔡邕",
  ["jiaowei"] = "焦尾",
  [":jiaowei"] = "锁定技，游戏开始时，你的初始手牌增加“弦”标记且不计入手牌上限。当你受到伤害时，若伤害来源手牌数不大于“弦”数，防止此伤害。",
  ["feibaic"] = "飞白",
  [":feibaic"] = "每回合限一次，当你连续使用两张牌后，你可以随机获得一张字数为X的牌（X为两张牌字数之和）；若你的“弦”数不大于X，此技能视为未发动。",
  ["@jiaowei"] = "弦",
  ["@@jiaowei-inhand"] = "弦",
}

--嵇康 曹不兴 马良

--袁胤

Fk:loadTranslationTable{
  ["tianshangyi"] = "田尚衣",
  ["posuo"] = "婆娑",
  [":posuo"] = "出牌阶段每种花色限一次，若你本阶段未对其他角色造成过伤害，你可以将一张手牌当本局游戏所用牌堆中此花色的伤害牌使用。",
  ["xiaoren"] = "绡刃",
  [":xiaoren"] = "每回合限一次，当你造成伤害后，你可以判定，若结果为：红色，你可以令一名角色回复1点体力；黑色，你对受伤角色的上家或下家造成1点"..
  "伤害，然后你可以对同一方向的下一名角色重复此流程，直到有角色死亡或此角色为你。",
}

local tmp_illustrate = fk.CreateActiveSkill{name = "tmp_illustrate"}

local chezhou = General(extension, "chezhou", "wei", 4)
chezhou:addSkill(tmp_illustrate)
chezhou.hidden = true
Fk:loadTranslationTable{
  ["chezhou"] = "车胄",
  ["tmp_illustrate"] = "看画",
  [":tmp_illustrate"] = "这个武将还没上线，你可以看看插画。不会出现在选将框。",
}

local matie = General(extension, "matie", "qun", 4)
matie:addSkill("tmp_illustrate")
matie.hidden = true
Fk:loadTranslationTable{
  ["matie"] = "马铁",
}

local hansong = General(extension, "hansong", "wei", 3)
hansong:addSkill("tmp_illustrate")
hansong.hidden = true
Fk:loadTranslationTable{
  ["hansong"] = "韩嵩",
}

local zhugemengxue = General(extension, "zhugemengxue", "wei", 3, 3, General.Female)
zhugemengxue:addSkill("tmp_illustrate")
zhugemengxue.hidden = true
Fk:loadTranslationTable{
  ["zhugemengxue"] = "诸葛梦雪",
}

local mu__daqiao = General(extension, "mu__daqiao", "wu", 3, 3, General.Female)
mu__daqiao:addSkill("tmp_illustrate")
mu__daqiao.hidden = true
Fk:loadTranslationTable{
  ["mu__daqiao"] = "乐大乔",
}

return extension
