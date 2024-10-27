local extension = Package("tenyear_xinghuo")
extension.extensionName = "tenyear"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["tenyear_xinghuo"] = "十周年-星火燎原",
  ["ty"] = "新服",
}

local yanjun = General(extension, "yanjun", "wu", 3)
local guanchao = fk.CreateTriggerSkill{
  name = "guanchao",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(player, {"@@guanchao_ascending-turn", "@@guanchao_decending-turn"}, self.name)
    room:setPlayerMark(player, choice, 1)
  end,

  refresh_events = {fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes(self.name, Player.HistoryTurn) > 0 and
      (player:getMark("@@guanchao_ascending-turn") > 0 or player:getMark("@@guanchao_decending-turn") > 0 or
      player:getMark("@guanchao_ascending-turn") > 0 or player:getMark("@guanchao_decending-turn") > 0)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("@@guanchao_ascending-turn") > 0 then
      room:setPlayerMark(player, "@@guanchao_ascending-turn", 0)
      if data.card.number then
        room:setPlayerMark(player, "@guanchao_ascending-turn", data.card.number)
      end
    elseif player:getMark("@@guanchao_decending-turn") > 0 then
      room:setPlayerMark(player, "@@guanchao_decending-turn", 0)
      if data.card.number then
        room:setPlayerMark(player, "@guanchao_decending-turn", data.card.number)
      end
    elseif player:getMark("@guanchao_ascending-turn") > 0 then
      if data.card.number and data.card.number > player:getMark("@guanchao_ascending-turn") then
        room:setPlayerMark(player, "@guanchao_ascending-turn", data.card.number)
        player:drawCards(1, self.name)
      else
        room:setPlayerMark(player, "@guanchao_ascending-turn", 0)
      end
    elseif player:getMark("@guanchao_decending-turn") > 0 then
      if data.card.number and data.card.number < player:getMark("@guanchao_decending-turn") then
        room:setPlayerMark(player, "@guanchao_decending-turn", data.card.number)
        player:drawCards(1, self.name)
      else
        room:setPlayerMark(player, "@guanchao_decending-turn", 0)
      end
    end
  end,
}
local xunxian = fk.CreateTriggerSkill{
  name = "xunxian",
  anim_type = "support",
  events = {fk.CardUseFinished, fk.CardRespondFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.room:getCardArea(data.card) == Card.Processing and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return (#p.player_cards[Player.Hand] > #player.player_cards[Player.Hand] or p.hp > player.hp) end), Util.IdMapper)
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#xunxian-choose:::"..data.card:toLogString(), self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(self.cost_data, data.card, true, fk.ReasonGive, player.id)
  end,
}
yanjun:addSkill(guanchao)
yanjun:addSkill(xunxian)
Fk:loadTranslationTable{
  ["yanjun"] = "严畯",
  ["#yanjun"] = "志存补益",
  ["illustrator:yanjun"] = "YanBai",
  ["guanchao"] = "观潮",
  [":guanchao"] = "出牌阶段开始时，你可以选择一项直到回合结束：1.当你使用牌时，若你此阶段使用过的所有牌的点数为严格递增，你摸一张牌；"..
  "2.当你使用牌时，若你此阶段使用过的所有牌的点数为严格递减，你摸一张牌。",
  ["xunxian"] = "逊贤",
  [":xunxian"] = "每回合限一次，你使用或打出的牌置入弃牌堆时，你可以将之交给一名手牌数或体力值大于你的角色。",
  ["@@guanchao_ascending-turn"] = "观潮：递增",
  ["@@guanchao_decending-turn"] = "观潮：递减",
  ["@guanchao_ascending-turn"] = "观潮：递增",
  ["@guanchao_decending-turn"] = "观潮：递减",
  ["#xunxian-choose"] = "逊贤：你可以将%arg交给一名手牌数大于你的角色",

  ["$guanchao1"] = "朝夕之间，可知所进退。",
  ["$guanchao2"] = "月盈，潮起晨暮也；月亏，潮起日半也。",
  ["$xunxian1"] = "督军之才，子明强于我甚多。",
  ["$xunxian2"] = "此间重任，公卿可担之。",
  ["~yanjun"] = "著作，还……没完成……",
}

local lidian = General(extension, "ty__lidian", "wei", 3)
local ty__wangxi = fk.CreateTriggerSkill{
  name = "ty__wangxi",
  events = {fk.Damage, fk.Damaged},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from and data.from ~= data.to and not (data.from.dead or data.to.dead)
  end,
  on_trigger = function(self, event, target, player, data)
    self.cancel_cost = false
    for i = 1, data.damage do
      if self.cancel_cost then break end
      if not self:triggerable(event, target, player, data) then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local to = event == fk.Damage and data.to or data.from
    if player.room:askForSkillInvoke(player, self.name, nil, "#ty__wangxi-invoke::"..to.id) then
      player.room:doIndicate(player.id, {to.id})
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    room:notifySkillInvoked(player, self.name, event == fk.Damaged and "masochism" or "drawcard")
    room:drawCards(player, 2, self.name)
    local to = event == fk.Damage and data.to or data.from
    if player.dead or player:isNude() or to.dead then return false end
    local card = room:askForCard(player, 1, 1, true, self.name, false, ".", "#ty__wangxi-give::"..to.id)
    if #card > 0 then
      room:moveCardTo(card, Card.PlayerHand, to, fk.ReasonGive, self.name, nil, false, player.id)
    end
  end
}
lidian:addSkill("xunxun")
lidian:addSkill(ty__wangxi)
Fk:loadTranslationTable{
  ["ty__lidian"] = "李典",
  ["#ty__lidian"] = "深明大义",
  ["ty__wangxi"] = "忘隙",
  [":ty__wangxi"] = "当你对其他角色造成1点伤害后，或当你受到其他角色造成的1点伤害后，若其存活，你可以摸两张牌，然后将一张牌交给该角色。",

  ["#ty__wangxi-invoke"] = "是否对 %dest 发动 忘隙",
  ["#ty__wangxi-give"] = "忘隙：选择一张牌，交给 %dest",

  ["$xunxun_ty__lidian1"] = "吾乃儒雅之士，不需与诸将争功。",
  ["$xunxun_ty__lidian2"] = "读诗书，尚礼仪，守纲常。",
  ["$ty__wangxi1"] = "小隙沉舟，同心方可戮力。",
  ["$ty__wangxi2"] = "为天下苍生，自当化解私怨。",
  ["~ty__lidian"] = "恩遇极此，惶恐之至……",
}

local duji = General(extension, "duji", "wei", 3)
local andong = fk.CreateTriggerSkill{
  name = "andong",
  events = {fk.DamageInflicted},
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from and data.from ~= player and not data.from.dead
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#andong-invoke::"..data.from.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {data.from.id})
    local choices = {"andong1", "andong2"}
    local choice = room:askForChoice(data.from, choices, self.name, "#andong-choice:"..player.id)
    if choice == "andong1" then
      room:setPlayerMark(data.from, "andong-turn", 1)
      return true
    else
      if data.from:isKongcheng() then return end
      U.viewCards(player, data.from:getCardIds("h"), self.name)
      local cards = table.filter(data.from:getCardIds("h"), function(id) return Fk:getCardById(id).suit == Card.Heart end)
      if #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, true, player.id)
      end
    end
  end,
}
local andong_maxcards = fk.CreateMaxCardsSkill{
  name = "#andong_maxcards",
  exclude_from = function(self, player, card)
    return player:getMark("andong-turn") > 0 and card.suit == Card.Heart
  end,
}
local yingshi = fk.CreateTriggerSkill{
  name = "yingshi",
  anim_type = "control",
  events = {fk.EventPhaseStart, fk.Death},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Play and
          not table.find(player.room.alive_players, function(p) return #p:getPile("duji_chou") > 0 end) and
          table.find(player:getCardIds("he"), function(id) return Fk:getCardById(id).suit == Card.Heart end)
      else
        return #target:getPile("duji_chou") > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), Util.IdMapper),
      1, 1, "#yingshi-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local cards = table.filter(player:getCardIds("he"), function(id) return Fk:getCardById(id).suit == Card.Heart end)
      room:getPlayerById(self.cost_data):addToPile("duji_chou", cards, true, self.name)
    else
      room:moveCardTo(target:getPile("duji_chou"), Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, true, player.id)
    end
  end,
}
local yingshi_trigger = fk.CreateTriggerSkill{
  name = "#yingshi_trigger",
  mute = true,
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card and data.card.trueName == "slash" and #data.to:getPile("duji_chou") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards, choice = U.askforChooseCardsAndChoice(player, data.to:getPile("duji_chou"), {"OK"}, "yingshi",
      "#yingshi-get", {"Cancel"}, 1, 1)
    if #cards > 0 then
      room:moveCardTo(Fk:getCardById(cards[1]), Card.PlayerHand, player, fk.ReasonJustMove, "yingshi", nil, true, player.id)
    end
  end
}
andong:addRelatedSkill(andong_maxcards)
yingshi:addRelatedSkill(yingshi_trigger)
duji:addSkill(andong)
duji:addSkill(yingshi)
Fk:loadTranslationTable{
  ["duji"] = "杜畿",
  ["#duji"] = "卧镇京畿",
  ["illustrator:duji"] = "李秀森",
  ["designer:duji"] = "笔枔",

  ["andong"] = "安东",
  [":andong"] = "当你受到其他角色造成的伤害时，你可令伤害来源选择一项：1.防止此伤害，本回合弃牌阶段<font color='red'>♥</font>牌不计入手牌上限；"..
  "2.观看其手牌，若其中有<font color='red'>♥</font>牌则你获得这些牌。",
  ["yingshi"] = "应势",
  [":yingshi"] = "出牌阶段开始时，若没有武将牌旁有“酬”的角色，你可将所有<font color='red'>♥</font>牌置于一名其他角色的武将牌旁，称为“酬”。"..
  "若如此做，当一名角色使用【杀】对武将牌旁有“酬”的角色造成伤害后，其可以获得一张“酬”。当武将牌旁有“酬”的角色死亡时，你获得所有“酬”。",
  ["#andong-invoke"] = "安东：你可以对 %dest 发动“安东”，令选择一项",
  ["andong1"] = "防止此伤害，本回合你的<font color='red'>♥</font>牌不计入手牌上限",
  ["andong2"] = "其观看你的手牌并获得其中的<font color='red'>♥</font>牌",
  ["#andong-choice"] = "安东：选择 %src 令你执行的一项",
  ["duji_chou"] = "酬",
  ["#yingshi-choose"] = "应势：你可以将所有<font color='red'>♥</font>牌置为一名角色的“酬”",
  ["#yingshi-get"] = "应势：你可以获得一张“酬”",

  ["$andong1"] = "勇足以当大难，智涌以安万变。",
  ["$andong2"] = "宽猛克济，方安河东之民。",
  ["$yingshi1"] = "应民之声，势民之根。",
  ["$yingshi2"] = "应势而谋，顺民而为。",
  ["~duji"] = "试船而溺之，虽亡而忠至。",
}

local liuyan = General(extension, "liuyan", "qun", 3)
local tushe = fk.CreateTriggerSkill{
  name = "tushe",
  anim_type = "drawcard",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.type ~= Card.TypeEquip and data.firstTarget and
      not table.find(player:getCardIds(Player.Hand), function(id) return Fk:getCardById(id).type == Card.TypeBasic end) and
      #AimGroup:getAllTargets(data.tos) > 0
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(#AimGroup:getAllTargets(data.tos), self.name)
  end,
}
local limu = fk.CreateActiveSkill{
  name = "limu",
  anim_type = "control",
  prompt = "#limu",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player) return not player:hasDelayedTrick("indulgence") end,
  target_filter = Util.FalseFunc,
  card_filter = function(self, to_select, selected)
    if #selected == 0 and Fk:getCardById(to_select).suit == Card.Diamond then
      local card = Fk:cloneCard("indulgence")
      card:addSubcard(to_select)
      return not Self:prohibitUse(card) and not Self:isProhibited(Self, card)
    end
  end,
  on_use = function(self, room, use)
    local player = room:getPlayerById(use.from)
    local cards = use.cards
    local card = Fk:cloneCard("indulgence")
    card:addSubcards(cards)
    room:useCard{
      from = use.from,
      tos = {{use.from}},
      card = card,
    }
    if player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        skillName = self.name
      }
    end
  end,
}
local limu_refresh = fk.CreateTriggerSkill{
  name = "#limu_refresh",

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    return player == target and #player:getCardIds(Player.Judge) > 0 and player:hasSkill(limu) and
    table.find(TargetGroup:getRealTargets(data.tos), function (pid)
      return player:inMyAttackRange(player.room:getPlayerById(pid))
    end)
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
}
local limu_targetmod = fk.CreateTargetModSkill{
  name = "#limu_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return player:hasSkill(limu) and #player:getCardIds(Player.Judge) > 0 and to and player:inMyAttackRange(to)
  end,
  bypass_distances =  function(self, player, skill, card, to)
    return player:hasSkill(limu) and #player:getCardIds(Player.Judge) > 0 and to and player:inMyAttackRange(to)
  end,
}
limu:addRelatedSkill(limu_refresh)
limu:addRelatedSkill(limu_targetmod)
liuyan:addSkill(tushe)
liuyan:addSkill(limu)
Fk:loadTranslationTable{
  ["liuyan"] = "刘焉",
  ["#liuyan"] = "裂土之宗",
  ["cv:liuyan"] = "金垚",
  ["illustrator:liuyan"] = "明暗交界", -- 传说皮 雄踞益州
  ["tushe"] = "图射",
  [":tushe"] = "当你使用非装备牌指定目标后，若你没有基本牌，则你可以摸X张牌（X为此牌指定的目标数）。",
  ["limu"] = "立牧",
  [":limu"] = "出牌阶段，你可以将一张方块牌当【乐不思蜀】对自己使用，然后回复1点体力；你的判定区有牌时，你对攻击范围内的其他角色使用牌没有次数和距离限制。",

  ["#limu"] = "立牧：选择一张方块牌当【乐不思蜀】对自己使用，然后回复1点体力",

  ["$tushe1"] = "据险以图进，备策而施为！",
  ["$tushe2"] = "夫战者，可时以奇险之策而图常谋！",
  ["$limu1"] = "今诸州纷乱，当立牧以定！",
  ["$limu2"] = "此非为偏安一隅，但求一方百姓安宁！",
  ["~liuyan"] = "季玉，望你能守好者益州疆土……",
}

local panjun = General(extension, "panjun", "wu", 3)
local guanwei = fk.CreateTriggerSkill{
  name = "guanwei",
  anim_type = "support",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target.phase == Player.Play and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and not player:isNude() then
        local x = 0
        local suit = nil
        player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
          local use = e.data[1]
          if use.from == target.id then
            if suit == nil then
              suit = use.card.suit
            elseif suit ~= use.card.suit then
              x = 0
              return true
            end
            x = x + 1
          end
        end, Player.HistoryTurn)
        return x > 1
    end
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#guanwei-invoke::"..target.id, true)
    if #cards > 0 then
      player.room:doIndicate(player.id, {target.id})
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:throwCard(self.cost_data, self.name, player, player)
    if not target.dead then
      target:drawCards(2, self.name)
      target:gainAnExtraPhase(Player.Play)
    end
  end,
}
local gongqing = fk.CreateTriggerSkill{
  name = "gongqing",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.from then
      return (data.from:getAttackRange() < 3 and data.damage > 1) or data.from:getAttackRange() > 3
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.from:getAttackRange() < 3 then
      data.damage = 1
      player:broadcastSkillInvoke(self.name, 1)
      room:notifySkillInvoked(player, self.name, "defensive")
    elseif data.from:getAttackRange() > 3 then
      data.damage = data.damage + 1
      player:broadcastSkillInvoke(self.name, 2)
      room:notifySkillInvoked(player, self.name, "negative")
    end
  end,
}
panjun:addSkill(guanwei)
panjun:addSkill(gongqing)
Fk:loadTranslationTable{
  ["panjun"] = "潘濬",
  ["#panjun"] = "方严疾恶",
  ["illustrator:panjun"] = "秋呆呆",
  ["guanwei"] = "观微",
  [":guanwei"] = "一名角色的出牌阶段结束时，若其于此回合内使用过的牌数大于1且这些牌花色均相同或均没有花色且你于此回合未发动过此技能，"..
  "你可弃置一张牌。其摸两张牌，获得一个额外的出牌阶段。",
  ["gongqing"] = "公清",
  [":gongqing"] = "锁定技，当你受到伤害时，若来源的攻击范围小于3且伤害值大于1，你将伤害值改为1；"..
  "当你受到伤害时，若来源的攻击范围大于3，你令伤害值+1。",
  ["#guanwei-invoke"] = "观微：你可以弃置一张牌，令 %dest 摸两张牌并执行一个额外的出牌阶段",

  ["$guanwei1"] = "今日宴请诸位，有要事相商。",
  ["$guanwei2"] = "天下未定，请主公以大局为重。",
  ["$gongqing1"] = "尔辈何故与降虏交善。",
  ["$gongqing2"] = "豪将在外，增兵必成祸患啊！",
  ["~panjun"] = "耻失荆州，耻失荆州啊！",
}

local ty__wangcan = General(extension, "ty__wangcan", "qun", 3)
local sanwen = fk.CreateTriggerSkill{
  name = "sanwen",
  events = {fk.AfterCardsMove},
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryTurn) < 1 then
      local get = {}
      local handcards = player:getCardIds("h")
      for _, move in ipairs(data) do
        if move.toArea == Card.PlayerHand and move.to == player.id then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(handcards, info.cardId) then
              table.insertIfNeed(get, info.cardId)
            end
          end
        end
      end
      local throw, show = {},{}
      for _, id in ipairs(get) do
        for _, _id in ipairs(handcards) do
          if not table.contains(get, _id) then
            local name = Fk:getCardById(_id).trueName
            if Fk:getCardById(id).trueName == name then
              table.insertIfNeed(throw, id)
              table.insertIfNeed(show, _id)
            end
          end
        end
      end
      if #throw > 0 then
        self.cost_data = {throw, show}
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local num = #self.cost_data[1]
    return player.room:askForSkillInvoke(player, self.name, nil, "#sanwen-invoke:::"..num)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local throw = self.cost_data[1]
    local show = self.cost_data[2]
    table.insertTable(show, throw)
    player:showCards(show)
    throw = table.filter(throw, function (id)
      return not player:prohibitDiscard(Fk:getCardById(id))
    end)
    if #throw > 0 then
      room:throwCard(throw, self.name, player, player)
      if not player.dead then
        player:drawCards(2 * #throw, self.name)
      end
    end
  end,
}
ty__wangcan:addSkill(sanwen)
local qiai = fk.CreateTriggerSkill{
  name = "qiai",
  frequency = Skill.Limited,
  events = {fk.EnterDying},
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
    table.find(player.room:getOtherPlayers(player), function(p) return not p:isNude() end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local players = table.filter(player.room:getOtherPlayers(player), function(p) return not p:isNude() end)
    local extra_data = {
      num = 1,
      min_num = 1,
      include_equip = true,
      skillName = self.name,
      pattern = ".",
      reason = self.name,
    }
    for _, p in ipairs(players) do
      p.request_data = json.encode({ "choose_cards_skill", "#qiai-give::"..player.id, false, extra_data })
    end
    room:notifyMoveFocus(players, self.name)
    room:doBroadcastRequest("AskForUseActiveSkill", players)
    local moveInfos = {}
    for _, p in ipairs(players) do
      local cards
      if p.reply_ready then
        local replyCard = json.decode(p.client_reply).card
        cards = json.decode(replyCard).subcards
      else
        cards = table.random(p:getCardIds("he"), 1)
      end
      table.insert(moveInfos, {
        ids = cards,
        from = p.id,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonGive,
        proposer = p.id,
        skillName = self.name,
      })
    end
    room:moveCards(table.unpack(moveInfos))
  end,
}
ty__wangcan:addSkill(qiai)
local denglou = fk.CreateTriggerSkill{
  name = "denglou",
  frequency = Skill.Limited,
  events = {fk.EventPhaseStart},
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and player.phase == Player.Finish and player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(4)
    room:moveCards({
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonPut,
      skillName = self.name,
      proposer = player.id,
    })
    room:delay(500)
    local get = {}
    for i = 4, 1, -1 do
      if Fk:getCardById(cards[i]).type ~= Card.TypeBasic then
        table.insert(get, table.remove(cards, i))
      end
    end
    if #get > 0 then
      room:moveCardTo(get, Card.PlayerHand, player, fk.ReasonPrey, self.name)
    end
    while not player.dead and #cards > 0 do
      local use = U.askForUseRealCard(room, player, cards, ".", self.name, nil, {expand_pile = cards})
      if use then
        table.removeOne(cards, use.card.id)
      else
        break
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
  end,
}
ty__wangcan:addSkill(denglou)
Fk:loadTranslationTable{
  ["ty__wangcan"] = "王粲",
  ["#ty__wangcan"] = "七子之冠冕",
  ["illustrator:ty__wangcan"] = "ZOO",

  ["sanwen"] = "散文",
  [":sanwen"] = "每回合限一次，当你获得牌时，若你手中有与这些牌牌名相同的牌，你可以展示之，并弃置获得的同名牌，然后摸弃牌数两倍数量的牌。",
  ["qiai"] = "七哀",
  [":qiai"] = "限定技，当你进入濒死状态时，你可令每名其他角色同时交给你一张牌。",
  ["denglou"] = "登楼",
  [":denglou"] = "限定技，结束阶段开始时，若你没有手牌，你可以亮出牌堆顶四张牌，然后获得其中的非基本牌，并使用其中的基本牌（不使用则置入弃牌堆）。",
  ["#sanwen-invoke"] = "散文：你可以弃置获得的同名牌(%arg张)，然后摸两倍的牌",
  ["#qiai-give"] = "七哀：交给 %dest 一张牌",
  ["#denglou-use"] = "登楼：你可以使用这些基本牌",
  ["denglou_viewas"] = "登楼",

  ["$sanwen1"] = "文若春华，思若泉涌。",
  ["$sanwen2"] = "独步汉南，散文天下。",
  ["$qiai1"] = "未知身死处，何能两相完？",
  ["$qiai2"] = "悟彼下泉人，喟然伤心肝。",
  ["$denglou1"] = "登兹楼以四望兮，聊暇日以销忧。",
  ["$denglou2"] = "惟日月之逾迈兮，俟河清其未极。",
  ["~ty__wangcan"] = "一作驴鸣悲，万古送葬别。",
}


local pangtong = General(extension, "sp__pangtong", "wu", 3)
local guolun = fk.CreateActiveSkill{
  name = "guolun",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local id1 = room:askForCardChosen(player, target, "h", self.name)
    target:showCards(id1)
    if not target.dead and not player:isNude() then
      local n1 = Fk:getCardById(id1).number
      local card = room:askForCard(player, 1, 1, false, self.name, true, ".", "#guolun-card:::"..tostring(n1))
      if #card > 0 then
        local id2 = card[1]
        player:showCards(id2)
        local n2 = Fk:getCardById(id2).number
        if player.dead then return end
        local move1 = {
          from = effect.from,
          ids = {id2},
          to = effect.tos[1],
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonJustMove,
          proposer = effect.from,
          skillName = self.name,
        }
        local move2 = {
          from = effect.tos[1],
          ids ={id1},
          to = effect.from,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonJustMove,
          proposer = effect.from,
          skillName = self.name,
        }
        room:moveCards(move1, move2)
        if n2 > n1 and not target.dead then
          target:drawCards(1, self.name)
        elseif n1 > n2 and not player.dead then
          player:drawCards(1, self.name)
        end
      end
    end
  end,
}
local songsang = fk.CreateTriggerSkill{
  name = "songsang",
  anim_type = "support",
  frequency = Skill.Limited,
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      })
    else
      room:changeMaxHp(player, 1)
    end
    room:handleAddLoseSkills(player, "zhanji", nil, true, false)
  end,
}
local zhanji = fk.CreateTriggerSkill{
  name = "zhanji",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player.phase == Player.Play then
      for _, move in ipairs(data) do
        if move.to == player.id and move.moveReason == fk.ReasonDraw and move.skillName ~= self.name then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,
}
pangtong:addSkill(guolun)
pangtong:addSkill(songsang)
pangtong:addRelatedSkill(zhanji)
Fk:loadTranslationTable{
  ["sp__pangtong"] = "庞统",
  ["#sp__pangtong"] = "南州士冠",
  ["illustrator:sp__pangtong"] = "兴游",
  ["guolun"] = "过论",
  [":guolun"] = "出牌阶段限一次，你可以展示一名其他角色的一张手牌，然后你可以展示一张手牌，交换这两张牌，展示牌点数小的角色摸一张牌。",
  ["songsang"] = "送丧",
  [":songsang"] = "限定技，当其他角色死亡时，若你已受伤，你可回复1点体力；若你未受伤，你可加1点体力上限。然后你获得〖展骥〗。",
  ["zhanji"] = "展骥",
  [":zhanji"] = "锁定技，当你于出牌阶段内不因此技能摸牌后，你摸一张牌。",
  ["#guolun-card"] = "过论：你可以选择一张牌并交换双方的牌，点数小的角色摸一张牌（对方点数为%arg）",

  ["$guolun1"] = "品过是非，讨评好坏。",
  ["$guolun2"] = "若有天下太平时，必讨四海之内才。",
  ["$songsang1"] = "送丧至东吴，使命已完。",
  ["$songsang2"] = "送丧虽至，吾与孝则得相交。",
  ["$zhanji1"] = "公瑾安全至吴，心安之。",
  ["$zhanji2"] = "功曹之恩，吾必有展骥之机。",
  ["~sp__pangtong"] = "我终究……不得东吴赏识。",
}

local taishici = General(extension, "sp__taishici", "qun", 4)
local jixu = fk.CreateActiveSkill{
  name = "jixu",
  anim_type = "control",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 999,
  prompt = "#jixu",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    if to_select ~= Self.id then
      if #selected == 0 then
        return true
      else
        return Fk:currentRoom():getPlayerById(to_select).hp == Fk:currentRoom():getPlayerById(selected[1]).hp
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:sortPlayersByAction(effect.tos)
    local targets = table.map(effect.tos, Util.Id2PlayerMapper)
    local result = U.askForJointChoice(player, targets, {"yes", "no"}, self.name, "#jixu-choice:"..player.id, true)
    local right = table.find(player:getCardIds("h"), function(id)
      return Fk:getCardById(id).trueName == "slash" end) and "yes" or "no"
    local n = 0
    for _, p in ipairs(targets) do
      local choice = result[p.id]
      if choice ~= right then
        n = n + 1
        room:doIndicate(player.id, {p.id})
        if right == "yes" then
          room:setPlayerMark(p, "@@jixu-turn", 1)
        else
          if not p:isNude() then
            local id = room:askForCardChosen(player, p, "he", self.name)
            room:throwCard({id}, self.name, p, player)
          end
        end
      end
    end
    if n > 0 then
      player:drawCards(n, self.name)
    else
      player._phase_end = true
    end
  end,
}
local jixu_trigger = fk.CreateTriggerSkill{
  name = "#jixu_trigger",
  mute = true,
  events = {fk.AfterCardTargetDeclared},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes("jixu", Player.HistoryTurn) > 0 and data.card.trueName == "slash" and
      table.find(player.room:getOtherPlayers(player), function(p)
        return p:getMark("@@jixu-turn") > 0 and table.contains(player.room:getUseExtraTargets(data, true), p.id)
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p:getMark("@@jixu-turn") > 0 and table.contains(room:getUseExtraTargets(data, true), p.id) then
        room:doIndicate(player.id, {p.id})
        TargetGroup:pushTargets(data.targetGroup, p.id)
      end
    end
  end,
}
jixu:addRelatedSkill(jixu_trigger)
taishici:addSkill(jixu)
Fk:loadTranslationTable{
  ["sp__taishici"] = "太史慈",
  ["#sp__taishici"] = "北海酬恩",
  ["illustrator:sp__taishici"] = "王立雄",

  ["jixu"] = "击虚",
  [":jixu"] = "出牌阶段限一次，你可令任意名体力值相同的其他角色同时猜测你的手牌中是否有【杀】。若有角色猜错，且你：有【杀】，你于本回合使用【杀】"..
  "额外指定所有猜错的角色为目标；没有【杀】，你弃置所有猜错的角色各一张牌。然后你摸等同于猜错的角色数的牌。若没有角色猜错，则你结束此阶段。",
  ["#jixu"] = "击虚：令任意名体力值相同的角色猜测你手牌中是否有【杀】",
  ["#jixu-choice"] = "击虚：猜测 %src 的手牌中是否有【杀】",
  ["@@jixu-turn"] = "击虚",
  ["#jixu_trigger"] = "击虚",

  ["$jixu1"] = "击虚箭射，懈敌戒备。",
  ["$jixu2"] = "虚实难辨，方迷敌方之心！",
  ["~sp__taishici"] = "刘繇之见，短浅也……",
}

local zhoufang = General(extension, "zhoufang", "wu", 3)
local duanfa = fk.CreateActiveSkill{
  name = "duanfa",
  anim_type = "drawcard",
  can_use = function(self, player)
    return player:getMark("duanfa-phase") < player.maxHp
  end,
  target_num = 0,
  min_card_num = 1,
  max_card_num = function()
    return Self.maxHp - Self:getMark("duanfa-phase")
  end,
  card_filter = function(self, to_select, selected)
    return #selected < (Self.maxHp - Self:getMark("duanfa-phase")) and Fk:getCardById(to_select).color == Card.Black
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player)
    room:drawCards(player, #effect.cards, self.name)
    room:addPlayerMark(player, "duanfa-phase", #effect.cards)
  end
}
local sp__youdi = fk.CreateTriggerSkill{
  name = "sp__youdi",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#sp__youdi-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local card = room:askForCardChosen(to, player, "h", self.name)
    room:throwCard({card}, self.name, player, to)
    if Fk:getCardById(card).trueName ~= "slash" and not to:isNude() then
      local card2 = room:askForCardChosen(player, to, "he", self.name)
      room:obtainCard(player, card2, false, fk.ReasonPrey)
    end
    if Fk:getCardById(card).color ~= Card.Black then
      player:drawCards(1, self.name)
    end
  end,
}
zhoufang:addSkill(duanfa)
zhoufang:addSkill(sp__youdi)
Fk:loadTranslationTable{
  ["zhoufang"] = "周鲂",
  ["#zhoufang"] = "下发载义",
  ["illustrator:zhoufang"] = "黑白画谱",
  ["duanfa"] = "断发",
  [":duanfa"] = "出牌阶段，你可以弃置任意张黑色牌，然后摸等量的牌（你每阶段以此法弃置的牌数总和不能大于体力上限）。",
  ["sp__youdi"] = "诱敌",
  [":sp__youdi"] = "结束阶段，你可以令一名其他角色弃置你一张手牌，若弃置的牌不是【杀】，则你获得其一张牌；若弃置的牌不是黑色，则你摸一张牌。",
  ["#sp__youdi-choose"] = "诱敌：令一名角色弃置你一张牌，若不为【杀】，你获得其一张牌；若不为黑色，你摸一张牌",

  ["$duanfa1"] = "身体发肤，受之父母。",
  ["$duanfa2"] = "今断发以明志，尚不可证吾之心意？",
  ["$sp__youdi1"] = "东吴已容不下我，愿降以保周全。",
  ["$sp__youdi2"] = "笺书七条，足以表我归降之心。",
  ["~zhoufang"] = "功亏一篑，功亏一篑啊。",
}

local lvdai = General(extension, "lvdai", "wu", 4)
local qinguo = fk.CreateTriggerSkill{
  name = "qinguo",
  mute = true,
  events = {fk.CardUseFinished, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player.phase ~= Player.NotActive then
      if event == fk.CardUseFinished then
        return target == player and data.card.type == Card.TypeEquip
      else
        local equipnum = #player:getCardIds("e")
        for _, move in ipairs(data) do
          for _, info in ipairs(move.moveInfo) do
            if move.from == player.id and info.fromArea == Card.PlayerEquip then
              equipnum = equipnum + 1
            elseif move.to == player.id and move.toArea == Card.PlayerEquip then
              equipnum = equipnum - 1
            end
          end
        end
        return #player:getCardIds("e") ~= equipnum and #player:getCardIds("e") == player.hp and player:isWounded()
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.CardUseFinished then
      local room = player.room
      local success, dat = room:askForUseActiveSkill(player, "qinguo_viewas", "#qinguo-ask", true)
      if success then
        self.cost_data = dat
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.CardUseFinished then
      room:notifySkillInvoked(player, self.name, "offensive")
      local card = Fk.skills["qinguo_viewas"]:viewAs(self.cost_data.cards)
      room:useCard{
        from = player.id,
        tos = table.map(self.cost_data.targets, function(id) return {id} end),
        card = card,
        extraUse = true,
      }
    else
      room:notifySkillInvoked(player, self.name, "support")
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      }
    end
  end,
}
local qinguo_viewas = fk.CreateViewAsSkill{
  name = "qinguo_viewas",
  pattern = "slash",
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    local card = Fk:cloneCard("slash")
    card.skillName = "qinguo"
    return card
  end,
}
local qinguo_targetmod = fk.CreateTargetModSkill{
  name = "#qinguo_targetmod",
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, "qinguo")
  end,
}
Fk:addSkill(qinguo_viewas)
qinguo:addRelatedSkill(qinguo_targetmod)
lvdai:addSkill(qinguo)
Fk:loadTranslationTable{
  ["lvdai"] = "吕岱",
  ["#lvdai"] = "清身奉公",
  ["illustrator:lvdai"] = "biou09",
  ["designer:lvdai"] = "笔枔",

  ["qinguo"] = "勤国",
  [":qinguo"] = "当你于回合内使用装备牌结算结束后，你可视为使用【杀】；当你的装备区里的牌数变化后，"..
  "若你装备区里的牌数与你的体力值相等，你回复1点体力。",
  ["qinguo_viewas"] = "勤国",
  ["#qinguo-ask"] = "勤国：你可以视为使用一张【杀】",

  ["$qinguo1"] = "为国勤事，体素精勤。",
  ["$qinguo2"] = "忠勤为国，通达治体。",
  ["~lvdai"] = "再也不能，为吴国奉身了。",
}

local liuyao = General(extension, "liuyao", "qun", 4)
local kannan = fk.CreateActiveSkill{
  name = "kannan",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:getMark("kannan-phase") == 0 and player:usedSkillTimes(self.name, Player.HistoryPhase) < player.hp
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and to_select ~= Self.id and target:getMark("kannan-phase") == 0 and Self:canPindian(target)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(target, "kannan-phase", 1)
    local pindian = player:pindian({target}, self.name)
    if pindian.results[target.id].winner == player then
      room:addPlayerMark(player, "@kannan", 1)
      room:setPlayerMark(player, "kannan-phase", 1)
    elseif pindian.results[target.id].winner == target then
      room:addPlayerMark(target, "@kannan", 1)
    end
  end,
}
local kannan_record = fk.CreateTriggerSkill{
  name = "#kannan_record",
  mute = true,
  events = {fk.PreCardUse},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@kannan") > 0 and data.card.trueName == "slash"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + player:getMark("@kannan")
    player.room:setPlayerMark(player, "@kannan", 0)
  end,
}
kannan:addRelatedSkill(kannan_record)
liuyao:addSkill(kannan)
Fk:loadTranslationTable{
  ["liuyao"] = "刘繇",
  ["#liuyao"] = "宗英外镇",
  ["illustrator:liuyao"] = "异酷",
  ["kannan"] = "戡难",
  [":kannan"] = "出牌阶段，若你于此阶段内发动过此技能的次数小于X（X为你的体力值），你可与你于此阶段内未以此法拼点过的一名角色拼点。"..
  "若：你赢，你使用的下一张【杀】的伤害值基数+1且你于此阶段内不能发动此技能；其赢，其使用的下一张【杀】的伤害值基数+1。",
  ["@kannan"] = "戡难",

  ["$kannan1"] = "俊才之杰，材匪戡难。",
  ["$kannan2"] = "戡，克也，难，攻之。",
  ["~liuyao"] = "伯符小儿，还我子义！",
}

local lvqian = General(extension, "lvqian", "wei", 4)
local weilu = fk.CreateTriggerSkill{
  name = "weilu",
  anim = "masochism",
  frequency = Skill.Compulsory,
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from and not data.from.dead and data.from ~= player
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(data.from, "@@weilu", 1)
  end,

  refresh_events = {fk.EventPhaseStart},
  can_refresh = function(self, event, target, player, data)
    local room = player.room
    if target == player and player:hasSkill(self) then
      local players = table.filter(room:getOtherPlayers(player), function(p)
        return p:getMark("@@weilu") > 0 or p:getMark("weilu".."-turn") > 0
      end)
      return #players > 0 and (player.phase == Player.Play or player.phase == Player.Finish)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local players = table.filter(room:getOtherPlayers(player), function(p)
      return p:getMark("@@weilu") > 0 or p:getMark("weilu".."-turn") > 0
    end)
    if player.phase == Player.Play then
      for _, p in ipairs(players) do
        room:setPlayerMark(p, self.name.."-turn", p:getMark("@@weilu"))
        room:setPlayerMark(p, self.name, p.hp - 1)
        room:loseHp(p, p:getMark(self.name), self.name)
      end
    elseif player.phase == Player.Finish then
      for _, p in ipairs(players) do
        local n = p:getMark(self.name)
        if n > 0 then
          room:recover({
            who = p,
            num = n,
            skillName = self.name,
          })
        end
        if p:getMark("@@weilu") == p:getMark("weilu".."-turn") then
          room:setPlayerMark(p, "@@weilu", 0)
        end
        room:setPlayerMark(p, self.name, 0)
      end
    end
  end,
}
local zengdao = fk.CreateActiveSkill{
  name = "zengdao",
  anim_type = "support",
  frequency = Skill.Limited,
  min_card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return #player:getCardIds("e") > 0 and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = function(self, to_select, selected)
    return Fk:currentRoom():getCardArea(to_select) == Player.Equip
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local cards = effect.cards
    target:addToPile(self.name, cards, true, self.name)
  end,
}
local zengdao_trigger = fk.CreateTriggerSkill{
  name = "#zengdao_trigger",
  mute = true,
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and #player:getPile("zengdao") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askForCard(player, 1, 1, false, "zengdao", true, ".|.|.|zengdao|.|.|.", "#zengdao-invoke", "zengdao")
    if #cards == 0 then cards = {player:getPile("zengdao")[math.random(1, #player:getPile("zengdao"))]} end
    room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, "zengdao", nil, true, player.id)
    data.damage = data.damage + 1
  end
}
zengdao:addRelatedSkill(zengdao_trigger)
lvqian:addSkill(weilu)
lvqian:addSkill(zengdao)
Fk:loadTranslationTable{
  ["lvqian"] = "吕虔",
  ["#lvqian"] = "恩威并诸",
  ["illustrator:lvqian"] = "Town",
  ["weilu"] = "威虏",
  [":weilu"] = "锁定技，当你受到其他角色造成的伤害后，伤害来源在你的下回合出牌阶段开始时失去体力至1，回合结束时其回复以此法失去的体力值。",
  ["zengdao"] = "赠刀",
  [":zengdao"] = "限定技，出牌阶段，你可以将装备区内任意数量的牌置于一名其他角色的武将牌旁，该角色造成伤害时，移去一张“赠刀”牌，然后此伤害+1。",
  ["@@weilu"] = "威虏",
  ["#zengdao-invoke"] = "赠刀：移去一张“赠刀”牌使你造成的伤害+1（点“取消”则随机移去一张）",

  ["$weilu1"] = "贼人势大，需从长计议。",
  ["$weilu2"] = "时机未到，先行撤退。",
  ["$zengdao1"] = "有功赏之，有过罚之。",
  ["$zengdao2"] = "治军之道，功过分明。",
  ["~lvqian"] = "我自泰山郡以来，百姓获安，镇军伐贼，此生已无憾！",
}

local zhangliang = General(extension, "zhangliang", "qun", 4)
local jijun = fk.CreateTriggerSkill{
  name = "jijun",
  anim_type = "drawcard",
  derived_piles = "zhangliang_fang",
  events = {fk.TargetSpecified},
  can_trigger = function(self, _, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Play and player.id == data.to and
      (data.card.sub_type == Card.SubtypeWeapon or
      data.card.type ~= Card.TypeEquip)
  end,
  on_use = function(self, _, _, player, _)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".",
    }
    room:judge(judge)
  end,
}
local jijun_delay = fk.CreateTriggerSkill{
  name = "#jijun_delay",
  events = {fk.AfterCardsMove},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player.dead then return false end
    local ids = {}
    local room = player.room
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonJudge then
        local judge_event = room.logic:getCurrentEvent():findParent(GameEvent.Judge)
        if judge_event and judge_event.data[1].who == player and judge_event.data[1].reason == "jijun" then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.Processing and room:getCardArea(info.cardId) == Card.DiscardPile then
              table.insertIfNeed(ids, info.cardId)
            end
          end
        end
      end
    end
    ids = U.moveCardsHoldingAreaCheck(room, ids)
    if #ids > 0 then
      self.cost_data = ids
      return true
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local ids = table.simpleClone(self.cost_data) --理论上来讲只有一张
    if player.room:askForSkillInvoke(player, self.name, nil,
    "#jijun-push:::" .. Fk:getCardById(ids[1]):toLogString()) then
    player:addToPile("zhangliang_fang", self.cost_data, true, self.name)
    end
  end,
}
zhangliang:addSkill(jijun)
jijun:addRelatedSkill(jijun_delay)
local fangtong = fk.CreateTriggerSkill{
  name = "fangtong",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, _, target, player, _)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Finish and #player:getPile("zhangliang_fang") > 0 and
      not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForDiscard(player, 1, 1, true, self.name,
      true, ".", "#fangtong-invoke", true)

    if #card > 0 then
      self.cost_data = card[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    local cards = room:askForCard(player, 1, 0xFFFF, false, self.name,
      false, ".|.|.|zhangliang_fang|.|.", "#fangtong-discard", "zhangliang_fang")

    if #cards == 0 then cards = table.random(player:getPile("zhangliang_fang"), 1) end
    room:throwCard(cards, self.name, player, player)

    local sum = Fk:getCardById(self.cost_data).number
    for _, id in ipairs(cards) do
      sum = sum + Fk:getCardById(id).number
    end

    if sum == 36 then
      local targets = table.map(room:getOtherPlayers(player), Util.IdMapper)
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#fangtong-choose", self.name, false)
      room:damage {
        from = player,
        to = room:getPlayerById(tos[1]),
        damage = 3,
        damageType = fk.ThunderDamage,
        skillName = self.name,
      }
    end
  end,
}
zhangliang:addSkill(fangtong)
Fk:loadTranslationTable{
  ["zhangliang"] = "张梁",
  ["#zhangliang"] = "人公将军",
  ["illustrator:zhangliang"] = "Town",
  ["jijun"] = "集军",
  [":jijun"] = "当你于出牌阶段内使用武器或非装备牌指定你为目标后，你可以判定。"..
  "当此次判定的判定牌移至弃牌堆后，你可以将此判定牌置于你的武将牌上（称为“方”）。",
  ["#jijun_delay"] = "集军",
  ["#jijun-push"] = "集军：是否%arg置于武将牌上（称为“方”）",
  ["zhangliang_fang"] = "方",
  ["fangtong"] = "方统",
  [":fangtong"] = "结束阶段，你可以弃置一张牌，然后将至少一张“方”置入弃牌堆。"..
  "若此牌与你以此法置入弃牌堆的所有“方”的点数之和为36，"..
  "你对一名其他角色造成3点雷电伤害。",
  ["#fangtong-invoke"] = "方统：你可以弃置一张牌发动“方统”",
  ["#fangtong-discard"] = "方统：将至少一张“方”置入弃牌堆，若和之前弃置的牌点数之和为36则可电人",
  ["#fangtong-choose"] = "方统：对一名其他角色造成3点雷电伤害",

  ["$jijun1"] = "集民力万千，亦可为军！",
  ["$jijun2"] = "集万千义军，定天下大局！",
  ["$fangtong1"] = "统领方队，为民意所举！",
  ["$fangtong2"] = "三十六方，必为大统！",
  ["~zhangliang"] = "人公也难逃被人所杀……",
}

return extension
