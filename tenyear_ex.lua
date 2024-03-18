local extension = Package("tenyear_ex")
extension.extensionName = "tenyear"
local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["tenyear_ex"] = "十周年-界一将成名",
  ["ty_ex"] = "新服界",
}

local caozhi = General(extension, "ty_ex__caozhi", "wei", 3)
local ty_ex__jiushi = fk.CreateViewAsSkill{
  name = "ty_ex__jiushi",
  anim_type = "support",
  pattern = "analeptic",
  card_filter = Util.FalseFunc,
  before_use = function(self, player)
    player:turnOver()
  end,
  view_as = function(self, cards)
    if not Self.faceup then return end
    local c = Fk:cloneCard("analeptic")
    c.skillName = self.name
    return c
  end,
}
local ty_ex__jiushi_record = fk.CreateTriggerSkill{
  name = "#ty_ex__jiushi_record",
  anim_type = "support",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.ty_ex__jiushi
  end,
  on_trigger = function(self, event, target, player, data)
    data.ty_ex__jiushi = false
    self:doCost(event, target, player, data)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name)
  end,
  on_use = function(self, event, target, player, data)
    player:turnOver()
  end,

  refresh_events = {fk.DamageInflicted},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and not player.faceup
  end,
  on_refresh = function(self, event, target, player, data)
    data.ty_ex__jiushi = true
  end,
}
local ty_ex__jiushi_buff = fk.CreateTriggerSkill{
  name = "#ty_ex__jiushi_buff",
  mute = true,
  events = {fk.AfterCardUseDeclared},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill("ty_ex__jiushi") and data.card.name == "analeptic"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@ty_ex_jiushi_buff",1)
  end,

  refresh_events ={fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@ty_ex_jiushi_buff") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@ty_ex_jiushi_buff", 0)
  end,
}
local jiushi_targetmod = fk.CreateTargetModSkill{
  name = "#jiushi_targetmod",
  residue_func = function(self, player, skill, scope)
    if player:hasSkill("ty_ex__jiushi") and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return player:getMark("@ty_ex_jiushi_buff")
    end
  end,
}
ty_ex__jiushi:addRelatedSkill(ty_ex__jiushi_record)
ty_ex__jiushi:addRelatedSkill(ty_ex__jiushi_buff)
ty_ex__jiushi:addRelatedSkill(jiushi_targetmod)
caozhi:addSkill("luoying")
caozhi:addSkill(ty_ex__jiushi)
Fk:loadTranslationTable{
  ["ty_ex__caozhi"] = "界曹植",
  ["#ty_ex__caozhi"] = "八斗之才",
  ["illustrator:ty_ex__caozhi"] = "黯荧岛工作室",
  ["ty_ex__jiushi"] = "酒诗",
  [":ty_ex__jiushi"] = "①若你的武将牌正面朝上，你可以翻面视为使用一张【酒】。②当你的武将牌背面朝上，你受到伤害时，"..
  "你可在伤害结算后翻面。③当你使用【酒】时，你令你使用【杀】次数上限+1，直到你的下个回合结束。",
  ["#ty_ex__jiushi_record"] = "酒诗",
  ["@ty_ex_jiushi_buff"] = "酒诗",

  ["$luoying_ty_ex__caozhi1"] = "花落断情伤，心碎斩痴妄。",
  ["$luoying_ty_ex__caozhi2"] = "流水不言恨，落英难解愁。",
  ["$ty_ex__jiushi1"] = "花开易见落难寻。",
  ["$ty_ex__jiushi2"] = "金樽盛清酒，烟景入诗篇。",
  ["~ty_ex__caozhi"] = "一生轻松待来生……",
}

local zhangchunhua = General(extension, "ty_ex__zhangchunhua", "wei", 3, 3, General.Female)
local ty_ex__jueqing_trigger = fk.CreateTriggerSkill{
  name = "#ty_ex__jueqing_trigger",
  anim_type = "offensive",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and not data.chain
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#jueqing-invoke::"..data.to.id..":"..data.damage..":"..data.damage)
  end,
  on_use = function(self, event, target, player, data)
     player.room:loseHp(player, data.damage, self.name)
    data.damage = data.damage * 2
  end,
}
local ty_ex__jueqing = fk.CreateTriggerSkill{
  name = "ty_ex__jueqing",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.PreDamage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes("#ty_ex__jueqing_trigger", Player.HistoryGame) >0
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(data.to, data.damage, self.name)
    return true
  end,
}
local ty_ex__shangshi_discard = fk.CreateTriggerSkill{
  name = "#ty_ex__shangshi_discard",
  anim_type = "negative",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
     return target == player and player:hasSkill("ty_ex__shangshi") and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForCard(player, 1, 1, false, self.name, true, ".", "#shangshi-invoke")
    if #card > 0 then
      self.cost_data = card[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
  end,
}
local ty_ex__shangshi = fk.CreateTriggerSkill{
  name = "ty_ex__shangshi",
  anim_type = "drawcard",
  events = {fk.HpChanged, fk.MaxHpChanged, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:getHandcardNum() < player:getLostHp() then
      if event == fk.AfterCardsMove then
        for _, move in ipairs(data) do
          return move.from == player.id
        end
      else
        return target == player
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(player:getLostHp() - player:getHandcardNum(), self.name)
  end,
}
ty_ex__jueqing:addRelatedSkill(ty_ex__jueqing_trigger)
ty_ex__shangshi:addRelatedSkill(ty_ex__shangshi_discard)
zhangchunhua:addSkill(ty_ex__jueqing)
zhangchunhua:addSkill(ty_ex__shangshi)
Fk:loadTranslationTable{
  ["ty_ex__zhangchunhua"] = "界张春华",
  ["#ty_ex__zhangchunhua"] = "冷血皇后",
  ["illustrator:ty_ex__zhangchunhua"] = "磐浦",
  ["ty_ex__jueqing"] = "绝情",
  ["#ty_ex__jueqing_trigger"] = "绝情",
  [":ty_ex__jueqing"] = "①每局限一次，当你造成伤害时，你可以失去同于伤害值点体力令此伤害翻倍。②锁定技，若你已发动过绝情①，你造成的伤害均视为体力流失。",
  ["ty_ex__shangshi"] = "伤逝",
  ["#ty_ex__shangshi_discard"] = "伤逝",
  [":ty_ex__shangshi"] = "①当你受到伤害时，你可以弃置一张手牌；②每当你的手牌数小于你已损失的体力值时，可立即将手牌数补至等同于你已损失的体力值。",
  ["#shangshi-invoke"] = "伤逝:是否弃置一张手牌？",
  ["#jueqing-invoke"] = "绝情:是否令即将对%dest造成的%arg点伤害翻倍？然后你失去%arg2点体力",

  ["$ty_ex__jueqing1"] = "不知情之所起，亦不知情之所终。",
  ["$ty_ex__jueqing2"] = "唯有情字最伤人！",
  ["$ty_ex__shangshi1"] = "半生韶华随流水，思君不见撷落花。",
  ["$ty_ex__shangshi2"] = "西风知我意，送我三尺秋。",
  ["~ty_ex__zhangchunhua"] = "仲达负我！",
}

local ty_ex__yujin = General(extension, "ty_ex__yujin", "wei", 4)
local ty_ex__zhenjun = fk.CreateTriggerSkill{
  name = "ty_ex__zhenjun",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (player.phase == Player.Start or player.phase == Player.Finish)
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.filter(player.room.alive_players, function (p) return not p:isNude() end)
    if #targets == 0 then return false end
    local tos = player.room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#ty_ex__zhenjun-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local num = math.min(math.max(1, to:getHandcardNum() - to.hp), #to:getCardIds("he"))
    local cards = room:askForCardsChosen(player, to, num, num, "he", self.name, "#ty_ex__zhenjun-card::"..to.id..":"..num)
    room:throwCard(cards, self.name, to, player)
    if player.dead or to.dead or table.find(cards, function(id) return Fk:getCardById(id).type == Card.TypeEquip end) then return end
    if not player:isNude() then
      if #room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#ty_ex__zhenjun-discard::"..to.id..":"..num) > 0 then
        return
      end
    end
    to:drawCards(num, self.name)
  end,
}
ty_ex__yujin:addSkill(ty_ex__zhenjun)
Fk:loadTranslationTable{
  ["ty_ex__yujin"] = "界于禁",
  ["#ty_ex__yujin"] = "讨暴坚垒",
  ["illustrator:ty_ex__yujin"] = "Yi章",
  ["ty_ex__zhenjun"] = "镇军",
  [":ty_ex__zhenjun"] = "准备阶段或结束阶段，你可以弃置一名角色X张牌（X为其手牌数减体力值且至少为1），若其中没有装备牌，你选择一项："..
  "1.你弃置一张牌；2.该角色摸等量的牌。",
  ["#ty_ex__zhenjun-choose"] = "镇军：选择一名角色，弃置其X张牌（X为其手牌数减体力值且至少为1）",
  ["#ty_ex__zhenjun-card"] = "镇军：弃置 %dest %arg张牌，若没有装备牌，你须弃牌或令其摸牌",
  ["#ty_ex__zhenjun-discard"] = "镇军：你须弃置一张牌，否则  %dest 摸 %arg 张牌",
  ["$ty_ex__zhenjun1"] = "奉令无犯，当敌制决！",
  ["$ty_ex__zhenjun2"] = "质中性一，守执节义，自当无坚不陷。",
  ["~ty_ex__yujin"] = "呃，晚节不保！",
}

local fazheng = General(extension, "ty_ex__fazheng", "shu", 3)
local ty_ex__enyuan = fk.CreateTriggerSkill{
  name = "ty_ex__enyuan",
  mute = true,
  events = {fk.AfterCardsMove, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.AfterCardsMove then
        for _, move in ipairs(data) do
          if move.from and move.from ~= player.id and move.to == player.id and move.toArea == Card.PlayerHand and #move.moveInfo > 1 then
            return true
          end
        end
      else
        return target == player and data.from and data.from ~= player and not data.from.dead
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    if event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.from and move.from ~= player.id and move.to == player.id and move.toArea == Card.PlayerHand and #move.moveInfo > 1 then
          if not player.dead and not player.room:getPlayerById(move.from).dead then
            self:doCost(event, target, player, {move.from})
          end
        end
      end
    else
      for i = 1, data.damage do
        if data.from.dead or player.dead then break end
        self:doCost(event, target, player, data)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.AfterCardsMove then
      return player.room:askForSkillInvoke(player, self.name, nil, "#ty_ex__enyuan-invoke::"..data[1])
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event ==  fk.AfterCardsMove then
      player:broadcastSkillInvoke(self.name)
      room:notifySkillInvoked(player, self.name, "support")
      room:doIndicate(player.id, {data[1]})
      room:getPlayerById(data[1]):drawCards(1, self.name)
    else
      player:broadcastSkillInvoke(self.name)
      room:notifySkillInvoked(player, self.name, "masochism")
      room:doIndicate(player.id, {data.from.id})
      local card = room:askForCard(data.from, 1, 1, false, self.name, true, ".|.|.|hand|.|.", "#ty_ex__enyuan-give:"..player.id)
      if #card > 0 then
        local suit = Fk:getCardById(card[1]).suit
        room:obtainCard(player, card[1], false, fk.ReasonGive, data.from.id)
        if suit ~= Card.Heart then
          player:drawCards(1, self.name)
        end
      else
        room:loseHp(data.from, 1, self.name)
      end
    end
  end,
}
local ty_ex__xuanhuo = fk.CreateTriggerSkill{
  name = "ty_ex__xuanhuo",
  anim_type = "control",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Draw and player:getHandcardNum() > 1
    and #player.room.alive_players > 2
  end,
  on_cost = function(self, event, target, player, data)
    local _, dat = player.room:askForUseActiveSkill(player, "ty_ex__xuanhuo_choose", "#ty_ex__xuanhuo-invoke", true)
    if dat then
      self.cost_data = dat
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.targets[1])
    room:moveCardTo(self.cost_data.cards, Card.PlayerHand, to, fk.ReasonGive, self.name, nil, false, player.id)
    if to.dead then return end
    local victim = room:getPlayerById(self.cost_data.targets[2])
    local cards = {}
    for _, id in ipairs(U.prepareUniversalCards(room)) do
      local card = Fk:getCardById(id)
      if card.trueName == "slash" or card.trueName == "duel" then
        if to:canUseTo(card, victim, {bypass_times = true}) then
          table.insertIfNeed(cards, id)
        end
      end
    end
    local name
    if #cards > 0 then
      local cancel = to:isKongcheng() and {} or {"ty_ex__xuanhuo_give"}
      local choices,_ = U.askforChooseCardsAndChoice(to, cards, {"ty_ex__xuanhuo_use"}, self.name,
      "#ty_ex__xuanhuo-choice:"..player.id..":"..victim.id, cancel, 1, 1)
      if #choices > 0 then
        name = Fk:getCardById(choices[1]).name
      end
    end
    if name then
      room:useVirtualCard(name, nil, to, victim, self.name, true)
    else
      room:moveCardTo(to.player_cards[Player.Hand], Card.PlayerHand, player, fk.ReasonGive, self.name, nil, false, to.id)
    end
  end,
}
local ty_ex__xuanhuo_choose = fk.CreateActiveSkill{
  name = "ty_ex__xuanhuo_choose",
  card_num = 2,
  target_num = 2,
  card_filter = function(self, to_select, selected)
    return #selected < 2 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected, cards)
    if to_select == Self.id or #selected == 2 or #cards ~= 2 then return false end
    local first = Fk:currentRoom():getPlayerById(selected[1])
    local victim = Fk:currentRoom():getPlayerById(to_select)
    if #selected == 0 then
      return true
    else
      return first:canUseTo(Fk:cloneCard("slash"), victim, {bypass_times = true})
      or first:canUseTo(Fk:cloneCard("duel"), victim, {bypass_times = true})
    end
  end,
}
Fk:addSkill(ty_ex__xuanhuo_choose)
fazheng:addSkill(ty_ex__enyuan)
fazheng:addSkill(ty_ex__xuanhuo)
Fk:loadTranslationTable{
  ["ty_ex__fazheng"] = "界法正",
  ["#ty_ex__fazheng"] = "蜀汉的辅翼",
  ["illustrator:ty_ex__fazheng"] = "君桓文化",
  ["ty_ex__enyuan"] = "恩怨",
  [":ty_ex__enyuan"] = "当你获得一名其他角色至少两张牌后，你可以令其摸一张牌；当你受到1点伤害后，伤害来源需选择一项：1.交给你一张手牌，"..
  "若不为<font color='red'>♥</font>，你摸一张牌；2.其失去1点体力。",
  ["ty_ex__xuanhuo"] = "眩惑",
  [":ty_ex__xuanhuo"] = "摸牌阶段结束时，你可以交给一名其他角色两张手牌，然后该角色选择一项：1.你选择另一名是【杀】或【决斗】合法目标的其他角色，"..
  "其视为对该角色使用任意一种【杀】或【决斗】；2.交给你所有手牌。",
  ["#ty_ex__enyuan-invoke"] = "恩怨：你可以令 %dest 摸一张牌",
  ["#ty_ex__enyuan-give"] = "恩怨：你需交给 %src 一张手牌，否则失去1点体力",
  ["ty_ex__xuanhuo_choose"] = "眩惑",
  ["#ty_ex__xuanhuo-invoke"] = "眩惑：交给第一名角色两张手牌，令其选择视为对第二名角色使用杀或决斗或交给你所有手牌",
  ["ty_ex__xuanhuo_use"] = "使用",
  ["ty_ex__xuanhuo_give"] = "交出所有手牌",
  ["#ty_ex__xuanhuo-choice"] = "眩惑：选择一种牌视为对 %dest 使用，否则交给 %src 所有手牌",

  ["$ty_ex__enyuan1"] = "善因得善果，恶因得恶报！",
  ["$ty_ex__enyuan2"] = "私我者赠之琼瑶，厌我者报之斧钺！",
  ["$ty_ex__xuanhuo1"] = "光以眩目，言以惑人。",
  ["$ty_ex__xuanhuo2"] = "我法孝直如何会害你？",
  ["~ty_ex__fazheng"] = "恨未得见吾主，君临天下……",
}

local masu = General(extension, "ty_ex__masu", "shu", 3)
local ty_ex__sanyao = fk.CreateActiveSkill{
  name = "ty_ex__sanyao",
  anim_type = "offensive",
  min_card_num = 1,
  min_target_num = 1,
  prompt = "#ty_ex__sanyao",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0 and not player:isNude()
  end,
  card_filter = function (self, to_select, selected, selected_targets)
    return not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected < #selected_cards then
      local target = Fk:currentRoom():getPlayerById(to_select)
      return table.every(Fk:currentRoom().alive_players, function(p) return p.hp <= target.hp end)
    end
  end,
  feasible = function(self, selected, selected_cards)
    return #selected == #selected_cards
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    local targets = table.simpleClone(effect.tos)
    room:sortPlayersByAction(targets)
    for _, id in ipairs(targets) do
      local p = room:getPlayerById(id)
      if not p.dead then
        room:damage{
          from = player,
          to = p,
          damage = 1,
          skillName = self.name,
        }
      end
    end
  end
}
local ty_ex__zhiman = fk.CreateTriggerSkill{
  name = "ty_ex__zhiman",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.to ~= player
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#ty_ex__zhiman-invoke::"..data.to.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {data.to.id})
    if not data.to:isAllNude() then
      local card = room:askForCardChosen(player, data.to, "hej", self.name)
      room:obtainCard(player.id, card, false, fk.ReasonPrey)
    end
    return true
  end
}
masu:addSkill(ty_ex__sanyao)
masu:addSkill(ty_ex__zhiman)
Fk:loadTranslationTable{
  ["ty_ex__masu"] = "界马谡",
  ["#ty_ex__masu"] = "军略之才器",
  ["illustrator:ty_ex__masu"] = "匠人绘",
  ["ty_ex__sanyao"] = "散谣",
  [":ty_ex__sanyao"] = "出牌阶段限一次，你可以弃置任意张牌，然后对体力值最多的等量名其他角色造成1点伤害。",
  ["ty_ex__zhiman"] = "制蛮",
  [":ty_ex__zhiman"] = "当你对其他角色造成伤害时，你可以防止此伤害，然后获得其区域内一张牌。",
  ["#ty_ex__sanyao"] = "散谣：弃置任意张牌，对等量名体力值最多的其他角色各造成1点伤害",
  ["#ty_ex__zhiman-invoke"] = "制蛮：你可以防止对 %dest 造成的伤害，然后获得其区域内的一张牌",

  ["$ty_ex__sanyao1"] = "蜚短流长，以基所毁，敌军自溃。",
  ["$ty_ex__sanyao2"] = "群言谣混，积是成非！",
  ["$ty_ex__zhiman1"] = "断其粮草，不战而胜！",
  ["$ty_ex__zhiman2"] = "用兵之道，攻心为上！",
  ["~ty_ex__masu"] = "谡虽死无恨于黄壤也……",
}

local ty_ex__xushu = General(extension, "ty_ex__xushu", "shu", 4)
local ty_ex__zhuhai = fk.CreateTriggerSkill{
  name = "ty_ex__zhuhai",
  events = {fk.EventPhaseStart},
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player ~= target and target.phase == Player.Finish and not player:isKongcheng() and not target.dead then
      local events = player.room.logic:getEventsOfScope(GameEvent.Damage, 1, function(e)
        local damage = e.data[1]
        return damage.from == target
      end, Player.HistoryTurn)
      return #events > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askForUseActiveSkill(player, "ty_ex__zhuhai_active", "#ty_ex__zhuhai-use:"..target.id, true,
    {ty_ex__zhuhai_victim = target.id}, true)
    if success and dat then
      self.cost_data = dat.cards[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local subcard = self.cost_data
    local card = Fk:cloneCard(player:getMark("ty_ex__zhuhai_card"))
    card:addSubcard(subcard)
    card.skillName = self.name
    room:useCard{
      from = player.id,
      tos =  {{target.id}},
      card = card,
      extraUse = true,
    }
  end,
}
local ty_ex__zhuhai_active = fk.CreateActiveSkill{
  name = "ty_ex__zhuhai_active",
  anim_type = "offensive",
  card_num = 1,
  target_num = 0,
  interaction = function()
    return UI.ComboBox {choices = {"slash", "dismantlement"} }
  end,
  card_filter = function(self, to_select, selected)
    if #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip then
      local card = Fk:cloneCard(self.interaction.data)
      card:addSubcard(to_select)
      card.skillName = "ty_ex__zhuhai"
      local to = Fk:currentRoom():getPlayerById(self.ty_ex__zhuhai_victim)
      return not Self:prohibitUse(card) and not Self:isProhibited(to, card)
      and card.skill:modTargetFilter(to.id, {}, Self.id, card, false)
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:setPlayerMark(player, "ty_ex__zhuhai_card", self.interaction.data)
  end,
}
Fk:addSkill(ty_ex__zhuhai_active)
ty_ex__xushu:addSkill(ty_ex__zhuhai)
local ty_ex__qianxin = fk.CreateTriggerSkill{
  name = "ty_ex__qianxin",
  events = {fk.Damage},
  frequency = Skill.Wake,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player.hp < player.maxHp
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    room:handleAddLoseSkills(player, "ty_ex__jianyan")
  end,
}
ty_ex__xushu:addSkill(ty_ex__qianxin)
local ty_ex__jianyan = fk.CreateActiveSkill{
  name = "ty_ex__jianyan",
  anim_type = "support",
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 0,
  can_use = function(self, player)
    return player:getMark("ty_ex__jianyan_color-phase") == 0 or player:getMark("ty_ex__jianyan_type-phase") == 0
  end,
  interaction = function()
    local choices = (Self:getMark("ty_ex__jianyan_type-phase") == 0) and {"basic", "trick", "equip"} or {}
    if Self:getMark("ty_ex__jianyan_color-phase") == 0 then
      table.insertTable(choices, {"black", "red"})
    end
    return UI.ComboBox {choices = choices }
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local pattern = self.interaction.data
    local _pattern
    if table.contains({"black", "red"}, pattern) then
      room:setPlayerMark(player, "ty_ex__jianyan_color-phase", 1)
      if pattern == "black" then
        _pattern = ".|.|spade,club"
      else
        _pattern = ".|.|heart,diamond"
      end
    else
      room:setPlayerMark(player, "ty_ex__jianyan_type-phase", 1)
      _pattern = ".|.|.|.|.|" .. pattern
    end
    local get
    for _, id in ipairs(room.draw_pile) do
      if Fk:getCardById(id):matchPattern(_pattern) then
        get = id
        break
      end
    end
    if not get then return end
    get = Fk:getCardById(get)
    room:moveCardTo(get, Card.Processing, nil, fk.ReasonJustMove, self.name)
    room:delay(500)
    local targets = table.map(table.filter(room.alive_players, function(p) return p.gender == General.Male 
    or p.gender == General.Bigender end), Util.IdMapper)
    if #targets > 0 then
      local to = room:askForChoosePlayers(player, targets, 1, 1,
      "#ty_ex__jianyan-give:::" .. get:toLogString(), self.name, false)[1]
      room:obtainCard(to, get, true, fk.ReasonGive, player.id)
    elseif room:getCardArea(get.id) == Card.Processing then
      room:moveCardTo(get, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name, nil, true, player.id)
    end
  end,
}
ty_ex__xushu:addRelatedSkill(ty_ex__jianyan)
Fk:loadTranslationTable{
  ["ty_ex__xushu"] = "界徐庶",
  ["#ty_ex__xushu"] = "化剑为犁",
  ["illustrator:ty_ex__xushu"] = "君桓文化",
  ["ty_ex__zhuhai"] = "诛害",
  [":ty_ex__zhuhai"] = "其他角色的结束阶段，若其本回合造成过伤害，你可以将一张手牌当【杀】或【过河拆桥】对其使用（无距离限制）。",
  ["ty_ex__qianxin"] = "潜心",
  [":ty_ex__qianxin"] = "觉醒技，当你造成伤害后，若你已受伤，你减1点体力上限，并获得〖荐言〗。",
  ["ty_ex__jianyan"] = "荐言",
  [":ty_ex__jianyan"] = "出牌阶段各限一次，你可以声明一种牌的类别或一种牌的颜色，亮出牌堆中第一张符合你声明的牌，交给一名男性角色。",
  ["#ty_ex__zhuhai-use"] = "诛害：将一张手牌当【杀】或【过河拆桥】对 %src 使用",
  ["ty_ex__zhuhai_active"] = "诛害",
  ["#ty_ex__jianyan-give"] = "荐言：你可将 %arg 交给一名角色",

  ["$ty_ex__zhuhai1"] = "霜刃出鞘，诛恶方还。",
  ["$ty_ex__zhuhai2"] = "心有不平，拔剑相向。",
  ["$ty_ex__qianxin1"] = "弃剑执笔，修习韬略。",
  ["$ty_ex__qianxin2"] = "休武兴文，专研筹划。",
  ["$ty_ex__jianyan1"] = "此人之才，胜吾十倍。",
  ["$ty_ex__jianyan2"] = "先生大才，请受此礼。",
  ["~ty_ex__xushu"] = "忠孝之德，庶两者皆空。",
}

local lingtong = General(extension, "ty_ex__lingtong", "wu", 4)
local ty_ex__xuanfeng = fk.CreateTriggerSkill{
  name = "ty_ex__xuanfeng",
  anim_type = "control",
  events = {fk.AfterCardsMove, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and table.every(player.room.alive_players, function(p) return not p.dying end) then
      if event == fk.AfterCardsMove then
        for _, move in ipairs(data) do
          if move.from == player.id then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerEquip then
                return table.find(player.room.alive_players, function (p)
                  return not p:isNude() and p ~= player
                end)
              end
            end
          end
        end
      elseif event == fk.EventPhaseEnd then
        if target == player and player.phase == Player.Discard and
        table.find(player.room.alive_players, function (p)
          return not p:isNude() and p ~= player
        end) then
          local x = 0
          local logic = player.room.logic
          logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
            for _, move in ipairs(e.data) do
              if move.from == player.id and move.moveReason == fk.ReasonDiscard and move.skillName == "game_rule" then
                x = x + #move.moveInfo
                if x > 1 then return true end
              end
            end
            return false
          end, Player.HistoryTurn)
          return x > 1
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p) return not p:isNude() and p ~= player end)
    if #targets == 0 then return false end
    local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#ty_ex__xuanfeng-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local victims = {self.cost_data}
    local to = room:getPlayerById(self.cost_data)
    local card = room:askForCardChosen(player, to, "he", self.name)
    room:throwCard({card}, self.name, to, player)
    if player.dead then return false end
    local targets = table.filter(room.alive_players, function(p) return not p:isNude() and p ~= player end)
    if #targets > 0 then
      local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#ty_ex__xuanfeng-choose", self.name, true)
      if #tos > 0 then
        table.insertIfNeed(targets, tos[1])
        to = room:getPlayerById(tos[1])
        card = room:askForCardChosen(player, to, "he", self.name)
        room:throwCard({card}, self.name, to, player)
        if player.dead then return false end
      end
    end
    if room.current == player then
      local tos = room:askForChoosePlayers(player, victims, 1, 1, "#ty_ex__xuanfeng-damage", self.name, true)
      if #tos > 0 then
        room:damage{
          from = player,
          to = room:getPlayerById(tos[1]),
          damage = 1,
          skillName = self.name,
        }
      end
    end
  end,
}
local ex__yongjin = fk.CreateActiveSkill{
  name = "ex__yongjin",
  anim_type = "offensive",
  frequency = Skill.Limited,
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local excludeIds = {}
    for i = 1, 3, 1 do
      if #room:canMoveCardInBoard("e", nil, excludeIds) == 0 or player.dead then break end
      local to = room:askForChooseToMoveCardInBoard(player, "#ex__yongjin-choose", self.name, true, "e", false, excludeIds)
      if #to == 2 then
        local result = room:askForMoveCardInBoard(player, room:getPlayerById(to[1]), room:getPlayerById(to[2]), self.name, "e", nil, excludeIds)
        if result then
          table.insert(excludeIds, result.card:getEffectiveId())
        else
          break
        end
      else
        break
      end
    end
  end,
}
lingtong:addSkill(ty_ex__xuanfeng)
lingtong:addSkill(ex__yongjin)
Fk:loadTranslationTable{
  ["ty_ex__lingtong"] = "界凌统",
  ["#ty_ex__lingtong"] = "豪情烈胆",
  ["illustrator:ty_ex__lingtong"] = "聚一",
  ["ty_ex__xuanfeng"] = "旋风",
  [":ty_ex__xuanfeng"] = "当你失去装备区里的牌，或于弃牌阶段弃掉两张或更多的牌时，且没有角色处于濒死状态，你可以依次弃置一至两名其他角色的共计两张牌。若此时是你的回合内，则你可以对其中一名角色造成1点伤害。",
  ["#ty_ex__xuanfeng-choose"] = "旋风：你可以依次弃置一至两名其他角色的共计两张牌",
  ["#ty_ex__xuanfeng-damage"] = "旋风：你可以对其中一名角色造成一点伤害。",
  ["ex__yongjin"] = "勇进",
  [":ex__yongjin"] = "限定技，出牌阶段，你可以依次移动场上至多三张装备牌。",
  ["#ex__yongjin-choose"] = "勇进：你可以移动场上的一张装备牌",

  ["$ty_ex__xuanfeng1"] = "风动扬帆起，枪出敌军溃！",
  ["$ty_ex__xuanfeng2"] = "御风而动，敌军四散！",
  ["$ex__yongjin1"] = "鏖兵卫主，勇足以却敌！",
  ["$ex__yongjin2"] = "勇不可挡，进则无退！",
  ["~ty_ex__lingtong"] = "泉下弟兄，统来也！",
}

local wuguotai = General(extension, "ty_ex__wuguotai", "wu", 3, 3, General.Female)
local ty_ex__ganlu = fk.CreateActiveSkill{
  name = "ty_ex__ganlu",
  anim_type = "control",
  target_num = 2,
  card_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    if #selected == 0 then
      return true
    elseif #selected == 1 then
      local target1 = Fk:currentRoom():getPlayerById(to_select)
      local target2 = Fk:currentRoom():getPlayerById(selected[1])
      if #target1:getCardIds("e") == 0 and #target2:getCardIds("e") == 0 then
        return false
      end
      return true
    else
      return false
    end
  end,
  on_use = function(self, room, effect)
    local target1 = Fk:currentRoom():getPlayerById(effect.tos[1])
    local target2 = Fk:currentRoom():getPlayerById(effect.tos[2])
    local cards1 = table.clone(target1:getCardIds("e"))
    local cards2 = table.clone(target2:getCardIds("e"))
    local moveInfos = {}
    if #cards1 > 0 then
      table.insert(moveInfos, {
        from = effect.tos[1],
        ids = cards1,
        toArea = Card.Processing,
        moveReason = fk.ReasonExchange,
        proposer = effect.from,
        skillName = self.name,
      })
    end
    if #cards2 > 0 then
      table.insert(moveInfos, {
        from = effect.tos[2],
        ids = cards2,
        toArea = Card.Processing,
        moveReason = fk.ReasonExchange,
        proposer = effect.from,
        skillName = self.name,
      })
    end
    if #moveInfos > 0 then
      room:moveCards(table.unpack(moveInfos))
    end

    moveInfos = {}

    if not target2.dead then
      local to_ex_cards1 = table.filter(cards1, function (id)
        return room:getCardArea(id) == Card.Processing and target2:getEquipment(Fk:getCardById(id).sub_type) == nil
      end)
      if #to_ex_cards1 > 0 then
        table.insert(moveInfos, {
          ids = to_ex_cards1,
          fromArea = Card.Processing,
          to = effect.tos[2],
          toArea = Card.PlayerEquip,
          moveReason = fk.ReasonExchange,
          proposer = effect.from,
          skillName = self.name,
        })
      end
    end
    if not target1.dead then
      local to_ex_cards = table.filter(cards2, function (id)
        return room:getCardArea(id) == Card.Processing and target1:getEquipment(Fk:getCardById(id).sub_type) == nil
      end)
      if #to_ex_cards > 0 then
        table.insert(moveInfos, {
          ids = to_ex_cards,
          fromArea = Card.Processing,
          to = effect.tos[1],
          toArea = Card.PlayerEquip,
          moveReason = fk.ReasonExchange,
          proposer = effect.from,
          skillName = self.name,
        })
      end
    end
    if #moveInfos > 0 then
      room:moveCards(table.unpack(moveInfos))
    end

    table.insertTable(cards1, cards2)

    local dis_cards = table.filter(cards1, function (id)
      return room:getCardArea(id) == Card.Processing
    end)
    if #dis_cards > 0 then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(dis_cards)
      room:moveCardTo(dummy, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name)
    end
     local player =room:getPlayerById(effect.from)
    if math.abs(#target1:getCardIds("e") - #target2:getCardIds("e")) > player:getLostHp() then
      if player:getHandcardNum() > 2 then
        room:askForDiscard(player, 2, 2, false, self.name, false, ".", "#ty_ex__ganlu-discard")
      else
        player:throwAllCards("h")
      end
    end
  end,
}
local ty_ex__buyi = fk.CreateTriggerSkill{
  name = "ty_ex__buyi",
  anim_type = "support",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not target:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#ty_ex__buyi-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #target.player_cards[Player.Hand] == 1 then
      self.cost_numer = true
    end
    local id = room:askForCardChosen(player, target, "h", self.name)
    target:showCards({id})
    if Fk:getCardById(id).type ~= Card.TypeBasic then
      room:throwCard({id}, self.name, target, target)
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name
      }
      if self.cost_numer ~= nil then
        target:drawCards(1, self.name)
      end
    end
  end,
}
wuguotai:addSkill(ty_ex__ganlu)
wuguotai:addSkill(ty_ex__buyi)
Fk:loadTranslationTable{
  ["ty_ex__wuguotai"] = "界吴国太",
  ["#ty_ex__wuguotai"] = "武烈皇后",
  ["illustrator:ty_ex__wuguotai"] = "匠人绘",
  ["ty_ex__ganlu"] = "甘露",
  [":ty_ex__ganlu"] = "出牌阶段限一次，你可以选择两名角色，交换其装备区内的所有牌，然后若其装备区牌数之差大于X，你需弃置两张手牌（X为你已损失体力值）。",
  ["ty_ex__buyi"] = "补益",
  [":ty_ex__buyi"] = "当一名角色进入濒死状态时，你可以展示其一张手牌：若不为基本牌，则其弃置此牌并回复1点体力。若此牌移动前是其唯一的手牌，"..
  "其摸一张牌。",
  ["#ty_ex__buyi-invoke"] = "补益：你可以展示 %dest 一张手牌，若为非基本牌则弃置并回复1点体力，若弃置前为唯一手牌则其摸一张牌。",
  ["#ty_ex__ganlu-discard"] ="甘露: 请弃置两张手牌",

  ["$ty_ex__ganlu1"] = "纳采问名，而后交换文定。",
  ["$ty_ex__ganlu2"] = "兵戈相向，何如化戈为帛？",
  ["$ty_ex__buyi1"] = "有老身在，阁下勿忧。",
  ["$ty_ex__buyi2"] = "如此佳婿，谁敢伤之？",
  ["~ty_ex__wuguotai"] = "爱女已去，老身何存？",
}

local xusheng = General(extension, "ty_ex__xusheng", "wu", 4)
local ty_ex__pojun = fk.CreateTriggerSkill{
  name = "ty_ex__pojun",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Play and data.card.trueName == "slash" then
      local to = player.room:getPlayerById(data.to)
      return to.hp > 0 and not to:isNude()
    end
  end,
  on_cost = function (self, event, target, player, data)
    local x = player.room:getPlayerById(data.to).hp
    return player.room:askForSkillInvoke(player, self.name, nil, "#ty_ex__pojun-invoke::"..data.to..":"..x)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    local cards = room:askForCardsChosen(player, to, 1, to.hp, "he", self.name)
    to:addToPile(self.name, cards, false, self.name)
    local equipC = table.filter(cards, function (id)
      return Fk:getCardById(id).type == Card.TypeEquip
    end)
    if #equipC > 0 then
      local card = room:askForCardChosen(player, to, { card_data = { { "$Throw", equipC }  } }, self.name, "#ty_ex__pojun-throw")
      room:throwCard({card}, self.name, to, player)
    end
    if not player.dead and table.find(cards, function (id)
      return Fk:getCardById(id).type == Card.TypeTrick
    end) then
      player:drawCards(1, self.name)
    end
  end,
}
local ty_ex__pojun_delay = fk.CreateTriggerSkill{
  name = "#ty_ex__pojun_delay",
  mute = true,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return not player.dead and #player:getPile("ty_ex__pojun") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local dummy = Fk:cloneCard("zixing")
    dummy:addSubcards(player:getPile("ty_ex__pojun"))
    local room = player.room
    room:obtainCard(player.id, dummy, false)
  end,
}

ty_ex__pojun:addRelatedSkill(ty_ex__pojun_delay)
xusheng:addSkill(ty_ex__pojun)
Fk:loadTranslationTable{
  ["ty_ex__xusheng"] = "界徐盛",
  ["#ty_ex__xusheng"] = "江东的铁壁",
  ["illustrator:ty_ex__xusheng"] = "黑羽",
  ["ty_ex__pojun"] = "破军",
  [":ty_ex__pojun"] = "当你于出牌阶段内使用【杀】指定一个目标后，你可以将其至多X张牌扣置于该角色的武将牌旁（X为其体力值），若其中有："..
  "装备牌，你弃置其中一张牌；锦囊牌，你摸一张牌。若如此做，当前回合结束后，该角色获得其武将牌旁的所有牌。",
  ["#ty_ex__pojun-invoke"] = "破军：你可以扣置 %dest 至多 %arg 张牌",
  ["#ty_ex__pojun_delay"] = "破军",
  ["$Throw"] = "弃置",
  ["#ty_ex__pojun-throw"] = "破军：弃置其中一张牌",

  ["$ty_ex__pojun1"] = "奋身出命，为国建功！",
  ["$ty_ex__pojun2"] = "披甲持戟，先登陷陈！",
  ["~ty_ex__xusheng"] = "文向已无憾矣！",
}

local ty_ex__gaoshun = General(extension, "ty_ex__gaoshun", "qun", 4)
local ty_ex__xianzhen = fk.CreateActiveSkill{
  name = "ty_ex__xianzhen",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and Self:canPindian(Fk:currentRoom():getPlayerById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local pindian = player:pindian({target}, self.name)
    if pindian.results[target.id].winner == player then
      room:setPlayerMark(target, "@@ty_ex__xianzhen-turn", 1)
    else
      room:setPlayerMark(player, "ty_ex__xianzhen_lose-turn", 1)
    end
  end,
}
local ty_ex__xianzhen_trigger = fk.CreateTriggerSkill{
  name = "#ty_ex__xianzhen_trigger",
  mute = true,
  events = {fk.TargetSpecified, fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if event == fk.TargetSpecified then
      return target == player and player:usedSkillTimes("ty_ex__xianzhen", Player.HistoryTurn) > 0 and data.card and data.card.trueName == "slash" and player.room:getPlayerById(data.to):getMark("@@ty_ex__xianzhen-turn") > 0
    else
      if target == player and player:usedSkillTimes("ty_ex__xianzhen", Player.HistoryTurn) > 0 and data.card
      and data.to:getMark("@@ty_ex__xianzhen-turn") > 0 then
        local mark = U.getMark(player, "ty_ex__xianzhen_damage-turn")
        return not table.contains(mark, data.card.trueName)
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetSpecified then
      room:addPlayerMark(room:getPlayerById(data.to), fk.MarkArmorNullified)
      data.extra_data = data.extra_data or {}
      data.extra_data.ty_ex__xianzhen = data.extra_data.ty_ex__xianzhen or {}
      data.extra_data.ty_ex__xianzhen[tostring(data.to)] = (data.extra_data.ty_ex__xianzhen[tostring(data.to)] or 0) + 1
    else
      local mark = U.getMark(player, "ty_ex__xianzhen_damage-turn")
      table.insert(mark, data.card.trueName)
      room:setPlayerMark(player, "ty_ex__xianzhen_damage-turn", mark)
      data.damage = data.damage + 1
    end
  end,

  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.ty_ex__xianzhen
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for key, num in pairs(data.extra_data.ty_ex__xianzhen) do
      local p = room:getPlayerById(tonumber(key))
      if p:getMark(fk.MarkArmorNullified) > 0 then
        room:removePlayerMark(p, fk.MarkArmorNullified, num)
      end
    end
    data.extra_data.ty_ex__xianzhen = nil
  end,
}
local ty_ex__xianzhen_targetmod = fk.CreateTargetModSkill{
  name = "#ty_ex__xianzhen_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return player:usedSkillTimes("ty_ex__xianzhen", Player.HistoryTurn) > 0 and to:getMark("@@ty_ex__xianzhen-turn") > 0
  end,
  bypass_distances =  function(self, player, skill, card, to)
    return player:usedSkillTimes("ty_ex__xianzhen", Player.HistoryTurn) > 0 and to:getMark("@@ty_ex__xianzhen-turn") > 0
  end,
}
local ty_ex__xianzhen_prohibit = fk.CreateProhibitSkill{
  name = "#ty_ex__xianzhen_prohibit",
  prohibit_use = function(self, player, card)
    if player:getMark("ty_ex__xianzhen_lose-turn") > 0 then
      return card.trueName == "slash"
    end
    if table.find(Fk:currentRoom().alive_players, function (p)
      return p ~= player and p:hasSkill(ty_ex__xianzhen) and p.phase ~= Player.NotActive
    end) then
      return card.trueName == "analeptic"
    end
  end,
}
local ty_ex__xianzhen_maxcards = fk.CreateMaxCardsSkill{
  name = "#ty_ex__xianzhen_maxcards",
  exclude_from = function(self, player, card)
    return card.trueName == "slash" and player:getMark("ty_ex__xianzhen_lose-turn") > 0
  end,
}
ty_ex__xianzhen:addRelatedSkill(ty_ex__xianzhen_trigger)
ty_ex__xianzhen:addRelatedSkill(ty_ex__xianzhen_targetmod)
ty_ex__xianzhen:addRelatedSkill(ty_ex__xianzhen_prohibit)
ty_ex__xianzhen:addRelatedSkill(ty_ex__xianzhen_maxcards)
ty_ex__gaoshun:addSkill(ty_ex__xianzhen)
local ty_ex__jinjiu = fk.CreateFilterSkill{
  name = "ty_ex__jinjiu",
  card_filter = function(self, card, player, isJudgeEvent)
    return player:hasSkill(self) and card.name == "analeptic" and
    (table.contains(player.player_cards[Player.Hand], card.id) or isJudgeEvent)
  end,
  view_as = function(self, card)
    return Fk:cloneCard("slash", card.suit, 13)
  end,
}
ty_ex__gaoshun:addSkill(ty_ex__jinjiu)
Fk:loadTranslationTable{
  ["ty_ex__gaoshun"] = "界高顺",
  ["#ty_ex__gaoshun"] = "攻无不克",
  ["illustrator:ty_ex__gaoshun"] = "鄧sir",
  ["ty_ex__xianzhen"] = "陷阵",
  [":ty_ex__xianzhen"] = "每回合限一次，出牌阶段，你可以与一名角色拼点：若你赢，本回合你无视该角色的防具、对其使用牌无距离和次数限制，"..
  "且你本回合使用牌对其造成伤害时，此伤害+1（每种牌名限一次）；若你没赢，本回合你不能使用【杀】且你的【杀】不计入手牌上限。",
  ["ty_ex__jinjiu"] = "禁酒",
  [":ty_ex__jinjiu"] = "锁定技，你的【酒】视为点数为K的【杀】；你的回合内，其他角色不能使用【酒】。",
  ["@@ty_ex__xianzhen-turn"] = "陷阵",
  ["$ty_ex__xianzhen1"] = "精练整齐，每战必克！",
  ["$ty_ex__xianzhen2"] = "陷阵杀敌，好不爽快！",
  ["$ty_ex__jinjiu1"] = "好酒之徒，难堪大任，不入我营！",
  ["$ty_ex__jinjiu2"] = "饮酒误事，必当严禁！",
  ["~ty_ex__gaoshun"] = "力尽于布，与之偕死。",
}

local chengong = General(extension, "ty_ex__chengong", "qun", 3)
local ty_ex__mingce = fk.CreateActiveSkill{
  name = "ty_ex__mingce",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and (Fk:getCardById(to_select).trueName == "slash" or Fk:getCardById(to_select).type == Card.TypeEquip)
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:obtainCard(target, Fk:getCardById(effect.cards[1]), false, fk.ReasonGive, player.id)
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(target)) do
      if target:inMyAttackRange(p) then
        table.insert(targets, p.id)
      end
    end
    if #targets == 0 then
      player:drawCards(1, self.name)
      target:drawCards(1, self.name)
    else
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#ty_ex__mingce-choose::"..target.id, self.name, false)
      local to
      if #tos > 0 then
        to = tos[1]
      else
        to = table.random(targets)
      end
      room:doIndicate(target.id, {to})
      local choice = room:askForChoice(target, {"ty_ex__mingce_slash", "draw1"}, self.name)
      if choice == "ty_ex__mingce_slash" then
        local use = {
          from = target.id,
          tos = {{to}},
          card = Fk:cloneCard("slash"),
          skillName = self.name,
          extraUse = true,
        }
        room:useCard(use)
        if use.damageDealt then
          if not player.dead then
            player:drawCards(1, self.name)
          end
          if not target.dead then
            target:drawCards(1, self.name)
          end
        end
      else
        player:drawCards(1, self.name)
        target:drawCards(1, self.name)
      end
    end
  end,
}
chengong:addSkill(ty_ex__mingce)
chengong:addSkill("zhichi")
Fk:loadTranslationTable{
  ["ty_ex__chengong"] = "界陈宫",
  ["#ty_ex__chengong"] = "刚直壮烈",
  ["illustrator:ty_ex__chengong"] = "君桓文化",
  ["ty_ex__mingce"] = "明策",
  [":ty_ex__mingce"] = "出牌阶段限一次，你可以交给一名其他角色一张装备牌或【杀】，其选择一项：1.视为对其攻击范围内的另一名由你指定的角色使用【杀】，"..
  "若此【杀】造成伤害则执行选项2；2.你与其各摸一张牌。",
  ["#ty_ex__mingce-choose"] = "明策：选择 %dest 视为使用【杀】的目标",
  ["ty_ex__mingce_slash"] = "视为使用【杀】",

  ["$ty_ex__mingce1"] = "阁下若纳此谋，则大业可成也！",
  ["$ty_ex__mingce2"] = "形势如此，将军可按计行事。",
  ["$zhichi_ty_ex__chengong1"] = "不若先行退避，再做打算。",
  ["$zhichi_ty_ex__chengong2"] = "敌势汹汹，不宜与其交锋。",
  ["~ty_ex__chengong"] = "一步迟，步步迟啊！",
}
-- yj2012
local ty_ex__xunyou = General(extension, "ty_ex__xunyou", "wei", 3)
local ty_ex__zhiyu = fk.CreateTriggerSkill{
  name = "ty_ex__zhiyu",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, self.name)
    local cards = player:getCardIds("h")
    player:showCards(cards)
    local throw
    if data.from and not data.from.dead and not data.from:isKongcheng() then
      throw = room:askForDiscard(data.from, 1, 1, false, self.name, false)[1]
    end
    if not player.dead and table.every(cards, function(id) return #cards == 0 or Fk:getCardById(id).color == Fk:getCardById(cards[1]).color end) then
      if throw and room:getCardArea(throw) == Card.DiscardPile then
        room:obtainCard(player, throw, true, fk.ReasonPrey)
      end
      room:addPlayerMark(player, "ty_ex__zhiyu")
    end
  end,
  refresh_events = {fk.TurnStart, fk.AfterSkillEffect},
  can_refresh = function (self, event, target, player, data)
    if event == fk.TurnStart then
      return player == target and player:getMark("ty_ex__zhiyu") > 0
    else
      return player == target and player:getMark("ty_ex__zhiyu-turn") > 0 and data.name == "qice"
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    if event == fk.TurnStart then
      room:setPlayerMark(player, "ty_ex__zhiyu-turn", player:getMark("ty_ex__zhiyu"))
      room:setPlayerMark(player, "ty_ex__zhiyu", 0)
    else
      room:removePlayerMark(player, "ty_ex__zhiyu-turn")
      player:addSkillUseHistory("qice", -1)
    end
  end,
}
ty_ex__xunyou:addSkill("qice")
ty_ex__xunyou:addSkill(ty_ex__zhiyu)
Fk:loadTranslationTable{
  ["ty_ex__xunyou"] = "界荀攸",
  ["#ty_ex__xunyou"] = "曹魏的谋主",
  ["illustrator:ty_ex__xunyou"] = "柏桦",
  ["ty_ex__zhiyu"] = "智愚",
  [":ty_ex__zhiyu"] = "当你受到伤害后，你可以摸一张牌，然后展示所有手牌且伤害来源弃置一张手牌。若你以此法展示的牌颜色均相同，你获得其弃置的牌且下回合奇策发动次数+1。",

  ["$qice_ty_ex__xunyou1"] = "攸已有妙计在胸，此事不足为虑。",
  ["$qice_ty_ex__xunyou2"] = "主公勿虑，攸有奇策，可解此局。",
  ["$ty_ex__zhiyu1"] = "经达权变，大智若愚。",
  ["$ty_ex__zhiyu2"] = "微末伎俩，让阁下见笑了。",
  ["~ty_ex__xunyou"] = "再不能替主公出谋了。",
}

local wangyi = General(extension, "ty_ex__wangyi", "wei", 4, 4, General.Female)
wangyi:addSkill("zhenlie")
wangyi:addSkill("miji")
Fk:loadTranslationTable{
  ["ty_ex__wangyi"] = "界王异",
  ["#ty_ex__wangyi"] = "决意的巾帼",
  ["illustrator:ty_ex__wangyi"] = "夏季和杨杨",

  ["$zhenlie_ty_ex__wangyi1"] = "女子，亦可有坚贞气节！",
  ["$zhenlie_ty_ex__wangyi2"] = "品德端正，心中不移。",
  ["$miji_ty_ex__wangyi1"] = "秘计已成，定助夫君得胜。",
  ["$miji_ty_ex__wangyi2"] = "秘计在此，将军必凯旋而归。",
  ["~ty_ex__wangyi"] = "秘计不成，此城难守……",
}

local ty_ex__caozhang = General(extension, "ty_ex__caozhang", "wei", 4)
local ty_ex__jiangchi_active = fk.CreateActiveSkill{
  name = "ty_ex__jiangchi_active",
  interaction = function()
    local choices = {"ty_ex__jiangchi_prohibit-phase", "ty_ex__jiangchi_draw"}
    if not Self:isNude() then
      table.insert(choices, "ty_ex__jiangchi_targetmod-phase")
    end
    return UI.ComboBox {choices = choices}
  end,
  target_num = 0,
  card_filter = function(self, to_select, selected)
    return self.interaction.data == "ty_ex__jiangchi_targetmod-phase" and #selected == 0 and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  feasible = function(self, selected, selected_cards)
    if #selected == 0 then
      if self.interaction.data == "ty_ex__jiangchi_targetmod-phase" then
        return #selected_cards == 1
      else
        return #selected_cards == 0
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local mark = self.interaction.data
    if mark:endsWith("-phase") then
      room:setPlayerMark(player, "@@"..mark, 1)
    end
  end,
}
Fk:addSkill(ty_ex__jiangchi_active)
local ty_ex__jiangchi = fk.CreateTriggerSkill{
  name = "ty_ex__jiangchi",
  events = {fk.EventPhaseStart},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local _, ret = player.room:askForUseActiveSkill(player, "ty_ex__jiangchi_active", "#ty_ex__jiangchi-invoke", true)
    if ret then
      self.cost_data = ret.cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if player:getMark("@@ty_ex__jiangchi_targetmod-phase") > 0 then
      room:notifySkillInvoked(player, self.name, "offensive")
      room:throwCard(self.cost_data, self.name, player)
    else
      room:notifySkillInvoked(player, self.name, "drawcard")
      local num = (player:getMark("@@ty_ex__jiangchi_prohibit-phase") > 0) and 2 or 1
      player:drawCards(num, self.name)
    end
  end,
}
local ty_ex__jiangchi_targetmod = fk.CreateTargetModSkill{
  name = "#ty_ex__jiangchi_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("@@ty_ex__jiangchi_targetmod-phase") > 0
    and scope == Player.HistoryPhase then
      return 1
    end
  end,
  bypass_distances =  function(self, player, skill, card, to)
    return skill.trueName == "slash_skill" and player:getMark("@@ty_ex__jiangchi_targetmod-phase") > 0
  end,
}
local ty_ex__jiangchi_prohibit = fk.CreateProhibitSkill{
  name = "#ty_ex__jiangchi_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("@@ty_ex__jiangchi_prohibit-phase") > 0 and card.trueName == "slash"
  end,
  prohibit_response = function (self, player, card)
    return player:getMark("@@ty_ex__jiangchi_prohibit-phase") > 0 and card.trueName == "slash"
  end
}
ty_ex__jiangchi:addRelatedSkill(ty_ex__jiangchi_targetmod)
ty_ex__jiangchi:addRelatedSkill(ty_ex__jiangchi_prohibit)
ty_ex__caozhang:addSkill(ty_ex__jiangchi)
Fk:loadTranslationTable{
  ["ty_ex__caozhang"] = "界曹彰",
  ["#ty_ex__caozhang"] = "黄须儿",
  ["illustrator:ty_ex__caozhang"] = "凝聚永恒",
  ["ty_ex__jiangchi"] = "将驰",
  [":ty_ex__jiangchi"] = "出牌阶段开始时，你可以选择一项：1.摸两张牌，此阶段不能使用或打出【杀】；2.摸一张牌；3.弃置一张牌，此阶段使用【杀】无距离限制且可以多使用一张【杀】。",
  ["#ty_ex__jiangchi-invoke"] = "将驰：你可以选一项执行",
  ["ty_ex__jiangchi_active"] = "将驰",
  ["@@ty_ex__jiangchi_targetmod-phase"] = "将驰 多出杀",
  ["@@ty_ex__jiangchi_prohibit-phase"] = "将驰 不出杀",
  ["ty_ex__jiangchi_targetmod-phase"] = "弃一张牌，【杀】无距离限制且次数+1",
  ["ty_ex__jiangchi_prohibit-phase"] = "摸两张牌，不能出【杀】",
  ["ty_ex__jiangchi_draw"] = "摸一张牌",
  ["$ty_ex__jiangchi1"] = "率师而行，所向皆破！",
  ["$ty_ex__jiangchi2"] = "数从征伐，志意慷慨，不避险阻！",
  ["~ty_ex__caozhang"] = "奈何病薨！",
}

local ty_ex__madai = General(extension, "ty_ex__madai", "shu", 4)
local ty_ex__qianxi = fk.CreateTriggerSkill{
  name = "ty_ex__qianxi",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, self.name)
    if player:isNude() then return end
    local card = room:askForDiscard(player, 1, 1, true, self.name, false, ".", "#qianxi-discard")
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return player:distanceTo(p) == 1 end), Util.IdMapper)
    if #targets == 0 then return false end
    local color = Fk:getCardById(card[1]):getColorString()
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#ty_ex__qianxi-choose:::" .. color, self.name, false)
    if #to > 0 then
      room:setPlayerMark(room:getPlayerById(to[1]), "@ty_ex__qianxi-turn", color)
    end
  end,
}
local ty_ex__qianxi_delay = fk.CreateTriggerSkill{
  name = "#ty_ex__qianxi_delay",
  mute = true,
  events = {fk.TargetSpecified, fk.HpRecover},
  can_trigger = function(self, event, target, player, data)
    if event == fk.TargetSpecified then
      if target == player and player:usedSkillTimes("ty_ex__qianxi", Player.HistoryTurn) > 0 and data.card and data.card.trueName == "slash" and player.room:getPlayerById(data.to):getMark("@ty_ex__qianxi-turn") ~= 0 then
        local to = player.room:getPlayerById(data.to)
        for _, id in ipairs(to:getEquipments(Card.SubtypeArmor)) do
          if Fk:getCardById(id):getColorString() == to:getMark("@ty_ex__qianxi-turn") then
            return true
          end
        end
      end
    else
      return player:usedSkillTimes("ty_ex__qianxi", Player.HistoryTurn) > 0 and not player.dead
      and target:getMark("@ty_ex__qianxi-turn") ~= 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetSpecified then
      room:addPlayerMark(room:getPlayerById(data.to), fk.MarkArmorNullified)
      data.extra_data = data.extra_data or {}
      data.extra_data.ty_ex__qianxi = data.extra_data.ty_ex__qianxi or {}
      data.extra_data.ty_ex__qianxi[tostring(data.to)] = (data.extra_data.ty_ex__qianxi[tostring(data.to)] or 0) + 1
    else
      player:drawCards(2, "ty_ex__qianxi")
    end
  end,

  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.ty_ex__qianxi
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for key, num in pairs(data.extra_data.ty_ex__qianxi) do
      local p = room:getPlayerById(tonumber(key))
      if p:getMark(fk.MarkArmorNullified) > 0 then
        room:removePlayerMark(p, fk.MarkArmorNullified, num)
      end
    end
    data.extra_data.ty_ex__qianxi = nil
  end,
}
local ty_ex__qianxi_prohibit = fk.CreateProhibitSkill{
  name = "#ty_ex__qianxi_prohibit",
  prohibit_use = function(self, player, card)
    if player:getMark("@ty_ex__qianxi-turn") ~= 0 and card:getColorString() == player:getMark("@ty_ex__qianxi-turn") then
      local cards = card:isVirtual() and card.subcards or {card.id}
      return table.find(cards, function(id) return table.contains(player.player_cards[Player.Hand], id) end)
    end
  end,
  prohibit_response = function(self, player, card)
    if player:getMark("@ty_ex__qianxi-turn") ~= 0 and card:getColorString() == player:getMark("@ty_ex__qianxi-turn") then
      local cards = card:isVirtual() and card.subcards or {card.id}
      return table.find(cards, function(id) return table.contains(player.player_cards[Player.Hand], id) end)
    end
  end,
}
ty_ex__qianxi:addRelatedSkill(ty_ex__qianxi_prohibit)
ty_ex__qianxi:addRelatedSkill(ty_ex__qianxi_delay)
ty_ex__madai:addSkill("mashu")
ty_ex__madai:addSkill(ty_ex__qianxi)
Fk:loadTranslationTable{
  ["ty_ex__madai"] = "界马岱",
  ["#ty_ex__madai"] = "临危受命",
  ["illustrator:ty_ex__madai"] = "君桓文化",
  ["ty_ex__qianxi"] = "潜袭",
  [":ty_ex__qianxi"] = "准备阶段，你可以摸一张牌，并弃置一张牌，然后选择一名距离为1的其他角色。若如此做，本回合：1.其不能使用或打出与你以此法弃置牌颜色相同的手牌；2.你无视其装备区里与你以此法弃置牌颜色相同的防具；3.你于该角色回复体力时摸两张牌。",
  
  ["#ty_ex__qianxi-choose"] = "潜袭：令距离为1的一名角色：本回合不能使用或打出 %arg 的手牌，你无视其此颜色的防具",
  ["@ty_ex__qianxi-turn"] = "潜袭",

  ["$ty_ex__qianxi1"] = "暗影深处，袭敌斩首！",
  ["$ty_ex__qianxi2"] = "哼，出不了牌了吧？",
  ["~ty_ex__madai"] = "丞相临终使命，岱已达成。",
}

local liaohua = General(extension, "ty_ex__liaohua", "shu", 4)
local ty_ex__dangxian = fk.CreateTriggerSkill{
  name = "ty_ex__dangxian",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseChanging, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.EventPhaseChanging then
        return data.to == Player.Start
      else
        return player.phase == Player.Play and player:getMark("ty_ex__dangxian-phase") > 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseChanging then
      room:setPlayerMark(player, "ty_ex__dangxian-phase", 1)
      player:gainAnExtraPhase(Player.Play)
    else
      room:setPlayerMark(player, "ty_ex__dangxian-phase", 0)
      if player:getMark("ty_ex__fuli") == 0 or room:askForSkillInvoke(player, self.name, nil, "#ty_ex__dangxian-invoke") then
        --为了加强关索，不用技能次数判断
        room:loseHp(player, 1, self.name)
        if not player.dead then
          local cards = room:getCardsFromPileByRule("slash", 1, "discardPile")
          if #cards > 0 then
            room:obtainCard(player, cards[1], true, fk.ReasonJustMove)
          end
        end
      end
    end
  end,
}
local ty_ex__fuli = fk.CreateTriggerSkill{
  name = "ty_ex__fuli",
  anim_type = "defensive",
  frequency = Skill.Limited,
  events = {fk.AskForPeaches},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.dying and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, self.name, 1)
    local kingdoms = {}
    for _, p in ipairs(room:getAlivePlayers()) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    room:recover({
      who = player,
      num = math.min(#kingdoms, player.maxHp) - player.hp,
      recoverBy = player,
      skillName = self.name
    })
    if player:getHandcardNum() < #kingdoms then
      player:drawCards(#kingdoms - player:getHandcardNum())
    end
    if #kingdoms > 2 then
      player:turnOver()
    end
  end,
}
liaohua:addSkill(ty_ex__dangxian)
liaohua:addSkill(ty_ex__fuli)
Fk:loadTranslationTable{
  ["ty_ex__liaohua"] = "界廖化",
  ["#ty_ex__liaohua"] = "历尽沧桑",
  ["illustrator:ty_ex__liaohua"] = "君桓文化",
  ["ty_ex__dangxian"] = "当先",
  [":ty_ex__dangxian"] = "锁定技，回合开始时，你执行一个额外的出牌阶段，此阶段开始时你失去1点体力并从弃牌堆获得一张【杀】。",
  ["ty_ex__fuli"] = "伏枥",
  [":ty_ex__fuli"] = "限定技，当你处于濒死状态时，你可以将体力回复至X点且手牌摸至X张（X为全场势力数），然后〖当先〗中失去体力的效果改为可选。"..
  "若X不小于3，你翻面。",
  ["#ty_ex__dangxian-invoke"] = "当先：你可以失去1点体力，从弃牌堆获得一张【杀】",

  ["$ty_ex__dangxian1"] = "竭诚当先，一举克定！",
  ["$ty_ex__dangxian2"] = "一马当先，奋勇杀敌！",
  ["$ty_ex__fuli1"] = "匡扶汉室，死而后已！",
  ["$ty_ex__fuli2"] = "一息尚存，不忘君恩！",
  ["~ty_ex__liaohua"] = "汉室，气数已尽……",
}

local guanxingzhangbao = General(extension, "ty_ex__guanxingzhangbao", "shu", 4)
local ty_ex__tongxin = fk.CreateAttackRangeSkill{
  name = "ty_ex__tongxin",
  correct_func = function (self, from, to)
    if from:hasSkill(self) then
      return 2
    end
    return 0
  end,
}

local ty_ex__fuhun = fk.CreateViewAsSkill{
  name = "ty_ex__fuhun",
  pattern = "slash",
  card_filter = function(self, to_select, selected)
    return #selected < 2 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  view_as = function(self, cards)
    if #cards ~= 2 then return end
    local c = Fk:cloneCard("slash")
    c.skillName = self.name
    c:addSubcards(cards)
    return c
  end,
}
local ty_ex__fuhun_delay = fk.CreateTriggerSkill{
  name = "#ty_ex__fuhun_delay",
  mute = true,
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card and table.contains(data.card.skillNames, "ty_ex__fuhun") and player.phase == Player.Play
    and not (player:hasSkill("ex__wusheng", true) and player:hasSkill("ex__paoxiao", true))
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local skills = table.filter({"ex__wusheng","ex__paoxiao"}, function(s) return not player:hasSkill(s,true) end)
    room:handleAddLoseSkills(player, table.concat(skills, "|"))
    room.logic:getCurrentEvent():findParent(GameEvent.Turn):addCleaner(function()
      room:handleAddLoseSkills(player, "-"..table.concat(skills, "|-"))
    end)
  end,
}
ty_ex__fuhun:addRelatedSkill(ty_ex__fuhun_delay)
guanxingzhangbao:addSkill(ty_ex__fuhun)
guanxingzhangbao:addSkill(ty_ex__tongxin)
guanxingzhangbao:addRelatedSkill("ex__wusheng")
guanxingzhangbao:addRelatedSkill("ex__paoxiao")
Fk:loadTranslationTable{
  ["ty_ex__guanxingzhangbao"] = "界关兴张苞",
  ["#ty_ex__guanxingzhangbao"] = "将门虎子",
  ["illustrator:ty_ex__guanxingzhangbao"] = "黯荧岛工作室",
  ["ty_ex__tongxin"] = "同心",
  [":ty_ex__tongxin"] = "锁定技，你的攻击范围+2。",
  ["ty_ex__fuhun"] = "父魂",
  [":ty_ex__fuhun"] = "你可以将两张手牌当【杀】使用或打出；当你于出牌阶段内以此法造成伤害后，本回合获得〖武圣〗和〖咆哮〗。",
  ["ty_ex__fuhun_delay"] = "父魂",

  ["$ty_ex__fuhun1"] = "擎刀执矛，以效先父之法。",
  ["$ty_ex__fuhun2"] = "苍天在上，儿必不堕父亲威名！",
  ["$ex__wusheng_ty_ex__guanxingzhangbao1"] = "青龙驰骋，恍若汉寿再世。",
  ["$ex__wusheng_ty_ex__guanxingzhangbao2"] = "偃月幽光，恰如武圣冲阵。",
  ["$ex__paoxiao_ty_ex__guanxingzhangbao1"] = "桓侯之子，当效父之勇烈！",
  ["$ex__paoxiao_ty_ex__guanxingzhangbao2"] = "蛇矛在手，谁敢与我一战！",
  ["~ty_ex__guanxingzhangbao"] = "马革裹尸，九泉之下无愧见父……",
}

local chengpu = General(extension, "ty_ex__chengpu", "wu", 4)
local ty_ex__lihuo = fk.CreateTriggerSkill{
  name = "ty_ex__lihuo",
  anim_type = "offensive",
  events = {fk.AfterCardUseDeclared, fk.AfterCardTargetDeclared, fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.AfterCardUseDeclared then
        return data.card.name == "slash"
      elseif event == fk.AfterCardTargetDeclared then
        return data.card.name == "fire__slash" and #U.getUseExtraTargets(player.room, data) > 0
      else
        if data.card.trueName ~= "slash" then return false end
        local cardlist = data.card:isVirtual() and data.card.subcards or {data.card.id}
        if #cardlist ~= 1 or Fk:getCardById(cardlist[1], true).trueName ~= "slash" then return false end
        local room = player.room
        if room:getCardArea(cardlist[1]) == Card.Processing then
          local logic = room.logic
          local use_event = logic:getCurrentEvent()
          local mark = player:getMark("ty_ex__lihuo_record-turn")
          if mark == 0 then
            logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
              local last_use = e.data[1]
              if last_use.from == player.id then
                mark = e.id
                room:setPlayerMark(player, "ty_ex__lihuo_record-turn", mark)
                return true
              end
              return false
            end, Player.HistoryTurn)
          end
          return mark == use_event.id
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.AfterCardUseDeclared then
      return player.room:askForSkillInvoke(player, self.name, nil, "#ty_ex__lihuo1-invoke:::"..data.card:toLogString())
    elseif event == fk.AfterCardTargetDeclared then
      local tos = player.room:askForChoosePlayers(player, U.getUseExtraTargets(player.room, data),
      1, 1, "#lihuo-choose:::"..data.card:toLogString(), self.name, true)
      if #tos > 0 then
        self.cost_data = tos
        return true
      end
    else
      return player.room:askForSkillInvoke(player, self.name, nil, "#ty_ex__lihuo2-invoke:::"..data.card:toLogString())
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.AfterCardUseDeclared then
      local card = Fk:cloneCard("fire__slash", data.card.suit, data.card.number)
      for k, v in pairs(data.card) do
        if card[k] == nil then
          card[k] = v
        end
      end
      if data.card:isVirtual() then
        card.subcards = data.card.subcards
      else
        card.id = data.card.id
      end
      card.skillNames = data.card.skillNames
      data.card = card
      data.extra_data = data.extra_data or {}
      data.extra_data.ty_ex__lihuo = data.extra_data.ty_ex__lihuo or {}
      table.insert(data.extra_data.ty_ex__lihuo, player.id)
    elseif event == fk.AfterCardTargetDeclared then
      table.insert(data.tos, self.cost_data)
    else
      player:addToPile("ty_ex__chengpu_chun", data.card, true, self.name)
    end
  end,
}
local ty_ex__lihuo_record = fk.CreateTriggerSkill{
  name = "#ty_ex__lihuo_record",
  events = {fk.CardUseFinished},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and data.damageDealt and data.extra_data and data.extra_data.ty_ex__lihuo and
    table.contains(data.extra_data.ty_ex__lihuo, player.id)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1, "ty_ex__lihuo")
  end,
}
local ty_ex__chunlao = fk.CreateTriggerSkill{
  name = "ty_ex__chunlao",
  anim_type = "support",
  derived_piles = "ty_ex__chengpu_chun",
  events = {fk.EventPhaseEnd, fk.AskForPeaches},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.EventPhaseEnd then
        return target == player and player.phase == Player.Play and #player:getPile("ty_ex__chengpu_chun") == 0 and not player:isKongcheng()
      else
        return target.dying and #player:getPile("ty_ex__chengpu_chun") > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    if event == fk.EventPhaseEnd then
      cards = room:askForCard(player, 1, #player.player_cards[Player.Hand], false, self.name, true, "slash", "#ty_ex__chunlao-cost")
    else
      cards = room:askForCard(player, 1, 1, false, self.name, true, ".|.|.|ty_ex__chengpu_chun|.|.",
        "#ty_ex__chunlao-invoke::"..target.id, "ty_ex__chengpu_chun")
    end
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseEnd then
      player:addToPile("ty_ex__chengpu_chun", self.cost_data, true, self.name)
    else
      room:moveCards({
        from = player.id,
        ids = self.cost_data,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = self.name,
        specialName = self.name,
      })
      room:useCard({
        card = Fk:cloneCard("analeptic"),
        from = target.id,
        tos = {{target.id}},
        extra_data = {analepticRecover = true},
        skillName = self.name,
      })
      if player.dead then return end
      if Fk:getCardById(self.cost_data[1]).name == "fire__slash" then
        if player:isWounded() then
          room:recover({
            who = player,
            num = 1,
            recoverBy = player,
            skillName = self.name
          })
        end
      elseif Fk:getCardById(self.cost_data[1]).name == "thunder__slash" then
        player:drawCards(2, self.name)
      end
    end
  end,
}
ty_ex__lihuo:addRelatedSkill(ty_ex__lihuo_record)
chengpu:addSkill(ty_ex__lihuo)
chengpu:addSkill(ty_ex__chunlao)
Fk:loadTranslationTable{
  ["ty_ex__chengpu"] = "界程普",
  ["#ty_ex__chengpu"] = "三朝虎臣",
  ["illustrator:ty_ex__chengpu"] = "zoo",
  ["ty_ex__lihuo"] = "疬火",
  [":ty_ex__lihuo"] = "你使用普通【杀】可以改为火【杀】，结算后若此法使用的【杀】造成了伤害，你失去1点体力；你使用火【杀】时，可以增加一个目标。"..
  "你于一个回合内使用的第一张牌结算后，若此牌为【杀】，你可以将之置为“醇”。",
  ["ty_ex__chunlao"] = "醇醪",
  [":ty_ex__chunlao"] = "出牌阶段结束时，若你没有“醇”，你可以将任意张【杀】置为“醇”；当一名角色处于濒死状态时，"..
  "你可以将一张“醇”置入弃牌堆，视为该角色使用一张【酒】；若你此法置入弃牌堆的是：火【杀】，你回复1点体力；雷【杀】，你摸两张牌。",
  ["#ty_ex__lihuo1-invoke"] = "疬火：是否将%arg改为火【杀】？",
  ["#ty_ex__lihuo2-invoke"] = "疬火：你可以将%arg置为“醇”",
  ["ty_ex__chengpu_chun"] = "醇",
  ["#ty_ex__chunlao-cost"] = "醇醪：你可以将任意张【杀】置为“醇”",
  ["#ty_ex__chunlao-invoke"] = "醇醪：你可以将一张“醇”置入弃牌堆，视为 %dest 使用一张【酒】",
  ["#ty_ex__lihuo_record"] = "疬火（失去体力）",

  ["$ty_ex__lihuo1"] = "叛军者，非烈火灼身难泄吾恨。",
  ["$ty_ex__lihuo2"] = "投敌于火，烧炙其身，皮焦肉烂！",
  ["$ty_ex__chunlao1"] = "醉里披甲执坚，梦中杀敌破阵。",
  ["$ty_ex__chunlao2"] = "醇醪须与明君饮，沙场无还亦不悔。",
  ["~ty_ex__chengpu"] = "病疠缠身，终天命难违……",
}

local bulianshi = General(extension, "ty_ex__bulianshi", "wu", 3, 3, General.Female)
local ty_ex__anxu = fk.CreateActiveSkill{
  name = "ty_ex__anxu",
  anim_type = "control",
  target_num = 2,
  card_num = 0,
  prompt = "#ty_ex__anxu",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    if #selected > 1 or to_select == Self.id then return false end
    if #selected == 0 then
      return true
    elseif #selected == 1 then
      local target1 = Fk:currentRoom():getPlayerById(to_select)
      local target2 = Fk:currentRoom():getPlayerById(selected[1])
      return target1:getHandcardNum() ~= target2:getHandcardNum()
    else
      return false
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target1 = room:getPlayerById(effect.tos[1])
    local target2 = room:getPlayerById(effect.tos[2])
    local from, to
    if target1:getHandcardNum() < target2:getHandcardNum() then
      from = target1
      to = target2
    else
      from = target2
      to = target1
    end
    local id = room:askForCardChosen(from, to, "h", self.name)
    room:obtainCard(from.id, id, true, fk.ReasonPrey)
    if room:getCardOwner(id) == from and room:getCardArea(id) == Card.PlayerHand then
      from:showCards({id})
    end
    if Fk:getCardById(id).suit ~= Card.Spade then
      player:drawCards(1, self.name)
    end
    if target1:getHandcardNum() == target2:getHandcardNum() and player:isWounded() and not player.dead then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      }
    end
  end,
}
local ty_ex__zhuiyi = fk.CreateTriggerSkill{
  name = "ty_ex__zhuiyi",
  anim_type = "support",
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self, false, true)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(room:getOtherPlayers(player), Util.IdMapper)
    if data.damage and data.damage.from then
      table.removeOne(targets, data.damage.from.id)
    end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#ty_ex__zhuiyi-choose:::"..#room.alive_players, self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    to:drawCards(#room.alive_players, self.name)
    if to:isWounded() then
      room:recover{
        who = to,
        num = 1,
        recoverBy = player,
        skillName = self.name
      }
    end
  end,
}
bulianshi:addSkill(ty_ex__anxu)
bulianshi:addSkill(ty_ex__zhuiyi)
Fk:loadTranslationTable{
  ["ty_ex__bulianshi"] = "界步练师",
  ["#ty_ex__bulianshi"] = "无冕之后",
  ["illustrator:ty_ex__bulianshi"] = "匠人绘",
  ["ty_ex__anxu"] = "安恤",
  [":ty_ex__anxu"] = "出牌阶段限一次，你可以选择两名手牌数不同的其他角色，令其中手牌少的角色获得手牌多的角色一张手牌并展示之：若此牌不为♠，"..
  "你摸一张牌；若其手牌数因此相同，你回复1点体力。",
  ["ty_ex__zhuiyi"] = "追忆",
  [":ty_ex__zhuiyi"] = "当你死亡时，可以令一名其他角色（杀死你的角色除外）摸X张牌（X为存活角色数）并回复1点体力。",
  ["#ty_ex__anxu"] = "安恤：选择两名手牌数不同的其他角色，手牌少的角色获得手牌多的角色一张手牌",
  ["#ty_ex__zhuiyi-choose"] = "追忆：你可以令一名角色摸%arg张牌并回复1点体力",

  ["$ty_ex__anxu1"] = "温言呢喃，消君之愁。",
  ["$ty_ex__anxu2"] = "吴侬软语，以解君忧。",
  ["$ty_ex__zhuiyi1"] = "别后庭中树，相思几度攀。",
  ["$ty_ex__zhuiyi2"] = "空馀宫阙恨，因此寄相思。",
  ["~ty_ex__bulianshi"] = "还请至尊多保重……",
}

local handang = General(extension, "ty_ex__handang", "wu", 4)
local ty_ex__gongqi = fk.CreateActiveSkill{
  name = "ty_ex__gongqi",
  anim_type = "offensive",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isNude()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:addPlayerMark(player, "ty_ex__gongqi-turn", 999)
    room:setPlayerMark(player, "@ty_ex__gongqi-turn", Fk:getCardById(effect.cards[1]):getSuitString(true))
    room:throwCard(effect.cards, self.name, player, player)
    if Fk:getCardById(effect.cards[1]).type == Card.TypeEquip then
      local to = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
        return not p:isNude() end), Util.IdMapper), 1, 1, "#ty_ex__gongqi-choose", self.name, true)
      if #to > 0 then
        local target = room:getPlayerById(to[1])
        local id = room:askForCardChosen(player, target, "he", self.name)
        room:throwCard({id}, self.name, target, player)
      end
    end
  end,
}
local ty_ex__gongqi_attackrange = fk.CreateAttackRangeSkill{
  name = "#ty_ex__gongqi_attackrange",
  correct_func = function (self, from, to)
    return from:getMark("ty_ex__gongqi-turn")
  end,
}
local ty_ex__gongqi_targetmod = fk.CreateTargetModSkill{
  name = "#ty_ex__gongqi_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return player:getMark("@ty_ex__gongqi-turn") ~= 0 and scope == Player.HistoryPhase and card and card.trueName == "slash" and
      player:getMark("@ty_ex__gongqi-turn") == card:getSuitString(true)
  end,
}
local ty_ex__jiefan = fk.CreateActiveSkill{
  name = "ty_ex__jiefan",
  anim_type = "drawcard",
  card_num = 0,
  target_num = 1,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    for _, p in ipairs(room:getOtherPlayers(target)) do
      if target.dead then break end
      if p:inMyAttackRange(target) then
        if #room:askForDiscard(p, 1, 1, true, self.name, true, ".|.|.|.|.|weapon", "#ty_ex__jiefan-discard::"..target.id) == 0 then
          target:drawCards(1, self.name)
        end
      end
    end
  end,
}
local ty_ex__jiefan_trigger = fk.CreateTriggerSkill{
  name = "#ty_ex__jiefan_trigger",
  mute = true,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:usedSkillTimes("ty_ex__jiefan", Player.HistoryTurn) > 0 and player.room:getTag("RoundCount") == 1
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:setSkillUseHistory("ty_ex__jiefan", 0, Player.HistoryGame)
  end,
}
ty_ex__gongqi:addRelatedSkill(ty_ex__gongqi_attackrange)
ty_ex__gongqi:addRelatedSkill(ty_ex__gongqi_targetmod)
ty_ex__jiefan:addRelatedSkill(ty_ex__jiefan_trigger)
handang:addSkill(ty_ex__gongqi)
handang:addSkill(ty_ex__jiefan)
Fk:loadTranslationTable{
  ["ty_ex__handang"] = "界韩当",
  ["#ty_ex__handang"] = "石城侯",
  ["illustrator:ty_ex__handang"] = "君桓文化",
  ["ty_ex__gongqi"] = "弓骑",
  [":ty_ex__gongqi"] = "出牌阶段限一次，你可以弃置一张牌，此回合你的攻击范围无限，且使用此花色的【杀】无次数限制。若你以此法弃置的牌为装备牌，"..
  "你可以弃置一名其他角色的一张牌。",
  ["ty_ex__jiefan"] = "解烦",
  [":ty_ex__jiefan"] = "限定技，出牌阶段，你可以选择一名角色，然后令攻击范围内有该角色的所有角色各选择一项：1.弃置一张武器牌；2.令其摸一张牌。"..
  "若此时为第一轮，此回合结束时本技能视为未发动过。",
  ["#ty_ex__gongqi-choose"] = "弓骑：你可以弃置一名其他角色的一张牌",
  ["@ty_ex__gongqi-turn"] = "弓骑",
  ["#ty_ex__jiefan-discard"] = "解烦：弃置一张武器牌，否则 %dest 摸一张牌",

  ["$ty_ex__gongqi1"] = "马踏飞箭，弓骑无双！",
  ["$ty_ex__gongqi2"] = "提弓上马，箭砺八方！",
  ["$ty_ex__jiefan1"] = "烦忧千万，且看我一刀解之。",
  ["$ty_ex__jiefan2"] = "莫道雄兵属北地，解烦威名天下扬。",
  ["~ty_ex__handang"] = "三石雕弓今尤在，不见当年挽弓人……",
}

local ty_ex__liubiao = General(extension, "ty_ex__liubiao", "qun", 3)
local ty_ex__zishou = fk.CreateTriggerSkill{
  name = "ty_ex__zishou",
  anim_type = "drawcard",
  events = {fk.DrawNCards, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if event == fk.DrawNCards then
      return target == player and player:hasSkill(self)
    elseif target == player and player:hasSkill(self) and player.phase == Player.Finish and not player:isKongcheng() then
      local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data[1]
        if use.from == player.id and use.tos then
          if table.find(TargetGroup:getRealTargets(use.tos), function(pid) return pid ~= player.id end) then
            return true
          end
        end
        return false
      end, Player.HistoryTurn)
      return #events == 0
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if event == fk.DrawNCards then
      local kingdoms = {}
      for _, p in ipairs(room.alive_players) do
        table.insertIfNeed(kingdoms, p.kingdom)
      end
      local num = #kingdoms
      if room:askForSkillInvoke(player, self.name, nil, "#ty_ex__zishou-draw:::"..num) then
        self.cost_data = num
        return true
      end
    else
      local success, dat = room:askForUseActiveSkill(player, "ty_ex__zishou_active", "#ty_ex__zishou-discard", true)
      if success and dat then
        self.cost_data = dat.cards
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DrawNCards then
      data.n = data.n + self.cost_data
      room:setPlayerMark(player, "@@ty_ex__zishou-turn", 1)
    else
      room:throwCard(self.cost_data, self.name, player, player)
      if not player.dead then
        player:drawCards(#self.cost_data, self.name)
      end
    end
  end,
}
local ty_ex__zishou_active = fk.CreateActiveSkill{
  name = "ty_ex__zishou_active",
  target_num = 0,
  min_card_num = 1,
  card_filter = function(self, to_select, selected)
    if Fk:currentRoom():getCardArea(to_select) == Player.Equip or Self:prohibitDiscard(Fk:getCardById(to_select)) then return end
    if #selected == 0 then
      return true
    else
      return table.every(selected, function (id) return Fk:getCardById(to_select).suit ~= Fk:getCardById(id).suit end)
    end
  end,
}
Fk:addSkill(ty_ex__zishou_active)
local ty_ex__zishou_delay = fk.CreateTriggerSkill{
  name = "#ty_ex__zishou_delay",
  mute = true,
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and data.to ~= player and player:getMark("@@ty_ex__zishou-turn") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player:broadcastSkillInvoke("ty_ex__zishou")
    return true
  end,
}
ty_ex__zishou:addRelatedSkill(ty_ex__zishou_delay)
ty_ex__liubiao:addSkill(ty_ex__zishou)
local ty_ex__zongshi = fk.CreateTriggerSkill{
  name = "ty_ex__zongshi",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.PreCardEffect, fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    if event == fk.PreCardEffect then
      return player:hasSkill(self) and player.phase == Player.NotActive and player.id == data.to and
      data.card.color == Card.NoColor and player:getHandcardNum() >= player:getMaxCards()
    else
      return player:hasSkill(self) and player.phase == Player.NotActive and player == target and
      data.card.sub_type == Card.SubtypeDelayedTrick and player:getHandcardNum() >= player:getMaxCards()
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if event == fk.PreCardEffect then
      return true
    else
      local cardIds = room:getSubcardsByRule(data.card, {Card.Processing})
      room:moveCards({
        ids = cardIds,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonUse,
      })
    end
  end
}
local ty_ex__zongshi_maxcards = fk.CreateMaxCardsSkill{
  name = "#ty_ex__zongshi_maxcards",
  correct_func = function(self, player)
    if player:hasSkill(ty_ex__zongshi) then
      local kingdoms = {}
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        table.insertIfNeed(kingdoms, p.kingdom)
      end
      return #kingdoms
    end
    return 0
  end,
}
ty_ex__zongshi:addRelatedSkill(ty_ex__zongshi_maxcards)
ty_ex__liubiao:addSkill(ty_ex__zongshi)
Fk:loadTranslationTable{
  ["ty_ex__liubiao"] = "界刘表",
  ["#ty_ex__liubiao"] = "跨蹈汉南",
  ["illustrator:ty_ex__liubiao"] = "聚一",
  ["ty_ex__zishou"] = "自守",
  [":ty_ex__zishou"] = "①摸牌阶段，你可以多摸X张牌（X为全场势力数），然后本回合你对其他角色造成伤害时，防止之；"..
  "<br>②结束阶段，若你本回合没有对其他角色使用过牌，你可以弃置任意张花色各不相同的手牌，摸等量的牌。",
  ["ty_ex__zongshi"] = "宗室",
  [":ty_ex__zongshi"] = "锁定技，①你的手牌上限+X（X为全场势力数）；"..
  "<br>②你的回合外，若你的手牌数不小于手牌上限，延时锦囊牌和无色牌对你无效。",
  ["@@ty_ex__zishou-turn"] = "自守",
  ["ty_ex__zishou_active"] = "自守",
  ["#ty_ex__zishou-draw"] = "自守：你可以多摸 %arg 张牌，防止本回合你对其他角色造成的伤害",
  ["#ty_ex__zishou-discard"] = "自守：可以弃置任意张花色各不相同的手牌，摸等量的牌",

  ["$ty_ex__zishou1"] = "恩威并著，从容自保！",
  ["$ty_ex__zishou2"] = "据有荆州，以观世事！",
  ["$ty_ex__zongshi1"] = "汉室江山，气数未尽！",
  ["$ty_ex__zongshi2"] = "我刘氏一族，皆海内之俊杰也！",
  ["~ty_ex__liubiao"] = "人心不古！",
}

local zhonghui = General(extension, "ty_ex__zhonghui", "wei", 4)
local ty_ex__quanji = fk.CreateTriggerSkill{
  name = "ty_ex__quanji",
  derived_piles = "zhonghui_quan",
  anim_type = "masochism",
  events = {fk.AfterCardsMove, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.from == player.id and move.to and move.to ~= player.id and move.moveReason == fk.ReasonPrey then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip or info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    elseif event == fk.Damaged and target == player then
      return true
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local x = 1
    if event == fk.Damaged then
      x = data.damage
    end
    self.cancel_cost = false
    for _ = 1, x do
      if self.cancel_cost or not player:hasSkill(self) then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askForSkillInvoke(player, self.name, data) then
      return true
    end  
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, self.name)
    if not player:isKongcheng() then
      local card = room:askForCard(player, 1, 1, false, self.name, false)
      player:addToPile("zhonghui_quan", card, true, self.name)
    end
  end,
}
local ex__quanji_maxcards = fk.CreateMaxCardsSkill{
  name = "#ex__quanji_maxcards",
  correct_func = function(self, player)
    if player:hasSkill(ty_ex__quanji) then
      return #player:getPile("zhonghui_quan")
    else
      return 0
    end
  end,
}
local ty_ex__zili = fk.CreateTriggerSkill{
  name = "ty_ex__zili",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #player:getPile("zhonghui_quan") > 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    player:drawCards(2, self.name)
    if player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    room:handleAddLoseSkills(player, "ty_ex__paiyi", nil, true, false)
  end,
}
local ty_ex__paiyi = fk.CreateActiveSkill{
  name = "ty_ex__paiyi",
  anim_type = "control",
  expand_pile = "zhonghui_quan",
  card_num = 1,
  min_target_num = 1,
  max_target_num = function(self)
    return self.interaction.data == "ty_ex__paiyi_draw" and 1 or #Self:getPile("zhonghui_quan") - 1
  end,
  prompt = function(self)
    if self.interaction.data  == "ty_ex__paiyi_draw" then
      return "#ty_ex__paiyi_draw:::"..(#Self:getPile("zhonghui_quan") - 1)
    else
      return "#ty_ex__paiyi_damage:::"..(#Self:getPile("zhonghui_quan") - 1)
    end
  end,
  interaction = function(self)
    local choiceList = {}
    if Self:getMark("ty_ex__paiyi_draw-phase") == 0 then
      table.insert(choiceList, "ty_ex__paiyi_draw")
    end
    if Self:getMark("ty_ex__paiyi_damage-phase") == 0 then 
      table.insert(choiceList, "ty_ex__paiyi_damage")
    end
    return UI.ComboBox { choices = choiceList }
  end,
  target_filter = function(self, to_select, selected)
    return  #selected == 0 or (self.interaction.data == "ty_ex__paiyi_damage" and #selected < #Self:getPile("zhonghui_quan") - 1)
  end,
  can_use = function(self, player)
    return #player:getPile("zhonghui_quan") > 0 and
      (player:getMark("ty_ex__paiyi_draw-phase") == 0 or player:getMark("ty_ex__paiyi_damage-phase") == 0)
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Self:getPileNameOfId(to_select) == "zhonghui_quan"
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:moveCards({
      from = player.id,
      ids = effect.cards,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
      skillName = self.name,
    })
    room:setPlayerMark(player, self.interaction.data.."-phase", 1)
    if self.interaction.data == "ty_ex__paiyi_draw" then
      target:drawCards(math.max(#player:getPile("zhonghui_quan"),1), self.name)
    else
      for _, id in ipairs(effect.tos) do
        local p = room:getPlayerById(id)
        if not p.dead then
          room:damage{
            from = player,
            to = p,
            damage = 1,
            skillName = self.name
          }
        end
      end
    end
  end,
}

ty_ex__quanji:addRelatedSkill(ex__quanji_maxcards)
zhonghui:addSkill(ty_ex__quanji)
zhonghui:addSkill(ty_ex__zili)
zhonghui:addRelatedSkill(ty_ex__paiyi)
Fk:loadTranslationTable{
  ["ty_ex__zhonghui"] = "界钟会",
  ["#ty_ex__zhonghui"] = "桀骜的野心家",
  ["illustrator:ty_ex__zhonghui"] = "君桓文化",
  ["ty_ex__quanji"] = "权计",
  [":ty_ex__quanji"] = "当你的牌被其他角色获得后或受到1点伤害后，你可以摸一张牌，然后将一张手牌置于武将牌上，称为“权”；每有一张“权”，你的手牌上限便+1。",
  ["ty_ex__zili"] = "自立",
  [":ty_ex__zili"] = "觉醒技，准备阶段，若“权”的数量达到3或更多，你减1点体力上限，然后回复1点体力并摸两张牌，并获得技能〖排异〗。",
  ["ty_ex__paiyi"] = "排异",
  [":ty_ex__paiyi"] = "出牌阶段各限一次，你可移去一张“权”并选择一项：1.令一名角色摸X张牌；2.对至多X名角色各造成1点伤害（X为“权”数且至少为1）。",
  ["#ty_ex__paiyi_draw"] = "排异：令一名角色摸%arg张牌",
  ["#ty_ex__paiyi_damage"] = "排异：对至多%arg名角色各造成1点伤害",
  ["ty_ex__paiyi_draw"] = "摸牌",
  ["ty_ex__paiyi_damage"] = "伤害",

  ["$ty_ex__quanji1"] = "操权弄略，舍小利，而谋大计!",
  ["$ty_ex__quanji2"] = "大丈夫行事，岂较一兵一将之得失？",
  ["$ty_ex__zili1"] = "烧去剑阁八百里，蜀中自有一片天!",
  ["$ty_ex__zili2"] = "天下风流出我辈，一遇风云便化龙。",
  ["$ty_ex__paiyi1"] = "蜀川三千里，皆由我一言决之!",
  ["$ty_ex__paiyi2"] = "顺我者，封侯拜将!，逆我者，斧钺加身!",
  ["~ty_ex__zhonghui"] = "这就是……自食恶果的下场吗？",
}
-- yj2013
local caochong = General(extension, "ty_ex__caochong", "wei", 3)
local ty_ex__chengxiang = fk.CreateTriggerSkill{
  name = "ty_ex__chengxiang",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and target:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(4)
    room:moveCards({
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonPut,
    })
    local get = room:askForPoxi(player, "chengxiang_count", {
      { self.name, cards },
    }, nil, true)
    if #get > 0 then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(get)
      room:obtainCard(player.id, dummy, true, fk.ReasonPrey)
      local n = 0
      for _, id in ipairs(get) do
        n = n + Fk:getCardById(id).number
      end
      if n == 13 then
        player:reset()
      end
    end
    cards = table.filter(cards, function(id) return room:getCardArea(id) == Card.Processing end)
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
      })
    end
  end
}
caochong:addSkill(ty_ex__chengxiang)
caochong:addSkill("renxin")
Fk:loadTranslationTable{
  ["ty_ex__caochong"] = "界曹冲",
  ["#ty_ex__caochong"] = "仁爱的神童",
  ["illustrator:ty_ex__caochong"] = "虫师网络",
  ["ty_ex__chengxiang"] = "称象",
  [":ty_ex__chengxiang"] = "当你受到伤害后，你可以亮出牌堆顶的四张牌，然后获得其中的任意张点数之和小于等于13的牌。若获得的牌点数之和为13，你复原武将牌。",

  ["$ty_ex__chengxiang1"] = "冲有一法，可得其重。",
  ["$ty_ex__chengxiang2"] = "待我细细算来。",
  ["$renxin_ty_ex__caochong1"] = "见死而不救，非仁者所为。",
  ["$renxin_ty_ex__caochong2"] = "遇难而不援，非我之道也。",
  ["~ty_ex__caochong"] = "父亲，兄长……",
}
local guohuai = General(extension, "ty_ex__guohuai", "wei", 4)
local ty_ex__jingce = fk.CreateTriggerSkill{
  name = "ty_ex__jingce",
  anim_type = "drawcard",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)  and #player.room.logic:getEventsOfScope(GameEvent.UseCard, 998, function(e) 
      local use = e.data[1]
      return use.from == player.id
    end, Player.HistoryTurn) >= player.hp
  end,
  on_use = function(self, event, target, player, data)
    local suits = {}
    local room = player.room
    room.logic:getEventsOfScope(GameEvent.UseCard, 998, function(e) 
      local use = e.data[1]
      if use.from == player.id then
        table.insertIfNeed(suits, use.card.suit)
      end
    end, Player.HistoryTurn)
    if #suits >= player.hp then
      player:gainAnExtraPhase(Player.Draw)
      player:gainAnExtraPhase(Player.Play)
    else
      local choice = room:askForChoice(player, {"jingce_draw" ,"jingce_play"}, self.name,"#ty_ex__jingce-active")
      if choice == "jingce_draw" then
        player:gainAnExtraPhase(Player.Draw)
      elseif choice == "jingce_play" then
        player:gainAnExtraPhase(Player.Play)
      end
    end
  end,
}
guohuai:addSkill(ty_ex__jingce)
Fk:loadTranslationTable{
  ["ty_ex__guohuai"] = "界郭淮",
  ["#ty_ex__guohuai"] = "垂问秦雍",
  ["illustrator:ty_ex__guohuai"] = "心中一凛",
  ["ty_ex__jingce"] = "精策",
  [":ty_ex__jingce"] = "回合结束时，若你本回合已使用的牌数大于或等于你的体力值，你可以选择一项:1，执行一个额外的摸牌阶段。2，执行一个额外的出牌阶段。;若你本回合使用的牌花色也大于或等于你的体力值，则改为两项均执行。",
  ["jingce_draw"] = "执行一个摸牌阶段",
  ["jingce_play"] = "执行一个出牌阶段",
  ["#ty_ex__jingce-active"] = "精策:选择执行一个额外的摸牌阶段或者出牌阶段",

  ["$ty_ex__jingce1"] = "精细入微，策敌制胜。",
  ["$ty_ex__jingce2"] = "妙策如神，精兵强将，安有不胜之理？",
  ["~ty_ex__guohuai"] = "岂料姜维……空手接箭！",
}

local liufeng = General(extension, "ty_ex__liufeng", "shu", 4)
local ty_ex__xiansi = fk.CreateTriggerSkill{
  name = "ty_ex__xiansi",
  derived_piles = "ty_ex__xiansi_ni",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Start then
      return not table.every(player.room:getOtherPlayers(player), function (p) return p:isNude() end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isNude() end), Util.IdMapper)
    local tos = room:askForChoosePlayers(player, targets, 1, 2, "#ty_ex__xiansi-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(self.cost_data) do
      local id = room:askForCardChosen(player, room:getPlayerById(p), "he", self.name)
      player:addToPile("ty_ex__xiansi_ni", id, true, self.name)
    end
  end,

  refresh_events = {fk.GameStart, fk.EventAcquireSkill, fk.EventLoseSkill, fk.Deathed},
  can_refresh = function(self, event, target, player, data)
    if event == fk.GameStart then
      return player:hasSkill(self, true)
    elseif event == fk.EventAcquireSkill or event == fk.EventLoseSkill then
      return data == self
    else
      return target == player and player:hasSkill(self, true, true)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart or event == fk.EventAcquireSkill then
      if player:hasSkill(self, true) then
        for _, p in ipairs(room:getOtherPlayers(player)) do
          room:handleAddLoseSkills(p, "ty_ex__xiansi&", nil, false, true)
        end
      end
    elseif event == fk.EventLoseSkill or event == fk.Deathed then
      for _, p in ipairs(room:getOtherPlayers(player, true, true)) do
        room:handleAddLoseSkills(p, "-ty_ex__xiansi&", nil, false, true)
      end
    end
  end,
}
local ty_ex__xiansi_viewas = fk.CreateViewAsSkill{
  name = "ty_ex__xiansi&",
  anim_type = "negative",
  pattern = "slash",
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    local c = Fk:cloneCard("slash")
    c.skillName = "ty_ex__xiansi"
    return c
  end,
  before_use = function(self, player, use)
    local room = player.room
    for _, id in ipairs(TargetGroup:getRealTargets(use.tos)) do
      local p = room:getPlayerById(id)
      if p:hasSkill("ty_ex__xiansi", true) and #p:getPile("ty_ex__xiansi_ni") > 1 then
        local cards = table.random(p:getPile("ty_ex__xiansi_ni"), 2)
        room:moveCards({
          from = id,
          ids = cards,
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonPutIntoDiscardPile,
          skillName = "ty_ex__xiansi",
        })
        break
      end
    end
  end,
  enabled_at_play = function(self, player)
    return table.find(Fk:currentRoom().alive_players, function(p)
      return (p:hasSkill("ty_ex__xiansi", true) and #p:getPile("ty_ex__xiansi_ni") > 1) end)
  end,
  enabled_at_response = function(self, player, response)
    return not response and table.find(Fk:currentRoom().alive_players, function(p)
      return (p:hasSkill("ty_ex__xiansi", true) and #p:getPile("ty_ex__xiansi_ni") > 1) end)
  end,
}
local ty_ex__xiansi_prohibit = fk.CreateProhibitSkill{  --FIXME: 目标多指！
  name = "#ty_ex__xiansi_prohibit",
  is_prohibited = function(self, from, to, card)
    if from:hasSkill(self, true) then
      return card.trueName == "slash" and table.contains(card.skillNames, "ty_ex__xiansi") and
        not (to:hasSkill("ty_ex__xiansi", true) and #to:getPile("ty_ex__xiansi_ni") > 1)
    end
  end,
}
ty_ex__xiansi_viewas:addRelatedSkill(ty_ex__xiansi_prohibit)
Fk:addSkill(ty_ex__xiansi_viewas)
local ty_ex__xiansi_viewasSkill = fk.CreateViewAsSkill{
  name = "ty_ex__xiansi_viewasSkill",
  anim_type = "negative",
  pattern = "slash",
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    local c = Fk:cloneCard("slash")
    c.skillName = "ty_ex__xiansi"
    return c
  end,
  before_use = function(self, player, use)
     local room = player.room
     local cards = table.random(player:getPile("ty_ex__xiansi_ni"), 1)
      room:moveCards({
        from = player.id,
        ids = cards,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = "ty_ex__xiansi",
      })
  end,
  enabled_at_play = function(self, player)
    return player:hasSkill("ty_ex__xiansi", true) and #player:getPile("ty_ex__xiansi_ni") > player.hp
  end,
  enabled_at_response = function(self, player, response)
    return not response and player:hasSkill("ty_ex__xiansi", true) and #player:getPile("ty_ex__xiansi_ni") > player.hp
  end,
}
ty_ex__xiansi:addRelatedSkill(ty_ex__xiansi_viewasSkill)
liufeng:addSkill(ty_ex__xiansi)
Fk:loadTranslationTable{
  ["ty_ex__liufeng"] = "界刘封",
  ["#ty_ex__liufeng"] = "骑虎之殇",
  ["illustrator:ty_ex__liufeng"] = "Thinking",
  ["ty_ex__xiansi"] = "陷嗣",
  [":ty_ex__xiansi"] = "回合开始阶段开始时，你可以将至多两名其他角色的各一张牌置于你的武将牌上，称为“逆”。每当其他角色需要对你使用一张【杀】时，"..
  "该角色可以弃置你武将牌上的两张“逆”，视为对你使用一张【杀】。若“逆”超过你的体力值，你可以移去一张“逆”，视为使用一张【杀】。",
  ["#ty_ex__xiansi-choose"] = "陷嗣：你可以将至多两名其他角色各一张牌置为“逆”",
  ["ty_ex__xiansi_ni"] = "逆",
  ["ty_ex__xiansi&"] = "陷嗣",
  [":ty_ex__xiansi&"] = "当你需使用【杀】时，你可以弃置刘封的两张“逆”，视为对其使用一张【杀】。",
  ["ty_ex__xiansi_viewasSkill"] = "陷嗣",
  [":ty_ex__xiansi_viewasSkill"] = "当你需使用【杀】时，若你的“逆”超过你的体力值，你可以弃置一张“逆”，视为使用一张【杀】。",

  ["$ty_ex__xiansi1"] = "非我不救，实乃孟达谗言。",
  ["$ty_ex__xiansi2"] = "此皆孟达之过也！",
  ["~ty_ex__liufeng"] = "父亲，儿实无异心……",
}
local guanping = General(extension, "ty_ex__guanping", "shu", 4)
local ty_ex__longyin = fk.CreateTriggerSkill{
  name = "ty_ex__longyin",
  anim_type = "support",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.phase == Player.Play and data.card.trueName == "slash" and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#ty_ex__longyin-invoke::"..target.id, true)
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:throwCard(self.cost_data, self.name, player, player)
    if not data.extraUse then
      data.extraUse = true
      target:addCardUseHistory(data.card.trueName, -1)
    end
    if data.card.color == Card.Red and not player.dead then
      player:drawCards(1, self.name)
    end
    if data.card.number == Fk:getCardById(self.cost_data[1]).number and player:usedSkillTimes("ty_ex__jiezhong", Player.HistoryGame) > 0 then
      player:setSkillUseHistory("ty_ex__jiezhong", 0, Player.HistoryGame)
    end
  end,
}
local ty_ex__jiezhong = fk.CreateTriggerSkill{
  name = "ty_ex__jiezhong",
  anim_type = "drawcard",
  frequency = Skill.Limited,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and
      math.min(player.maxHp, 5) > player:getHandcardNum() and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local draw = math.min(player.maxHp, 5) - player:getHandcardNum()
    return player.room:askForSkillInvoke(player, self.name, nil, "#ty_ex__jiezhong-invoke:::"..draw)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = math.min(player.maxHp, 5) - player:getHandcardNum()
    player:drawCards(n, self.name)
  end,
}
guanping:addSkill(ty_ex__longyin)
guanping:addSkill(ty_ex__jiezhong)
Fk:loadTranslationTable{
  ["ty_ex__guanping"] = "界关平",
  ["#ty_ex__guanping"] = "忠臣孝子",
  ["illustrator:ty_ex__guanping"] = "君桓文化",
  ["ty_ex__longyin"] = "龙吟",
  [":ty_ex__longyin"] = "每当一名角色在其出牌阶段使用【杀】时，你可以弃置一张牌令此【杀】不计入出牌阶段使用次数，若此【杀】为红色，你摸一张牌。"..
  "若你以此法弃置的牌点数与此【杀】相同，你重置〖竭忠〗。",
  ["#ty_ex__longyin-invoke"] = "龙吟：你可以弃置一张牌令 %dest 的【杀】不计入次数限制",
  ["ty_ex__jiezhong"] = "竭忠",
  [":ty_ex__jiezhong"] = "限定技，出牌阶段开始时，若你的手牌数小于体力上限，你可以将手牌补至体力上限（至多为5）。",
  ["#ty_ex__jiezhong-invoke"] = "竭忠：是否发动“竭忠”摸%arg张牌？ ",

  ["$ty_ex__jiezhong1"] = "犯我疆土者，竭忠尽节以灭之。",
  ["$ty_ex__jiezhong2"] = "竭力尽能以立功于国，忠心不二。",
  ["$ty_ex__longyin1"] = "风云将起，龙虎齐鸣！",
  ["$ty_ex__longyin2"] = "武圣龙威，破敌无惧！",
  ["~ty_ex__guanping"] = "黄泉路远，儿愿为父亲牵马执鞭……",
}

local ty_ex__jianyong = General(extension, "ty_ex__jianyong", "shu", 3)
local ty_ex__qiaoshui = fk.CreateActiveSkill{
  name = "ty_ex__qiaoshui",
  anim_type = "control",
  can_use = function(self, player)
    return not player:isKongcheng()
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 1,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Self:canPindian(Fk:currentRoom():getPlayerById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.tos[1])
    local pindian = player:pindian({to}, self.name)
    if pindian.results[to.id].winner == player then
      room:addPlayerMark(player, "@ty_ex__qiaoshui-turn", 1)
    else
      room:setPlayerMark(player, "ty_ex__qiaoshui_fail-turn", 1)
      player:endPlayPhase()
    end
  end,
}
local ty_ex__qiaoshui_delay = fk.CreateTriggerSkill{
  name = "#ty_ex__qiaoshui_delay",
  events = {fk.AfterCardTargetDeclared},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@ty_ex__qiaoshui-turn") > 0 and data.card.type ~= Card.TypeEquip and data.card.sub_type ~= Card.SubtypeDelayedTrick
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local num = player:getMark("@ty_ex__qiaoshui-turn")
    room:setPlayerMark(player, "@ty_ex__qiaoshui-turn", 0)
    local targets = U.getUseExtraTargets(room, data)
    table.insertTableIfNeed(targets, TargetGroup:getRealTargets(data.tos))
    if #targets == 0 then return false end
    local tos = room:askForChoosePlayers(player, targets, 1, num, "#ty_ex__qiaoshui-choose:::"
    ..data.card:toLogString()..":"..num, ty_ex__qiaoshui.name, true)
    local add,remove = {},{}
    for _, to in ipairs(tos) do
      if TargetGroup:includeRealTargets(data.tos, to) then
        table.insert(remove, to)
      else
        table.insert(add, to)
      end
    end
    if #add > 0 then
      for _, to in ipairs(add) do
        table.insert(data.tos, {to})
      end
      room:sendLog{ type = "#AddTargetsBySkill", from = target.id, to = add, arg = ty_ex__qiaoshui.name, arg2 = data.card:toLogString() }
    end
    if #remove > 0 then
      for _, to in ipairs(remove) do
        TargetGroup:removeTarget(data.tos, to)
      end
      room:sendLog{ type = "#RemoveTargetsBySkill", from = target.id, to = remove, arg = ty_ex__qiaoshui.name, arg2 = data.card:toLogString() }
    end
  end,
}
ty_ex__qiaoshui:addRelatedSkill(ty_ex__qiaoshui_delay)
local ty_ex__qiaoshui_maxcards = fk.CreateMaxCardsSkill{
  name = "#ty_ex__qiaoshui_maxcards",
  exclude_from = function(self, player, card)
    return player:getMark("ty_ex__qiaoshui_fail-turn") > 0 and card.type == Card.TypeTrick
  end,
}
ty_ex__qiaoshui:addRelatedSkill(ty_ex__qiaoshui_maxcards)
ty_ex__jianyong:addSkill(ty_ex__qiaoshui)
ty_ex__jianyong:addSkill("zongshij")
Fk:loadTranslationTable{
  ["ty_ex__jianyong"] = "界简雍",
  ["#ty_ex__jianyong"] = "悠游风议",
  ["illustrator:ty_ex__jianyong"] = "黑羽",
  ["ty_ex__qiaoshui"] = "巧说",
  [":ty_ex__qiaoshui"] = "出牌阶段，你可以与一名角色拼点。若你赢，本回合你使用下一张基本牌或普通锦囊牌可以多或少选择一个目标；若你没赢，你结束出牌阶段且本回合锦囊牌不计入手牌上限。",
  ["#ty_ex__qiaoshui-choose"] = "巧说：你可以为%arg增加/减少至多 %arg2 个目标",
  ["@ty_ex__qiaoshui-turn"] = "巧说",
  ["#AddTargetsBySkill"] = "用于 %arg 的效果，%from 使用的 %arg2 增加了目标 %to",
  ["#RemoveTargetsBySkill"] = "用于 %arg 的效果，%from 使用的 %arg2 取消了目标 %to",

  ["$ty_ex__qiaoshui1"] = "慧心妙舌，难题可解。",
  ["$ty_ex__qiaoshui2"] = "巧言善辩，应对自如。",
  ["$zongshij_ty_ex__jianyong1"] = "能断大事者，不拘小节。",
  ["$zongshij_ty_ex__jianyong2"] = "闲暇自得，威仪不肃。",
  ["~ty_ex__jianyong"] = "此景竟无言以对。",
}

local zhuran = General(extension, "ty_ex__zhuran", "wu", 4)
local ty_ex__danshou = fk.CreateTriggerSkill{
  name = "ty_ex__danshou",
  mute = true,
  events = {fk.TargetConfirmed, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
      if event == fk.TargetConfirmed then
        if target == player and data.card.type ~= Card.TypeEquip then
          local n = 0
          local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
            local use = e.data[1]
            if use.card.type ~= Card.TypeEquip and table.contains(TargetGroup:getRealTargets(use.tos), player.id) then
              n = n + 1
            end
          end, Player.HistoryTurn)
          return n > 0
        end
      elseif event == fk.EventPhaseStart then
        return target.phase == Player.Finish and #player:getCardIds("he") >= target:getHandcardNum()
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetConfirmed then
      local n = 0
      local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
        local use = e.data[1]
        if use.card.type ~= Card.TypeEquip and table.contains(TargetGroup:getRealTargets(use.tos), player.id) then
          n = n + 1
        end
      end, Player.HistoryTurn)
      if room:askForSkillInvoke(player, self.name, nil, "#ty_ex__danshou-draw:::"..n) then
        self.cost_data = n
        return true
      end
    else
      local n = target:getHandcardNum()
      local cards = {}
      local yes = false
      if n == 0 then
        if room:askForSkillInvoke(player, self.name, nil, "#ty_ex__danshou-trigger::"..target.id) then
          yes = true
        end
      else
        cards = room:askForDiscard(player, n, n, true, self.name, true, ".", "#ty_ex__danshou-damage::"..target.id..":"..n, true)
        if #cards == n then
          yes = true
        end
      end
      if yes then
        self.cost_data = cards
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.TargetConfirmed then
      room:notifySkillInvoked(player, self.name, "drawcard")
      room:setPlayerMark(player, "@ty_ex__danshou-turn", 0)
      player:drawCards(self.cost_data, self.name)
    else
      room:notifySkillInvoked(player, self.name, "offensive")
      room:throwCard(self.cost_data, self.name, player, player)
      if not target.dead then
        room:doIndicate(player.id, {target.id})
        room:damage{
          from = player,
          to = target,
          damage = 1,
          skillName = self.name,
        }
      end
    end
  end,

  refresh_events = {fk.TargetConfirmed},
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card.type ~= Card.TypeEquip
    and player:hasSkill(self, true) and player:usedSkillTimes("ty_ex__danshou", Player.HistoryTurn) == 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
      local use = e.data[1]
      return use.card.type ~= Card.TypeEquip and table.contains(TargetGroup:getRealTargets(use.tos), player.id)
    end, Player.HistoryTurn)
    room:setPlayerMark(player, "@ty_ex__danshou-turn", #events)
  end,
}
zhuran:addSkill(ty_ex__danshou)
Fk:loadTranslationTable{
  ["ty_ex__zhuran"] = "界朱然",
  ["#ty_ex__zhuran"] = "不动之督",
  ["illustrator:ty_ex__zhuran"] = "F源",
  ["ty_ex__danshou"] = "胆守",
  [":ty_ex__danshou"] = "每回合限一次，当你成为基本牌或锦囊牌的目标后，你可以摸X张牌（X为你本回合成为基本牌或锦囊牌的目标次数）；"..
  "一名角色的结束阶段，若你本回合没有以此法摸牌，你可以弃置其手牌数的牌，对其造成1点伤害。",
  ["#ty_ex__danshou-draw"] = "胆守：你可以摸%arg张牌",
  ["#ty_ex__danshou-trigger"] = "胆守：你可以对 %dest 造成1点伤害",
  ["#ty_ex__danshou-damage"] = "胆守：你可以弃置%arg张牌，对 %dest 造成1点伤害",
  ["@ty_ex__danshou-turn"] = "胆守",

  ["$ty_ex__danshou1"] = "胆识过人而劲勇，则见敌无所畏惧",
  ["$ty_ex__danshou2"] = "胆守有余，可堪大任！",
  ["~ty_ex__zhuran"] = "义封一生……不负国家！",
}

local ty_ex__liru = General(extension, "ty_ex__liru", "qun", 3)
local ty_ex__mieji = fk.CreateActiveSkill{
  name = "ty_ex__mieji",
  anim_type = "offensive",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isNude()
  end,
  card_filter = function(self, to_select, selected, targets)
    local card = Fk:getCardById(to_select)
    return #selected == 0 and ((card.type == Card.TypeTrick and card.color == Card.Black) or card.sub_type == Card.SubtypeWeapon)
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:moveCards({
      ids = effect.cards,
      from = player.id,
      fromArea = Card.PlayerHand,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonPut,
      skillName = self.name,
    })
    local ids = room:askForDiscard(target, 1, 1, true, self.name, false, ".", "#ty_ex__mieji-discard1")
    if #ids > 0 and Fk:getCardById(ids[1]).type ~= Card.TypeTrick then
      room:askForDiscard(target, 1, 1, true, self.name, false, ".|.|.|.|.|basic,equip", "#ty_ex__mieji-discard2")
    end
  end,
}
local ty_ex__fencheng = fk.CreateActiveSkill{
  name = "ty_ex__fencheng",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = function() return "#ty_ex__mieji-prompt" end,
  card_filter = Util.FalseFunc,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local first = room:getPlayerById(effect.tos[1])
    local targets = {first}
    local temp = first.next
    while temp ~= first do
      if not temp.dead then
        table.insert(targets, temp)
      end
      temp = temp.next
    end
    table.removeOne(targets, player)
    local n = 0
    for _, target in ipairs(targets) do
      if not target.dead then
        local canDamage = (#target:getCardIds("he") < n + 1)
        if not canDamage then
          local cards = room:askForDiscard(target, n + 1, 999, true, self.name, true, ".", "#ty_ex__fencheng-discard:::"..tostring(n + 1))
          if #cards > n then
            n = #cards
          else
            canDamage = true
          end
        end
        if canDamage then
          room:damage{
            from = player,
            to = target,
            damage = 2,
            damageType = fk.FireDamage,
            skillName = self.name,
          }
          n = 0
        end
      end
    end
  end
}
ty_ex__liru:addSkill("juece")
ty_ex__liru:addSkill(ty_ex__mieji)
ty_ex__liru:addSkill(ty_ex__fencheng)
Fk:loadTranslationTable{
  ["ty_ex__liru"] = "界李儒",
  ["#ty_ex__liru"] = "魔仕",
  ["illustrator:ty_ex__liru"] = "胖虎饭票",
  ["ty_ex__mieji"] = "灭计",
  [":ty_ex__mieji"] = "出牌阶段限一次，你可以将一张武器牌或黑色锦囊牌置于牌堆顶，令一名有手牌的其他角色弃置一张牌。若其弃置的牌不为锦囊牌，其弃置一张非锦囊牌（没有则不弃）。",
  ["ty_ex__fencheng"] = "焚城",
  [":ty_ex__fencheng"] = "限定技，出牌阶段，你可以选择一名角色，从该角色开始，所有其他角色依次选择一项：1.弃置至少X张牌（X为上一名此技能的目标因此弃置的牌数+1）；2.受到2点火焰伤害。",
  ["#ty_ex__juece-choose"] = "绝策：你可以对一名没有手牌的其他角色造成1点伤害",
  ["#ty_ex__mieji-discard1"] = "灭计：弃置一张锦囊牌或依次弃置两张非锦囊牌",
  ["#ty_ex__mieji-discard2"] = "灭计：再弃置一张非锦囊牌",
  ["#ty_ex__mieji-prompt"] = "焚城：选择一名角色，从该角色开始按座位顺序结算“焚城”",
  ["#ty_ex__fencheng-discard"] = "焚城：弃置至少%arg张牌，否则受到2点火焰伤害",

  ["$juece_ty_ex__liru1"] = "所谓智斗，便是以兑子入局取势，而后成杀。",
  ["$juece_ty_ex__liru2"] = "欲成大事，当弃则弃，怎可优柔寡断？",
  ["$ty_ex__mieji1"] = "乏谋少计，别做无谓挣扎了！",
  ["$ty_ex__mieji2"] = "缺兵少粮，看你还能如何应对？",
  ["$ty_ex__fencheng1"] = "堆薪聚垛，以燃焚天之焰！",
  ["$ty_ex__fencheng2"] = "就让这熊熊烈焰，为尔等送葬！",
  ["~ty_ex__liru"] = "多行不义，必自毙。",
}

local fuhuanghou = General(extension, "ty_ex__fuhuanghou", "qun", 3, 3, General.Female)
local ty_ex__zhuikong = fk.CreateTriggerSkill{
  name = "ty_ex__zhuikong",
  anim_type = "control",
  events = {fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not target.dead and target ~= player and
    player:isWounded() and player:canPindian(target)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#ty_ex__zhuikong-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local pindian = player:pindian({target}, self.name)
    if pindian.results[target.id].winner == player then
      room:addPlayerMark(target, "@@ty_ex__zhuikong_prohibit-turn")
    elseif not player.dead then
      local slash = Fk:cloneCard("slash")
      if not target.dead and not player.dead and not target:prohibitUse(slash) and not target:isProhibited(player, slash) then
        room:useVirtualCard("slash", nil, target, player, self.name, true)
      end
    end
  end
}
local ty_ex__zhuikong_prohibit = fk.CreateProhibitSkill{
  name = "#ty_ex__zhuikong_prohibit",
  is_prohibited = function(self, from, to, card)
    return from:getMark("@@ty_ex__zhuikong_prohibit-turn") > 0 and from ~= to
  end,
}
local ty_ex__zhuikong_delay = fk.CreateTriggerSkill{
  name = "#ty_ex__zhuikong_delay",
  events = {fk.PindianResultConfirmed},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player.dead and data.from == player and data.winner ~= player and
      data.toCard and player.room:getCardArea(data.toCard) == Card.Processing then
      return data.reason == ty_ex__zhuikong.name
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player, data.toCard, true, fk.ReasonPrey)
  end,
}
ty_ex__zhuikong:addRelatedSkill(ty_ex__zhuikong_delay)
ty_ex__zhuikong:addRelatedSkill(ty_ex__zhuikong_prohibit)
fuhuanghou:addSkill(ty_ex__zhuikong)
local ty_ex__qiuyuan = fk.CreateTriggerSkill{
  name = "ty_ex__qiuyuan",
  anim_type = "defensive",
  events = {fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.card.trueName == "slash" then
      local tos = AimGroup:getAllTargets(data.tos)
      return table.find(player.room:getOtherPlayers(player), function(p)
        return p.id ~= data.from and not table.contains(tos, p.id) and not target:isProhibited(player, data.card) end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player), function(p)
      return p.id ~= data.from and not table.contains(AimGroup:getAllTargets(data.tos), p.id) and not target:isProhibited(player, data.card)
    end)
    if #targets > 0 then
      local to = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#ty_ex__qiuyuan-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local toId = self.cost_data
    local to = room:getPlayerById(toId)
    -- FIXME: fix exppattern
    local cards = table.filter(to:getCardIds("he"), function(id) return Fk:getCardById(id).type == Card.TypeBasic and Fk:getCardById(id).trueName ~= "slash" end)
    if #cards > 0 then
      local card = room:askForCard(to, 1, 1, false, self.name, true, ".|.|.|.|.|.|"..table.concat(cards, ","), "#ty_ex__qiuyuan-give::"..player.id)
      if #card > 0 then
        room:obtainCard(player, Fk:getCardById(card[1]), true, fk.ReasonGive, to.id)
        return
      end
    end
    AimGroup:addTargets(room, data, toId)
    AimGroup:setTargetDone(data.tos, toId)
    local e = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if e then
      local _data = e.data[1]
      _data.disresponsiveList = _data.disresponsiveList or {}
      table.insertIfNeed(_data.disresponsiveList, toId)
    end
  end,
}
fuhuanghou:addSkill(ty_ex__qiuyuan)
Fk:loadTranslationTable{
  ["ty_ex__fuhuanghou"] = "界伏皇后",
  ["#ty_ex__fuhuanghou"] = "孤注一掷",
  ["illustrator:ty_ex__fuhuanghou"] = "凝聚永恒",
  ["ty_ex__zhuikong"] = "惴恐",
  ["#ty_ex__zhuikong_delay"] = "惴恐",
  [":ty_ex__zhuikong"] = "其他角色的回合开始时，若你已受伤，你可以与其拼点：若你赢，本回合该角色只能对自己使用牌；若你没赢，你获得其拼点的牌，然后其视为对你使用一张【杀】。",
  ["#ty_ex__zhuikong-invoke"] = "惴恐：你可以与 %dest 拼点，若赢则其本回合使用牌只能指定自己为目标",
  ["@@ty_ex__zhuikong_prohibit-turn"] = "惴恐",
  ["ty_ex__qiuyuan"] = "求援",
  [":ty_ex__qiuyuan"] = "当你成为【杀】的目标时，你可以令另一名其他角色交给你一张除【杀】以外的基本牌，否则也成为此【杀】的目标且不能响应此【杀】。",
  ["#ty_ex__qiuyuan-choose"] = "求援：令另一名其他角色交给你一张不为【杀】的基本牌，否则其成为此【杀】额外目标",
  ["#ty_ex__qiuyuan-give"] = "求援：交给 %dest 一张不为【杀】的基本牌，否则成为此【杀】额外目标且不能响应此【杀】",

  ["$ty_ex__zhuikong1"] = "曹贼！你怎可如此不尊汉室！",
  ["$ty_ex__zhuikong2"] = "密信之事，不可被曹贼知晓。",
  ["$ty_ex__qiuyuan1"] = "陛下，我不想离开。",
  ["$ty_ex__qiuyuan2"] = "将军此事，可有希望。",
  ["~ty_ex__fuhuanghou"] = "这幽禁之地，好冷……",
}

local ty_ex__panzhangmazhong = General(extension, "ty_ex__panzhangmazhong", "wu", 4)
local ty_ex__anjian = fk.CreateTriggerSkill{
  name = "ty_ex__anjian",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash"
    and not player.room:getPlayerById(data.to):inMyAttackRange(player)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.additionalDamage = (data.additionalDamage or 0) + 1
    room:addPlayerMark(room:getPlayerById(data.to), fk.MarkArmorNullified)
    data.extra_data = data.extra_data or {}
    data.extra_data.ty_ex__anjian = data.extra_data.ty_ex__anjian or {}
    data.extra_data.ty_ex__anjian[tostring(data.to)] = (data.extra_data.ty_ex__anjian[tostring(data.to)] or 0) + 1
  end,

  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.ty_ex__anjian
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for key, num in pairs(data.extra_data.ty_ex__anjian) do
      local p = room:getPlayerById(tonumber(key))
      if p:getMark(fk.MarkArmorNullified) > 0 then
        room:removePlayerMark(p, fk.MarkArmorNullified, num)
      end
    end
    data.extra_data.ty_ex__anjian = nil
  end,
}
local ty_ex__anjian_delay = fk.CreateTriggerSkill{
  name = "#ty_ex__anjian_delay",
  refresh_events = {fk.EnterDying, fk.AfterDying},
  can_refresh = function(self, event, target, player, data)
    if player == target then
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
      if e then
        local use = e.data[1]
        if use.extra_data and use.extra_data.ty_ex__anjian and use.extra_data.ty_ex__anjian[tostring(math.floor(target.id))] then
          return true
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.EnterDying then
      player.room:addPlayerMark(player, "ty_ex__anjian_poison")
    else
      player.room:removePlayerMark(player, "ty_ex__anjian_poison")
    end
  end,
}
ty_ex__anjian:addRelatedSkill(ty_ex__anjian_delay)
local ty_ex__anjian_prohibit = fk.CreateProhibitSkill{
  name = "#ty_ex__anjian_prohibit",
  prohibit_use = function(self, player, card)
    return card and card.name == "peach" and player:getMark("ty_ex__anjian_poison") > 0
  end,
}
ty_ex__panzhangmazhong:addSkill("duodao")
ty_ex__anjian:addRelatedSkill(ty_ex__anjian_prohibit)
ty_ex__panzhangmazhong:addSkill(ty_ex__anjian)
Fk:loadTranslationTable{
  ["ty_ex__panzhangmazhong"] = "界潘璋马忠",
  ["#ty_ex__panzhangmazhong"] = "擒龙伏虎",
  ["illustrator:ty_ex__panzhangmazhong"] = "青学",
  
  ["ty_ex__anjian"] = "暗箭",
  [":ty_ex__anjian"] = "锁定技，当你使用【杀】指定一名角色为目标后，若你不在其攻击范围内，此【杀】对其造成的基础伤害值+1且无视其防具，然后若该角色因此进入濒死状态，其不能使用【桃】直到此次濒死结算结束。",

  ["$duodao_ty_ex__panzhangmazhong1"] = "宝刀配英雄，此刀志在必得！",
  ["$duodao_ty_ex__panzhangmazhong2"] = "你根本不会用刀！",
  ["$ty_ex__anjian1"] = "暗箭中人，其疮及骨！",
  ["$ty_ex__anjian2"] = "战阵之间，不厌诈伪！",
  ["~ty_ex__panzhangmazhong"] = "不知黄雀在其傍！",
}

local ty_ex__yufan = General(extension, "ty_ex__yufan", "wu", 3)
local ty_ex__zongxuan = fk.CreateTriggerSkill{
  name = "ty_ex__zongxuan",
  anim_type = "control",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      for _, move in ipairs(data) do
        if move.from == player.id and move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              if player.room:getCardArea(info.cardId) == Card.DiscardPile then
                return true
              end
            end
          end
        end
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local cards, tricks = {}, {}
    for _, move in ipairs(data) do
      if move.from == player.id and move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip)
          and room:getCardArea(info.cardId) == Card.DiscardPile then
            table.insertIfNeed(cards, info.cardId)
            if Fk:getCardById(info.cardId).type == Card.TypeTrick then
              table.insertIfNeed(tricks, info.cardId)
            end
          end
        end
      end
    end
    if #tricks > 0 then
      local tos = player.room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#ty_ex__zongxuan-choose", self.name, true)
      if #tos > 0 then
        self.cost_data = {cards, tos[1], tricks}
        return true
      end
    end
    if room:askForSkillInvoke(player, self.name, nil, "#ty_ex__zongxuan-invoke") then
      self.cost_data = {cards}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = self.cost_data[1]
    local to = self.cost_data[2]
    local top_limit
    if to then
      to = room:getPlayerById(to)
      local tricks = self.cost_data[3]
      local card = #tricks == 1 and tricks[1] or
      room:askForCardChosen(player, player, { card_data = { { "$Prey", tricks }  } }, self.name, "#ty_ex__zongxuan-get")
      room:obtainCard(to, card, true, fk.ReasonPrey)
      if player.dead then return end
      cards = table.filter(cards, function(id) return room:getCardArea(id) == Card.DiscardPile and id ~= card end)
    else
      top_limit = {1, #cards}
    end
    if #cards > 0 then
      local top = room:askForGuanxing(player, cards, top_limit, nil, self.name, true, {nil, "ty_ex__zongxuan_noput"}).top
      if #top > 0 then
        room:moveCards({
          ids = table.reverse(top),
          toArea = Card.DrawPile,
          moveReason = fk.ReasonPut,
          skillName = self.name,
          proposer = player.id,
        })
      end
    end
  end,
}
local ty_ex__zhiyan = fk.CreateTriggerSkill{
  name = "ty_ex__zhiyan",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), Util.IdMapper), 1, 1, "#ty_ex__zhiyan-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local id = to:drawCards(1, self.name)[1]
    local card = Fk:getCardById(id)
    to:showCards(card)
    room:delay(1000)
    if card.type == Card.TypeBasic and not player.dead then
      player:drawCards(1, self.name)
    end
    if card.type == Card.TypeEquip and not to.dead and U.canUseCardTo(room, to, to, card) then
      room:useCard({
        from = to.id,
        tos = {{to.id}},
        card = card,
      })
      if to:isWounded() and not to.dead then
        room:recover({
          who = to,
          num = 1,
          recoverBy = player,
          skillName = self.name
        })
      end
    end
  end,
}
ty_ex__yufan:addSkill(ty_ex__zongxuan)
ty_ex__yufan:addSkill(ty_ex__zhiyan)
Fk:loadTranslationTable{
  ["ty_ex__yufan"] = "界虞翻",
  ["#ty_ex__yufan"] = "狂直之士",
  ["illustrator:ty_ex__yufan"] = "君桓文化",
  ["ty_ex__zongxuan"] = "纵玄",
  [":ty_ex__zongxuan"] = "当你的牌因弃置而置入弃牌堆时，若其中有锦囊牌，你可以令一名其他角色获得其中一张锦囊牌，然后你可以将其余的牌中任意张置于牌堆顶。",
  ["#ty_ex__zongxuan-choose"] = "纵玄：可以令一名其他角色获得其中一张锦囊牌",
  ["#ty_ex__zongxuan-invoke"] = "纵玄：可以将其中至少一张牌置于牌堆顶",
  ["#ty_ex__zongxuan-get"]= "纵玄：获得其中一张牌",
  ["$Prey"] = "获得",
  ["ty_ex__zhiyan"] = "直言",
  [":ty_ex__zhiyan"] = "结束阶段，你可以令一名角色摸一张牌并展示之，若此牌为：基本牌，你摸一张牌；装备牌，其使用此牌并回复1点体力。",
  ["ty_ex__zongxuan_noput"] = "不置顶",
  ["#ty_ex__zhiyan-choose"] = "直言：你可以令一名角色摸一张牌并展示之，若为装备牌其使用之并回复1点体力",

  ["$ty_ex__zongxuan1"] = "天命所定，乃天数之法。",
  ["$ty_ex__zongxuan2"] = "因果循坏，已有定数。",
  ["$ty_ex__zhiyan1"] = "此事，臣有一言要讲。",
  ["$ty_ex__zhiyan2"] = "还望将军听我一言。",
  ["~ty_ex__yufan"] = "若听谏言，何至如此……",
}

-- yj2014
local chenqun = General(extension, "ty_ex__chenqun", "wei", 3)
local ty_ex__pindi = fk.CreateActiveSkill{
  name = "ty_ex__pindi",
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  prompt = function(self)
    return "#ty_ex__pindi:::"..(Self:usedSkillTimes(self.name, Player.HistoryTurn) + 1)
  end,
  interaction = function(self)
    return UI.ComboBox { choices = {"ty_ex__pindi_draw", "ty_ex__pindi_discard"} }
  end,
  can_use = function(self, player)
    return not player:isNude()
  end,
  card_filter = function(self, to_select, selected)
    if #selected == 0 and not Self:prohibitDiscard(Fk:getCardById(to_select)) then
      local mark = U.getMark(Self, "ty_ex__pindi-phase")
      return not table.contains(mark, Fk:getCardById(to_select):getTypeString())
    end
  end,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    if #selected == 0 and target:getMark("ty_ex__pindi_target-phase") == 0 then
      return self.interaction.data == "ty_ex__pindi_draw" or not target:isNude()
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local mark = U.getMark(player, "ty_ex__pindi-phase")
    table.insert(mark, Fk:getCardById(effect.cards[1]):getTypeString())
    room:setPlayerMark(player, "ty_ex__pindi-phase", mark)
    room:setPlayerMark(target, "ty_ex__pindi_target-phase", 1)
    room:throwCard(effect.cards, self.name, player)
    if not target.dead then
      local n = player:usedSkillTimes(self.name, Player.HistoryTurn)
      if self.interaction.data == "ty_ex__pindi_draw" then
        target:drawCards(n, self.name)
      else
        room:askForDiscard(target, n, n, true, self.name, false)
      end
    end
    if target:isWounded() and not player.dead then
      player:setChainState(not player.chained)
    end
  end,
}
local ty_ex__faen = fk.CreateTriggerSkill{
  name = "ty_ex__faen",
  anim_type = "drawcard",
  events = {fk.TurnedOver, fk.ChainStateChanged},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      return (event == fk.TurnedOver and target.faceup) or (event == fk.ChainStateChanged and target.chained)
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#ty_ex__faen-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    player.room:doIndicate(player.id, {target.id})
    target:drawCards(1, self.name)
  end,
}
chenqun:addSkill(ty_ex__pindi)
chenqun:addSkill(ty_ex__faen)
Fk:loadTranslationTable{
  ["ty_ex__chenqun"] = "界陈群",
  ["#ty_ex__chenqun"] = "万世臣表",
  ["illustrator:ty_ex__chenqun"] = "黯荧岛工作室",
  ["ty_ex__pindi"] = "品第",
  [":ty_ex__pindi"] = "出牌阶段每名角色限一次，你可以弃置一张本阶段未以此法弃置类型的牌并选择一名角色，令其摸X张牌或弃置X张牌"..
  "（X为本回合此技能发动次数）。若其已受伤，横置或重置你的武将牌。",
  ["ty_ex__faen"] = "法恩",
  [":ty_ex__faen"] = "当一名角色翻至正面或横置后，你可以令其摸一张牌。",
  ["#ty_ex__pindi"] = "品第：弃置一张未弃置过类别的牌，令一名角色摸牌或弃牌（%arg张）",
  ["ty_ex__pindi_draw"] = "摸牌",
  ["ty_ex__pindi_discard"] = "弃牌",
  ["#ty_ex__faen-invoke"] = "法恩：你可以令 %dest 摸一张牌",

  ["$ty_ex__pindi1"] = "以九品论才，正是栋梁之谋。",
  ["$ty_ex__pindi2"] = "置州郡中正，可为百年之政。",
  ["$ty_ex__faen1"] = "国法虽严，然不外乎于情。",
  ["$ty_ex__faen2"] = "律令如铁，亦有可商榷之处。",
  ["~ty_ex__chenqun"] = "吾身虽亡，然吾志当遗百年……",
}

local ty_ex__caozhen = General(extension, "ty_ex__caozhen", "wei", 4)
local ty_ex__sidi = fk.CreateTriggerSkill{
  name = "ty_ex__sidi",
  anim_type = "control",
  derived_piles = "ty_ex__sidi",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if target == player then
        return player.phase == Player.Finish and not player:isNude()
      else
        return target.phase == Player.Play and #player:getPile(self.name) > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if target == player then
      local card = room:askForCard(player, 1, 1, true, self.name, true, ".|.|.|.|.|trick,equip", "#ty_ex__sidi-put")
      if #card > 0 then
        self.cost_data = card
        return true
      end
    else
      local card = room:askForCard(player, 1, 1, false, self.name, true, ".|.|.|ty_ex__sidi|.|.", "#ty_ex__sidi-invoke::"..target.id, "ty_ex__sidi")
      if #card > 0 then
        self.cost_data = card
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if target == player then
      player:addToPile(self.name, self.cost_data[1], true, self.name)
    else
      room:doIndicate(player.id, {target.id})
      local color = Fk:getCardById(self.cost_data[1]):getColorString()
      room:moveCards({
        from = player.id,
        ids = self.cost_data,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = self.name,
        specialName = self.name,
      })
      local mark = U.getMark(target, "@ty_ex__sidi-phase")
      table.insertIfNeed(mark, color)
      room:setPlayerMark(target, "@ty_ex__sidi-phase", mark)
      room:setPlayerMark(player, "ty_ex__sidi_victim-phase", target.id)
    end
  end,
}
local ty_ex__sidi_prohibit = fk.CreateProhibitSkill{
  name = "#ty_ex__sidi_prohibit",
  prohibit_response = function(self, player, card)
    local mark = U.getMark(player, "@ty_ex__sidi-phase")
    return table.contains(mark, card:getColorString())
  end,
  prohibit_use = function(self, player, card)
    local mark = U.getMark(player, "@ty_ex__sidi-phase")
    return table.contains(mark, card:getColorString())
  end,
}
ty_ex__sidi:addRelatedSkill(ty_ex__sidi_prohibit)
local ty_ex__sidi_delay = fk.CreateTriggerSkill{
  name = "#ty_ex__sidi_delay",
  mute = true,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if not player.dead and player:getMark("ty_ex__sidi_victim-phase") == target.id and target.phase == Player.Play then
      local trick,slash = true,true
      player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data[1]
        if use.from == target.id then
          if use.card.type == Card.TypeTrick then
            trick = false
          elseif use.card.trueName == "slash" then
            slash = false
          end
        end
        return false
      end, Player.HistoryPhase)
      if trick or slash then
        self.cost_data = {trick = trick, slash = slash}
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data.slash and not target.dead then
      room:useVirtualCard("slash", nil, player, target, "ty_ex__sidi", true)
    end
    if self.cost_data.trick and not player.dead then
      player:drawCards(2, "ty_ex__sidi")
    end
  end,
}
ty_ex__sidi:addRelatedSkill(ty_ex__sidi_delay)
ty_ex__caozhen:addSkill(ty_ex__sidi)
Fk:loadTranslationTable{
  ["ty_ex__caozhen"] = "界曹真",
  ["#ty_ex__caozhen"] = "荷国天督",
  ["illustrator:ty_ex__caozhen"] = "凝聚永恒",
  ["ty_ex__sidi"] = "司敌",
  [":ty_ex__sidi"] = "结束阶段，你可以将一张非基本牌置于武将牌上，称为“司”。其他角色的出牌阶段开始时，你可以移去一张“司”，令其于此阶段不能使用或打出与此“司”颜色相同的牌，此阶段结束时，若其没有使用过：【杀】，你视为对其使用一张【杀】；锦囊牌，你摸两张牌。",
  ["#ty_ex__sidi-put"] = "司敌：可以将一张非基本牌置于武将牌上，称为“司”",
  ["#ty_ex__sidi-invoke"] = "司敌：可以移去一张“司”，令 %dest 此阶段不能使用或打出与此“司”颜色相同的牌",
  ["@ty_ex__sidi-phase"] = "司敌",

  ["$ty_ex__sidi1"] = "总算困住你了！",
  ["$ty_ex__sidi2"] = "你出得了手吗？",
  ["~ty_ex__caozhen"] = "未竟之业，请你们务必继续！",
}

local ty_ex__hanhaoshihuan = General(extension, "ty_ex__hanhaoshihuan", "wei", 4)
local ty_ex__shenduan = fk.CreateTriggerSkill{
  name = "ty_ex__shenduan",
  anim_type = "control",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip)
            and player.room:getCardArea(info.cardId) == Card.DiscardPile then
              local card = Fk:getCardById(info.cardId)
              if card.type ~= Card.TypeTrick and card.color == Card.Black then
                return true
              end
            end
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local ids = {}
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip)
            and player.room:getCardArea(info.cardId) == Card.DiscardPile then
            local card = Fk:getCardById(info.cardId)
            if card.type ~= Card.TypeTrick and card.color == Card.Black then
              table.insertIfNeed(ids, info.cardId)
            end
          end
        end
      end
    end
    for i = 1, #ids, 1 do
      if player.dead then break end
      local cards = table.filter(ids, function(id) return player.room:getCardArea(id) == Card.DiscardPile end)
      if #cards == 0 then break end
      self.cancel_cost = false
      self:doCost(event, nil, player, cards)
      if self.cancel_cost then
        self.cancel_cost = false
        break
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    room:delay(500)
    room:setPlayerMark(player, "ty_ex__shenduan_cards", data)
    local success, dat = room:askForUseActiveSkill(player, "ty_ex__shenduan_active", "#ty_ex__shenduan-use", true, {expand_pile = data})
    if success then
      self.cost_data = dat
      return true
    else
      self.cancel_cost = true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dat = self.cost_data
    local to = room:getPlayerById(dat.targets[1])
    room:useVirtualCard("supply_shortage", dat.cards, player, to, self.name, true)
  end,
}
local ty_ex__shenduan_active = fk.CreateActiveSkill{
  name = "ty_ex__shenduan_active",
  card_num = 1,
  target_num = 1,
  expand_pile = "ty_ex__shenduan",
  card_filter = function(self, to_select, selected)
    if #selected == 0 then
      local ids = U.getMark(Self, "ty_ex__shenduan_cards")
      return table.contains(ids, to_select)
    end
  end,
  target_filter = function (self, to_select, selected, selected_cards)
    if #selected == 0 and to_select ~= Self.id then
      local card = Fk:cloneCard("supply_shortage")
      card:addSubcards(selected_cards)
      local target = Fk:currentRoom():getPlayerById(to_select)
      return not target:isProhibited(target, card) and not Self:prohibitUse(card)
    end
  end,
}
local ty_ex__yonglue = fk.CreateTriggerSkill{
  name = "ty_ex__yonglue",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and target.phase == Player.Judge and #target:getCardIds("j") > 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#ty_ex__yonglue-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local card = #target:getCardIds("j") == 1 and target:getCardIds("j")[1] or
    room:askForCardChosen(player, target, "j", self.name)
    room:throwCard({card}, self.name, target, player)
    if player.dead or target.dead then return end
    if player:inMyAttackRange(target) then
      player:drawCards(1, self.name)
    else
      room:useVirtualCard("slash", nil, player, target, self.name, true)
    end
  end,
}
Fk:addSkill(ty_ex__shenduan_active)
ty_ex__hanhaoshihuan:addSkill(ty_ex__shenduan)
ty_ex__hanhaoshihuan:addSkill(ty_ex__yonglue)
Fk:loadTranslationTable{
  ["ty_ex__hanhaoshihuan"] = "界韩浩史涣",
  ["#ty_ex__hanhaoshihuan"] = "中军之主",
  ["illustrator:ty_ex__hanhaoshihuan"] = "alien",

  ["ty_ex__shenduan"] = "慎断",
  [":ty_ex__shenduan"] = "当你的黑色非锦囊牌因弃置而置入弃牌堆时，你可以将此牌当【兵粮寸断】使用（无距离限制）。",
  ["ty_ex__yonglue"] = "勇略",
  [":ty_ex__yonglue"] = "其他角色的判定阶段开始时，你可以弃置其判定区里的一张牌，然后若该角色：在你的攻击范围内，你摸一张牌；在你的攻击范围外，视为你对其使用一张【杀】。",
  ["#ty_ex__shenduan-use"] = "慎断：你可以将这些牌当【兵粮寸断】使用",
  ["ty_ex__shenduan_active"] = "慎断",
  ["#ty_ex__yonglue-invoke"] = "勇略：你可以弃置 %dest 判定区一张牌",

  ["$ty_ex__shenduan1"] = "行军断策需慎之又慎！",
  ["$ty_ex__shenduan2"] = "为将者务当慎行谨断！",
  ["$ty_ex__yonglue1"] = "兵势勇健，战胜攻取，无不如志！",
  ["$ty_ex__yonglue2"] = "雄才大略，举无遗策，威震四海！",
  ["~ty_ex__hanhaoshihuan"] = "末将愧对主公知遇之恩！",
}

local wuyi = General(extension, "ty_ex__wuyi", "shu", 4)
local benxi = fk.CreateTriggerSkill{
  name = "ty_ex__benxi",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase ~= Player.NotActive
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@ty_ex__benxi-turn", 1)
  end,
}
local benxi_choice = fk.CreateTriggerSkill{
  name = "#ty_ex__benxi_choice",
  mute = true,
  main_skill = benxi,
  events = {fk.AfterCardTargetDeclared},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill("ty_ex__benxi") and player.phase ~= Player.NotActive then
      for _, p in ipairs(player.room:getOtherPlayers(player)) do
        if player:distanceTo(p) > 1 then return end
      end
      return (data.card.trueName == "slash" or data.card:getSubtypeString() == "normal_trick") and
      #TargetGroup:getRealTargets(data.tos) == 1
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room

    local choices = {
      "ty_ex__benxi_choice1",
      "ty_ex__benxi_choice2",
      "ty_ex__benxi_choice3",
      "ty_ex__benxi_choice4",
      "Cancel"
    }
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "Cancel" then return end
    table.removeOne(choices, choice)
    local choice2 = room:askForChoice(player, choices, self.name)

    if choice == "ty_ex__benxi_choice1" or choice2 == "ty_ex__benxi_choice1" then
      if (data.card.name == "collateral") then return end

      local targets = U.getUseExtraTargets(room, data)
      if #targets > 0 then
        local tos = room:askForChoosePlayers(player, targets, 1, 1,
        "#ty_ex__benxi-choose:::"..data.card:toLogString(), benxi.name, true)

        if #tos > 0 then
          table.forEach(tos, function (id)
            table.insert(data.tos, {id})
          end)
        end
      end
    end

    if choice == "ty_ex__benxi_choice3" or choice2 == "ty_ex__benxi_choice3" then
      data.unoffsetableList = table.map(room.alive_players, Util.IdMapper)
    end

    local card_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if not card_event then return end

    if choice == "ty_ex__benxi_choice2" or choice2 == "ty_ex__benxi_choice2" then
      card_event.tybenxi_armor = true
      for _, p in ipairs(room.alive_players) do
        room:addPlayerMark(p, fk.MarkArmorNullified)
      end
    end

    if choice == "ty_ex__benxi_choice4" or choice2 == "ty_ex__benxi_choice4" then
      card_event.tybenxi_draw = player
    end
  end,

  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    if player ~= target then return false end
    local card_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
    return card_event and card_event.tybenxi_armor
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      room:removePlayerMark(p, fk.MarkArmorNullified)
    end
  end,
}
local benxi_effect = fk.CreateTriggerSkill{
  name = "#ty_ex__benxi_effect",
  mute = true,
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if player.dead then return false end
    local card_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
    return card_event and card_event.tybenxi_draw == player and data.card == card_event.data[1].card
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, benxi.name)
  end
}
local benxi_distance = fk.CreateDistanceSkill{
  name = "#ty_ex__benxi_distance",
  correct_func = function(self, from, to)
    return -from:getMark("@ty_ex__benxi-turn")
  end,
}
benxi:addRelatedSkill(benxi_choice)
benxi:addRelatedSkill(benxi_effect)
benxi:addRelatedSkill(benxi_distance)
wuyi:addSkill(benxi)

Fk:loadTranslationTable{
  ["ty_ex__wuyi"] = "界吴懿",
  ["#ty_ex__wuyi"] = "建兴鞍辔",
  ["illustrator:ty_ex__wuyi"] = "青岛磐蒲",
  ["ty_ex__benxi"] = "奔袭",
  [":ty_ex__benxi"] = "锁定技，当你于回合内使用牌时，本回合你至其他角色距离-1；你的回合内，若你与所有其他角色的距离均为1，你使用仅指定一个目标的"..
  "【杀】或普通锦囊牌时依次选择至多两项：1.为此牌额外指定一个目标；2.此牌无视防具；3.此牌不能被抵消；4.此牌造成伤害时，你摸一张牌。",
  ["@ty_ex__benxi-turn"] = "奔袭",
  ["#ty_ex__benxi_choice"] = "奔袭",
  ["#ty_ex__benxi_effect"] = "奔袭",

  ["#ty_ex__benxi-choose"] = "奔袭：请为此【%arg】额外指定一个目标",
  ["ty_ex__benxi_choice1"] = "此牌额外指定一个目标",
  ["ty_ex__benxi_choice2"] = "此牌无视防具",
  ["ty_ex__benxi_choice3"] = "此牌不能被抵消",
  ["ty_ex__benxi_choice4"] = "此牌造成伤害时，你摸一张牌",
  ["$ty_ex__benxi1"] = "北伐曹魏，以弱制强！",
  ["$ty_ex__benxi2"] = "引军汉中，以御敌袭！",
  ["~ty_ex__wuyi"] = "终有疲惫之时！休矣！",
}

local zhoucang = General(extension, "ty_ex__zhoucang", "shu", 4)
local ty_ex__zhongyong = fk.CreateTriggerSkill{
  name = "ty_ex__zhongyong",
  events = {fk.CardUseFinished},
  anim_type = "drawCard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target == player and data.card.trueName == "slash" and data.tos then
      local ids = player.room:getSubcardsByRule(data.card, { Card.Processing })
      if data.cardsResponded then
        for _, c in ipairs(data.cardsResponded) do
          table.insertTableIfNeed(ids, player.room:getSubcardsByRule(c, { Card.DiscardPile }))
        end
      end
      return #ids > 0
    end
  end,
  on_cost = function (self, event, target, player, data)
    local targets = table.filter(player.room.alive_players, function (p) return not table.contains(TargetGroup:getRealTargets(data.tos), p.id) and p ~= player end)
    if #targets == 0 then return false end
    local tos = player.room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#ty_ex__zhongyong-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local ids = player.room:getSubcardsByRule(data.card, { Card.Processing })
    for _, c in ipairs(data.cardsResponded or {}) do
      table.insertTableIfNeed(ids, player.room:getSubcardsByRule(c, { Card.DiscardPile }))
    end

    if #ids < 1 then
      return false
    end

    room:moveCardTo(ids, Card.PlayerHand, to, fk.ReasonGive, self.name, nil, true, player.id)
    if to.dead then return end
    if table.find(ids, function(id) return Fk:getCardById(id).color == Card.Black end) then
      to:drawCards(1, self.name)
    end
    if to.dead or player.dead then return end
    if table.find(ids, function(id) return Fk:getCardById(id).color == Card.Red end) then
      local victims = table.filter(room.alive_players, function(p) return player:inMyAttackRange(p) and to ~= p end)
      if #victims == 0 then return end
      local use = room:askForUseCard(to, "slash", "slash", "#ty_ex__zhongyong-slash::"..player.id, true,
        {exclusive_targets = table.map(victims, Util.IdMapper) , bypass_distances = true})
      if use then
        use.extraUse = true
        room:useCard(use)
      end
    end
  end,
}
zhoucang:addSkill(ty_ex__zhongyong)
Fk:loadTranslationTable{
  ["ty_ex__zhoucang"] = "界周仓",
  ["#ty_ex__zhoucang"] = "披肝沥胆",
  ["illustrator:ty_ex__zhoucang"] = "君桓文化",
  ["ty_ex__zhongyong"] = "忠勇",
  [":ty_ex__zhongyong"] = "当你使用的【杀】结算结束后，你可以将此【杀】和响应此【杀】的【闪】交给另一名其他角色，然后若你交给其获得的牌中包含：红色牌，其可以对你攻击范围内的一名角色使用一张【杀】；黑色牌，其摸一张牌。",
  ["#ty_ex__zhongyong-choose"] = "忠勇：你可以将【杀】和响应之的【闪】交给另一名其他角色",
  ["#ty_ex__zhongyong-slash"] = "忠勇：你可以对 %dest 攻击范围内一名角色使用一张【杀】",

  ["$ty_ex__zhongyong1"] = "赤兔北奔，马踏鼠胆之辈！",
  ["$ty_ex__zhongyong2"] = "青龙夜照，刀斩悖主之贼！",
  ["~ty_ex__zhoucang"] = "愿随将军赴死！",
}

local zhangsong = General(extension, "ty_ex__zhangsong", "shu", 3)
local ty_ex__xiantu = fk.CreateTriggerSkill{
  name = "ty_ex__xiantu",
  mute = true,
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self) and target.phase == Player.Play and not target.dead
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#ty_ex__xiantu-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    room:notifySkillInvoked(player, self.name)
    player:drawCards(2, self.name)
    if player:isNude() then return end
    local cards
    if #player:getCardIds("he") <= 2 then
      cards = player:getCardIds("he")
    else
      cards = room:askForCard(player, 2, 2, true, self.name, false, ".", "#ty_ex__xiantu-give::"..target.id)
    end
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(cards)
    room:obtainCard(target.id, dummy, false, fk.ReasonGive, player.id)
  end,
}
local ty_ex__xiantu_trigger = fk.CreateTriggerSkill{
  name = "#ty_ex__xiantu_trigger",
  mute = true,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target.phase == Player.Play and player:usedSkillTimes("ty_ex__xiantu", Player.HistoryPhase) > 0 and not player.dead then
      local events = player.room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function(e)
        local damage = e.data[5]
        return damage and target == damage.from
      end, Player.HistoryPhase)
      return #events == 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("ty_ex__xiantu")
    room:notifySkillInvoked(player, "ty_ex__xiantu", "negative")
    room:loseHp(player, 1, "ty_ex__xiantu")
  end,
}
ty_ex__xiantu:addRelatedSkill(ty_ex__xiantu_trigger)
zhangsong:addSkill("qiangzhi")
zhangsong:addSkill(ty_ex__xiantu)
Fk:loadTranslationTable{
  ["ty_ex__zhangsong"] = "界张松",
  ["#ty_ex__zhangsong"] = "怀璧待凤仪",
  ["illustrator:ty_ex__zhangsong"] = "匠人绘",
  ["ty_ex__xiantu"] = "献图",
  [":ty_ex__xiantu"] = "其他角色出牌阶段开始时，你可以摸两张牌，然后将两张牌交给该角色。若如此做，此阶段结束时，"..
  "若其于此阶段内没有造成过伤害，你失去1点体力。",
  ["#ty_ex__xiantu-invoke"] = "献图：你可以摸两张牌并交给 %dest 两张牌",
  ["#ty_ex__xiantu-give"] = "献图：选择交给 %dest 的两张牌",

  ["$qiangzhi_ty_ex__zhangsong1"] = "过目难忘，千载在我腹间。",
  ["$qiangzhi_ty_ex__zhangsong2"] = "吾目为镜，可照世间文字。",
  ["$ty_ex__xiantu1"] = "此图载益州山水，请君纳之。",
  ["$ty_ex__xiantu2"] = "我献梧木一株，为引凤而来。",
  ["~ty_ex__zhangsong"] = "恨未见使君，入主益州……",
}

local zhuhuan = General(extension, "ty_ex__zhuhuan", "wu", 4)
local ty_ex__fenli = fk.CreateTriggerSkill{
  name = "ty_ex__fenli",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(self) then return false end
    if data.to == Player.Draw or data.to == Player.Judge then
      return table.every(player.room:getOtherPlayers(player), function (p)
        return p:getHandcardNum() <= player:getHandcardNum() end)
    elseif data.to == Player.Play then
      return table.every(player.room:getOtherPlayers(player), function (p) return p.hp <= player.hp end)
    elseif data.to == Player.Discard and #player.player_cards[Player.Equip] > 0 then
      return table.every(player.room:getOtherPlayers(player), function (p)
        return #p.player_cards[Player.Equip] <= #player.player_cards[Player.Equip] end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local phase = "phase_discard"
    if data.to == Player.Draw or data.to == Player.Judge then
      phase = "phase_judge_and_draw"
    elseif data.to == Player.Play then
      phase = "phase_play"
    end
    return player.room:askForSkillInvoke(player, self.name, data, "#ty_ex__fenli-invoke:::"..phase)
  end,
  on_use = function(self, event, target, player, data)
    player:skip(data.to)
    if data.to == Player.Draw then
      player:skip(Player.Judge)
    elseif data.to == Player.Judge then
      player:skip(Player.Draw)
    end
    return true
  end,
}
zhuhuan:addSkill(ty_ex__fenli)
local sixPhases = {Player.Start, Player.Judge, Player.Draw, Player.Play, Player.Discard, Player.Finish}
local ty_ex__pingkou = fk.CreateTriggerSkill{
  name = "ty_ex__pingkou",
  anim_type = "offensive",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and data.to == Player.NotActive and player:hasSkill(self)
    and table.find(sixPhases, function(phase) return player.skipped_phases[phase] end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    for _, phase in ipairs(sixPhases) do
      if player.skipped_phases[phase] then
        n = n + 1
      end
    end
    if n == 0 then return false end
    local targets = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, n, "#ty_ex__pingkou-choose:::"..n, self.name, true)
    if #targets > 0 then
      self.cost_data = {targets, n}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = self.cost_data[1]
    room:sortPlayersByAction(tos)
    local n = self.cost_data[2]
    for _, pid in ipairs(tos) do
      local p = room:getPlayerById(pid)
      if not p.dead then
        room:damage{
          from = player,
          to = p,
          damage = 1,
          skillName = self.name,
        }
      end
    end
    if #tos < n and not player.dead then
      local targets = table.filter(tos, function(pid)
        return #room:getPlayerById(pid):getCardIds("e") > 0
      end)
      if #targets > 0 then
        local to = room:getPlayerById(room:askForChoosePlayers(player, targets, 1, 1, "#ty_ex__pingkou-throw", self.name, false)[1])
        local card = table.random(to:getCardIds("e"), 1)
        room:throwCard(card, self.name, to, to)
      end
    end
  end,
}
zhuhuan:addSkill(ty_ex__pingkou)
Fk:loadTranslationTable{
  ["ty_ex__zhuhuan"] = "界朱桓",
  ["#ty_ex__zhuhuan"] = "中洲拒天人",
  ["illustrator:ty_ex__zhuhuan"] = "XXX",
  ["ty_ex__fenli"] = "奋励",
  [":ty_ex__fenli"] = "若你的手牌数为全场最多，你可以跳过判定和摸牌阶段；若你的体力值为全场最多，你可以跳过出牌阶段；若你的装备区里有牌且数量为全场最多，你可以跳过弃牌阶段。",
  ["ty_ex__pingkou"] = "平寇",
  [":ty_ex__pingkou"] = "回合结束时，你可以对至多X名其他角色各造成1点伤害（X为你本回合跳过的阶段数），然后若你选择的角色数小于X，你再选择其中一名角色，令其随机弃置装备区里的一张牌。",
  ["#ty_ex__fenli-invoke"] = "平寇：你可以跳过 %arg",
  ["#ty_ex__pingkou-choose"] = "平寇：你可以对至多%arg名角色各造成1点伤害",
  ["#ty_ex__pingkou-throw"] = "平寇：令一名角色随机弃置装备区里的一张牌",
  ["phase_judge_and_draw"] = "判定和摸牌阶段",
  
  ["$ty_ex__fenli1"] = "兵威已振，怎能踟蹰不前？",
  ["$ty_ex__fenli2"] = "敌势汹汹，自当奋勇以对。",
  ["$ty_ex__pingkou1"] = "群寇蜂起，以军平之。",
  ["$ty_ex__pingkou2"] = "所到之处，寇患皆平。",
  ["~ty_ex__zhuhuan"] = "憾老死病榻，恨未马革裹尸。",
}

local ty_ex__guyong = General(extension, "ty_ex__guyong", "wu", 3)
local ty_ex__shenxing = fk.CreateActiveSkill{
  name = "ty_ex__shenxing",
  anim_type = "drawcard",
  card_num = function(self)
    return math.min(2, Self:usedSkillTimes(self.name, Player.HistoryPhase))
  end,
  target_num = 0,
  prompt = function(self)
    local n = Self:usedSkillTimes(self.name, Player.HistoryPhase)
    if n == 0 then
      return "#ty_ex__shenxing-draw"
    else
      return "#ty_ex__shenxing:::"..math.min(2, n)
    end
  end,
  can_use = Util.TrueFunc,
  card_filter = function(self, to_select, selected)
    return #selected < math.min(2, Self:usedSkillTimes(self.name, Player.HistoryPhase)) and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    if not player.dead then
      player:drawCards(1, self.name)
    end
  end
}
local ty_ex__bingyi = fk.CreateTriggerSkill{
  name = "ty_ex__bingyi",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getCardIds("h")
    player:showCards(cards)
    if player.dead then return end
    if table.every(cards, function(id) return Fk:getCardById(id).color == Fk:getCardById(cards[1]).color end) then
      local tos = room:askForChoosePlayers(player, table.map(room:getAlivePlayers(), Util.IdMapper), 1, #cards, "#ty_ex__bingyi-choose:::"..#cards, self.name, true)
      if #tos > 0 then
        for _, p in ipairs(tos) do
          room:getPlayerById(p):drawCards(1, self.name)
        end
        if table.every(cards, function(id) return Fk:getCardById(id).number == Fk:getCardById(cards[1]).number end) then
          player:drawCards(1, self.name)
        end
      end
    end
  end,
}
ty_ex__guyong:addSkill(ty_ex__shenxing)
ty_ex__guyong:addSkill(ty_ex__bingyi)
Fk:loadTranslationTable{
  ["ty_ex__guyong"] = "界顾雍",
  ["#ty_ex__guyong"] = "庙堂的玉磬",
  ["illustrator:ty_ex__guyong"] = "大佬荣",
  ["ty_ex__shenxing"] = "慎行",
  [":ty_ex__shenxing"] = "出牌阶段，你可以弃置X张牌，然后摸一张牌（X为你此阶段发动本技能次数，至多为2）。",
  ["ty_ex__bingyi"] = "秉壹",
  [":ty_ex__bingyi"] = "结束阶段开始时，你可以展示所有手牌，若均为同一颜色，你可以令至多X名角色各摸一张牌（X为你的手牌数）；若点数也相同，你摸一张牌。",
  ["#ty_ex__shenxing-draw"] = "慎行：你可以摸一张牌",
  ["#ty_ex__shenxing"] = "慎行：你可以弃置%arg张牌，摸一张牌",
  ["#ty_ex__bingyi-choose"] = "秉壹：你可以令至多%arg名角色各摸一张牌",

  ["$ty_ex__shenxing1"] = "谋而后动，行不容差。",
  ["$ty_ex__shenxing2"] = "谋略之道，需慎之又慎。",
  ["$ty_ex__bingyi1"] = "秉持心性，心口如一。",
  ["$ty_ex__bingyi2"] = "秉忠职守，一生不事二主。",
  ["~ty_ex__guyong"] = "君不可不慎呐……",
}

local sunluban = General(extension, "ty_ex__sunluban", "wu", 3, 3, General.Female)
local ty_ex__zenhui = fk.CreateTriggerSkill{
  name = "ty_ex__zenhui",
  anim_type = "control",
  events = {fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:getMark("@@ty_ex__zenhui-turn") == 0 and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and data.firstTarget and
      U.isOnlyTarget(player.room:getPlayerById(data.to), data, event) and #U.getUseExtraTargets(player.room, data, true, true) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, U.getUseExtraTargets(room, data, true, true), 1, 1,
    "#ty_ex__zenhui-choose:::"..data.card:toLogString(), self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    if not to:isNude() then
      local cards = room:askForCard(to, 1, 1, true, self.name, true, ".",
      "#ty_ex__zenhui-give::"..player.id..":"..data.card:toLogString())
      if #cards > 0 then
        room:obtainCard(player, cards[1], false, fk.ReasonPrey, to.id)
        data.from = to.id
        room:sendLog{
          type = "#ChangeUserBySkill",
          from = player.id,
          to = {to.id},
          arg = self.name,
          arg2 = data.card:toLogString(),
        }
        return
      end
    end
    AimGroup:addTargets(room, data, to.id)
    room:setPlayerMark(player, "@@ty_ex__zenhui-turn", 1)
    room:sendLog{ type = "#AddTargetsBySkill", from = player.id, to = {to.id}, arg = self.name, arg2 = data.card:toLogString() }
  end,
}
sunluban:addSkill(ty_ex__zenhui)
local ty_ex__jiaojin = fk.CreateTriggerSkill{
  name = "ty_ex__jiaojin",
  anim_type = "defensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from ~= player.id and (data.card.trueName == "slash" or data.card:isCommonTrick()) and not player:isNude() and player:getMark("@@ty_ex__jiaojin-turn") == 0
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".|.|.|.|.|equip", "#ty_ex__jiaojin-discard::"..data.from..":"..data.card:toLogString(), true)
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player)
    table.insertIfNeed(data.nullifiedTargets, player.id)
    data.extra_data = data.extra_data or {}
    local list = data.extra_data.ty_ex__jiaojin or {}
    table.insertIfNeed(list, player.id)
    data.extra_data.ty_ex__jiaojin = list
    if U.isFemale(room:getPlayerById(data.from)) then
      room:setPlayerMark(player, "@@ty_ex__jiaojin-turn", 1)
    end
  end,
}
local ty_ex__jiaojin_delay = fk.CreateTriggerSkill{
  name = "#ty_ex__jiaojin_delay",
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return not player.dead and data.extra_data and data.extra_data.ty_ex__jiaojin and table.contains(data.extra_data.ty_ex__jiaojin, player.id) and #player.room:getSubcardsByRule(data.card, {Card.Processing}) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = room:getSubcardsByRule(data.card, {Card.Processing})
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(ids)
    room:obtainCard(player, dummy, true, fk.ReasonJustMove)
  end,
}
ty_ex__jiaojin:addRelatedSkill(ty_ex__jiaojin_delay)
sunluban:addSkill(ty_ex__jiaojin)
Fk:loadTranslationTable{
  ["ty_ex__sunluban"] = "界孙鲁班",
  ["#ty_ex__sunluban"] = "为虎作伥",
  ["illustrator:ty_ex__sunluban"] = "匠人绘",
  ["ty_ex__zenhui"] = "谮毁",
  [":ty_ex__zenhui"] = "当你使用【杀】或普通锦囊牌指定一名角色为唯一目标时，你可以令能成为此牌目标的另一名其他角色选择一项：1.交给你一张牌，然后代替你成为此牌的使用者；2.也成为此牌的目标，然后你的〖谮毁〗本回合失效。",
  ["#ty_ex__zenhui-choose"] = "谮毁：选择一名能成为%arg的目标的角色",
  ["#ty_ex__zenhui-give"] = "谮毁：交给 %dest 一张牌，成为%arg的使用者；或成为%arg的目标",
  ["@@ty_ex__zenhui-turn"] = "谮毁失效",
  ["#ChangeUserBySkill"] = "由于 %arg 的效果，%arg2的使用者由 %from 改为 %to",
  ["ty_ex__jiaojin"] = "骄矜",
  [":ty_ex__jiaojin"] = "当你成为其他角色使用【杀】或普通锦囊牌的目标后，你可以弃置一张装备牌，令此牌对你无效，然后此牌结算结束后你获得此牌。若该角色为女性，你的〖骄矜〗本回合无效。",
  ["#ty_ex__jiaojin-discard"] = "骄矜：可弃置一张装备牌，令 %dest 使用的%arg对你无效，且结算后你获得之",
  ["@@ty_ex__jiaojin-turn"] = "骄矜失效",

  ["$ty_ex__zenhui1"] = "稍稍谮毁，万劫不复！",
  ["$ty_ex__zenhui2"] = "萋兮斐兮，谋欲谮人！",
  ["$ty_ex__jiaojin1"] = "凭汝之力，何不自鉴？",
  ["$ty_ex__jiaojin2"] = "万金之躯，岂容狎侮！",
  ["~ty_ex__sunluban"] = "谁敢动哀家一根寒毛！",
}

local ty_ex__caifuren = General(extension, "ty_ex__caifuren", "qun", 3, 3, General.Female)
local ty_ex__qieting = fk.CreateTriggerSkill{
  name = "ty_ex__qieting",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and target.phase == Player.Finish
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choices = {}
    if #player.room.logic:getEventsOfScope(GameEvent.Damage, 1, function(e)
      local damage = e.data[1]
      return damage.from and damage.from == target
    end, Player.HistoryTurn) == 0 then
      if target:canMoveCardsInBoardTo(player, "e") and room:askForSkillInvoke(player, self.name, nil, "#ty_ex__qieting-move:"..target.id) then
        table.insert(choices, "move")
      end
    end
    if #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
      local use = e.data[1]
      if use.from == target.id and use.tos then
        if table.find(TargetGroup:getRealTargets(use.tos), function(pid) return pid ~= target.id end) then
          return true
        end
      end
      return false
    end, Player.HistoryTurn) == 0 then
      table.insert(choices, "draw")
    end
    if #choices > 0 then
      self.cost_data = choices
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if table.contains(self.cost_data, "move") then
      room:askForMoveCardInBoard(player, target, player, self.name, "e", target)
    end
    if not player.dead and table.contains(self.cost_data, "draw") then
      player:drawCards(1, self.name)
    end
  end,
}
local ty_ex__xianzhou = fk.CreateActiveSkill{
  name = "ty_ex__xianzhou",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and #player.player_cards[Player.Equip] > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local n = #player:getCardIds("e")
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(player.player_cards[Player.Equip])
    room:obtainCard(target, dummy, false, fk.ReasonGive, player.id)
    if not player.dead and player:isWounded() then
      room:recover({
        who = player,
        num = math.min(n, player:getLostHp()),
        recoverBy = player,
        skillName = self.name
      })
    end
    if player.dead or target.dead then return end
    local targets = table.filter(room:getOtherPlayers(target), function(p) return target:inMyAttackRange(p) end)
    if #targets > 0 then
      local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, n, "#ty_ex__xianzhou-choose::"..target.id..":"..n, self.name, true)
      if #tos > 0 then
        for _, p in ipairs(tos) do
          room:damage{
            from = player,
            to = room:getPlayerById(p),
            damage = 1,
            skillName = self.name,
          }
        end
      end
    end
  end,
}
ty_ex__caifuren:addSkill(ty_ex__qieting)
ty_ex__caifuren:addSkill(ty_ex__xianzhou)
Fk:loadTranslationTable{
  ["ty_ex__caifuren"] = "界蔡夫人",
  ["#ty_ex__caifuren"] = "襄江的蒲苇",
  ["illustrator:ty_ex__caifuren"] = "合子映画",
  ["ty_ex__qieting"] = "窃听",
  [":ty_ex__qieting"] = "其他角色的回合结束时，若其本回合：没有造成过伤害，你可以将其装备区里的一张牌置入你的装备区；没有对其他角色使用过牌，你摸一张牌。",
  ["ty_ex__xianzhou"] = "献州",
  [":ty_ex__xianzhou"] = "限定技，出牌阶段，你可以将装备区里的所有牌交给一名其他角色，然后你回复X点体力，并对其攻击范围内的至多X名角色各造成1点伤害（X为你交给其的牌数）。",
  ["#ty_ex__qieting-move"] = "窃听：你可以将 %src 装备区里的一张牌置入你的装备区",
  ["ty_ex__qieting_move"] = "窃听：将其一张装备移动给你",
  ["#ty_ex__xianzhou-choose"] = "献州：对 %dest 攻击范围内至多 %arg 名角色各造成1点伤害",

  ["$ty_ex__qieting1"] = "谋略未定，窃听以察先机。",
  ["$ty_ex__qieting2"] = "所见相同，何必谓我？",
  ["$ty_ex__xianzhou1"] = "举州请降，高枕无忧。",
  ["$ty_ex__xianzhou2"] = "州固可贵，然不及我儿安危。",
  ["~ty_ex__caifuren"] = "枉费妾身机关算尽……",
}

local jvshou = General(extension, "ty_ex__jvshou", "qun", 3)
local ty_ex__jianying = fk.CreateTriggerSkill{
  name = "ty_ex__jianying",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if player ~= target or not player:hasSkill(self) then return false end
    local room = player.room
    local logic = room.logic
    local use_event = logic:getCurrentEvent()
    local events = logic.event_recorder[GameEvent.UseCard] or Util.DummyTable
    local last_find = false
    for i = #events, 1, -1 do
      local e = events[i]
      if e.data[1].from == player.id then
        if e.id == use_event.id then
          last_find = true
        elseif last_find then
          local last_use = e.data[1]
          return data.card:compareSuitWith(last_use.card) or data.card:compareNumberWith(last_use.card)
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,

  refresh_events = {fk.AfterCardUseDeclared, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    if event == fk.AfterCardUseDeclared then
      return target == player and player:hasSkill(self, true)
    elseif event == fk.EventLoseSkill then
      return data == self
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardUseDeclared then
      room:setPlayerMark(player, "@ty_ex__jianying", {data.card:getSuitString(true), data.card:getNumberStr()})
    elseif event == fk.EventLoseSkill then
      room:setPlayerMark(player, "@ty_ex__jianying", 0)
    end
  end,
}
local ty_ex__shibei = fk.CreateTriggerSkill{
  name = "ty_ex__shibei",
  mute = true,
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(self) then return false end
    local room = player.room
    local damage_event = room.logic:getCurrentEvent()
    local mark = player:getMark("ty_ex__shibei_record-turn")
    if type(mark) ~= "table" then
      mark = {}
    end
    if #mark < 2 and not table.contains(mark, damage_event.id) then
      local damage_ids = {}
      room.logic:getEventsOfScope(GameEvent.ChangeHp, 2, function (e)
        if e.data[1] == player and e.data[3] == "damage" then
          local first_damage_event = e:findParent(GameEvent.Damage)
          if first_damage_event then
            table.insert(damage_ids, first_damage_event.id)
            return true
          end
        end
        return false
      end, Player.HistoryTurn)
      if #damage_ids > #mark then
        mark = damage_ids
        room:setPlayerMark(player, "ty_ex__shibei_record-turn", mark)
      end
    end
    return table.contains(mark, damage_event.id) and not (mark[1] == damage_event.id and not player:isWounded())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("ty_ex__shibei_record-turn")
    if type(mark) ~= "table" or #mark == 0 then return false end
    local damage_event = room.logic:getCurrentEvent():findParent(GameEvent.Damage, true)
    if not damage_event then return false end
    if mark[1] == damage_event.id then
      player:broadcastSkillInvoke(self.name, 1)
      room:notifySkillInvoked(player, self.name)
      room:recover{
        who = player,
        num = 1,
        skillName = self.name
      }
    end
    if #mark > 1 and mark[2] == damage_event.id then
      player:broadcastSkillInvoke(self.name, 2)
      room:notifySkillInvoked(player, self.name, "negative")
      room:loseHp(player, 1, self.name)
    end
  end,
}
jvshou:addSkill(ty_ex__jianying)
jvshou:addSkill(ty_ex__shibei)

Fk:loadTranslationTable{
  ["ty_ex__jvshou"] = "界沮授",
  ["#ty_ex__jvshou"] = "监军谋国",
  ["illustrator:ty_ex__jvshou"] = "鲨鱼嚼嚼",
  ["ty_ex__jianying"] = "渐营",
  [":ty_ex__jianying"] = "当你使用牌时，若此牌与你使用的上一张牌点数或花色相同，你可以摸一张牌。",
  ["ty_ex__shibei"] = "矢北",
  [":ty_ex__shibei"] = "锁定技，当你受到伤害后，若此次伤害：是你本回合受到的第一次伤害，你回复1点体力；是你本回合受到的第二次伤害，你失去1点体力。",

  ["@ty_ex__jianying"] = "渐营",

  ["$ty_ex__jianying1"] = "步步为营，缓缓而进。",
  ["$ty_ex__jianying2"] = "以强击弱，何必心急？",
  ["$ty_ex__shibei1"] = "主公在北，吾心亦在北！",
  ["$ty_ex__shibei2"] = "宁向北而死，不面南而生。",
  ["~ty_ex__jvshou"] = "身处河南，魂归河北……",
}
--yj2015
local caorui = General(extension, "ty_ex__caorui", "wei", 3)
local ty_ex__xingshuai = fk.CreateTriggerSkill{
  name = "ty_ex__xingshuai$",
  anim_type = "defensive",
  frequency = Skill.Limited,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
      not table.every(player.room:getOtherPlayers(player), function(p) return p.kingdom ~= "wei" end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p.kingdom == "wei" and room:askForSkillInvoke(p, self.name, data, "#xingshuai-invoke::"..player.id) then
        table.insert(targets, p)
      end
    end
    if #targets > 0 then
      for _, p in ipairs(targets) do
        room:recover{
          who = player,
          num = 1,
          recoverBy = p,
          skillName = self.name
        }
      end
    end
    if not player.dying then
      for _, p in ipairs(targets) do
        room:damage{
          to = p,
          damage = 1,
          skillName = self.name,
        }
      end
    end
  end,

  refresh_events = {fk.Deathed},
  can_refresh = function(self, event, target, player, data)
    return player:usedSkillTimes(self.name, Player.HistoryGame) > 0 and data.damage and data.damage.from and
      data.damage.from:getMark("@@mingjian-turn") > 0 and data.damage.from.phase ~= Player.NotActive
  end,
  on_refresh = function(self, event, target, player, data)
    player:setSkillUseHistory(self.name, 0, Player.HistoryGame)
  end,
}

local ty_ex__mingjian = fk.CreateActiveSkill{
  name = "ty_ex__mingjian",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  prompt = "#ty_ex__mingjian-active",
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:moveCardTo(player:getCardIds(Player.Hand), Player.Hand, target, fk.ReasonGive, self.name, nil, false, player.id)
    room:addPlayerMark(target, "@@" .. self.name, 1)
  end,
}

local ty_ex__mingjian_record = fk.CreateTriggerSkill{
  name = "#ty_ex__mingjian_record",

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return player == target and player:getMark("@@ty_ex__mingjian") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local x = player:getMark("@@ty_ex__mingjian")
    room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, x)
    room:addPlayerMark(player, MarkEnum.SlashResidue .. "-turn", x)

    local turn_event = room.logic:getCurrentEvent()
    turn_event:addCleaner(function()
      room:removePlayerMark(player, "@@ty_ex__mingjian", x)
    end)
  end,
}

local ty_ex__huituo = fk.CreateTriggerSkill{
  name = "ty_ex__huituo",
  anim_type = "masochism",
  events = {fk.Damaged, fk.Damage},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.Damaged then
      return target == player
    elseif event == fk.Damage then
      if target and target:getMark("@@ty_ex__mingjian") > 0 and target.phase ~= Player.NotActive then
        local room = player.room
        local damage_event = room.logic:getCurrentEvent()
        if not damage_event then return false end
        local x = target:getMark("ty_ex__huituo_record-trun")
        if x == 0 then
          room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
            local reason = e.data[3]
            if reason == "damage" then
              local first_damage_event = e:findParent(GameEvent.Damage)
              if first_damage_event and first_damage_event.data[1].from == target then
                x = first_damage_event.id
                room:setPlayerMark(target, "ty_ex__huituo_record-trun", x)
                return true
              end
            end
          end, Player.HistoryTurn)
        end
        return damage_event.id == x
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper),
      1, 1, "#ty_ex__huituo-choose:::" .. tostring(data.damage), self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local judge = {
      who = to,
      reason = self.name,
      pattern = ".",
    }
    room:judge(judge)
    if to.dead then return false end
    if judge.card.color == Card.Red then
      if to:isWounded() then
        room:recover({
          who = to,
          num = 1,
          recoverBy = player,
          skillName = self.name
        })
      end
    elseif judge.card.color == Card.Black then
      to:drawCards(data.damage, self.name)
    end
  end,
}

ty_ex__mingjian:addRelatedSkill(ty_ex__mingjian_record)
caorui:addSkill(ty_ex__huituo)
caorui:addSkill(ty_ex__mingjian)
caorui:addSkill("xingshuai")
--caorui:addSkill(ty_ex__xingshuai)

Fk:loadTranslationTable{
  ["ty_ex__caorui"] = "界曹叡",
  ["#ty_ex__caorui"] = "天资的明君",
  ["illustrator:ty_ex__caorui"] = "君桓文化",
  ["ty_ex__huituo"] = "恢拓",
  [":ty_ex__huituo"] = "当你受到伤害后，你可以令一名角色判定，若结果为：红色，其回复1点体力；黑色，其摸X张牌（X为伤害值）。",
  ["ty_ex__mingjian"] = "明鉴",
  [":ty_ex__mingjian"] = "出牌阶段限一次，你可以将所有手牌交给一名其他角色，然后该角色下回合：使用【杀】的次数上限和手牌上限+1；"..
  "首次造成伤害后，你可以发动〖恢拓〗。",

  ["#ty_ex__huituo-choose"] = "你可以发动 恢拓，令一名角色判定，若为红色，其回复1点体力；黑色，其摸%arg张牌",

  ["#ty_ex__mingjian-active"] = "发动 明鉴，将所有手牌交给一名角色，令其下个回合获得增益",
  ["@@ty_ex__mingjian"] = "明鉴",

  ["$ty_ex__huituo1"] = "拓土复疆，扬大魏鸿威！",
  ["$ty_ex__huituo2"] = "制律弘法，固天下社稷！",
  ["$ty_ex__mingjian1"] = "敌将寇边，还请将军领兵御之。",
  ["$ty_ex__mingjian2"] = "逆贼滔乱，须得阁下出手相助。",
  ["$xingshuai_ty_ex__caorui1"] = "家国兴衰，与君共担！",
  ["$xingshuai_ty_ex__caorui2"] = "携君并进，共克此难！",
  ["~ty_ex__caorui"] = "胸有宏图待展，奈何命数已尽……",
}

local caoxiu = General(extension, "ty_ex__caoxiu", "wei", 4)
local ty_ex__qingxi = fk.CreateTriggerSkill{
  name = "ty_ex__qingxi",
  events = {fk.TargetSpecified},
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (data.card.trueName == "slash" or data.card.trueName == "duel")
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    for _, p in ipairs(room.alive_players) do
      if player:inMyAttackRange(p) then
        n = n + 1
      end
    end
    local max_num = #player:getEquipments(Card.SubtypeWeapon) > 0 and 4 or 2
    n = math.min(n, max_num)
    if player.room:askForSkillInvoke(player, self.name, data, "#ty_ex__qingxi::" .. data.to..":"..n) then
      self.cost_data = n
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    local num = self.cost_data
    if #room:askForDiscard(to, num, num, false, self.name, true, ".", "#ty_ex__qingxi-discard:::"..num) == num then
      local weapon = player:getEquipments(Card.SubtypeWeapon)
      if #weapon > 0 then
        room:throwCard(weapon, self.name, player, to)
      end
    else
      data.extra_data = data.extra_data or {}
      data.extra_data.ty_ex__qingxi = data.to
      local judge = {
        who = player,
        reason = self.name,
        pattern = ".|.|heart,diamond",
      }
      room:judge(judge)
      if judge.card.color == Card.Red then
        data.disresponsive = true
      end
    end
  end,
}
local ty_ex__qingxi_delay = fk.CreateTriggerSkill{
  name = "#ty_ex__qingxi_delay",
  events = {fk.DamageCaused},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target == player then
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
      if e then
        local use = e.data[1]
        if use.extra_data and use.extra_data.ty_ex__qingxi == data.to.id then
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
ty_ex__qingxi:addRelatedSkill(ty_ex__qingxi_delay)
caoxiu:addSkill("qianju")
caoxiu:addSkill(ty_ex__qingxi)
Fk:loadTranslationTable{
  ["ty_ex__caoxiu"] = "界曹休",
  ["#ty_ex__caoxiu"] = "千里骐骥",
  ["illustrator:ty_ex__caoxiu"] = "写之火工作室",
  ["ty_ex__qingxi"] = "倾袭",
  [":ty_ex__qingxi"] = "当你使用【杀】或【决斗】指定一名角色为目标后，你可以令其选择一项：1.弃置等同于你攻击范围内的角色数张手牌（至多为2，若你武器区里有武器牌则改为至多为4），然后弃置你装备区里的武器牌；2.令此牌对其造成的基础伤害值+1且你进行一次判定，若结果为红色，该角色不能响应此牌。",
  ["#ty_ex__qingxi"] = "倾袭：可令 %dest 选一项：1.弃 %arg 张手牌并弃置你的武器；2.伤害+1且你判定，为红不能响应",
  ["#ty_ex__qingxi-discard"] = "倾袭：你需弃置 %arg 张手牌，否则伤害+1且其判定，结果为红你不能响应",

  ["$ty_ex__qingxi1"] = "虎豹骑倾巢而动，安有不胜之理？",
  ["$ty_ex__qingxi2"] = "任尔等固若金汤，虎豹骑可破之！",
  ["~ty_ex__caoxiu"] = "奈何痈发背薨！",
}

local ty_ex__zhongyao = General(extension, "ty_ex__zhongyao", "wei", 3)
local ty_ex__huomo = fk.CreateViewAsSkill{
  name = "ty_ex__huomo",
  pattern = ".|.|.|.|.|basic",
  prompt = function ()
    return "#ty_ex__huomo-card"
  end,
  interaction = function()
    local names = {}
    local mark = U.getMark(Self, "ty_ex__huomo-turn")
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if ((Fk.currentResponsePattern == nil and Self:canUse(card)) or
      (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card))) then
        if card.type == Card.TypeBasic and not table.contains(mark, card.trueName) then
          table.insertIfNeed(names, card.name)
        end
      end
    end
    if #names == 0 then return false end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function (self, to_select, selected)
    local card = Fk:getCardById(to_select)
    return #selected == 0 and card.type ~= Card.TypeBasic and card.color == Card.Black
  end,
  before_use = function (self, player, use)
    local room = player.room
    local mark = U.getMark(player, "ty_ex__huomo-turn")
    table.insert(mark, use.card.trueName)
    room:setPlayerMark(player, "ty_ex__huomo-turn", mark)
    local put = use.card:getMark(self.name)
    if put ~= 0 and table.contains(player:getCardIds("he"), put) then
      room:moveCards({
        ids = {put},
        from = player.id,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonPut,
        skillName = self.name,
        proposer = player.id,
      })
    end
  end,
  view_as = function(self, cards)
    if not self.interaction.data or #cards ~= 1 then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:setMark(self.name, cards[1])
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    return not player:isNude()
  end,
  enabled_at_response = function(self, player, response)
    return not response and not player:isNude()
  end,
}
ty_ex__zhongyao:addSkill(ty_ex__huomo)
ty_ex__zhongyao:addSkill("zuoding")
Fk:loadTranslationTable{
  ["ty_ex__zhongyao"] = "界钟繇",
  ["#ty_ex__zhongyao"] = "正楷萧曹",
  ["illustrator:ty_ex__zhongyao"] = "匠人绘",
  ["ty_ex__huomo"] = "活墨",
  [":ty_ex__huomo"] = "当你需要使用基本牌时（每种牌名每回合限一次），你可以将一张黑色非基本牌置于牌堆顶，视为使用此基本牌。",
  ["#ty_ex__huomo-card"] = "活墨：将一张黑色非基本牌置于牌堆顶",

  ["$ty_ex__huomo1"] = "笔墨抒胸臆，妙手成汗青。",
  ["$ty_ex__huomo2"] = "胸蕴大家之行，则下笔如有神助。",
  ["$zuoding_ty_ex__zhongyao1"] = "腹有大才，可助阁下成事。",
  ["$zuoding_ty_ex__zhongyao2"] = "胸有良策，可济将军之危。",
  ["~ty_ex__zhongyao"] = "人有寿终日，笔有墨尽时。",
}

local quancong = General(extension, "ty_ex__quancong", "wu", 4)
local ty_ex__yaoming = fk.CreateTriggerSkill{
  name = "ty_ex__yaoming",
  anim_type = "control",
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:getMark("ty_ex__yaoming_"..event.."-turn") == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local _, dat = room:askForUseActiveSkill(player, "ty_ex__yaoming_active", "#ty_ex__yaoming-invoke", true)
    if dat then
      self.cost_data = {player:getMark(self.name), dat.targets[1]}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "ty_ex__yaoming_"..event.."-turn", 1)
    local choice = self.cost_data[1]
    local to = room:getPlayerById(self.cost_data[2])
    if choice == "ty_ex__yaoming_throw" then
      local cid = room:askForCardChosen(player, to, "h", self.name)
      room:throwCard({cid}, self.name, to, player)
    elseif choice == "ty_ex__yaoming_draw" then
      to:drawCards(1, self.name)
    else
      local n = #room:askForDiscard(to, 0, 2, true, self.name, true, ".", "#ty_ex__yaoming-recast")
      if n > 0 and not to.dead then
        to:drawCards(n, self.name)
      end
    end
  end,
}
local ty_ex__yaoming_active = fk.CreateActiveSkill{
  name = "ty_ex__yaoming_active",
  card_num = 0,
  target_num = 1,
  interaction = function()
    return UI.ComboBox {choices = {"ty_ex__yaoming_throw", "ty_ex__yaoming_draw", "ty_ex__yaoming_recast" } }
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected ~= 0 then return false end
    local to = Fk:currentRoom():getPlayerById(to_select)
    if self.interaction.data == "ty_ex__yaoming_throw" then
      return Self.id ~= to_select and not to:isKongcheng()
    elseif self.interaction.data == "ty_ex__yaoming_draw" then
      return Self.id ~= to_select
    else
      return true
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:setPlayerMark(player, "ty_ex__yaoming", self.interaction.data)
  end,
}
Fk:addSkill(ty_ex__yaoming_active)
quancong:addSkill(ty_ex__yaoming)
Fk:loadTranslationTable{
  ["ty_ex__quancong"] = "界全琮",
  ["#ty_ex__quancong"] = "慕势耀族",
  ["illustrator:ty_ex__quancong"] = "YanBai",
  ["ty_ex__yaoming"] = "邀名",
  [":ty_ex__yaoming"] = "每回合每项限一次，当你造成或受到伤害后，你可以选择一项：1.弃置一名其他角色的一张手牌；2.令一名其他角色摸一张牌；3.令一名角色弃置至多两张牌再摸等量的牌。",
  ["#ty_ex__yaoming-invoke"] = "可以发动“邀名”",
  ["ty_ex__yaoming_throw"] = "弃置一名其他角色的一张手牌",
  ["ty_ex__yaoming_draw"] = "令一名其他角色摸一张牌",
  ["ty_ex__yaoming_recast"] = "令一名角色弃置至多两张牌再摸等量的牌",
  ["ty_ex__yaoming_active"] = "邀名",
  ["#ty_ex__yaoming-recast"] = "邀名：可以弃置至多两张牌再摸等量的牌",
  ["$ty_ex__yaoming1"] = "养威持重，不营小利。",
  ["$ty_ex__yaoming2"] = "则天而行，作功邀名。",
  ["~ty_ex__quancong"] = "邀名射利，内伤骨体，外乏筋肉。",
}

local sunxiu = General(extension, "ty_ex__sunxiu", "wu", 3)
local ty_ex__yanzhu = fk.CreateActiveSkill{
  name = "ty_ex__yanzhu",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    if Self:getMark(self.name) > 0 then
      return #selected == 0 and to_select ~= Self.id 
    else
      return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isNude()
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    if player:getMark(self.name) > 0 then
      room:setPlayerMark(target, "@@yanzhudamage", 1)
      return
    end
    local choices = {"ty_ex__yanzhu_choice1"}
    if #target:getCardIds("e") > 0 then
      table.insert(choices, "ty_ex__yanzhu_choice2")
    end
    local choice = room:askForChoice(target, choices, self.name, "#ty_ex__yanzhu-choice:" .. player.id)
    if choice == "ty_ex__yanzhu_choice1" then
       room:setPlayerMark(target, "@@yanzhudamage", 1)
       room:askForDiscard(target, 1, 1, true, self.name, false)
    elseif choice == "ty_ex__yanzhu_choice2" then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(target:getCardIds("e"))
      room:obtainCard(player.id, dummy, true, fk.ReasonGive, target.id)
      room:setPlayerMark(player, self.name, 1)
    end
  end,
}
local ty_ex__yanzhu_trigger = fk.CreateTriggerSkill{
  name = "#ty_ex__yanzhu_trigger",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target:getMark("@@yanzhudamage") ~= 0 
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
    local room = player.room
    room:setPlayerMark(target, "@@yanzhudamage",0)
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
     return target:getMark("@@yanzhudamage") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(target, "@@yanzhudamage",0)
  end,
}
ty_ex__yanzhu:addRelatedSkill(ty_ex__yanzhu_trigger)
local ty_ex__xingxue = fk.CreateTriggerSkill{
  name = "ty_ex__xingxue",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local n = player.hp
    if player:getMark("ty_ex__yanzhu") > 0 then
      n = player.maxHp
    end
    local tos = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), Util.IdMapper), 1, n,
      "#ty_ex__xingxue-choose:::"..n, self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(self.cost_data) do
      local to = room:getPlayerById(id)
      to:drawCards(1, self.name)
    end
    for _, id in ipairs(self.cost_data) do
      local to = room:getPlayerById(id)
      if to:getHandcardNum() > to.hp then
        local card = room:askForCard(to, 1, 1, true, self.name, false, ".", "#ty_ex__xingxue-card")
        room:moveCards({
          ids = card,
          from = id,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonJustMove,
          skillName = self.name,
        })
      end
    end
  end,
}
sunxiu:addSkill(ty_ex__yanzhu)
sunxiu:addSkill(ty_ex__xingxue)
sunxiu:addSkill("zhaofu")
Fk:loadTranslationTable{
  ["ty_ex__sunxiu"] = "界孙休",
  ["ty_ex__yanzhu"] = "宴诛",
  ["#ty_ex__yanzhu_trigger"] = "宴诛",
  [":ty_ex__yanzhu"] = "出牌阶段限一次，你可以令一名其他角色选择一项：1.弃置一张牌，其下次受到伤害的+1直到其下个回合开始；2.交给你装备区内所有的牌，"..
  "你修改〖宴诛〗为 “出牌阶段限一次，你可以选择一名其他角色，令其下次受到的伤害+1直到其下个回合开始。”和修改〖兴学〗为“X为你的体力上限”。",
  ["ty_ex__xingxue"] = "兴学",
  [":ty_ex__xingxue"] = "结束阶段，你可以令X名角色依次摸一张牌，然后其中手牌数量大于体力值的角色依次将一张牌置于牌堆顶（X为你的体力值）。",
  ["@@yanzhudamage"] = "宴诛 受伤+1",
  ["#ty_ex__yanzhu-choice"] = "宴诛：选择%src弃置一张牌或令%src获得你装备区所有牌并修改“宴诛”和“兴学”",
  ["ty_ex__yanzhu_choice1"] = "弃置一张牌",
  ["ty_ex__yanzhu_choice2"] = "令其获得你装备区里所有牌并修改宴诛和兴学",
  ["#ty_ex__xingxue-choose"] = "兴学：你可以令至多%arg名角色依次摸一张牌，然后其中手牌数量大于体力值的角色依次将一张牌置于牌堆顶",
  ["#ty_ex__xingxue-card"] = "兴学：将一张牌置于牌堆顶",

  ["$ty_ex__yanzhu1"] = "觥筹交错，杀人于无形！",
  ["$ty_ex__yanzhu2"] = "子烈设宴，意在汝项上人头！",
  ["$ty_ex__xingxue1"] = "案古置学官，以敦王化，以隆风俗。",
  ["$ty_ex__xingxue2"] = "志善好学，未来可期！",
  ["~ty_ex__sunxiu"] = "盛世未成，实为憾事！",
}

local zhuzhi = General(extension, "ty_ex__zhuzhi", "wu", 4)
local function doty_ex__anguo(player, type, source)
  local room = player.room
  if type == "draw" then
    if table.every(room.alive_players, function (p) return p:getHandcardNum() >= player:getHandcardNum() end) then
      player:drawCards(1, "ty_ex__anguo")
      return true
    end
  elseif type == "recover" then
    if player:isWounded() and table.every(room.alive_players, function (p) return p.hp >= player.hp end) then
      room:recover({
        who = player,
        num = 1,
        recoverBy = source,
        skillName = "ty_ex__anguo",
      })
      return true
    end
  elseif type == "equip" then
    if #player:getCardIds("e") < 5 and table.every(room.alive_players, function(p)
      return #p:getCardIds("e") >= #player:getCardIds("e") end) then
      local types = {Card.SubtypeWeapon, Card.SubtypeArmor, Card.SubtypeDefensiveRide, Card.SubtypeOffensiveRide, Card.SubtypeTreasure}
      local cards = {}
      for i = 1, #room.draw_pile, 1 do
        local card = Fk:getCardById(room.draw_pile[i])
        for _, t in ipairs(types) do
          if card.sub_type == t and player:getEquipment(t) == nil then
            table.insertIfNeed(cards, room.draw_pile[i])
          end
        end
      end
      if #cards > 0 then
        room:useCard({
          from = player.id,
          tos = {{player.id}},
          card = Fk:getCardById(table.random(cards)),
        })
        return true
      end
    end
  end
  return false
end
local ty_ex__anguo = fk.CreateActiveSkill{
  name = "ty_ex__anguo",
  anim_type = "support",
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
    local types = {"equip", "recover", "draw"}
    for i = 3, 1, -1 do
      if target.dead then break end
      if doty_ex__anguo(target, types[i], player) then
        table.removeOne(types, types[i])
      end
    end
    for i = #types, 1, -1 do
      if player.dead then break end
      if doty_ex__anguo(player, types[i], player) then
        table.removeOne(types, types[i])
      end
    end
    if #types ==0 and not player.dead and not player:isNude() then
      local cards = room:askForCard(player, 1, 999, true, self.name, true, ".", "#ty_ex__anguo-card")
      if #cards > 0 then
        room:recastCard(cards, player, self.name)
      end
    end
  end,
}
zhuzhi:addSkill(ty_ex__anguo)
Fk:loadTranslationTable{
  ["ty_ex__zhuzhi"] = "界朱治",
  ["#ty_ex__zhuzhi"] = "王事靡盬",
  ["illustrator:ty_ex__zhuzhi"] = "福州明暗",
  ["ty_ex__anguo"] = "安国",
  [":ty_ex__anguo"] = "出牌阶段限一次，你可以选择一名其他角色，若其手牌数为全场最少，其摸一张牌；体力值为全场最低，回复1点体力；"..
  "装备区内牌数为全场最少，随机使用一张装备牌。然后若该角色有未执行的效果且你满足条件，你执行之。若双方执行了全部分支，你可以重铸任意张牌。",
  ["#ty_ex__anguo-card"] = "安国：你可以重铸任意张牌",

  ["$ty_ex__anguo1"] = "非武不可安邦，非兵不可定国。",
  ["$ty_ex__anguo2"] = "天下纷乱，正是吾等用武之时。",
  ["~ty_ex__zhuzhi"] = "刀在人在，刀折人亡……",
}

local ty_ex__liuchen = General(extension, "ty_ex__liuchen", "shu", 4)
local ty_ex__zhanjue = fk.CreateViewAsSkill{
  name = "ty_ex__zhanjue",
  anim_type = "offensive",
  card_num = 0,
  prompt = "#ty_ex__zhanjue",
  card_filter = function(self, to_select, selected)
    return false
  end,
  view_as = function(self, cards)
    local card = Fk:cloneCard("duel")
    local cards = table.filter(Self:getCardIds("h"), function (id) return Fk:getCardById(id):getMark("@@ty_ex__qinwang-inhand-turn") == 0 end)
    card:addSubcards(cards)
    return card
  end,
  after_use = function(self, player, use)
    local room = player.room
    if not player.dead then
      player:drawCards(1, "ty_ex__zhanjue")
      room:addPlayerMark(player, "ty_ex__zhanjue-phase", 1)
    end
    if use.damageDealt then
      for _, p in ipairs(room.alive_players) do
        if use.damageDealt[p.id] then
          p:drawCards(1, "ty_ex__zhanjue")
          if p == player then
            room:addPlayerMark(player, "ty_ex__zhanjue-phase", 1)
          end
        end
      end
    end
  end,
  enabled_at_play = function(self, player)
    return player:getMark("ty_ex__zhanjue-phase") < 3 and table.find(player:getCardIds("h"), function (id) return Fk:getCardById(id):getMark("@@ty_ex__qinwang-inhand") == 0 end)
  end
}
ty_ex__liuchen:addSkill(ty_ex__zhanjue)
local ty_ex__qinwang = fk.CreateActiveSkill{
  name = "ty_ex__qinwang$",
  anim_type = "offensive",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 0,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local loyal = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if player.dead then break end
      if not p.dead and p.kingdom == "shu" and not p:isKongcheng() then
        local cards = room:askForCard(p, 1, 1, false, self.name, true, "slash", "#ty_ex__qinwang-ask:"..player.id)
        if #cards > 0 then
          table.insert(loyal, p)
          room:moveCards({
            ids = cards,
            from = p.id,
            to = player.id,
            toArea = Card.PlayerHand,
            moveReason = fk.ReasonGive,
            proposer = p.id,
            skillName = self.name,
            moveVisible = false,
          })
          if table.contains(player:getCardIds("h"), cards[1]) then
            room:setCardMark(Fk:getCardById(cards[1]), "@@ty_ex__qinwang-inhand-turn", 1)
          end
        end
      end
    end
    if not player.dead and #loyal > 0 and room:askForSkillInvoke(player, self.name, nil, "#ty_ex__qinwang-draw") then
      for _, p in ipairs(loyal) do
        if not p.dead then
          p:drawCards(1, self.name)
        end
      end
    end
  end,
}
ty_ex__liuchen:addSkill(ty_ex__qinwang)
Fk:loadTranslationTable{
  ["ty_ex__liuchen"] = "界刘谌",
  ["#ty_ex__liuchen"] = "血荐轩辕",
  ["illustrator:ty_ex__liuchen"] = "青雨",
  ["ty_ex__zhanjue"] = "战绝",
  [":ty_ex__zhanjue"] = "出牌阶段，你可以将所有手牌（至少一张）当【决斗】使用，然后此【决斗】结算结束后，你和因此【决斗】受伤的角色各摸一张牌。"..
  "若你本阶段因此技能而摸过至少三张牌，本阶段你的〖战绝〗失效。",
  ["ty_ex__qinwang"] = "勤王",
  [":ty_ex__qinwang"] = "主公技，出牌阶段限一次，你可以令其他蜀势力角色依次选择是否交给你一张【杀】，然后你可以令所有交给你【杀】的角色摸一张牌"..
  "（以此法获得的【杀】于本回合不会被〖战绝〗使用）。",
  ["#ty_ex__zhanjue"] = "战绝：你可以将除因勤王获得的牌外的所有手牌当【决斗】使用，然后你和受伤的角色各摸一张牌",
  ["#ty_ex__qinwang-ask"] = "勤王：可以交给 %src 一张【杀】",
  ["#ty_ex__qinwang-draw"] = "勤王：你可以令所有交给你【杀】的角色摸一张牌",
  ["@@ty_ex__qinwang-inhand-turn"] = "勤王",

  ["$ty_ex__zhanjue1"] = "千里锦绣江山，岂能拱手相让！",
  ["$ty_ex__zhanjue2"] = "先帝一生心血，安可坐以待毙！",
  ["$ty_ex__qinwang1"] = "泰山倾崩，可有坚贞之臣？",
  ["$ty_ex__qinwang2"] = "大江潮来，怎无忠勇之士？",
  ["~ty_ex__liuchen"] = "儿欲死战，父亲何故先降……",
}

local ty_ex__zhangyi = General(extension, "ty_ex__zhangyi", "shu", 5)
local ty_ex__wurong = fk.CreateActiveSkill{
  name = "ty_ex__wurong",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local fromCard = room:askForCard(player, 1, 1, false, self.name, false, ".", "#ty_ex__wurong-show")[1]
    local toCard = room:askForCard(target, 1, 1, false, self.name, false, ".", "#ty_ex__wurong-show")[1]
    player:showCards(fromCard)
    target:showCards(toCard)
    if Fk:getCardById(fromCard).trueName == "slash" and Fk:getCardById(toCard).name ~= "jink" then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
    end
    if Fk:getCardById(fromCard).trueName ~= "slash" and Fk:getCardById(toCard).name == "jink" then
      if not target:isNude() then
        local id = room:askForCardChosen(player, target, "he", self.name)
        room:obtainCard(player, id, false)
      end
    end
  end,
}
ty_ex__zhangyi:addSkill(ty_ex__wurong)
local ty_ex__shizhi = fk.CreateFilterSkill{
  name = "ty_ex__shizhi",
  card_filter = function(self, to_select, player, isJudgeEvent)
    return player:hasSkill(self) and player.hp == 1 and to_select.name == "jink" and
    (table.contains(player.player_cards[Player.Hand], to_select.id) or isJudgeEvent)
  end,
  view_as = function(self, to_select)
    return Fk:cloneCard("slash", to_select.suit, to_select.number)
  end,
}
local ty_ex__shizhi_trigger = fk.CreateTriggerSkill{
  name = "#ty_ex__shizhi_trigger",
  events = {fk.Damage},
  mute = true,
  frequency = Skill.Compulsory,
  can_trigger = function (self, event, target, player, data)
    return player == target and player:hasSkill("ty_ex__shizhi") and data.card and player:isWounded()
    and table.contains(data.card.skillNames, "ty_ex__shizhi")
  end,
  on_use = function (self, event, target, player, data)
    player:broadcastSkillInvoke("ty_ex__shizhi")
    player.room:notifySkillInvoked(player, "ty_ex__shizhi", "defensive")
    player.room:recover { num = 1, skillName = "ty_ex__shizhi", who = player, recoverBy = player}
  end,

  refresh_events = {fk.HpChanged},
  can_refresh = function(self, event, target, player, data)
    return player == target and player:hasSkill(self)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(player:getCardIds("h")) do
      Fk:filterCard(id, player)
    end
  end,
}
ty_ex__shizhi:addRelatedSkill(ty_ex__shizhi_trigger)
ty_ex__zhangyi:addSkill(ty_ex__shizhi)

Fk:loadTranslationTable{
  ["ty_ex__zhangyi"] = "界张嶷",
  ["#ty_ex__zhangyi"] = "通壮逾古",
  ["illustrator:ty_ex__zhangyi"] = "兴游",
  ["ty_ex__wurong"] = "怃戎",
  [":ty_ex__wurong"] = "出牌阶段限一次，你可以令一名其他角色与你同时展示一张手牌，若：你展示的是【杀】且该角色不是【闪】，你对其造成1点伤害；你展示的不是【杀】且该角色是【闪】，你获得其一张牌。",
  ["#ty_ex__wurong-show"] = "怃戎：选择一张展示的手牌",
  ["ty_ex__shizhi"] = "矢志",
  [":ty_ex__shizhi"] = "锁定技，当你的体力值为1时，你的【闪】视为【杀】；当你使用这些【杀】造成伤害后，你回复1点体力。",

  ["$ty_ex__wurong1"] = "策略以入算，果烈以立威！",
  ["$ty_ex__wurong2"] = "诈与和亲，不攻可得！",
  ["~ty_ex__zhangyi"] = "挥师未捷，杀身以报！",
}

local xiahoushi = General(extension, "ty_ex__xiahoushi", "shu", 3, 3, General.Female)
local ty_ex__qiaoshi = fk.CreateTriggerSkill{
  name = "ty_ex__qiaoshi",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self) and target.phase == Player.Finish and
      player:getHandcardNum() == target:getHandcardNum()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#ty_ex__qiaoshi-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:getCardById(player:drawCards(1, self.name)[1])
    local card1 = Fk:getCardById(target:drawCards(1, self.name)[1])
    if card.color == card1.color then
      for i = 1, 99, 1 do
        if room:askForSkillInvoke(player, self.name, nil, "#ty_ex__qiaoshi-invoke::"..target.id) then
          card = Fk:getCardById(player:drawCards(1, self.name)[1])
          card1 = Fk:getCardById(target:drawCards(1, self.name)[1])
          if card.color ~= card1.color then
            
            return
          end
        else
          return
        end
      end
    end
  end,
}
local ty_ex__yanyu = fk.CreateActiveSkill{
  name = "ty_ex__yanyu",
  anim_type = "drawcard",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).trueName == "slash"
  end,
  on_use = function(self, room, effect)
    room:recastCard(effect.cards, room:getPlayerById(effect.from), self.name)
  end,
}
local ty_ex__yanyu_record = fk.CreateTriggerSkill{
  name = "#ty_ex__yanyu_record",
  anim_type = "support",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == player.Play and player:usedSkillTimes("ty_ex__yanyu", Player.HistoryPhase) > 0 and
      not table.every(player.room:getOtherPlayers(player), function(p) return p.gender ~= General.Male end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room:getAlivePlayers(), function(p)
      return p.gender == General.Male end), Util.IdMapper), 1, 1,
      "#ty_ex__yanyu-draw:::"..math.min(3, player:usedSkillTimes("ty_ex__yanyu", Player.HistoryPhase)), self.name, true)
    if #to > 0 then
      self.cost_data = room:getPlayerById(to[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local num = math.min(3, player:usedSkillTimes("ty_ex__yanyu", Player.HistoryPhase))
    self.cost_data:drawCards(num, "ty_ex__yanyu")
  end,
}
ty_ex__yanyu:addRelatedSkill(ty_ex__yanyu_record)
xiahoushi:addSkill(ty_ex__qiaoshi)
xiahoushi:addSkill(ty_ex__yanyu)
Fk:loadTranslationTable{
  ["ty_ex__xiahoushi"] = "界夏侯氏",
  ["#ty_ex__xiahoushi"] = "采缘撷睦",
  ["illustrator:ty_ex__xiahoushi"] = "匠人绘",
  ["ty_ex__qiaoshi"] = "樵拾",
  [":ty_ex__qiaoshi"] = "其他角色的结束阶段，若其手牌数等于你，你可以与其各摸一张牌，若这两张牌颜色相同，你可以重复此流程。",
  ["ty_ex__yanyu"] = "燕语",
  [":ty_ex__yanyu"] = "①出牌阶段，你可以重铸【杀】；②出牌阶段结束时，若你于此阶段内发动过【燕语①】，则你可以令一名男性角色摸X张牌"..
  "（X为你本阶段发动过【燕语①】的次数且至多为3）。",
  ["#ty_ex__qiaoshi-invoke"] = "樵拾：你可以与 %dest 各摸一张牌",
  ["#ty_ex__yanyu_record"] = "燕语",
  ["#ty_ex__yanyu-draw"] = "燕语：你可以选择一名男性角色，令其摸%arg张牌",

  ["$ty_ex__qiaoshi1"] = "暖风细雨，心有灵犀。",
  ["$ty_ex__qiaoshi2"] = "樵采城郭外，忽见郎君来。",
  ["$ty_ex__yanyu1"] = "边功未成，还请郎君努力。",
  ["$ty_ex__yanyu2"] = "郎君有意倾心诉，妾身心中相思埋。",
  ["~ty_ex__xiahoushi"] = "天气渐寒，郎君如今安在？",
}

local guotupangji = General(extension, "ty_ex__guotupangji", "qun", 3)
local ty_ex__jigong = fk.CreateTriggerSkill{
  name = "ty_ex__jigong",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
      for i = 1, 3, 1 do
        table.insert(choices, tostring(i))
      end
     local choice = room:askForChoice(player, choices, self.name, "#ty_ex__jigong-choice")
    player:drawCards(tonumber(choice), self.name)
    room:addPlayerMark(player, "@jigong_draw-turn",tonumber(choice))
  end,

  refresh_events = {fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes(self.name, Player.HistoryPhase) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@ty_ex__jigong-turn", data.damage)
  end,
}
local ty_ex__jigong_maxcards = fk.CreateMaxCardsSkill{
  name = "#ty_ex__jigong_maxcards",
  fixed_func = function (self, player)
    if player:usedSkillTimes("ty_ex__jigong", Player.HistoryTurn) > 0 then
      return player:getMark("@ty_ex__jigong-turn")
    end
  end,
}
local ty_ex__jigong_recover = fk.CreateTriggerSkill{
  name = "#ty_ex__jigong_recover",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
      local num = player:getMark("@ty_ex__jigong-turn")
      local num1 = player:getMark("@jigong_draw-turn")
      if target == player and player:usedSkillTimes("ty_ex__jigong", Player.HistoryTurn) > 0 and player.phase == Player.Discard then
        return num >= num1 and player:isWounded()
      end
  end,
  on_use = function(self, event, target, player, data)
    player.room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = "ty_ex__jigong"
    })  
  end,
}
ty_ex__jigong:addRelatedSkill(ty_ex__jigong_maxcards)
ty_ex__jigong:addRelatedSkill(ty_ex__jigong_recover)
guotupangji:addSkill(ty_ex__jigong)
guotupangji:addSkill("shifei")
Fk:loadTranslationTable{
  ["ty_ex__guotupangji"] = "界郭图逄纪",
  ["#ty_ex__guotupangji"] = "凶蛇两端",
  ["illustrator:ty_ex__guotupangji"] = "磐蒲",
  ["ty_ex__jigong"] = "急攻",
  [":ty_ex__jigong"] = "出牌阶段开始时，你可以摸至多三张牌。若如此做，你本回合的手牌上限基数改为X，且弃牌阶段结束时，若X不小于Y，则你回复1点体力。"..
  "（X为你本回合内造成的伤害值之和，Y为你本回合内因〖急攻〗摸牌而获得的牌的数量总和）",
  ["@jigong_draw-turn"] = "急攻 摸牌数",
  ["@ty_ex__jigong-turn"] = "急攻 伤害数",
  ["#ty_ex__jigong-choice"] = "急攻:请选择你要摸的牌数量",

  ["$ty_ex__jigong1"] = "此时不战，更待何时！",
  ["$ty_ex__jigong2"] = "箭在弦上，不得不发！",
  ["$shifei_ty_ex__guotupangji1"] = "若依吾计而行，许昌旦夕可破！",
  ["$shifei_ty_ex__guotupangji2"] = "先锋怯战，非谋策之过。",
  ["~ty_ex__guotupangji"] = "主公，我还有一计啊！",
}
local gongsunyuan = General(extension, "ty_ex__gongsunyuan", "qun", 4)
local ty_ex__huaiyi = fk.CreateActiveSkill{
  name = "ty_ex__huaiyi",
  anim_type = "control",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:getMark("huaiyi-phase") < 2 and not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:addPlayerMark(player, "huaiyi-phase", 2)
    local cards = table.clone(player:getCardIds("h"))
    player:showCards(cards)
    local colors = {}
    for _, id in ipairs(cards) do
      table.insertIfNeed(colors, Fk:getCardById(id):getColorString())
    end
    if #colors < 2 then
      player:drawCards(1, self.name)
      room:removePlayerMark(player, "huaiyi-phase", 1)
    else
      local color = room:askForChoice(player, colors, self.name)
      local throw = {}
      for _, id in ipairs(cards) do
        if Fk:getCardById(id):getColorString() == color then
          table.insert(throw, id)
        end
      end
      room:throwCard(throw, self.name, player, player)
      local targets = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
        return (not p:isNude()) end), Util.IdMapper), 1, #throw, "#huaiyi-choose:::"..tostring(#throw), self.name, true)
      if #targets > 0 then
        local get = {}
        for _, p in ipairs(targets) do
          local id = room:askForCardChosen(player, room:getPlayerById(p), "he", self.name)
          table.insert(get, id)
        end
        for _, id in ipairs(get) do
          room:obtainCard(player, id, false, fk.ReasonPrey)
        end
        if #get > 1 and not player.dead then
          room:loseHp(player, 1, self.name)
        end
      end
    end
  end,
}
gongsunyuan:addSkill(ty_ex__huaiyi)
Fk:loadTranslationTable{
  ["ty_ex__gongsunyuan"] = "界公孙渊",
  ["#ty_ex__gongsunyuan"] = "狡徒悬海",
  ["illustrator:ty_ex__gongsunyuan"] = "君桓文化",
  ["ty_ex__huaiyi"] = "怀异",
  [":ty_ex__huaiyi"] = "出牌阶段限一次，你可以展示所有手牌。若仅有一种颜色，你摸一张牌，然后此技能本阶段改为“出牌阶段限两次”；"..
  "若有两种颜色，你弃置其中一种颜色的牌，然后获得至多X名角色各一张牌（X为弃置的手牌数），若你获得的牌大于一张，你失去1点体力。",

  ["$ty_ex__huaiyi1"] = "曹刘可王，孤亦可王！",
  ["$ty_ex__huaiyi2"] = "汉失其鹿，天下豪杰当共逐之。",
  ["~ty_ex__gongsunyuan"] = "大星落，君王死……",
}

return extension
