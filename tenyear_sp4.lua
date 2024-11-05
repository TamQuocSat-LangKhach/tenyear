local extension = Package("tenyear_sp4")
extension.extensionName = "tenyear"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["tenyear_sp4"] = "十周年-限定专属4",
  ["wm"] = "武",
}

--祈福：关索 赵襄 鲍三娘 徐荣 曹纯 张琪瑛
local guansuo = General(extension, "ty__guansuo", "shu", 4)
local ty__zhengnan = fk.CreateTriggerSkill{
  name = "ty__zhengnan",
  anim_type = "drawcard",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and (player:getMark(self.name) == 0 or not table.contains(player:getMark(self.name), target.id))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark(self.name)
    if mark == 0 then mark = {} end
    table.insert(mark, target.id)
    room:setPlayerMark(player, self.name, mark)
    if player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    local choices = {"ex__wusheng", "ty_ex__dangxian", "ty_ex__zhiman"}
    for i = 3, 1, -1 do
      if player:hasSkill(choices[i], true) then
        table.removeOne(choices, choices[i])
      end
    end
    if #choices > 0 then
      player:drawCards(1, self.name)
      local choice = room:askForChoice(player, choices, self.name, "#zhengnan-choice", true)
      room:handleAddLoseSkills(player, choice, nil)
      if choice == "ty_ex__dangxian" then
        room:setPlayerMark(player, "ty_ex__fuli", 1)  --直接获得升级后的当先
      end
    else
      player:drawCards(3, self.name)
    end
  end,
}
guansuo:addSkill(ty__zhengnan)
guansuo:addSkill("xiefang")
guansuo:addRelatedSkill("ex__wusheng")
guansuo:addRelatedSkill("ty_ex__dangxian")
guansuo:addRelatedSkill("ty_ex__zhiman")
Fk:loadTranslationTable{
  ["ty__guansuo"] = "关索",
  ["#ty__guansuo"] = "倜傥孑侠",
  ["illustrator:ty__guansuo"] = "第七个桔子", -- 传说皮 万花簇威
  ["ty__zhengnan"] = "征南",
  [":ty__zhengnan"] = "每名角色限一次，当一名角色进入濒死状态时，你可以回复1点体力，然后摸一张牌并选择获得下列技能中的一个："..
  "〖武圣〗，〖当先〗和〖制蛮〗（若技能均已获得，则改为摸三张牌）。",

  ["$ty__zhengnan1"] = "南征之役，愿效死力。",
  ["$ty__zhengnan2"] = "南征之险恶，吾已有所准备。",
  ["$ex__wusheng_ty__guansuo"] = "我敬佩你的勇气。",
  ["$ty_ex__dangxian_ty__guansuo"] = "时时居先，方可快人一步。",
  ["$ty_ex__zhiman_ty__guansuo"] = "败军之将，自当纳贡！",
  ["~ty__guansuo"] = "索，至死不辱家风！",
}

local zhaoxiang = General(extension, "ty__zhaoxiang", "shu", 4, 4, General.Female)
local ty__fanghun = fk.CreateViewAsSkill{
  name = "ty__fanghun",
  prompt = "#ty__fanghun-viewas",
  pattern = "slash,jink",
  card_filter = function(self, to_select, selected)
    if #selected == 1 then return false end
    local _c = Fk:getCardById(to_select)
    local c
    if _c.trueName == "slash" then
      c = Fk:cloneCard("jink")
    elseif _c.name == "jink" then
      c = Fk:cloneCard("slash")
    else
      return false
    end
    return (Fk.currentResponsePattern == nil and c.skill:canUse(Self, c)) or
      (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(c))
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then
      return nil
    end
    local _c = Fk:getCardById(cards[1])
    local c
    if _c.trueName == "slash" then
      c = Fk:cloneCard("jink")
    elseif _c.name == "jink" then
      c = Fk:cloneCard("slash")
    end
    c.skillNames = c.skillNames or {}
    table.insert(c.skillNames, "ty__fanghun")
    table.insert(c.skillNames, "longdan")
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = function(self, player)
    return player:getMark("@meiying") > 0
  end,
  enabled_at_response = function(self, player)
    return player:getMark("@meiying") > 0
  end,
  before_use = function(self, player)
    player.room:removePlayerMark(player, "@meiying")
    player:drawCards(1, self.name)
  end,
}
local ty__fanghun_trigger = fk.CreateTriggerSkill{
  name = "#ty__fanghun_trigger",
  events = {fk.TargetSpecified, fk.TargetConfirmed},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, "ty__fanghun")
    if not table.contains(data.card.skillNames, "ty__fanghun") or event == fk.TargetConfirmed then
      player:broadcastSkillInvoke("ty__fanghun")
    end
    room:addPlayerMark(player, "@meiying")
  end,
}
local ty__fuhan = fk.CreateTriggerSkill{
  name = "ty__fuhan",
  events = {fk.TurnStart},
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:getMark("@meiying") > 0 and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#ty__fuhan-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:getMark("@meiying")
    room:setPlayerMark(player, "@meiying", 0)
    player:drawCards(n, self.name)
    if player.dead then return end

    local generals, same_g = {}, {}
    for _, general_name in ipairs(room.general_pile) do
      same_g = Fk:getSameGenerals(general_name)
      table.insert(same_g, general_name)
      same_g = table.filter(same_g, function (g_name)
        local general = Fk.generals[g_name]
        return general.kingdom == "shu" or general.subkingdom == "shu"
      end)
      if #same_g > 0 then
        table.insert(generals, table.random(same_g))
      end
    end
    if #generals == 0 then return false end
    generals = table.random(generals, math.max(4, #room.alive_players))

    local skills = {}
    local choices = {}
    for _, general_name in ipairs(generals) do
      local general = Fk.generals[general_name]
      local g_skills = {}
      for _, skill in ipairs(general.skills) do
        if not (table.contains({Skill.Limited, Skill.Wake, Skill.Quest}, skill.frequency) or skill.lordSkill) and
        (#skill.attachedKingdom == 0 or (table.contains(skill.attachedKingdom, "shu") and player.kingdom == "shu")) then
          table.insertIfNeed(g_skills, skill.name)
        end
      end
      for _, s_name in ipairs(general.other_skills) do
        local skill = Fk.skills[s_name]
        if not (table.contains({Skill.Limited, Skill.Wake, Skill.Quest}, skill.frequency) or skill.lordSkill) and
        (#skill.attachedKingdom == 0 or (table.contains(skill.attachedKingdom, "shu") and player.kingdom == "shu")) then
          table.insertIfNeed(g_skills, skill.name)
        end
      end
      table.insertIfNeed(skills, g_skills)
      if #choices == 0 and #g_skills > 0 then
        choices = {g_skills[1]}
      end
    end
    if #choices > 0 then
      local result = player.room:askForCustomDialog(player, self.name,
      "packages/tenyear/qml/ChooseGeneralSkillsBox.qml", {
        generals, skills, 1, 2, "#ty__fuhan-choice", false
      })
      if result ~= "" then
        choices = json.decode(result)
      end
      room:handleAddLoseSkills(player, table.concat(choices, "|"), nil)
    end

    if not player.dead and player:isWounded() and
    table.every(room.alive_players, function(p) return p.hp >= player.hp end) then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
ty__fanghun:addRelatedSkill(ty__fanghun_trigger)
zhaoxiang:addSkill(ty__fanghun)
zhaoxiang:addSkill(ty__fuhan)
Fk:loadTranslationTable{
  ["ty__zhaoxiang"] = "赵襄",
  ["#ty__zhaoxiang"] = "拾梅鹊影",
  ["cv:ty__zhaoxiang"] = "闲踏梧桐",
  ["illustrator:ty__zhaoxiang"] = "木美人", -- 传说皮 芳芷飒敌
  ["ty__fanghun"] = "芳魂",
  [":ty__fanghun"] = "当你使用【杀】指定目标后或成为【杀】的目标后，你获得1个“梅影”标记；你可以移去1个“梅影”标记发动〖龙胆〗并摸一张牌。",
  ["ty__fuhan"] = "扶汉",
  [":ty__fuhan"] = "限定技，回合开始时，若你有“梅影”标记，你可以移去所有“梅影”标记并摸等量的牌，然后从X张（X为存活人数且至少为4）蜀势力"..
  "武将牌中选择并获得至多两个技能（限定技、觉醒技、主公技除外）。若此时你是体力值最低的角色，你回复1点体力。",
  ["#ty__fanghun-viewas"] = "发动 芳魂，弃1枚”梅影“，将【杀】当【闪】、【闪】当【杀】使用或打出，并摸一张牌",
  ["#ty__fanghun_trigger"] = "芳魂",
  ["#ty__fuhan-invoke"] = "扶汉：你可以移去“梅影”标记，获得两个蜀势力武将的技能！",
  ["#ty__fuhan-choice"] = "扶汉：选择你要获得的至多2个技能",

  ["$ty__fanghun1"] = "芳年华月，不负期望。",
  ["$ty__fanghun2"] = "志洁行芳，承父高志。",
  ["$ty__fuhan1"] = "汉盛刘兴，定可指日成之。",
  ["$ty__fuhan2"] = "蜀汉兴存，吾必定尽力而为。",
  ["~ty__zhaoxiang"] = "此生为汉臣，死为汉芳魂……",
}

local baosanniang = General(extension, "ty__baosanniang", "shu", 3, 3, General.Female)
local ty__wuniang = fk.CreateTriggerSkill{
  name = "ty__wuniang",
  anim_type = "control",
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash" and
      not table.every(player.room:getOtherPlayers(player, false), function(p) return p:isNude() end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local prompt = "#ty__wuniang1-choose"
    if player:usedSkillTimes("ty__xushen", Player.HistoryGame) > 0 and
      table.find(room.alive_players, function(p) return string.find(p.general, "guansuo") end) then
      prompt = "#ty__wuniang2-choose"
    end
    local to = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isNude() end), Util.IdMapper), 1, 1, prompt, self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, player, target, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local id = room:askForCardChosen(player, to, "he", self.name)
    room:obtainCard(player.id, id, false, fk.ReasonPrey)
    if not to.dead then
      to:drawCards(1, self.name)
    end
    if player:usedSkillTimes("ty__xushen", Player.HistoryGame) > 0 then
      for _, p in ipairs(room.alive_players) do
        if string.find(p.general, "guansuo") and not p.dead then
          p:drawCards(1, self.name)
        end
      end
    end
  end,
}
local ty__xushen = fk.CreateTriggerSkill{
  name = "ty__xushen",
  anim_type = "defensive",
  frequency = Skill.Limited,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.dying and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:recover({
      who = player,
      num = 1,
      recoverBy = player,
      skillName = self.name
    })
    room:handleAddLoseSkills(player, "ty__zhennan", nil, true, false)
    data.extra_data = data.extra_data or {}
    data.extra_data.ty__xushen_data = player.id
  end,
}
local ty__xushen_delay = fk.CreateTriggerSkill{
  name = "#ty__xushen_delay",
  events = {fk.AfterDying},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and data.extra_data and data.extra_data.ty__xushen_data == player.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if table.find(room.alive_players, function(p) return string.find(p.general, "guansuo") end) then return end
    local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#ty__xushen-choose", self.name, true)
    if #to > 0 then
      to = room:getPlayerById(to[1])
      if room:askForSkillInvoke(to, self.name, nil, "#ty__xushen-invoke") then
        U.changeHero(to, "ty__guansuo")
        if not to.dead then
          to:drawCards(3, self.name)
        end
      end
    end
  end,
}
local ty__zhennan = fk.CreateTriggerSkill{
  name = "ty__zhennan",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.card:isCommonTrick() and data.firstTarget and #AimGroup:getAllTargets(data.tos) > 1
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#ty__zhennan-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:damage{
      from = player,
      to = player.room:getPlayerById(self.cost_data),
      damage = 1,
      skillName = self.name,
    }
  end,
}
ty__xushen:addRelatedSkill(ty__xushen_delay)
baosanniang:addSkill(ty__wuniang)
baosanniang:addSkill(ty__xushen)
baosanniang:addRelatedSkill(ty__zhennan)
Fk:loadTranslationTable{
  ["ty__baosanniang"] = "鲍三娘",
  ["#ty__baosanniang"] = "南中武娘",
  ["illustrator:ty__baosanniang"] = "DH",
  ["ty__wuniang"] = "武娘",
  [":ty__wuniang"] = "当你使用或打出【杀】时，你可以获得一名其他角色的一张牌，若如此做，其摸一张牌。若你已发动〖许身〗，则关索也摸一张牌。",
  ["ty__xushen"] = "许身",
  [":ty__xushen"] = "限定技，当你进入濒死状态后，你可以回复1点体力并获得技能〖镇南〗，然后如果你脱离濒死状态且关索不在场，"..
  "你可令一名其他角色选择是否用关索代替其武将并令其摸三张牌",
  ["ty__zhennan"] = "镇南",
  [":ty__zhennan"] = "当有角色使用普通锦囊牌指定目标后，若此牌目标数大于1，你可以对一名其他角色造成1点伤害。",
  ["#ty__wuniang1-choose"] = "武娘：你可以获得一名其他角色的一张牌，其摸一张牌",
  ["#ty__wuniang2-choose"] = "武娘：你可以获得一名其他角色的一张牌，其摸一张牌，关索摸一张牌",
  ["#ty__xushen_delay"] = "许身",
  ["#ty__xushen-choose"] = "许身：你可以令一名其他角色选择是否变身为十周年关索并摸三张牌！",
  ["#ty__xushen-invoke"]= "许身：你可以变身为十周年关索并摸三张牌！",
  ["#ty__zhennan-choose"] = "镇南：你可以对一名其他角色造成1点伤害",

  ["$ty__wuniang1"] = "得公亲传，彰其武威。",
  ["$ty__wuniang2"] = "灵彩武动，娇影摇曳。",
  ["$ty__xushen1"] = "倾郎心，许君身。",
  ["$ty__xushen2"] = "世间只与郎君好。",
  ["$ty__zhennan1"] = "遵丞相之志，护南中安乐。",
  ["$ty__zhennan2"] = "哼，又想扰乱南中安宁？",
  ["~ty__baosanniang"] = "彼岸花开红似火，花期苦短终别离……",
}

local xurong = General(extension, "xurong", "qun", 4)
local xionghuo = fk.CreateActiveSkill{
  name = "xionghuo",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#xionghuo-active",
  can_use = function(self, player)
    return player:getMark("@baoli") > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):getMark("@baoli") == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:removePlayerMark(player, "@baoli", 1)
    room:addPlayerMark(target, "@baoli", 1)
  end,
}
local xionghuo_record = fk.CreateTriggerSkill{
  name = "#xionghuo_record",
  main_skill = xionghuo,
  anim_type = "offensive",
  events = {fk.GameStart, fk.DamageCaused, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(xionghuo) then
      if event == fk.GameStart then
        return player:getMark("@baoli") < 3
      elseif event == fk.DamageCaused then
        return target == player and data.to ~= player and data.to:getMark("@baoli") > 0
      else
        return target ~= player and target:getMark("@baoli") > 0 and target.phase == Player.Play
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("xionghuo")
    if event == fk.GameStart then
      room:setPlayerMark(player, "@baoli", 3)
    elseif event == fk.DamageCaused then
      room:doIndicate(player.id, {data.to.id})
      data.damage = data.damage + 1
    else
      room:doIndicate(player.id, {target.id})
      room:removePlayerMark(target, "@baoli", 1)
      local rand = math.random(1, target:isNude() and 2 or 3)
      if rand == 1 then
        room:damage {
          from = player,
          to = target,
          damage = 1,
          damageType = fk.FireDamage,
          skillName = "xionghuo",
        }
        local mark = target:getTableMark("xionghuo_prohibit-turn")
        table.insert(mark, player.id)
        room:setPlayerMark(target, "xionghuo_prohibit-turn", mark)

      elseif rand == 2 then
        room:loseHp(target, 1, "xionghuo")
        room:addPlayerMark(target, "MinusMaxCards-turn", 1)
      else
        local cards = table.random(target:getCardIds{Player.Hand, Player.Equip}, 2)
        room:moveCardTo(cards, Player.Hand, player, fk.ReasonPrey, "xionghuo", "", false, player.id)
      end
    end
  end,

  refresh_events = {fk.BuryVictim, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    if event == fk.BuryVictim then
      return player == target and player:hasSkill(xionghuo, true, true) and table.every(player.room.alive_players, function (p)
        return not p:hasSkill(xionghuo, true)
      end)
    elseif event == fk.EventLoseSkill then
      return player == target and data == xionghuo and table.every(player.room.alive_players, function (p)
        return not p:hasSkill(xionghuo, true)
      end)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      if p:getMark("@baoli") > 0 then
        room:setPlayerMark(p, "@baoli", 0)
      end
    end
  end,
}
local xionghuo_prohibit = fk.CreateProhibitSkill{
  name = "#xionghuo_prohibit",
  is_prohibited = function(self, from, to, card)
    return card.trueName == "slash" and table.contains(from:getTableMark("xionghuo_prohibit-turn") ,to.id)
  end,
}
local shajue = fk.CreateTriggerSkill{
  name = "shajue",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self) and (player:getMark("@baoli") < 3 or
    (target.hp < 0 and data.damage and data.damage.card and U.hasFullRealCard(player.room, data.damage.card)))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("@baoli") < 3 then
      room:addPlayerMark(player, "@baoli", 1)
    end
    if target.hp < 0 and data.damage and data.damage.card and U.hasFullRealCard(room, data.damage.card) then
      room:obtainCard(player, data.damage.card, true, fk.ReasonPrey)
    end
  end
}
xionghuo:addRelatedSkill(xionghuo_record)
xionghuo:addRelatedSkill(xionghuo_prohibit)
xurong:addSkill(xionghuo)
xurong:addSkill(shajue)
Fk:loadTranslationTable{
  ["xurong"] = "徐荣",
  ["#xurong"] = "玄菟战魔",
  ["cv:xurong"] = "曹真",
  ["designer:xurong"] = "Loun老萌",
  ["illustrator:xurong"] = "zoo",
  ["xionghuo"] = "凶镬",
  [":xionghuo"] = "游戏开始时，你获得3个“暴戾”标记（标记上限为3）。出牌阶段，你可以交给一名其他角色一个“暴戾”标记，"..
  "你对有此标记的其他角色造成的伤害+1，且其出牌阶段开始时，移去“暴戾”并随机执行一项："..
  "1.受到1点火焰伤害且本回合不能对你使用【杀】；"..
  "2.流失1点体力且本回合手牌上限-1；"..
  "3.你随机获得其两张牌。",
  ["shajue"] = "杀绝",
  [":shajue"] = "锁定技，其他角色进入濒死状态时，你获得一个“暴戾”标记，"..
  "若其需要超过一张【桃】或【酒】救回，你获得使其进入濒死状态的牌。",
  ["#xionghuo_record"] = "凶镬",
  ["@baoli"] = "暴戾",
  ["#xionghuo-active"] = "发动 凶镬，将“暴戾”交给其他角色",

  ["$xionghuo1"] = "此镬加之于你，定有所伤！",
  ["$xionghuo2"] = "凶镬沿袭，怎会轻易无伤？",
  ["$shajue1"] = "杀伐决绝，不留后患。",
  ["$shajue2"] = "吾即出，必绝之！",
  ["~xurong"] = "此生无悔，心中无愧。",
}

local caochun = General(extension, "ty__caochun", "wei", 4)
local ty__shanjia = fk.CreateTriggerSkill{
  name = "ty__shanjia",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(3, self.name)
    local cards = {}
    if player:getMark(self.name) < 3 then
      local x = 3 - player:getMark(self.name)
      cards = room:askForDiscard(player, x, x, true, self.name, false, ".", "#ty__shanjia-discard:::"..x)
    end
    local flag1, flag2 = false, false
    if not table.find(cards, function(id) return Fk:getCardById(id).type == Card.TypeBasic end) then
      flag1 = true
      room:addPlayerMark(player, MarkEnum.SlashResidue.."-turn", 1)
    end
    if not table.find(cards, function(id) return Fk:getCardById(id).type == Card.TypeTrick end) then
      flag2 = true
      room:addPlayerMark(player, MarkEnum.BypassDistancesLimit.."-turn", 1)
    end
    if flag1 and flag2 then
      U.askForUseVirtualCard(room, player, "slash", nil, self.name, "#ty__shanjia-use", true, true, false, true)
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player:getMark(self.name) < 3
  end,
  on_refresh = function(self, event, target, player, data)
    local n = 0
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason ~= fk.ReasonUse then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).type == Card.TypeEquip then
            n = n + 1
          end
        end
      end
    end
    if n > 0 then
      player.room:addPlayerMark(player, self.name, math.min(n, 3 - player:getMark(self.name)))
      if player:hasSkill(self, true) then
        player.room:setPlayerMark(player, "@ty__shanjia", player:getMark(self.name))
      end
    end
  end,
}
caochun:addSkill(ty__shanjia)
Fk:loadTranslationTable{
  ["ty__caochun"] = "曹纯",
  ["#ty__caochun"] = "虎豹骑首",
  ["illustrator:ty__caochun"] = "凡果_Make", -- 虎啸龙渊
  ["ty__shanjia"] = "缮甲",
  [":ty__shanjia"] = "出牌阶段开始时，你可以摸三张牌，然后弃置三张牌（你每不因使用而失去过一张装备牌，便少弃置一张），若你本次没有弃置过："..
  "基本牌，你此阶段使用【杀】次数上限+1；锦囊牌，你此阶段使用牌无距离限制；都满足，你可以视为使用【杀】。",
  ["#ty__shanjia-discard"] = "缮甲：你需弃置%arg张牌",
  ["#ty__shanjia-use"] = "缮甲：你可以视为使用【杀】",
  ["@ty__shanjia"] = "缮甲",

  ["$ty__shanjia1"] = "百锤锻甲，披之可陷靡阵、断神兵、破坚城！",
  ["$ty__shanjia2"] = "千炼成兵，邀天下群雄引颈，且试我剑利否！",
  ["~ty__caochun"] = "不胜即亡，唯一死而已！",
}

local zhangqiying = General(extension, "zhangqiying", "qun", 3, 3, General.Female)
local falu = fk.CreateTriggerSkill{
  name = "falu",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.GameStart, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.GameStart then
        return true
      else
        for _, move in ipairs(data) do
          if move.from == player.id and move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
            self.cost_data = {}
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                local suit = Fk:getCardById(info.cardId):getSuitString()
                if player:getMark("@@falu" .. suit) == 0 then
                  table.insertIfNeed(self.cost_data, suit)
                end
              end
            end
            return #self.cost_data > 0
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local suits = {"spade", "club", "heart", "diamond"}
      for i = 1, 4, 1 do
        room:addPlayerMark(player, "@@falu" .. suits[i], 1)
      end
    else
      for _, suit in ipairs(self.cost_data) do
        room:addPlayerMark(player, "@@falu" .. suit, 1)
      end
    end
  end,

  refresh_events = {fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local suits = {"spade", "club", "heart", "diamond"}
    for i = 1, 4, 1 do
      room:setPlayerMark(player, "@@falu" .. suits[i], 0)
    end
  end,
}

local zhenyi = fk.CreateViewAsSkill{
  name = "zhenyi",
  anim_type = "support",
  pattern = "peach",
  prompt = "#zhenyi2",
  card_num = 1,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  before_use = function(self, player)
    player.room:removePlayerMark(player, "@@faluclub", 1)
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return nil end
    local c = Fk:cloneCard("peach")
    c.skillName = self.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = Util.FalseFunc,
  enabled_at_response = function(self, player)
    return player.phase == Player.NotActive and player:getMark("@@faluclub") > 0
  end,
}
local zhenyi_trigger = fk.CreateTriggerSkill {
  name = "#zhenyi_trigger",
  main_skill = zhenyi,
  events = {fk.AskForRetrial, fk.DamageCaused, fk.Damaged},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhenyi) then
      if event == fk.AskForRetrial then
        return player:getMark("@@faluspade") > 0
      elseif event == fk.DamageCaused then
        return target == player and player:getMark("@@faluheart") > 0
      elseif event == fk.Damaged then
        return target == player and player:getMark("@@faludiamond") > 0 and data.damageType ~= fk.NormalDamage
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local prompt
    if event == fk.AskForRetrial then
      prompt = "#zhenyi1::"..target.id
    elseif event == fk.DamageCaused then
      prompt = "#zhenyi3::"..data.to.id
    elseif event == fk.Damaged then
      prompt = "#zhenyi4"
    end
    return room:askForSkillInvoke(player, zhenyi.name, nil, prompt)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(zhenyi.name)
    if event == fk.AskForRetrial then
      room:notifySkillInvoked(player, zhenyi.name, "control")
      room:removePlayerMark(player, "@@faluspade", 1)
      local choice = room:askForChoice(player, {"zhenyi_spade", "zhenyi_heart"}, zhenyi.name)
      local new_card = Fk:cloneCard(data.card.name, choice == "zhenyi_spade" and Card.Spade or Card.Heart, 5)
      new_card.skillName = zhenyi.name
      new_card.id = data.card.id
      data.card = new_card
      room:sendLog{
        type = "#ChangedJudge",
        from = player.id,
        to = { data.who.id },
        arg2 = new_card:toLogString(),
        arg = zhenyi.name,
      }
    elseif event == fk.DamageCaused then
      room:notifySkillInvoked(player, zhenyi.name, "offensive")
      room:removePlayerMark(player, "@@faluheart", 1)
      data.damage = data.damage + 1
    elseif event == fk.Damaged then
      room:notifySkillInvoked(player, zhenyi.name, "masochism")
      room:removePlayerMark(player, "@@faludiamond", 1)
      local cards = {}
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|basic"))
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|trick"))
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|equip"))
      if #cards > 0 then
        room:moveCards({
          ids = cards,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonJustMove,
          proposer = player.id,
          skillName = zhenyi.name,
        })
      end
    end
  end,
}
local dianhua = fk.CreateTriggerSkill{
  name = "dianhua",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (player.phase == Player.Start or player.phase == Player.Finish) and
    not table.every({"spade", "club", "heart", "diamond"}, function (suit)
      return player:getMark("@@falu"..suit) == 0
    end)
  end,
  on_cost = function(self, event, target, player, data)
    local n = 0
    for _, suit in ipairs({"spade", "club", "heart", "diamond"}) do
      if player:getMark("@@falu"..suit) > 0 then
        n = n + 1
      end
    end
    if n > 0 and player.room:askForSkillInvoke(player, self.name) then
      self.cost_data = n
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:askForGuanxing(player, room:getNCards(self.cost_data))
  end,
}
zhenyi:addRelatedSkill(zhenyi_trigger)
zhangqiying:addSkill(falu)
zhangqiying:addSkill(zhenyi)
zhangqiying:addSkill(dianhua)
Fk:loadTranslationTable{
  ["zhangqiying"] = "张琪瑛",
  ["#zhangqiying"] = "禳祷西东",
  ["illustrator:zhangqiying"] = "alien",
  ["falu"] = "法箓",
  [":falu"] = "锁定技，当你的牌因弃置而移至弃牌堆后，根据这些牌的花色，你获得对应标记：<br>"..
  "♠，你获得1枚“紫微”；<br>"..
  "♣，你获得1枚“后土”；<br>"..
  "<font color='red'>♥</font>，你获得1枚“玉清”；<br>"..
  "<font color='red'>♦</font>，你获得1枚“勾陈”。<br>"..
  "每种标记限拥有一个。游戏开始时，你获得以上四种标记。",
  ["zhenyi"] = "真仪",
  [":zhenyi"] = "你可以在以下时机弃置相应的标记来发动以下效果：<br>"..
  "当一张判定牌生效前，你可以弃置“紫微”，然后将判定结果改为♠5或<font color='red'>♥5</font>；<br>"..
  "当你于回合外需要使用【桃】时，你可以弃置“后土”，然后将你的一张牌当【桃】使用；<br>"..
  "当你造成伤害时，你可以弃置“玉清”，此伤害+1；<br>"..
  "当你受到属性伤害后，你可以弃置“勾陈”，然后你从牌堆中随机获得三种类型的牌各一张。",
  ["dianhua"] = "点化",
  [":dianhua"] = "准备阶段或结束阶段，你可以观看牌堆顶的X张牌（X为你的标记数）。若如此做，你将这些牌以任意顺序放回牌堆顶或牌堆底。",
  ["@@faluspade"] = "♠紫微",
  ["@@faluclub"] = "♣后土",
  ["@@faluheart"] = "<font color='red'>♥</font>玉清",
  ["@@faludiamond"] = "<font color='red'>♦</font>勾陈",
  ["#zhenyi1"] = "真仪：你可以弃置♠紫微，将 %dest 的判定结果改为♠5或<font color='red'>♥5</font>",
  ["#zhenyi2"] = "真仪：你可以弃置♣后土，将一张牌当【桃】使用",
  ["#zhenyi3"] = "真仪：你可以弃置<font color='red'>♥</font>玉清，对 %dest 造成的伤害+1",
  ["#zhenyi4"] = "真仪：你可以弃置<font color='red'>♦</font>勾陈，从牌堆中随机获得三种类型的牌各一张",
  ["#zhenyi_trigger"] = "真仪",
  ["zhenyi_spade"] = "将判定结果改为♠5",
  ["zhenyi_heart"] = "将判定结果改为<font color='red'>♥</font>5",

  ["$falu1"] = "求法之道，以司箓籍。",
  ["$falu2"] = "取舍有法，方得其法。",
  ["$zhenyi1"] = "不疾不徐，自爱自重。",
  ["$zhenyi2"] = "紫薇星辰，斗数之仪。",
  ["$dianhua1"] = "大道无形，点化无为。",
  ["$dianhua2"] = "得此点化，必得大道。",
  ["~zhangqiying"] = "米碎面散，我心欲绝……",
}

--隐山之玉：周夷 卢弈 孙翎鸾 曹轶
local zhouyi = General(extension, "zhouyi", "wu", 3, 3, General.Female)
local zhukou = fk.CreateTriggerSkill{
  name = "zhukou",
  anim_type = "offensive",
  events = {fk.Damage, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      local room = player.room
      if event == fk.Damage then
        if room.current and room.current.phase == Player.Play then
          local damage_event = room.logic:getCurrentEvent()
          if not damage_event then return false end
          local x = player:getMark("zhukou_record-phase")
          if x == 0 then
            room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
              local reason = e.data[3]
              if reason == "damage" then
                local first_damage_event = e:findParent(GameEvent.Damage)
                if first_damage_event and first_damage_event.data[1].from == player then
                  x = first_damage_event.id
                  room:setPlayerMark(player, "zhukou_record-phase", x)
                end
                return true
              end
            end, Player.HistoryPhase)
          end
          if damage_event.id == x then
            local events = room.logic.event_recorder[GameEvent.UseCard] or Util.DummyTable
            local end_id = player:getMark("zhukou_record-turn")
            if end_id == 0 then
              local turn_event = damage_event:findParent(GameEvent.Turn, false)
              end_id = turn_event.id
            end
            room:setPlayerMark(player, "zhukou_record-turn", room.logic.current_event_id)
            local y = player:getMark("zhukou_usecard-turn")
            for i = #events, 1, -1 do
              local e = events[i]
              if e.id <= end_id then break end
              local use = e.data[1]
              if use.from == player.id then
                y = y + 1
              end
            end
            room:setPlayerMark(player, "zhukou_usecard-turn", y)
            return y > 0
          end
        end
      else
        if player.phase == Player.Finish and #room.alive_players > 2 then
          if player:getMark("zhukou_damaged-turn") > 0 then return false end
          local events = room.logic.event_recorder[GameEvent.ChangeHp] or Util.DummyTable
          local end_id = player:getMark("zhukou_damage_record-turn")
          if end_id == 0 then
            local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, false)
            end_id = turn_event.id
          end
          room:setPlayerMark(player, "zhukou_damage_record-turn", room.logic.current_event_id)
          for i = #events, 1, -1 do
            local e = events[i]
            if e.id <= end_id then break end
            local damage = e.data[5]
            if damage and damage.from == player then
              room:setPlayerMark(player, "zhukou_damaged-turn", 1)
              return false
            end
          end
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damage then
      return room:askForSkillInvoke(player, self.name)
    else
      local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
      if #targets < 2 then return end
      local tos = room:askForChoosePlayers(player, targets, 2, 2, "#zhukou-choose", self.name, true)
      if #tos == 2 then
        self.cost_data = tos
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.Damage then
      local x = player:getMark("zhukou_usecard-turn")
      if x > 0 then
        player:drawCards(x, self.name)
      end
    else
      local room = player.room
      local tar
      for _, p in ipairs(self.cost_data) do
        tar = room:getPlayerById(p)
        if not tar.dead then
          room:damage{
            from = player,
            to = tar,
            damage = 1,
            skillName = self.name,
          }
        end
      end
    end
  end,
}
local mengqing = fk.CreateTriggerSkill{
  name = "mengqing",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #table.filter(player.room.alive_players, function(p) return p:isWounded() end) > player.hp
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 3)
    room:recover({
      who = player,
      num = 3,
      recoverBy = player,
      skillName = self.name
    })
    room:handleAddLoseSkills(player, "-zhukou|yuyun", nil)
  end,
}
local yuyun = fk.CreateTriggerSkill{
  name = "yuyun",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local chs = {"loseHp"}
    if player.maxHp > 1 then table.insert(chs, "loseMaxHp") end
    local chc = room:askForChoice(player, chs, self.name)
    if chc == "loseMaxHp" then
      room:changeMaxHp(player, -1)
    else
      room:loseHp(player, 1, self.name)
    end
    local choices = {"yuyun1", "yuyun2", "yuyun3", "yuyun4", "yuyun5", "Cancel"}
    local n = 1 + player:getLostHp()
    for i = 1, n, 1 do
      if player.dead or #choices < 2 then return end
      local choice = room:askForChoice(player, choices, self.name)
      if choice == "Cancel" then return end
      table.removeOne(choices, choice)
      if choice == "yuyun1" then
        player:drawCards(2, self.name)
      elseif choice == "yuyun2" then
        local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
        if #targets > 0 then
          local to = room:askForChoosePlayers(player, targets, 1, 1, "#yuyun2-choose", self.name, false)
          if #to > 0 then
            local tar = room:getPlayerById(to[1])
            room:damage{
              from = player,
              to = tar,
              damage = 1,
              skillName = self.name,
            }
            if not tar.dead then
              room:addPlayerMark(tar, "@@yuyun-turn")
              local targetRecorded = type(player:getMark("yuyun2-turn")) == "table" and player:getMark("yuyun2-turn") or {}
              table.insertIfNeed(targetRecorded, to[1])
              room:setPlayerMark(player, "yuyun2-turn", targetRecorded)
            end
          end
        end
      elseif choice == "yuyun3" then
        room:addPlayerMark(player, "@@yuyun-turn")
        room:addPlayerMark(player, "yuyun3-turn", 1)
      elseif choice == "yuyun4" then
        local targets = table.map(table.filter(room:getOtherPlayers(player, false), function(p)
          return not p:isAllNude() end), Util.IdMapper)
        if #targets > 0 then
          local to = room:askForChoosePlayers(player, targets, 1, 1, "#yuyun4-choose", self.name, false)
          if #to > 0 then
            local id = room:askForCardChosen(player, room:getPlayerById(to[1]), "hej", self.name)
            room:obtainCard(player.id, id, false, fk.ReasonPrey)
          end
        end
      elseif choice == "yuyun5" then
        local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
        if #targets > 0 then
          local to = room:askForChoosePlayers(player, targets, 1, 1, "#yuyun5-choose", self.name, false)
          if #to > 0 then
            local p = room:getPlayerById(to[1])
            local x = math.min(p.maxHp, 5) - p:getHandcardNum()
            if x > 0 then
              room:drawCards(p, x, self.name)
            end
          end
        end
      end
    end
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    if player == target and data.card.trueName == "slash" then
      local mark = player:getTableMark("yuyun2-turn")
      return #mark > 0 and table.find(TargetGroup:getRealTargets(data.tos), function (pid)
        return table.contains(mark, pid)
      end)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
}
local yuyun_targetmod = fk.CreateTargetModSkill{
  name = "#yuyun_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return card.trueName == "slash" and to and table.contains(player:getTableMark("yuyun2-turn"), to.id)
  end,
  bypass_distances =  function(self, player, skill, card, to)
    return card.trueName == "slash" and to and table.contains(player:getTableMark("yuyun2-turn"), to.id)
  end,
}
local yuyun_maxcards = fk.CreateMaxCardsSkill{
  name = "#yuyun_maxcards",
  exclude_from = function(self, player, card)
    return player:getMark("yuyun3-turn") > 0
  end,
}
yuyun:addRelatedSkill(yuyun_targetmod)
yuyun:addRelatedSkill(yuyun_maxcards)
zhouyi:addSkill(zhukou)
zhouyi:addSkill(mengqing)
zhouyi:addRelatedSkill(yuyun)
Fk:loadTranslationTable{
  ["zhouyi"] = "周夷",
  ["#zhouyi"] = "靛情雨黛",
  ["illustrator:zhouyi"] = "Tb罗根",
  ["zhukou"] = "逐寇",
  [":zhukou"] = "当你于每回合的出牌阶段第一次造成伤害后，你可以摸X张牌（X为本回合你已使用的牌数）。结束阶段，若你本回合未造成过伤害，"..
  "你可以对两名其他角色各造成1点伤害。",
  ["mengqing"] = "氓情",
  [":mengqing"] = "觉醒技，准备阶段，若已受伤的角色数大于你的体力值，你加3点体力上限并回复3点体力，失去〖逐寇〗，获得〖玉殒〗。",
  ["yuyun"] = "玉陨",
  [":yuyun"] = "锁定技，出牌阶段开始时，你失去1点体力或体力上限（你的体力上限不能以此法被减至1以下），然后选择X+1项（X为你已损失的体力值）：<br>"..
  "1.摸两张牌；<br>"..
  "2.对一名其他角色造成1点伤害，然后本回合对其使用【杀】无距离和次数限制；<br>"..
  "3.本回合没有手牌上限；<br>"..
  "4.获得一名其他角色区域内的一张牌；<br>"..
  "5.令一名其他角色将手牌摸至体力上限（最多摸至5）。",
  ["#zhukou-choose"] = "是否发动逐寇，选择2名其他角色，对其各造成1点伤害",
  ["yuyun1"] = "摸两张牌",
  ["yuyun2"] = "对一名其他角色造成1点伤害，本回合对其使用【杀】无距离和次数限制",
  ["yuyun3"] = "本回合没有手牌上限",
  ["yuyun4"] = "获得一名其他角色区域内的一张牌",
  ["yuyun5"] = "令一名其他角色将手牌摸至体力上限（最多摸至5）",
  ["#yuyun2-choose"] = "玉陨：对一名其他角色造成1点伤害，本回合对其使用【杀】无距离和次数限制",
  ["#yuyun4-choose"] = "玉陨：获得一名其他角色区域内的一张牌",
  ["#yuyun5-choose"] = "玉陨：令一名其他角色将手牌摸至体力上限（最多摸至5）",
  ["@@yuyun-turn"] = "玉陨",

  ["$zhukou1"] = "草莽贼寇，不过如此。",
  ["$zhukou2"] = "轻装上阵，利剑出鞘。",
  ["$mengqing1"] = "女之耽兮，不可说也。",
  ["$mengqing2"] = "淇水汤汤，渐车帷裳。",
  ["$yuyun1"] = "春依旧，人消瘦。",
  ["$yuyun2"] = "泪沾青衫，玉殒香消。",
  ["~zhouyi"] = "江水寒，萧瑟起……",
}

local luyi = General(extension, "luyi", "qun", 3, 3, General.Female)

local function searchFuxueCards(room, findOne)
  if #room.discard_pile == 0 then return {} end
  local ids = {}
  local discard_pile = table.simpleClone(room.discard_pile)
  local logic = room.logic
  local events = logic.event_recorder[GameEvent.MoveCards] or Util.DummyTable
  for i = #events, 1, -1 do
    local e = events[i]
    for _, move in ipairs(e.data) do
      for _, info in ipairs(move.moveInfo) do
        local id = info.cardId
        if table.removeOne(discard_pile, id) then
          if move.toArea == Card.DiscardPile and move.moveReason ~= fk.ReasonUse then
            table.insertIfNeed(ids, id)
            if findOne then
              return ids
            end
          end
        end
      end
    end
    if #discard_pile == 0 then break end
  end
  return ids
end
local fuxue = fk.CreateTriggerSkill{
  name = "fuxue",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if player.phase == Player.Start then
        return #searchFuxueCards(player.room, true) > 0
      elseif player.phase == Player.Finish then
        return player:isKongcheng() or
          table.every(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id):getMark("@@fuxue-inhand-turn") == 0 end)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player.phase == Player.Start then
      return player.room:askForSkillInvoke(player, self.name, nil, "#fuxue-invoke:::"..player.hp)
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if player.phase == Player.Start then
      local room = player.room
      local cards = searchFuxueCards(room, false)
      if #cards == 0 then return false end
      table.sort(cards, function (a, b)
        local cardA, cardB = Fk:getCardById(a), Fk:getCardById(b)
        if cardA.type == cardB.type then
          if cardA.sub_type == cardB.sub_type then
            if cardA.name == cardB.name then
              return a > b
            else
              return cardA.name > cardB.name
            end
          else
            return cardA.sub_type < cardB.sub_type
          end
        else
          return cardA.type < cardB.type
        end
      end)
      local get = room:askForCardsChosen(player, player, 1, player.hp, {
        card_data = {
          { "pile_discard", cards }
        }
      }, self.name, "#fuxue-choose:::" .. tostring(player.hp))
      room:moveCardTo(get, Player.Hand, player, fk.ReasonJustMove, self.name, "", false, player.id, "@@fuxue-inhand-turn")
    else
      player:drawCards(player.hp, self.name)
    end
  end,
}
local yaoyi = fk.CreateTriggerSkill{
  name = "yaoyi",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(player.room:getAlivePlayers()) do
      if not (p.dead or p:hasSkill("shoutan", true)) then
        local yes = true
        for _, skill in ipairs(p.player_skills) do
          if skill.switchSkillName then
            yes = false
            break
          end
        end
        if yes then
          room:handleAddLoseSkills(p, "shoutan", nil, true, false)
        end
      end
    end
  end,
}
local yaoyi_prohibit = fk.CreateProhibitSkill{
  name = "#yaoyi_prohibit",
  frequency = Skill.Compulsory,
  is_prohibited = function(self, from, to, card)
    if from ~= to and table.find(Fk:currentRoom().alive_players, function(p) return p:hasSkill(yaoyi) end) then
      local fromskill
      for _, skill in ipairs(from.player_skills) do
        if skill.switchSkillName then
          if fromskill == nil then
            fromskill = from:getSwitchSkillState(skill.switchSkillName)
          elseif fromskill ~= from:getSwitchSkillState(skill.switchSkillName) then
            return false
          end
        end
      end
      if fromskill == nil then return false end
      local toskill
      for _, skill in ipairs(to.player_skills) do
        if skill.switchSkillName then
          if toskill == nil then
            toskill = to:getSwitchSkillState(skill.switchSkillName)
          elseif toskill ~= to:getSwitchSkillState(skill.switchSkillName) then
            return false
          end
        end
      end
      return fromskill == toskill
    end
  end,
}
local shoutan = fk.CreateActiveSkill{
  name = "shoutan",
  anim_type = "switch",
  switch_skill_name = "shoutan",
  prompt = function()
    local prompt = "#shoutan-active:::"
    if Self:getSwitchSkillState("shoutan", false) == fk.SwitchYang then
      if not Self:hasSkill(yaoyi) then
        prompt = prompt .. "shoutan_yang"
      end
      prompt = prompt .. ":yin"
    else
      if not Self:hasSkill(yaoyi) then
        prompt = prompt .. "shoutan_yin"
      end
      prompt = prompt .. ":yang"
    end
    return prompt
  end,
  card_num = function()
    if Self:hasSkill(yaoyi) then
      return 0
    else
      return 1
    end
  end,
  target_num = 0,
  can_use = function(self, player)
    if player:hasSkill(yaoyi) then
      return player:getMark("shoutan_prohibit-phase") == 0
    else
      return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
    end
  end,
  card_filter = function(self, to_select, selected)
    if Self:hasSkill(yaoyi) then
      return false
    elseif #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerEquip then
      local card = Fk:getCardById(to_select)
      return not Self:prohibitDiscard(card) and (card.color == Card.Black) == (Self:getSwitchSkillState(self.name, false) == fk.SwitchYin)
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
  end,
}
local shoutan_refresh = fk.CreateTriggerSkill{
  name = "#shoutan_refresh",

  refresh_events = {fk.StartPlayCard},
  can_refresh = function(self, event, target, player, data)
    return player == target
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("shoutan-phase") < player:usedSkillTimes("shoutan", Player.HistoryPhase) then
      room:setPlayerMark(player, "shoutan-phase", player:usedSkillTimes("shoutan", Player.HistoryPhase))
      room:setPlayerMark(player, "shoutan_prohibit-phase", 1)
    else
      room:setPlayerMark(player, "shoutan_prohibit-phase", 0)
    end
  end,
}
yaoyi:addRelatedSkill(yaoyi_prohibit)
shoutan:addRelatedSkill(shoutan_refresh)
luyi:addSkill(fuxue)
luyi:addSkill(yaoyi)
luyi:addRelatedSkill(shoutan)
Fk:loadTranslationTable{
  ["luyi"] = "卢弈",
  ["#luyi"] = "落子惊鸿",
  ["designer:luyi"] = "星移",
  ["illustrator:luyi"] = "匠人绘",
  ["fuxue"] = "复学",
  [":fuxue"] = "准备阶段，你可以从弃牌堆中获得至多X张不因使用而进入弃牌堆的牌。结束阶段，若你手中没有以此法获得的牌，你摸X张牌。（X为你的体力值）",
  ["yaoyi"] = "邀弈",
  [":yaoyi"] = "锁定技，游戏开始时，所有没有转换技的角色获得〖手谈〗；你发动〖手谈〗无需弃置牌且无次数限制。"..
  "所有角色使用牌只能指定自己及与自己转换技状态不同的角色为目标。",
  ["shoutan"] = "手谈",
  [":shoutan"] = "转换技，出牌阶段限一次，你可以弃置一张：阳：非黑色手牌；阴：黑色手牌。",
  ["#fuxue-invoke"] = "复学：你可以获得弃牌堆中至多%arg张不因使用而进入弃牌堆的牌",
  ["#fuxue-choose"] = "复学：从弃牌堆中挑选至多%arg张卡牌获得",
  ["@@fuxue-inhand-turn"] = "复学",
  ["#shoutan-active"] = "发动 手谈，%arg将此技能转换为%arg2状态",
  ["shoutan_yin"] = "弃置一张黑色手牌，",
  ["shoutan_yang"] = "弃置一张非黑色手牌，",

  ["$fuxue1"] = "普天之大，唯此处可安书桌。",
  ["$fuxue2"] = "书中自有风月，何故东奔西顾？",
  ["$yaoyi1"] = "对弈未分高下，胜负可问春风。",
  ["$yaoyi2"] = "我掷三十六道，邀君游弈其中。",
  ["$shoutan1"] = "对弈博雅，落子珠玑胜无声。",
  ["$shoutan2"] = "弈者无言，手执黑白谈古今。",
  ["~luyi"] = "此生博弈，落子未有悔……",
}

local sunlingluan = General(extension, "sunlingluan", "wu", 3, 3, General.Female)
local lingyue = fk.CreateTriggerSkill{
  name = "lingyue",
  anim_type = "drawcard",
  events = {fk.Damage},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) or not target then return false end
    local room = player.room
    local damage_event = room.logic:getCurrentEvent()
    if not damage_event then return false end
    local x = target:getMark("lingyue_record-round")
    if x == 0 then
      room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
        local reason = e.data[3]
        if reason == "damage" then
          local first_damage_event = e:findParent(GameEvent.Damage)
          if first_damage_event and first_damage_event.data[1].from == target then
            x = first_damage_event.id
            room:setPlayerMark(target, "lingyue_record-round", x)
            return true
          end
        end
      end, Player.HistoryRound)
    end
    return damage_event.id == x
  end,
  on_use = function(self, event, target, player, data)
    if target.phase == Player.NotActive then
      local room = player.room
      local events = room.logic.event_recorder[GameEvent.ChangeHp] or Util.DummyTable
      local end_id = player:getMark("lingyue_record-turn")
      if end_id == 0 then
        local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, false)
        if not turn_event then
          player:drawCards(1, self.name)
          return false
        end
        end_id = turn_event.id
      end
      room:setPlayerMark(player, "lingyue_record-turn", room.logic.current_event_id)
      local x = player:getMark("lingyue_damage-turn")
      for i = #events, 1, -1 do
        local e = events[i]
        if e.id <= end_id then break end
        local damage = e.data[5]
        if damage and damage.from then
          x = x + damage.damage
        end
      end
      room:setPlayerMark(player, "lingyue_damage-turn", x)
      if x > 0 then
        player:drawCards(x, self.name)
      end
    else
      player:drawCards(1, self.name)
    end
  end,
}
local pandi = fk.CreateActiveSkill{
  name = "pandi",
  anim_type = "control",
  prompt = "#pandi-active",
  can_use = function(self, player)
    return player:getMark("pandi_prohibit-phase") == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):getMark("pandi_damaged-turn") == 0
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = effect.tos[1]
    room:setPlayerMark(player, "pandi_prohibit-phase", 1)
    room:setPlayerMark(player, "pandi_target", target)
    local general_info = {player.general, player.deputyGeneral}
    local tar_player = room:getPlayerById(target)
    player.general = tar_player.general
    player.deputyGeneral = tar_player.deputyGeneral
    room:broadcastProperty(player, "general")
    room:broadcastProperty(player, "deputyGeneral")
    local _, ret = room:askForUseActiveSkill(player, "pandi_use", "#pandi-use::" .. target, true)
    room:setPlayerMark(player, "pandi_target", 0)
    player.general = general_info[1]
    player.deputyGeneral = general_info[2]
    room:broadcastProperty(player, "general")
    room:broadcastProperty(player, "deputyGeneral")
    if ret then
      room:useCard({
        from = target,
        tos = table.map(ret.targets, function(pid) return { pid } end),
        card = Fk:getCardById(ret.cards[1]),
      })
    end
  end,
}
local pandi_refresh = fk.CreateTriggerSkill{
  name = "#pandi_refresh",

  refresh_events = {fk.EventAcquireSkill, fk.Damage, fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    if event == fk.Damage then
      return player == target and player:getMark("pandi_damaged-turn") == 0
    elseif event == fk.EventAcquireSkill then
      return player == target and data == self and player.room.current == player and player.room:getTag("RoundCount")
    elseif event == fk.PreCardUse then
      return player:getMark("pandi_prohibit-phase") > 0
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.Damage then
      player.room:addPlayerMark(player, "pandi_damaged-turn")
    elseif event == fk.EventAcquireSkill then
      local room = player.room
      local current_event = room.logic:getCurrentEvent()
      if current_event == nil then return false end
      local start_event = current_event:findParent(GameEvent.Turn, true)
      if start_event == nil then return false end
      room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
        local damage = e.data[5]
        if damage and damage.from then
          room:addPlayerMark(damage.from, "pandi_damaged-turn")
        end
      end, Player.HistoryTurn)
    elseif event == fk.PreCardUse then
      player.room:setPlayerMark(player, "pandi_prohibit-phase", 0)
    end
  end,
}
local pandi_use = fk.CreateActiveSkill{
  name = "pandi_use",
  card_filter = function(self, to_select, selected)
    if #selected > 0 then return false end
    local room = Fk:currentRoom()
    if room:getCardArea(to_select) == Card.PlayerEquip then return false end
    local target_id = Self:getMark("pandi_target")
    local target = room:getPlayerById(target_id)
    local card = Fk:getCardById(to_select)
    return target:canUse(card) and not target:prohibitUse(card)
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected_cards ~= 1 then return false end
    local card = Fk:getCardById(selected_cards[1])
    local card_skill = card.skill
    local room = Fk:currentRoom()
    local target_id = Self:getMark("pandi_target")
    local target = room:getPlayerById(target_id)
    if card_skill:getMinTargetNum() == 0 or #selected >= card_skill:getMaxTargetNum(target, card) then return false end
    return not target:isProhibited(room:getPlayerById(to_select), card) and
      card_skill:modTargetFilter(to_select, selected, target_id, card, true)
  end,
  feasible = function(self, selected, selected_cards)
    if #selected_cards ~= 1 then return false end
    local card = Fk:getCardById(selected_cards[1])
    local card_skill = card.skill
    local room = Fk:currentRoom()
    local target_id = Self:getMark("pandi_target")
    local target = room:getPlayerById(target_id)
    return #selected >= card_skill:getMinTargetNum() and #selected <= card_skill:getMaxTargetNum(target, card)
  end,
}
Fk:addSkill(pandi_use)
pandi:addRelatedSkill(pandi_refresh)
sunlingluan:addSkill(lingyue)
sunlingluan:addSkill(pandi)
Fk:loadTranslationTable{
  ["sunlingluan"] = "孙翎鸾",
  ["#sunlingluan"] = "弦凤栖梧",
  ["designer:sunlingluan"] = "星移",
  ["illustrator:sunlingluan"] = "HEI-LEI",

  ["lingyue"] = "聆乐",
  [":lingyue"] = "锁定技，一名角色在本轮首次造成伤害后，你摸一张牌。若此时是该角色回合外，改为摸X张牌（X为本回合全场造成的伤害值）。",
  ["pandi"] = "盻睇",
  [":pandi"] = "出牌阶段，你可以选择一名本回合未造成过伤害的其他角色，你此阶段内使用的下一张牌改为由其对你选择的目标使用。" ..
  '<br /><font color="red">（村：发动后必须立即使用牌，且不支持转化使用，否则必须使用一张牌之后才能再次发动此技能）</font>',

  ["pandi_use"] = "盻睇",
  ["#pandi-active"] = "发动盻睇，选择一名其他角色，下一张牌视为由该角色使用",
  ["#pandi-use"] = "盻睇：选择一张牌，视为由 %dest 使用（若需要选目标则你来选择目标）",

  ["$lingyue1"] = "宫商催角羽，仙乐自可聆。",
  ["$lingyue2"] = "玉琶奏折柳，天地尽箫声。",
  ["$pandi1"] = "待君归时，共泛轻舟于湖海。",
  ["$pandi2"] = "妾有一曲，可壮卿之峥嵘。",
  ["~sunlingluan"] = "良人当归，苦酒何妨……",
}

local caoyi = General(extension, "caoyi", "wei", 4, 4, General.Female)
local miyi = fk.CreateTriggerSkill{
  name = "miyi",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Start and player:hasSkill(self)
  end,
  on_cost = function(self, event, target, player, data)
    local _, dat = player.room:askForUseActiveSkill(player, "miyi_active", "#miyi-invoke", true)
    if dat then
      self.cost_data = dat
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = self.cost_data.targets
    room:sortPlayersByAction(targets)
    room:doIndicate(player.id, targets)
    local choice = self.cost_data.interaction
    for _, id in ipairs(targets) do
      local p = room:getPlayerById(id)
      if not p.dead then
        room:setPlayerMark(p, "@@"..choice.."-turn", 1)
        if choice == "miyi2"  then
          room:damage{
            from = player,
            to = p,
            damage = 1,
            skillName = self.name,
          }
        elseif p:isWounded() then
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
local miyi_delay = fk.CreateTriggerSkill{
  name = "#miyi_delay",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and player.phase == Player.Finish
    and table.find(player.room.alive_players, function (p)
      return p:getMark("@@miyi1-turn") > 0 or p:getMark("@@miyi2-turn") > 0
    end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      if not p.dead then
        if p:getMark("@@miyi2-turn") > 0 and p:isWounded() then
          room:recover({
            who = p,
            num = 1,
            recoverBy = player,
            skillName = "miyi",
          })
        elseif p:getMark("@@miyi1-turn") > 0 then
          room:damage{
            from = player,
            to = p,
            damage = 1,
            skillName = "miyi",
          }
        end
      end
    end
  end,
}
local miyi_active = fk.CreateActiveSkill{
  name = "miyi_active",
  card_num = 0,
  min_target_num = 1,
  interaction = function()
    return UI.ComboBox {choices = {"miyi1", "miyi2"}}
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.TrueFunc,
}
local yinjun = fk.CreateTriggerSkill{
  name = "yinjun",
  anim_type = "offensive",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.tos and
      (data.card.trueName == "slash" or data.card.type == Card.TypeTrick) and
      #TargetGroup:getRealTargets(data.tos) == 1 and TargetGroup:getRealTargets(data.tos)[1] ~= player.id and
      player:getMark("yinjun_fail-turn") == 0 then
      if U.IsUsingHandcard(player, data) then
        local to = player.room:getPlayerById(TargetGroup:getRealTargets(data.tos)[1])
        local card = Fk:cloneCard("slash")
        card.skillName = self.name
        return not to.dead and not player:prohibitUse(card) and not player:isProhibited(to, card)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#yinjun-invoke::"..TargetGroup:getRealTargets(data.tos)[1])
  end,
  on_use = function(self, event, target, player, data)
    local use = {
      from = player.id,
      tos = {TargetGroup:getRealTargets(data.tos)},
      card = Fk:cloneCard("slash"),
      extraUse = true,
    }
    use.card.skillName = self.name
    player.room:useCard(use)
    if not player.dead and player:usedSkillTimes(self.name, Player.HistoryTurn) > player.hp then
      player.room:setPlayerMark(player, "yinjun_fail-turn", 1)
    end
  end,

  refresh_events = {fk.PreDamage},
  can_refresh = function(self, event, target, player, data)
    return data.card and table.contains(data.card.skillNames, self.name)
  end,
  on_refresh = function(self, event, target, player, data)
    data.from = nil
  end,
}
Fk:addSkill(miyi_active)
caoyi:addSkill(miyi)
miyi:addRelatedSkill(miyi_delay)
caoyi:addSkill(yinjun)
Fk:loadTranslationTable{
  ["caoyi"] = "曹轶",
  ["#caoyi"] = "飒姿缔燹",
  ["designer:caoyi"] = "星移",
  ["miyi"] = "蜜饴",
  [":miyi"] = "准备阶段，你可以选择一项令任意名角色执行：1.回复1点体力；2.你对其造成1点伤害。若如此做，结束阶段，这些角色执行另一项。",
  ["yinjun"] = "寅君",
  [":yinjun"] = "当你对其他角色从手牌使用指定唯一目标的【杀】或锦囊牌结算后，你可以视为对其使用一张【杀】（此【杀】伤害无来源）。若本回合发动次数"..
  "大于你当前体力值，此技能本回合无效。",
  ["miyi_active"] = "蜜饴",
  ["#miyi-invoke"] = "蜜饴：你可以令任意名角色执行你选择的效果，本回合结束阶段执行另一项",
  ["miyi1"] = "各回复1点体力",
  ["miyi2"] = "各受到你的1点伤害",
  ["@@miyi1-turn"] = "蜜饴:伤害",
  ["@@miyi2-turn"] = "蜜饴:回复",
  ["#yinjun-invoke"] = "寅君：你可以视为对 %dest 使用【杀】",

  ["$miyi1"] = "百战黄沙苦，舒颜红袖甜。",
  ["$miyi2"] = "撷蜜凝饴糖，入喉润心颜。",
  ["$yinjun1"] = "既乘虎豹之威，当弘大魏万年。",
  ["$yinjun2"] = "今日青锋在手，可驯四方虎狼。",
  ["~caoyi"] = "霜落寒鸦浦，天下无故人……",
}

--高山仰止：王朗 刘徽
local wanglang = General(extension, "ty__wanglang", "wei", 3)
local ty__gushe = fk.CreateActiveSkill{
  name = "ty__gushe",
  anim_type = "control",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 3,
  prompt = "#ty__gushe-active",
  times = function(self)
    return Self.phase ~= Player.NotActive and 7 - Self:getMark("ty__raoshe_win-turn") - Self:getMark("@ty__raoshe") or -1
  end,
  can_use = function(self, player)
    return not player:isKongcheng() and player:getMark("ty__raoshe_invalidity-turn") == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected < 3 and Self:canPindian(Fk:currentRoom():getPlayerById(to_select))
  end,
  on_use = function(self, room, effect)
    local tos = table.simpleClone(effect.tos)
    room:sortPlayersByAction(tos)
    room:getPlayerById(effect.from):pindian(table.map(tos, function(p) return room:getPlayerById(p) end), self.name)
  end,
}
local ty__gushe_delay = fk.CreateTriggerSkill{
  name = "#ty__gushe_delay",
  events = {fk.PindianResultConfirmed},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return data.reason == "ty__gushe" and data.from == player
    --王朗死亡后依旧有效
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not player.dead and data.winner ~= player then
      room:addPlayerMark(player, "@ty__raoshe", 1)
      local mark = player:getTableMark("@ty__gushe-turn")
      if #mark == 2 and mark[2] > 1 then
        room:setPlayerMark(player, "@ty__gushe-turn", {"times_left", mark[2] - 1})
      end
      if player:getMark("@ty__raoshe") >= 7 then
        room:killPlayer({who = player.id,})
      end
      if not player.dead then
        if #room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#ty__gushe-discard:"..player.id) == 0 then
          player:drawCards(1, self.name)
        end
      end
    end
    if not data.to.dead and data.winner ~= data.to then
      if player.dead then
        room:askForDiscard(data.to, 1, 1, true, self.name, false, ".", "#ty__gushe2-discard")
      else
        if #room:askForDiscard(data.to, 1, 1, true, self.name, true, ".", "#ty__gushe-discard:"..player.id) == 0 then
          player:drawCards(1, self.name)
        end
      end
    end
  end,

  refresh_events = {fk.PindianResultConfirmed, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    if event == fk.PindianResultConfirmed then
      return data.winner and data.winner == player and player:hasSkill(ty__gushe, true)
    elseif event == fk.EventLoseSkill then
      return player == target and data == ty__gushe
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.PindianResultConfirmed then
      room:addPlayerMark(player, "ty__raoshe_win-turn")
      if player:getMark("@ty__raoshe") + player:getMark("ty__raoshe_win-turn") > 6 then
        if player:getMark("ty__raoshe_invalidity-turn") == 0 then
          room:setPlayerMark(player, "ty__raoshe_invalidity-turn", 1)
          room:addTableMark(player, MarkEnum.InvalidSkills .. "-turn", "ty__gushe")
        end
      end
    elseif event == fk.EventLoseSkill then
      room:setPlayerMark(player, "@ty__raoshe", 0)
      room:setPlayerMark(player, "ty__raoshe_win-turn", 0)
      room:setPlayerMark(player, "ty__raoshe_invalidity-turn", 0)
      room:removeTableMark(player, MarkEnum.InvalidSkills .. "-turn", "ty__gushe")
    end
  end,
}
local ty__jici = fk.CreateTriggerSkill{
  name = "ty__jici",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.PindianCardsDisplayed, fk.Death},
  can_trigger = function(self, event, target, player, data)
    if event == fk.PindianCardsDisplayed then
      if player:hasSkill(self) then
        if data.from == player then
          return data.fromCard.number <= player:getMark("@ty__raoshe")
        elseif table.contains(data.tos, player) then
          return data.results[player.id].toCard.number <= player:getMark("@ty__raoshe")
        end
      end
    elseif event == fk.Death then
      return target == player and player:hasSkill(self, false, true) and data.damage and data.damage.from and not data.damage.from.dead
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.PindianCardsDisplayed then
      local card
      if data.from == player then
        card = data.fromCard
      elseif table.contains(data.tos, player) then
        card = data.results[player.id].toCard
      end
      card.number = card.number + player:getMark("@ty__raoshe")
      if player.dead then return end
      local n = card.number
      if data.fromCard.number > n then
        n = data.fromCard.number
      end
      for _, result in pairs(data.results) do
        if result.toCard.number > n then
          n = result.toCard.number
        end
      end
      local cards = {}
      if data.fromCard.number == n and room:getCardArea(data.fromCard) == Card.Processing then
        table.insertIfNeed(cards, data.fromCard)
      end
      for _, result in pairs(data.results) do
        if result.toCard.number == n and room:getCardArea(data.fromCard) == Card.Processing then
          table.insertIfNeed(cards, result.toCard)
        end
      end
      if #cards > 0 then
        room:moveCardTo(cards, Player.Hand, player, fk.ReasonJustMove, self.name, "", true, player.id)
      end
    elseif event == fk.Death then
      local n = 7 - player:getMark("@ty__raoshe")
      if n > 0 then
        room:askForDiscard(data.damage.from, n, n, true, self.name, false)
        if data.damage.from.dead then return false end
      end
      room:loseHp(data.damage.from, 1, self.name)
    end
  end,
}
ty__gushe:addRelatedSkill(ty__gushe_delay)
wanglang:addSkill(ty__gushe)
wanglang:addSkill(ty__jici)
Fk:loadTranslationTable{
  ["ty__wanglang"] = "王朗",
  ["#ty__wanglang"] = "凤鹛",
  ["illustrator:ty__wanglang"] = "第七个桔子", -- 皮肤 骧龙御宇
  ["ty__gushe"] = "鼓舌",
  [":ty__gushe"] = "出牌阶段，你可以用一张手牌与至多三名角色同时拼点，没赢的角色选择一项: 1.弃置一张牌；2.令你摸一张牌。"..
  "若你没赢，获得一个“饶舌”标记；若你有7个“饶舌”标记，你死亡。当你一回合内累计七次拼点赢时（每有一个“饶舌”标记，此累计次数减1），本回合此技能失效。",
  ["ty__jici"] = "激词",
  [":ty__jici"] = "锁定技，当你的拼点牌亮出后，若此牌点数小于等于X，则点数+X（X为“饶舌”标记的数量）且你获得本次拼点中点数最大的牌。"..
  "你死亡时，杀死你的角色弃置7-X张牌并失去1点体力。",
  ["#ty__gushe-active"] = "发动 鼓舌，与1-3名角色拼点！",
  ["#ty__gushe-discard"] = "鼓舌：你需弃置一张牌，否则 %src 摸一张牌",
  ["#ty__gushe2-discard"] = "鼓舌：你需弃置一张牌",
  ["#ty__gushe_delay"] = "鼓舌",
  ["@ty__gushe-turn"] = "鼓舌",
  ["@ty__raoshe"] = "饶舌",
  ["times_left"] = "剩余",
  ["invalidity"] = "失效",

  ["$ty__gushe1"] = "承寇贼之要，相时而后动，择地而后行，一举更无余事。",
  ["$ty__gushe2"] = "春秋之义，求诸侯莫如勤王。今天王在魏都，宜遣使奉承王命。",
  ["$ty__jici1"] = "天数有变，神器更易，而归于有德之人，此自然之理也。",
  ["$ty__jici2"] = "王命之师，囊括五湖，席卷三江，威取中国，定霸华夏。",
  ["~ty__wanglang"] = "我本东海弄墨客，如何枉做沙场魂……",
}

local liuhui = General(extension, "liuhui", "qun", 4)

local function startCircle(player, points)
  local room = player.room
  table.shuffle(points)
  room:setPlayerMark(player, "@[geyuan]", {
    all = points, ok = {}
  })
end

--- 返回下一个能点亮圆环的点数
---@return integer[]
local function getCircleProceed(value)
  local all_points = value.all
  local ok_points = value.ok
  local all_len = #all_points
  -- 若没有点亮的就全部都满足
  if #ok_points == 0 then return all_points end
  -- 若全部点亮了返回空表
  if #ok_points == all_len then return Util.DummyTable end

  local function c(idx)
    if idx == 0 then idx = all_len end
    if idx == all_len + 1 then idx = 1 end
    return idx
  end

  -- 否则，显示相邻的，逻辑上要构成循环
  local ok_map = {}
  for _, v in ipairs(ok_points) do ok_map[v] = true end
  local start_idx, end_idx
  for i, v in ipairs(all_points) do
    -- 前一个不亮，这个是左端
    if ok_map[v] and not ok_map[all_points[c(i-1)]] then
      start_idx = i
    end
    -- 后一个不亮，这个是右端
    if ok_map[v] and not ok_map[all_points[c(i+1)]] then
      end_idx = i
    end
  end

  start_idx = c(start_idx - 1)
  end_idx = c(end_idx + 1)

  if start_idx == end_idx then
    return { all_points[start_idx] }
  else
    return { all_points[start_idx], all_points[end_idx] }
  end
end

Fk:addQmlMark{
  name = "geyuan",
  how_to_show = function(name, value)
    -- FIXME: 神秘bug导致value可能为空串有待排查
    if type(value) ~= "table" then return " " end
    local nums = getCircleProceed(value)
    if #nums == 1 then
      return Card:getNumberStr(nums[1])
    elseif #nums == 2 then
      return Card:getNumberStr(nums[1]) .. Card:getNumberStr(nums[2])
    else
      return " "
    end
  end,
  qml_path = "packages/tenyear/qml/GeyuanBox"
}

local geyuan = fk.CreateTriggerSkill{
  name = "geyuan",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    local circle_data = player:getMark("@[geyuan]")
    if circle_data == 0 then return end
    local proceed = getCircleProceed(circle_data)
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          local number = Fk:getCardById(info.cardId).number
          if table.contains(proceed, number) then return true end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local circle_data = player:getMark("@[geyuan]")
    local proceed = getCircleProceed(circle_data)
    local completed = false
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          local number = Fk:getCardById(info.cardId).number
          if table.contains(proceed, number) then
            table.insert(circle_data.ok, number)
            proceed = getCircleProceed(circle_data)
            if proceed == Util.DummyTable then -- 已完成？
              -- FAQ: 成功了后还需结算剩下的？摸了，我不结算
              completed = true
              goto BREAK
            end
          end
        end
      end
    end
    ::BREAK::

    if completed then
      local start, end_ = circle_data.ok[1], circle_data.ok[#circle_data.ok]
      local waked = player:usedSkillTimes("gusuan", Player.HistoryGame) > 0
      if waked then
        local players = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper),
          0, 3, "#gusuan-choose", self.name, true)

        if players[1] then
          room:getPlayerById(players[1]):drawCards(3, self.name)
        end
        if players[2] then
          local p = room:getPlayerById(players[2])
          room:askForDiscard(p, 4, 4, true, self.name, false)
        end
        if players[3] then
          local p = room:getPlayerById(players[3])
          local cards = p:getCardIds(Player.Hand)
          room:moveCards({
            from = p.id,
            ids = cards,
            toArea = Card.Processing,
            moveReason = fk.ReasonExchange,
            proposer = player.id,
            skillName = self.name,
            moveVisible = false,
          })
          if not p.dead then
            room:moveCardTo(room:getNCards(5, "bottom"), Card.PlayerHand, p, fk.ReasonExchange, self.name, nil, false, player.id)
          end
          if #cards > 0 then
            table.shuffle(cards)
            room:moveCards({
              ids = cards,
              fromArea = Card.Processing,
              toArea = Card.DrawPile,
              moveReason = fk.ReasonExchange,
              skillName = self.name,
              moveVisible = false,
              drawPilePosition = -1,
            })
          end
        end
      else
        local toget = {}
        for _, p in ipairs(room.alive_players) do
          for _, id in ipairs(p:getCardIds("ej")) do
            local c = Fk:getCardById(id, true)
            if c.number == start or c.number == end_ then
              table.insert(toget, c.id)
            end
          end
        end
        for _, id in ipairs(room.draw_pile) do
          local c = Fk:getCardById(id, true)
          if c.number == start or c.number == end_ then
            table.insert(toget, c.id)
          end
        end
        room:moveCardTo(toget, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, true, player.id)
      end

      local all = circle_data.all
      if not waked then
        if #all > 3 then table.removeOne(all, start) end
        if #all > 3 then table.removeOne(all, end_) end
      end
      startCircle(player, all)
    else
      room:setPlayerMark(player, "@[geyuan]", circle_data)
    end
  end,

  refresh_events = {fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@[geyuan]", 0)
  end,
}
local geyuan_start = fk.CreateTriggerSkill{
  name = "#geyuan_start",
  main_skill = geyuan,
  events = {fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(geyuan) and player:getMark("@[geyuan]") == 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke("geyuan")
    local points = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13}
    startCircle(player, points)
  end
}
geyuan:addRelatedSkill(geyuan_start)
local jieshu = fk.CreateTriggerSkill{
  name = "jieshu",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player:getMark("@[geyuan]") ~= 0 then
      local proceed = getCircleProceed(player:getMark("@[geyuan]"))
      return table.contains(proceed, data.card.number)
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,
}
local jieshu_max = fk.CreateMaxCardsSkill{
  name = "#jieshu_maxcard",
  exclude_from = function(self, player, card)
    if player:hasSkill(jieshu) then
      local mark = player:getMark("@[geyuan]")
      local all = Util.DummyTable
      if type(mark) == "table" and mark.all then all = mark.all end
      return not table.contains(all, card.number)
    end
  end,
}
jieshu:addRelatedSkill(jieshu_max)
local gusuan = fk.CreateTriggerSkill{
  name = "gusuan",
  frequency = Skill.Wake,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    local mark = player:getMark("@[geyuan]")
    return type(mark) == "table" and #mark.all == 3
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
  end,
}
liuhui:addSkill(geyuan)
liuhui:addSkill(jieshu)
liuhui:addSkill(gusuan)
Fk:loadTranslationTable{
  ["liuhui"] = "刘徽",
  ["#liuhui"] = "周天古率",
  ["cv:liuhui"] = "冰霜墨菊",
  ["illustrator:liuhui"] = "凡果_肉山大魔王",

  ["geyuan"] = "割圆",
  [":geyuan"] = '锁定技，游戏开始时，将A~K的所有点数随机排列成一个圆环。有牌进入弃牌堆时，将满足圆环进度的点数记录在圆环内。当圆环完成后，你获得牌堆和场上所有完成此圆环最初和最后点数的牌，然后从圆环中移除这两个点数（不会被移除到三个以下），重新开始圆环。<br><font color="grey">进度点数：圆环中即将被点亮的点数。</font>',
  ["jieshu"] = "解术",
  [":jieshu"] = "锁定技，非圆环内点数的牌不计入你的手牌上限。你使用或打出牌时，若满足圆环进度点数，你摸一张牌。",
  ["gusuan"] = "股算",
  [":gusuan"] = '觉醒技，每个回合结束时，若圆环剩余点数为3个，你减1点体力上限，并修改“割圆”。<br><font color="grey">☆割圆·改：锁定技，有牌进入弃牌堆时，将满足圆环进度的点数记录在圆环内。当圆环完成后，你至多依次选择三名角色（按照点击他们的顺序）并依次执行其中一项：1.摸三张牌；2.弃四张牌；3.将其手牌与牌堆底五张牌交换。结算完成后，重新开始圆环。</font>',

  ["@[geyuan]"] = "割圆", -- 仅用到了前缀，因为我感觉够了，实际上右括号后能加更多后缀
  ["#geyuan_start"] = "割圆",
  ["#gusuan-choose"] = "割圆：依次点选至多三名角色，第一个摸3，第二个弃4，第三个换牌",

  ["$geyuan1"] = "绘同径之距，置内圆而割之。",
  ["$geyuan2"] = "矩割弥细，圆失弥少，以至不可割。",
  ["$jieshu1"] = "累乘除以成九数者，可以加减解之。",
  ["$jieshu2"] = "数有其理，见筹一可知沙数。",
  ["$gusuan1"] = "勾中容横，股中容直，可知其玄五。",
  ["$gusuan2"] = "累矩连索，类推衍化，开立而得法。",
  ["~liuhui"] = "算学如海，穷我一生，只得杯水……",
}

--武庙：诸葛亮 陆逊 关羽 皇甫嵩
local zhugeliang = General(extension, "wm__zhugeliang", "shu", 4, 7)
local jincui = fk.CreateTriggerSkill{
  name = "jincui",
  anim_type = "control",
  frequency = Skill.Compulsory,
  mute = true,
  events = {fk.EventPhaseStart, fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    if event == fk.GameStart then
      return player:hasSkill(self) and player:getHandcardNum() < 7
    elseif event == fk.EventPhaseStart then
      return target == player and player:hasSkill(self) and player.phase == Player.Start
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:broadcastSkillInvoke(self.name)
      local n = 7 - player:getHandcardNum()
      if n > 0 then
        player:drawCards(n, self.name)
      end
    elseif event == fk.EventPhaseStart then
      room:notifySkillInvoked(player, self.name)
      player:broadcastSkillInvoke(self.name)
      local n = 0
      for _, id in ipairs(room.draw_pile) do
        if Fk:getCardById(id).number == 7 then
          n = n + 1
        end
      end
      player.hp = math.min(player.maxHp, math.max(n, 1))
      room:broadcastProperty(player, "hp")
      room:askForGuanxing(player, room:getNCards(player.hp))
    end
  end,
}
local qingshi = fk.CreateTriggerSkill{
  name = "qingshi",
  events = {fk.CardUsing},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and
      not table.contains(player:getTableMark(MarkEnum.InvalidSkills .. "-turn"), self.name) and
      table.find(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id).trueName == data.card.trueName end) and
      not table.contains(player:getTableMark("qingshi-turn"), data.card.trueName)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(player, {"qingshi1", "qingshi2", "qingshi3", "Cancel"},
    self.name, "#qingshi-invoke:::"..data.card:toLogString())
    if choice == "qingshi1" then
      local to = room:askForChoosePlayers(player, TargetGroup:getRealTargets(data.tos), 1, 1,
        "#qingshi1-choose:::"..data.card:toLogString(), self.name)
      if #to > 0 then
        self.cost_data = {choice, to}
        return true
      end
    elseif choice == "qingshi2" then
      local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player, false), Util.IdMapper), 1, 998,
      "#qingshi2-choose:::"..data.card:toLogString(), self.name)
      if #to > 0 then
        self.cost_data = {choice, to}
        return true
      end
    elseif choice == "qingshi3" then
      self.cost_data = {choice}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("qingshi-turn")
    table.insert(mark, data.card.trueName)
    room:setPlayerMark(player, "qingshi-turn", mark)
    if self.cost_data[1] == "qingshi1" then
      room:notifySkillInvoked(player, self.name, "offensive")
      player:broadcastSkillInvoke(self.name)
      data.extra_data = data.extra_data or {}
      data.extra_data.qingshi_data = data.extra_data.qingshi_data or {}
      table.insert(data.extra_data.qingshi_data, {player.id, self.cost_data[2][1]})
    elseif self.cost_data[1] == "qingshi2" then
      room:notifySkillInvoked(player, self.name, "support")
      player:broadcastSkillInvoke(self.name)
      local tos = self.cost_data[2]
      room:sortPlayersByAction(tos)
      for _, id in ipairs(tos) do
        local p = room:getPlayerById(id)
        if not p.dead then
          p:drawCards(1, self.name)
        end
      end
    elseif self.cost_data[1] == "qingshi3" then
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:broadcastSkillInvoke(self.name)
      player:drawCards(3, self.name)
      room:addTableMark(player, MarkEnum.InvalidSkills .. "-turn", self.name)
    end
  end,

  refresh_events = {fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return target ~= player and data == SetInteractionDataOfSkill
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "qingshi-turn", 0)
    room:removeTableMark(player, MarkEnum.InvalidSkills .. "-turn", self.name)
  end,
}
local qingshi_delay = fk.CreateTriggerSkill{
  name = "#qingshi_delay",
  events = {fk.DamageCaused},
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player.dead or data.card == nil or data.chain then return false end
    local room = player.room
      local card_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if not card_event then return false end
      local use = card_event.data[1]
      if use.extra_data then
        local qingshi_data = use.extra_data.qingshi_data
        if qingshi_data then
          return table.find(qingshi_data, function (players)
            return players[1] == player.id and players[2] == data.to.id
          end)
        end
      end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(qingshi.name)
    data.damage = data.damage + 1
  end,
}
local zhizhe = fk.CreateActiveSkill{
  name = "zhizhe",
  prompt = "#zhizhe-active",
  anim_type = "special",
  frequency = Skill.Limited,
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Card.PlayerHand
    and not Fk:getCardById(to_select).is_derived and to_select > 0
  end,
  on_use = function(self, room, effect)
    local c = Fk:getCardById(effect.cards[1], true)
    local toGain = room:printCard(c.name, c.suit, c.number)
    room:moveCards({
      ids = {toGain.id},
      to = effect.from,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonPrey,
      proposer = effect.from,
      skillName = self.name,
      moveVisible = false,
    })
  end
}
local zhizhe_delay = fk.CreateTriggerSkill{
  name = "#zhizhe_delay",
  mute = true,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    local mark = player:getTableMark("zhizhe")
    if #mark == 0 then return false end
    local room = player.room
    local move_event = room.logic:getCurrentEvent()
    local parent_event = move_event.parent
    if parent_event and (parent_event.event == GameEvent.UseCard or parent_event.event == GameEvent.RespondCard) then
      local parent_data = parent_event.data[1]
      if parent_data.from == player.id then
        local card_ids = room:getSubcardsByRule(parent_data.card)
        local to_get = {}
        for _, move in ipairs(data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              local id = info.cardId
              if info.fromArea == Card.Processing and room:getCardArea(id) == Card.DiscardPile and
              table.contains(card_ids, id) and table.contains(mark, id) then
                table.insertIfNeed(to_get, id)
              end
            end
          end
        end
        if #to_get > 0 then
          self.cost_data = to_get
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name)
    player:broadcastSkillInvoke(zhizhe.name)
    room:obtainCard(player, self.cost_data, true, fk.ReasonJustMove, player.id, "zhizhe")
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local marked = player:getTableMark("zhizhe")
    local marked2 = player:getTableMark("zhizhe-turn")
    marked2 = table.filter(marked2, function (id)
      return room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player
    end)
    for _, move in ipairs(data) do
      if move.to == player.id and move.toArea == Card.PlayerHand and move.skillName == zhizhe.name then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player then
            if info.fromArea == Card.Void then
              table.insertIfNeed(marked, id)
            else
              table.insert(marked2, id)
            end
            room:setCardMark(Fk:getCardById(id), "@@zhizhe-inhand", 1)
          end
        end
      elseif move.moveReason ~= fk.ReasonUse and move.moveReason ~= fk.ReasonResonpse then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          table.removeOne(marked, id)
        end
      end
    end
    room:setPlayerMark(player, "zhizhe", marked)
    room:setPlayerMark(player, "zhizhe-turn", marked2)
  end,
}
local zhizhe_prohibit = fk.CreateProhibitSkill{
  name = "#zhizhe_prohibit",
  prohibit_use = function(self, player, card)
    local mark = player:getTableMark("zhizhe-turn")
    if #mark == 0 then return false end
    local cardList = card:isVirtual() and card.subcards or {card.id}
    return table.find(cardList, function (id) return table.contains(mark, id) end)
  end,
  prohibit_response = function(self, player, card)
    local mark = player:getMark("zhizhe-turn")
    if #mark == 0 then return false end
    local cardList = card:isVirtual() and card.subcards or {card.id}
    return table.find(cardList, function (id) return table.contains(mark, id) end)
  end,
}
qingshi:addRelatedSkill(qingshi_delay)
zhizhe:addRelatedSkill(zhizhe_delay)
zhizhe:addRelatedSkill(zhizhe_prohibit)
zhugeliang:addSkill(jincui)
zhugeliang:addSkill(qingshi)
zhugeliang:addSkill(zhizhe)
Fk:loadTranslationTable{
  ["wm__zhugeliang"] = "武诸葛亮",
  ["#wm__zhugeliang"] = "忠武良弼",
  ["designer:wm__zhugeliang"] = "韩旭",
  ["illustrator:wm__zhugeliang"] = "梦回唐朝",
  ["jincui"] = "尽瘁",
  [":jincui"] = "锁定技，游戏开始时，你将手牌补至7张。准备阶段，你的体力值调整为与牌堆中点数为7的游戏牌数量相等（至少为1）。"..
  "然后你观看牌堆顶X张牌（X为你的体力值），将这些牌以任意顺序放回牌堆顶或牌堆底。",
  ["qingshi"] = "情势",
  [":qingshi"] = "当你于出牌阶段内使用一张牌时（每种牌名每回合限一次），若手牌中有同名牌，你可以选择一项：1.令此牌对其中一个目标造成的伤害值+1："..
  "2.令任意名其他角色各摸一张牌；3.摸三张牌，然后此技能本回合失效。",
  ["zhizhe"] = "智哲",
  [":zhizhe"] = "限定技，出牌阶段，你可以复制一张手牌（衍生牌除外）。此牌因你使用或打出而进入弃牌堆后，你获得且本回合不能再使用或打出之。",
  ["qingshi-turn"] = "情势",
  ["#qingshi-invoke"] = "情势：请选择一项（当前使用牌为%arg）",
  ["qingshi1"] = "令此牌对其中一个目标伤害+1",
  ["qingshi2"] = "令任意名其他角色各摸一张牌",
  ["qingshi3"] = "摸三张牌，然后此技能本回合失效",
  ["#qingshi1-choose"] = "情势：令%arg对其中一名目标造成伤害+1",
  ["#qingshi2-choose"] = "情势：令任意名其他角色各摸一张牌",
  ["#qingshi_delay"] = "情势",
  ["#zhizhe_delay"] = "智哲",
  ["#zhizhe-active"] = "发动 智哲，选择一张手牌（衍生牌除外），获得一张此牌的复制",
  ["@@zhizhe-inhand"] = "智哲",

  ["$jincui1"] = "情记三顾之恩，亮必继之以死。",
  ["$jincui2"] = "身负六尺之孤，臣当鞠躬尽瘁。",
  ["$qingshi1"] = "兵者，行霸道之势，彰王道之实。",
  ["$qingshi2"] = "将为军魂，可因势而袭，其有战无类。",
  ["$zhizhe1"] = "轻舟载浊酒，此去，我欲借箭十万。",
  ["$zhizhe2"] = "主公有多大胆略，亮便有多少谋略。",
  ["~wm__zhugeliang"] = "天下事，了犹未了，终以不了了之……",
}

local luxun = General(extension, "wm__luxun", "wu", 3)
local xiongmu = fk.CreateTriggerSkill{
  name = "xiongmu",
  mute = true,
  events = {fk.RoundStart, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.RoundStart then
        return true
      else
        return player == target and player:getHandcardNum() <= player.hp and player:getMark("xiongmu_defensive-turn") == 0 and
        #player.room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
          local damage = e.data[5]
          return damage and damage.to == player
        end, Player.HistoryTurn) == 0
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.RoundStart then
      player:broadcastSkillInvoke(self.name)
      room:notifySkillInvoked(player, self.name, "drawcard")
      local x = player.maxHp - player:getHandcardNum()
      if x > 0 and room:askForSkillInvoke(player, self.name, nil, "#xiongmu-draw:::" .. tostring(x)) then
        room:drawCards(player, x, self.name)
        if player.dead then return false end
      end
      if player:isNude() then return false end
      local cards = room:askForCard(player, 1, 998, true, self.name, true, ".", "#xiongmu-cards")
      x = #cards
      if x == 0 then return false end
      table.shuffle(cards)
      local positions = {}
      local y = #room.draw_pile
      for _ = 1, x, 1 do
        table.insert(positions, math.random(y+1))
      end
      table.sort(positions, function (a, b)
        return a > b
      end)
      local moveInfos = {}
      for i = 1, x, 1 do
        table.insert(moveInfos, {
          ids = {cards[i]},
          from = player.id,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonJustMove,
          skillName = self.name,
          drawPilePosition = positions[i],
        })
      end
      room:moveCards(table.unpack(moveInfos))
      if player.dead then return false end
      cards = room:getCardsFromPileByRule(".|8", x)
      if x > #cards then
        table.insertTable(cards, room:getCardsFromPileByRule(".|8", x - #cards, "discardPile"))
      end
      if #cards > 0 then
        player.room:moveCards({
          ids = cards,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonPrey,
          proposer = player.id,
          skillName = self.name,
          moveMark = "@@xiongmu-inhand-round",
        })
      end
    else
      player:broadcastSkillInvoke(self.name)
      room:notifySkillInvoked(player, self.name, "defensive")
      room:setPlayerMark(player, "xiongmu_defensive-turn", 1)
      data.damage = data.damage - 1
    end
  end,

}
local xiongmu_maxcards = fk.CreateMaxCardsSkill{
  name = "#xiongmu_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@xiongmu-inhand-round") > 0
  end,
}
local zhangcai = fk.CreateTriggerSkill{
  name = "zhangcai",
  anim_type = "drawcard",
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (player:getMark("@@ruxian") > 0 or data.card.number == 8)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(math.max(1, #table.filter(player:getCardIds(Player.Hand), function (id)
      return Fk:getCardById(id):compareNumberWith(data.card, false)
    end)), self.name)
  end,
}
local ruxian = fk.CreateActiveSkill{
  name = "ruxian",
  prompt = "#ruxian-active",
  card_num = 0,
  target_num = 0,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    room:setPlayerMark(room:getPlayerById(effect.from), "@@ruxian", 1)
  end,
}
local ruxian_refresh = fk.CreateTriggerSkill{
  name = "#ruxian_refresh",

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@ruxian") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@ruxian", 0)
  end,
}
xiongmu:addRelatedSkill(xiongmu_maxcards)
ruxian:addRelatedSkill(ruxian_refresh)
luxun:addSkill(xiongmu)
luxun:addSkill(zhangcai)
luxun:addSkill(ruxian)
Fk:loadTranslationTable{
  ["wm__luxun"] = "武陆逊",
  ["#wm__luxun"] = "释武怀儒",
  ["designer:wm__luxun"] = "韩旭",
  ["illustrator:wm__luxun"] = "小新",
  ["xiongmu"] = "雄幕",
  [":xiongmu"] = "每轮开始时，你可以将手牌摸至体力上限，然后将任意张牌随机置入牌堆，从牌堆或弃牌堆中获得等量的点数为8的牌，"..
  "这些牌此轮内不计入你的手牌上限。当你每回合受到第一次伤害时，若你的手牌数小于等于体力值，此伤害-1。",
  ["zhangcai"] = "彰才",
  [":zhangcai"] = "当你使用或打出点数为8的牌时，你可以摸X张牌（X为手牌中与使用的牌点数相同的牌的数量且至少为1）。",
  ["ruxian"] = "儒贤",
  [":ruxian"] = "限定技，出牌阶段，你可以将〖彰才〗改为所有点数均可触发摸牌直到你的下回合开始。",

  ["#xiongmu-draw"] = "雄幕：是否将手牌补至体力上限（摸%arg张牌）",
  ["#xiongmu-cards"] = "雄幕：你可将任意张牌随机置入牌堆，然后获得等量张点数为8的牌",
  ["@@xiongmu-inhand-round"] = "雄幕",
  ["#ruxian-active"] = "发动 儒贤，令你发动〖彰才〗没有点数的限制直到你的下个回合开始",
  ["@@ruxian"] = "儒贤",

  ["$xiongmu1"] = "步步为营者，定无后顾之虞。",
  ["$xiongmu2"] = "明公彀中藏龙卧虎，放之海内皆可称贤。",
  ["$zhangcai1"] = "今提墨笔绘乾坤，湖海添色山永春。",
  ["$zhangcai2"] = "手提玉剑斥千军，昔日锦鲤化金龙。",
  ["$ruxian1"] = "儒道尚仁而有礼，贤者知命而独悟。",
  ["$ruxian2"] = "儒门有言，仁为己任，此生不负孔孟之礼。",
  ["~wm__luxun"] = "此生清白，不为浊泥所染……",
}

local guanyu = General(extension, "wm__guanyu", "shu", 5)
local juewu = fk.CreateViewAsSkill{
  name = "juewu",
  prompt = "#juewu-viewas",
  anim_type = "offensive",
  pattern = ".",
  interaction = function()
    local names = Self:getMark("juewu_names")
    if type(names) ~= "table" then
      names = {}
      for _, id in ipairs(Fk:getAllCardIds()) do
        local card = Fk:getCardById(id, true)
        if card.is_damage_card and not card.is_derived then
          table.insertIfNeed(names, card.name)
        end
      end
      table.insertIfNeed(names, "ty__drowning")
      Self:setMark("juewu_names", names)
    end
    local choices = U.getViewAsCardNames(Self, "juewu", names, nil, Self:getTableMark("juewu-turn"))
    if #choices == 0 then return end
    return UI.ComboBox { choices = choices, all_choices = names }
  end,
  card_filter = function(self, to_select, selected)
    if self.interaction.data == nil or #selected > 0 then return false end
    local card = Fk:getCardById(to_select)
    if card.number == 2 then
      return true
    end
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return nil end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    local mark = player:getTableMark("juewu-turn")
    table.insert(mark, use.card.trueName)
    player.room:setPlayerMark(player, "juewu-turn", mark)
  end,
  enabled_at_play = function(self, player)
    local names = player:getMark("juewu_names")
    if type(names) ~= "table" then
      names = {}
      for _, id in ipairs(Fk:getAllCardIds()) do
        local card = Fk:getCardById(id, true)
        if card.is_damage_card and not card.is_derived then
          table.insertIfNeed(names, card.name)
        end
      end
      table.insertIfNeed(names, "ty__drowning")
      player:setMark("juewu_names", names)
    end
    local mark = player:getTableMark("juewu-turn")
    local choices = {}
    for _, name in pairs(names) do
      local to_use = Fk:cloneCard(name)
      to_use.skillName = self.name
      if not table.contains(mark, to_use.trueName) and player:canUse(to_use) then
        return true
      end
    end
  end,
  enabled_at_response = function(self, player, response)
    if response then return false end
    if Fk.currentResponsePattern == nil then return false end
    local names = player:getMark("juewu_names")
    if type(names) ~= "table" then
      names = {}
      for _, id in ipairs(Fk:getAllCardIds()) do
        local card = Fk:getCardById(id, true)
        if card.is_damage_card and not card.is_derived then
          table.insertIfNeed(names, card.name)
        end
      end
      table.insertIfNeed(names, "ty__drowning")
      player:setMark("juewu_names", names)
    end
    local mark = player:getTableMark("juewu-turn")
    local choices = {}
    for _, name in pairs(names) do
      local to_use = Fk:cloneCard(name)
      to_use.skillName = self.name
      if not table.contains(mark, to_use.trueName) and Exppattern:Parse(Fk.currentResponsePattern):match(to_use) then
        return true
      end
    end
  end,
}
local juewu_trigger = fk.CreateTriggerSkill{
  name = "#juewu_trigger",
  events = {fk.AfterCardsMove},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(juewu) then return false end
    local cards = {}
    local handcards = player:getCardIds(Player.Hand)
    for _, move in ipairs(data) do
      if move.to == player.id and move.from and move.from ~= player.id and move.toArea == Player.Hand then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if table.contains({Player.Hand, Player.Equip}, info.fromArea) and  table.contains(handcards, id) then
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
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(self.cost_data) do
      room:setCardMark(Fk:getCardById(id), "@@juewu-inhand", 1)
    end
  end,

  refresh_events = {fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return target == player and data == juewu and player:getMark("juewu-turn") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "juewu-turn", 0)
  end,
}
local juewu_filter = fk.CreateFilterSkill{
  name = "#juewu_filter",
  mute = true,
  card_filter = function(self, card, player, isJudgeEvent)
    return card:getMark("@@juewu-inhand") > 0 and table.contains(player.player_cards[Player.Hand], card.id)
  end,
  view_as = function(self, card)
    return Fk:cloneCard(card.name, card.suit, 2)
  end,
}
local wuyou = fk.CreateActiveSkill{
  name = "wuyou",
  prompt = "#wuyou-active",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = effect.tos and #effect.tos > 0 and room:getPlayerById(effect.tos[1]) or player
    local card_names = player:getMark("wuyou_names")
    if type(card_names) ~= "table" then
      card_names = {}
      local tmp_names = {}
      local card, index
      for _, id in ipairs(Fk:getAllCardIds()) do
        card = Fk:getCardById(id, true)
        if not card.is_derived and card.type ~= Card.TypeEquip then
          index = table.indexOf(tmp_names, card.trueName)
          if index == -1 then
            table.insert(tmp_names, card.trueName)
            table.insert(card_names, {card.name})
          else
            table.insertIfNeed(card_names[index], card.name)
          end
        end
      end
      room:setPlayerMark(player, "wuyou_names", card_names)
    end
    if #card_names == 0 then return end
    card_names = table.map(table.random(card_names, 5), function (card_list)
      return table.random(card_list)
    end)
    local success, dat = room:askForUseActiveSkill(player, "wuyou_declare",
    "#wuyou-declare::" .. target.id, true, { interaction_choices = card_names })
    if not success then return end
    local id = dat.cards[1]
    local card_name = dat.interaction
    if target == player then
      room:setCardMark(Fk:getCardById(id), "@@wuyou-inhand", card_name)
    else
      room:moveCardTo(id, Player.Hand, target, fk.ReasonGive, self.name, nil, false, player.id, {"@@wuyou-inhand", card_name})
    end
  end,
}
local wuyou_refresh = fk.CreateTriggerSkill{
  name = "#wuyou_refresh",

  refresh_events = {fk.PreCardUse, fk.EventAcquireSkill, fk.EventLoseSkill, fk.BuryVictim},
  can_refresh = function(self, event, target, player, data)
    if event == fk.PreCardUse then
      return player == target and not data.card:isVirtual() and data.card:getMark("@@wuyou-inhand") ~= 0
    elseif event == fk.EventAcquireSkill or event == fk.EventLoseSkill then
      return data == wuyou
    elseif event == fk.BuryVictim then
      return player:hasSkill(wuyou, true, true)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.PreCardUse then
      data.extraUse = true
      return false
    end
    local room = player.room
    if table.every(room.alive_players, function(p) return not p:hasSkill(self, true) or p == player end) then
      if player:hasSkill("wuyou&", true, true) then
        room:handleAddLoseSkills(player, "-wuyou&", nil, false, true)
      end
    else
      if not player:hasSkill("wuyou&", true, true) then
        room:handleAddLoseSkills(player, "wuyou&", nil, false, true)
      end
    end
  end,
}
local wuyou_active = fk.CreateActiveSkill{
  name = "wuyou&",
  anim_type = "support",
  prompt = "#wuyou-other",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    local targetRecorded = player:getTableMark("wuyou_targets-phase")
    return table.find(Fk:currentRoom().alive_players, function(p)
      return p ~= player and p:hasSkill(wuyou) and not table.contains(targetRecorded, p.id)
    end)
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):hasSkill(wuyou) and
    not table.contains(Self:getTableMark("wuyou_targets-phase"), to_select)
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.from)
    local player = room:getPlayerById(effect.tos[1])
    player:broadcastSkillInvoke("wuyou")
    local targetRecorded = target:getTableMark("wuyou_targets-phase")
    table.insertIfNeed(targetRecorded, player.id)
    room:setPlayerMark(target, "wuyou_targets-phase", targetRecorded)
    room:moveCardTo(effect.cards, Player.Hand, player, fk.ReasonGive, self.name, nil, false, target.id)
    if player.dead or player:isKongcheng() or target.dead then return end
    wuyou:onUse(room, {from = player.id, tos = {target.id}})
  end,
}
local wuyou_declare = fk.CreateActiveSkill{
  name = "wuyou_declare",
  card_num = 1,
  target_num = 0,
  interaction = function(self)
    return UI.ComboBox { choices = self.interaction_choices}
  end,
  can_use = Util.FalseFunc,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and self.interaction.data and Fk:currentRoom():getCardArea(to_select) == Card.PlayerHand
  end,
}
local wuyou_filter = fk.CreateFilterSkill{
  name = "#wuyou_filter",
  mute = true,
  card_filter = function(self, card, player, isJudgeEvent)
    return card:getMark("@@wuyou-inhand") ~= 0 and table.contains(player.player_cards[Player.Hand], card.id)
  end,
  view_as = function(self, card)
    return Fk:cloneCard(card:getMark("@@wuyou-inhand"), card.suit, card.number)
  end,
}
local wuyou_targetmod = fk.CreateTargetModSkill{
  name = "#wuyou_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return not card:isVirtual() and card:getMark("@@wuyou-inhand") ~= 0
  end,
  bypass_distances =  function(self, player, skill, card, to)
    return not card:isVirtual() and card:getMark("@@wuyou-inhand") ~= 0
  end,
}
local yixian = fk.CreateActiveSkill{
  name = "yixian",
  anim_type = "control",
  card_num = 0,
  target_num = 0,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  interaction = function()
    return UI.ComboBox {
      choices = {"yixian_field", "yixian_discard"}
    }
  end,
  prompt = function(self)
    return "#yixian-active:::" .. self.interaction.data
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if self.interaction.data == "yixian_field" then
      local yixianmap = {}
      local cards = {}
      local equips = {}
      for _, p in ipairs(room.alive_players) do
        equips = p:getCardIds{Player.Equip}
        if #equips > 0 then
          yixianmap[p.id] = #equips
          table.insertTable(cards, equips)
        end
      end
      if #cards == 0 then return end
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id)
      if player.dead then return end
      for _, p in ipairs(room:getAlivePlayers()) do
        if not p.dead then
          local n = yixianmap[p.id]
          if n and n > 0 and room:askForSkillInvoke(player, self.name, nil, "#yixian-repay::" .. p.id..":"..tostring(n)) then
            room:drawCards(p, n, self.name)
            if not p.dead and p:isWounded() then 
              room:recover{
                who = p,
                num = 1,
                recoverBy = player,
                skillName = self.name,
              }
            end
            if player.dead then break end
          end
        end
      end
    elseif self.interaction.data == "yixian_discard" then
      local equips = table.filter(room.discard_pile, function(id)
        return Fk:getCardById(id).type == Card.TypeEquip
      end)
      if #equips > 0 then
        room:moveCardTo(equips, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id)
      end
    end
  end,
}
Fk:addSkill(wuyou_active)
Fk:addSkill(wuyou_declare)
juewu:addRelatedSkill(juewu_trigger)
juewu:addRelatedSkill(juewu_filter)
wuyou:addRelatedSkill(wuyou_refresh)
wuyou:addRelatedSkill(wuyou_filter)
wuyou:addRelatedSkill(wuyou_targetmod)
guanyu:addSkill(juewu)
guanyu:addSkill(wuyou)
guanyu:addSkill(yixian)
Fk:loadTranslationTable{
  ["wm__guanyu"] = "武关羽",
  ["#wm__guanyu"] = "义武千秋",
  ["illustrator:wm__guanyu"] = "黯荧岛_小董",
  ["juewu"] = "绝武",
  [":juewu"] = "你可以将点数为2的牌当伤害牌或【水淹七军】使用（每回合每种牌名限一次）。当你得到其他角色的牌后，这些牌的点数视为2。",
  ["wuyou"] = "武佑",
  [":wuyou"] = "出牌阶段限一次，你可以从五个随机的不为装备牌的牌名中声明一个并选择你的一张手牌，此牌视为你声明的牌且使用时无距离和次数限制。"..
  "其他角色的出牌阶段限一次，其可以将一张手牌交给你，然后你可以从五个随机的不为装备牌的牌名中声明一个并将一张手牌交给该角色，"..
  "此牌视为你声明的牌且使用时无距离和次数限制。",
  ["yixian"] = "义贤",
  [":yixian"] = "限定技，出牌阶段，你可以选择：1.获得场上的所有装备牌，你对以此法被你获得牌的角色依次可以令其摸等量的牌并回复1点体力；"..
  "2.获得弃牌堆中的所有装备牌。",

  ["#juewu-viewas"] = "发动 绝武，将点数为2的牌转化为任意伤害牌使用",
  ["#juewu_trigger"] = "绝武",
  ["#juewu_filter"] = "绝武",
  ["@@juewu-inhand"] = "绝武",
  ["wuyou&"] = "武佑",
  [":wuyou&"] = "出牌阶段限一次，你可以将一张牌交给武关羽，然后其可以将一张牌交给你并声明一种基本牌或普通锦囊牌的牌名，此牌视为声明的牌。",
  ["#wuyou-active"] = "发动 武佑，令一张手牌视为你声明的牌（五选一）",
  ["#wuyou-other"] = "发动 武佑，选择一张牌交给一名拥有“武佑”的角色",
  ["#wuyou-declare"] = "武佑：将一张手牌交给%dest并令此牌视为声明的牌名",
  ["wuyou_declare"] = "武佑",
  ["#wuyou_filter"] = "武佑",
  ["@@wuyou-inhand"] = "武佑",
  ["#yixian-active"] = "发动 义贤，%arg",
  ["yixian_field"] = "获得场上的装备牌",
  ["yixian_discard"] = "获得弃牌堆里的装备牌",
  ["#yixian-repay"] = "义贤：是否令%dest摸%arg张牌并回复1点体力",

  ["$juewu1"] = "此身屹沧海，覆手潮立，浪涌三十六天。",
  ["$juewu2"] = "青龙啸肃月，长刀裂空，威降一十九将。",
  ["$wuyou1"] = "秉赤面，观春秋，虓菟踏纛，汗青著峥嵘！",
  ["$wuyou2"] = "着青袍，饮温酒，五关已过，来将且通名！",
  ["$yixian1"] = "春秋着墨十万卷，长髯映雪千里行。",
  ["$yixian2"] = "义驱千里长路，风起桃园芳菲。",
  ["~wm__guanyu"] = "天下泪染将军袍，且枕青山梦桃园……",
}

local huangfusong = General(extension, "wm__huangfusong", "qun", 4)
local chaozhen = fk.CreateTriggerSkill{
  name = "chaozhen",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart, fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:getMark("@@chaozhen-turn") == 0 and
      (event == fk.EventPhaseStart and player.phase == Player.Start or event == fk.EnterDying)
  end,
  on_cost = function(self, event, target, player, data)
    local choice = player.room:askForChoice(player, {"Field", "Pile", "Cancel"}, self.name, "#chaozhen-invoke")
    if choice ~= "Cancel" then
      self.cost_data = {choice = choice}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards, num = {}, 14
    if self.cost_data.choice == "Field" then
      for _, p in ipairs(room.alive_players) do
        for _, id in ipairs(p:getCardIds("ej")) do
          if Fk:getCardById(id).number <= num then
            num = Fk:getCardById(id).number
            table.insert(cards, id)
          end
        end
      end
    else
      for _, id in ipairs(room.draw_pile) do
        if Fk:getCardById(id).number <= num then
          num = Fk:getCardById(id).number
          table.insert(cards, id)
        end
      end
    end
    cards = table.filter(cards, function (id)
      return Fk:getCardById(id).number == num
    end)
    if #cards == 0 then return end
    local card = table.random(cards)
    local yes = Fk:getCardById(card).number == 1
    room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, true, player.id)
    if player.dead then return end
    if yes then
      room:setPlayerMark(player, "@@chaozhen-turn", 1)
      if player:isWounded() then
        room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name,
        })
      end
    else
      room:changeMaxHp(player, -1)
    end
  end,
}
local lianjie = fk.CreateTriggerSkill{
  name = "lianjie",
  anim_type = "drawcard",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.firstTarget and player:getHandcardNum() < player.maxHp and
      U.IsUsingHandcard(player, data) and not player:isKongcheng() and
      table.every(player:getCardIds("h"), function (id)
        return Fk:getCardById(id).number >= data.card.number
      end) and
      not table.contains(player:getTableMark("lianjie-turn"), data.card.number)
  end,
  on_use = function(self, event, target, player, data)
    player.room:addTableMark(player, "lianjie-turn", data.card.number)
    player:drawCards(player.maxHp - player:getHandcardNum(), self.name, "top", "@@lianjie-inhand-turn")
  end,
}
local lianjie_targetmod = fk.CreateTargetModSkill{
  name = "#lianjie_targetmod",
  bypass_times = function (self, player, skill, scope, card, to)
    return card:getMark("@@lianjie-inhand-turn") > 0
  end,
  bypass_distances = function(self, player, skill, card)
    return card:getMark("@@lianjie-inhand-turn") > 0
  end,
}
local jiangxian = fk.CreateActiveSkill{
  name = "jiangxian",
  anim_type = "special",
  card_num = 0,
  target_num = 0,
  frequency = Skill.Limited,
  prompt = "#jiangxian",
  interaction = function()
    local choices = {"jiangxian2"}
    if Self:hasSkill(chaozhen, true) then
      table.insert(choices, 1, "jiangxian1")
    end
    return UI.ComboBox {choices = choices}
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if self.interaction.data == "jiangxian1" then
      room:handleAddLoseSkills(player, "-chaozhen", nil, true, false)
      if player.dead then return end
      room:setPlayerMark(player, "jiangxian1", 1)
      if player.maxHp < 5 then
        room:changeMaxHp(player, 5 - player.maxHp)
      end
    else
      room:setPlayerMark(player, "@@jiangxian-turn", 1)
    end
  end,
}
local jiangxian_maxcards = fk.CreateMaxCardsSkill{
  name = "#jiangxian_maxcards",
  fixed_func = function(self, player)
    if player:getMark("jiangxian1") > 0 then
      return 5
    end
  end
}
local jiangxian_delay = fk.CreateTriggerSkill{
  name = "#jiangxian_delay",
  mute = true,
  events = {fk.DamageCaused, fk.AfterTurnEnd},
  can_trigger = function(self, event, target, player, data)
    if target and target == player and player:getMark("@@jiangxian-turn") > 0 then
      if event == fk.DamageCaused then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if use_event then
        local use = use_event.data[1]
        return (use.extra_data or {}).jiangxian == player.id
      end
      elseif event == fk.AfterTurnEnd then
        return player:hasSkill(lianjie, true)
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DamageCaused then
      data.damage = data.damage + math.min(5,
      #player.room.logic:getActualDamageEvents(5, function(e)
        return e.data[1].from == player
      end, Player.HistoryTurn))
    elseif event == fk.AfterTurnEnd then
      room:handleAddLoseSkills(player, "-lianjie", nil, true, false)
    end
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("@@jiangxian-turn") > 0 and data.card.is_damage_card and
      data.card:getMark("@@lianjie-inhand-turn") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.jiangxian = player.id
  end,
}
lianjie:addRelatedSkill(lianjie_targetmod)
jiangxian:addRelatedSkill(jiangxian_maxcards)
jiangxian:addRelatedSkill(jiangxian_delay)
huangfusong:addSkill(chaozhen)
huangfusong:addSkill(lianjie)
huangfusong:addSkill(jiangxian)
Fk:loadTranslationTable{
  ["wm__huangfusong"] = "武皇甫嵩",
  ["#wm__huangfusong"] = "襄武翼汉",
  ["illustrator:wm__huangfusong"] = "",

  ["chaozhen"] = "朝镇",
  [":chaozhen"] = "准备阶段或当你进入濒死状态时，你可以选择从场上或牌堆中随机获得一张点数最小的牌，若此牌点数：为A，你回复1点体力，"..
  "此技能本回合失效；不为A，你减1点体力上限。",
  ["lianjie"] = "连捷",
  [":lianjie"] = "当你使用手牌指定目标后，若你手牌的点数均不小于此牌点数（每个点数每回合限一次，无点数视为0），你可以将手牌摸至体力上限，"..
  "本回合使用以此法摸到的牌无距离次数限制。",
  ["jiangxian"] = "将贤",
  [":jiangxian"] = "限定技，出牌阶段，你可以选择一项：<br>1.失去〖朝镇〗，将体力上限和手牌上限增加至5；<br>2.直到回合结束，当你使用因"..
  "〖连捷〗获得的牌造成伤害时，此伤害+X（X为你本回合造成伤害次数，至多为5），此回合结束后你失去〖连捷〗。",
  ["#chaozhen-invoke"] = "朝镇：你可以从场上或牌堆中随机获得一张点数最小的牌",
  ["@@chaozhen-turn"] = "朝镇失效",
  ["@@lianjie-inhand-turn"] = "连捷",
  ["#jiangxian"] = "将贤：选择一项",
  ["jiangxian1"] = "失去“朝镇”，体力上限和手牌上限增加至5",
  ["jiangxian2"] = "使用“连捷”牌伤害增加，回合结束失去“连捷”",
  ["@@jiangxian-turn"] = "将贤",
}



return extension
