local extension = Package("tenyear_huicui2")
extension.extensionName = "tenyear"
local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["tenyear_huicui2"] = "十周年-群英荟萃2",
  ["mu"] = "乐",
}

--江湖之远：管宁 黄承彦 胡昭 王烈 孟节
local guanning = General(extension, "guanning", "qun", 3, 7)
local dunshi = fk.CreateViewAsSkill{
  name = "dunshi",
  pattern = "slash,jink,peach,analeptic",
  interaction = function()
    local all_names, names = {"slash", "jink", "peach", "analeptic"}, {}
    local mark = Self:getMark("dunshi")
    for _, name in ipairs(all_names) do
      if type(mark) ~= "table" or not table.contains(mark, name) then
        local to_use = Fk:cloneCard(name)
        if ((Fk.currentResponsePattern == nil and to_use.skill:canUse(Self, to_use) and not Self:prohibitUse(to_use)) or
            (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(to_use))) then
          table.insertIfNeed(names, name)
        end
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    if not self.interaction.data then return nil end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    player.room:setPlayerMark(player, "dunshi_name-turn", use.card.trueName)
  end,
  enabled_at_play = function(self, player)
    if player:usedSkillTimes(self.name, Player.HistoryTurn) > 0 then return false end
    local names = {"slash", "jink", "peach", "analeptic"}
    local mark = player:getMark("dunshi")
    for _, name in ipairs(names) do
      if type(mark) ~= "table" or not table.contains(mark, name) then
        local to_use = Fk:cloneCard(name)
        if to_use.skill:canUse(player, to_use) and not player:prohibitUse(to_use) then
          return true
        end
      end
    end
  end,
  enabled_at_response = function(self, player, response)
    if player:usedSkillTimes(self.name, Player.HistoryTurn) > 0 then return false end
    local names = {"slash", "jink", "peach", "analeptic"}
    local mark = player:getMark("dunshi")
    for _, name in ipairs(names) do
      if type(mark) ~= "table" or not table.contains(mark, name) then
        local to_use = Fk:cloneCard(name)
        if (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(to_use)) then
          return true
        end
      end
    end
  end,
}
local dunshi_record = fk.CreateTriggerSkill{
  name = "#dunshi_record",
  anim_type = "special",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if player:usedSkillTimes("dunshi", Player.HistoryTurn) > 0 and target and target == player.room.current then
      if target:getMark("dunshi-turn") == 0 then
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player.room:setPlayerMark(target, "dunshi-turn", 1)
    local choices = {"dunshi1", "dunshi2", "dunshi3"}
    for i = 1, 2, 1 do
      local choice = room:askForChoice(player, choices, self.name)
      table.removeOne(choices, choice)
      if choice == "dunshi1" then
        local skills = {}
        for _, general in ipairs(Fk:getAllGenerals()) do
          for _, skill in ipairs(general.skills) do
            local str = Fk:translate(skill.name)
            if not target:hasSkill(skill,true) and
              (string.find(str, "仁") or string.find(str, "义") or string.find(str, "礼") or string.find(str, "智") or string.find(str, "信")) then
              table.insertIfNeed(skills, skill.name)
            end
          end
        end
        if #skills > 0 then
          local skill = room:askForChoice(player, table.random(skills, math.min(3, #skills)), self.name, "#dunshi-chooseskill::"..target.id, true)
          room:handleAddLoseSkills(target, skill, nil, true, false)
        end
      elseif choice == "dunshi2" then
        room:changeMaxHp(player, -1)
        if not player.dead and player:getMark("dunshi") ~= 0 then
          player:drawCards(#player:getMark("dunshi"), "dunshi")
        end
      elseif choice == "dunshi3" then
        local mark = player:getMark("dunshi")
        if mark == 0 then
          mark = {}
        end
        table.insert(mark, player:getMark("dunshi_name-turn"))
        room:setPlayerMark(player, "dunshi", mark)

        local UImark = player:getMark("@$dunshi")
        if type(UImark) == "table" then
          table.removeOne(UImark, player:getMark("dunshi_name-turn"))
          room:setPlayerMark(player, "@$dunshi", #UImark > 0 and UImark or 0)
        end
      end
    end
    if not table.contains(choices, "dunshi1") then
      return true
    end
  end,

  refresh_events = {fk.EventLoseSkill, fk.EventAcquireSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.EventAcquireSkill then
      local UImark = {"slash", "jink", "peach", "analeptic"}
      for _, name in ipairs(U.getMark(player, "dunshi")) do
        table.removeOne(UImark, name)
      end
      player:getMark("@$dunshi")
      player.room:setPlayerMark(player, "@$dunshi", #UImark > 0 and UImark or 0)
    else
      player.room:setPlayerMark(player, "@$dunshi", 0)
    end
  end,
}
dunshi:addRelatedSkill(dunshi_record)
guanning:addSkill(dunshi)
Fk:loadTranslationTable{
  ["guanning"] = "管宁",
  ["#guanning"] = "辟境归元",
  ["designer:guanning"] = "七哀",
  ["illustrator:guanning"] = "游漫美绘",
  ["dunshi"] = "遁世",
  [":dunshi"] = "每回合限一次，你可视为使用或打出一张【杀】，【闪】，【桃】或【酒】。然后当前回合角色本回合下次造成伤害时，你选择两项：<br>"..
  "1.防止此伤害，选择1个包含“仁义礼智信”的技能令其获得；<br>"..
  "2.减1点体力上限并摸X张牌（X为你选择3的次数）；<br>"..
  "3.删除你本次视为使用的牌名。",
  ["#dunshi_record"] = "遁世",
  ["@$dunshi"] = "遁世",
  ["dunshi1"] = "防止此伤害，选择1个“仁义礼智信”的技能令其获得",
  ["dunshi2"] = "减1点体力上限并摸X张牌",
  ["dunshi3"] = "删除你本次视为使用的牌名",
  ["#dunshi-chooseskill"] = "遁世：选择令%dest获得的技能",

  ["$dunshi1"] = "失路青山隐，藏名白水游。",
  ["$dunshi2"] = "隐居青松畔，遁走孤竹丘。",
  ["~guanning"] = "高节始终，无憾矣。",
}

local huangchengyan = General(extension, "ty__huangchengyan", "qun", 3)
local jiezhen = fk.CreateActiveSkill{
  name = "jiezhen",
  anim_type = "control",
  prompt = "#jiezhen-active",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):getMark("@@jiezhen") == 0
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(target, "@@jiezhen", 1)
    room:setPlayerMark(target, "jiezhen_source", effect.from)
    if not target:hasSkill("bazhen", true) then
      room:addPlayerMark(target, "jiezhen_tmpbazhen")
      room:handleAddLoseSkills(target, "bazhen", nil, true, false)
    end
  end,
}
local jiezhen_trigger = fk.CreateTriggerSkill{
  name = "#jiezhen_trigger",
  events = {fk.FinishJudge, fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(jiezhen) then
      if event == fk.FinishJudge then
        return not target.dead and table.contains({"bazhen", "eight_diagram"}, data.reason) and
        target:getMark("jiezhen_source") == player.id
      elseif event == fk.TurnStart then
        if target == player then
          for _, p in ipairs(player.room.alive_players) do
            if p:getMark("jiezhen_source") == player.id then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = {}
    if event == fk.TurnStart then
      tos = table.filter(room.alive_players, function (p) return p:getMark("jiezhen_source") == player.id end)
    else
      table.insert(tos, target)
    end
    room:doIndicate(player.id, table.map(tos, Util.IdMapper))
    for _, to in ipairs(tos) do
      if player.dead then break end
      room:setPlayerMark(to, "jiezhen_source", 0)
      room:setPlayerMark(to, "@@jiezhen", 0)
      if to:getMark("jiezhen_tmpbazhen") > 0 then
        room:handleAddLoseSkills(to, "-bazhen", nil, true, false)
      end
      if not to:isAllNude() then
        local card = room:askForCardChosen(player, to, "hej", jiezhen.name)
        room:obtainCard(player.id, card, false, fk.ReasonPrey)
      end
    end
  end,
}
local jiezhen_invalidity = fk.CreateInvaliditySkill {
  name = "#jiezhen_invalidity",
  invalidity_func = function(self, from, skill)
    if from:getMark("@@jiezhen") > 0 then
      return not (table.contains({Skill.Compulsory, Skill.Limited, Skill.Wake}, skill.frequency) or
        not skill:isPlayerSkill(from) or skill.lordSkill)
    end
  end
}
local zecai = fk.CreateTriggerSkill{
  name = "zecai",
  frequency = Skill.Limited,
  events = {fk.RoundEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) < 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local player_table = {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
      local use = e.data[1]
      if use.card.type == Card.TypeTrick then
        local from = use.from
        player_table[from] = (player_table[from] or 0) + 1
      end
    end, Player.HistoryRound)
    local max_time, max_pid = 0, nil
    for pid, time in pairs(player_table) do
      if time > max_time then
        max_pid, max_time = pid, time
      elseif time == max_time then
        max_pid = 0
      end
    end
    local max_p = nil
    if max_pid ~= 0 then
      max_p = room:getPlayerById(max_pid)
    end
    if max_p and not max_p.dead then
      room:setPlayerMark(max_p, "@@zecai_extra", 1)
    end
    local to = room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#zecai-choose", self.name, true)
    if max_p and not max_p.dead then
      room:setPlayerMark(max_p, "@@zecai_extra", 0)
    end
    if #to > 0 then
      self.cost_data = {to[1], max_pid}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tar = room:getPlayerById(self.cost_data[1])
    if not tar:hasSkill("ex__jizhi", true) then
      room:addPlayerMark(tar, "zecai_tmpjizhi")
      room:handleAddLoseSkills(tar, "ex__jizhi", nil, true, false)
    end
    if self.cost_data[1] == self.cost_data[2] then
      tar:gainAnExtraTurn()
    end
  end,

  refresh_events = {fk.RoundEnd},
  can_refresh = function(self, event, target, player, data)
    return player:getMark("zecai_tmpjizhi") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "zecai_tmpjizhi", 0)
    room:handleAddLoseSkills(player, "-ex__jizhi", nil, true, false)
  end,
}
local yinshih = fk.CreateTriggerSkill{
  name = "yinshih",
  frequency = Skill.Compulsory,
  anim_type = "defensive",
  events = {fk.FinishJudge, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.FinishJudge then
        return table.contains({"eight_diagram", "#eight_diagram_skill"}, data.reason) and player.room:getCardArea(data.card) == Card.Processing
      elseif player == target and (not data.card or data.card.color == Card.NoColor) and player:getMark("yinshih_defensive-turn") == 0 then
        return #U.getActualDamageEvents(player.room, 1, function(e)
          local damage = e.data[1]
          return damage.to == player and (not damage.card or damage.card.color == Card.NoColor)
        end) == 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.FinishJudge then
      player.room:moveCardTo(data.card, Card.PlayerHand, player, fk.ReasonPrey, self.name)
    else
      player.room:setPlayerMark(player, "yinshih_defensive-turn", 1)
      return true
    end
  end,
}
jiezhen:addRelatedSkill(jiezhen_trigger)
jiezhen:addRelatedSkill(jiezhen_invalidity)
huangchengyan:addSkill(jiezhen)
huangchengyan:addSkill(zecai)
huangchengyan:addSkill(yinshih)
Fk:loadTranslationTable{
  ["ty__huangchengyan"] = "黄承彦",
  ["#ty__huangchengyan"] = "捧月共明",
  ["designer:ty__huangchengyan"] = "七哀",
  ["illustrator:ty__huangchengyan"] = "凡果",
  ["jiezhen"] = "解阵",
  ["#jiezhen_trigger"] = "解阵",
  [":jiezhen"] = "出牌阶段限一次，你可令一名其他角色的所有技能替换为〖八阵〗（锁定技、限定技、觉醒技、主公技除外）。"..
  "你的回合开始时或当其【八卦阵】判定后，你令其失去〖八阵〗并获得原技能，然后你获得其区域里的一张牌。",
  ["zecai"] = "择才",
  [":zecai"] = "限定技，一轮结束时，你可令一名其他角色获得〖集智〗直到下一轮结束，若其是本轮使用锦囊牌数唯一最多的角色，其执行一个额外的回合。",
  ["yinshih"] = "隐世",
  [":yinshih"] = "锁定技，你每回合首次受到无色牌或非游戏牌造成的伤害时，防止此伤害。当场上有角色判定【八卦阵】时，你获得其生效的判定牌。",

  ["#jiezhen-active"] = "发动 解阵，将一名角色的技能替换为〖八阵〗",
  ["@@jiezhen"] = "解阵",
  ["#zecai-choose"] = "你可以发动择才，令一名其他角色获得〖集智〗直到下轮结束",
  ["@@zecai_extra"] = "择才 额外回合",

  ["$jiezhen1"] = "八阵无破，唯解死而向生。",
  ["$jiezhen2"] = "此阵，可由景门入、生门出。",
  ["$zecai1"] = "诸葛良才，可为我佳婿。",
  ["$zecai2"] = "梧桐亭亭，必引凤而栖。",
  ["$yinshih1"] = "南阳隐世，耕读传家。",
  ["$yinshih2"] = "手扶耒耜，不闻风雷。",
  ["~ty__huangchengyan"] = "卧龙出山天伦逝，悔教吾婿离南阳……",
}

local huzhao = General(extension, "huzhao", "qun", 3)
local midu = fk.CreateActiveSkill{
  name = "midu",
  anim_type = "special",
  card_num = 0,
  target_num = 0,
  prompt = function (self)
    return "#"..self.interaction.data
  end,
  interaction = function(self)
    local choices = {}
    if #Self:getAvailableEquipSlots() > 0 or not table.contains(Self.sealedSlots, Player.JudgeSlot) then
      table.insert(choices, "midu1")
    end
    if #Self.sealedSlots > 0 then
      table.insert(choices, "midu2")
    end
    return UI.ComboBox { choices = choices }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if self.interaction.data == "midu1" then
      local choices = {}
      if not table.contains(player.sealedSlots, Player.JudgeSlot) then
        table.insert(choices, "JudgeSlot")
      end
      table.insertTable(choices, player:getAvailableEquipSlots())
      local choice = room:askForChoices(player, choices, 1, #choices, self.name, "#midu-abort", false)
      room:abortPlayerArea(player, choice)
      if not player.dead then
        local to = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 1,
          "#midu-draw:::"..#choice, self.name, false)
        if #to > 0 then
          to = to[1]
        else
          to = player.id
        end
        room:getPlayerById(to):drawCards(#choice, self.name)
      end
    else
      local choices = table.simpleClone(player.sealedSlots)
      local choice = room:askForChoice(player, choices, self.name, "#midu-resume")
      room:resumePlayerArea(player, {choice})
      if not player:hasSkill("ty_ex__huomo", true) then
        room:handleAddLoseSkills(player, "ty_ex__huomo", nil, true, false)
        room:setPlayerMark(player, self.name, 1)
      end
    end
  end,
}
local midu_trigger = fk.CreateTriggerSkill{
  name = "#midu_trigger",

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("midu") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "midu", 0)
    room:handleAddLoseSkills(player, "-ty_ex__huomo", nil, true, false)
  end,
}
local xianwang = fk.CreateDistanceSkill{
  name = "xianwang",
  frequency = Skill.Compulsory,
  correct_func = function(self, from, to)
    if from:hasSkill(self) then
      local n = #table.filter(from.sealedSlots, function(slot) return slot ~= "JudgeSlot" end)
      if n > 3 then
        return -2
      elseif n > 0 then
        return -1
      end
    end
    if to:hasSkill(self) then
      local n = #table.filter(to.sealedSlots, function(slot) return slot ~= "JudgeSlot" end)
      if n > 3 then
        return 2
      elseif n > 0 then
        return 1
      end
    end
    return 0
  end,
}
midu:addRelatedSkill(midu_trigger)
huzhao:addSkill(midu)
huzhao:addSkill(xianwang)
huzhao:addRelatedSkill("ty_ex__huomo")
Fk:loadTranslationTable{
  ["huzhao"] = "胡昭",
  ["#huzhao"] = "阖门守静",
  ["illustrator:huzhao"] = "游漫美绘",
  ["midu"] = "弥笃",
  [":midu"] = "出牌阶段限一次，你可以选择一项：1.废除任意个装备栏或判定区，令一名角色摸等量的牌；2.恢复一个被废除的装备栏或判定区，"..
  "你获得〖活墨〗直到你下个回合开始。",
  ["xianwang"] = "贤望",
  [":xianwang"] = "锁定技，若你有废除的装备栏，其他角色计算与你的距离+1，你计算与其他角色的距离-1；若你有至少三个废除的装备栏，以上数字改为2。",
  ["midu1"] = "废除",
  ["midu2"] = "恢复",
  ["#midu1"] = "弥笃：废除任意个区域，令一名角色摸等量牌",
  ["#midu2"] = "弥笃：恢复一个区域，直到下个回合开始获得〖活墨〗",
  ["#midu-abort"] = "弥笃：选择要废除的区域",
  ["#midu-draw"] = "弥笃：令一名角色摸%arg张牌",
  ["#midu-resume"] = "弥笃：选择要恢复的区域",

  ["$midu1"] = "皓首穷经，其心不移。",
  ["$midu2"] = "竹简册书，百读不厌。",
  ["$xianwang1"] = "浩气长存，以正压邪。",
  ["$xianwang2"] = "名彰千里，盗无敢侵。",
  ["$ty_ex__huomo_huzhao1"] = "行文挥毫，得心应手。",
  ["$ty_ex__huomo_huzhao2"] = "泼墨走笔，挥洒自如。",
  ["~huzhao"] = "纵有清名，无益于世也。",
}

local wanglie = General(extension, "wanglie", "qun", 3)
local chongwang = fk.CreateTriggerSkill{
  name = "chongwang",
  anim_type = "control",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target ~= player and (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) then
      local logic = player.room.logic
      local use_event = logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if use_event == nil then return false end
      local events = logic.event_recorder[GameEvent.UseCard] or Util.DummyTable
      local last_find = false
      for i = #events, 1, -1 do
        local e = events[i]
        if e.id == use_event.id then
          last_find = true
        elseif last_find then
          if e.data[1].from == player.id then
            return true
          end
          return false
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {"Cancel", "chongwang2"}
    if player.room:getCardArea(data.card) == Card.Processing then
      table.insert(choices, 2, "chongwang1")
    end
    local choice = player.room:askForChoice(player, choices, self.name,
    "#chongwang-invoke::"..target.id .. ":" .. data.card:toLogString(), false, {"chongwang1", "chongwang2", "Cancel"})
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if self.cost_data == "chongwang1" then
      player.room:obtainCard(target, data.card, true, fk.ReasonPrey)
    else
      if data.toCard ~= nil then
        data.toCard = nil
      else
        data.nullifiedTargets = table.map(player.room.players, Util.IdMapper)
      end
    end
  end,

  refresh_events = {fk.CardUsing, fk.EventAcquireSkill, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    if event == fk.CardUsing then
      return player:hasSkill(self, true)
    else
      return data == self and target == player
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local x = 0
    if event == fk.CardUsing and target == player then
      x = 1
    elseif event == fk.EventAcquireSkill then
      local events = player.room.logic.event_recorder[GameEvent.UseCard] or Util.DummyTable
      if #events > 0 and events[#events].data[1].from == player.id then
        x = 1
      end
    end
    if player:getMark("@@chongwang") ~= x then
      player.room:setPlayerMark(player, "@@chongwang", x)
    end
  end,
}
local huagui = fk.CreateTriggerSkill{
  name = "huagui",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isNude() end), Util.IdMapper)
    if #targets == 0 then return end
    local nums = {0, 0, 0}
    for _, p in ipairs(room.alive_players) do
      if p.role == "lord" or p.role == "loyalist" then
        nums[1] = nums[1] + 1
      elseif p.role == "rebel" then
        nums[2] = nums[2] + 1
      else
        nums[3] = nums[3] + 1
      end
    end
    local n = math.max(table.unpack(nums))
    local tos = room:askForChoosePlayers(player, targets, 1, n, "#huagui-choose:::"..tostring(n), self.name, true, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = table.map(self.cost_data, function(id) return room:getPlayerById(id) end)
    local other_players = room:getOtherPlayers(player, false)
    --FIXME:用activeskill整合成一个读条
    local extraData = {
      num = 1,
      min_num = 1,
      include_equip = true,
      pattern = ".",
      reason = self.name,
    }
    for _, p in ipairs(tos) do
      p.request_data = json.encode({ "choose_cards_skill", "#huagui-card:"..player.id, false, extraData })
    end
    room:notifyMoveFocus(other_players, self.name)
    room:doBroadcastRequest("AskForUseActiveSkill", tos)
    for _, p in ipairs(tos) do
      local id
      if p.reply_ready then
        local replyCard = json.decode(p.client_reply).card
        id = json.decode(replyCard).subcards[1]
      else
        id = table.random(p:getCardIds{Player.Hand, Player.Equip})
      end
      room:setPlayerMark(p, "huagui-phase", id)
    end

    for _, p in ipairs(tos) do
      local id = p:getMark("huagui-phase")
      local choices = {"huagui1"}
      if room:getCardArea(id) == Player.Hand then
        table.insert(choices, "huagui2")
      end
      local card = Fk:getCardById(id)
      p.request_data = json.encode({ choices, choices, self.name, "#huagui-choice:"..player.id.."::"..card:toLogString() })
    end
    room:notifyMoveFocus(other_players, self.name)
    room:doBroadcastRequest("AskForChoice", tos)
    local get = true
    for _, p in ipairs(tos) do
      local choice
      if p.reply_ready then
        choice = p.client_reply
      else
        choice = "huagui1"
      end
      local card = Fk:getCardById(p:getMark("huagui-phase"))
      if choice == "huagui1" then
        get = false
        room:obtainCard(player, card, false, fk.ReasonGive, p.id)
      else
        p:showCards({card})
      end
    end

    if get then
      room:delay(2000)
    end
    for _, p in ipairs(tos) do
      if get then
        local card = Fk:getCardById(p:getMark("huagui-phase"))
        room:obtainCard(player, card, false, fk.ReasonPrey)
      end
      room:setPlayerMark(p, "huagui-phase", 0)
    end
  end,
}
wanglie:addSkill(chongwang)
wanglie:addSkill(huagui)
Fk:loadTranslationTable{
  ["wanglie"] = "王烈",
  ["#wanglie"] = "通识达道",
  ["designer:wanglie"] = "七哀",
  ["cv:wanglie"] = "虞晓旭",
  ["illustrator:wanglie"] = "青岛君桓",
  ["chongwang"] = "崇望",
  [":chongwang"] = "其他角色使用一张基本牌或普通锦囊牌时，若你为上一张牌的使用者，你可令其获得其使用的牌或令该牌无效。",
  ["huagui"] = "化归",
  [":huagui"] = "出牌阶段开始时，你可秘密选择至多X名其他角色（X为最大阵营存活人数），这些角色同时选择："..
  "若1.将一张牌交给你；2.展示一张牌。均选择展示牌，你获得这些牌。",
  ["@@chongwang"] = "崇望",
  ["#chongwang-invoke"] = "崇望：你可以令 %dest 对%arg执行的一项",
  ["chongwang1"] = "其获得此牌",
  ["chongwang2"] = "此牌无效",
  ["#huagui-choose"] = "化归：你可以秘密选择至多%arg名角色，各选择交给你一张牌或展示一张牌",
  ["#huagui-card"] = "化归：选择一张牌，交给 %src 或展示之",
  ["#huagui-choice"] = "化归：选择将%arg交给 %src 或展示之",
  ["huagui1"] = "交出",
  ["huagui2"] = "展示",

  ["$chongwang1"] = "乡人所崇者，烈之义行也。",
  ["$chongwang2"] = "诸家争讼曲直，可质于我。",
  ["$huagui1"] = "烈不才，难为君之朱紫。",
  ["$huagui2"] = "一身风雨，难坐高堂。",
  ["~wanglie"] = "烈尚不能自断，何断人乎？",
}

local mengjie = General(extension, "mengjie", "qun", 3)
local yinlu = fk.CreateTriggerSkill{
  name = "yinlu",
  events = {fk.GameStart, fk.EventPhaseStart, fk.Death},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.GameStart then
        return true
      elseif event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Start
      else
        for i = 1, 4, 1 do
          if target:getMark("@@yinlu"..i) > 0 then
            return true
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.GameStart then
      return true
    elseif event == fk.EventPhaseStart then
      local targets = {}
      for _, p in ipairs(player.room:getAlivePlayers()) do
        for i = 1, 4, 1 do
          if p:getMark("@@yinlu"..i) > 0 then
            table.insert(targets, p.id)
          end
        end
      end
      if #targets > 0 then
        local to = player.room:askForChoosePlayers(player, targets, 1, 1, "#yinlu_move-invoke1", self.name, true)
        if #to > 0 then
          self.cost_data = to[1]
          return true
        end
      end
    else
      if player.room:askForSkillInvoke(player, self.name, nil, "#yinlu_move-invoke2::"..target.id) then
        self.cost_data = target.id
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local targets = table.map(room:getAlivePlayers(), Util.IdMapper)
      for i = 1, 3, 1 do
        local to = room:askForChoosePlayers(player, targets, 1, 1, "#yinlu-give"..i, self.name)
        if #to > 0 then
          to = to[1]
        else
          to = table.random(targets)
        end
        room:setPlayerMark(room:getPlayerById(to), "@@yinlu"..i, 1)
      end
      room:setPlayerMark(player, "@@yinlu4", 1)
      room:addPlayerMark(player, "@yunxiang", 1)  --开局自带一个小芸香标记
    else
      local to = room:getPlayerById(self.cost_data)
      local choices = {}
      for i = 1, 4, 1 do
        if to:getMark("@@yinlu"..i) > 0 then
          table.insert(choices, "@@yinlu"..i)
        end
      end
      if event == fk.Death then
        table.insert(choices, "Cancel")
      end
      while true do
        local choice = room:askForChoice(player, choices, self.name, "#yinlu-choice")
        if choice == "Cancel" then return end
        table.removeOne(choices, choice)
        local targets = table.map(room:getOtherPlayers(to), Util.IdMapper)
        local dest
        if #targets > 1 then
          dest = room:askForChoosePlayers(player, targets, 1, 1, "#yinlu-move:::"..choice, self.name, false)
          if #dest > 0 then
            dest = dest[1]
          else
            dest = table.random(targets)
          end
        else
          dest = targets[1]
        end
        dest = room:getPlayerById(dest)
        room:setPlayerMark(to, choice, 0)
        room:setPlayerMark(dest, choice, 1)
        if event == fk.EventPhaseStart then return end
      end
    end
  end,

  refresh_events = {fk.Deathed},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self, true, true) and
      not table.find(player.room.alive_players, function(p) return p:hasSkill(self, true) end)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      for i = 1, 4, 1 do
        room:setPlayerMark(p, "@@yinlu"..i, 0)
      end
    end
  end,
}
local yinlu1 = fk.CreateTriggerSkill{
  name = "#yinlu1",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@yinlu1") > 0 and player.phase == Player.Finish and player:isWounded() and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    return #player.room:askForDiscard(player, 1, 1, true, "yinlu", true, ".|.|diamond", "#yinlu1-invoke") > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:recover{
      who = player,
      num = 1,
      recoverBy = player,
      skillName = "yinlu",
    }
  end,
}
local yinlu2 = fk.CreateTriggerSkill{
  name = "#yinlu2",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@yinlu2") > 0 and player.phase == Player.Finish and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    return #player.room:askForDiscard(player, 1, 1, true, "yinlu", true, ".|.|heart", "#yinlu2-invoke") > 0
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, "yinlu")
  end,
}
local yinlu3 = fk.CreateTriggerSkill{
  name = "#yinlu3",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@yinlu3") > 0 and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    if player:isNude() or #player.room:askForDiscard(player, 1, 1, true, "yinlu", true, ".|.|spade", "#yinlu3-invoke") == 0 then
      player.room:loseHp(player, 1, "yinlu")
    end
  end,
}
local yinlu4 = fk.CreateTriggerSkill{
  name = "#yinlu4",
  mute = true,
  events = {fk.EventPhaseStart, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.EventPhaseStart then
        return player:getMark("@@yinlu4") > 0 and player.phase == Player.Finish and not player:isNude()
      else
        return player:getMark("@yunxiang") > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return #player.room:askForDiscard(player, 1, 1, true, "yinlu", true, ".|.|club", "#yinlu4-invoke") > 0
    else
      return player.room:askForSkillInvoke(player, "yinlu", nil, "#yinlu-yunxiang")
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:addPlayerMark(player, "@yunxiang", 1)
    else
      local num = player:getMark("@yunxiang")
      room:setPlayerMark(player, "@yunxiang", 0)
      if data.damage > num then
        data.damage = data.damage - num
      else
        return true
      end
    end
  end,
}
local youqi = fk.CreateTriggerSkill{
  name = "youqi",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      for _, move in ipairs(data) do
        if move.skillName == "yinlu" and move.from and move.from ~= player.id then
          self.cost_data = move
          local x = 1 - (math.min(5, player:distanceTo(player.room:getPlayerById(move.from))) / 10)
          return x > math.random()  --据说，距离1 0.9概率，距离5以上 0.5概率
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    for _, info in ipairs(self.cost_data.moveInfo) do
      player.room:obtainCard(player.id, info.cardId, true, fk.ReasonJustMove)
    end
  end,
}
yinlu:addRelatedSkill(yinlu1)
yinlu:addRelatedSkill(yinlu2)
yinlu:addRelatedSkill(yinlu3)
yinlu:addRelatedSkill(yinlu4)
mengjie:addSkill(yinlu)
mengjie:addSkill(youqi)
Fk:loadTranslationTable{
  ["mengjie"] = "孟节",
  ["#mengjie"] = "万安隐者",
  ["designer:mengjie"] = "神壕",
  ["illustrator:mengjie"] = "君桓文化",

  ["yinlu"] = "引路",
  [":yinlu"] = "游戏开始时，你令三名角色依次获得以下一个标记：“乐泉”、“藿溪”、“瘴气”，然后你获得一个“芸香”。<br>"..
  "准备阶段，你可以移动一个标记；有标记的角色死亡时，你可以移动其标记。拥有标记的角色获得对应的效果：<br>"..
  "乐泉：结束阶段，你可以弃置一张<font color='red'>♦</font>牌，然后回复1点体力；<br>"..
  "藿溪：结束阶段，你可以弃置一张<font color='red'>♥</font>牌，然后摸两张牌；<br>"..
  "瘴气：结束阶段，你需要弃置一张♠牌，否则失去1点体力；<br>"..
  "芸香：结束阶段，你可以弃置一张♣牌，获得一个“芸香”；当你受到伤害时，你可以移去所有“芸香”并防止等量的伤害。",
  ["youqi"] = "幽栖",
  [":youqi"] = "锁定技，其他角色因“引路”弃置牌时，你有概率获得此牌，该角色距离你越近，概率越高。",
  ["#yinlu-give1"] = "引路：请选择获得“乐泉”（回复体力）的角色",
  ["#yinlu-give2"] = "引路：请选择获得“藿溪”（摸牌）的角色",
  ["#yinlu-give3"] = "引路：请选择获得“瘴气”（失去体力）的角色",
  ["#yinlu-give4"] = "引路：请选择获得“芸香”（防止伤害）的角色",
  ["@@yinlu1"] = "<font color='red'>♦</font>乐泉",
  ["@@yinlu2"] = "<font color='red'>♥</font>藿溪",
  ["@@yinlu3"] = "♠瘴气",
  ["@@yinlu4"] = "♣芸香",
  ["@yunxiang"] = "芸香",
  ["#yinlu_move-invoke1"] = "引路：你可以移动一个标记",
  ["#yinlu_move-invoke2"] = "引路：你可以移动 %dest 的标记",
  ["#yinlu-choice"] = "引路：请选择要移动的标记",
  ["#yinlu-move"] = "引路：请选择获得“%arg”的角色",
  ["#yinlu1"] = "<font color='red'>♦</font>乐泉",
  ["#yinlu2"] = "<font color='red'>♥</font>藿溪",
  ["#yinlu3"] = "♠瘴气",
  ["#yinlu4"] = "♣芸香",
  ["#yinlu1-invoke"] = "<font color='red'>♦</font>乐泉：你可以弃置一张<font color='red'>♦</font>牌，回复1点体力",
  ["#yinlu2-invoke"] = "<font color='red'>♥</font>藿溪：你可以弃置一张<font color='red'>♥</font>牌，摸两张牌",
  ["#yinlu3-invoke"] = "♠瘴气：你需弃置一张♠牌，否则失去1点体力",
  ["#yinlu4-invoke"] = "♣芸香：你可以弃置一张♣牌，获得一个可以防止1点伤害的“芸香”标记",
  ["#yinlu-yunxiang"] = "♣芸香：你可以消耗所有“芸香”，防止等量的伤害",

  ["$yinlu1"] = "南疆苦瘴，非土人不得过。",
  ["$yinlu2"] = "闻丞相南征，某特来引之。",
  ["$youqi1"] = "寒烟锁旧山，坐看云起出。",
  ["$youqi2"] = "某隐居山野，不慕富贵功名。",
  ["~mengjie"] = "蛮人无知，请丞相教之……",
}

--悬壶济世：吉平 孙寒华 郑浑 刘宠骆俊 吴普
local jiping = General(extension, "jiping", "qun", 3)
local xunli = fk.CreateTriggerSkill{
  name = "xunli",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove, fk.EventPhaseStart},
  derived_piles = "jiping_li",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:getMark("lieyi_using-phase") == 0 then  --发动烈医过程中不会触发询疠，新杀智慧
      if event == fk.AfterCardsMove and #player:getPile("jiping_li") < 9 then
        local ids = {}
        for _, move in ipairs(data) do
          if move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              if Fk:getCardById(info.cardId).color == Card.Black and player.room:getCardArea(info.cardId) == Card.DiscardPile then
                table.insert(ids, info.cardId)
              end
            end
          end
        end
        if #ids > 0 then
          self.cost_data = ids
          return true
        end
      elseif event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Play and not player:isKongcheng() and #player:getPile("jiping_li") > 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      local ids = self.cost_data
      local n = 9 - #player:getPile("jiping_li")
      if n < #ids then
        ids = table.slice(ids, 1, n + 1)
      end
      player:addToPile("jiping_li", ids, true, self.name)
    else
      local cards = table.filter(player:getCardIds("h"), function(id)
        return Fk:getCardById(id, true).color == Card.Black and Fk:getCardById(id).color == Card.Black
      end)
      local piles = U.askForArrangeCards(player, self.name, {player:getPile("jiping_li"), cards, "jiping_li", "$Hand"},
      "#xunli-exchange", true)
      U.swapCardsWithPile(player, piles[1], piles[2], self.name, "jiping_li", true)
    end
  end,
}
local zhishi = fk.CreateTriggerSkill{
  name = "zhishi",
  anim_type = "support",
  expand_pile = "jiping_li",
  events = {fk.EventPhaseStart, fk.TargetConfirmed, fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Finish
      else
        return player:getMark(self.name) == target.id and not target.dead and
          ((event == fk.TargetConfirmed and data.card.trueName == "slash") or event == fk.EnterDying) and
          #player:getPile("jiping_li") > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local to = player.room:askForChoosePlayers(player, table.map(player.room.alive_players, Util.IdMapper),
        1, 1, "#zhishi-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    else
      local cards = player.room:askForCard(player, 1, 999, false, self.name, true,
        ".|.|.|jiping_li", "#zhishi-invoke::"..target.id, "jiping_li")
      if #cards > 0 then
        self.cost_data = cards
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local to = room:getPlayerById(self.cost_data)
      room:setPlayerMark(to, "@@zhishi", 1)
      room:setPlayerMark(player, self.name, to.id)
    else
      room:doIndicate(player.id, {target.id})
      local cards = table.simpleClone(self.cost_data)
      room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name, nil, true, player.id)
      if not target.dead then
        target:drawCards(#cards, self.name)
      end
    end
  end,

  refresh_events = {fk.TurnStart, fk.Death},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark(self.name) ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(player:getMark(self.name))
    if not to.dead then
      room:setPlayerMark(to, "@@zhishi", 0)
    end
    room:setPlayerMark(player, self.name, 0)
  end,
}
local lieyi = fk.CreateActiveSkill{
  name = "lieyi",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#lieyi",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and #player:getPile("jiping_li") > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(player, "lieyi_using-phase", 1)
    player:showCards(player:getPile("jiping_li"))
    local yes = true
    while #player:getPile("jiping_li") > 0 and not player.dead and not target.dead do
      if target.dead then break end
      local id = room:askForCard(player, 1, 1, false, self.name, false, ".|.|.|jiping_li", "#lieyi-use::"..target.id, "jiping_li")
      if #id > 0 then
        id = id[1]
      else
        id = table.random(player:getPile("jiping_li"))
      end
      local card = Fk:getCardById(id)
      local canUse = player:canUseTo(card, target, {bypass_distances = true, bypass_times = true}) and not
      (card.skill:getMinTargetNum() == 0 and not card.multiple_targets)
      local tos = {{target.id}}
      if canUse and card.skill:getMinTargetNum() == 2 then
        local seconds = {}
        Self = player
        for _, second in ipairs(room:getOtherPlayers(target)) do
          if card.skill:targetFilter(second.id, {target.id}, {}, card) then
            table.insert(seconds, second.id)
          end
        end
        if #seconds > 0 then
          local second = room:askForChoosePlayers(player, seconds, 1, 1, "#lieyi-second:::"..card:toLogString(), self.name, false, true)
          table.insert(tos, second)
        else
          canUse = false
        end
      end
      if canUse then
        local use = {
          from = player.id,
          tos = tos,
          card = card,
          extraUse = true,
        }
        use.extra_data = use.extra_data or {}
        use.extra_data.lieyi_use = player.id
        room:useCard(use)
        if use.extra_data.lieyi_dying then
          yes = false
        end
      else
        room:moveCardTo(card, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name, nil, true, player.id)
      end
    end
    if #player:getPile("jiping_li") > 0 then
      room:moveCardTo(player:getPile("jiping_li"), Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name, nil, true, player.id)
    end
    room:setPlayerMark(player, "lieyi_using-phase", 0)
    if yes and not player.dead then
      room:loseHp(player, 1, self.name)
    end
  end,
}
local lieyi_trigger = fk.CreateTriggerSkill{
  name = "#lieyi_trigger",

  refresh_events = {fk.EnterDying},
  can_refresh = function (self, event, target, player, data)
    if data.damage and data.damage.card then
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if e then
        local use = e.data[1]
        return use.extra_data and use.extra_data.lieyi_use and use.extra_data.lieyi_use == player.id
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if e then
      local use = e.data[1]
      use.extra_data = use.extra_data or {}
      use.extra_data.lieyi_dying = true
    end
  end,
}
lieyi:addRelatedSkill(lieyi_trigger)
jiping:addSkill(xunli)
jiping:addSkill(zhishi)
jiping:addSkill(lieyi)
Fk:loadTranslationTable{
  ["jiping"] = "吉平",
  ["#jiping"] = "白虹贯日",
  ["illustrator:jiping"] = "游漫美绘",
  ["xunli"] = "询疠",
  [":xunli"] = "锁定技，当黑色牌因弃置进入弃牌堆后，将之置于你的武将牌上，称为“疠”（至多9张）。出牌阶段开始时，你可以用任意张黑色手牌交换等量的“疠”。",
  ["zhishi"] = "指誓",
  [":zhishi"] = "结束阶段，你可以选择一名角色，直到你下回合开始，该角色成为【杀】的目标后或进入濒死状态时，你可以移去任意张“疠”，令其摸等量的牌。",
  ["lieyi"] = "烈医",
  [":lieyi"] = "出牌阶段限一次，你可以展示所有“疠”并选择一名其他角色，并依次对其使用可使用的“疠”（无距离与次数限制且不计入次数），不可使用的置入弃牌堆。然后若该角色未因此进入濒死状态，你失去1点体力。",

  ["jiping_li"] = "疠",
  ["#xunli-exchange"] = "询疠：用黑色手牌交换等量的“疠”",
  ["#zhishi-choose"] = "指誓：选择一名角色，当其成为【杀】的目标后或进入濒死状态时，你可以移去“疠”令其摸牌",
  ["@@zhishi"] = "指誓",
  ["#zhishi-invoke"] = "指誓：你可以移去任意张“疠”，令 %dest 摸等量的牌",
  ["#lieyi"] = "烈医：你可以对一名角色使用所有“疠”！",
  ["#lieyi-use"] = "烈医：选择一张“疠”对 %dest 使用（若无法使用则置入弃牌堆）",
  ["#lieyi-second"] = "烈医：选择你对其使用 %arg 的副目标",

  ["$xunli1"] = "病情扑朔，容某思量。",
  ["$xunli2"] = "此疾难辨，容某细察。",
  ["$zhishi1"] = "嚼指为誓，誓杀国贼！",
  ["$zhishi2"] = "心怀汉恩，断指相随。",
  ["$lieyi1"] = "君有疾在身，不治将恐深。",
  ["$lieyi2"] = "汝身患重疾，当以虎狼之药去之。",
  ["~jiping"] = "今事不成，惟死而已！",
}

local sunhanhua = General(extension, "ty__sunhanhua", "wu", 3, 3, General.Female)
local huiling = fk.CreateTriggerSkill{
  name = "huiling",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local red, black = 0, 0
    local color
    for _, id in ipairs(room.discard_pile) do
      color = Fk:getCardById(id).color
      if color == Card.Red then
        red = red+1
      elseif color == Card.Black then
        black = black+1
      end
    end
    if red > black then
      if data.card.color == Card.Black then
        room:addPlayerMark(player, "ty__sunhanhua_ling", 1)
        room:setPlayerMark(player, "@ty__sunhanhua_ling", "<font color='red'>" .. tostring(player:getMark("ty__sunhanhua_ling")) .. "</font>")
      end
      if player:isWounded() then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name,
        }
      end
    elseif black > red then
      if data.card.color == Card.Red then
        room:addPlayerMark(player, "ty__sunhanhua_ling", 1)
        room:setPlayerMark(player, "@ty__sunhanhua_ling", tostring(player:getMark("ty__sunhanhua_ling")))
      end
      local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
        return not p:isAllNude() end), Util.IdMapper)
      if #targets > 0 then
        local to = room:askForChoosePlayers(player, targets, 1, 1, "#huiling-choose", self.name)
        if #to > 0 then
          to = room:getPlayerById(to[1])
          local id = room:askForCardChosen(player, to, "hej", self.name)
          room:throwCard({id}, self.name, to, player)
        end
      end
    end
  end,

  refresh_events = {fk.AfterCardsMove, fk.AfterDrawPileShuffle, fk.EventAcquireSkill, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    if event == fk.AfterCardsMove then
      if not player:hasSkill(self, true) then return false end
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          return true
        end
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.DiscardPile then
            return true
          end
        end
      end
    elseif event == fk.AfterDrawPileShuffle then
      return player:hasSkill(self, true)
    elseif event == fk.EventAcquireSkill or event == fk.EventLoseSkill then
      return player == target and data == self
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventLoseSkill then
      room:setPlayerMark(player, "ty__sunhanhua_ling", 0)
      room:setPlayerMark(player, "@ty__sunhanhua_ling", 0)
    else
      local red, black = 0, 0
      local color
      for _, id in ipairs(room.discard_pile) do
        color = Fk:getCardById(id).color
        if color == Card.Red then
          red = red+1
        elseif color == Card.Black then
          black = black+1
        end
      end
      local x = player:getMark("ty__sunhanhua_ling")
      local huiling_info = ""
      if red > black then
        huiling_info = "<font color='red'>" .. tostring(x) .. "</font>"
      elseif red < black then
        huiling_info = tostring(x)
      else
        huiling_info = "<font color='grey'>" .. tostring(x) .. "</font>"
      end
      room:setPlayerMark(player, "@ty__sunhanhua_ling", huiling_info)
    end
  end,
}
local chongxu = fk.CreateActiveSkill{
  name = "chongxu",
  anim_type = "special",
  frequency = Skill.Limited,
  card_num = 0,
  target_num = 0,
  prompt = function(self)
    return "#chongxu:::"..tostring(Self:getMark("ty__sunhanhua_ling"))
  end,
  can_use = function(self, player)
    return player:getMark("ty__sunhanhua_ling") > 3 and player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and player:hasSkill("huiling", true)
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local x = player:getMark("ty__sunhanhua_ling")
    room:handleAddLoseSkills(player, "-huiling", nil, true, false)
    room:changeMaxHp(player, x)
    room:handleAddLoseSkills(player, "taji|qinghuang", nil, true, false)
  end
}
local function doTaji(player, n)
  local room = player.room
  if n == 1 then
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isNude() end), Util.IdMapper)
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#taji-choose", "taji", false)
    if #to > 0 then
      to = room:getPlayerById(to[1])
      local id = room:askForCardChosen(player, to, "he", "taji")
      room:throwCard({id}, "taji", to, player)
    end
  elseif n == 2 then
    player:drawCards(1, "taji")
  elseif n == 3 then
    if player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = "taji",
      }
    end
  elseif n == 4 then
    room:addPlayerMark(player, "@taji", 1)
  end
end
local taji = fk.CreateTriggerSkill{
  name = "taji",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
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
  on_use = function(self, event, target, player, data)
    local index = {}
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            if move.moveReason == fk.ReasonUse then
              table.insertIfNeed(index, 1)
            elseif move.moveReason == fk.ReasonResonpse then
              table.insertIfNeed(index, 2)
            elseif move.moveReason == fk.ReasonDiscard then
              table.insertIfNeed(index, 3)
            else
              table.insertIfNeed(index, 4)
            end
          end
        end
      end
    end
    for _, i in ipairs(index) do
      if player.dead then return end
      doTaji(player, i)
      if not player.dead and player:getMark("@@qinghuang-turn") > 0 then
        local nums = {1, 2, 3, 4}
        table.removeOne(nums, i)
        doTaji(player, table.random(nums))
      end
    end
  end,
}
local taji_trigger = fk.CreateTriggerSkill{
  name = "#taji_trigger",
  mute = true,
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and data.to ~= player and player:getMark("@taji") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + player:getMark("@taji")
    player.room:setPlayerMark(player, "@taji", 0)
  end,
}
local qinghuang = fk.CreateTriggerSkill{
  name = "qinghuang",
  anim_type = "special",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#qinghuang-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if not player.dead then
      room:setPlayerMark(player, "@@qinghuang-turn", 1)
    end
  end,
}
taji:addRelatedSkill(taji_trigger)
sunhanhua:addSkill(huiling)
sunhanhua:addSkill(chongxu)
sunhanhua:addRelatedSkill(taji)
sunhanhua:addRelatedSkill(qinghuang)
Fk:loadTranslationTable{
  ["ty__sunhanhua"] = "孙寒华",
  ["#ty__sunhanhua"] = "青丝慧剑",
  ["designer:ty__sunhanhua"] = "韩旭",
  ["illustrator:ty__sunhanhua"] = "鬼宿一",
  ["huiling"] = "汇灵",
  [":huiling"] = "锁定技，你使用牌时，若弃牌堆中的红色牌数量多于黑色牌，你回复1点体力；"..
  "黑色牌数量多于红色牌，你可以弃置一名其他角色区域内的一张牌；牌数较少的颜色与你使用牌的颜色相同，你获得一个“灵”标记。",
  ["chongxu"] = "冲虚",
  [":chongxu"] = "限定技，出牌阶段，若“灵”的数量不小于4，你可以失去〖汇灵〗，增加等量的体力上限，并获得〖踏寂〗和〖清荒〗。",
  ["taji"] = "踏寂",
  [":taji"] = "当你失去手牌后，你根据此牌的失去方式执行效果：<br>使用-弃置一名其他角色一张牌；<br>打出-摸一张牌；<br>弃置-回复1点体力；<br>"..
  "其他-你下次对其他角色造成的伤害+1。",
  ["qinghuang"] = "清荒",
  [":qinghuang"] = "出牌阶段开始时，你可以减1点体力上限，然后你本回合发动〖踏寂〗时随机额外执行一种效果。",
  ["@ty__sunhanhua_ling"] = "灵",
  ["#huiling-choose"] = "汇灵：你可以弃置一名其他角色区域内的一张牌",
  ["#chongxu"] = "冲虚：你可以失去〖汇灵〗，加%arg点体力上限，获得〖踏寂〗和〖清荒〗",
  ["@taji"] = "踏寂",
  ["#taji-choose"] = "踏寂：你可以弃置一名其他角色一张牌",
  ["#taji_trigger"] = "踏寂",
  ["#qinghuang-invoke"] = "清荒：你可以减1点体力上限，令你本回合发动〖踏寂〗时随机额外执行一种效果",
  ["@@qinghuang-turn"] = "清荒",

  ["$huiling1"] = "天地有灵，汇于我眸间。",
  ["$huiling2"] = "撷四时钟灵，拈芳兰毓秀。",
  ["$chongxu1"] = "慕圣道冲虚，有求者皆应。",
  ["$chongxu2"] = "养志无为，遗冲虚于物外。",
  ["$taji1"] = "仙途本寂寥，结发叹长生。",
  ["$taji2"] = "仙者不言，手执春风。",
  ["$qinghuang1"] = "上士无争，焉生妄心。",
  ["$qinghuang2"] = "心有草木，何畏荒芜？",
  ["~ty__sunhanhua"] = "长生不长乐，悔觅仙途……",
}

local zhenghun = General(extension, "zhenghun", "wei", 3)
local qiangzhiz = fk.CreateActiveSkill{
  name = "qiangzhiz",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and
      #Fk:currentRoom():getPlayerById(to_select):getCardIds{Player.Hand, Player.Equip} + #Self:getCardIds{Player.Hand, Player.Equip} > 2
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local card_data = {}
    if #target:getCardIds(Player.Hand) > 0 then
      local handcards = {}
      --FIXME：如何手动判定自动明牌的逻辑？
      for _ = 1, #target:getCardIds(Player.Hand), 1 do
        table.insert(handcards, -1)
      end
      table.insert(card_data, { "needhand", handcards })
    end
    if #target:getCardIds(Player.Equip) > 0 then
      table.insert(card_data, { "needequip", target:getCardIds(Player.Equip) })
    end
    if #player:getCardIds(Player.Hand) > 0 then
      table.insert(card_data, { "wordhand", player:getCardIds(Player.Hand) })
    end
    if #player:getCardIds(Player.Equip) > 0 then
      table.insert(card_data, { "wordequip", player:getCardIds(Player.Equip) })
    end
    local cards = room:askForCardsChosen(player, target, 3, 3, { card_data = card_data }, self.name)
    local cards1 = table.filter(cards, function(id) return table.contains(player:getCardIds{Player.Hand, Player.Equip}, id) end)
    local cards2 = table.filter(cards, function(id) return table.contains(target:getCardIds{Player.Hand, Player.Equip}, id) end)
    local moveInfos = {}
    if #cards1 > 0 then
      table.insert(moveInfos, {
        from = player.id,
        ids = cards1,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonDiscard,
        proposer = effect.from,
        skillName = self.name,
      })
    end
    if #cards2 > 0 then
      table.insert(moveInfos, {
        from = target.id,
        ids = cards2,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonDiscard,
        proposer = effect.from,
        skillName = self.name,
      })
    end
    room:moveCards(table.unpack(moveInfos))
    if not player.dead and not target.dead then
      if #cards1 == 3 then
        room:damage{
          from = player,
          to = target,
          damage = 1,
          skillName = self.name,
        }
      elseif #cards2 == 3 then
        room:damage{
          from = target,
          to = player,
          damage = 1,
          skillName = self.name,
        }
      end
    end
  end,
}
local pitian = fk.CreateTriggerSkill{
  name = "pitian",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove, fk.Damaged, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.AfterCardsMove then
        for _, move in ipairs(data) do
          if move.from == player.id and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerEquip or info.fromArea == Card.PlayerHand then
                return true
              end
            end
          end
        end
      elseif event == fk.Damaged then
        return target == player
      else
        return target == player and player.phase == Player.Finish and player:getHandcardNum() < player:getMaxCards()
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return player.room:askForSkillInvoke(player, self.name, nil, "#pitian-invoke")
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      player:drawCards(math.min(player:getMaxCards() - player:getHandcardNum(), 5), self.name)
      player.room:setPlayerMark(player, "@pitian", 0)
    else
      player.room:addPlayerMark(player, "@pitian", 1)
      player.room:broadcastProperty(player, "MaxCards")
    end
  end,
}
local pitian_maxcards = fk.CreateMaxCardsSkill{
  name = "#pitian_maxcards",
  correct_func = function(self, player)
    return player:getMark("@pitian")
  end,
}
pitian:addRelatedSkill(pitian_maxcards)
zhenghun:addSkill(qiangzhiz)
zhenghun:addSkill(pitian)
Fk:loadTranslationTable{
  ["zhenghun"] = "郑浑",
  ["#zhenghun"] = "民安寇灭",
  ["designer:zhenghun"] = "黑寡妇无敌",
  ["illustrator:zhenghun"] = "青雨",
  ["qiangzhiz"] = "强峙",
  [":qiangzhiz"] = "出牌阶段限一次，你可以弃置你和一名其他角色共计三张牌。若有角色因此弃置三张牌，其对另一名角色造成1点伤害。",
  ["pitian"] = "辟田",
  [":pitian"] = "当你的牌因弃置而进入弃牌堆后或当你受到伤害后，你的手牌上限+1。结束阶段，若你的手牌数小于手牌上限，"..
  "你可以将手牌摸至手牌上限（最多摸五张），然后重置因此技能而增加的手牌上限。",
  ["#qiangzhiz-choose"] = "强峙：弃置双方共计三张牌",
  ["#pitian-invoke"] = "辟田：你可以将手牌摸至手牌上限，然后重置本技能增加的手牌上限",
  ["@pitian"] = "辟田",

  ["wordhand"] = "我的手牌",
  ["wordequip"] = "我的装备",
  ["needhand"] = "对方手牌",
  ["needequip"] = "对方装备",

  ["$qiangzhiz1"] = "吾民在后，岂惧尔等魍魉。",
  ["$qiangzhiz2"] = "凶兵来袭，当长戈相迎。",
  ["$pitian1"] = "此间辟地数旬，必成良田千亩。",
  ["$pitian2"] = "民以物力为天，物力唯田可得。",
  ["~zhenghun"] = "此世为官，未辱青天之名……",
}

local liuchongluojun = General(extension, "liuchongluojun", "qun", 3)
local minze = fk.CreateActiveSkill{
  name = "minze",
  anim_type = "support",
  min_card_num = 1,
  max_card_num = 2,
  target_num = 1,
  can_use = function(self, player)
    return player:getMark("@@minze-phase") == 0 and not player:isNude()
  end,
  card_filter = function(self, to_select, selected)
    if #selected == 0 then
      return true
    elseif #selected == 1 then
      return Fk:getCardById(to_select).trueName ~= Fk:getCardById(selected[1]).trueName
    end
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and Self:getHandcardNum() > target:getHandcardNum()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local mark = player:getMark("@$minze-turn")
    if mark == 0 then mark = {} end
    for _, id in ipairs(effect.cards) do
      table.insertIfNeed(mark, Fk:getCardById(id).trueName)
    end
    room:setPlayerMark(player, "@$minze-turn", mark)
    room:setPlayerMark(target, "minze-phase", 1)
    room:obtainCard(target, effect.cards, false, fk.ReasonGive, player.id)
  end,
}
local minze_trigger = fk.CreateTriggerSkill{
  name = "#minze_trigger",
  mute = true,
  events = {fk.EventPhaseStart},
  main_skill = minze,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(minze) and player.phase == Player.Finish and
      player:getMark("@$minze-turn") ~= 0 and player:getHandcardNum() < math.min(#player:getMark("@$minze-turn"), 5)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("minze")
    room:notifySkillInvoked(player, "minze", "drawcard")
    player:drawCards(math.min(#player:getMark("@$minze-turn"), 5) - player:getHandcardNum(), "minze")
  end,
}
local jini = fk.CreateTriggerSkill{
  name = "jini",
  anim_type = "masochism",
  events ={fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and not player:isKongcheng() and player:getMark("jini-turn") < player.maxHp
  end,
  on_cost = function(self, event, target, player, data)
    local n = player.maxHp - player:getMark("jini-turn")
    local prompt = "#jini1-invoke:::"..n
    if data.from and data.from ~= player and not data.from.dead then
      prompt = "#jini2-invoke::"..data.from.id..":"..n
    end
    local cards = player.room:askForCard(player, 1, n, false, self.name, true, ".", prompt)
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = #self.cost_data
    room:moveCards({
      ids = self.cost_data,
      from = player.id,
      toArea = Card.DiscardPile,
      skillName = self.name,
      moveReason = fk.ReasonPutIntoDiscardPile,
      proposer = target.id
    })
    room:sendLog{
      type = "#RecastBySkill",
      from = player.id,
      card = self.cost_data,
      arg = self.name,
    }
    local cards = player:drawCards(n, self.name)
    room:addPlayerMark(player, "jini-turn", n)
    if player.dead or not data.from or data.from == player or data.from.dead then return end
    if table.find(cards, function(id) return Fk:getCardById(id, true).trueName == "slash" end) then
      local use = room:askForUseCard(player, "slash", "slash", "#jini-slash::"..data.from.id, true,
        {must_targets = {data.from.id}, bypass_distances = true, bypass_times = true})
      if use then
        use.disresponsiveList = {data.from.id}
        room:useCard(use)
      end
    end
  end,
}
minze:addRelatedSkill(minze_trigger)
liuchongluojun:addSkill(minze)
liuchongluojun:addSkill(jini)
Fk:loadTranslationTable{
  ["liuchongluojun"] = "刘宠骆俊",
  ["#liuchongluojun"] = "定境安民",
  ["designer:liuchongluojun"] = "坑坑",
  ["illustrator:liuchongluojun"] = "匠人绘",
  ["minze"] = "悯泽",
  [":minze"] = "出牌阶段每名角色限一次，你可以将至多两张牌名不同的牌交给一名手牌数小于你的角色。"..
  "结束阶段，你将手牌补至X张（X为本回合你因此技能失去牌的牌名数，至多为5）。",
  ["jini"] = "击逆",
  [":jini"] = "当你受到伤害后，你可以重铸任意张手牌（每回合以此法重铸的牌数不能超过你的体力上限），若你以此法获得了【杀】，"..
  "你可以对伤害来源使用一张无距离限制且不可响应的【杀】。",
  ["@@minze-phase"] = "悯泽失效",
  ["@$minze-turn"] = "悯泽",
  ["#jini1-invoke"] = "击逆：你可以重铸至多%arg张手牌",
  ["#jini2-invoke"] = "击逆：你可以重铸至多%arg张手牌，若摸到了【杀】，你可以对 %dest 使用一张无距离限制且不可响应的【杀】",
  ["#jini-slash"] = "击逆：你可以对 %dest 使用一张无距离限制且不可响应的【杀】",

  ["$minze1"] = "百姓千载皆苦，勿以苛政待之。",
  ["$minze2"] = "黎庶待哺，人主当施恩德泽。",
  ["$jini1"] = "备劲弩强刃，待恶客上门。",
  ["$jini2"] = "逆贼犯境，诸君当共击之。",
  ["~liuchongluojun"] = "袁术贼子，折我大汉基业……",
}

local wupu = General(extension, "wupu", "qun", 4)
local duanti = fk.CreateTriggerSkill{
  name = "duanti",
  events = {fk.CardUseFinished, fk.CardRespondFinished},
  frequency = Skill.Compulsory,
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("@duanti") < 4 then
      room:addPlayerMark(player, "@duanti")
      return false
    else
      room:setPlayerMark(player, "@duanti", 0)
    end
    if player:isWounded() then
      room:recover{
        who = player,
        recoverBy = player,
        num = 1,
        skillName = self.name
      }
      if player.dead then return false end
    end
    if player:getMark("duanti_addmaxhp") < 5 then
      room:addPlayerMark(player, "duanti_addmaxhp")
      room:changeMaxHp(player, 1)
    end
  end,

  refresh_events = {fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@duanti", 0)
    player.room:setPlayerMark(player, "duanti_addmaxhp", 0)
  end,
}
local shicao = fk.CreateActiveSkill{
  name = "shicao",
  anim_type = "drawcard",
  card_num = 0,
  target_num = 0,
  prompt = "#shicao-active",
  can_use = function(self, player)
    return player:getMark("@@shicao-turn") == 0 and player:usedSkillTimes(self.name) < 20
  end,
  interaction = function()
    return UI.ComboBox {choices = {
      "shicao_type:::basic:Top", "shicao_type:::basic:Bottom",
      "shicao_type:::trick:Top", "shicao_type:::trick:Bottom",
      "shicao_type:::equip:Top", "shicao_type:::equip:Bottom",
    } }
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local shicao_type = self.interaction.data:split(":")
    local from_place = shicao_type[5]:lower()
    local ids = room:drawCards(player, 1, self.name, from_place)
    if #ids == 0 or player.dead then return end
    if Fk:getCardById(ids[1]):getTypeString() ~= shicao_type[4] then
      if from_place == "top" then
        ids = room:getNCards(2, "bottom")
        table.insertTable(room.draw_pile, ids)
      else
        ids = room:getNCards(2)
        table.insert(room.draw_pile, 1, ids[2])
        table.insert(room.draw_pile, 1, ids[1])
      end
      U.viewCards(player, ids, self.name)
      room:setPlayerMark(player, "@@shicao-turn", 1)
    end
  end,
}
wupu:addSkill(duanti)
wupu:addSkill(shicao)

Fk:loadTranslationTable{
  ["wupu"] = "吴普",
  ["#wupu"] = "健体养魄",
  --["designer:wupu"] = "",
  --["illustrator:wupu"] = "",
  ["duanti"] = "锻体",
  [":duanti"] = "锁定技，当你每使用或打出五张牌结算结束后，你回复1点体力，加1点体力上限（最多加5）。",
  ["shicao"] = "识草",
  [":shicao"] = "出牌阶段，你可以声明一种类别，从牌堆顶/牌堆底摸一张牌，"..
  "若此牌不为你声明的类别，你观看牌堆底/牌堆顶的两张牌，此技能于此回合内无效。",

  ["@duanti"] = "锻体",
  ["#shicao-active"] = "发动 识草，选择牌的类别和摸牌的位置",
  ["shicao_type"] = "%arg | %arg2",
  ["@@shicao-turn"] = "识草 无效",

  ["$duanti1"] = "流水不腐，户枢不蠹。",
  ["$duanti2"] = "五禽锻体，百病不侵。",
  ["$shicao1"] = "药长于草木，然草木非皆可入药。",
  ["$shicao2"] = "掌中非药，乃活人之根本。",
  ["~wupu"] = "医者，不可使人长生……",
}

--纵横捭阖：陆郁生 祢衡 华歆 荀谌 冯熙 邓芝 宗预 羊祜
local luyusheng = General(extension, "luyusheng", "wu", 3, 3, General.Female)
local zhente = fk.CreateTriggerSkill{
  name = "zhente",
  anim_type = "defensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player:usedSkillTimes(self.name) == 0 and data.from ~= player.id then
      return data.card:isCommonTrick() or data.card.type == Card.TypeBasic
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askForSkillInvoke(player, self.name, nil,
    "#zhente-invoke:".. data.from .. "::" .. data.card:toLogString() .. ":" .. data.card:getColorString()) then
      player.room:doIndicate(player.id, {data.from})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.from)
    local color = data.card:getColorString()
    local choice = room:askForChoice(to, {
      "zhente_negate::" .. tostring(player.id) .. ":" .. data.card.name,
      "zhente_colorlimit:::" .. color
    }, self.name)
    if choice:startsWith("zhente_negate") then
      table.insertIfNeed(data.nullifiedTargets, player.id)
    else
      local colorsRecorded = type(to:getMark("@zhente-turn")) == "table" and to:getMark("@zhente-turn") or {}
      table.insertIfNeed(colorsRecorded, color)
      room:setPlayerMark(to, "@zhente-turn", colorsRecorded)
    end
  end,
}
local zhente_prohibit = fk.CreateProhibitSkill{
  name = "#zhente_prohibit",
  prohibit_use = function(self, player, card)
    local mark = player:getMark("@zhente-turn")
    return type(mark) == "table" and table.contains(mark, card:getColorString())
  end,
}
local zhiwei = fk.CreateTriggerSkill{
  name = "zhiwei",
  events = {fk.GameStart, fk.TurnStart, fk.AfterCardsMove, fk.Damage, fk.Damaged},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.GameStart then
        return true
      elseif event == fk.TurnStart then
        return player == target and player:getMark(self.name) == 0
      elseif event == fk.AfterCardsMove then
        if player.phase ~= Player.Discard then return false end
        local zhiwei_id = player:getMark(self.name)
        if zhiwei_id == 0 then return false end
        local room = player.room
        local to = room:getPlayerById(zhiwei_id)
        if to == nil or to.dead then return false end
        for _, move in ipairs(data) do
          if move.from == player.id and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
              room:getCardArea(info.cardId) == Card.DiscardPile then
                return true
              end
            end
          end
        end
      elseif event == fk.Damage then
        return target ~= nil and not target.dead and player:getMark(self.name) == target.id
      elseif event == fk.Damaged then
        return target ~= nil and not target.dead and player:getMark(self.name) == target.id and not player:isKongcheng()
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.TurnStart then
      local room = player.room
      local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#zhiwei-choose", self.name, true, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
      return false
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnStart then
      room:notifySkillInvoked(player, self.name, "special")
      player:broadcastSkillInvoke(self.name)
      room:setPlayerMark(player, self.name, self.cost_data)
    elseif event == fk.GameStart then
      room:notifySkillInvoked(player, self.name, "special")
      player:broadcastSkillInvoke(self.name)
      local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
      if #targets == 0 then return false end
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#zhiwei-choose", self.name, false, true)
      if #to > 0 then
        room:setPlayerMark(player, self.name, to[1])
      end
    elseif event == fk.AfterCardsMove then
      local zhiwei_id = player:getMark(self.name)
      if zhiwei_id == 0 then return false end
      local to = room:getPlayerById(zhiwei_id)
      if to == nil or to.dead then return false end
      local cards = {}
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
            room:getCardArea(info.cardId) == Card.DiscardPile then
              table.insertIfNeed(cards, info.cardId)
            end
          end
        end
      end
      if #cards > 0 then
        room:notifySkillInvoked(player, self.name, "support")
        player:broadcastSkillInvoke(self.name)
        room:setPlayerMark(player, "@zhiwei", to.general)
        room:moveCards({
        ids = cards,
        to = zhiwei_id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = self.name,
      })
      end
    elseif event == fk.Damage then
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:broadcastSkillInvoke(self.name)
      room:setPlayerMark(player, "@zhiwei", target.general)
      room:drawCards(player, 1, self.name)
    elseif event == fk.Damaged then
      local cards = player:getCardIds(Player.Hand)
      if #cards > 0 then
        room:notifySkillInvoked(player, self.name, "negative")
        player:broadcastSkillInvoke(self.name)
        room:setPlayerMark(player, "@zhiwei", target.general)
        room:throwCard(table.random(cards, 1), self.name, player, player)
      end
    end
  end,

  refresh_events = {fk.BuryVictim},
  can_refresh = function(self, event, target, player, data)
    return player:getMark(self.name) == target.id
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, self.name, 0)
    room:setPlayerMark(player, "@zhiwei", 0)
  end,
}
zhente:addRelatedSkill(zhente_prohibit)
luyusheng:addSkill(zhente)
luyusheng:addSkill(zhiwei)
Fk:loadTranslationTable{
  ["luyusheng"] = "陆郁生",
  ["#luyusheng"] = "义姑",
  ["illustrator:luyusheng"] = "君桓文化",
  ["zhente"] = "贞特",
  [":zhente"] = "每名角色的回合限一次，当你成为其他角色使用基本牌或普通锦囊牌的目标后，你可令其选择一项：1.本回合不能再使用此颜色的牌；2.此牌对你无效。",
  ["zhiwei"] = "至微",
  [":zhiwei"] = "游戏开始时，你选择一名其他角色，该角色造成伤害后，你摸一张牌；该角色受到伤害后，你随机弃置一张手牌。"..
  "你弃牌阶段弃置的牌均被该角色获得。准备阶段，若场上没有“至微”角色，你可以重新选择一名其他角色。",
  --实测：目标死亡时（具体时机不确定）会发动一次技能，推测是清理标记
  --实测：只在目标死亡的下个准备阶段（具体时机不确定）可以重新选择角色，若取消则此后不会再询问了
  --懒得按这个逻辑做

  ["#zhente-invoke"] = "是否使用贞特，令%src选择令【%arg】对你无效或不能再使用%arg2牌",
  ["zhente_negate"] = "令【%arg】对%dest无效",
  ["zhente_colorlimit"] = "本回合不能再使用%arg牌",
  ["@zhente-turn"] = "贞特",
  ["#zhiwei-choose"] = "至微：选择一名其他角色",
  ["@zhiwei"] = "至微",

  ["$zhente1"] = "抗声昭节，义形于色。",
  ["$zhente2"] = "少履贞特之行，三从四德。",
  ["$zhiwei1"] = "体信贯于神明，送终以礼。",
  ["$zhiwei2"] = "昭德以行，生不能侍奉二主。",
  ["~luyusheng"] = "父亲，郁生甚是想念……",
}

local miheng = General(extension, "ty__miheng", "qun", 3)
local kuangcai = fk.CreateTriggerSkill{
  name = "kuangcai",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if player.phase == Player.Discard then
        local used = #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
          local use = e.data[1]
          return use.from == player.id
        end, Player.HistoryTurn) > 0
        if not used then
          self.cost_data = "noused"
          return true
        elseif  #U.getActualDamageEvents(player.room, 1, function(e) return e.data[1].from == player end) == 0 then
          self.cost_data = "used"
          return true
        end
      elseif player.phase == Player.Finish then
        local n = 0
        U.getActualDamageEvents(player.room, 1, function(e)
          if e.data[1].from == player then
            n = n + e.data[1].damage
          end
        end)
        if n > 0 then
          self.cost_data = n
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if player.phase == Player.Discard then
      if self.cost_data == "noused" then
        room:notifySkillInvoked(player, self.name, "support")
        room:addPlayerMark(player, MarkEnum.AddMaxCards, 1)
      else
        room:notifySkillInvoked(player, self.name, "negative")
        room:addPlayerMark(player, MarkEnum.MinusMaxCards, 1)
      end
      room:broadcastProperty(player, "MaxCards")
    elseif player.phase == Player.Finish then
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:drawCards(math.min(self.cost_data, 5))
    end
  end,
}
local kuangcai_targetmod = fk.CreateTargetModSkill{
  name = "#kuangcai_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return player:hasSkill("kuangcai") and player.phase ~= Player.NotActive
  end,
  bypass_distances = function(self, player, skill, card, to)
    return player:hasSkill("kuangcai") and player.phase ~= Player.NotActive
  end,
}
local shejian = fk.CreateTriggerSkill{
  name = "shejian",
  anim_type = "control",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from ~= player.id and #AimGroup:getAllTargets(data.tos) == 1 and
      #player:getCardIds("he") > 1 and player:usedSkillTimes(self.name, Player.HistoryTurn) < 2
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForDiscard(player, 2, 999, false, self.name, true, ".|.|.|hand", "#shejian-card::"..data.from, true)
    if #cards > 1 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = room:getPlayerById(data.from)
    local n = #self.cost_data
    room:throwCard(self.cost_data, self.name, player, player)
    if not (player.dead or from.dead) then
      room:doIndicate(player.id, {data.from})
      local choices = {"damage1"}
      if #from:getCardIds("he") >= n then
        table.insert(choices, 1, "discard_skill")
      end
      local choice = room:askForChoice(player, choices, self.name, "#shejian-choice::"..data.from)
      if choice == "discard_skill" then
        local cards = room:askForCardsChosen(player, from, n, n, "he", self.name)
        room:throwCard(cards, self.name, from, player)
      else
        room:damage{
          from = player,
          to = from,
          damage = 1,
          skillName = self.name
        }
      end
    end
  end,
}
kuangcai:addRelatedSkill(kuangcai_targetmod)
miheng:addSkill(kuangcai)
miheng:addSkill(shejian)
Fk:loadTranslationTable{
  ["ty__miheng"] = "祢衡",
  ["#ty__miheng"] = "狂傲奇人",
  ["cv:ty__miheng"] = "虞晓旭",
  ["illustrator:ty__miheng"] = "鬼画府",
  ["kuangcai"] = "狂才",
  [":kuangcai"] = "①锁定技，你的回合内，你使用牌无距离和次数限制。<br>②弃牌阶段开始时，若你本回合：没有使用过牌，你的手牌上限+1；"..
  "使用过牌且没有造成伤害，你手牌上限-1。<br>③结束阶段，若你本回合造成过伤害，你摸等于伤害值数量的牌（最多摸五张）。",
  ["shejian"] = "舌剑",
  [":shejian"] = "每回合限两次，当你成为其他角色使用牌的唯一目标后，你可以弃置至少两张手牌，然后弃置其等量的牌或对其造成1点伤害。",
  ["#shejian-card"] = "舌剑：你可以弃置至少两张手牌，弃置 %dest 等量的牌或对其造成1点伤害",
  ["damage1"] = "造成1点伤害",
  ["#shejian-choice"] = "舌剑：选择对 %dest 执行的一项",

  ["$kuangcai1"] = "耳所瞥闻，不忘于心。",
  ["$kuangcai2"] = "吾焉能从屠沽儿耶？",
  ["$shejian1"] = "伤人的，可不止刀剑！",
  ["$shejian2"] = "死公！云等道？",
  ["~ty__miheng"] = "恶口……终至杀身……",
}

local huaxin = General(extension, "ty__huaxin", "wei", 3)
local wanggui = fk.CreateTriggerSkill{
  name = "wanggui",
  mute = true,
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      return (event == fk.Damage and player:getMark("wanggui-turn") == 0) or event == fk.Damaged
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets, prompt = {}, ""
    if event == fk.Damage then
      targets = table.map(table.filter(room.alive_players, function(p)
        return p.kingdom ~= player.kingdom end), Util.IdMapper)
      prompt = "#wanggui1-choose"
    else
      targets = table.map(table.filter(room.alive_players, function(p)
        return p.kingdom == player.kingdom end), Util.IdMapper)
      prompt = "#wanggui2-choose"
    end
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, prompt, self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    if event == fk.Damage then
      room:setPlayerMark(player, "wanggui-turn", 1)
      room:damage{
        from = player,
        to = to,
        damage = 1,
        skillName = self.name,
      }
    else
      to:drawCards(1, self.name)
      if to ~= player then
        player:drawCards(1, self.name)
      end
    end
  end,
}
local xibing = fk.CreateTriggerSkill{
  name = "xibing",
  anim_type = "control",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and target.phase == Player.Play and data.firstTarget and
      data.card.color == Card.Black and (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      target:getHandcardNum() < math.min(target.hp, 5) and #AimGroup:getAllTargets(data.tos) == 1 and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#xibing-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    player.room:doIndicate(player.id, {target.id})
    target:drawCards(math.min(target.hp, 5) - target:getHandcardNum())
    player.room:setPlayerMark(target, "xibing-turn", 1)
  end,
}
local xibing_prohibit = fk.CreateProhibitSkill{
  name = "#xibing_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("xibing-turn") > 0
  end,
}
xibing:addRelatedSkill(xibing_prohibit)
huaxin:addSkill(wanggui)
huaxin:addSkill(xibing)
Fk:loadTranslationTable{
  ["ty__huaxin"] = "华歆",
  ["#ty__huaxin"] = "渊清玉洁",
  ["illustrator:ty__huaxin"] = "秋呆呆",
  ["wanggui"] = "望归",
  [":wanggui"] = "当你造成伤害后，你可以对与你势力不同的一名角色造成1点伤害（每回合限一次）；当你受到伤害后，你可令一名与你势力相同的角色摸一张牌，"..
  "若不为你，你也摸一张牌。",
  ["xibing"] = "息兵",
  [":xibing"] = "每回合限一次，当一名其他角色在其出牌阶段内使用黑色【杀】或黑色普通锦囊牌指定唯一角色为目标后，你可令该角色将手牌摸至体力值"..
  "（至多摸至五张），然后其本回合不能再使用牌。",
  ["#wanggui1-choose"] = "望归：你可以对一名势力与你不同的角色造成1点伤害",
  ["#wanggui2-choose"] = "望归：你可以令一名势力与你相同的角色摸一张牌，若不为你，你也摸一张牌",
  ["#xibing-invoke"] = "息兵：你可以令 %dest 将手牌摸至体力值（至多五张），然后其本回合不能使用牌",
  
  ["$wanggui1"] = "存志太虚，安心玄妙。",
  ["$wanggui2"] = "礼法有度，良德才略。",
  ["$xibing1"] = "千里运粮，非用兵之利。",
  ["$xibing2"] = "宜弘一代之治，绍三王之迹。",
  ["~ty__huaxin"] = "大举发兵，劳民伤国。",
}

local xunchen = General(extension, "ty__xunchen", "qun", 3)
local ty__fenglue = fk.CreateActiveSkill{
  name = "ty__fenglue",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Self:canPindian(Fk:currentRoom():getPlayerById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.tos[1])
    local pindian = player:pindian({to}, self.name)
    local winner = pindian.results[to.id].winner
    if winner == player then
      if to:isAllNude() or player.dead then return end
      local cards = to:getCardIds("hej")
      if #cards > 2 then
        cards = room:askForCardsChosen(player, to, 2, 2, "hej", self.name)
      end
      room:obtainCard(player, cards, false, fk.ReasonPrey)
    elseif winner == to then
      if room:getCardArea(pindian.fromCard) == Card.DiscardPile and not to.dead then
        room:obtainCard(to, pindian.fromCard, true, fk.ReasonPrey)
      end
    elseif not player.dead then
      if room:getCardArea(pindian.fromCard) == Card.DiscardPile then
        room:obtainCard(player, pindian.fromCard, true, fk.ReasonPrey)
      end
      player:setSkillUseHistory(self.name, 0, Player.HistoryPhase)
    end
  end,
}
local anyong = fk.CreateTriggerSkill{
  name = "anyong",
  anim_type = "offensive",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and not player:isNude() and target and target == player.room.current and not data.to.dead and data.damage == 1 then
      local dat = U.getActualDamageEvents(player.room, 1, function(e) return e.data[1].from == target end)
      return #dat > 0 and dat[1].data[1] == data
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#anyong-invoke::"..data.to.id, true)
    if #card > 0 then
      room:doIndicate(player.id, {data.to.id})
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    if data.to.dead then return false end
    room:damage{
      from = player,
      to = data.to,
      damage = 1,
      skillName = self.name,
    }
  end,
}
xunchen:addSkill(ty__fenglue)
xunchen:addSkill(anyong)
Fk:loadTranslationTable{
  ["ty__xunchen"] = "荀谌",
  ["#ty__xunchen"] = "三公谋主",
  ["illustrator:ty__xunchen"] = "凝聚永恒",

  ["ty__fenglue"] = "锋略",
  [":ty__fenglue"] = "出牌阶段限一次，你可以和一名角色拼点。若：你赢，你获得其区域里的两张牌；"..
  "你与其均没赢，你获得你的拼点牌且此技能视为未发动过；其赢，其获得你拼点的牌。",
  ["#ty__fenglue-give"] = "锋略：请选择你区域内的两张牌交给 %src",
  ["anyong"] = "暗涌",
  [":anyong"] = "当一名角色于其回合内第一次造成伤害后，若此伤害值为1，你可以弃置一张牌对受到伤害的角色造成1点伤害。",
  ["#anyong-invoke"] = "暗涌：你可以弃置一张牌，对 %dest 造成1点伤害",

  ["$ty__fenglue1"] = "当今敢称贤者，唯袁氏本初一人！",
  ["$ty__fenglue2"] = "冀州宝地，本当贤者居之！",
  ["$anyong1"] = "殿上太守且相看，殿下几人还拥韩？",
  ["$anyong2"] = "冀州暗潮汹涌，群士居危思变。",
  ["~ty__xunchen"] = "为臣当不贰，贰臣不当为……",
}

local fengxi = General(extension, "fengxiw", "wu", 3)
local yusui = fk.CreateTriggerSkill{
  name = "yusui",
  anim_type = "offensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from ~= player.id and data.card.color == Card.Black and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.from)
    room:loseHp(player, 1, self.name)
    if player.dead or to.dead then return end
    local choices = {}
    if #to.player_cards[Player.Hand] > #player.player_cards[Player.Hand] then
      table.insert(choices, "yusui_discard")
    end
    if to.hp > player.hp then
      table.insert(choices, "yusui_loseHp")
    end
    if #choices > 0 then
      local choice = room:askForChoice(player, choices, self.name)
      if choice == "yusui_discard" then
        local n = #to.player_cards[Player.Hand] - #player.player_cards[Player.Hand]
        room:askForDiscard(to, n, n, false, self.name, false)
      else
        room:loseHp(to, to.hp - player.hp, self.name)
      end
    end
  end,
}
local boyan = fk.CreateActiveSkill{
  name = "boyan",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local n = math.min(target.maxHp, 5) - target:getHandcardNum()
    if n > 0 then
      target:drawCards(n, self.name)
    end
    room:setPlayerMark(target, "@@boyan-turn", 1)
  end,
}
local boyan_prohibit = fk.CreateProhibitSkill{
  name = "#boyan_prohibit",
  prohibit_use = function(self, player, card)
    if player:getMark("@@boyan-turn") > 0 then
      local cardlist = Card:getIdList(card)
      return #cardlist > 0 and table.every(cardlist, function(id)
        return table.contains(player:getCardIds(Player.Hand), id)
      end)
    end
  end,
  prohibit_response = function(self, player, card)
    if player:getMark("@@boyan-turn") > 0 then
      local cardlist = Card:getIdList(card)
      return #cardlist > 0 and table.every(cardlist, function(id)
        return table.contains(player:getCardIds(Player.Hand), id)
      end)
    end
  end,
}
boyan:addRelatedSkill(boyan_prohibit)
fengxi:addSkill(yusui)
fengxi:addSkill(boyan)
Fk:loadTranslationTable{
  ["fengxiw"] = "冯熙",
  ["#fengxiw"] = "东吴苏武",
  ["illustrator:fengxiw"] = "匠人绘",
  ["yusui"] = "玉碎",
  [":yusui"] = "每回合限一次，当你成为其他角色使用黑色牌的目标后，你可以失去1点体力，然后选择一项：1.令其弃置手牌至与你相同；2.令其失去体力值至与你相同。",
  ["boyan"] = "驳言",
  [":boyan"] = "出牌阶段限一次，你可以选择一名其他角色，该角色将手牌摸至体力上限（最多摸至5张），其本回合不能使用或打出手牌。",
  ["yusui_discard"] = "令其弃置手牌至与你相同",
  ["yusui_loseHp"] = "令其失去体力值至与你相同",
  ["@@boyan-turn"] = "驳言",

  ["$yusui1"] = "宁为玉碎，不为瓦全！",
  ["$yusui2"] = "生义相左，舍生取义。",
  ["$boyan1"] = "黑白颠倒，汝言谬矣！",
  ["$boyan2"] = "魏王高论，实为无知之言。",
  ["~fengxiw"] = "乡音未改双鬓苍，身陷北国有义求。",
}

local dengzhi = General(extension, "ty__dengzhi", "shu", 3)
local jianliang = fk.CreateTriggerSkill{
  name = "jianliang",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Draw and
      not table.every(player.room.alive_players, function(p) return player:getHandcardNum() >= p:getHandcardNum() end)
  end,
  on_cost = function(self, event, target, player, data)
    local tos = player.room:askForChoosePlayers(player, table.map(player.room.alive_players,
      Util.IdMapper), 1, 2, "#jianliang-invoke", self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(self.cost_data) do
      local p = room:getPlayerById(id)
      if not p.dead then
        p:drawCards(1, self.name)
      end
    end
  end,
}
local weimeng = fk.CreateActiveSkill{
  name = "weimeng",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = function (self, selected, selected_cards)
    return "#weimeng:::"..Self.hp
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and player.hp > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cards = room:askForCardsChosen(player, target, 1, player.hp, "h", self.name)
    local n1 = 0
    for _, id in ipairs(cards) do
      n1 = n1 + Fk:getCardById(id).number
    end
    room:obtainCard(player, cards, false, fk.ReasonPrey)
    if player.dead or player:isNude() or target.dead then return end
    local cards2
    if #player:getCardIds("he") <= #cards then
      cards2 = player:getCardIds("he")
    else
      cards2 = room:askForCard(player, #cards, #cards, true, self.name, false, ".",
        "#weimeng-give::"..target.id..":"..#cards..":"..n1)
      if #cards2 < #cards then
        cards2 = table.random(player:getCardIds("he"), #cards)
      end
    end
    local n2 = 0
    for _, id in ipairs(cards2) do
      n2 = n2 + Fk:getCardById(id).number
    end
    room:obtainCard(target, cards2, false, fk.ReasonGive, player.id)
    if n1 < n2 then
      if not player.dead then
        player:drawCards(1, self.name)
      end
    elseif n1 > n2 then
      if not (player.dead or target.dead or target:isAllNude()) then
        local id = room:askForCardChosen(player, target, "hej", self.name)
        room:throwCard({id}, self.name, target, player)
      end
    end
  end,
}
dengzhi:addSkill(jianliang)
dengzhi:addSkill(weimeng)
Fk:loadTranslationTable{
  ["ty__dengzhi"] = "邓芝",
  ["#ty__dengzhi"] = "绝境的外交家",
  ["illustrator:ty__dengzhi"] = "凝聚永恒",
  ["jianliang"] = "简亮",
  [":jianliang"] = "摸牌阶段开始时，若你的手牌数不为全场最多，你可以令至多两名角色各摸一张牌。",
  ["weimeng"] = "危盟",
  [":weimeng"] = "出牌阶段限一次，你可以获得一名其他角色至多X张手牌，然后交给其等量的牌（X为你的体力值）。"..
  "若你给出的牌点数之和：大于获得的牌，你摸一张牌；小于获得的牌，你弃置其区域内一张牌。",
  ["#jianliang-invoke"] = "简亮：你可以令至多两名角色各摸一张牌",
  ["#weimeng"] = "危盟：获得一名其他角色至多%arg张牌，交还等量牌，根据点数执行效果",
  ["#weimeng-give"] = "危盟：交还 %dest %arg张牌，若点数大于%arg2则摸一张牌，若小于则弃置其一张牌",
  
  ["$jianliang1"] = "岂曰少衣食，与君共袍泽！",
  ["$jianliang2"] = "义士同心力，粮秣应期来！",
  ["$weimeng1"] = "此礼献于友邦，共赴兴汉大业！",
  ["$weimeng2"] = "吴有三江之守，何故委身侍魏？",
  ["~ty__dengzhi"] = "伯约啊，我帮不了你了……",
}

local zongyu = General(extension, "ty__zongyu", "shu", 3)
local qiao = fk.CreateTriggerSkill{
  name = "qiao",
  anim_type = "control",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from ~= player.id and
      not player.room:getPlayerById(data.from):isNude() and player:usedSkillTimes(self.name, Player.HistoryTurn) < 2
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#qiao-invoke::"..data.from)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = room:getPlayerById(data.from)
    local id = room:askForCardChosen(player, from, "he", self.name)
    room:throwCard({id}, self.name, from, player)
    if not player:isNude() then
      room:askForDiscard(player, 1, 1, true, self.name, false)
    end
  end,
}
local chengshang = fk.CreateTriggerSkill{
  name = "chengshang",
  anim_type = "drawcard",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and data.tos and
      table.find(TargetGroup:getRealTargets(data.tos), function(id) return id ~= player.id end) and not data.damageDealt and
      data.card.suit ~= Card.NoSuit and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil,
      "#chengshang-invoke:::"..data.card:getSuitString()..":"..tostring(data.card.number))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getCardsFromPileByRule(".|"..tostring(data.card.number).."|"..data.card:getSuitString())
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
    else
      player:setSkillUseHistory(self.name, 0, Player.HistoryPhase)
    end
  end,
}
zongyu:addSkill(qiao)
zongyu:addSkill(chengshang)
Fk:loadTranslationTable{
  ["ty__zongyu"] = "宗预",
  ["#ty__zongyu"] = "九酝鸿胪",
  ["illustrator:ty__zongyu"] = "铁杵文化",
  ["qiao"] = "气傲",
  [":qiao"] = "每回合限两次，当你成为其他角色使用牌的目标后，你可以弃置其一张牌，然后你弃置一张牌。",
  ["chengshang"] = "承赏",
  [":chengshang"] = "出牌阶段内限一次，你使用指定其他角色为目标的牌结算后，若此牌没有造成伤害，你可以获得牌堆中所有与此牌花色点数均相同的牌。"..
  "若你没有因此获得牌，此技能视为未发动过。",
  ["#qiao-invoke"] = "气傲：你可以弃置 %dest 一张牌，然后你弃置一张牌",
  ["#chengshang-invoke"] = "承赏：你可以获得牌堆中所有的%arg%arg2牌",
  
  ["$qiao1"] = "吾六十何为不受兵邪？",
  ["$qiao2"] = "芝性骄傲，吾独不为屈。",
  ["$chengshang1"] = "嘉其抗直，甚爱待之。",
  ["$chengshang2"] = "为国鞠躬，必受封赏。",
  ["~ty__zongyu"] = "吾年逾七十，唯少一死耳……",
}

local yanghu = General(extension, "ty__yanghu", "wei", 3)
local deshao = fk.CreateTriggerSkill{
  name = "deshao",
  anim_type = "defensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.color == Card.Black and
      data.from ~= player.id and player:usedSkillTimes(self.name, Player.HistoryTurn) < 2
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#deshao-invoke::"..data.from)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, self.name)
    local from = room:getPlayerById(data.from)
    if from:getHandcardNum() >= player:getHandcardNum() then
      local id = room:askForCardChosen(player, from, "he", self.name)
      room:throwCard(id, self.name, from, player)
    end
  end,
}
local mingfa = fk.CreateTriggerSkill{
  name = "mingfa",
  anim_type = "offensive",
  events = {fk.CardUseFinished, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.CardUseFinished then
        return target == player and player.phase == Player.Play and #player:getPile(self.name) == 0 and
          (data.card.trueName == "slash" or data.card:isCommonTrick()) and player.room:getCardArea(data.card) == Card.Processing and
          U.isPureCard(data.card) and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
      else
        return target.phase == Player.Finish and player:getMark(self.name) ~= 0 and #player:getPile(self.name) > 0 and
          player:getMark(self.name) == target.id
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.CardUseFinished then
      local room = player.room
      local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#mingfa-choose:::"..data.card:toLogString(), self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUseFinished then
      player:addToPile(self.name, data.card, true, self.name)
      room:setPlayerMark(player, self.name, self.cost_data)
      local to = room:getPlayerById(self.cost_data)
      local mark = to:getMark("@@mingfa")
      if mark == 0 then mark = {} end
      table.insert(mark, player.id)
      room:setPlayerMark(to, "@@mingfa", mark)
    else
      local card = Fk:cloneCard(Fk:getCardById(player:getPile(self.name)[1]).name)
      if card.trueName ~= "nullification" and card.skill:getMinTargetNum() < 2 and not player:isProhibited(target, card) then
        --据说没有合法性检测甚至无懈都能虚空用，甚至不合法目标还能触发贞烈。我不好说
        local n = math.max(target:getHandcardNum(), 1)
        n = math.min(n, 5)
        for i = 1, n, 1 do
          if target.dead then break end
          room:useCard({
            card = card,
            from = player.id,
            tos = {{target.id}},
            skillName = self.name,
          })
        end
      end
      room:setPlayerMark(player, self.name, 0)
      if not target.dead then
        local mark = U.getMark(target, "@@mingfa")
        table.removeOne(mark, player.id)
        room:setPlayerMark(target, "@@mingfa", #mark > 0 and mark or 0)
      end
      room:moveCards({
        from = player.id,
        ids = player:getPile(self.name),
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = self.name,
        specialName = self.name,
      })
    end
  end,

  refresh_events = {fk.EventLoseSkill, fk.Death},
  can_refresh = function(self, event, target, player, data)
    if #player:getPile(self.name) > 0 and player:getMark(self.name) ~= 0 then
      if event == fk.EventLoseSkill then
        return target == player and data == self
      else
        return target == player or target:getMark("@@mingfa") ~= 0
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventLoseSkill or (event == fk.Death and target == player) then
      local to = room:getPlayerById(player:getMark(self.name))
      room:setPlayerMark(player, self.name, 0)
      room:moveCards({
        from = player.id,
        ids = player:getPile(self.name),
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = self.name,
        specialName = self.name,
      })
      if not to.dead then
        local mark = U.getMark(to, "@@mingfa")
        table.removeOne(mark, player.id)
        room:setPlayerMark(to, "@@mingfa", #mark > 0 and mark or 0)
      end
    else
      local mark = target:getMark("@@mingfa")
      if table.contains(mark, player.id) then
        table.removeOne(mark, player.id)
        if #mark == 0 then mark = 0 end
        room:setPlayerMark(target, "@@mingfa", mark)
        room:setPlayerMark(player, self.name, 0)
        room:moveCards({
          from = player.id,
          ids = player:getPile(self.name),
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonPutIntoDiscardPile,
          skillName = self.name,
          specialName = self.name,
        })
      end
    end
  end,
}
yanghu:addSkill(deshao)
yanghu:addSkill(mingfa)
Fk:loadTranslationTable{
  ["ty__yanghu"] = "羊祜",
  ["#ty__yanghu"] = "制纮同轨",
  ["illustrator:ty__yanghu"] = "匠人绘",
  ["deshao"] = "德劭",
  [":deshao"] = "每回合限两次，当你成为其他角色使用黑色牌的目标后，你可以摸一张牌，然后若其手牌数大于等于你，你弃置其一张牌。",
  ["mingfa"] = "明伐",
  [":mingfa"] = "出牌阶段内限一次，你使用非转化的【杀】或普通锦囊牌结算完毕后，若你没有“明伐”牌，可将此牌置于武将牌上并选择一名其他角色。"..
  "该角色的结束阶段，视为你对其使用X张“明伐”牌（X为其手牌数，最少为1，最多为5），然后移去“明伐”牌。",
  ["#deshao-invoke"] = "德劭：你可以摸一张牌，然后若 %dest 手牌数不少于你，你弃置其一张牌",
  ["#mingfa-choose"] = "明伐：将%arg置为“明伐”，选择一名角色，其结束阶段视为对其使用其手牌张数次“明伐”牌",
  ["@@mingfa"] = "明伐",

  ["$deshao1"] = "名德远播，朝野俱瞻。",
  ["$deshao2"] = "增修德信，以诚服人。",
  ["$mingfa1"] = "煌煌大势，无须诈取。",
  ["$mingfa2"] = "开示公道，不为掩袭。",
  ["~ty__yanghu"] = "臣死之后，杜元凯可继之……",
}

--匡鼎炎汉：刘巴 黄权 吴班 霍峻 傅肜傅佥 向朗 高翔 杨仪 蒋琬费祎 李丰
local liuba = General(extension, "ty__liuba", "shu", 3)
local ty__zhubi = fk.CreateTriggerSkill{
  name = "ty__zhubi",
  anim_type = "control",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).suit == Card.Diamond then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#ty__zhubi-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getCardsFromPileByRule("ex_nihilo")
    if #cards > 0 then
      local id = cards[1]
      table.removeOne(room.draw_pile, id)
      table.insert(room.draw_pile, 1, id)
    else
      cards = room:getCardsFromPileByRule("ex_nihilo", 1, "discardPile")
      if #cards > 0 then
        room:moveCards({
          ids = cards,
          fromArea = Card.DiscardPile,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonPut,
          skillName = self.name,
        })
      end
    end
  end,
}
local liuzhuan = fk.CreateTriggerSkill{
  name = "liuzhuan",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    local room = player.room
    local current = room.current
    if current == player or current.phase == Player.NotActive then return false end
    local toMarked, toObtain = {}, {}
    local id
    for _, move in ipairs(data) do
      if current.phase ~= Player.Draw and move.to == current.id and move.toArea == Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
          id = info.cardId
          if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == current then
            table.insert(toMarked, id)
          end
        end
      end
      local mark = U.getMark(player, "liuzhuan_record-turn")
      if move.toArea == Card.DiscardPile and #mark > 0 then
        for _, info in ipairs(move.moveInfo) do
          id = info.cardId
          --for stupid manjuan
          if info.fromArea ~= Card.DiscardPile and table.removeOne(mark, id) and room:getCardArea(id) == Card.DiscardPile then
            table.insert(toObtain, id)
          end
        end
      end
      toObtain = U.moveCardsHoldingAreaCheck(room, toObtain)
      if #toMarked > 0 or #toObtain > 0 then
        self.cost_data = {toMarked, toObtain}
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local toMarked = table.simpleClone(self.cost_data[1])
    local toObtain = table.simpleClone(self.cost_data[2])
    local mark = U.getMark(player, "liuzhuan_record-turn")
    table.insertTableIfNeed(mark, toMarked)
    room:setPlayerMark(player, "liuzhuan_record-turn", mark)
    for _, id in ipairs(toMarked) do
      room:setCardMark(Fk:getCardById(id), "@@liuzhuan-inhand-turn", 1)
    end
    if #toObtain > 0 then
      room:moveCardTo(toObtain, Player.Hand, player, fk.ReasonJustMove, self.name, "", true, player.id)
    end
  end,

  refresh_events = {fk.AfterCardsMove, fk.Death},
  can_refresh = function(self, event, target, player, data)
    if event == fk.Death and player ~= target then return false end
    return #U.getMark(player, "liuzhuan_record-turn") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = U.getMark(player, "liuzhuan_record-turn")
    if event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.to ~= room.current.id and (move.toArea == Card.PlayerHand or move.toArea == Card.PlayerEquip) then
          for _, info in ipairs(move.moveInfo) do
            table.removeOne(mark, info.cardId)
          end
        end
      end
      room:setPlayerMark(player, "liuzhuan_record-turn", mark)
    elseif event == fk.Death then
      local card
      for _, id in ipairs(mark) do
        card = Fk:getCardById(id)
        if card:getMark("@@liuzhuan-inhand-turn") > 0 and table.every(room.alive_players, function (p)
          return not table.contains(U.getMark(p, "liuzhuan_record-turn"), id)
        end) then
          room:setCardMark(card, "@@liuzhuan-inhand-turn", 0)
        end
      end
    end
  end,
}
local liuzhuan_prohibit = fk.CreateProhibitSkill{
  name = "#liuzhuan_prohibit",
  is_prohibited = function(self, from, to, card)
    if not to:hasSkill(liuzhuan) then return false end
    local mark = U.getMark(to, "liuzhuan_record-turn")
    if #mark == 0 then return false end
    for _, id in ipairs(Card:getIdList(card)) do
      if table.contains(mark, id) and table.contains(from:getCardIds("he"), id) then
        return true
      end
    end
  end,
}
liuzhuan:addRelatedSkill(liuzhuan_prohibit)
liuba:addSkill(ty__zhubi)
liuba:addSkill(liuzhuan)
Fk:loadTranslationTable{
  ["ty__liuba"] = "刘巴",
  ["#ty__liuba"] = "清尚之节",
  ["designer:ty__liuba"] = "七哀",
  ["illustrator:ty__liuba"] = "匠人绘",
  ["ty__zhubi"] = "铸币",
  [":ty__zhubi"] = "当<font color='red'>♦</font>牌因弃置而进入弃牌堆后，你可从牌堆或弃牌堆将一张【无中生有】置于牌堆顶。",
  ["liuzhuan"] = "流转",
  [":liuzhuan"] = "锁定技，其他角色的回合内，其于摸牌阶段外获得的牌无法对你使用，这些牌本回合进入弃牌堆后，你获得之。",
  ["#ty__zhubi-invoke"] = "铸币：是否将一张【无中生有】置于牌堆顶？",
  ["@@liuzhuan-inhand-turn"] = "流转",

  ["$ty__zhubi1"] = "铸币平市，百货可居。",
  ["$ty__zhubi2"] = "做钱直百，府库皆实。",
  ["$liuzhuan1"] = "身似浮萍，随波逐流。",
  ["$liuzhuan2"] = "辗转四方，宦游八州。",
  ["~ty__liuba"] = "竹蕴于林，风必摧之。",
}

local huangquan = General(extension, "ty__huangquan", "shu", 3)
local quanjian = fk.CreateActiveSkill{
  name = "quanjian",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:getMark("quanjian1-phase") == 0 or player:getMark("quanjian2-phase") == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    if #selected == 0 and to_select ~= Self.id then
      if Self:getMark("quanjian2-phase") == 0 then
        return true
      else
        for _, p in ipairs(Fk:currentRoom().alive_players) do
          if Fk:currentRoom():getPlayerById(to_select):inMyAttackRange(p) then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(target)) do
      if target:inMyAttackRange(p) then
        table.insert(targets, p.id)
      end
    end
    local choices = {}
    if player:getMark("quanjian1-phase") == 0 and #targets > 0 then
      table.insert(choices, "quanjian1")
    end
    if player:getMark("quanjian2-phase") == 0 then
      table.insert(choices, "quanjian2")
    end
    local choice = room:askForChoice(player, choices, self.name)
    room:addPlayerMark(player, choice.."-phase", 1)
    local to
    if choice == "quanjian1" then
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#quanjian-choose", self.name)
      if #tos > 0 then
        to = tos[1]
      else
        to = table.random(targets)
      end
      room:doIndicate(target.id, {to})
    end
    local choices2 = {"quanjian_cancel"}
    if choice == "quanjian1" then
      table.insert(choices2, 1, "quanjian_damage")
    else
      table.insert(choices2, 1, "quanjian_draw")
    end
    local choice2 = room:askForChoice(target, choices2, self.name)
    if choice2 == "quanjian_damage" then
      room:damage{
        from = target,
        to = room:getPlayerById(to),
        damage = 1,
        skillName = self.name,
      }
    elseif choice2 == "quanjian_draw" then
      if #target.player_cards[Player.Hand] < math.min(target:getMaxCards(), 5) then
        target:drawCards(math.min(target:getMaxCards(), 5) - #target.player_cards[Player.Hand])
      end
      if #target.player_cards[Player.Hand] > target:getMaxCards() then
        local n = #target.player_cards[Player.Hand] - target:getMaxCards()
        room:askForDiscard(target, n, n, false, self.name, false)
      end
      room:addPlayerMark(target, "quanjian_prohibit-turn", 1)
    else
      room:addPlayerMark(target, "quanjian_damage-turn", 1)
    end
  end,
}
local quanjian_prohibit = fk.CreateProhibitSkill{
  name = "#quanjian_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("quanjian_prohibit-turn") > 0
  end,
}
local quanjian_record = fk.CreateTriggerSkill{
  name = "#quanjian_record",
  anim_type = "offensive",

  refresh_events = {fk.DamageInflicted},
  can_refresh = function(self, event, target, player, data)
    return target:getMark("quanjian_damage-turn") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.damage = data.damage + target:getMark("quanjian_damage-turn")
    player.room:setPlayerMark(target, "quanjian_damage-turn", 0)
  end,
}
local tujue = fk.CreateTriggerSkill{
  name = "tujue",
  anim_type = "defensive",
  frequency = Skill.Limited,
  events = {fk.AskForPeaches},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.dying and not player:isNude() and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#tujue-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getCardIds("he")
    room:moveCardTo(cards, Card.PlayerHand, room:getPlayerById(self.cost_data), fk.ReasonGive, self.name, nil, false, player.id)
    room:recover({
      who = player,
      num = math.min(#cards, player.maxHp - player.hp),
      recoverBy = player,
      skillName = self.name
    })
    player:drawCards(#cards, self.name)
  end,
}
quanjian:addRelatedSkill(quanjian_prohibit)
quanjian:addRelatedSkill(quanjian_record)
huangquan:addSkill(quanjian)
huangquan:addSkill(tujue)
Fk:loadTranslationTable{
  ["ty__huangquan"] = "黄权",
  ["#ty__huangquan"] = "忠事三朝",
  ["designer:ty__huangquan"] = "头发好借好还",
  ["illustrator:ty__huangquan"] = "匠人绘",
  ["quanjian"] = "劝谏",
  [":quanjian"] = "出牌阶段每项限一次，你选择以下一项令一名其他角色选择是否执行：1.对一名其攻击范围内你指定的角色造成1点伤害。"..
  "2.将手牌调整至手牌上限（最多摸到5张），其不能使用手牌直到回合结束。若其不执行，则其本回合下次受到的伤害+1。",
  ["tujue"] = "途绝",
  [":tujue"] = "限定技，当你处于濒死状态时，你可以将所有牌交给一名其他角色，然后你回复等量的体力值并摸等量的牌。",
  ["quanjian1"] = "对一名其攻击范围内你指定的角色造成1点伤害",
  ["quanjian2"] = "将手牌调整至手牌上限（最多摸到5张），其不能使用手牌直到回合结束",
  ["#quanjian-choose"] = "劝谏：选择一名其攻击范围内的角色",
  ["quanjian_damage"] = "对指定的角色造成1点伤害",
  ["quanjian_draw"] = "将手牌调整至手牌上限（最多摸到5张），不能使用手牌直到回合结束",
  ["quanjian_cancel"] = "不执行，本回合下次受到的伤害+1",
  ["#tujue-choose"] = "途绝：你可以将所有牌交给一名其他角色，然后回复等量的体力值并摸等量的牌",

  ["$quanjian1"] = "陛下宜后镇，臣请为先锋！",
  ["$quanjian2"] = "吴人悍战，陛下万不可涉险！",
  ["$tujue1"] = "归蜀无路，孤臣泪尽江北。",
  ["$tujue2"] = "受吾主殊遇，安能降吴！",
  ["~ty__huangquan"] = "败军之将，何言忠乎？",
}

local wuban = General(extension, "ty__wuban", "shu", 4)
local youzhan = fk.CreateTriggerSkill{
  name = "youzhan",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player.phase ~= Player.NotActive then
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
          player:drawCards(1, self.name, nil, "@@youzhan-inhand-turn")
          local to = room:getPlayerById(move.from)
          if not to.dead then
            room:addPlayerMark(to, "@youzhan-turn", 1)
            room:addPlayerMark(to, "youzhan-turn", 1)
          end
        end
      end
    end
  end,
}
local youzhan_trigger = fk.CreateTriggerSkill{
  name = "#youzhan_trigger",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.DamageInflicted then
        return player:getMark("youzhan-turn") > 0 and player:getMark("@youzhan-turn") > 0
      else
        return player.phase == Player.Finish and table.find(player.room.alive_players, function(p) return p:getMark("@youzhan-turn") > 0 end)
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
      player:broadcastSkillInvoke("youzhan")
      room:notifySkillInvoked(player, "youzhan", "drawcard")
      for _, p in ipairs(room.alive_players) do
        if #room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function(e)
          local damage = e.data[5]
          if damage and damage.to == p then
            return true
          end
        end, Player.HistoryTurn) == 0 then
          room:doIndicate(player.id, {p.id})
          p:drawCards(math.min(p:getMark("youzhan-turn"), 3), "youzhan")
        end
      end
    end
  end,
}
local youzhan_maxcards = fk.CreateMaxCardsSkill{
  name = "#youzhan_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@youzhan-inhand-turn") > 0
  end,
}
youzhan:addRelatedSkill(youzhan_trigger)
youzhan:addRelatedSkill(youzhan_maxcards)
wuban:addSkill(youzhan)
Fk:loadTranslationTable{
  ["ty__wuban"] = "吴班",
  ["#ty__wuban"] = "激东奋北",
  ["designer:ty__wuban"] = "七哀",
  ["illustrator:ty__wuban"] = "君桓文化",
  ["youzhan"] = "诱战",
  [":youzhan"] = "锁定技，其他角色在你的回合失去牌后，你摸一张牌且此牌本回合不计入手牌上限，其本回合下次受到的伤害+1。结束阶段，若这些角色本回合"..
  "未受到过伤害，其摸X张牌（X为其本回合失去牌的次数，至多为3）。",
  ["@youzhan-turn"] = "诱战",
  ["@@youzhan-inhand-turn"] = "诱战",

  ["$youzhan1"] = "本将军在此！贼仲达何在？",
  ["$youzhan2"] = "以身为饵，诱老贼出营。",
  ["$youzhan3"] = "呔！尔等之胆略尚不如蜀地小儿。",
  ["$youzhan4"] = "我等引兵叫阵，魏狗必衔尾而来。",
  ["~ty__wuban"] = "班……有负丞相重望……",
}

local huojun = General(extension, "ty__huojun", "shu", 4)
local gue = fk.CreateViewAsSkill{
  name = "gue",
  anim_type = "defensive",
  pattern = "slash,jink",
  prompt = "#gue",
  interaction = function()
    local names = {}
    for _, name in ipairs({"slash", "jink"}) do
      local card = Fk:cloneCard(name)
      if ((Fk.currentResponsePattern == nil and Self:canUse(card) and not Self:prohibitUse(card)) or
        (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card))) then
        table.insertIfNeed(names, card.name)
      end
    end
    if #names == 0 then return false end
    return UI.ComboBox { choices = names, all_choices = {"slash", "jink"} }
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player)
    local room = player.room
    local cards = player:getCardIds("h")
    if #cards == 0 then return end
    player:showCards(cards)
    if #table.filter(cards, function(id)
      return table.contains({"slash", "jink"}, Fk:getCardById(id).trueName)
    end) > 1 then
      return ""
    end
  end,
  enabled_at_play = Util.FalseFunc,
  enabled_at_response = function(self, player, response)
    return player:usedSkillTimes(self.name) == 0 and table.find(Fk:currentRoom().alive_players, function (p)
      return p ~= player and p.phase ~= Player.NotActive
    end)
  end,
}
local sigong = fk.CreateTriggerSkill{
  name = "sigong",
  anim_type = "offensive",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target ~= player and player:getMark("@@sigong-round") == 0 and
      target and not target.dead and not player:isProhibited(target, Fk:cloneCard("slash")) then
      local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data[1]
        return use.responseToEvent and use.responseToEvent.from == target.id
      end, Player.HistoryTurn)
      if #events > 0 then return true end
      events = player.room.logic:getEventsOfScope(GameEvent.RespondCard, 1, function(e)
        local response = e.data[1]
        return response.responseToEvent and response.responseToEvent.from == target.id
      end, Player.HistoryTurn)
      if #events > 0 then return true end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player:getHandcardNum() > 1 then
      local n = player:getHandcardNum() - 1
      local cards = player.room:askForDiscard(player, n, n, false, self.name, true, ".|.|.|hand", "#sigong-discard::"..target.id, true)
      if #cards == n then
        self.cost_data = cards
        return true
      end
    else
      local prompt = "#sigong-invoke::"..target.id
      if player:isKongcheng() then
        prompt = "#sigong-draw::"..target.id
      end
      if player.room:askForSkillInvoke(player, self.name, nil, prompt) then
        self.cost_data = {}
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:isKongcheng() then
      player:drawCards(1, self.name)
    else
      room:throwCard(self.cost_data, self.name, player, player)
    end
    local use = {
      from = player.id,
      tos = {{target.id}},
      card = Fk:cloneCard("slash"),
      extraUse = true,
    }
    use.card.skillName = self.name
    if #self.cost_data > 0 then
      use.extra_data = use.extra_data or {}
      use.extra_data.sigong = #self.cost_data
    end
    use.additionalDamage = (use.additionalDamage or 0) + 1
    room:useCard(use)
    if not player.dead and use.damageDealt then
      room:setPlayerMark(player, "@@sigong-round", 1)
    end
  end,

  refresh_events = {fk.PreCardEffect},
  can_refresh = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, self.name)
  end,
  on_refresh = function(self, event, target, player, data)
    if data.extra_data and data.extra_data.sigong then
      data.fixedResponseTimes = data.fixedResponseTimes or {}
      data.fixedResponseTimes["jink"] = data.extra_data.sigong
    end
  end,
}
huojun:addSkill(gue)
huojun:addSkill(sigong)
Fk:loadTranslationTable{
  ["ty__huojun"] = "霍峻",
  ["#ty__huojun"] = "坚磐石锐",
  ["illustrator:ty__huojun"] = "热图文化",
  ["gue"] = "孤扼",
  [":gue"] = "每名其他角色的回合内限一次，当你需要使用或打出【杀】或【闪】时，你可以：展示所有手牌，若其中【杀】和【闪】的总数小于2，视为你使用或打出之。",
  ["sigong"] = "伺攻",
  [":sigong"] = "其他角色的回合结束时，若其本回合内使用牌被响应过，你可以将手牌调整至一张，视为对其使用一张需要X张【闪】抵消且伤害+1的【杀】"..
  "（X为你以此法弃置牌数且至少为1）。若此【杀】造成伤害，此技能本轮失效。",
  ["#gue"] = "孤扼：你可以展示所有手牌，若【杀】【闪】总数不大于1，视为你使用或打出之",
  ["@@sigong-round"] = "伺攻失效",
  ["#sigong-discard"] = "伺攻：你可以将手牌弃至一张，视为对 %dest 使用【杀】",
  ["#sigong-invoke"] = "伺攻：你可以视为对 %dest 使用【杀】",
  ["#sigong-draw"] = "伺攻：你可以摸一张牌，视为对 %dest 使用【杀】",
  
  ["$gue1"] = "哀兵必胜，况吾众志成城。",
  ["$gue2"] = "扼守孤城，试问万夫谁开？",
  ["$sigong1"] = "善守者亦善攻，不可死守。",
  ["$sigong2"] = "璋军疲敝，可伺机而攻。",
  ["~ty__huojun"] = "蒙君知恩，奈何早薨……",
}

local furongfuqian = General(extension, "furongfuqian", "shu", 4, 6)
local ty__xuewei = fk.CreateTriggerSkill{
  name = "ty__xuewei",
  anim_type = "defensive",
  events = {fk.EventPhaseStart, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Finish
      else
        return target:getMark("@@ty__xuewei") > 0 and player.tag[self.name][1] == target.id
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local to = player.room:askForChoosePlayers(player, table.map(table.filter(player.room:getAlivePlayers(), function(p)
        return p.hp <= player.hp end), Util.IdMapper), 1, 1, "#ty__xuewei-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:addPlayerMark(room:getPlayerById(self.cost_data), "@@ty__xuewei", 1)
      player.tag[self.name] = {self.cost_data}
    else
      room:loseHp(player, 1, self.name)
      if not player.dead then
        player:drawCards(1, self.name)
      end
      if not target.dead then
        target:drawCards(1, self.name)
      end
      return true
    end
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self, true) and
      player.tag[self.name] and #player.tag[self.name] > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(player.tag[self.name][1])
    room:setPlayerMark(to, "@@ty__xuewei", 0)
    player.tag[self.name] = {}
  end,
}
local yuguan = fk.CreateTriggerSkill{
  name = "yuguan",
  anim_type = "drawcard",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and
      table.every(player.room:getOtherPlayers(player), function (p) return p:getLostHp() <= player:getLostHp() end)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#yuguan-invoke:::"..math.max(0, player:getLostHp() - 1))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if not player.dead and player:getLostHp() > 0 then
      local targets = table.map(table.filter(room:getAlivePlayers(), function(p)
        return #p.player_cards[Player.Hand] < p.maxHp end), Util.IdMapper)
      if #targets == 0 then return end
      local tos = room:askForChoosePlayers(player, targets, 1, player:getLostHp(), "#yuguan-choose:::"..player:getLostHp(), self.name, false)
      if #tos == 0 then
        tos = {player.id}
      end
      for _, id in ipairs(tos) do
        local p = room:getPlayerById(id)
        p:drawCards(p.maxHp - #p.player_cards[Player.Hand], self.name)
      end
    end
  end,
}
furongfuqian:addSkill(ty__xuewei)
furongfuqian:addSkill(yuguan)
Fk:loadTranslationTable{
  ["furongfuqian"] = "傅肜傅佥",
  ["#furongfuqian"] = "奕世忠义",
  ["designer:furongfuqian"] = "韩旭",
  ["illustrator:furongfuqian"] = "一意动漫",
  ["ty__xuewei"] = "血卫",
  [":ty__xuewei"] = "结束阶段，你可以选择一名体力值不大于你的角色。直到你的下回合开始前，该角色受到伤害时，防止此伤害，然后你失去1点体力并与其各摸一张牌。",
  ["yuguan"] = "御关",
  [":yuguan"] = "每个回合结束时，若你是损失体力值最多的角色，你可以减1点体力上限，然后令至多X名角色将手牌摸至体力上限（X为你已损失的体力值）。",
  ["@@ty__xuewei"] = "血卫",
  ["#ty__xuewei-choose"] = "血卫：你可以指定一名体力值不大于你的角色<br>直到你下回合开始前防止其受到的伤害，你失去1点体力并与其各摸一张牌",
  ["#yuguan-invoke"] = "御关：你可以减1点体力上限，令至多%arg名角色将手牌摸至体力上限",
  ["#yuguan-choose"] = "御关：令至多%arg名角色将手牌摸至体力上限",
  
  ["$ty__xuewei1"] = "慷慨赴国难，青山侠骨香。",
  ["$ty__xuewei2"] = "舍身卫主之志，死犹未悔！",
  ["$yuguan1"] = "城后即为汉土，吾等无路可退！",
  ["$yuguan2"] = "舍身卫关，身虽死而志犹在。",
  ["~furongfuqian"] = "此间，何有汉将军降者！",
}

local xianglang = General(extension, "xianglang", "shu", 3)
local kanji = fk.CreateActiveSkill{
  name = "kanji",
  anim_type = "drawcard",
  card_num = 0,
  target_num = 0,
  prompt = function()
    local suits = {}
    for _, id in ipairs(Self.player_cards[Player.Hand]) do
      local suit = Fk:getCardById(id).suit
      if suit ~= Card.NoSuit then
        if table.contains(suits, suit) then
          return "#kanji-active"
        else
          table.insert(suits, suit)
        end
      end
    end
    return "#kanji-active:::kanji_draw"
  end,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) < 2
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local cards = player.player_cards[Player.Hand]
    player:showCards(cards)
    local suits = {}
    for _, id in ipairs(cards) do
      local suit = Fk:getCardById(id).suit
      if suit ~= Card.NoSuit then
        if table.contains(suits, suit) then
          return
        else
          table.insert(suits, suit)
        end
      end
    end
    local suits1 = #suits
    player:drawCards(2, self.name)
    if suits1 == 4 then return end
    suits = {}
    for _, id in ipairs(player.player_cards[Player.Hand]) do
      local suit = Fk:getCardById(id).suit
      if suit ~= Card.NoSuit then
        table.insertIfNeed(suits, suit)
      end
    end
    if #suits == 4 then
      room:setPlayerMark(player, "@@kanji-turn", 1)
      player:skip(Player.Discard)
    end
  end,
}
local qianzheng = fk.CreateTriggerSkill{
  name = "qianzheng",
  anim_type = "drawcard",
  events = {fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from ~= player.id and
      (data.card:isCommonTrick() or data.card.trueName == "slash") and #player:getCardIds{Player.Hand, Player.Equip} > 1 and
      player:usedSkillTimes(self.name, Player.HistoryTurn) < 2
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = "#qianzheng1-card:::"..data.card:getTypeString()..":"..data.card:toLogString()
    if data.card:isVirtual() and not data.card:getEffectiveId() then
      prompt = "#qianzheng2-card"
    end
    local cards = player.room:askForCard(player, 2, 2, true, self.name, true, ".", prompt)
    if #cards == 2 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = self.cost_data
    if Fk:getCardById(cards[1]).type ~= data.card.type and Fk:getCardById(cards[2]).type ~= data.card.type then
      data.extra_data = data.extra_data or {}
      data.extra_data.qianzheng = player.id
    end
    room:recastCard(cards, player, self.name)
  end,
}
local qianzheng_trigger = fk.CreateTriggerSkill{
  name = "#qianzheng_trigger",
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.qianzheng and data.extra_data.qianzheng == player.id and
      player.room:getCardArea(data.card) == Card.Processing and not player.dead
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, "qianzheng", nil, "#qianzheng-invoke:::"..data.card:toLogString())
  end,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player.id, data.card, true, fk.ReasonJustMove)
  end,
}
qianzheng:addRelatedSkill(qianzheng_trigger)
xianglang:addSkill(kanji)
xianglang:addSkill(qianzheng)
Fk:loadTranslationTable{
  ["xianglang"] = "向朗",
  ["#xianglang"] = "校书翾翻",
  ["illustrator:xianglang"] = "匠人绘",
  ["kanji"] = "勘集",
  [":kanji"] = "出牌阶段限两次，你可以展示所有手牌，若花色均不同，你摸两张牌，然后若因此使手牌包含四种花色，则你跳过本回合的弃牌阶段。",
  ["qianzheng"] = "愆正",
  [":qianzheng"] = "每回合限两次，当你成为其他角色使用普通锦囊牌或【杀】的目标时，你可以重铸两张牌，若这两张牌与使用牌类型均不同，"..
  "此牌结算后进入弃牌堆时你可以获得之。",

  ["#kanji-active"] = "发动 勘集，展示所有手牌%arg",
  ["kanji_draw"] = "，然后摸两张牌",
  ["@@kanji-turn"] = "勘集",
  ["#qianzheng1-card"] = "愆正：你可以重铸两张牌，若均不为%arg，结算后获得%arg2",
  ["#qianzheng2-card"] = "愆正：你可以重铸两张牌",
  ["#qianzheng-invoke"] = "愆正：你可以获得此%arg",

  ["$kanji1"] = "览文库全书，筑文心文胆。",
  ["$kanji2"] = "世间学问，皆载韦编之上。",
  ["$qianzheng1"] = "悔往昔之种种，恨彼时之切切。",
  ["$qianzheng2"] = "罪臣怀咎难辞，有愧国恩。",
  ["~xianglang"] = "识文重义而徇私，恨也……",
}

local gaoxiang = General(extension, "gaoxiang", "shu", 4)
local chiying = fk.CreateActiveSkill{
  name = "chiying",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#chiying-invoke",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getPlayerById(to_select).hp <= Self.hp
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local ids = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if target:inMyAttackRange(p) and not p.dead and not p:isNude() then
        local card = room:askForDiscard(p, 1, 1, true, self.name, false, nil)
        if target ~= player and #card > 0 and Fk:getCardById(card[1]).type == Card.TypeBasic then
          table.insertIfNeed(ids, card[1])
        end
      end
    end
    if #ids == 0 or target.dead then return end
    ids = table.filter(ids, function(id) return room:getCardArea(id) == Card.DiscardPile end)
    if #ids == 0 then return end
    room:obtainCard(target, ids, true, fk.ReasonJustMove)
  end,
}
gaoxiang:addSkill(chiying)
Fk:loadTranslationTable{
  ["gaoxiang"] = "高翔",
  ["#gaoxiang"] = "玄乡侯",
  ["designer:gaoxiang"] = "神壕",
  ["illustrator:gaoxiang"] = "黯荧岛工作室",

  ["chiying"] = "驰应",
  [":chiying"] = "出牌阶段限一次，你可以选择一名体力值不大于你的角色，令其攻击范围内的其他角色各弃置一张牌。若选择的角色不为你，其获得其中的基本牌。",
  ["#chiying-invoke"] = "驰应：选择一名角色，其攻击范围内其他角色各弃一张牌",

  ["$chiying1"] = "今诱老贼来此，必折其父子于上方谷。",
  ["$chiying2"] = "列柳城既失，当下唯死守阳平关。",
  ["~gaoxiang"] = "老贼不死，实天意也……",
}

local yangyi = General(extension, "ty__yangyi", "shu", 3)
local ty__juanxia_active = fk.CreateActiveSkill{
  name = "ty__juanxia_active",
  expand_pile = function(self)
    return self.ty__juanxia_names or {}
  end,
  card_num = 1,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and table.contains(self.ty__juanxia_names or {}, to_select)
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected_cards == 0 then return false end
    local to = self.ty__juanxia_target
    if #selected == 0 then
      return to_select == to
    elseif #selected == 1 then
      local card = Fk:cloneCard(Fk:getCardById(selected_cards[1]).name)
      card.skillName = "ty__juanxia"
      if card.skill:getMinTargetNum() == 2 and selected[1] == to then
        return card.skill:targetFilter(to_select, selected, {}, card)
      end
    end
  end,
  feasible = function(self, selected, selected_cards)
    if #selected_cards == 0 then return false end
    local to_use = Fk:cloneCard(Fk:getCardById(selected_cards[1]).name)
    to_use.skillName = "ty__juanxia"
    local selected_copy = table.simpleClone(selected)
    if #selected_copy == 0 then
      table.insert(selected_copy, self.ty__juanxia_target)
    end
    return to_use.skill:feasible(selected_copy, {}, Self, to_use)
  end,
}
local ty__juanxia = fk.CreateTriggerSkill{
  name = "ty__juanxia",
  anim_type = "offensive",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#ty__juanxia-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local x = 0
    local all = table.filter(U.getUniversalCards(room, "t"), function(id)
      local trick = Fk:getCardById(id)
      return not trick.multiple_targets and trick.skill:getMinTargetNum() > 0
    end)
    for i = 1, 3 do
      local names = table.filter(all, function (id)
        local card = Fk:cloneCard(Fk:getCardById(id).name)
        card.skillName = self.name
        return player:canUseTo(card, to, {bypass_distances = true})
      end)
      if #names == 0 then break end
      local _, dat = room:askForUseActiveSkill(player, "ty__juanxia_active", "#ty__juanxia-invoke::" .. to.id..":"..i, true,
      {ty__juanxia_names = names, ty__juanxia_target = to.id})
      if not dat then break end
      table.removeOne(all, dat.cards[1])
      local card = Fk:cloneCard(Fk:getCardById(dat.cards[1]).name)
      x = x + 1
      card.skillName = self.name
      local tos = dat.targets
      if #tos == 0 then table.insert(tos, to.id) end
      room:useCard{
        from = player.id,
        tos = table.map(dat.targets, function(id) return {id} end),
        card = card,
      }
      if player.dead or to.dead then return end
    end
    if x == 0 then return end
    room:setPlayerMark(to, "@ty__juanxia", x)
    room:setPlayerMark(to, "ty__juanxia_src", player.id)
  end,

  refresh_events = {fk.AfterTurnEnd},
  can_refresh = function(self, event, target, player, data)
    return player == target and (player:getMark("@ty__juanxia") > 0 or player:getMark("ty__juanxia_src") > 0)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@ty__juanxia", 0)
    room:setPlayerMark(player, "ty__juanxia_src", 0)
  end,
}
local ty__juanxia_delay = fk.CreateTriggerSkill{
  name = "#ty__juanxia_delay",
  events = {fk.TurnEnd},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and not target.dead and target:getMark("@ty__juanxia") > 0 and
    target:getMark("ty__juanxia_src") == player.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = target:getMark("@ty__juanxia")
    for i = 1, n, 1 do
      local slash = Fk:cloneCard("slash")
      slash.skillName = "ty__juanxia"
      if U.canUseCardTo(room, target, player, slash, false, false) and
      room:askForSkillInvoke(target, self.name, nil, "#ty__juanxia-slash:"..player.id.."::"..n..":"..i) then
        room:useCard{
          from = target.id,
          tos = {{player.id}},
          card = slash,
          extraUse = true,
        }
      else
        break
      end
      if player.dead or target.dead then break end
    end
  end
}
local ty__dingcuo = fk.CreateTriggerSkill{
  name = "ty__dingcuo",
  anim_type = "drawcard",
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
    and not (data.to == player and data.from == player)
  end,
  on_use = function(self, event, target, player, data)
    local cards = player:drawCards(2, self.name)
    if Fk:getCardById(cards[1]).color ~= Fk:getCardById(cards[2]).color and not player.dead then
      player.room:askForDiscard(player, 1, 1, false, self.name, false)
    end
  end
}
Fk:addSkill(ty__juanxia_active)
ty__juanxia:addRelatedSkill(ty__juanxia_delay)
yangyi:addSkill(ty__juanxia)
yangyi:addSkill(ty__dingcuo)
Fk:loadTranslationTable{
  ["ty__yangyi"] = "杨仪",
  ["#ty__yangyi"] = "武侯长史",
  ["designer:ty__yangyi"] = "步穗",
  ["illustrator:ty__yangyi"] = "鬼画府", -- 驭雷伏乱

  ["ty__juanxia"] = "狷狭",
  [":ty__juanxia"] = "结束阶段，你可以选择一名其他角色，视为依次使用至多三张牌名各不相同的仅指定唯一目标的普通锦囊牌（无距离限制）。若如此做，该角色的下一个结束阶段开始时，其可以视为对你使用等量张【杀】。",
  ["ty__dingcuo"] = "定措",
  [":ty__dingcuo"] = "当你对其他角色造成伤害后，或当你受到其他角色造成的伤害后，若你于当前回合内未发动过此技能，你可摸两张牌，然后若这两张牌颜色不同，你须弃置一张手牌。",
  ["ty__juanxia_active"] = "狷狭",
  ["#ty__juanxia-choose"] = "狷狭：选择一名其他角色，视为对其使用至多三张仅指定唯一目标的普通锦囊",
  ["#ty__juanxia-invoke"] = "狷狭：你可以视为对 %dest 使用一张锦囊（第%arg张，至多3张）",
  ["#ty__juanxia_delay"] = "狷狭",
  ["#ty__juanxia-slash"] = "狷狭：你可以视为对 %src 使用【杀】（第%arg2张，至多%arg张）",
  ["@ty__juanxia"] = "狷狭",

  ["$ty__juanxia1"] = "放之海内，知我者少、同我者无，可谓高处胜寒。",
  ["$ty__juanxia2"] = "满堂朱紫，能文者不武，为将者少谋，唯吾兼备。",
  ["$ty__dingcuo1"] = "奋笔墨为锄，茁大汉以壮、慷国士以慨。",
  ["$ty__dingcuo2"] = "执金戈为尺，定国之方圆、立人之规矩。",
  ["~ty__yangyi"] = "幼主昏聩，群臣无谋，国将亡。",
}

local ty__jiangwanfeiyi = General(extension, "ty__jiangwanfeiyi", "shu", 3)
ty__jiangwanfeiyi:addSkill("ld__shengxi")
local shoucheng = fk.CreateTriggerSkill{
  name = "ty__shoucheng",
  anim_type = "support",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) or player:usedSkillTimes(self.name, Player.HistoryTurn) > 0 then return end
    for _, move in ipairs(data) do
      if move.from then
        local from = player.room:getPlayerById(move.from)
        if from:isKongcheng() and from.phase == Player.NotActive and not from.dead then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local targets = {}
    local room = player.room
    for _, move in ipairs(data) do
      if move.from then
        local from = room:getPlayerById(move.from)
        if from:isKongcheng() and from.phase == Player.NotActive and not from.dead then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              table.insertIfNeed(targets, from.id)
              break
            end
          end
        end
      end
    end
    if #targets == 0 then return end
    if #targets > 1 then
      local tos = player.room:askForChoosePlayers(player, targets, 1, 1, "#ty__shoucheng-choose", self.name, true)
      if #tos > 0 then
        self.cost_data = tos[1]
        return true
      end
    else
      self.cost_data = targets[1]
      return player.room:askForSkillInvoke(player, self.name, nil, "#ty__shoucheng-draw::" .. targets[1])
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    room:doIndicate(player.id, {to.id})
    player:broadcastSkillInvoke("shoucheng")
    to:drawCards(2, self.name)
  end,
}
ty__jiangwanfeiyi:addSkill(shoucheng)
Fk:loadTranslationTable{
  ["ty__jiangwanfeiyi"] = "蒋琬费祎",
  ["#ty__jiangwanfeiyi"] = "社稷股肱",
  ["designer:ty__jiangwanfeiyi"] = "淬毒",
  --["illustrator:ty__jiangwanfeiyi"] = "",

  ["ty__shoucheng"] = "守成",
  [":ty__shoucheng"] = "当一名角色于其回合外失去手牌后，若其没有手牌且你于当前回合内未发动过此技能，你可令其摸两张牌。",

  ["#ty__shoucheng-draw"] = "守成：你可令 %dest 摸两张牌",
  ["#ty__shoucheng-choose"] = "守成：你可令一名失去最后手牌的角色摸两张牌",
}

local lifeng = General(extension, "ty__lifeng", "shu", 3)
Fk:loadTranslationTable{
  ["ty__lifeng"] = "李丰",
  ["#ty__lifeng"] = "继责尽任",
  ["designer:ty__lifeng"] = "步穗",
  ["illustrator:ty__lifeng"] = "君桓文化", --五谷丰盈*李丰
  ["~ty__lifeng"] = "蜀穗重丰，不见丞相还……",
}

local tunchu = fk.CreateTriggerSkill{
  name = "ty__tunchu",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.GameStart, fk.BeforeCardsMove, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then
      return false
    end

    if event == fk.GameStart then
      return (#player.room.players * 4 - player:getHandcardNum()) > 0
    elseif event == fk.BeforeCardsMove then
      return
        table.find(
          data,
          function(info)
            return
              info.from == player.id and
              info.moveReason == fk.ReasonDiscard and
              table.find(info.moveInfo, function(moveInfo) return moveInfo.fromArea == Card.PlayerHand end)
          end
        )
    else
      return target == player and player.phase == Player.Start and player:getHandcardNum() > player.hp
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      player:drawCards(#room.players * 4 - player:getHandcardNum(), self.name)
    elseif event == fk.BeforeCardsMove then
      local ids = {}
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason == fk.ReasonDiscard then
          local moveInfos = {}
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              table.insert(ids, info.cardId)
            else
              table.insert(moveInfos, info)
            end
          end
          if #ids > 0 then
            move.moveInfo = moveInfos
          end
        end
      end
      if #ids > 0 then
        player.room:sendLog{
          type = "#cancelDismantle",
          card = ids,
          arg = self.name,
        }
      end
    else
      room:setPlayerMark(player, "@ty__tunchu-turn", 3)
    end
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@ty__tunchu-turn") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local tunchuMark = player:getMark("@ty__tunchu-turn")
    tunchuMark = tunchuMark - 1
    if tunchuMark == 0 then
      room:addPlayerMark(player, "@@ty__tunchu_prohibit-turn")
    end

    room:setPlayerMark(player, "@ty__tunchu-turn", tunchuMark)
  end,
}
local tunchuProhibit = fk.CreateProhibitSkill{
  name = "#ty__tunchu_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("@@ty__tunchu_prohibit-turn") > 0
  end,
  prohibit_discard = function(self, player, card)
    return player:hasSkill(tunchu) and Fk:currentRoom():getCardArea(card.id) == Card.PlayerHand
  end,
}
local tunchuBreak = fk.CreateTriggerSkill{
  name = "#ty__tunchu_break",
  mute = true,
  priority = 100,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    return data[1].skillName == tunchu.name and data[1].moveReason == fk.ReasonDraw
  end,
  on_trigger = function(self, event, target, player, data)
    return true
  end,
}
Fk:loadTranslationTable{
  ["ty__tunchu"] = "囤储",
  [":ty__tunchu"] = "锁定技，游戏开始时，你将手牌摸至等同于游戏人数四倍数量张（以此法摸牌不生成牌移动后时机）；你不能弃置你的手牌；" ..
  "当你因其他角色弃置而失去手牌前，防止这些牌移动；准备阶段开始时，若你的手牌数大于体力值，则你于本回合内只能使用三张牌。",
  ["@ty__tunchu-turn"] = "囤储",
  ["@@ty__tunchu_prohibit-turn"] = "囤储 不能出牌",

  ["$ty__tunchu1"] = "秋收冬藏，此四时之理，亘古不变。",
  ["$ty__tunchu2"] = "囤粮之家，必无饥馑之虞。",
}

tunchu:addRelatedSkill(tunchuProhibit)
tunchu:addRelatedSkill(tunchuBreak)
lifeng:addSkill(tunchu)

local shuliang = fk.CreateTriggerSkill{
  name = "ty__shuliang",
  anim_type = "support",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(self) and
      not player:isNude() and
      table.find(player.room.alive_players, function(p) return p ~= player and p:isKongcheng() end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local availableTargets = table.filter(room.alive_players, function(p) return p ~= player and p:isKongcheng() end)
    if #availableTargets > 0 then
      local tos, cid = room:askForChooseCardAndPlayers(
        player,
        table.map(availableTargets, Util.IdMapper),
        1,
        1,
        nil,
        "#ty__shuliang-choose",
        self.name,
        true
      )

      if #tos > 0 and cid then
        self.cost_data = {tos[1], cid}
        return true
      end
    end

    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:moveCardTo(self.cost_data[2], Player.Hand, room:getPlayerById(self.cost_data[1]), fk.ReasonGive, self.name, nil, false, player.id)

    local GivenMap = { [self.cost_data[1]] = self.cost_data[2] }
    local targetsGiven = { self.cost_data[1] }
    local availableTargets = table.filter(
      room.alive_players,
      function(p) return p ~= player and p:isKongcheng() and not GivenMap[p.id] end
    )

    while #availableTargets > 0 and not player:isNude() do
      local tos, cid = room:askForChooseCardAndPlayers(
        player,
        table.map(availableTargets, Util.IdMapper),
        1,
        1,
        nil,
        "#ty__shuliang-choose",
        self.name,
        true
      )

      if #tos > 0 and cid then
        GivenMap[tos[1]] = cid
        table.insert(targetsGiven, tos[1])
        room:moveCardTo(cid, Player.Hand, room:getPlayerById(tos[1]), fk.ReasonGive, self.name, nil, false, player.id)
      else
        break
      end

      availableTargets = table.filter(
        room.alive_players,
        function(p) return p ~= player and p:isKongcheng() and not GivenMap[p.id] end
      )
    end

    room:sortPlayersByAction(targetsGiven)
    for _, pid in ipairs(targetsGiven) do
      local p = room:getPlayerById(pid)
      local cardToUse = Fk:getCardById(GivenMap[pid])
      if p:isAlive() and room:getCardArea(cardToUse.id) == Card.PlayerHand and
      U.canUseCardTo(room, p, p, cardToUse, true, false) and
      room:askForSkillInvoke(p, self.name, nil, "#ty__shuliang-use:::"..cardToUse:toLogString()) then
        local use = {
          from = p.id,
          card = cardToUse,
          extraUse = true,
        }
        --FIXME: 目前没有对自己使用且必须指定两个以上目标的卡牌，暂不作处理
        if cardToUse.skill:getMinTargetNum() == 1 then
          use.tos = {{p.id}}
        end
        room:useCard(use)
      end
    end
  end,
}
Fk:loadTranslationTable{
  ["ty__shuliang"] = "输粮",
  [":ty__shuliang"] = "每个回合结束时，你可以交给至少一名没有手牌的其他角色各一张牌。若此牌可指定该角色自己为目标，则其可使用此牌。",
  ["#ty__shuliang-choose"] = "输粮：你可选择一张牌和一名没有手牌的其他角色，交给其此牌",
  ["#ty__shuliang-use"] = "输粮：是否对自己使用%arg",

  ["$ty__shuliang1"] = "北伐鏖战正酣，此正需粮之时。",
  ["$ty__shuliang2"] = "粮草先于兵马而动，此军心之本。",
}

lifeng:addSkill(shuliang)

--太平甲子：管亥 张闿 刘辟 裴元绍 张楚 张曼成
local guanhai = General(extension, "guanhai", "qun", 4)
local suoliang = fk.CreateTriggerSkill{
  name = "suoliang",
  anim_type = "offensive",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
      not data.to.dead and not data.to:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#suoliang-invoke::"..data.to.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askForCardsChosen(player, data.to, 1, math.min(data.to.maxHp, 5), "he", self.name)
    if #cards > 0 then
      local suits = {Card.Heart, Card.Club}
      local to_get = table.filter(cards, function (id)
        return table.contains(suits, Fk:getCardById(id).suit)
      end)
      if #to_get > 0 then
        room:obtainCard(player, to_get, true, fk.ReasonPrey)
      else
        room:throwCard(cards, self.name, data.to, player)
      end
    end
  end,
}
local qinbao = fk.CreateTriggerSkill{
  name = "qinbao",
  anim_type = "offensive",
  events = {fk.CardUsing},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      #table.filter(player.room:getOtherPlayers(player), function(p) return p:getHandcardNum() >= player:getHandcardNum() end) > 0
  end,
  on_use = function(self, event, target, player, data)
    local targets = table.filter(player.room:getOtherPlayers(player), function(p)
      return p:getHandcardNum() >= player:getHandcardNum() end)
    if #targets > 0 then
      data.disresponsiveList = data.disresponsiveList or {}
      for _, p in ipairs(targets) do
        table.insertIfNeed(data.disresponsiveList, p.id)
      end
    end
  end,
}
guanhai:addSkill(suoliang)
guanhai:addSkill(qinbao)
Fk:loadTranslationTable{
  ["guanhai"] = "管亥",
  ["#guanhai"] = "掠地劫州",
  ["illustrator:guanhai"] = "六道目",
  ["suoliang"] = "索粮",
  [":suoliang"] = "每回合限一次，你对一名其他角色造成伤害后，选择其至多X张牌（X为其体力上限且最多为5），获得其中的<font color='red'>♥</font>和♣牌。"..
  "若你未获得牌，则弃置你选择的牌。",
  ["qinbao"] = "侵暴",
  [":qinbao"] = "锁定技，手牌数大于等于你的其他角色不能响应你使用的【杀】或普通锦囊牌。",
  ["#suoliang-invoke"] = "索粮：你可以选择 %dest 最多其体力上限张牌，获得其中的<font color='red'>♥</font>和♣牌，若没有则弃置这些牌",

  ["$suoliang1"] = "奉上万石粮草，吾便退兵！",
  ["$suoliang2"] = "听闻北海富庶，特来借粮。",
  ["$qinbao1"] = "赤箓护身，神鬼莫当。",
  ["$qinbao2"] = "头裹黄巾，代天征伐。",
  ["~guanhai"] = "这红脸汉子，为何如此眼熟……",
}

local zhangkai = General(extension, "zhangkai", "qun", 4)
local xiangshuz = fk.CreateTriggerSkill{
  name = "xiangshuz",
  anim_type = "offensive",
  events = {fk.EventPhaseStart, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(self) and target.phase == Player.Play then
      if event == fk.EventPhaseStart then
        return target:getHandcardNum() >= target.hp
      else
        return player:usedSkillTimes(self.name, Player.HistoryPhase) > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return player.room:askForSkillInvoke(player, self.name, nil, "#xiangshuz-invoke::"..target.id)
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:doIndicate(player.id, {target.id})
      local choices = {}
      for i = 0, 5, 1 do
        table.insert(choices, tostring(i))
      end
      local choice = room:askForChoice(player, choices, self.name, "#xiangshuz-choice::"..target.id)
      local mark = self.name
      if player:isKongcheng() or #room:askForDiscard(player, 1, 1, false, self.name, true, ".", "#xiangshuz-discard") == 0 then
        mark = "@"..self.name
      end
      room:setPlayerMark(target, mark, choice)
    else
      room:doIndicate(player.id, {target.id})
      local n1 = target:getHandcardNum()
      local n2 = math.max(tonumber(target:getMark(self.name)), tonumber(target:getMark("@"..self.name)))
      room:setPlayerMark(target, self.name, 0)
      room:setPlayerMark(target, "@"..self.name, 0)
      if math.abs(n1 - n2) < 2 and not target:isNude() then
        local id = room:askForCardChosen(player, target, "he", self.name)
        room:obtainCard(player.id, id, false, fk.ReasonPrey)
      end
      if n1 == n2 then
        room:damage{
          from = player,
          to = target,
          damage = 1,
          skillName = self.name,
        }
      end
    end
  end,
}
zhangkai:addSkill(xiangshuz)
Fk:loadTranslationTable{
  ["zhangkai"] = "张闿",
  ["#zhangkai"] = "无餍狍鸮",
  ["illustrator:zhangkai"] = "猎枭",
  ["xiangshuz"] = "相鼠",
  [":xiangshuz"] = "其他角色出牌阶段开始时，若其手牌数不小于体力值，你可以声明一个0~5的数字（若你弃置一张手牌，则数字不公布）。"..
  "此阶段结束时，若其手牌数与你声明的数：相差1以内，你获得其一张牌；相等，你对其造成1点伤害。",
  ["#xiangshuz-invoke"] = "相鼠：猜测 %dest 此阶段结束时手牌数，若相差1以内，获得其一张牌；相等，再对其造成1点伤害",
  ["#xiangshuz-choice"] = "相鼠：猜测 %dest 此阶段结束时的手牌数",
  ["#xiangshuz-discard"] = "相鼠：你可以弃置一张手牌令你猜测的数值不公布",
  ["@xiangshuz"] = "相鼠",

  ["$xiangshuz1"] = "要财还是要命，选一个吧！",
  ["$xiangshuz2"] = "有什么好东西，都给我交出来！",
  ["~zhangkai"] = "报应竟来得这么快……",
}

local liupi = General(extension, "liupi", "qun", 4)
local juying = fk.CreateTriggerSkill{
  name = "juying",
  anim_type = "drawcard",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Play then
      local card = Fk:cloneCard("slash")
      local slash_skill = card.skill
      local status_skills = Fk:currentRoom().status_skills[TargetModSkill] or Util.DummyTable
      for _, skill in ipairs(status_skills) do
        if skill:bypassTimesCheck(player, slash_skill, Player.HistoryPhase, card, nil) then return true end
      end
      return player:usedCardTimes("slash", Player.HistoryPhase) < slash_skill:getMaxUseTime(player, Player.HistoryPhase, card, nil)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room

    local all_choices = {"juying1", "juying2", "juying3"}
    local choices = room:askForChoices(player, all_choices, 1, 3, self.name, "#juying-choice", true)

    if #choices == 0 then return false end

    if table.contains(choices, "juying1") then
      room:addPlayerMark(player, self.name)
    end
    if table.contains(choices, "juying2") then
      room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, 2)
    end
    if table.contains(choices, "juying3") then
      player:drawCards(3, self.name)
    end

    if not player.dead and #choices > player.hp then
      room:askForDiscard(player, 1, 1, true, self.name, false)
    end
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark(self.name) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, MarkEnum.SlashResidue .. "-turn", player:getMark(self.name))
    room:setPlayerMark(player, self.name, 0)
  end,
}

liupi:addSkill(juying)
Fk:loadTranslationTable{
  ["liupi"] = "刘辟",
  ["#liupi"] = "慕义渠帅",
  ["designer:liupi"] = "韩旭",
  ["illustrator:liupi"] = "君桓文化",
  ["juying"] = "踞营",
  [":juying"] = "出牌阶段结束时，若你本阶段使用【杀】的次数小于次数上限，你可以选择任意项：1.下个回合出牌阶段使用【杀】次数上限+1；"..
  "2.本回合手牌上限+2；3.摸三张牌。若你选择的选项数大于你的体力值，你弃置一张牌。",
  ["#juying-choice"] = "踞营：你可以选择任意项，每比体力值多选一项便弃一张牌",
  ["juying1"] = "下个回合出牌阶段使用【杀】上限+1",
  ["juying2"] = "本回合手牌上限+2",
  ["juying3"] = "摸三张牌",

  ["$juying1"] = "垒石为寨，纵万军亦可阻。",
  ["$juying2"] = "如虎踞汝南，攻守自有我。",
  ["~liupi"] = "玄德公高义，辟宁死不悔！",
}

local peiyuanshao = General(extension, "peiyuanshao", "qun", 4)
local moyu = fk.CreateActiveSkill{
  name = "moyu",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = function()
    return "#moyu-active:::" .. tostring((Self:getMark("@@moyu1-phase") > 0) and 2 or 1)
  end,
  can_use = function(self, player)
    return player:getMark("@@moyu2-turn") == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and not table.contains(U.getMark(Self, "moyu_targets-phase"), to_select) and
    #Fk:currentRoom():getPlayerById(to_select):getCardIds("hej") > Self:getMark("@@moyu1-phase")
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local mark = U.getMark(player, "moyu_targets-phase")
    table.insert(mark, target.id)
    room:setPlayerMark(player, "moyu_targets-phase", mark)
    local x = 1
    if player:getMark("@@moyu1-phase") > 0 then
      x = 2
      room:setPlayerMark(player, "@@moyu1-phase", 0)
    end
    local ids = room:askForCardsChosen(player, target, x, x, "hej", self.name)
    room:obtainCard(player.id, ids, false, fk.ReasonPrey)
    if target.dead then return end
    local use = room:askForUseCard(target, "slash", "slash", "#moyu-slash::"..player.id, true,
      {must_targets = {player.id}, bypass_distances = true, bypass_times = true})
    if use then
      room:useCard(use)
      if player.dead then return end
      if use.damageDealt and use.damageDealt[player.id] then
        room:setPlayerMark(player, "@@moyu2-turn", 1)
      else
        room:setPlayerMark(player, "@@moyu1-phase", 1)
      end
    end
  end,
}
peiyuanshao:addSkill(moyu)
Fk:loadTranslationTable{
  ["peiyuanshao"] = "裴元绍",
  ["#peiyuanshao"] = "买椟还珠",
  ["designer:peiyuanshao"] = "步穗",
  ["illustrator:peiyuanshao"] = "匠人绘",
  ["moyu"] = "没欲",
  [":moyu"] = "出牌阶段，你可以获得一名此阶段内未选择过的一名其他角色区域里的一张牌，然后该角色可以对你使用一张【杀】（无距离限制），"..
  "若此【杀】：未对你造成过伤害，你于此阶段内下次发动此技能改为获得两张牌；对你造成过伤害，此技能于此回合内无效。",
  ["#moyu-active"] = "发动 没欲，选择1名角色，获得其区域里的%arg张牌",
  ["#moyu-slash"] = "没欲：你可以对 %dest 使用一张【杀】",
  ["@@moyu1-phase"] = "没欲强化",
  ["@@moyu2-turn"] = "没欲失效",

  ["$moyu1"] = "人之所有，我之所欲。",
  ["$moyu2"] = "胸有欲壑千丈，自当饥不择食。",
  ["~peiyuanshao"] = "好生厉害的白袍小将……",
}

local zhangchu = General(extension, "zhangchu", "qun", 3, 3, General.Female)
local jizhong = fk.CreateActiveSkill{
  name = "jizhong",
  anim_type = "control",
  prompt = "#jizhong-active",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    target:drawCards(2, self.name)
    if target.dead or player.dead then return end

    if target:getMark("@@xinzhong") > 0 then
      local cards = target:getCardIds(Player.Hand)
      if #cards > 3 then
        cards = room:askForCard(target, 3, 3, false, self.name, false, ".", "#jizhong-give:" .. player.id)
      end
      if #cards > 0 then
        room:moveCardTo(cards, Player.Hand, player, fk.ReasonGive, self.name, nil, false, target.id)
      end
    else
      local cards = room:askForCard(target, 3, 3, false, self.name, true, ".", "#jizhong-choice:" .. player.id)
      if #cards == 0 then
        room:setPlayerMark(target, "@@xinzhong", 1)
      else
        room:moveCardTo(cards, Player.Hand, player, fk.ReasonGive, self.name, nil, false, target.id)
      end
    end
  end,
}
local rihui = fk.CreateTriggerSkill{
  name = "rihui",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
      (data.card:isCommonTrick() or (data.card.type == Card.TypeBasic and data.card.color == Card.Black)) and
      data.tos and #TargetGroup:getRealTargets(data.tos) == 1 and TargetGroup:getRealTargets(data.tos)[1] ~= player.id
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(TargetGroup:getRealTargets(data.tos)[1])
    if to.dead then return end
    if to:getMark("@@xinzhong") == 0 then
      for _, p in ipairs(room:getOtherPlayers(to)) do
        if p:getMark("@@xinzhong") > 0 then
          return room:askForSkillInvoke(player, self.name, data, "#rihui-use::" .. to.id .. ":" .. data.card.name)
        end
      end
    else
      if to:isAllNude() then return end
      return room:askForSkillInvoke(player, self.name, data, "#rihui-get::" .. to.id)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(TargetGroup:getRealTargets(data.tos)[1])
    if to:getMark("@@xinzhong") == 0 then
      for _, p in ipairs(room:getOtherPlayers(to)) do
        if p:getMark("@@xinzhong") > 0 then
          if to.dead or p.dead then return end
          room:useVirtualCard(data.card.name, nil, p, to, self.name, true)
        end
      end
    else
      local id = room:askForCardChosen(player, to, "hej", self.name)
      room:obtainCard(player.id, id, false, fk.ReasonPrey)
    end
  end,
}
local guangshi = fk.CreateTriggerSkill{
  name = "guangshi",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and
      table.every(player.room:getOtherPlayers(player, false), function (p)
        return p:getMark("@@xinzhong") > 0
      end)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
    if player:isAlive() then
      player.room:loseHp(player, 1, self.name)
    end
  end,
}
zhangchu:addSkill(jizhong)
zhangchu:addSkill(rihui)
zhangchu:addSkill(guangshi)
Fk:loadTranslationTable{
  ["zhangchu"] = "张楚",
  ["#zhangchu"] = "大贤后裔",
  ["designer:zhangchu"] = "韩旭",
  ["illustrator:zhangchu"] = "黯荧岛工作室",
  ["jizhong"] = "集众",
  [":jizhong"] = "出牌阶段限一次，你可以令一名其他角色摸两张牌，然后若其：不是“信众”，则其选择一项：1.成为“信众”；"..
  "2.将三张手牌交给你；是“信众”，其将三张手牌交给你（不足则全部交给）。",
  ["rihui"] = "日慧",
  [":rihui"] = "每回合限一次，当你使用指定唯一其他角色为目标的普通锦囊牌或黑色基本牌后，若其：不是“信众”，所有“信众”均视为对其使用此牌；"..
  "是“信众”，你可以获得其区域内的一张牌。",
  ["guangshi"] = "光噬",
  [":guangshi"] = "锁定技，准备阶段，若所有其他角色均是“信众”，你摸两张牌并失去1点体力。",
  ["#jizhong-active"] = "发动 集众，令一名其他角色摸两张牌，然后其选择交给你三张牌或成为“信众”",
  ["@@xinzhong"] = "信众",
  ["#jizhong-choice"] = "集众：选择将三张手牌交给 %src，否则成为“信众”",
  ["#jizhong-give"] = "集众：选择将三张手牌交给 %src",
  ["#rihui-use"] = "日慧：你可以令所有“信众”视为对 %dest 使用一张【%arg】",
  ["#rihui-get"] = "日慧：你可以获得 %dest 区域内一张牌",

  ["$jizhong1"] = "聚八方之众，昭黄天之明。",
  ["$jizhong2"] = "联苦厄黎庶，传大道太平。",
  ["$rihui1"] = "甲子双至，黄巾再起。",
  ["$rihui2"] = "日中必彗，操刀必割。",
  ["$guangshi1"] = "舍身饲火，光耀人间。",
  ["$guangshi2"] = "愿为奉光之薪柴，照太平于人间。",
  ["~zhangchu"] = "苦难不尽，黄天不死……",
}

local zhangmancheng = General(extension, "ty__zhangmancheng", "qun", 4)
local luecheng = fk.CreateActiveSkill{
  name = "luecheng",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(target, "@@luecheng-turn", 1)
    local card
    for _, id in ipairs(player:getCardIds(Player.Hand)) do
      card = Fk:getCardById(id)
      if card.trueName == "slash" then
        room:setCardMark(card, "@@luecheng-inhand-phase", 1)
      end
    end
  end,
}
local luecheng_targetmod = fk.CreateTargetModSkill{
  name = "#luecheng_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return to and to:getMark("@@luecheng-turn") ~= 0 and card.trueName == "slash" and card:getMark("@@luecheng-inhand-phase") ~= 0
  end,
}
local luecheng_delay = fk.CreateTriggerSkill{
  name = "#luecheng_delay",
  events = {fk.EventPhaseEnd},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return not (player.dead or target.dead) and target.phase == Player.Finish and
    player:getMark("@@luecheng-turn") ~= 0 and not player:isKongcheng()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local cards = player:getCardIds(Player.Hand)
    player:showCards(cards)
    local slashs = table.filter(cards, function (id)
      return Fk:getCardById(id).trueName == "slash"
    end)
    while #slashs > 0 do
      local use = room:askForUseCard(player, "slash", tostring(Exppattern{ id = slashs }), "#luecheng-slash::" .. target.id, true,
      { exclusive_targets = {target.id}, bypass_distances = true, bypass_times = true })
      if use then
        use.extraUse = true
        room:useCard(use)
      else
        break
      end
      if player.dead or target.dead then break end
      slashs = table.filter(slashs, function (id)
        return table.contains(player:getCardIds(Player.Hand), id) and Fk:getCardById(id).trueName == "slash"
      end)
    end
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    return player == target and data.card.trueName == "slash" and data.card:getMark("@@luecheng-inhand-phase") ~= 0 and
    table.find(TargetGroup:getRealTargets(data.tos), function (pid)
      return player.room:getPlayerById(pid):getMark("@@luecheng-turn") > 0
    end)
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
}
local zhongji = fk.CreateTriggerSkill{
  name = "zhongji",
  anim_type = "drawcard",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:getHandcardNum() < player.maxHp and
    not table.find(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id).suit == data.card.suit end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(player.maxHp - player:getHandcardNum(), self.name)
    local n = player:usedSkillTimes(self.name, Player.HistoryTurn)
    if n > 0 then
      room:askForDiscard(player, n, n, true, self.name, false)
    end
  end,
}
luecheng:addRelatedSkill(luecheng_targetmod)
luecheng:addRelatedSkill(luecheng_delay)
zhangmancheng:addSkill(luecheng)
zhangmancheng:addSkill(zhongji)
Fk:loadTranslationTable{
  ["ty__zhangmancheng"] = "张曼成",
  ["#ty__zhangmancheng"] = "蚁萃宛洛",
  ["designer:ty__zhangmancheng"] = "快雪时晴",
  ["illustrator:ty__zhangmancheng"] = "君桓文化",
  ["luecheng"] = "掠城",
  [":luecheng"] = "出牌阶段限一次，你可以选择一名其他角色，你本回合对其使用当前手牌中的【杀】无次数限制。"..
  "若如此做，回合结束时，该角色展示手牌：若其中有【杀】，其可选择对你依次使用手牌中所有的【杀】。",
  ["zhongji"] = "螽集",
  [":zhongji"] = "当你使用牌时，若你没有该花色的手牌且手牌数小于体力上限，你可将手牌摸至体力上限并弃置X张牌（X为本回合发动此技能的次数）。",

  ["@@luecheng-turn"] = "掠城",
  ["@@luecheng-inhand-phase"] = "掠城",
  ["#luecheng_delay"] = "掠城",
  ["#luecheng-slash"] = "掠城：你可以依次对 %dest 使用手牌中所有【杀】！",

  ["$luecheng1"] = "我等一无所有，普天又有何惧？",
  ["$luecheng2"] = "我视百城为饵，皆可食之果腹。",
  ["$zhongji1"] = "羸汉暴政不息，黄巾永世不绝。",
  ["$zhongji2"] = "宛洛膏如秋实，怎可不生螟虫？",
  ["~ty__zhangmancheng"] = "逡巡不前，坐以待毙……",
}

--异军突起：公孙度 孟优 公孙修
local gongsundu = General(extension, "gongsundu", "qun", 4)
local zhenze = fk.CreateTriggerSkill{
  name = "zhenze",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Discard
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(player, {"zhenze_lose", "zhenze_recover"}, self.name)
    if choice == "zhenze_lose" then
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if ((p:getHandcardNum() > p.hp) ~= (player:getHandcardNum() > player.hp) or
          (p:getHandcardNum() == p.hp) ~= (player:getHandcardNum() == player.hp) or
          (p:getHandcardNum() < p.hp) ~= (player:getHandcardNum() < player.hp)) then
            room:loseHp(p, 1, self.name)
        end
      end
    else
      for _, p in ipairs(room:getAlivePlayers()) do
        if p:isWounded() and
          ((p:getHandcardNum() > p.hp) and (player:getHandcardNum() > player.hp) or
          (p:getHandcardNum() == p.hp) and (player:getHandcardNum() == player.hp) or
          (p:getHandcardNum() < p.hp) and (player:getHandcardNum() < player.hp)) then
            room:recover({
              who = p,
              num = 1,
              recoverBy = player,
              skillName = self.name
            })
        end
      end
    end
  end,
}
local anliao = fk.CreateActiveSkill{
  name = "anliao",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    local n = 0
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if p.kingdom == "qun" then
        n = n + 1
      end
    end
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < n
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and not Fk:currentRoom():getPlayerById(to_select):isNude()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local id = room:askForCardChosen(player, target, "he", self.name)
    room:recastCard({id}, target, self.name)
  end,
}
gongsundu:addSkill(zhenze)
gongsundu:addSkill(anliao)
Fk:loadTranslationTable{
  ["gongsundu"] = "公孙度",
  ["#gongsundu"] = "雄张海东",
  ["designer:gongsundu"] = "拔都沙皇",
  ["illustrator:gongsundu"] = "匠人绘",
  ["zhenze"] = "震泽",
  [":zhenze"] = "弃牌阶段开始时，你可以选择一项：1.令所有手牌数和体力值的大小关系与你不同的角色失去1点体力；"..
  "2.令所有手牌数和体力值的大小关系与你相同的角色回复1点体力。",
  ["anliao"] = "安辽",
  [":anliao"] = "出牌阶段限X次（X为群势力角色数），你可以重铸一名角色的一张牌。",
  ["zhenze_lose"] = "手牌数和体力值的大小关系与你不同的角色失去1点体力",
  ["zhenze_recover"] = "所有手牌数和体力值的大小关系与你相同的角色回复1点体力",

  ["$zhenze1"] = "名震千里，泽被海东。",
  ["$zhenze2"] = "施威除暴，上下咸服。",
  ["$anliao1"] = "地阔天高，大有可为。",
  ["$anliao2"] = "水草丰沛，当展宏图。",
  ["~gongsundu"] = "为何都不愿出仕！",
}

local mengyou = General(extension, "mengyou", "qun", 5)
local manzhi = fk.CreateTriggerSkill{
  name = "manzhi",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player ~= target or not player:hasSkill(self) then return end
    local room = player.room
    if player.phase == Player.Finish then
      if player:getMark("@manzhi-turn") == 0 or player.hp ~= tonumber(player:getMark("@manzhi-turn")) then return end
      local record = U.getMark(player, "_manzhi-turn")
      if #record >= 2 then return end
      return table.find(room:getOtherPlayers(player), function(p)
        return (not table.contains(record, "manzhi_give") and #p:getCardIds("he") > 1)
        or (not table.contains(record, "manzhi_get") and #p:getCardIds("hej") > 0)
      end)
    elseif player.phase == Player.Start then
      return table.find(room.alive_players, function(p) return not p:isAllNude() and p ~= player end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local _, dat = room:askForUseActiveSkill(player, "manzhi_active", "#manzhi-ask", true, nil, false)
    if dat then
      local choice = dat.interaction
      local record = U.getMark(player, "_manzhi-turn")
      table.insertIfNeed(record, choice)
      room:setPlayerMark(player, "_manzhi-turn", record)
      self.cost_data = {dat.targets[1], choice}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data[1])
    local choice = self.cost_data[2]
    if choice == "manzhi_give" then
      local cards = room:askForCard(to, 2, 2, true, self.name, false, nil, "#manzhi-give:" .. player.id)
      room:moveCardTo(cards, Player.Hand, player, fk.ReasonGive, self.name, nil, false, player.id)
      if not to.dead then
        U.askForUseVirtualCard(room, to,  "slash", nil, self.name, nil, false, true, true)
      end
    else
      local card = room:askForCardsChosen(player, to, 1, 2, "hej", self.name)
      room:moveCardTo(card, Player.Hand, player, fk.ReasonPrey, self.name, nil, false, player.id)
      local num = #card
      if player.dead or player:isNude() then return false end
      local give = player:getCardIds{Player.Hand, Player.Equip}
      if #give > num then
        give = room:askForCard(player, num, num, true, self.name, false, nil, "#manzhi-back::" .. to.id .. ":" .. num)
      end
      room:moveCardTo(give, Player.Hand, to, fk.ReasonGive, self.name, nil, false, player.id)
      if not player.dead then player:drawCards(1, self.name) end
    end
  end,

  refresh_events = {fk.EventPhaseStart},
  can_refresh = function(self, event, target, player, data)
    return player == target and target:hasSkill(self) and player.phase == Player.Start -- ...
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@manzhi-turn", tostring(player.hp))
  end,
}
local manzhi_active = fk.CreateActiveSkill{
  name = "manzhi_active",
  card_num = 0,
  target_num = 1,
  interaction = function()
    local all_choices = {"manzhi_give", "manzhi_prey"}
    local choices = table.filter(all_choices, function (str) return not table.contains(U.getMark(Self, "_manzhi-turn"), str) end)
    return UI.ComboBox {choices = choices, all_choices = all_choices}
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    local to = Fk:currentRoom():getPlayerById(to_select)
    if #selected > 0 or  Self.id == to_select then return false end
    if self.interaction.data == "manzhi_give" then
      return #to:getCardIds("he") > 1
    else
      return not to:isAllNude()
    end
  end,
}
Fk:addSkill(manzhi_active)
mengyou:addSkill("manyi")
mengyou:addSkill(manzhi)

Fk:loadTranslationTable{
  ["mengyou"] = "孟优",
  ["#mengyou"] = "蛮杰陷谋",
  ["designer:mengyou"] = "残昼厄夜",
  ["illustrator:mengyou"] = "韩少侠&错落宇宙",
  ["manzhi"] = "蛮智",
  [":manzhi"] = "准备阶段，你可以选择一名其他角色，然后选择一项：1.令其交给你两张牌，然后其视为使用一张无距离限制的【杀】；"..
  "2.获得其区域内的至多两张牌，然后交给其等量牌并摸一张牌。"..
  "结束阶段，若你的体力值与此回合准备阶段开始时相等，你可以执行此回合未选择过的一项。",

  ["manzhi_active"] = "蛮智",
  ["#manzhi-ask"] = "你可对一名其他角色发动“蛮智”",
  ["manzhi_give"] = "令其交给你两张牌，其视为使用【杀】",
  ["manzhi_prey"] = "获得至多两张牌，交给其等量牌并牌",
  ["#manzhi-give"] = "蛮智：请交给%src两张牌",
  ["#manzhi_slash-ask"] = "蛮智：视为使用一张无距离限制的【杀】",
  ["#manzhi-back"] = "蛮智：交给%dest%arg张牌",
  ["@manzhi-turn"] = "蛮智",

  ["$manyi_mengyou1"] = "我辈蛮夷久居荒野，岂为兽虫所伤。",
  ["$manyi_mengyou2"] = "我乃蛮王孟获之弟，谁敢伤我！",
  ["$manzhi1"] = "吾有蛮勇可攻，亦有蛮智可御。",
  ["$manzhi2"] = "远交近攻之法，怎可不为我所用。",
  ["~mengyou"] = "大哥，诸葛亮又打来了。",
}

local gongsunxiu = General(extension, "gongsunxiu", "qun", 4)
local gangu = fk.CreateTriggerSkill{
  name = "gangu",
  frequency = Skill.Compulsory,
  events = {fk.HpLost},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:usedSkillTimes(self.name) == 0
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
    if not player.dead then
      player.room:loseHp(player, 1, self.name)
    end
  end,
}
local kuizhen = fk.CreateActiveSkill{
  name = "kuizhen",
  anim_type = "offensive",
  prompt = "#kuizhen-active",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    if #selected == 0 then
      local target = Fk:currentRoom():getPlayerById(to_select)
      if target.hp > Self.hp or target:getHandcardNum() > Self:getHandcardNum() then
        local duel = Fk:cloneCard("duel")
        duel.skillName = self.name
        return target:canUseTo(duel, Self)
      end
    end
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local card = Fk:cloneCard("duel")
    card.skillName = self.name
    local use = {} ---@type CardUseStruct
    use.from = target.id
    use.tos = { {player.id} }
    use.card = card
    use.extraUse = true
    room:useCard(use)
    if target.dead then return end
    if use.damageDealt and use.damageDealt[player.id] then
      if player.dead then return end
      local cards = target:getCardIds(Player.Hand)
      if #cards == 0 then return end
      U.viewCards(player, cards, self.name)
      cards = table.filter(cards, function (id)
        return Fk:getCardById(id).trueName == "slash"
      end)
      if #cards == 0 then return end
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id, "@@kuizhen-inhand")
    else
      room:loseHp(target, 1, self.name)
    end
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    return player == target and
    data.card.trueName == "slash" and not data.card:isVirtual() and data.card:getMark("@@kuizhen-inhand") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
}
local kuizhen_targetmod = fk.CreateTargetModSkill{
  name = "#kuizhen_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return card and card.trueName == "slash" and not card:isVirtual() and card:getMark("@@kuizhen-inhand") > 0
  end,
}
kuizhen:addRelatedSkill(kuizhen_targetmod)
gongsunxiu:addSkill(gangu)
gongsunxiu:addSkill(kuizhen)
Fk:loadTranslationTable{
  ["gongsunxiu"] = "公孙修",
  ["#gongsunxiu"] = "寸莛击钟",
  ["illustrator:gongsunxiu"] = "鬼画府",
  ["gangu"] = "干蛊",
  [":gangu"] = "锁定技，当一名角色失去体力后，若你于当前回合内未发动过此技能，你摸两张牌，失去1点体力。",
  ["kuizhen"] = "溃阵",
  [":kuizhen"] = "出牌阶段限一次，你可以选择一名手牌数或体力值大于你的角色，其视为对你使用【决斗】，若你："..
  "受到过此【决斗】造成的伤害，你观看其所有手牌，获得其中所有的【杀】且你使用以此法获得的【杀】无次数限制；"..
  "未受到过此【决斗】造成的伤害，其失去1点体力。",

  ["#kuizhen-active"] = "发动 溃阵，选择一名角色，令其视为对你使用【决斗】",
  ["@@kuizhen-inhand"] = "溃阵",

  ["$gangu1"] = "承志奉祠，达于行伍之事。",
  ["$gangu2"] = "干父之蛊，全辽裔未竟之业。",
  ["$kuizhen1"] = "今一马当先，效霸王破釜！",
  ["$kuizhen2"] = "自古北马皆傲，视南风为鱼俎。",
  ["~gongsunxiu"] = "大星坠地，父子俱亡……",
}



--正音雅乐：蔡文姬 周妃 蔡邕 大乔 小乔
local caiwenji = General(extension, "mu__caiwenji", "qun", 3, 3, General.Female)
local shuangjia = fk.CreateTriggerSkill{
  name = "shuangjia",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getCardIds(Player.Hand)
    for _, id in ipairs(cards) do
      room:setCardMark(Fk:getCardById(id), "@@shuangjia-inhand", 1)
    end
    room:setPlayerMark(player, "beifen", cards)
    room:setPlayerMark(player, "@shuangjia", #cards)
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return #U.getMark(player, "beifen") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = U.getMark(player, "beifen")
    for _, id in ipairs(player:getCardIds(Player.Hand)) do
      local card = Fk:getCardById(id)
      local value = table.contains(mark, id) and 1 or 0
      if card:getMark("@@shuangjia-inhand") ~= value then
        room:setCardMark(card, "@@shuangjia-inhand", value)
      end
    end
  end,
}
local shuangjia_maxcards = fk.CreateMaxCardsSkill{
  name = "#shuangjia_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@shuangjia-inhand") > 0
  end,
}
local shuangjia_distance = fk.CreateDistanceSkill{
  name = "#shuangjia_distance",
  correct_func = function(self, from, to)
    return math.min(to:getMark("@shuangjia"), 5)
  end,
}
local beifen = fk.CreateTriggerSkill{
  name = "beifen",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      local mark = U.getMark(player, "beifen")
      if #mark == 0 then return false end
      local cards = {}
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand and table.contains(mark, info.cardId) then
              table.insert(cards, info.cardId)
            end
          end
        end
      end
      if #cards > 0 then
        self.cost_data = cards
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = U.getMark(player, "beifen")
    for _, id in ipairs(self.cost_data) do
      table.removeOne(mark, id)
    end
    room:setPlayerMark(player, "beifen", #mark > 0 and mark or 0)
    room:setPlayerMark(player, "@shuangjia", #mark)

    local suits = {"heart", "diamond", "spade", "club"}
    for _, id in ipairs(player:getCardIds(Player.Hand)) do
      local card = Fk:getCardById(id)
      if card:getMark("@@shuangjia-inhand") > 0 then
        table.removeOne(suits, card:getSuitString())
      end
    end
    if #suits == 0 then return false end
    local patternTable = {}
    for _, suit in ipairs(suits) do
      patternTable[suit] = {}
    end
    for _, id in ipairs(room.draw_pile) do
      local suit = Fk:getCardById(id):getSuitString()
      if table.contains(suits, suit) then
        table.insert(patternTable[suit], id)
      end
    end
    local cards = {}
    for _, suit in ipairs(suits) do
      local ids = patternTable[suit]
      if #ids > 0 then
        table.insert(cards, table.random(ids))
      end
    end
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
    end
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    return player == target and player:hasSkill(self) and player:usedSkillTimes("shuangjia", Player.HistoryGame) > 0 and
    player:getHandcardNum() > 2 * player:getMark("@shuangjia")
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
}
local beifen_targetmod = fk.CreateTargetModSkill{
  name = "#beifen_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return player:hasSkill(beifen) and player:usedSkillTimes("shuangjia", Player.HistoryGame) > 0 and
    player:getHandcardNum() > 2 * player:getMark("@shuangjia")
  end,
  bypass_distances = function(self, player, skill, card, to)
    return player:hasSkill(beifen) and player:usedSkillTimes("shuangjia", Player.HistoryGame) > 0 and
    player:getHandcardNum() > 2 * player:getMark("@shuangjia")
  end,
}
shuangjia:addRelatedSkill(shuangjia_maxcards)
shuangjia:addRelatedSkill(shuangjia_distance)
beifen:addRelatedSkill(beifen_targetmod)
caiwenji:addSkill(shuangjia)
caiwenji:addSkill(beifen)
Fk:loadTranslationTable{
  ["mu__caiwenji"] = "乐蔡文姬",
  ["#mu__caiwenji"] = "胡笳十八拍",
  ["designer:mu__caiwenji"] = "星移",
  ["illustrator:mu__caiwenji"] = "匠人绘",
  ["shuangjia"] = "霜笳",
  [":shuangjia"] = "锁定技，游戏开始时，你的初始手牌增加“胡笳”标记且不计入手牌上限。你每拥有一张“胡笳”，其他角色计算与你距离+1（最多+5）。",
  ["beifen"] = "悲愤",
  [":beifen"] = "锁定技，当你失去“胡笳”后，你获得与手中“胡笳”花色均不同的牌各一张。你手中“胡笳”少于其他牌时，你使用牌无距离和次数限制。",
  ["@@shuangjia-inhand"] = "胡笳",
  ["@shuangjia"] = "胡笳",

  ["$shuangjia1"] = "塞外青鸟匿，不闻折柳声。",
  ["$shuangjia2"] = "向晚吹霜笳，雪落白发生。",
  ["$beifen1"] = "此心如置冰壶，无物可暖。",
  ["$beifen2"] = "年少爱登楼，欲说语还休。",
  ["~mu__caiwenji"] = "天何薄我，天何薄我……",
}

local zhoufei = General(extension, "mu__zhoufei", "wu", 3, 3, General.Female)
local lingkong = fk.CreateTriggerSkill{
  name = "lingkong",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.GameStart, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    local handcards = player:getCardIds(Player.Hand)
    if event == fk.GameStart then
      return #handcards > 0
    elseif event == fk.AfterCardsMove then
      local room = player.room
      if room.current == nil or room.current.phase == Player.Draw or player:getMark("lingkongused-turn") > 0 then return false end
      local cards = {}
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Player.Hand then
          for _, info in ipairs(move.moveInfo) do
            local id = info.cardId
            if table.contains(handcards, id) then
              table.insert(cards, id)
            end
          end
        end
      end
      cards = U.moveCardsHoldingAreaCheck(player.room, cards)
      if #cards > 0 then
        self.cost_data = cards
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      for _, id in ipairs(player.player_cards[Player.Hand]) do
        room:setCardMark(Fk:getCardById(id), "@@konghou-inhand", 1)
      end
    elseif event == fk.AfterCardsMove then
      room:setPlayerMark(player, "lingkongused-turn", 1)
      for _, id in ipairs(self.cost_data) do
        room:setCardMark(Fk:getCardById(id), "@@konghou-inhand", 1)
      end
    end
  end,
}
local lingkong_maxcards = fk.CreateMaxCardsSkill{
  name = "#lingkong_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@konghou-inhand") > 0
  end,
}
local xianshu = fk.CreateActiveSkill{
  name = "xianshu",
  card_num = 1,
  target_num = 1,
  prompt = "#xianshu-active",
  anim_type = "drawcard",
  can_use = Util.TrueFunc,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select):getMark("@@konghou-inhand") > 0
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local color = Fk:getCardById(effect.cards[1]).color
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:obtainCard(target.id, effect.cards[1], true, fk.ReasonGive, player.id)
    if player.dead or target.dead then return end
    local x = math.abs(player.hp - target.hp)
    if x > 0 then
      room:drawCards(player, math.min(x, 5), self.name)
    end
    if player.dead or target.dead then return end
    if color == Card.Red and target.hp <= player.hp and target:isWounded() then
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name
      }
    end
    if color == Card.Black and target.hp >= player.hp then
      room:loseHp(target, 1, self.name)
    end
  end,
}
lingkong:addRelatedSkill(lingkong_maxcards)
zhoufei:addSkill(lingkong)
zhoufei:addSkill(xianshu)
Fk:loadTranslationTable{
  ["mu__zhoufei"] = "乐周妃",
  ["#mu__zhoufei"] = "芙蓉泣露",
  ["illustrator:mu__zhoufei"] = "匠人绘",
  ["lingkong"] = "灵箜",
  [":lingkong"] = "锁定技，游戏开始时，你的初始手牌增加“箜篌”标记且不计入手牌上限。每回合你于摸牌阶段外首次获得牌后，将这些牌标记为“箜篌”。",
  ["xianshu"] = "贤淑",
  [":xianshu"] = "出牌阶段，你可以将一张“箜篌”牌交给一名其他角色并摸X张牌（X为你与该角色体力值之差且至多为5），"..
  "若此牌为：红色，且该角色体力值不大于你，该角色回复1点体力；黑色，且该角色体力值不小于你，该角色失去1点体力。",

  ["@@konghou-inhand"] = "箜篌",
  ["#xianshu-active"] = "发动 贤淑，选择一张带有“箜篌”标记的牌交给其他角色",

  ["$lingkong1"] = "箜篌奏晚歌，渔樵有归期。",
  ["$lingkong2"] = "吴宫绿荷惊涟漪，飞燕啄新泥。",
  ["$xianshu1"] = "居宠而不骄，秉贤淑于内庭。",
  ["$xianshu2"] = "心怀玲珑意，宜家国于春秋。",
  ["~mu__zhoufei"] = "红颜薄命，望君珍重……",
}

local daqiao = General(extension, "mu__daqiao", "wu", 3, 3, General.Female)
local qiqin = fk.CreateTriggerSkill{
  name = "qiqin",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.GameStart, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if event == fk.GameStart then
      return player:hasSkill(self) and not player:isKongcheng()
    elseif player:hasSkill(self) and target == player and player.phase == Player.Start then
      local get = table.filter(player.room.discard_pile, function(id)
        return Fk:getCardById(id):getMark("qiqin") > 0
      end)
      if #get > 0 then
        self.cost_data = get
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local cards = player:getCardIds(Player.Hand)
      for _, id in ipairs(cards) do
        room:setCardMark(Fk:getCardById(id), "@@qiqin-inhand", 1)
        room:setCardMark(Fk:getCardById(id), "qiqin", 1)
      end
    else
      room:moveCardTo(self.cost_data, Player.Hand, player, fk.ReasonJustMove, self.name, "", false, player.id)
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(player:getCardIds(Player.Hand)) do
      local card = Fk:getCardById(id)
      local value = (card:getMark("qiqin") > 0 and player:hasSkill(self, true)) and 1 or 0
      if card:getMark("@@qiqin-inhand") ~= value then
        room:setCardMark(card, "@@qiqin-inhand", value)
      end
    end
  end,
}
local qiqin_maxcards = fk.CreateMaxCardsSkill{
  name = "#qiqin_maxcards",
  exclude_from = function(self, player, card)
    return player:hasSkill(qiqin) and card:getMark("qiqin") > 0
  end,
}
Fk:addQmlMark{
  name = "zixi",
  how_to_show = function(name, value, p)
    if type(value) ~= "table" then return " " end
    return table.concat(table.map(value, function(zixi_pair)
      return Fk:translate(zixi_pair[2] .. "_short")
    end), " ")
  end,
  qml_path = "packages/tenyear/qml/ZixiBox"
}
local zixi_active = fk.CreateActiveSkill{
  name = "zixi_active",
  card_num = 1,
  target_num = 1,
  interaction = function()
    return UI.ComboBox {choices = {"indulgence", "supply_shortage", "lightning"}}
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select):getMark("qiqin") > 0
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected_cards == 0 or #selected > 0 then return false end
    local to = Fk:currentRoom():getPlayerById(to_select)
    return not (table.contains(to.sealedSlots, Player.JudgeSlot) or to:hasDelayedTrick(self.interaction.data))
  end,
}
Fk:addSkill(zixi_active)
local zixi = fk.CreateTriggerSkill{
  name = "zixi",
  anim_type = "control",
  events = {fk.EventPhaseStart, fk.EventPhaseEnd, fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(self) then return false end
    if event == fk.TargetSpecified then
      if (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      not table.contains(data.card.skillNames, self.name) then
        local to = player.room:getPlayerById(data.to)
        local x = #to:getCardIds(Player.Judge)
        if x > 0 and x < 4 and U.isOnlyTarget(to, data, event) then
          return true
        end
      end
    else
      return player.phase == Player.Play and not player:isNude()
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetSpecified then
      local to = room:getPlayerById(data.to)
      local x = #to:getCardIds(Player.Judge)
      if room:askForSkillInvoke(player, self.name, nil,
      "#zixi-invoke" .. tostring(x) .. "::" .. data.to .. ":" .. data.card:toLogString()) then
        room:doIndicate(player.id, {data.to})
        return true
      end
    else
      local _, dat = room:askForUseActiveSkill(player, "zixi_active", "#zixi-cost", true)
      if dat then
        self.cost_data = dat
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetSpecified then
      local to = room:getPlayerById(data.to)
      local x = #to:getCardIds(Player.Judge)
      if x == 1 then
        data.extra_data = data.extra_data or {}
        data.extra_data.zixi = {
          from = player.id,
          to = data.to,
          subTargets = data.subTargets
        }
      elseif x == 2 then
        room:drawCards(player, 2, self.name)
      elseif x == 3 then
        to:throwAllCards("j")
        if not to.dead then
          room:damage{
            from = player,
            to = to,
            damage = 3,
            skillName = self.name,
          }
        end
      end
    else
      local dat = table.simpleClone(self.cost_data)
      local to = room:getPlayerById(dat.targets[1])
      local card = Fk:cloneCard(dat.interaction)
      card:addSubcard(dat.cards[1])
      card.skillName = self.name
      to:addVirtualEquip(card)
      room:moveCardTo(card, Player.Judge, to, fk.ReasonJustMove, self.name)
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = {}
    for _, id in ipairs(player:getCardIds(Player.Judge)) do
      local zixi_card = player:getVirualEquip(id)
      if zixi_card and table.contains(zixi_card.skillNames, "zixi") then
        table.insert(mark, {id, zixi_card.trueName})
      end
    end
    local old_mark = player:getMark("@[zixi]")
    if #mark == 0 then
      if old_mark ~= 0 then
        room:setPlayerMark(player, "@[zixi]", 0)
      end
      return false
    end
    if type(old_mark) ~= "table" or #mark ~= #old_mark then
      room:setPlayerMark(player, "@[zixi]", mark)
    end
  end,
}
local zixi_delay = fk.CreateTriggerSkill{
  name = "#zixi_delay",
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if data.extra_data and data.extra_data.zixi and not player.dead then
      local use = table.simpleClone(data.extra_data.zixi)
      if use.from == player.id then
        local card = Fk:cloneCard(data.card.name)
        card.skillName = zixi.name
        if player:prohibitUse(card) then return false end
        use.card = card
        local room = player.room
        local to = room:getPlayerById(use.to)
        if not to.dead and U.canTransferTarget(to, use, false) then
          local tos = {use.to}
          if use.subTargets then
            table.insertTable(tos, use.subTargets)
          end
          self.cost_data = {
            from = player.id,
            tos = table.map(tos, function(pid) return { pid } end),
            card = card,
            extraUse = true
          }
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:useCard(table.simpleClone(self.cost_data))
  end,
}
local zixi_special_rule = fk.CreateTriggerSkill{
  name = "#zixi_special_rule",
  events = {fk.EventPhaseStart},
  mute = true,
  priority = 0, -- game rule
  can_trigger = function(self, event, target, player, data)
    return player.phase == Player.Judge
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getCardIds(Player.Judge)
    for i = #cards, 1, -1 do
      if table.contains(player:getCardIds(Player.Judge), cards[i]) then
        local zixi_card = player:getVirualEquip(cards[i])
        if zixi_card == nil or not table.contains(zixi_card.skillNames, "zixi") then
          local card
          card = player:removeVirtualEquip(cards[i])
          if not card then
            card = Fk:getCardById(cards[i])
          end
          
          room:moveCardTo(card, Card.Processing, nil, fk.ReasonPut, "game_rule")

          ---@type CardEffectEvent
          local effect_data = {
            card = card,
            to = player.id,
            tos = { {player.id} },
          }
          room:doCardEffect(effect_data)
          if effect_data.isCancellOut and card.skill then
            card.skill:onNullified(room, effect_data)
          end
        end
      end
    end
    return true
  end,
}

qiqin:addRelatedSkill(qiqin_maxcards)
zixi:addRelatedSkill(zixi_delay)
zixi:addRelatedSkill(zixi_special_rule)
daqiao:addSkill(qiqin)
daqiao:addSkill(zixi)

Fk:loadTranslationTable{
  ["mu__daqiao"] = "乐大乔",
  ["#mu__daqiao"] = "玉桐姊韵",
  ["designer:mu__daqiao"] = "星移",

  ["qiqin"] = "绮琴",
  [":qiqin"] = "锁定技，游戏开始时，你的初始手牌增加“琴”标记且不计入手牌上限。准备阶段，你获得弃牌堆中所有“琴”牌。",
  ["zixi"] = "姊希",
  [":zixi"] = "出牌阶段开始时和结束时，你可以将一张“琴”放置在一名角色的判定区"..
  "（牌名当做【兵粮寸断】、【乐不思蜀】或【闪电】使用，且判定阶段不执行效果）。"..
  "你使用基本牌或普通锦囊牌指定唯一目标后，可根据其判定区牌的张数执行："..
  "1张：此牌结算后，你视为对其使用一张牌名相同的牌；2张：你摸2张牌；3张：弃置其判定区所有牌，对其造成3点伤害。",
  ["@@qiqin-inhand"] = "琴",
  ["#zixi-cost"] = "是否发动 姊希，将一张“琴”放置在一名角色的判定区",
  ["zixi_active"] = "姊希",
  ["#zixi_delay"] = "姊希",
  ["#zixi_special_rule"] = "姊希",
  ["#zixi-invoke1"] = "是否发动 姊希，令%arg对%dest额外结算一次",
  ["#zixi-invoke2"] = "是否发动 姊希，摸两张牌",
  ["#zixi-invoke3"] = "是否发动 姊希，令%dest弃置判定区所有牌并受到3点伤害",

  ["@[zixi]"] = "姊希",
  ["indulgence_short"] = "乐",
  ["supply_shortage_short"] = "兵",
  ["lightning_short"] = "电",

  ["$qiqin_mu__daqiao1"] = "山月栖瑶琴，一曲渔歌和晚音。",
  ["$qiqin_mu__daqiao2"] = "指尖有琴音，何不于君指上听？",
  ["$zixi1"] = "日暮飞伯劳，倦梳头，坐看鸥鹭争舟。",
  ["$zixi2"] = "姊折翠柳寄江北，念君心悠悠。",
  ["~mu__daqiao"] = "曲终人散，再会奈何桥畔……",
}

local xiaoqiao = General(extension, "mu__xiaoqiao", "wu", 3, 3, General.Female)
local weiwan = fk.CreateActiveSkill{
  name = "weiwan",
  anim_type = "offensive",
  prompt = "#weiwan-active",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_num = 1,
  card_filter = function (self, to_select, selected)
    if #selected > 0 then return false end
    local card = Fk:getCardById(to_select)
    return not Self:prohibitDiscard(card) and card:getMark("qiqin") > 0
  end,
  target_num = 1,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.tos[1])
    local qin_suit = Fk:getCardById(effect.cards[1]).suit
    room:throwCard(effect.cards, self.name, player, player)
    if player.dead or to.dead then return end
    local cardsMap = {}
    for _, id in ipairs(to:getCardIds("hej")) do
      local suit = Fk:getCardById(id).suit
      if suit ~= Card.NoSuit and suit ~= qin_suit then
        cardsMap[suit] = cardsMap[suit] or {}
        table.insert(cardsMap[suit], id)
      end
    end
    local get = {}
    for _, value in pairs(cardsMap) do
      table.insert(get, table.random(value))
    end
    if #get > 0 then
      room:moveCardTo(get, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, true, player.id)
      if to.dead then return end
      if #get == 1 then
        room:loseHp(to, 1, self.name)
      elseif #get == 2 then
        local mark = U.getMark(player, "weiwan_targetmod-turn")
        table.insert(mark, to.id)
        room:setPlayerMark(player, "weiwan_targetmod-turn", mark)
      elseif #get == 3 then
        local mark = U.getMark(player, "weiwan_prohibit-turn")
        table.insert(mark, to.id)
        room:setPlayerMark(player, "weiwan_prohibit-turn", mark)
      end
    end
  end,
}
local weiwan_refresh = fk.CreateTriggerSkill{
  name = "#weiwan_refresh",

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    if player == target then
      local mark = U.getMark(player, "weiwan_targetmod-turn")
      return #mark > 0 and table.find(TargetGroup:getRealTargets(data.tos), function (pid)
        return table.contains(mark, pid)
      end)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
}
local weiwan_targetmod = fk.CreateTargetModSkill{
  name = "#weiwan_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return to and table.contains(U.getMark(player, "weiwan_targetmod-turn"), to.id)
  end,
  bypass_distances = function(self, player, skill, card, to)
    return to and table.contains(U.getMark(player, "weiwan_targetmod-turn"), to.id)
  end,
}
local weiwan_prohibit = fk.CreateProhibitSkill{
  name = "#weiwan_prohibit",
  is_prohibited = function(self, player, to, card)
    return table.contains(U.getMark(player, "weiwan_prohibit-turn"), to.id)
  end,
}
weiwan:addRelatedSkill(weiwan_refresh)
weiwan:addRelatedSkill(weiwan_targetmod)
weiwan:addRelatedSkill(weiwan_prohibit)
xiaoqiao:addSkill("qiqin")
xiaoqiao:addSkill(weiwan)
Fk:loadTranslationTable{
  ["mu__xiaoqiao"] = "乐小乔",
  ["#mu__xiaoqiao"] = "绿绮嫒媛",
  ["designer:mu__xiaoqiao"] = "星移",

  ["weiwan"] = "媦婉",
  [":weiwan"] = "出牌阶段限一次，你可以弃置一张“琴”并选择一名其他角色，随机获得其区域内与此“琴”不同花色的牌各一张。"..
  "若你获得的牌数为：1，其失去1点体力；2，你本回合对其使用牌无距离与次数限制；3，你本回合不能对其使用牌。",
  ["#weiwan-active"] = "发动 媦婉，选择一张“琴”弃置并选择一名其他角色",

  ["$qiqin_mu__xiaoqiao1"] = "渔歌唱晚落山月，素琴薄暮声。",
  ["$qiqin_mu__xiaoqiao2"] = "指上琴音浅，欲听还需抚瑶琴。",
  ["$weiwan1"] = "繁花初成，所幸未晚于桑榆。",
  ["$weiwan2"] = "群胥泛舟，共载佳期若瑶梦。",
  ["~mu__xiaoqiao"] = "独寄人间白首，曲误周郎难顾……",
}

return extension
