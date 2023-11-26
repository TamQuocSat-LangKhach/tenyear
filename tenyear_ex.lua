local extension = Package("tenyear_ex")
extension.extensionName = "tenyear"
local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["tenyear_ex"] = "十周年-界限突破",
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
        room:obtainCard(player, card[1], false, fk.ReasonGive)
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
  end,
  on_cost = function(self, event, target, player, data)
    local success, dat = player.room:askForUseActiveSkill(player, "ty_ex__xuanhuo_active", "#ty_ex__xuanhuo-invoke", true)
    if success then
      self.cost_data = dat
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.targets[1])
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(self.cost_data.cards)
    room:obtainCard(to, dummy, false, fk.ReasonGive)
    local slash = Fk:cloneCard("slash")
    local duel = Fk:cloneCard("duel")
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return p ~= to and (U.canUseCardTo(room, to, p, slash, true, false) or U.canUseCardTo(room, to, p, duel, true, false))
     end), Util.IdMapper)
    if #targets == 0 then
      if not to:isKongcheng() then
        local dummy2 = Fk:cloneCard("dilu")
        dummy2:addSubcards(to:getCardIds("h"))
        room:obtainCard(player, dummy2, false, fk.ReasonGive)
      end
    else
      local victim = room:askForChoosePlayers(player, targets, 1, 1, "#ty_ex__xuanhuo-choose::"..to.id, self.name, false)[1]
      room:doIndicate(to.id, {victim})
      room:setPlayerMark(to, "ty_ex__xuanhuo-phase", victim)
      local command = "AskForUseActiveSkill"
      room:notifyMoveFocus(to, "ty_ex__xuanhuo_viewas")
      local dat = {"ty_ex__xuanhuo_viewas", "#ty_ex__xuanhuo-slash:"..player.id..":"..victim, true, json.encode({})}
      local result = room:doRequest(to, command, json.encode(dat))
      room:setPlayerMark(to, "ty_ex__xuanhuo-phase", 0)
      if result ~= "" then
        dat = json.decode(result)
        room:useVirtualCard(dat.interaction_data, nil, to, room:getPlayerById(victim), self.name, true)
      else
        if not to:isKongcheng() then
          local dummy2 = Fk:cloneCard("dilu")
          dummy2:addSubcards(to:getCardIds("h"))
          room:obtainCard(player, dummy2, false, fk.ReasonGive)
        end
      end
    end
  end,
}
local ty_ex__xuanhuo_active = fk.CreateActiveSkill{
  name = "ty_ex__xuanhuo_active",
  mute = true,
  card_num = 2,
  target_num = 1,
  card_filter = function(self, to_select, selected)
    return #selected < 2 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
}
local ty_ex__xuanhuo_viewas = fk.CreateActiveSkill{
  name = "ty_ex__xuanhuo_viewas",
  interaction = function()
    local names = {}
    local victim = Self:getMark("ty_ex__xuanhuo-phase")
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if (card.trueName == "slash" or card.trueName == "duel") and
        card.skill:targetFilter(victim, {}, {}, card) and not Self:isProhibited(Fk:currentRoom():getPlayerById(victim), card) then
        table.insertIfNeed(names, card.name)
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = Util.FalseFunc,
}
Fk:addSkill(ty_ex__xuanhuo_active)
Fk:addSkill(ty_ex__xuanhuo_viewas)
fazheng:addSkill(ty_ex__enyuan)
fazheng:addSkill(ty_ex__xuanhuo)
Fk:loadTranslationTable{
  ["ty_ex__fazheng"] = "界法正",
  ["ty_ex__enyuan"] = "恩怨",
  [":ty_ex__enyuan"] = "当你获得一名其他角色至少两张牌后，你可以令其摸一张牌；当你受到1点伤害后，伤害来源需选择一项：1.交给你一张手牌，"..
  "若不为<font color='red'>♥</font>，你摸一张牌；2.其失去1点体力。",
  ["ty_ex__xuanhuo"] = "眩惑",
  [":ty_ex__xuanhuo"] = "摸牌阶段结束时，你可以交给一名其他角色两张手牌，然后该角色选择一项：1.你选择另一名是【杀】或【决斗】合法目标的其他角色，"..
  "其视为对该角色使用任意一种【杀】或【决斗】；2.交给你所有手牌。",
  ["#ty_ex__enyuan-invoke"] = "恩怨：你可以令 %dest 摸一张牌",
  ["#ty_ex__enyuan-give"] = "恩怨：你需交给 %src 一张手牌，否则失去1点体力",
  ["ty_ex__xuanhuo_active"] = "眩惑",
  ["#ty_ex__xuanhuo-invoke"] = "眩惑：你可以交出两张手牌，令目标视为使用【杀】或【决斗】或交给你所有手牌",
  ["#ty_ex__xuanhuo-choose"] = "眩惑：选择令 %dest 视为使用【杀】或【决斗】的目标",
  ["ty_ex__xuanhuo_viewas"] = "眩惑",
  ["#ty_ex__xuanhuo-slash"] = "眩惑：选择一种牌视为对 %dest 使用，否则 %src 获得你所有手牌",

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
  card_filter = Util.TrueFunc,
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
    for _, id in ipairs(effect.tos) do
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
      room:obtainCard(player.id, card, true, fk.ReasonPrey)
    end
    return true
  end
}
masu:addSkill(ty_ex__sanyao)
masu:addSkill(ty_ex__zhiman)
Fk:loadTranslationTable{
  ["ty_ex__masu"] = "界马谡",
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

Fk:loadTranslationTable{
  ["ty_ex__xushu"] = "界徐庶",
  ["ty_ex__zhuhai"] = "诛害",
  [":ty_ex__zhuhai"] = "其他角色的结束阶段，若其本回合造成过伤害，你可以将一张手牌当【杀】或【过河拆桥】对其使用。",
  ["ty_ex__qianxin"] = "潜心",
  [":ty_ex__qianxin"] = "觉醒技，当你造成伤害后，若你已受伤，你减1点体力上限，并获得〖荐言〗。",
  ["ty_ex__jianyan"] = "荐言",
  [":ty_ex__jianyan"] = "出牌阶段各限一次，你可以声明一种牌的类别或一种牌的颜色，然后将牌堆中第一张符合你声明的牌交给一名男性角色。",
}

local lingtong = General(extension, "ty_ex__lingtong", "wu", 4)
local ty_ex__xuanfeng = fk.CreateTriggerSkill{
  name = "ty_ex__xuanfeng",
  anim_type = "control",
  events = {fk.AfterCardsMove, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.AfterCardsMove then
        for _, move in ipairs(data) do
          if move.from == player.id then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerEquip then
                return true
              end
            end
          end
        end
      else
        return target == player and player.phase == Player.Discard and player:getMark("ty_ex__xuanfeng-phase") > 1
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if table.every(player.room:getOtherPlayers(player), function (p) return p:isNude() end) then return end
    return player.room:askForSkillInvoke(player, self.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targetsx = {}
    for i = 1, 2, 1 do
      local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
        return not p:isNude() end), Util.IdMapper)
      if #targets > 0 then
        local tos = room:askForChoosePlayers(player, targets, 1, 1, "#ty_ex__xuanfeng-choose", self.name, true)
        if #tos > 0 then
          room:doIndicate(player.id, tos)
          local card = room:askForCardChosen(player, room:getPlayerById(tos[1]), "he", self.name)
          room:throwCard({card}, self.name, room:getPlayerById(tos[1]), player)
          if player.phase ~= Player.NotActive then
            table.insert(targetsx, tos[1])
          end
        end
      end
    end
    if #targetsx > 0 then
      local tos = room:askForChoosePlayers(player, targetsx, 1, 1, "#ty_ex__xuanfeng-damage", self.name, true)
      if #tos > 0 then
        room:damage{
          from = player,
          to = room:getPlayerById(tos[1]),
          damage = 1,
          skillName = self.name,
        }
      end
    else return end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self) and player.phase == Player.Discard
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason == fk.ReasonDiscard then
        player.room:addPlayerMark(player, "ty_ex__xuanfeng-phase", #move.moveInfo)
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
  ["ty_ex__xuanfeng"] = "旋风",
  [":ty_ex__xuanfeng"] = "当你失去装备区里的牌，或于弃牌阶段弃掉两张或更多的牌时，你可以依次弃置一至两名角色的共计两张牌。"..
  "若此时是你的回合内，则你可以对其中一名角色造成1点伤害。",
  ["#ty_ex__xuanfeng-choose"] = "旋风：你可以依次弃置一至两名角色的共计两张牌",
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
      if #target1.player_cards[Player.Equip] == 0 and #target2.player_cards[Player.Equip] == 0 then
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
    local cards1 = table.clone(target1.player_cards[Player.Equip])
    local cards2 = table.clone(target2.player_cards[Player.Equip])
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
    if math.abs(#target1.player_cards[Player.Equip] - #target2.player_cards[Player.Equip]) > player:getLostHp() then
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
    return target == player and player:hasSkill(self) and data.card.trueName == "slash" and
      not player.room:getPlayerById(data.to):isNude()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    local cards = room:askForCardsChosen(player, to, 0, to.hp, "he", self.name)
    if #cards > 0 then
       local equipC = table.filter(cards, function (id)
        return Fk:getCardById(id).type == Card.TypeEquip
      end)
       if #equipC > 0 then
         room:fillAG(player, equipC)
         local id = room:askForAG(player, equipC, false, self.name)
        room:closeAG(player)
        room:throwCard({id}, self.name, to, player)
         table.removeOne(cards, id)
       end
       to:addToPile(self.name, cards, false, self.name)
       local drawtrick = table.filter(cards, function (id)
        return Fk:getCardById(id).type == Card.TypeTrick
      end)
       if #drawtrick > 0 then
         player:drawCards(1, self.name)
       end   
    end
  end,
}
local ty_ex__pojun_delay = fk.CreateTriggerSkill{
  name = "#ty_ex__pojun_delay",
  mute = true,
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return data.to == Player.NotActive and #player:getPile("ty_ex__pojun") > 0
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
  ["ty_ex__pojun"] = "破军",
  [":ty_ex__pojun"] = "当你于出牌阶段内使用【杀】指定一个目标后，你可以将其至多X张牌扣置于该角色的武将牌旁（X为其体力值）,若其中有：装备牌，你弃置其中一张牌；锦囊牌，你摸一张牌。"..
  "若如此做，当前回合结束后，该角色获得其武将牌旁的所有牌。",

  ["$ty_ex__pojun1"] = "奋身出命，为国建功！",
  ["$ty_ex__pojun2"] = "披甲持戟，先登陷陈！",
  ["~ty_ex__xusheng"] = "文向已无憾矣！",
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
    room:obtainCard(target, Fk:getCardById(effect.cards[1]), false, fk.ReasonGive)
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

  ["$zhenlie_ty_ex__wangyi1"] = "女子，亦可有坚贞气节！",
  ["$zhenlie_ty_ex__wangyi2"] = "品德端正，心中不移。",
  ["$miji_ty_ex__wangyi1"] = "秘计已成，定助夫君得胜。",
  ["$miji_ty_ex__wangyi2"] = "秘计在此，将军必凯旋而归。",
  ["~ty_ex__wangyi"] = "秘计不成，此城难守……",
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
local ty_ex__fuhun_record = fk.CreateTriggerSkill{
  name = "#ty_ex__fuhun_record",

  refresh_events = {fk.Damage, fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    if target == player then
      if event == fk.Damage then
        return player:hasSkill(self) and data.card and table.contains(data.card.skillNames, "ty_ex__fuhun") and player.phase == Player.Play and
          not (player:hasSkill("ex__wusheng", true) and player:hasSkill("ex__paoxiao", true))
      else
        return player:hasSkill(self.name, true)
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.Damage then
      player.room:handleAddLoseSkills(player, "ex__wusheng|ex__paoxiao", nil, true, false)
    else
      player.room:handleAddLoseSkills(player, "-ex__wusheng|-ex__paoxiao", nil, true, false)
    end
  end,
}
ty_ex__fuhun:addRelatedSkill(ty_ex__fuhun_record)
guanxingzhangbao:addSkill(ty_ex__fuhun)
guanxingzhangbao:addSkill(ty_ex__tongxin)
guanxingzhangbao:addRelatedSkill("ex__wusheng")
guanxingzhangbao:addRelatedSkill("ex__paoxiao")
Fk:loadTranslationTable{
  ["ty_ex__guanxingzhangbao"] = "界关兴张苞",
  ["ty_ex__tongxin"] = "同心",
  [":ty_ex__tongxin"] = "锁定技，你的攻击范围+2。",
  ["ty_ex__fuhun"] = "父魂",
  [":ty_ex__fuhun"] = "你可以将两张手牌当【杀】使用或打出；当你于出牌阶段内以此法造成伤害后，本回合获得〖武圣〗和〖咆哮〗。",

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
  events = {fk.AfterCardUseDeclared, fk.TargetSpecifying, fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.AfterCardUseDeclared then
        return data.card.name == "slash"
      elseif event == fk.TargetSpecifying then
        return data.card.name == "fire__slash"
      else
        return data.card.trueName == "slash" and data.extra_data and data.extra_data.ty_ex__lihuo == 1 and
          player.room:getCardArea(data.card) == Card.Processing
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.AfterCardUseDeclared then
      return player.room:askForSkillInvoke(player, self.name, nil, "#ty_ex__lihuo1-invoke:::"..data.card:toLogString())
    elseif event == fk.TargetSpecifying then
      local targets = table.map(table.filter(player.room:getOtherPlayers(player), function(p)
        return not table.contains(TargetGroup:getRealTargets(data.tos), p.id) and
        data.card.skill:getDistanceLimit(p, data.card) + player:getAttackRange() >= player:distanceTo(p) and
        not player:isProhibited(p, data.card) end), Util.IdMapper)
      if #targets == 0 then return false end
      local tos = player.room:askForChoosePlayers(player, targets, 1, 1, "#lihuo-choose:::"..data.card:toLogString(), self.name, true)
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
      local card = Fk:cloneCard("fire__slash")
      card.skillName = self.name
      card:addSubcard(data.card)
      data.card = card
    elseif event == fk.TargetSpecifying then
      table.insert(data.tos, self.cost_data)
    else
      player:addToPile("ty_ex__chengpu_chun", data.card, true, self.name)
    end
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "ty_ex__lihuo-turn", 1)
    data.extra_data = data.extra_data or {}
    data.extra_data.ty_ex__lihuo = player:getMark("ty_ex__lihuo-turn")
  end,
}
local ty_ex__lihuo_record = fk.CreateTriggerSkill{
  name = "#ty_ex__lihuo_record",
  events = {fk.CardUseFinished},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, "ty_ex__lihuo") and data.damageDealt
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("ty_ex__lihuo", 1)
    room:notifySkillInvoked(player, "ty_ex__lihuo", "negative")
    room:loseHp(player, 1, "ty_ex__lihuo")
  end,
}
local ty_ex__chunlao = fk.CreateTriggerSkill{
  name = "ty_ex__chunlao",
  anim_type = "support",
  expand_pile = "ty_ex__chengpu_chun",
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
    return target == player and player:hasSkill(self.name, false, true)
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
    return #selected == 0
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

local zhonghui = General(extension, "ty_ex__zhonghui", "wei", 4)
local ty_ex__quanji = fk.CreateTriggerSkill{
  name = "ty_ex__quanji",
  anim_type = "masochism",
  events = {fk.AfterCardsMove, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    
    if event == fk.AfterCardsMove and player:hasSkill(self) then
      for _, move in ipairs(data) do
        if move.from == player.id and move.to and move.to ~= player.id and move.moveReason == fk.ReasonPrey then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip or info.fromArea == Card.PlayerHand then
              self.cancel_cost = false
              self:doCost(event, target, player, data)
            end
          end
        end
      end
    elseif event == fk.Damaged and player:hasSkill(self) and target == player then
      self.cancel_cost = false
      for i = 1, data.damage do
        if self.cancel_cost then break end
        self:doCost(event, target, player, data)
      end
    else
      return false
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
    if player:hasSkill(self) then
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
    return self.interaction.data == "ty_ex__paiyi_draw" and #selected == 0 or #selected < #Self:getPile("zhonghui_quan") - 1
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
  ["$ty_ex__quanji2"] = "大丈夫行事，岂较一兵一将之得失?",
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
    local card_ids = room:getNCards(4)
    local get, throw = {}, {}
    room:moveCards({
      ids = card_ids,
      toArea = Card.Processing,
      moveReason = fk.ReasonPut,
    })
    table.forEach(room.players, function(p)
      room:fillAG(p, card_ids)
    end)
    while true do
      local sum = 0
      table.forEach(get, function(id)
        sum = sum + Fk:getCardById(id).number
      end)
      for i = #card_ids, 1, -1 do
        local id = card_ids[i]
        if sum + Fk:getCardById(id).number > 13 then
          room:takeAG(player, id, room.players)
          table.insert(throw, id)
          table.removeOne(card_ids, id)
        end
      end
      if #card_ids == 0 then break end
      local card_id = room:askForAG(player, card_ids, false, self.name)
      --if card_id == nil then break end
      room:takeAG(player, card_id, room.players)
      table.insert(get, card_id)
      table.removeOne(card_ids, card_id)
      if #card_ids == 0 then break end
    end
    table.forEach(room.players, function(p)
      room:closeAG(p)
    end)
    if #get > 0 then
      local n = 0
      for _, id in ipairs(get) do
        n = n + Fk:getCardById(id).number
      end
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(get)
      room:obtainCard(player.id, dummy, true, fk.ReasonPrey)
      if n == 13 and not player.dead then
        if not player.faceup then
          player:turnOver()
        end
        if player.chained then
          player:setChainState(false)
        end
      end
    end
    if #throw > 0 then
      room:moveCards({
        ids = throw,
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
      --因为额外阶段是逆序进行的，因此需要反着获得额外阶段才行
      player:gainAnExtraPhase(Player.Play)
      player:gainAnExtraPhase(Player.Draw)
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
      return player:hasSkill(self.name, true)
    elseif event == fk.EventAcquireSkill or event == fk.EventLoseSkill then
      return data == self
    else
      return target == player and player:hasSkill(self.name, true, true)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart or event == fk.EventAcquireSkill then
      if player:hasSkill(self.name, true) then
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
    if from:hasSkill(self.name, true) then
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
    local cards = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#ty_ex__longyin-invoke::"..target.id) 
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    target:addCardUseHistory(data.card.trueName, -1)
    if data.card.color == Card.Red then
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
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
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
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@ty_ex__qiaoshui-turn") > 0 and data.card.type ~= Card.TypeEquip and data.card.sub_type ~= Card.SubtypeDelayedTrick
  end,
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
  ["ty_ex__jianyong"] = "简雍",
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
            if table.contains(TargetGroup:getRealTargets(use.tos), player.id) then
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
        if table.contains(TargetGroup:getRealTargets(use.tos), player.id) then
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
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "ty_ex__danshou-turn", 1)
    if player:hasSkill("ty_ex__danshou", true) and player:usedSkillTimes("ty_ex__danshou", Player.HistoryTurn) == 0 then
      room:setPlayerMark(player, "@ty_ex__danshou-turn", player:getMark("ty_ex__danshou-turn"))
    end
  end,
}
zhuran:addSkill(ty_ex__danshou)
Fk:loadTranslationTable{
  ["ty_ex__zhuran"] = "界朱然",
  ["ty_ex__danshou"] = "胆守",
  [":ty_ex__danshou"] = "每回合限一次，当你成为基本牌或锦囊牌的目标后，你可以摸X张牌（X为你本回合成为牌的目标次数）；"..
  "一名角色的结束阶段，若你本回合没有以此法摸牌，你可以弃置其手牌数的牌，对其造成1点伤害。",
  ["#ty_ex__danshou-draw"] = "胆守：你可以摸%arg张牌",
  ["#ty_ex__danshou-trigger"] = "胆守：你可以对 %dest 造成1点伤害",
  ["#ty_ex__danshou-damage"] = "胆守：你可以弃置%arg张牌，对 %dest 造成1点伤害",
  ["@ty_ex__danshou-turn"] = "胆守",

  ["$ty_ex__danshou1"] = "胆识过人而劲勇，则见敌无所畏惧",
  ["$ty_ex__danshou2"] = "胆守有余，可堪大任！",
  ["~ty_ex__zhuran"] = "义封一生……不负国家！",
}
--yj2014
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
    if #selected == 0 then
      local mark = Self:getMark("ty_ex__pindi-phase")
      if mark == 0 then
        return true
      else
        return not table.contains(mark, Fk:getCardById(to_select):getTypeString())
      end
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
    local mark = player:getMark("ty_ex__pindi-phase")
    if mark == 0 then mark = {} end
    table.insert(mark, Fk:getCardById(effect.cards[1]):getTypeString())
    room:setPlayerMark(player, "ty_ex__pindi-phase", mark)
    room:setPlayerMark(target, "ty_ex__pindi_target-phase", 1)
    room:throwCard(effect.cards, self.name, player)
    local n = player:usedSkillTimes(self.name, Player.HistoryTurn)
    if self.interaction.data == "ty_ex__pindi_draw" then
      target:drawCards(n, self.name)
    else
      if #target:getCardIds("he") <= n then
        target:throwAllCards("he")
      else
        room:askForDiscard(target, n, n, true, self.name, false)
      end
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
    if target == player and player:hasSkill(self) and player.phase ~= Player.NotActive then
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

local zhangsong = General(extension, "ty_ex__zhangsong", "shu", 3)
local ty_ex__xiantu = fk.CreateTriggerSkill{
  name = "ty_ex__xiantu",
  mute = true,
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self) and target.phase == Player.Play
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
    room:obtainCard(target.id, dummy, false, fk.ReasonGive)
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
    return #selected < math.min(2, Self:usedSkillTimes(self.name, Player.HistoryPhase))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    player:drawCards(1, self.name)
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
      return target == player and player:hasSkill(self.name, true)
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
caorui:addSkill("huituo")
caorui:addSkill("mingjian")
caorui:addSkill(ty_ex__xingshuai)
Fk:loadTranslationTable{
  ["ty_ex__caorui"] = "界曹叡",
  ["ty_ex__xingshuai"] = "兴衰",
  [":ty_ex__xingshuai"] = "主公技，限定技，当你进入濒死状态时，你可令其他魏势力角色依次选择是否令你回复1点体力。选择是的角色在此次濒死结算结束后受到1点"..
  "无来源的伤害。有“明鉴”标记的角色于其回合内杀死一名角色后，此技能视为未发动过。",
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
    if #target.player_cards[Player.Equip] > 0 then
      table.insert(choices, "ty_ex__yanzhu_choice2")
    end
    local choice = room:askForChoice(target, choices, self.name, "#ty_ex__yanzhu-choice:" .. player.id)
    if choice == "ty_ex__yanzhu_choice1" then
       room:setPlayerMark(target, "@@yanzhudamage", 1)
       room:askForDiscard(target, 1, 1, true, self.name, false)
    elseif choice == "ty_ex__yanzhu_choice2" then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(target.player_cards[Player.Equip])
      room:obtainCard(player.id, dummy, true, fk.ReasonGive)
      
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
    local tos = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), Util.IdMapper), 1, n, "#ty_ex__xingxue-choose:::"..n, self.name, true)
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
  [":ty_ex__yanzhu"] = "出牌阶段限一次，你可以令一名其他角色选择一项：1.弃置一张牌并令其下次受到伤害的+1，直到其下个回合开始；2.交给你装备区内所有的牌，你修改〖宴诛〗为 “出牌阶段限一次，你可以选择一名其他角色，令其下次受到的伤害+1直到其下个回合开始。”和修改〖兴学〗为“X为你的体力上限”。",
  ["ty_ex__xingxue"] = "兴学",
  [":ty_ex__xingxue"] = "结束阶段，你可以令X名角色依次摸一张牌，然后其中手牌数量大于体力值的角色依次将一张牌置于牌堆顶（X为你的体力值）。",
  ["@@yanzhudamage"] = "宴诛 受伤+1",
  ["#ty_ex__yanzhu-choice"] = "宴诛：选择%src弃置一张牌或令%src获得你装备区所有牌并修改宴诛和兴学",
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
  card_filter = Util.FalseFunc,
  view_as = function(self)
    local card = Fk:cloneCard("duel")
    local cards = table.filter(Self:getCardIds("h"), function (id) return Fk:getCardById(id):getMark("@@ty_ex__qinwang-inhand") == 0 end)
    card:addSubcards(cards)
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    if player:getMark("ty_ex__zhanjue-turn") < 3 and not player:isKongcheng() then
      return table.find(player:getCardIds("h"), function (id) return Fk:getCardById(id):getMark("@@ty_ex__qinwang-inhand") == 0 end)
    end
  end,
}
local ty_ex__zhanjue_trigger = fk.CreateTriggerSkill{
  name = "#ty_ex__zhanjue_trigger",
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, "ty_ex__zhanjue") and data.damageDealt
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not player.dead then
      player:drawCards(1, "ty_ex__zhanjue")
      room:addPlayerMark(player, "ty_ex__zhanjue-turn", 1)
    end
    for _, p in ipairs(room.alive_players) do
      if data.damageDealt[p.id] then
        p:drawCards(1, "ty_ex__zhanjue")
        if p == player then
          room:addPlayerMark(player, "ty_ex__zhanjue-turn", 1)
        end
      end
    end
  end,
}
ty_ex__zhanjue:addRelatedSkill(ty_ex__zhanjue_trigger)
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
            proposer = player.id,
            skillName = self.name,
            moveVisible = false,
          })
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
local ty_ex__qinwang_trigger = fk.CreateTriggerSkill{
  name = "#ty_ex__qinwang_trigger",
  refresh_events = {fk.AfterCardsMove, fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return player:usedSkillTimes(ty_ex__qinwang.name, Player.HistoryTurn) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.skillName == ty_ex__qinwang.name and move.moveReason == fk.ReasonGive and move.to == player.id then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(player:getCardIds("h"), info.cardId) then
              room:setCardMark(Fk:getCardById(info.cardId), "@@ty_ex__qinwang-inhand", 1)
            end
          end
        end
      end
    else
      for _, id in ipairs(player:getCardIds("h")) do
        room:setCardMark(Fk:getCardById(id), "@@ty_ex__qinwang-inhand", 0)
      end
    end
  end,
}
ty_ex__qinwang:addRelatedSkill(ty_ex__qinwang_trigger)
ty_ex__liuchen:addSkill(ty_ex__qinwang)
Fk:loadTranslationTable{
  ["ty_ex__liuchen"] = "刘谌",
  ["ty_ex__zhanjue"] = "战绝",
  [":ty_ex__zhanjue"] = "出牌阶段，你可以将所有手牌（至少一张）当【决斗】使用，然后此【决斗】结算结束后，你和因此【决斗】受伤的角色各摸一张牌。若你本阶段因此技能而摸过至少三张牌，本阶段你的〖战绝〗失效。",
  ["ty_ex__qinwang"] = "勤王",
  [":ty_ex__qinwang"] = "主公技，出牌阶段限一次，你可以令其他蜀势力角色依次选择是否交给你一张【杀】，然后你可以令所有交给你【杀】的角色摸一张牌（以此法获得的【杀】于本回合不会被〖战绝〗使用）。",
  ["#ty_ex__qinwang-ask"] = "勤王：可以交给 %src 一张【杀】",
  ["#ty_ex__qinwang-draw"] = "勤王：你可以令所有交给你【杀】的角色摸一张牌",
  ["@@ty_ex__qinwang-inhand"] = "勤王",

  ["$ty_ex__zhanjue1"] = "千里锦绣江山，岂能拱手相让！",
  ["$ty_ex__zhanjue2"] = "先帝一生心血，安可坐以待毙！",
  ["$ty_ex__qinwang1"] = "泰山倾崩，可有坚贞之臣？",
  ["$ty_ex__qinwang2"] = "大江潮来，怎无忠勇之士？",
  ["~ty_ex__liuchen"] = "儿欲死战，父亲何故先降……",
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
    local player = room:getPlayerById(effect.from)
    room:moveCards({
      ids = effect.cards,
      from = effect.from,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,  --TODO: reason recast
    })
    player:drawCards(1, self.name)
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
      return p.gender == General.Male end), Util.IdMapper), 1, 1, "#ty_ex__yanyu-draw:::" ..  math.min(3, player:usedSkillTimes("ty_ex__yanyu", Player.HistoryPhase)), self.name, true)
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
  ["ty_ex__qiaoshi"] = "樵拾",
  [":ty_ex__qiaoshi"] = "其他角色的结束阶段，若其手牌数等于你，你可以与其各摸一张牌，若这两张牌颜色相同，你可以重复此流程。",
  ["ty_ex__yanyu"] = "燕语",
  [":ty_ex__yanyu"] = "①出牌阶段，你可以重铸【杀】；②出牌阶段结束时，若你于此阶段内发动过【燕语①】，则你可以令一名男性角色摸X张牌(X为你本阶段发动过【燕语①】的次数且至多为3)。",
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
  ["ty_ex__guotupangji"] = "郭图逄纪",
  ["ty_ex__jigong"] = "急攻",
  [":ty_ex__jigong"] = "出牌阶段开始时，你可以摸至多三张牌。若如此做，你本回合的手牌上限基数改为X，且弃牌阶段结束时，若X不小于Y，则你回复1点体力。（X为你本回合内造成的伤害值之和，Y为你本回合内因〖急攻〗摸牌而获得的牌的数量总和）",
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
  ["ty_ex__huaiyi"] = "怀异",
  [":ty_ex__huaiyi"] = "出牌阶段限一次，你可以展示所有手牌。若仅有一种颜色，你摸一张牌，然后此技能本阶段改为“出牌阶段限两次”；"..
  "若有两种颜色，你弃置其中一种颜色的牌，然后获得至多X名角色各一张牌（X为弃置的手牌数），若你获得的牌大于一张，你失去1点体力。",

  ["$ty_ex__huaiyi1"] = "曹刘可王，孤亦可王！",
  ["$ty_ex__huaiyi2"] = "汉失其鹿，天下豪杰当共逐之。",
  ["~ty_ex__gongsunyuan"] = "大星落，君王死……",
}
--yj2016
local ty_ex__sundeng = General(extension, "ty_ex__sundeng", "wu", 4)
local ty_ex__kuangbi = fk.CreateTriggerSkill {
  name = "ty_ex__kuangbi",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and player.phase == Player.Play
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player), function(p) return not p:isNude() end)
    if #targets > 0 then
      local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#ty_ex__kuangbi-choose", self.name, true)
      if #tos > 0 then
        self.cost_data = tos[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local cards = room:askForCard(to, 1, 3, true, self.name, false, ".", "#ty_ex__kuangbi-card:"..player.id)
    local dummy = Fk:cloneCard("slash")
    dummy:addSubcards(cards)
    player:addToPile(self.name, dummy, false, self.name)
    room:setPlayerMark(player, self.name, to.id)
  end,
}
local ty_ex__kuangbi_trigger = fk.CreateTriggerSkill {
  name = "#ty_ex__kuangbi_trigger",
  mute = true,
  events = {fk.CardUsing, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and #player:getPile("ty_ex__kuangbi") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      local cards = player:getPile("ty_ex__kuangbi")
      local ids = table.filter(cards, function(id) return Fk:getCardById(id).suit == data.card.suit end)
      local throw = #ids > 0 and table.random(ids) or table.random(cards)
      room:moveCards({ids = {throw}, from = player.id ,toArea = Card.DiscardPile, moveReason = fk.ReasonPutIntoDiscardPile })
      if not player.dead then
        player:drawCards(1, "ty_ex__kuangbi")
      end
      if #ids == 0 then return end
      local to = room:getPlayerById(player:getMark("ty_ex__kuangbi"))
      if to and not to.dead then
        room:doIndicate(player.id, {to.id})
        to:drawCards(1, "ty_ex__kuangbi")
      end
    else
      room:moveCards({ids = player:getPile("ty_ex__kuangbi"),from = player.id, toArea = Card.DiscardPile, moveReason = fk.ReasonPutIntoDiscardPile })
    end
  end,
}
ty_ex__kuangbi:addRelatedSkill(ty_ex__kuangbi_trigger)
ty_ex__sundeng:addSkill(ty_ex__kuangbi)
Fk:loadTranslationTable{
  ["ty_ex__sundeng"] = "界孙登",
  ["ty_ex__kuangbi"] = "匡弼",
  [":ty_ex__kuangbi"] = "出牌阶段开始时，你可以令一名其他角色将一至三张牌置于你的武将牌上，本阶段结束时将“匡弼”牌置入弃牌堆。当你于有“匡弼”牌时使用牌时，若你：有与之花色相同的“匡弼”牌，则随机将其中一张置入弃牌堆，然后你与该角色各摸一张牌；没有与之花色相同的“匡弼”牌，则随机将一张置入弃牌堆，然后你摸一张牌。",
  ["#ty_ex__kuangbi-choose"] = "匡弼：你可以令一名其他角色将一至三张牌置于你的武将牌上",
  ["#ty_ex__kuangbi-card"] = "匡弼：将一至三张牌置为 %src 的“匡弼”牌",

  ["$ty_ex__kuangbi1"] = "江东多娇，士当弼国以全方圆。",
  ["$ty_ex__kuangbi2"] = "吴垒锦绣，卿当匡佐使延万年。",
  ["~ty_ex__sundeng"] = "此别无期，此恨绵绵。",
}

local huangyueying = General(extension, "ty_ex__huangyueying", "qun", 3, 3, General.Female)
local ty__jiqiao = fk.CreateTriggerSkill{
  name = "ty__jiqiao",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForDiscard(player, 1, 999, true, self.name, true, ".", "#ty__jiqiao-invoke", true)
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    if player.dead then return end
    local n = 0
    for _, id in ipairs(self.cost_data) do
      if Fk:getCardById(id).type == Card.TypeEquip then
        n = n + 2
      else
        n = n + 1
      end
    end
    local cards = room:getNCards(n)
    room:moveCards{
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    }
    local get = {}
    for i = #cards, 1, -1 do
      if Fk:getCardById(cards[i]).type ~= Card.TypeEquip then
        table.insert(get, cards[i])
        table.removeOne(cards, cards[i])
      end
    end
    if #get > 0 then
      room:delay(1000)
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(get)
      room:obtainCard(player.id, dummy, true, fk.ReasonJustMove)
    end
    if #cards > 0 then
      room:delay(1000)
      room:moveCards{
        ids = cards,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
      }
    end
  end,
}
local ty__linglong = fk.CreateTriggerSkill{
  name = "ty__linglong",
  anim_type = "offensive",
  events = {fk.CardUsing},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      table.every({Card.SubtypeArmor, Card.SubtypeOffensiveRide, Card.SubtypeDefensiveRide, Card.SubtypeTreasure}, function(type)
        return player:getEquipment(type) == nil end)
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = table.map(player.room.alive_players, Util.IdMapper)
  end,

  refresh_events = {fk.GameStart, fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.GameStart then
        return true
      else
        for _, move in ipairs(data) do
          if move.from == player.id then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerEquip then
                return true
              end
            end
          end
          if move.to == player.id and move.toArea == Player.Equip then
            return true
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)  --FIXME: 虚拟装备技能应该用statusSkill而非triggerSkill
    if player:getEquipment(Card.SubtypeArmor) == nil and not player:hasSkill("#eight_diagram_skill", true) then
      player.room:handleAddLoseSkills(player, "#eight_diagram_skill", self, false, true)
    elseif player:getEquipment(Card.SubtypeArmor) ~= nil and player:hasSkill("#eight_diagram_skill", true) then
      player.room:handleAddLoseSkills(player, "-#eight_diagram_skill", nil, false, true)
    end
    if player:getEquipment(Card.SubtypeTreasure) == nil and not player:hasSkill("qicai", true) then
      player.room:handleAddLoseSkills(player, "qicai", self, false, true)
    elseif player:getEquipment(Card.SubtypeTreasure) ~= nil and player:hasSkill("qicai", true) then
      player.room:handleAddLoseSkills(player, "-qicai", nil, false, true)
    end
  end,
}
local ty__linglong_maxcards = fk.CreateMaxCardsSkill{
  name = "#ty__linglong_maxcards",
  correct_func = function(self, player)
    if player:hasSkill("ty__linglong") and
      player:getEquipment(Card.SubtypeOffensiveRide) == nil and player:getEquipment(Card.SubtypeDefensiveRide) == nil then
      return 2
    end
    return 0
  end,
}
ty__linglong:addRelatedSkill(ty__linglong_maxcards)
huangyueying:addSkill(ty__jiqiao)
huangyueying:addSkill(ty__linglong)
huangyueying:addRelatedSkill("qicai")
Fk:loadTranslationTable{
  ["ty_ex__huangyueying"] = "界黄月英",
  ["ty__jiqiao"] = "机巧",
  [":ty__jiqiao"] = "出牌阶段开始时，你可以弃置任意张牌，然后你亮出牌堆顶等量的牌，你弃置的牌中每有一张装备牌，则多亮出一张牌。然后你获得其中的非装备牌。",
  ["ty__linglong"] = "玲珑",
  [":ty__linglong"] = "锁定技，若你的装备区里没有防具牌，你视为装备【八卦阵】；若你的装备区里没有坐骑牌，你的手牌上限+2；"..
  "若你的装备区里没有宝物牌，你视为拥有〖奇才〗。若均满足，你使用的【杀】和普通锦囊牌不能被响应。",
  ["#ty__jiqiao-invoke"] = "机巧：你可以弃置任意张牌，亮出牌堆顶等量牌（每有一张装备牌额外亮出一张），获得非装备牌",

  ["$ty__jiqiao1"] = "机关将作之术，在乎手巧心灵。",
  ["$ty__jiqiao2"] = "机巧藏于心，亦如君之容。",
  ["$ty__linglong1"] = "我夫所赠之玫，遗香自长存。",
  ["$ty__linglong2"] = "心有玲珑罩，不殇春与秋。",
  ["~ty_ex__huangyueying"] = "此心欲留夏，奈何秋风起……",
}
local gongsunzan = General(extension, "ty_ex__gongsunzan", "qun", 4)
local ty_ex__qiaomeng = fk.CreateTriggerSkill{
  name = "ty_ex__qiaomeng",
  events = {fk.TargetSpecified},
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card and data.card.color == Card.Black and data.firstTarget
    and table.find(AimGroup:getAllTargets(data.tos), function(pid)
      return pid ~= player.id and not player.room:getPlayerById(pid):isNude()
    end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(AimGroup:getAllTargets(data.tos), function(pid)
      return pid ~= player.id and not room:getPlayerById(pid):isNude()
    end)
    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#ty_ex__qiaomeng-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local cid = room:askForCardChosen(player, to, "he", self.name)
    local card = Fk:getCardById(cid, true)
    if card.type == Card.TypeEquip then
      room:obtainCard(player, cid, false, fk.ReasonPrey)
    else
      room:throwCard({cid}, self.name, to, player)
      if card.type == Card.TypeTrick then
        data.disresponsiveList = table.map(room.alive_players, Util.IdMapper)
      end
    end
  end,
}
gongsunzan:addSkill(ty_ex__qiaomeng)
local ty_ex__yicong = fk.CreateDistanceSkill{
  name = "ty_ex__yicong",
  frequency = Skill.Compulsory,
  correct_func = function(self, from, to)
    if from:hasSkill(self) then
      return -1
    end
    if to:hasSkill(self) and to.hp < 3 then
      return 1
    end
    return 0
  end,
}
local ty_ex__yicong_audio = fk.CreateTriggerSkill{
  name = "#ty_ex__yicong_audio",
  refresh_events = {fk.HpChanged},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill("ty_ex__yicong") and not player:isFakeSkill("ty_ex__yicong")
    and player.hp < 3 and data.num < 0 and player.hp - data.num > 2
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, "ty_ex__yicong", "defensive")
    player:broadcastSkillInvoke("ty_ex__yicong")
  end,
}
ty_ex__yicong:addRelatedSkill(ty_ex__yicong_audio)
gongsunzan:addSkill(ty_ex__yicong)
Fk:loadTranslationTable{
  ["ty_ex__gongsunzan"] = "公孙瓒",
  ["ty_ex__qiaomeng"] = "趫猛",
  [":ty_ex__qiaomeng"] = "当你使用黑色牌指定目标后，你可以弃置其中一名其他目标角色的一张牌，若此牌为：锦囊牌，此黑色牌不能被响应；装备牌，你改为获得之。",
  ["#ty_ex__qiaomeng-choose"] = "趫猛：弃置一名其他目标角色的一张牌",
  ["ty_ex__yicong"] = "义从",
  [":ty_ex__yicong"] = "锁定技，①你计算与其他角色的距离-1；②若你已损失的体力值不小于2，其他角色计算与你的距离+1。",

  ["$ty_ex__qiaomeng1"] = "猛士骁锐，可慑百蛮失蹄！",
  ["$ty_ex__qiaomeng2"] = "锐士志猛，可凭白手夺马！",
  ["$ty_ex__yicong1"] = "恩义聚骠骑，百战从公孙！",
  ["$ty_ex__yicong2"] = "义从呼啸至，白马抖精神！",
  ["~ty_ex__gongsunzan"] = "良弓断，白马亡。",
}
return extension
