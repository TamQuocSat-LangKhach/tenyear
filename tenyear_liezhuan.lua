local extension = Package("tenyear_liezhuan")
extension.extensionName = "tenyear"
local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["tenyear_liezhuan"] = "十周年-武将列传",
}

--黄巾之乱：韩遂 刘宏 朱儁 许劭
local hansui = General(extension, "ty__hansui", "qun", 4)
local ty__niluan = fk.CreateViewAsSkill{
  name = "ty__niluan",
  anim_type = "offensive",
  pattern = "slash",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("slash")
    card.skillName = self.name
    card:addSubcard(cards[1])
    return card
  end,
  enabled_at_response = function(self, player, response)
    return not response and player.phase == Player.Play
  end,
}
local ty__niluan_record = fk.CreateTriggerSkill{
  name = "#ty__niluan_record",

  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, "ty__niluan") and not data.damageDealt
  end,
  on_refresh = function(self, event, target, player, data)
    if not data.extraUse then
      data.extraUse = true
      player:addCardUseHistory(data.card.trueName, -1)
    end
  end,
}
local weiwu = fk.CreateViewAsSkill{
  name = "weiwu",
  anim_type = "control",
  pattern = "snatch",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Red
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("snatch")
    card.skillName = self.name
    card:addSubcard(cards[1])
    return card
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
}
local weiwu_targetmod = fk.CreateTargetModSkill{
  name = "#weiwu_targetmod",
  bypass_distances =  function(self, player, skill, card, to)
    return table.contains(card.skillNames, weiwu.name)
  end,
}
ty__niluan:addRelatedSkill(ty__niluan_record)
weiwu:addRelatedSkill(weiwu_targetmod)
hansui:addSkill(ty__niluan)
hansui:addSkill(weiwu)
Fk:loadTranslationTable{
  ["ty__hansui"] = "韩遂",
  ["#ty__hansui"] = "雄踞北疆",
  ["illustrator:ty__hansui"] = "凝聚永恒",
  ["ty__niluan"] = "逆乱",
  [":ty__niluan"] = "出牌阶段，你可以将一张黑色牌当【杀】使用；你以此法使用的【杀】结算后，若此【杀】未造成伤害，其不计入使用次数限制。",
  ["weiwu"] = "违忤",
  [":weiwu"] = "出牌阶段限一次，你可以将一张红色牌当无距离限制的【顺手牵羊】使用。",

  ["$ty__niluan1"] = "如果不能功成名就，那就干脆为祸一方！",
  ["$ty__niluan2"] = "哈哈哈哈哈，天下之事皆无常！",
  ["$weiwu1"] = "凉州寸土，不可拱手让人。",
  ["$weiwu2"] = "明遵旨，暗忤意。",
  ["~ty__hansui"] = "马侄儿为何？啊！！",
}

local ty__liuhong = General(extension, "ty__liuhong", "qun", 4)
local yujue = fk.CreateActiveSkill{
  name = "yujue",
  anim_type = "support",
  interaction = function()
    local slots = {}
    for _, slot in ipairs({"WeaponSlot","ArmorSlot","OffensiveRideSlot","DefensiveRideSlot","TreasureSlot"}) do
      local subtype = Util.convertSubtypeAndEquipSlot(slot)
      if #Self:getAvailableEquipSlots(subtype) > 0 then
        table.insert(slots, slot)
      end
    end
    if #slots == 0 then return end
    return UI.ComboBox {choices = slots}
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1 and #player:getAvailableEquipSlots() > 0
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 1,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.tos[1])
    room:abortPlayerArea(player, self.interaction.data)
    if not player.dead and not to:isKongcheng() then
      local card = room:askForCard(to, 1, 1, false, self.name, false, ".", "#yujue-give:"..player.id)
      if #card > 0 then
        room:obtainCard(player, card[1], false, fk.ReasonGive)
      end
    end
    if not to:hasSkill("zhihu",true) then
      local mark = type(player:getMark("yujue_skill")) == "table" and player:getMark("yujue_skill") or {}
      table.insertIfNeed(mark, to.id)
      room:setPlayerMark(player, "yujue_skill", mark)
      room:handleAddLoseSkills(to, "zhihu", nil)
    end
  end,
}
local yujue_trigger = fk.CreateTriggerSkill{
  name = "#yujue_trigger",
  refresh_events = {fk.TurnStart, fk.Death},
  can_refresh = function (self, event, target, player, data)
    return player == target and type(player:getMark("yujue_skill")) == "table"
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("yujue_skill")
    room:setPlayerMark(player, "yujue_skill", 0)
    for _, pid in ipairs(mark) do
      local p = room:getPlayerById(pid)
      room:handleAddLoseSkills(p, "-zhihu", nil, false)
    end
  end,
}
yujue:addRelatedSkill(yujue_trigger)
ty__liuhong:addSkill(yujue)
local tuxing = fk.CreateTriggerSkill{
  name = "tuxing",
  events = {fk.AreaAborted, fk.DamageCaused},
  mute = true,
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if event == fk.AreaAborted then
      if target == player and player:hasSkill(self) then
        local slots = data.slots
        for i = 3, 7 do
          if slots[tostring(i)] then
            return true
          end
        end
      end
    else
      return target == player and player:getMark("@@tuxing_damage") > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.AreaAborted then
      room:notifySkillInvoked(player, self.name, "defensive")
      room:changeMaxHp(player, 1)
      if player:isWounded() and not player.dead then
        room:recover({ who = player, num = 1, recoverBy = player, skillName = self.name })
      end
      if #player:getAvailableEquipSlots() == 0 and player:getMark("@@tuxing_damage") == 0 and player:hasSkill(self) then
        room:notifySkillInvoked(player, self.name, "big")
        room:addPlayerMark(player, "@@tuxing_damage")
        room:changeMaxHp(player, -4)
      end
    else
      room:notifySkillInvoked(player, self.name, "offensive")
      data.damage = data.damage + 1
    end
  end,
}
ty__liuhong:addSkill(tuxing)
local zhihu = fk.CreateTriggerSkill{
  name = "zhihu",
  frequency = Skill.Compulsory,
  events = {fk.Damage},
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryTurn) < 2 and player ~= data.to
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
  end,
}
ty__liuhong:addRelatedSkill(zhihu)
Fk:loadTranslationTable{
  ["ty__liuhong"] = "刘宏",
  ["#ty__liuhong"] = "汉灵帝",
  ["illustrator:ty__liuhong"] = "凝聚永恒",
  ["yujue"] = "鬻爵",
  [":yujue"] = "出牌阶段限一次，你可以废除你的一个装备栏，并选择一名有手牌的其他角色，令其交给你一张手牌，然后其获得技能“执笏”直到你的下个回合开始。",
  ["#yujue-give"] = "鬻爵：请交给 %src 一张手牌",
  ["tuxing"] = "图兴",
  [":tuxing"] = "锁定技，①当你废除一个装备栏时，你加1点体力上限并回复1点体力。②当你首次废除所有装备栏后，你减4点体力上限，然后你本局游戏接下来造成的伤害+1。",
  ["@@tuxing_damage"] = "图兴加伤",
  ["zhihu"] = "执笏",
  [":zhihu"] = "锁定技，每回合限两次，当你对其他角色造成伤害后，你摸两张牌。",
  
  ["$yujue1"] = "国库空虚，鬻爵可解。",
  ["$yujue2"] = "卖官鬻爵，酣歌畅饮。",
  ["$tuxing1"] = "国之兴亡，休戚相关。",
  ["$tuxing2"] = "兴业安民，宏图可绘。",
  ["~ty__liuhong"] = "权利的滋味，让人沉沦。",
}

local zhujun = General(extension, "ty__zhujun", "qun", 4)
local gongjian = fk.CreateTriggerSkill{
  name = "gongjian",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and data.card.trueName == "slash" and data.firstTarget and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
      return self.gongjian_to and #self.gongjian_to > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(self.gongjian_to, function(id) return not room:getPlayerById(id):isNude() end)
    local tos = room:askForChoosePlayers(player, targets, 1, 10, "#gongjian-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(self.cost_data) do
      local cards = room:askForCardsChosen(player, room:getPlayerById(id), 1, 2, "he", self.name)
      local dummy = Fk:cloneCard("dilu")
      for i = #cards, 1, -1 do
        if Fk:getCardById(cards[i]).trueName == "slash" then
          dummy:addSubcard(cards[i])
          table.removeOne(cards, cards[i])
        end
      end
      if #dummy.subcards > 0 then
        room:obtainCard(player, dummy, false, fk.ReasonPrey)
      end
      if #cards > 0 then
        room:throwCard(cards, self.name, room:getPlayerById(id), player)
      end
    end
  end,

  refresh_events = {fk.TargetSpecified},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self) and data.card.trueName == "slash" and data.firstTarget
  end,
  on_refresh = function(self, event, target, player, data)
    self.gongjian_to = {}
    player.tag[self.name] = player.tag[self.name] or {}
    if #AimGroup:getAllTargets(data.tos) > 0 then
      for _, id in ipairs(AimGroup:getAllTargets(data.tos)) do
        if table.contains(player.tag[self.name], id) then
          table.insert(self.gongjian_to, id)
        end
      end
    end
    if #AimGroup:getAllTargets(data.tos) > 0 then
      player.tag[self.name] = AimGroup:getAllTargets(data.tos)
    else
      player.tag[self.name] = {}
    end
  end,
}
local kuimang = fk.CreateTriggerSkill{
  name = "kuimang",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player.tag[self.name] and table.contains(player.tag[self.name], target.id)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
  end,

  refresh_events = {fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_refresh = function(self, event, target, player, data)
    player.tag[self.name] = player.tag[self.name] or {}
    table.insertIfNeed(player.tag[self.name], data.to.id)
  end,
}
zhujun:addSkill(gongjian)
zhujun:addSkill(kuimang)
Fk:loadTranslationTable{
  ["ty__zhujun"] = "朱儁",
  ["#ty__zhujun"] = "征无疑虑",
  ["illustrator:ty__zhujun"] = "凝聚永恒",
  ["gongjian"] = "攻坚",
  [":gongjian"] = "每回合限一次，当一名角色使用【杀】指定目标后，若此【杀】与上一张【杀】有相同的目标，则你可以弃置其中相同目标角色各至多两张牌，"..
  "你获得其中的【杀】。",
  ["kuimang"] = "溃蟒",
  [":kuimang"] = "锁定技，当一名角色死亡时，若你对其造成过伤害，你摸两张牌。",
  ["#gongjian-choose"] = "攻坚：你可以选择其中相同的目标角色，弃置每名角色各至多两张牌，你获得其中的【杀】",

  ["$gongjian1"] = "善攻者，敌不知其所守。",
  ["$gongjian2"] = "围解自出，势必意散。",
  ["$kuimang1"] = "黄巾流寇，不过如此。",
  ["$kuimang2"] = "黄巾作乱，奉旨平叛！",
  ["~ty__zhujun"] = "乞降不受，愿一战！",
}

local xushao = General(extension, "ty__xushao", "qun", 4)

---@param player ServerPlayer
local addTYPingjianSkill = function(player, skill_name)
  local room = player.room
  local skill = Fk.skills[skill_name]
  if skill == nil or player:hasSkill(skill_name, true) then return false end
  room:handleAddLoseSkills(player, skill_name, nil)
  local pingjian_skills = U.getMark(player, "ty__pingjian_skills")
  table.insertIfNeed(pingjian_skills, skill_name)
  room:setPlayerMark(player, "ty__pingjian_skills", pingjian_skills)
  local pingjian_skill_times = U.getMark(player, "ty__pingjian_skill_times")
  table.insert(pingjian_skill_times, {skill_name, player:usedSkillTimes(skill_name)})
  for _, s in ipairs(skill.related_skills) do
    table.insert(pingjian_skill_times, {s.name, player:usedSkillTimes(s.name)})
  end
  room:setPlayerMark(player, "ty__pingjian_skill_times", pingjian_skill_times)
end

---@param player ServerPlayer
local removeTYPingjianSkill = function(player, skill_name)
  local room = player.room
  local skill = Fk.skills[skill_name]
  if skill == nil then return false end
  room:handleAddLoseSkills(player, "-" .. skill_name, nil)
  local pingjian_skills = U.getMark(player, "ty__pingjian_skills")
  table.removeOne(pingjian_skills, skill_name)
  room:setPlayerMark(player, "ty__pingjian_skills", pingjian_skills)
  local invoked = false
  local pingjian_skill_times = U.getMark(player, "ty__pingjian_skill_times")
  local record_copy = {}
  for _, pingjian_record in ipairs(pingjian_skill_times) do
    if #pingjian_record == 2 then
      local record_name = pingjian_record[1]
      if record_name == skill_name or not table.every(skill.related_skills, function (s)
          return s.name ~= record_name end) then
        if player:usedSkillTimes(record_name) > pingjian_record[2] then
          invoked = true
        end
      else
        table.insert(record_copy, pingjian_record)
      end
    end
  end
  room:setPlayerMark(player, "ty__pingjian_skill_times", record_copy)

  if invoked then
    local used_skills = U.getMark(player, "ty__pingjian_used_skills")
    table.insertIfNeed(used_skills, skill_name)
    room:setPlayerMark(player, "ty__pingjian_used_skills", used_skills)
  end
end

local ty__pingjian = fk.CreateActiveSkill{
  name = "ty__pingjian",
  prompt = "#ty__pingjian-active",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local used_skills = U.getMark(player, "ty__pingjian_used_skills")
    local skills = table.filter({
      "qiangwu", "ol_ex__qiangxi", "ol_ex__luanji", "ty_ex__sanyao", "ol__xuehen", "ex__yijue", "daoshu", "m_ex__xianzhen",
      "tianyi", "ty_ex__zhanjue", "ty__lianji", "ty_ex__wurong", "fenxun", "ol_ex__jiuchi", "m_ex__zenhui", "xuezhao", "hs__kurou", "m_ex__mieji",
      "ex__zhiheng", "ex__guose", "ty_ex__shenxing", "ty__songci", "guolun", "os__gongxin", "lueming", "busuan", "ty__lianzhu",
      "ex__fanjian", "tanbei", "ty__qingcheng", "chengshang", "ty__songshu", "poxi", "m_ex__ganlu", "qixi", "ty__kuangfu", "qice",
      "os_ex__gongqi", "ty_ex__huaiyi", "shanxi", "ol_ex__tiaoxin", "qingnang", "quji", "ty_ex__anguo", "limu", "ex__jieyin",
      "m_ex__anxu", "ty_ex__mingce", "ziyuan", "mou__lijian", "mingjian", "ex__rende", "mizhao", "yanjiao", "ol_ex__dimeng", "ol_ex__zhijian",
      "quhu", "nuchen", "kanji", "ol_ex__duanliang", "yangjie", "hongyi", "m_ex__junxing", "m_ex__yanzhu", "ol_ex__changbiao",
      "fengzi", "yanxi", "jiwu", "xuanbei", "yushen", "jinhui", "shuojian", "qingshi", "guanxu", "zunwei", "jichun", "liangyan"
    }, function (skill_name)
      return not table.contains(used_skills, skill_name) and not player:hasSkill(skill_name, true)
    end)
    if #skills == 0 then return false end
    local choices = table.random(skills, 3)
    local skill_name = room:askForChoice(player, choices, self.name, "#ty__pingjian-choice", true)
    local phase_event = room.logic:getCurrentEvent():findParent(GameEvent.Phase)
    if phase_event ~= nil then
      addTYPingjianSkill(player, skill_name)
      phase_event:addCleaner(function()
        removeTYPingjianSkill(player, skill_name)
      end)
    end
  end,
}
local ty__pingjian_trigger = fk.CreateTriggerSkill{
  name = "#ty__pingjian_trigger",
  events = {fk.Damaged, fk.EventPhaseStart},
  main_skill = ty__pingjian,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(ty__pingjian.name) or player ~= target then return false end
    if event == fk.Damaged then
      return true
    elseif event == fk.EventPhaseStart then
      return player.phase == Player.Finish
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, ty__pingjian.name)
    player:broadcastSkillInvoke(ty__pingjian.name)
    local used_skills = U.getMark(player, "ty__pingjian_used_skills")
    local skills = {}
    if event == fk.Damaged then
      skills = table.filter({
        "guixin", "ty__benyu", "ex__fankui", "ex__ganglie", "ex__yiji", "ex__jianxiong", "os_ex__enyuan", "chouce", "ol_ex__jieming",
        "fangzhu", "chengxiang", "huituo", "ty__wangxi", "yuce", "zhiyu", "wanggui", "qianlong", "ty__jilei",
        "xianchou", "rangjie", "liejie", "os__fupan", "zhichi", "yuqi", "silun", "yashi", "qingxian", "xiace"
      }, function (skill_name)
        return not table.contains(used_skills, skill_name) and not player:hasSkill(skill_name, true)
      end)
    elseif event == fk.EventPhaseStart then
      skills = table.filter({
        "ty_ex__zhiyan", "ex__biyue", "fujian", "kunfen", "ol_ex__jushou", "os_ex__bingyi", "miji", "zhengu",
        "juece", "sp__youdi", "kuanshi", "ty__jieying", "suizheng", "m_ex__jieyue", "shenfu", "meihun",
        "pijing", "zhuihuan", "os__juchen", "os__xingbu", "zuilun", "mozhi", "ty_ex__jingce", "nuanhui", "sangu",
        "js__pianchong", "linghui"
      }, function (skill_name)
        return not table.contains(used_skills, skill_name) and not player:hasSkill(skill_name, true)
      end)
    end
    if #skills == 0 then return false end
    local choices = table.random(skills, 3)
    local skill_name = room:askForChoice(player, choices, ty__pingjian.name, "#ty__pingjian-choice", true)
    local skill = Fk.skills[skill_name]
    if skill == nil then return false end

    addTYPingjianSkill(player, skill_name)
    if skill:triggerable(event, target, player, data) then
      skill:trigger(event, target, player, data)
    end
    removeTYPingjianSkill(player, skill_name)
  end,
}
local ty__pingjian_invalidity = fk.CreateInvaliditySkill {
  name = "#ty__pingjian_invalidity",
  invalidity_func = function(self, player, skill)
    local pingjian_skill_times = U.getMark(player, "ty__pingjian_skill_times")
    return table.find(pingjian_skill_times, function (pingjian_record)
      if #pingjian_record == 2 then
        local skill_name = pingjian_record[1]
        if skill.name == skill_name or not table.every(skill.related_skills, function (s)
          return s.name ~= skill_name end) then
            return player:usedSkillTimes(skill_name) > pingjian_record[2]
        end
      end
    end)
  end
}

ty__pingjian:addRelatedSkill(ty__pingjian_trigger)
ty__pingjian:addRelatedSkill(ty__pingjian_invalidity)
xushao:addSkill(ty__pingjian)

Fk:loadTranslationTable{
  ["ty__xushao"] = "许劭",
  ["#ty__xushao"] = "识人读心",
  ["illustrator:ty__xushao"] = "Thinking",
  ["ty__pingjian"] = "评荐",
  ["#ty__pingjian_trigger"] = "评荐",
  [":ty__pingjian"] = "出牌阶段，或结束阶段，或当你受到伤害后，你可以从对应时机的技能池中随机抽取三个技能，"..
    "然后你选择并视为拥有其中一个技能直到时机结束（每个技能限发动一次）。",
  ["#ty__pingjian-active"] = "发动 评荐，从三个出牌阶段的技能中选择一个学习",
  ["#ty__pingjian-choice"] = "评荐：选择要学习的技能",

  ["$ty__pingjian1"] = "识人读心，评荐推达。",
  ["$ty__pingjian2"] = "月旦雅评，试论天下。",
  ["~ty__xushao"] = "守节好耻，不可逡巡……",
}

--诸侯伐董：丁原 王荣 麹义 韩馥
local dingyuan = General(extension, "ty__dingyuan", "qun", 4)
local cixiao = fk.CreateTriggerSkill{
  name = "cixiao",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and
    table.find(player.room.alive_players, function (p) return p ~= player and not p:hasSkill("panshi", true) end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if table.find(room.alive_players, function (p) return p:hasSkill("panshi", true) end) then
      local tos, id = room:askForChooseCardAndPlayers(player, table.map(table.filter(room.alive_players, function (p)
        return p ~= player and not p:hasSkill("panshi", true) end), Util.IdMapper), 1, 1, ".", "#cixiao-discard", self.name, true)
      if #tos > 0 and id then
        self.cost_data = {tos[1], id}
        return true
      end
    else
      local tos = room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#cixiao-choose", self.name, true)
      if #tos > 0 then
        self.cost_data = {tos[1]}
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data[1])
    if #self.cost_data > 1 then
      room:throwCard(self.cost_data[2], self.name, player, player)
    end
    for _, p in ipairs(room.alive_players) do
      room:handleAddLoseSkills(p, "-panshi", nil, true, false)
    end
    room:handleAddLoseSkills(to, "panshi", nil, true, false)
  end,
}
local xianshuai = fk.CreateTriggerSkill{
  name = "xianshuai",
  anim_type = "offensive",
  events = {fk.Damage},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    local room = player.room
    local damage_event = room.logic:getCurrentEvent()
    if not damage_event then return false end
    local x = player:getMark("xianshuai_record-round")
    if x == 0 then
      room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
        local reason = e.data[3]
        if reason == "damage" then
          local first_damage_event = e:findParent(GameEvent.Damage)
          if first_damage_event then
            x = first_damage_event.id
            room:setPlayerMark(player, "xianshuai_record-round", x)
          end
          return true
        end
      end, Player.HistoryRound)
    end
    return damage_event.id == x
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
    if player == target and not data.to.dead then
      player.room:damage{
        from = player,
        to = data.to,
        damage = 1,
        skillName = self.name,
      }
    end
  end,
}
local panshi = fk.CreateTriggerSkill{
  name = "panshi",
  events = {fk.EventPhaseStart, fk.DamageCaused, fk.Damage},
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player == target then
      if event == fk.EventPhaseStart then
        return player.phase == Player.Start and table.find(player.room.alive_players, function (p)
          return p ~= player and p:hasSkill(cixiao.name, true) end)
      elseif event == fk.DamageCaused or event == fk.Damage then
        return player.phase == Player.Play and data.to:hasSkill(cixiao.name, true) and
        data.card and data.card.trueName =="slash" and not data.chain
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:notifySkillInvoked(player, self.name, "negative")
      player:broadcastSkillInvoke(self.name)
      local fathers = table.filter(room.alive_players, function (p) return p ~= player and p:hasSkill(cixiao.name, true) end)
      if #fathers == 1 then
        room:doIndicate(player.id, {fathers[1].id})
        if player:isKongcheng() then return false end
        local card = room:askForCard(player, 1, 1, false, self.name, false, ".", "#panshi-give-to:"..fathers[1].id)
        if #card > 0 then
          room:obtainCard(fathers[1].id, card[1], false, fk.ReasonGive)
        end
      else
        local tos, id = room:askForChooseCardAndPlayers(player, table.map(fathers, Util.IdMapper), 1, 1, ".|.|.|hand", "#panshi-give", self.name, false)
        if #tos > 0 and id then
          room:obtainCard(tos[1], id, false, fk.ReasonGive)
        end
      end
    elseif event == fk.DamageCaused then
      room:notifySkillInvoked(player, self.name, "offensive")
      player:broadcastSkillInvoke(self.name)
      data.damage = data.damage + 1
    elseif event == fk.Damage then
      room:notifySkillInvoked(player, self.name, "negative")
      player:broadcastSkillInvoke(self.name)
      player:endPlayPhase()
    end
  end,

  refresh_events = {fk.EventLoseSkill, fk.EventAcquireSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@panshi_son", event == fk.EventAcquireSkill and 1 or 0)
  end,
}
dingyuan:addSkill(cixiao)
dingyuan:addSkill(xianshuai)
dingyuan:addRelatedSkill(panshi)
Fk:loadTranslationTable{
  ["ty__dingyuan"] = "丁原",
  ["#ty__dingyuan"] = "养虎为患",
  ["illustrator:ty__dingyuan"] = "秋呆呆",
  ["cixiao"] = "慈孝",
  [":cixiao"] = "准备阶段，若场上没有“义子”，你可以令一名其他角色获得一个“义子”标记；若场上有“义子”标记，你可以弃置一张牌移动“义子”标记。拥有“义子”标记的角色获得技能〖叛弑〗。",
  ["xianshuai"] = "先率",
  [":xianshuai"] = "锁定技，一名角色造成伤害后，若此伤害是本轮第一次造成伤害，你摸一张牌。若伤害来源为你，你对受到伤害的角色造成1点伤害。",
  ["panshi"] = "叛弑",
  [":panshi"] = "锁定技，准备阶段，你将一张手牌交给拥有技能〖慈孝〗的角色；你于出牌阶段使用的【杀】对其造成伤害时，此伤害+1且你于造成伤害后结束出牌阶段。",
  ["#cixiao-choose"] = "慈孝：可选择一名其他角色，令其获得义子标记",
  ["#cixiao-discard"] = "慈孝：可弃置一张牌来转移将义子标记",
  ["@@panshi_son"] = "义子",
  ["#panshi-give-to"] = "叛弑：必须选择一张手牌交给%src",
  ["#panshi-give"] = "叛弑：必须选择一张手牌交给一名拥有慈孝的角色",

  ["$cixiao1"] = "吾儿奉先，天下无敌！",
  ["$cixiao2"] = "父慈子孝，义理为先！",
  ["$xianshuai1"] = "九州齐喑，首义瞩吾！",
  ["$xianshuai2"] = "雄兵一击，则天下大白！",
  ["~ty__dingyuan"] = "你我父子，此恩今日断！",
}

local wangrong = General(extension, "ty__wangrongh", "qun", 3, 3, General.Female)
local minsi = fk.CreateActiveSkill{
  name = "minsi",
  anim_type = "drawcard",
  min_card_num = 1,
  target_num = 0,
  prompt = "#minsi",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isNude()
  end,
  card_filter = function(self, to_select, selected)
    if not Self:prohibitDiscard(Fk:getCardById(to_select)) then
      local num = 0
      for _, id in ipairs(selected) do
        num = num + Fk:getCardById(id).number
      end
      return num + Fk:getCardById(to_select).number <= 13
    end
  end,
  feasible = function (self, selected, selected_cards)
    local num = 0
    for _, id in ipairs(selected_cards) do
      num = num + Fk:getCardById(id).number
    end
    return num == 13
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    if player.dead then return end
    local cards = player:drawCards(2 * #effect.cards, self.name)
    if player.dead then return end
    cards = table.filter(cards, function(id) return room:getCardOwner(id) == player and room:getCardArea(id) == Card.PlayerHand end)
    if #cards == 0 then return end
    for _, id in ipairs(cards) do
      room:setCardMark(Fk:getCardById(id), "@@minsi-inhand", 1)
    end
  end,
}
local minsi_record = fk.CreateTriggerSkill{
  name = "#minsi_record",

  refresh_events = {fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes("minsi", Player.HistoryTurn) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    for _, id in ipairs(player:getCardIds("h")) do
      player.room:setCardMark(Fk:getCardById(id), "@@minsi-inhand", 0)
    end
  end,
}
local minsi_targetmod = fk.CreateTargetModSkill{
  name = "#minsi_targetmod",
  bypass_distances =  function(self, player, skill, card, to)
    return card and card:getMark("@@minsi-inhand") > 0 and card.color == Card.Black
  end,
}
local minsi_maxcards = fk.CreateMaxCardsSkill{
  name = "#minsi_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@minsi-inhand") > 0 and card.color == Card.Red
  end,
}
local jijing = fk.CreateTriggerSkill{
  name = "jijing",
  anim_type = "defensive",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
    }
    room:judge(judge)
    if player.dead or player:isNude() then return end
    local n = judge.card.number
    room:setPlayerMark(player, "jijing-tmp", n)
    local success, dat = room:askForUseActiveSkill(player, "jijing_active", "#jijing-discard:::"..n, true)
    room:setPlayerMark(player, "jijing-tmp", 0)
    if success then
      room:throwCard(dat.cards, self.name, player, player)
      if not player.dead and player:isWounded() then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name,
        }
      end
    end
  end,
}
local jijing_active = fk.CreateActiveSkill{
  name = "jijing_active",
  mute = true,
  min_card_num = 1,
  target_num = 0,
  card_filter = function(self, to_select, selected)
    if not Self:prohibitDiscard(Fk:getCardById(to_select)) then
      local num = 0
      for _, id in ipairs(selected) do
        num = num + Fk:getCardById(id).number
      end
      return num + Fk:getCardById(to_select).number <= Self:getMark("jijing-tmp")
    end
  end,
  feasible = function (self, selected, selected_cards)
    local num = 0
    for _, id in ipairs(selected_cards) do
      num = num + Fk:getCardById(id).number
    end
    return num == Self:getMark("jijing-tmp")
  end,
}
local zhuide = fk.CreateTriggerSkill{
  name = "zhuide",
  anim_type = "support",
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self, false, true)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(room:getOtherPlayers(player), Util.IdMapper)
    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#zhuide-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local names = {}
    for _, id in ipairs(room.draw_pile) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeBasic and not table.find(names, function(name) return Fk:cloneCard(name).trueName == card.trueName end) then
        table.insert(names, card.name)
      end
    end
    if #names == 0 then return end
    names = table.random(names, 4)
    local dummy = Fk:cloneCard("slash")
    for _, name in ipairs(names) do
      dummy:addSubcards(room:getCardsFromPileByRule(name))
    end
    if #dummy.subcards > 0 then
      room:obtainCard(room:getPlayerById(self.cost_data), dummy, false, fk.ReasonDraw)
    end
  end,
}
minsi:addRelatedSkill(minsi_record)
minsi:addRelatedSkill(minsi_targetmod)
minsi:addRelatedSkill(minsi_maxcards)
Fk:addSkill(jijing_active)
wangrong:addSkill(minsi)
wangrong:addSkill(jijing)
wangrong:addSkill(zhuide)
Fk:loadTranslationTable{
  ["ty__wangrongh"] = "王荣",
  ["#ty__wangrongh"] = "灵怀皇后",
  ["illustrator:ty__wangrongh"] = "福州明暗",
  ["minsi"] = "敏思",
  [":minsi"] = "出牌阶段限一次，你可以弃置任意张点数之和为13的牌，并摸两倍的牌。本回合以此法获得的牌中，黑色牌无距离限制，红色牌不计入手牌上限。",
  ["jijing"] = "吉境",
  [":jijing"] = "当你受到伤害后，你可以判定，然后你可以弃置任意张点数之和等于判定结果的牌，若如此做，你回复1点体力",
  ["zhuide"] = "追德",
  [":zhuide"] = "当你死亡时，你可以令一名其他角色摸四张不同牌名的基本牌。",
  ["#minsi"] = "敏思：弃置任意张点数之和为13的牌，摸两倍的牌",
  ["@@minsi-inhand"] = "敏思",
  ["jijing_active"] = "吉境",
  ["#jijing-discard"] = "吉境：你可以弃置任意张点数之和为%arg的牌，回复1点体力",
  ["#zhuide-choose"] = "追德：你可以令一名角色摸四张不同牌名的基本牌",

  ["$minsi1"] = "能书会记，心思灵巧。",
  ["$minsi2"] = "才情兼备，选入掖庭。",
  ["$jijing1"] = "吉梦赐福，顺应天命。",
  ["$jijing2"] = "梦之指引，必为吉运。",
  ["$zhuide1"] = "思美人，两情悦。",
  ["$zhuide2"] = "花香蝶恋，君德妾慕。",
  ["~ty__wangrongh"] = "谁能护妾身幼子……",
}

--麹义

local hanfu = General(extension, "hanfu", "qun", 4)

local ty__jieying = fk.CreateTriggerSkill{
  name = "ty__jieying",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local tos = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#ty__jieying-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player.room:getPlayerById(self.cost_data), "@ty__jieying", {})
  end,
}
local ty__jieying_delay = fk.CreateTriggerSkill{
  name = "#ty__jieying_delay",
  events = {fk.AfterCardTargetDeclared, fk.Damage},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player ~= target or player.dead or player:getMark("@ty__jieying") == 0 or player.phase == Player.NotActive then return false end
    if event == fk.AfterCardTargetDeclared then
      return (data.card:isCommonTrick() or data.card.trueName == "slash") and #TargetGroup:getRealTargets(data.tos) == 1
    elseif event == fk.Damage then
      return true
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardTargetDeclared then
      local tos = room:askForChoosePlayers(player, U.getUseExtraTargets(room, data), 1, 1,
        "#ty__jieying-extra:::"..data.card:toLogString(), ty__jieying.name, true)
      if #tos == 1 then
        table.insert(data.tos, tos)
      end
    elseif event == fk.Damage then
      room:setPlayerMark(player, "@ty__jieying", {"ty__jieying_prohibit"})
    end
  end,

  refresh_events = {fk.AfterTurnEnd},
  can_refresh = function(self, event, target, player, data)
    return player == target and player:getMark("@ty__jieying") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@ty__jieying", 0)
  end,
}
local ty__jieying_targetmod = fk.CreateTargetModSkill{
  name = "#ty__jieying_targetmod",
  bypass_distances = function(self, player, skill, card)
    return card and (card:isCommonTrick() or card.trueName == "slash") and player:getMark("@ty__jieying") ~= 0 and player.phase ~= Player.NotActive
  end,
}
local ty__jieying_prohibit = fk.CreateProhibitSkill{
  name = "#ty__jieying_prohibit",
  prohibit_use = function(self, player, card)
    return type(player:getMark("@ty__jieying")) == "table" and table.contains(player:getMark("@ty__jieying"), "ty__jieying_prohibit")
  end,
}
local ty__weipo = fk.CreateTriggerSkill{
  name = "ty__weipo",
  events = {fk.TargetConfirmed},
  frequency = Skill.Compulsory,
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player == target and player:getMark("@@ty__weipo_invalidity-round") == 0 and
      data.from ~= player.id and (data.card.trueName == "slash" or data.card:isCommonTrick()) and player:getHandcardNum() < player.maxHp
  end,
  on_use = function(self, event, target, player, data)
    if player:getHandcardNum() < player.maxHp then
      player:drawCards(player.maxHp - player:getHandcardNum(), self.name)
      data.extra_data = data.extra_data or {}
      local weipo_players = data.extra_data.ty__weipo_players or {}
      table.insertIfNeed(weipo_players, player.id)
      data.extra_data.ty__weipo_players = weipo_players
    end
  end,
}
local ty__weipo_delay = fk.CreateTriggerSkill{
  name = "#ty__weipo_delay",
  events = {fk.CardUseFinished},
  frequency = Skill.Compulsory,
  anim_type = "drawcard",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.ty__weipo_players and table.contains(data.extra_data.ty__weipo_players, player.id) and
      not player.dead and player:getHandcardNum() < player.maxHp
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, ty__weipo.name, "negative")
    player:broadcastSkillInvoke(ty__weipo.name)
    if not target.dead and not player:isKongcheng() then
      local card = room:askForCard(player, 1, 1, false, ty__weipo.name, false, ".", "#ty__weipo-give:"..target.id)
      if #card > 0 then
        room:obtainCard(target.id, card[1], false, fk.ReasonGive)
      end
    end
    room:addPlayerMark(player, "@@ty__weipo_invalidity-round")
  end,
}
ty__jieying:addRelatedSkill(ty__jieying_delay)
ty__jieying:addRelatedSkill(ty__jieying_targetmod)
ty__jieying:addRelatedSkill(ty__jieying_prohibit)
ty__weipo:addRelatedSkill(ty__weipo_delay)
hanfu:addSkill(ty__jieying)
hanfu:addSkill(ty__weipo)
Fk:loadTranslationTable{
  ["hanfu"] = "韩馥",
  ["#hanfu"] = "度势恇然",
  ["illustrator:hanfu"] = "福州明暗",
  ["ty__jieying"] = "节应",
  ["#ty__jieying_delay"] = "节应",
  [":ty__jieying"] = "结束阶段，你可以选择一名其他角色，然后该角色的下回合内：其使用【杀】或普通锦囊牌无距离限制，若仅指定一个目标则可以多指定一个目标；当其造成伤害后，其不能再使用牌直到回合结束。",
  ["ty__weipo"] = "危迫",
  ["#ty__weipo_delay"] = "危迫",
  [":ty__weipo"] = "锁定技，当你成为其他角色使用【杀】或普通锦囊牌的目标后，你将手牌摸至X张，然后若你因此摸牌且此牌结算结束后你的手牌数小于X，你交给该角色一张手牌且此技能失效直到你的下回合开始。（X为你的体力上限）",

  ["@ty__jieying"] = "节应",
  ["ty__jieying_prohibit"] = "不能出牌",
  ["#ty__jieying-choose"] = "节应：选择一名其他角色，令其下个回合<br>使用牌无距离限制且可多指定1个目标，造成伤害后不能使用牌",
  ["#ty__jieying-extra"] = "节应：可为此【%arg】额外指定1个目标",
  ["#ty__weipo-give"] = "危迫：必须选择一张手牌交给%src，且本回合危迫失效",
  ["@@ty__weipo_invalidity-round"] = "危迫失效",
  ["$ty__jieying1"] = "秉志持节，应时而动。",
  ["$ty__jieying2"] = "授节于汝，随机应变！",
  ["$ty__weipo1"] = "临渊勒马，进退维谷！",
  ["$ty__weipo2"] = "前狼后虎，朝不保夕！",
  ["~hanfu"] = "袁本初，你为何不放过我！",
}

--徐州风云：陶谦 曹嵩 张邈 丘力居
local caosong = General(extension, "ty__caosong", "wei", 4)
local lilu = fk.CreateTriggerSkill{
  name = "lilu",
  anim_type = "support",
  events ={fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Draw
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#lilu-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local n = math.min(player.maxHp, 5) - player:getHandcardNum()
    if n > 0 then
      player:drawCards(n, self.name)
      if player.dead or player:isKongcheng() then return true end
    end
    local room = player.room
    local targets = room:getOtherPlayers(player, false)
    if #targets == 0 then return true end
    local x = player:getMark("@lilu")
    local tos, cards = room:askForChooseCardsAndPlayers(player, 1, 999, table.map(targets, Util.IdMapper), 1, 1, ".|.|.|hand",
    "#lilu-card:::"..tostring(x), self.name, false, true)
    local to = room:getPlayerById(tos[1])
    room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonGive, self.name, nil, false, player.id)
    if player.dead then return true end
    room:setPlayerMark(player, "@lilu", #cards)
    if #cards > x then
      room:changeMaxHp(player, 1)
      if player:isAlive() and player:isWounded() then
        room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name
        })
      end
    end
    return true
  end,
}
local yizhengc = fk.CreateTriggerSkill{
  name = "yizhengc",
  mute = true,
  events = {fk.EventPhaseStart, fk.DamageCaused, fk.PreHpRecover},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.EventPhaseStart then
        return target == player and player:hasSkill(self) and player.phase == Player.Finish
      else
        if player:getMark("@@yizhengc") ~= 0 then
          for _, id in ipairs(player:getMark("@@yizhengc")) do
            local p = player.room:getPlayerById(id)
            if not p.dead and p.maxHp > player.maxHp then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player, false), Util.IdMapper),
      1, 1, "#yizhengc-choose", self.name, true)
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
      player:broadcastSkillInvoke(self.name)
      room:notifySkillInvoked(player, self.name, "support")
      local to = room:getPlayerById(self.cost_data)
      local mark = to:getMark("@@yizhengc")
      if mark == 0 then mark = {} end
      table.insertIfNeed(mark, player.id)
      room:setPlayerMark(to, "@@yizhengc", mark)
      room:setPlayerMark(player, self.name, to.id)
    else
      for _, id in ipairs(player:getMark("@@yizhengc")) do
        local p = player.room:getPlayerById(id)
        p:broadcastSkillInvoke(self.name)
        room:notifySkillInvoked(p, self.name, "support")
        room:changeMaxHp(p, -1)
        if event == fk.DamageCaused then
          data.damage = data.damage + 1
        else
          data.num = data.num + 1
        end
      end
    end
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark(self.name) ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(player:getMark(self.name))
    room:setPlayerMark(player, self.name, 0)
    if not to.dead then
      local mark = to:getMark("@@yizhengc")
      table.removeOne(mark, player.id)
      if #mark == 0 then mark = 0 end
      room:setPlayerMark(to, "@@yizhengc", mark)
    end
  end,
}
caosong:addSkill(lilu)
caosong:addSkill(yizhengc)
Fk:loadTranslationTable{
  ["ty__caosong"] = "曹嵩",
  ["#ty__caosong"] = "依权弼子",
  ["illustrator:ty__caosong"] = "凝聚永恒",
  ["lilu"] = "礼赂",
  [":lilu"] = "摸牌阶段，你可以放弃摸牌，改为将手牌摸至体力上限（最多摸至5张），并将至少一张手牌交给一名其他角色；"..
  "若你交出的牌数大于上次以此法交出的牌数，你增加1点体力上限并回复1点体力。",
  ["yizhengc"] = "翊正",
  [":yizhengc"] = "结束阶段，你可以选择一名其他角色。直到你的下回合开始，当该角色造成伤害或回复体力时，若其体力上限小于你，"..
  "你减1点体力上限，然后此伤害或回复值+1。",
  ["#lilu-invoke"] = "礼赂：你可以放弃摸牌，改为将手牌摸至体力上限，然后将至少一张手牌交给一名其他角色",
  ["#lilu-card"] = "礼赂：将至少一张手牌交给一名其他角色，若大于%arg，你加1点体力上限并回复1点体力",
  ["lilu_active"] = "礼赂",
  ["@lilu"] = "礼赂",
  ["#yizhengc-choose"] = "翊正：你可以指定一名角色，直到你下回合开始，其造成伤害/回复体力时数值+1，你减1点体力上限",
  ["@@yizhengc"] = "翊正",

  ["$lilu1"] = "乱狱滋丰，以礼赂之。",
  ["$lilu2"] = "微薄之礼，聊表敬意！",
  ["$yizhengc1"] = "玉树盈阶，望子成龙！",
  ["$yizhengc2"] = "择善者，翊赞季兴。",
  ["~ty__caosong"] = "孟德，勿忘汝父之仇！",
}

local zhangmiao = General(extension, "zhangmiao", "qun", 4)
local mouni = fk.CreateTriggerSkill{
  name = "mouni",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), Util.IdMapper),
      1, 1, "#mouni-invoke", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local ids = table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id).trueName == "slash" end)
    if #ids == 0 then return end
    ids = table.reverse(ids)  --十周年是手牌从右往左使用
    local yes = true
    for _, id in ipairs(ids) do
      if player.dead or to.dead then return end
      if room:getCardOwner(id) == player and room:getCardArea(id) == Card.PlayerHand then
        local card = Fk:getCardById(id)
        if U.canUseCardTo(room, player, to, card, false, false) then
          local use = {
            from = player.id,
            tos = {{to.id}},
            card = card,
            extraUse = true,
          }
          use.extra_data = use.extra_data or {}
          use.extra_data.mouni_use = player.id
          room:useCard(use)
          if not use.damageDealt then
            yes = false
            player:skip(Player.Play)
            player:skip(Player.Discard)
          end
          if use.extra_data.mouni_dying then
            break
          end
        end
      end
    end
    if yes and not player.dead then
      room:setPlayerMark(player, "mouni-turn", 1)
    end
  end,

  refresh_events = {fk.EnterDying},
  can_refresh = function (self, event, target, player, data)
    if data.damage and data.damage.card then
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if e then
        local use = e.data[1]
        return use.extra_data and use.extra_data.mouni_use and use.extra_data.mouni_use == player.id
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if e then
      local use = e.data[1]
      use.extra_data = use.extra_data or {}
      use.extra_data.mouni_dying = true
    end
  end,
}
local zongfan = fk.CreateTriggerSkill{
  name = "zongfan",
  frequency = Skill.Wake,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:getMark("mouni-turn") > 0 and not player.skipped_phases[Player.Play]
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not player:isNude() then
      local success, dat = room:askForUseActiveSkill(player, "zongfan_active", "#zongfan-give", false)
      if success then
        local dummy = Fk:cloneCard("dilu")
        dummy:addSubcards(dat.cards)
        room:moveCardTo(dummy, Card.PlayerHand, room:getPlayerById(dat.targets[1]), fk.ReasonGive, self.name, nil, false, player.id)
        local n = math.min(#dat.cards, 5)
        if not player.dead then
          room:changeMaxHp(player, n)
        end
        if not player.dead and player:isWounded() then
          room:recover({
            who = player,
            num = math.min(n, player:getLostHp()),
            recoverBy = player,
            skillName = self.name
          })
        end
      end
    end
    room:handleAddLoseSkills(player, "-mouni|zhangu", nil, true, false)
  end,
}
local zongfan_active = fk.CreateActiveSkill{
  name = "zongfan_active",
  min_card_num = 1,
  target_num = 1,
  card_filter = Util.TrueFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
}
local zhangu = fk.CreateTriggerSkill{
  name = "zhangu",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.maxHp > 1 and (player:isKongcheng() or #player:getCardIds("e") == 0)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if player.dead then return end
    local dummy = Fk:cloneCard("dilu")
    local types = {"basic", "trick", "equip"}
    while #types > 0 do
      local pattern = table.random(types)
      table.removeOne(types, pattern)
      dummy:addSubcards(room:getCardsFromPileByRule(".|.|.|.|.|"..pattern))
    end
    if #dummy.subcards > 0 then
      room:obtainCard(player.id, dummy, false, fk.ReasonJustMove)
    end
  end,
}
Fk:addSkill(zongfan_active)
zhangmiao:addSkill(mouni)
zhangmiao:addSkill(zongfan)
zhangmiao:addRelatedSkill(zhangu)
Fk:loadTranslationTable{
  ["zhangmiao"] = "张邈",
  ["#zhangmiao"] = "苔岑往却",
  ["illustrator:zhangmiao"] = "猎枭",
  ["mouni"] = "谋逆",
  [":mouni"] = "准备阶段，你可对一名其他角色依次使用你手牌中所有的【杀】直到该角色进入濒死状态。若以此法使用的【杀】中有未造成伤害的【杀】，"..
  "你本回合跳过出牌阶段和弃牌阶段。",
  ["zongfan"] = "纵反",
  [":zongfan"] = "觉醒技，回合结束时，若你本回合发动〖谋逆〗使用过【杀】且未跳过出牌阶段，你交给一名其他角色任意张牌，加X点体力上限并回复X点体力"..
  "（X为你交给该角色的牌数且最多为5），失去〖谋逆〗，获得〖战孤〗",
  ["zhangu"] = "战孤",
  [":zhangu"] = "锁定技，回合开始时，若你体力上限大于1且没有手牌或装备区没有牌，你减1点体力上限，然后从牌堆中随机获得三张不同类别的牌。",
  ["#mouni-invoke"] = "谋逆：你可以对一名角色使用你手牌中所有【杀】！",
  ["zongfan_active"] = "纵反",
  ["#zongfan-give"] = "纵反：交给一名其他角色任意张牌，你加等量体力上限并回复等量体力",

  ["$mouni1"] = "反制于人，不以鄙乎！",
  ["$mouni2"] = "与诸君终为敌，吾欲先手。",
  ["$zongfan1"] = "今天下未定，有能者皆可谋之！",
  ["$zongfan2"] = "吾以千里之众，当四战之地，可反也！",
  ["$zhangu1"] = "孤军奋战，独破众将。",
  ["$zhangu2"] = "雄狮搏兔，何须援乎？",
  ["~zhangmiao"] = "独木终难支矣。",
}

local qiuliju = General(extension, "qiuliju", "qun", 4, 6)
local koulue = fk.CreateTriggerSkill{
  name = "koulue",
  anim_type = "drawcard",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and data.to ~= player and
      not data.to.dead and not data.to:isKongcheng() and data.to:isWounded()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#koulue-invoke::"..data.to.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {data.to.id})
    local cards = room:askForCardsChosen(player, data.to, 1, data.to:getLostHp(), "h", self.name)
    data.to:showCards(cards)
    if player.dead then return end
    local get = table.filter(cards, function(id)
      return Fk:getCardById(id).is_damage_card and room:getCardOwner(id) == data.to and room:getCardArea(id) == Card.PlayerHand end)
    if #get > 0 then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(get)
      room:moveCardTo(dummy, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, true, player.id)
    end
    if not player.dead and table.find(cards, function(id) return Fk:getCardById(id).color == Card.Red end) then
      if player:isWounded() then
        room:changeMaxHp(player, -1)
      else
        room:loseHp(player, 1, self.name)
      end
      if not player.dead then
        player:drawCards(2, self.name)
      end
    end
  end,
}
local suirenq = fk.CreateTriggerSkill{
  name = "suirenq",
  anim_type = "support",
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self, false, true) and
      table.find(player:getCardIds("h"), function(id) return Fk:getCardById(id).is_damage_card end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(room.alive_players, Util.IdMapper)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#suirenq-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id).is_damage_card end))
    room:moveCardTo(dummy, Card.PlayerHand, to, fk.ReasonGive, self.name, nil, false, player.id)
  end,
}
qiuliju:addSkill(koulue)
qiuliju:addSkill(suirenq)
Fk:loadTranslationTable{
  ["qiuliju"] = "丘力居",
  ["#qiuliju"] = "乌丸王",
  ["illustrator:qiuliju"] = "盲特",
  ["koulue"] = "寇略",
  [":koulue"] = "出牌阶段内，当你对其他角色造成伤害后，你可以展示其X张手牌（X为其已损失体力值），你获得其中的【杀】和伤害锦囊牌。若展示牌中有红色牌，"..
  "若你已受伤，你减1点体力上限；若你未受伤，则失去1点体力；然后你摸两张牌。",
  ["suirenq"] = "随认",
  [":suirenq"] = "你死亡时，可以将手牌中所有【杀】和伤害锦囊牌交给一名其他角色。",
  ["#koulue-invoke"]= "寇略：你可以展示 %dest 的手牌，获得其中的伤害牌",
  ["#suirenq-choose"] = "随认：你可以将手牌中所有【杀】和伤害锦囊牌交给一名角色",

  ["$koulue1"] = "兵强马壮，时出寇略。",
  ["$koulue2"] = "饥则寇略，饱则弃馀。",
  ["$suirenq1"] = "就交给你了。",
  ["$suirenq2"] = "我的财富，收好！",
  ["~qiuliju"] = "乌丸危矣！",
}

--中原狼烟：董承 胡车儿 邹氏 曹安民
local dongcheng = General(extension, "ty__dongcheng", "qun", 4)
local xuezhao = fk.CreateActiveSkill{
  name = "xuezhao",
  anim_type = "offensive",
  card_num = 1,
  min_target_num = 1,
  max_target_num = function()
    return Self.maxHp
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected, targets)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected, cards)
    return #selected < Self.maxHp and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    for _, to in ipairs(effect.tos) do
      local p = room:getPlayerById(to)
      if p:isNude() then
        room:addPlayerMark(p, "xuezhao-phase", 1)
      else
        local card = room:askForCard(p, 1, 1, true, self.name, true, ".", "#xuezhao-give:"..player.id)
        if #card > 0 then
          room:obtainCard(player, Fk:getCardById(card[1]), false, fk.ReasonGive)
          p:drawCards(1, self.name)
          room:addPlayerMark(player, "xuezhao_add-turn", 1)
        else
          room:addPlayerMark(p, "xuezhao-phase", 1)
        end
      end
    end
  end,
}
local xuezhao_targetmod = fk.CreateTargetModSkill{
  name = "#xuezhao_targetmod",
  residue_func = function(self, player, skill, scope)
    if player:getMark("xuezhao_add-turn") > 0 and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return player:getMark("xuezhao_add-turn")
    end
  end,
}
local xuezhao_record = fk.CreateTriggerSkill{
  name = "#xuezhao_record",

  refresh_events = {fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes("xuezhao", Player.HistoryPhase) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player), function(p) return p:getMark("xuezhao-phase") > 0 end)
    data.disresponsiveList = data.disresponsiveList or {}
    for _, p in ipairs(targets) do
      table.insertIfNeed(data.disresponsiveList, p.id)
    end
  end,
}
xuezhao:addRelatedSkill(xuezhao_targetmod)
xuezhao:addRelatedSkill(xuezhao_record)
dongcheng:addSkill(xuezhao)
Fk:loadTranslationTable{
  ["ty__dongcheng"] = "董承",
  ["#ty__dongcheng"] = "扬义誓诛",
  ["illustrator:ty__dongcheng"] = "游漫美绘",
  ["xuezhao"] = "血诏",
  [":xuezhao"] = "出牌阶段限一次，你可以弃置一张手牌并选择至多X名其他角色（X为你的体力上限），然后令这些角色依次选择是否交给你一张牌，"..
  "若选择是，该角色摸一张牌且你本阶段使用【杀】的次数上限+1；若选择否，该角色本阶段不能响应你使用的牌。",
  ["#xuezhao-give"] = "血诏：交出一张牌并摸一张牌使 %src 使用【杀】次数上限+1；或本阶段不能响应其使用的牌",

  ["$xuezhao1"] = "奉旨行事，莫敢不从？",
  ["$xuezhao2"] = "衣带密诏，当诛曹公！",
  ["~ty__dongcheng"] = "是谁走漏了风声？",
}

local hucheer = General(extension, "ty__hucheer", "qun", 4)
local ty__daoji = fk.CreateTriggerSkill{
  name = "ty__daoji",
  anim_type = "control",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self) and data.extra_data and data.extra_data.ty__daoji_triggerable
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {"ty__daoji_prohibit", "Cancel"}
    if room:getCardArea(data.card:getEffectiveId()) == Card.Processing then
      table.insert(choices, 1, "ty__daoji_prey")
    end
    self.cost_data = room:askForChoice(player, choices, self.name, "#ty__daoji-choice::" .. target.id .. ":" .. data.card:toLogString())
    return self.cost_data ~= "Cancel"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data == "ty__daoji_prey" then
      if room:getCardArea(data.card:getEffectiveId()) == Card.Processing then
        room:obtainCard(player.id, data.card, true)
      end
    elseif self.cost_data == "ty__daoji_prohibit" then
      room:addPlayerMark(target, "@@ty__daoji_prohibit-turn")
    end
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("ty__daoji_used_weapon") == 0 and data.card.sub_type == Card.SubtypeWeapon
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "ty__daoji_used_weapon", 1)
    data.extra_data = data.extra_data or {}
    data.extra_data.ty__daoji_triggerable = true
  end,
}
local ty__daoji_prohibit = fk.CreateProhibitSkill{
  name = "#ty__daoji_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("@@ty__daoji_prohibit-turn") > 0 and card.trueName == "slash"
  end,
  prohibit_response = function(self, player, card)
    return player:getMark("@@ty__daoji_prohibit-turn") > 0 and card.trueName == "slash"
  end,
}
local fuzhong = fk.CreateTriggerSkill{
  name = "fuzhong",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove, fk.DrawNCards, fk.EventPhaseStart},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.AfterCardsMove and player.phase == Player.NotActive then
        for _, move in ipairs(data) do
          if move.to == player.id and move.toArea == Card.PlayerHand then
            return true
          end
        end
      elseif event == fk.DrawNCards then
        return player == target and player:getMark("@fuzhong_weight") > 0
      elseif event == fk.EventPhaseStart then
        return player == target and player.phase == Player.Finish and player:getMark("@fuzhong_weight") > 3
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      room:notifySkillInvoked(player, self.name)
      player:broadcastSkillInvoke(self.name)
      room:addPlayerMark(player, "@fuzhong_weight")
    elseif event == fk.DrawNCards then
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:broadcastSkillInvoke(self.name)
      data.n = data.n + 1
    elseif event == fk.EventPhaseStart then
      room:notifySkillInvoked(player, self.name, "offensive")
      player:broadcastSkillInvoke(self.name)
      local targets = room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#fuzhong-choose", self.name, false)
      if #targets > 0 then
        room:damage{
          from = player,
          to = room:getPlayerById(targets[1]),
          damage = 1,
          skillName = self.name,
        }
        room:removePlayerMark(player, "@fuzhong_weight", 4)
      end
    end
  end,
}
local fuzhong_distance = fk.CreateDistanceSkill{
  name = "#fuzhong_distance",
  frequency = Skill.Compulsory,
  correct_func = function(self, from, to)
    if from:hasSkill(fuzhong.name) and from:getMark("@fuzhong_weight") > 1 then
      return -2
    end
  end,
}
local fuzhong_maxcards = fk.CreateMaxCardsSkill{
  name = "#fuzhong_maxcards",
  correct_func = function(self, player)
    if player:hasSkill(fuzhong.name) and player:getMark("@fuzhong_weight") > 2 then
      return 3
    end
  end,
}
ty__daoji:addRelatedSkill(ty__daoji_prohibit)
hucheer:addSkill(ty__daoji)
hucheer:addSkill(fuzhong)
fuzhong:addRelatedSkill(fuzhong_distance)
fuzhong:addRelatedSkill(fuzhong_maxcards)
Fk:loadTranslationTable{
  ["ty__hucheer"] = "胡车儿",
  ["#ty__hucheer"] = "惩奸除恶",
  ["illustrator:ty__hucheer"] = "游漫美绘",
  ["ty__daoji"] = "盗戟",
  [":ty__daoji"] = "当其他角色本局游戏第一次使用武器牌时，你可以选择一项：1.获得此武器牌；2.其本回合不能使用或打出【杀】。",
  ["fuzhong"] = "负重",
  [":fuzhong"] = "锁定技，当你于回合外得到牌时，你获得一枚“重”标记。当你的“重”标记数：大于等于1，摸牌阶段，你多摸一张牌；"..
  "大于等于2，你计算与其他角色的距离-2；大于等于3，你的手牌上限+3；大于等于4，结束阶段，你对一名其他角色造成1点伤害，然后移去4个“重”。",

  ["#ty__daoji-choice"] = "盗戟：可选择获得%dest使用的%arg或令其本回合不能出杀",
  ["ty__daoji_prey"] = "获得其使用的武器牌",
  ["ty__daoji_prohibit"] = "令其本回合不能出杀",
  ["@@ty__daoji_prohibit-turn"] = "盗戟 不能出杀",
  ["@fuzhong_weight"] = "重",
  ["#fuzhong-choose"] = "负重：必须选择一名其他角色，对其造成1点伤害，然后移去4个重标记",

  ["$ty__daoji1"] = "典韦勇猛，盗戟可除。",
  ["$ty__daoji2"] = "你的，就是我的。",
  ["$fuzhong1"] = "身负重任，绝无懈怠。",
  ["$fuzhong2"] = "勇冠其军，负重前行。",
  ["~ty__hucheer"] = "好快的涯角枪！",
}

local zoushi = General(extension, "ty__zoushi", "qun", 3, 3, General.Female)
local ty__huoshui_active = fk.CreateActiveSkill{
  name = "ty__huoshui_active",
  mute = true,
  card_num = 0,
  min_target_num = 1,
  max_target_num = function()
    local n = math.max(Self:getLostHp(), 1)
    return math.min(n, 3)
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, cards)
    if to_select ~= Self.id then
      local target = Fk:currentRoom():getPlayerById(to_select)
      if #selected == 0 then
        return true
      elseif #selected == 1 then
        return not target:isKongcheng()
      elseif #selected == 2 then
        return #target.player_cards[Player.Equip] > 0
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    for i = 1, #effect.tos, 1 do
      local target = room:getPlayerById(effect.tos[i])
      if i == 1 then
        room:setPlayerMark(target, MarkEnum.UncompulsoryInvalidity.."-turn", 1)
      elseif i == 2 then
        local card = room:askForCard(target, 1, 1, false, "ty__huoshui", false, ".", "#ty__huoshui-give:"..player.id)
        room:obtainCard(player.id, card[1], false, fk.ReasonGive)
      elseif i == 3 then
        target:throwAllCards("e")
      end
    end
  end,
}
local ty__huoshui = fk.CreateTriggerSkill{
  name = "ty__huoshui",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local n = math.max(player:getLostHp(), 1)
    n = math.min(n, 3)
    return player.room:askForUseActiveSkill(player, "ty__huoshui_active", "#ty__huoshui-choose:::"..tostring(n), true, {}, false)
  end,
}
local ty__qingcheng = fk.CreateActiveSkill{
  name = "ty__qingcheng",
  anim_type = "control",
  target_num = 1,
  card_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and to_select ~= Self.id and target.gender == General.Male and Self:getHandcardNum() >= target:getHandcardNum()
  end,
  on_use = function(self, room, effect)
    local cards1 = table.clone(room:getPlayerById(effect.from).player_cards[Player.Hand])
    local cards2 = table.clone(room:getPlayerById(effect.tos[1]).player_cards[Player.Hand])
    local move1 = {
      from = effect.from,
      ids = cards1,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      proposer = effect.from,
      skillName = self.name,
    }
    local move2 = {
      from = effect.tos[1],
      ids = cards2,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      proposer = effect.from,
      skillName = self.name,
    }
    room:moveCards(move1, move2)
    local move3 = {
      ids = table.filter(cards1, function(id) return room:getCardArea(id) == Card.Processing end),
      fromArea = Card.Processing,
      to = effect.tos[1],
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonJustMove,
      proposer = effect.from,
      skillName = self.name,
    }
    local move4 = {
      ids = table.filter(cards2, function(id) return room:getCardArea(id) == Card.Processing end),
      fromArea = Card.Processing,
      to = effect.from,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonJustMove,
      proposer = effect.from,
      skillName = self.name,
    }
    room:moveCards(move3, move4)
  end,
}
Fk:addSkill(ty__huoshui_active)
zoushi:addSkill(ty__huoshui)
zoushi:addSkill(ty__qingcheng)
Fk:loadTranslationTable{
  ["ty__zoushi"] = "邹氏",
  ["#ty__zoushi"] = "惑心之魅",
  ["illustrator:ty__zoushi"] = "猎枭",
  ["ty__huoshui"] = "祸水",
  [":ty__huoshui"] = "准备阶段，你可以令至多X名其他角色（X为你已损失体力值，至少为1，至多为3）按你选择的顺序依次执行一项：1.本回合所有非锁定技失效；"..
  "2.交给你一张手牌；3.弃置装备区里的所有牌。",
  ["ty__qingcheng"] = "倾城",
  [":ty__qingcheng"] = "出牌阶段限一次，你可以与一名手牌数不大于你的男性角色交换手牌。",
  ["#ty__huoshui-choose"] = "祸水：选择至多%arg名角色，按照选择的顺序：<br>1.本回合非锁定技失效，2.交给你一张手牌，3.弃置装备区里的所有牌",
  ["ty__huoshui_active"] = "祸水",
  ["#ty__huoshui-give"] = "祸水：你须交给%src一张手牌",

  ["$ty__huoshui1"] = "呵呵，走不动了嘛。",
  ["$ty__huoshui2"] = "别走了，再玩一会儿嘛。",
  ["$ty__qingcheng1"] = "我和你们真是投缘呐。",
  ["$ty__qingcheng2"] = "哼，眼睛都直了呀。",
  ["~ty__zoushi"] = "年老色衰了吗……",
}

local caoanmin = General(extension, "caoanmin", "wei", 4)
local xianwei = fk.CreateTriggerSkill{
  name = "xianwei",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart, fk.AreaAborted},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.EventPhaseStart then
        return player.phase == Player.Start and #player:getAvailableEquipSlots() > 0
      else
        return #player:getAvailableEquipSlots() == 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local choices = player:getAvailableEquipSlots()
      local choice = room:askForChoice(player, choices, self.name, "#xianwei-abort")
      room:abortPlayerArea(player, choice)
      if player.dead then return end
      if #player:getAvailableEquipSlots() > 0 then
        player:drawCards(#player:getAvailableEquipSlots(), self.name)
      end
      if player.dead then return end
      local targets = table.map(room:getOtherPlayers(player), Util.IdMapper)
      local mapper = {
        [Player.WeaponSlot] = "weapon",
        [Player.ArmorSlot] = "armor",
        [Player.OffensiveRideSlot] = "offensive_horse",
        [Player.DefensiveRideSlot] = "defensive_horse",
        [Player.TreasureSlot] = "treasure",
      }
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#xianwei-choose:::"..mapper[choice], self.name, false)
      if #to > 0 then
        to = to[1]
      else
        to = table.random(targets)
      end
      to = room:getPlayerById(to)
      local subtype = Util.convertSubtypeAndEquipSlot(choice)
      for _, id in ipairs(room.draw_pile) do
        local card = Fk:getCardById(id)
        if card.sub_type == subtype and not to:isProhibited(to, card) then
          room:useCard({
            from = to.id,
            tos = {{to.id}},
            card = card,
          })
          return
        end
      end
      to:drawCards(1, self.name)
    else
      room:setPlayerMark(player, "@@xianwei", 1)
      room:changeMaxHp(player, 2)
    end
  end,
}
local xianwei_attackrange = fk.CreateAttackRangeSkill{
  name = "#xianwei_attackrange",
  frequency = Skill.Compulsory,
  within_func = function (self, from, to)
    return from:getMark("@@xianwei") > 0 or to:getMark("@@xianwei") > 0
  end,
}
xianwei:addRelatedSkill(xianwei_attackrange)
caoanmin:addSkill(xianwei)
Fk:loadTranslationTable{
  ["caoanmin"] = "曹安民",
  ["#caoanmin"] = "履薄临深",
  ["illustrator:caoanmin"] = "君桓文化",
  ["xianwei"] = "险卫",
  [":xianwei"] = "锁定技，准备阶段，你废除一个装备栏并摸等同于你未废除装备栏数的牌，然后令一名其他角色使用牌堆中第一张此副类别的装备牌"..
  "（没有则其摸一张牌）。<br>你的所有装备栏均废除后，你加2点体力上限，然后你和其他角色始终互相视为在对方攻击范围内。",
  ["#xianwei-abort"] = "险卫：废除一个装备栏",
  ["#xianwei-choose"] = "险卫：令一名角色使用牌堆中一张%arg",
  ["@@xianwei"] = "险卫",

  ["$xianwei1"] = "曹家儿郎，何惧一死！",
  ["$xianwei2"] = "此役当战，有死无生！",
  ["~caoanmin"] = "伯父快走！",
}

--虓虎悲歌：郝萌 严夫人 朱灵 阎柔
local haomeng = General(extension, "ty__haomeng", "qun", 7)
local xiongmang = fk.CreateViewAsSkill{
  name = "xiongmang",
  anim_type = "offensive",
  pattern = "slash",
  card_filter = function(self, to_select, selected)
    if Fk:currentRoom():getCardArea(to_select) == Player.Equip then return end
    if #selected == 0 then
      return true
    else
      return table.every(selected, function (id) return Fk:getCardById(to_select).suit ~= Fk:getCardById(id).suit end)
    end
  end,
  view_as = function(self, cards)
    if #cards == 0 then return end
    local card = Fk:cloneCard("slash")
    card.skillName = self.name
    card:addSubcards(cards)
    return card
  end,
  enabled_at_response = function(self, player, response)
    return not response
  end,
}
local xiongmang_targetmod = fk.CreateTargetModSkill{
  name = "#xiongmang_targetmod",
  extra_target_func = function(self, player, skill, card)
    if player:hasSkill("xiongmang") and skill.trueName == "slash_skill" and table.contains(card.skillNames, "xiongmang") then
      return #card.subcards - 1
    end
  end,
}
local xiongmang_trigger = fk.CreateTriggerSkill{
  name = "#xiongmang_trigger",
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, "xiongmang") and not data.damageDealt and not player.dead
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:changeMaxHp(player, -1)
  end,
}
xiongmang:addRelatedSkill(xiongmang_trigger)
xiongmang:addRelatedSkill(xiongmang_targetmod)
haomeng:addSkill(xiongmang)
Fk:loadTranslationTable{
  ["ty__haomeng"] = "郝萌",
  ["#ty__haomeng"] = "悖虎之伥",
  ["illustrator:ty__haomeng"] = "猎枭", -- 夜袭虓虎
  ["xiongmang"] = "雄莽",
  [":xiongmang"] = "你可以将任意张花色不同的手牌当【杀】使用，此【杀】目标数上限等于用于转化的牌数；此【杀】结算后，若没有造成伤害，你减1点体力上限。",

  ["$xiongmang1"] = "力逮千军，唯武为雄！",
  ["$xiongmang2"] = "莽行沙场，乱世称雄！",
  ["~ty__haomeng"] = "曹性，汝欲反我不成？",
}

local yanfuren = General(extension, "yanfuren", "qun", 3, 3, General.Female)
local channi_viewas = fk.CreateViewAsSkill{
  name = "channi_viewas",
  anim_type = "offensive",
  pattern = "duel",
  card_filter = function(self, to_select, selected)
    return Fk:currentRoom():getCardArea(to_select) ~= Player.Equip and #selected < Self:getMark("channi")
  end,
  view_as = function(self, cards)
    if #cards == 0 then return end
    local card = Fk:cloneCard("duel")
    card:addSubcards(cards)
    card.skillName = "channi"
    return card
  end,
}
local channi = fk.CreateActiveSkill{
  name = "channi",
  anim_type = "support",
  prompt = "#channi-active",
  min_card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerEquip
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local n = #effect.cards
    room:moveCardTo(effect.cards, Player.Hand, target, fk.ReasonGive, self.name, nil, false, player.id)
    room:setPlayerMark(target, self.name, n)
    local success, data = room:askForUseActiveSkill(target, "channi_viewas", "#channi-invoke:"..player.id.."::"..n, true, {}, false)
    room:setPlayerMark(target, self.name, 0)
    if success then
      local card = Fk:cloneCard("duel")
      card.skillName = self.name
      card:addSubcards(data.cards)
      local use = {
        from = target.id,
        tos = table.map(data.targets, function(id) return {id} end),
        card = card,
        extra_data = {channi_data = {player.id, target.id, #data.cards}}
      }
      room:useCard(use)
    end
  end,
}
local channi_delay = fk.CreateTriggerSkill{
  name = "#channi_delay",
  events = {fk.Damage, fk.Damaged},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player.dead and target and not target.dead and data.card and not data.chain and
    table.contains(data.card.skillNames, channi.name) then
      local room = player.room
      local card_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if not card_event then return false end
      local use = card_event.data[1]
      if use.extra_data then
        local channi_data = use.extra_data.channi_data
        if channi_data and channi_data[1] == player.id and channi_data[2] == target.id then
          self.cost_data = channi_data[3]
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damage then
      room:notifySkillInvoked(player, channi.name, "drawcard")
      room:doIndicate(player.id, {target.id})
      room:drawCards(target, self.cost_data, channi.name)
    else
      room:notifySkillInvoked(player, channi.name, "negative")
      local n = player:getHandcardNum()
      room:askForDiscard(player, n, n, false, channi.name, false)
    end
  end
}

local nifu = fk.CreateTriggerSkill{
  name = "nifu",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.phase == Player.Finish and player:getHandcardNum() ~= 3
  end,
  on_use = function(self, event, target, player, data)
    local n = player:getHandcardNum() - 3
    if n < 0 then
      player:drawCards(-n, self.name)
    else
      player.room:askForDiscard(player, n, n, false, self.name, false)
    end
  end,
}
Fk:addSkill(channi_viewas)
channi:addRelatedSkill(channi_delay)
yanfuren:addSkill(channi)
yanfuren:addSkill(nifu)
Fk:loadTranslationTable{
  ["yanfuren"] = "严夫人",
  ["#yanfuren"] = "霜天薄裳",
  ["illustrator:yanfuren"] = "君桓文化",
  ["channi"] = "谗逆",
  [":channi"] = "出牌阶段限一次，你可以交给一名其他角色任意张手牌，然后该角色可以将X张手牌当一张【决斗】使用（X至多为你以此法交给其的牌数）。"..
  "其因此使用【决斗】造成伤害后，其摸X张牌；其因此使用【决斗】受到伤害后，你弃置所有手牌。",
  ["nifu"] = "匿伏",
  [":nifu"] = "锁定技，一名角色的结束阶段，你将手牌摸至或弃置至三张。",
  ["channi_viewas"] = "谗逆",
  ["#channi_delay"] = "谗逆",
  ["#channi-active"] = "发动 谗逆，将任意数量的手牌交给一名角色",
  ["#channi-invoke"] = "谗逆：你可以将至多%arg张手牌当一张【决斗】使用<br>若对目标造成伤害你摸等量牌，若你受到伤害则 %src 弃置所有手牌",

  ["$channi1"] = "此人心怀叵测，将军当拔剑诛之！",
  ["$channi2"] = "请夫君听妾身之言，勿为小人所误！",
  ["$nifu1"] = "当为贤妻宜室，莫做妒妇祸家。",
  ["$nifu2"] = "将军且往沙场驰骋，妾身自有苟全之法。",
  ["~yanfuren"] = "妾身绝不会害将军呀！",
}

local zhuling = General(extension, "ty__zhuling", "wei", 4)
local ty__zhanyi = fk.CreateTriggerSkill{
  name = "ty__zhanyi",
  anim_type = "special",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local all_choices = {"basic", "trick", "equip", "Cancel"}
    local choices = {"Cancel"}
    for _, id in ipairs(player:getCardIds("he")) do
      local card = Fk:getCardById(id)
      --if not player:prohibitDiscard(card) then
      table.insertIfNeed(choices, card:getTypeString())
      --end
    end
    if #choices == 1 then return end
    local choice = player.room:askForChoice(player, choices, self.name, "#ty__zhanyi-choice", false, all_choices)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local types = {"basic", "trick", "equip"}
    local card_type = self.cost_data
    local mark = U.getMark(player, "@[cardtypes]ty__zhanyi")
    if card_type == "basic" then
      table.insertTableIfNeed(mark, {2, 3})
    elseif card_type == "trick" then
      table.insertTableIfNeed(mark, {1, 3})
    elseif card_type == "equip" then
      table.insertTableIfNeed(mark, {1, 2})
    end
    room:setPlayerMark(player, "@[cardtypes]ty__zhanyi", mark)
    local cards = table.filter(player:getCardIds("he"), function(id)
      local card = Fk:getCardById(id)
      return card:getTypeString() == card_type and not player:prohibitDiscard(card)
    end)
    if #cards > 0 then
      room:throwCard(cards, self.name, player, player)
    end
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@[cardtypes]ty__zhanyi") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@[cardtypes]ty__zhanyi", 0)
  end,
}
local ty__zhanyi_trigger = fk.CreateTriggerSkill{
  name = "#ty__zhanyi_trigger",
  mute = true,
  events = {fk.CardUsing, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if event == fk.CardUsing then
      return target == player and not player.dead and
      data.card.type < 3 and table.contains(U.getMark(player, "@[cardtypes]ty__zhanyi"), data.card.type)
    elseif table.contains(U.getMark(player, "@[cardtypes]ty__zhanyi"), 3) then
      for _, move in ipairs(data) do
        if move.to and move.to == player.id and move.toArea == Player.Equip and #move.moveInfo > 0 then
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      if data.card.type == Card.TypeBasic then
        if data.card.is_damage_card then
          player:broadcastSkillInvoke("ty__zhanyi")
          room:notifySkillInvoked(player, "ty__zhanyi", "offensive")
          data.additionalDamage = (data.additionalDamage or 0) + 1
        elseif data.card.name == "peach" or (data.card.name == "analeptic" and data.extra_data and data.extra_data.analepticRecover) then
          player:broadcastSkillInvoke("ty__zhanyi")
          room:notifySkillInvoked(player, "ty__zhanyi", "support")
          data.additionalRecover = (data.additionalRecover or 0) + 1
        end
        if data.card.trueName == "slash" and data.extra_data and data.extra_data.drankBuff then
          data.additionalDamage = (data.additionalDamage or 0) + data.extra_data.drankBuff
        end
      elseif data.card.type == Card.TypeTrick then
        player:broadcastSkillInvoke("ty__zhanyi")
        room:notifySkillInvoked(player, "ty__zhanyi", "drawcard")
        player:drawCards(1, "ty__zhanyi")
      end
    else
      player:broadcastSkillInvoke("ty__zhanyi")
      room:notifySkillInvoked(player, "ty__zhanyi", "control")
      local targets = table.map(table.filter(room.alive_players, function(p)
        return p ~= player and not p:isNude() end), Util.IdMapper)
      if #targets == 0 then return false end
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#ty__zhanyi-discard", "ty__zhanyi", true)
      if #to > 0 then
        to = room:getPlayerById(to[1])
        local id = room:askForCardChosen(player, to, "he", "ty__zhanyi")
        room:throwCard({id}, "ty__zhanyi", to, player)
      end
    end
  end,
}
local ty__zhanyi_targetmod = fk.CreateTargetModSkill{
  name = "#ty__zhanyi_targetmod",
  bypass_distances = function(self, player, skill, card)
    return table.contains(U.getMark(player, "@[cardtypes]ty__zhanyi"), 1) and card and card.type == Card.TypeBasic
  end,
}
local ty__zhanyi_maxcards = fk.CreateMaxCardsSkill{
  name = "#ty__zhanyi_maxcards",
  exclude_from = function(self, player, card)
    return table.contains(U.getMark(player, "@[cardtypes]ty__zhanyi"), 2) and card.type == Card.TypeTrick
  end,
}
ty__zhanyi:addRelatedSkill(ty__zhanyi_trigger)
ty__zhanyi:addRelatedSkill(ty__zhanyi_targetmod)
ty__zhanyi:addRelatedSkill(ty__zhanyi_maxcards)
zhuling:addSkill(ty__zhanyi)
Fk:loadTranslationTable{
  ["ty__zhuling"] = "朱灵",
  ["#ty__zhuling"] = "良将之亚",
  ["illustrator:ty__zhuling"] = "XXX&Karneval",
  ["ty__zhanyi"] = "战意",
  [":ty__zhanyi"] = "出牌阶段开始时，你可以弃置一种类别的所有牌，另外两种类别的牌获得以下效果直到你的下个回合开始：<br>"..
  "基本牌：你使用基本牌无距离限制且造成的伤害和回复值+1；<br>"..
  "锦囊牌：你使用锦囊牌时摸一张牌，你的锦囊牌不计入手牌上限；<br>"..
  "装备牌：当装备牌置入你的装备区后，可以弃置一名其他角色的一张牌。",
  ["#ty__zhanyi-choice"] = "是否发动 战意，弃置一种类别所有的牌，另两张类别的牌获得额外效果",
  ["@[cardtypes]ty__zhanyi"] = "战意",
  ["#ty__zhanyi-discard"] = "战意：你可以弃置一名角色一张牌",

  ["$ty__zhanyi1"] = "此命不已，此战不休！",
  ["$ty__zhanyi2"] = "以役兴国，战意磅礴！",
  ["~ty__zhuling"] = "吾，错付曹公……",
}

local yanrou = General(extension, "yanrou", "wei", 4)
local choutao = fk.CreateTriggerSkill{
  name = "choutao",
  anim_type = "offensive",
  events = {fk.TargetSpecified, fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash" and data.firstTarget and
      not player.room:getPlayerById(data.from):isNude()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#choutao-invoke::"..data.from)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = room:getPlayerById(data.from)
    local id = room:askForCardChosen(player, from, "he", self.name)
    room:throwCard({id}, self.name, from, player)
    data.disresponsive = true
    if data.from == player.id then
      player:addCardUseHistory(data.card.trueName, -1)
    end
  end,
}
local xiangshu = fk.CreateTriggerSkill{
  name = "xiangshu",
  anim_type = "support",
  frequency = Skill.Limited,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and player:getMark("xiangshu-turn") > 0 and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getAlivePlayers(), function(p)
      return p:isWounded() end), Util.IdMapper)
    if #targets == 0 then return end
    local n = math.min(player:getMark("xiangshu-turn"), 5)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#xiangshu-invoke:::"..n..":"..n, self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local n = math.min(player:getMark("xiangshu-turn"), 5)
    room:recover({
      who = to,
      num = math.min(n, to:getLostHp()),
      recoverBy = player,
      skillName = self.name
    })
    to:drawCards(n, self.name)
  end,

  refresh_events = {fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self, true) and player.phase ~= Player.NotActive
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "xiangshu-turn", data.damage)
  end,
}
yanrou:addSkill(choutao)
yanrou:addSkill(xiangshu)
Fk:loadTranslationTable{
  ["yanrou"] = "阎柔",
  ["#yanrou"] = "冠玉啸北",
  ["illustrator:yanrou"] = "凝聚永恒",
  ["choutao"] = "仇讨",
  [":choutao"] = "当你使用【杀】指定目标后或成为【杀】的目标后，你可以弃置使用者一张牌，令此【杀】不能被响应；若你是使用者，则此【杀】不计入次数限制。",
  ["xiangshu"] = "襄戍",
  [":xiangshu"] = "限定技，结束阶段，若你本回合造成过伤害，你可令一名已受伤角色回复X点体力并摸X张牌（X为你本回合造成的伤害值且最多为5）。",
  ["#choutao-invoke"] = "仇讨：你可以弃置 %dest 一张牌令此【杀】不能被响应；若为你则此【杀】不计次",
  ["#xiangshu-invoke"] = "襄戍：你可令一名已受伤角色回复%arg点体力并摸%arg2张牌",

  ["$choutao1"] = "大恨深仇，此剑讨之！",
  ["$choutao2"] = "是非恩怨，此役决之！",
  ["$xiangshu1"] = "得道多襄，为公是瞻！",
  ["$xiangshu2"] = "愿为中原，永戍北疆！",
  ["~yanrou"] = "寒风折戍矛，铁衣裹枯骨……",
}

return extension
