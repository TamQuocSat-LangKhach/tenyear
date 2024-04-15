local extension = Package("tenyear_exxinghuo")
extension.extensionName = "tenyear"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["tenyear_exxinghuo"] = "十周年-界星火燎原",
}

local ty_ex__sundeng = General(extension, "ty_ex__sundeng", "wu", 4)
local ty_ex__kuangbi = fk.CreateTriggerSkill {
  name = "ty_ex__kuangbi",
  events = {fk.EventPhaseStart},
  derived_piles = "ty_ex__kuangbi",
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
  ["#ty_ex__sundeng"] = "才高德茂",
  ["illustrator:ty_ex__sundeng"] = "匠人绘",
  ["ty_ex__kuangbi"] = "匡弼",
  [":ty_ex__kuangbi"] = "出牌阶段开始时，你可以令一名其他角色将一至三张牌置于你的武将牌上，本阶段结束时将“匡弼”牌置入弃牌堆。当你于有“匡弼”牌时"..
  "使用牌时，若你：有与之花色相同的“匡弼”牌，则随机将其中一张置入弃牌堆，然后你与该角色各摸一张牌；没有与之花色相同的“匡弼”牌，则随机将一张置入弃牌堆，"..
  "然后你摸一张牌。",
  ["#ty_ex__kuangbi-choose"] = "匡弼：你可以令一名其他角色将一至三张牌置于你的武将牌上",
  ["#ty_ex__kuangbi-card"] = "匡弼：将一至三张牌置为 %src 的“匡弼”牌",

  ["$ty_ex__kuangbi1"] = "江东多娇，士当弼国以全方圆。",
  ["$ty_ex__kuangbi2"] = "吴垒锦绣，卿当匡佐使延万年。",
  ["~ty_ex__sundeng"] = "此别无期，此恨绵绵。",
}

local duji = General(extension, "ty_ex__duji", "wei", 3)
local ty_ex__andong = fk.CreateTriggerSkill{
  name = "ty_ex__andong",
  events = {fk.DamageInflicted},
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from and data.from ~= player and not data.from.dead
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#ty_ex__andong-invoke::"..data.from.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {data.from.id})
    local choices = {"ty_ex__andong1", "ty_ex__andong2"}
    local to = data.from
    local prompt = "#ty_ex__andong-choice:"..player.id
    if player:getMark(self.name) > 0 then
      choices = {"ty_ex__andong1Ex", "ty_ex__andong2Ex"}
      to = player
      prompt = "#ty_ex__andong2-choice::"..data.from.id
      room:setPlayerMark(player, self.name, 0)
    end
    local choice = room:askForChoice(to, choices, self.name, prompt)
    if choice[14] == "1" then
      room:setPlayerMark(data.from, "ty_ex__andong-turn", 1)
      return true
    else
      if data.from:isKongcheng() then
        room:setPlayerMark(player, self.name, 1)
        return
      end
      U.viewCards(player, data.from:getCardIds("h"), self.name)
      local cards = table.filter(data.from:getCardIds("h"), function(id) return Fk:getCardById(id).suit == Card.Heart end)
      if #cards > 0 then
        local dummy = Fk:cloneCard("dilu")
        dummy:addSubcards(cards)
        room:moveCardTo(dummy, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, true, player.id)
      end
    end
  end,
}
local ty_ex__andong_maxcards = fk.CreateMaxCardsSkill{
  name = "#ty_ex__andong_maxcards",
  exclude_from = function(self, player, card)
    return player:getMark("ty_ex__andong-turn") > 0 and card.suit == Card.Heart
  end,
}
local ty_ex__yingshi = fk.CreateTriggerSkill{
  name = "ty_ex__yingshi",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local success, dat = player.room:askForUseActiveSkill(player, "ty_ex__yingshi_active", "#ty_ex__yingshi-invoke", true)
    if success then
      self.cost_data = dat
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local target1 = room:getPlayerById(self.cost_data.targets[1])
    local target2 = room:getPlayerById(self.cost_data.targets[2])
    local id = self.cost_data.cards[1]
    local card_info = {Fk:getCardById(id):getSuitString(), Fk:getCardById(id).number}
    player:showCards({id})
    if target1.dead or target2.dead then return end
    local use = room:askForUseCard(target2, "slash", "slash", "#ty_ex__yingshi-slash::"..target1.id, true,
      {must_targets = {target1.id}, bypass_distances = true, bypass_times = true})
    if use then
      use.extraUse = true
      room:useCard(use)
      if not target2.dead and (table.contains(player:getCardIds("he"), id) or room:getCardArea(id) == Card.DiscardPile) then
        room:moveCardTo(Fk:getCardById(id), Card.PlayerHand, target2, fk.ReasonPrey, self.name, nil, true, target2.id)
      end
      if not target2.dead and use.damageDealt and card_info[1] ~= "nosuit" then
        local cards = room:getCardsFromPileByRule(".|"..card_info[2].."|"..card_info[1], 999)
        if #cards > 0 then
          room:moveCards({
            ids = cards,
            to = target2.id,
            toArea = Card.PlayerHand,
            moveReason = fk.ReasonPrey,
            proposer = target2.id,
            skillName = self.name,
          })
        end
      end
    end
  end,
}
local ty_ex__yingshi_active = fk.CreateActiveSkill{
  name = "ty_ex__yingshi_active",
  card_num = 1,
  target_num = 2,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Player.Hand
  end,
  target_filter = function(self, to_select, selected)
    if #selected == 0 then
      return to_select ~= Self.id
    elseif #selected == 1 then
      return true
    else
      return false
    end
  end,
}
ty_ex__andong:addRelatedSkill(ty_ex__andong_maxcards)
Fk:addSkill(ty_ex__yingshi_active)
duji:addSkill(ty_ex__andong)
duji:addSkill(ty_ex__yingshi)
Fk:loadTranslationTable{
  ["ty_ex__duji"] = "界杜畿",
  ["#ty_ex__duji"] = "卧镇京畿",
  ["illustrator:ty_ex__duji"] = "匠人绘",

  ["ty_ex__andong"] = "安东",
  [":ty_ex__andong"] = "当你受到其他角色造成的伤害时，你可令伤害来源选择一项：1.防止此伤害，本回合弃牌阶段<font color='red'>♥</font>牌不计入手牌上限；"..
  "2.观看其手牌，若其中有<font color='red'>♥</font>牌则你获得这些牌。若选择2且其没有手牌，则下一次发动时改为由你选择。",
  ["ty_ex__yingshi"] = "应势",
  [":ty_ex__yingshi"] = "出牌阶段开始时，你可以展示一张手牌并选择一名其他角色，然后令另一名角色对其使用一张【杀】（无距离次数限制）。"..
  "若其使用了【杀】，则其获得你展示的牌；若此【杀】造成了伤害，则其再获得牌堆中所有与展示牌花色点数均相同的牌。",
  ["#ty_ex__andong-invoke"] = "安东：你可以对 %dest 发动“安东”",
  ["ty_ex__andong1"] = "防止此伤害，本回合你的<font color='red'>♥</font>牌不计入手牌上限",
  ["ty_ex__andong2"] = "其观看你的手牌并获得其中的<font color='red'>♥</font>牌",
  ["ty_ex__andong1Ex"] = "防止此伤害，本回合其<font color='red'>♥</font>牌不计入手牌上限",
  ["ty_ex__andong2Ex"] = "观看其手牌并获得其中的<font color='red'>♥</font>牌",
  ["#ty_ex__andong-choice"] = "安东：选择 %src 令你执行的一项",
  ["#ty_ex__andong2-choice"] = "安东：选择对 %dest 执行的一项",
  ["ty_ex__yingshi_active"] = "应势",
  ["#ty_ex__yingshi-invoke"] = "应势：展示一张手牌并选择两名角色，后者可以对前者使用一张【杀】",
  ["#ty_ex__yingshi-slash"] = "应势：你可以对 %dest 使用一张【杀】，然后获得展示牌",

  ["$ty_ex__andong1"] = "青龙映木，星出其东则天下安。",
  ["$ty_ex__andong2"] = "以身涉险，剑伐不臣而定河东。",
  ["$ty_ex__yingshi1"] = "大势如潮，可应之而不可逆之。",
  ["$ty_ex__yingshi2"] = "应大势伐贼者，当以重酬彰之。",
  ["~ty_ex__duji"] = "公无渡河，公竟渡河。",
}

local guohuanghou = General(extension, "ty_ex__guohuanghou", "wei", 3, 3, General.Female)
local ty_ex__jiaozhao = fk.CreateActiveSkill{
  name = "ty_ex__jiaozhao",
  anim_type = "special",
  card_num = 1,
  prompt = function ()
    return "#ty_ex__jiaozhao-prompt"..((Self:getMark("@ty_ex__jiaozhao") > 0) and "1" or "")
  end,
  can_use = function(self, player)
    if not player:isKongcheng() then
      if player:getMark("@ty_ex__jiaozhao") < 2 then
        return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
      else
        return #U.getMark(player, "ty_ex__jiaozhao_choice-phase") < 2
      end
    end
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected)
    if #selected == 0 and Self:getMark("@ty_ex__jiaozhao") == 0 then
      local n = 999
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        if p ~= Self and not p:isRemoved() and Self:distanceTo(p) < n then
          n = Self:distanceTo(p)
        end
      end
      return Self:distanceTo(Fk:currentRoom():getPlayerById(to_select)) == n
    end
  end,
  feasible = function(self, selected, selected_cards)
    local n = Self:getMark("@ty_ex__jiaozhao") == 0 and 1 or 0
    return #selected == n and #selected_cards == 1
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = #effect.tos > 0 and room:getPlayerById(effect.tos[1]) or player
    player:showCards(effect.cards)
    if player.dead then return end
    local c = Fk:getCardById(effect.cards[1])
    local mark = U.getMark(player, "ty_ex__jiaozhao_choice-phase")
    local pat = table.contains(mark, "b") and "" or "b"
    if not table.contains(mark, "t") then pat = pat .. "t" end
    local names = U.getAllCardNames(pat)
    local choice = room:askForChoice(target, names, self.name, "#ty_ex__jiaozhao-choice:"..player.id.."::"..c:toLogString())
    table.insert(mark, Fk:cloneCard(choice).type == Card.TypeBasic and "b" or "t")
    room:setPlayerMark(player, "ty_ex__jiaozhao_choice-phase", mark)
    room:sendLog{
      type = "#TYEXJiaozhaoChoice",
      from = player.id,
      arg = choice,
      arg2 = self.name,
      toast = true,
    }
    if room:getCardOwner(c) == player and room:getCardArea(c) == Card.PlayerHand then
      room:setCardMark(c, "ty_ex__jiaozhao-inhand", choice)
      room:setCardMark(c, "@ty_ex__jiaozhao-inhand", Fk:translate(choice)) --- FIXME : translate for visble card mark
      room:handleAddLoseSkills(player, "ty_ex__jiaozhao&", nil, false, true)
    end
  end,
}
local ty_ex__jiaozhaoVS = fk.CreateViewAsSkill{
  name = "ty_ex__jiaozhao&",
  pattern = ".",
  mute = true,
  prompt = "#ty_ex__jiaozhaoVS",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select):getMark("ty_ex__jiaozhao-inhand") ~= 0
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard(Fk:getCardById(cards[1]):getMark("ty_ex__jiaozhao-inhand"))
    card.skillName = "ty_ex__jiaozhao"
    card:addSubcard(cards[1])
    return card
  end,
  before_use = function(self, player, use)
    player:broadcastSkillInvoke("ty_ex__jiaozhao")
  end,
  enabled_at_play = function(self, player)
    return table.find(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("ty_ex__jiaozhao-inhand") ~= 0 end)
  end,
  enabled_at_response = function(self, player, response)
    if not response and not player:isKongcheng() and Fk.currentResponsePattern then
      local cards = {}
      for _, id in ipairs(player.player_cards[Player.Hand]) do
        local name = Fk:getCardById(id):getMark("ty_ex__jiaozhao-inhand")
        if name ~= 0 then
          local c = Fk:cloneCard(name)
          c:addSubcard(id)
          table.insert(cards, c)
        end
      end
      return table.find(cards, function(c) return Exppattern:Parse(Fk.currentResponsePattern):match(c) end)
    end
  end,
}
local ty_ex__jiaozhao_prohibit = fk.CreateProhibitSkill{
  name = "#ty_ex__jiaozhao_prohibit",
  is_prohibited = function(self, from, to, card)
    return card and from == to and table.contains(card.skillNames, "ty_ex__jiaozhao") and from:getMark("@ty_ex__jiaozhao") < 2
  end,
}
local ty_ex__jiaozhao_change = fk.CreateTriggerSkill{
  name = "#ty_ex__jiaozhao_change",

  refresh_events = {fk.AfterTurnEnd, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    if event == fk.AfterTurnEnd then
      return target == player and player:hasSkill("ty_ex__jiaozhao&", true)
    else
      return target == player and data == ty_ex__jiaozhao
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterTurnEnd then
      room:handleAddLoseSkills(player, "-ty_ex__jiaozhao&", nil, false, true)
      for _, id in ipairs(player.player_cards[Player.Hand]) do
        local c = Fk:getCardById(id)
        if c:getMark("ty_ex__jiaozhao-inhand") ~= 0 then
          room:setCardMark(c, "ty_ex__jiaozhao-inhand", 0)
          room:setCardMark(c, "@ty_ex__jiaozhao-inhand", 0)
        end
      end
    else
      room:setPlayerMark(player, "@ty_ex__jiaozhao", 0)
    end
  end,
}
local ty_ex__danxin = fk.CreateTriggerSkill{
  name = "ty_ex__danxin",
  anim_type = "masochism",
  events = {fk.Damaged},
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
    if player:getMark("@ty_ex__jiaozhao") < 2 then
      player.room:addPlayerMark(player, "@ty_ex__jiaozhao", 1)
    end
  end,
}
ty_ex__jiaozhaoVS:addRelatedSkill(ty_ex__jiaozhao_prohibit)
Fk:addSkill(ty_ex__jiaozhaoVS)
ty_ex__jiaozhao:addRelatedSkill(ty_ex__jiaozhao_change)
guohuanghou:addSkill(ty_ex__danxin)
guohuanghou:addSkill(ty_ex__jiaozhao)
Fk:loadTranslationTable{
  ["ty_ex__guohuanghou"] = "界郭皇后",
  ["#ty_ex__guohuanghou"] = "月华驱霾",
  ["illustrator:ty_ex__guohuanghou"] = "匠人绘",
  ["ty_ex__jiaozhao"] = "矫诏",
  [":ty_ex__jiaozhao"] = "出牌阶段限一次，你可以展示一张手牌并选择一名距离最近的其他角色，该角色声明一种或普通锦囊牌的牌名，"..
  "本回合你可以将此牌当声明的牌使用（不能指定自己为目标）。",
  ["ty_ex__danxin"] = "殚心",
  [":ty_ex__danxin"] = "当你受到伤害后，你可以摸一张牌并修改〖矫诏〗。第1次修改：将“一名距离最近的其他角色”改为“你”；第2次修改：删去“不能指定自己为目标”并将“出牌阶段限一次”改为“出牌阶段每种类型限声明一次”。",
  ["@ty_ex__jiaozhao"] = "矫诏",
  ["ty_ex__jiaozhao&"] = "矫诏",
  [":ty_ex__jiaozhao&"] = "你可以将“矫诏”牌当本回合被声明的牌使用。",
  ["#ty_ex__jiaozhaoVS"] = "矫诏：你可以将“矫诏”牌当本回合被声明的牌使用",
  ["#ty_ex__jiaozhao-prompt"] = "矫诏：展示一张手牌令一名角色声明一种基本牌或普通锦囊牌，你本回合可以将此牌当声明的牌使用",
  ["#ty_ex__jiaozhao-prompt1"] = "矫诏：展示一张手牌并声明一种基本牌或普通锦囊牌，你本回合可以将此牌当声明的牌使用",
  ["#ty_ex__jiaozhao-choice"] = "矫诏：声明一种牌名，%src 本回合可以将%arg当此牌使用",
  ["#TYEXJiaozhaoChoice"] = "%from “%arg2” 声明牌名 %arg",
  ["@ty_ex__jiaozhao-inhand"] = "矫诏",

  ["$ty_ex__jiaozhao1"] = "事关社稷，万望阁下谨慎行事。",
  ["$ty_ex__jiaozhao2"] = "为续江山，还请爱卿仔细观之。",
  ["$ty_ex__danxin1"] = "殚精出谋，以保社稷。",
  ["$ty_ex__danxin2"] = "竭心筹划，求续魏统。",
  ["~ty_ex__guohuanghou"] = "哀家愧对先帝。",
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
      proposer = player.id,
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
  events = {fk.CardUsing, fk.AskForCardUse, fk.AskForCardResponse, fk.BeforeCardsMove},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if event == fk.CardUsing then
      return target == player and player:hasSkill(self) and (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      table.every({Card.SubtypeArmor, Card.SubtypeOffensiveRide, Card.SubtypeDefensiveRide, Card.SubtypeTreasure}, function(type)
        return player:getEquipment(type) == nil
      end)
    elseif event == fk.BeforeCardsMove then
      if player:hasSkill(self) and player:getEquipment(Card.SubtypeArmor) and not player:getEquipment(Card.SubtypeTreasure) then
        for _, move in ipairs(data) do
          if move.from == player.id and move.moveReason == fk.ReasonDiscard and move.proposer ~= player.id then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerEquip and Fk:getCardById(info.cardId).sub_type == Card.SubtypeArmor then
                return true
              end
            end
          end
        end
      end
    else
      return target == player and player:hasSkill(self) and not player:isFakeSkill(self) and
      (data.cardName == "jink" or (data.pattern and Exppattern:Parse(data.pattern):matchExp("jink|0|nosuit|none"))) and
      not player:getEquipment(Card.SubtypeArmor) and player:getMark(fk.MarkArmorNullified) == 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.CardUsing or event == fk.BeforeCardsMove then return true end
    return player.room:askForSkillInvoke(player, self.name, data)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      data.disresponsiveList = table.map(room.alive_players, Util.IdMapper)
    elseif event == fk.BeforeCardsMove then
      local ids = {}
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason == fk.ReasonDiscard and move.proposer ~= player.id then
          local move_info = {}
          for _, info in ipairs(move.moveInfo) do
            local id = info.cardId
            if info.fromArea == Card.PlayerEquip and Fk:getCardById(info.cardId).sub_type == Card.SubtypeArmor then
              table.insert(ids, id)
            else
              table.insert(move_info, info)
            end
          end
          if #ids > 0 then
            move.moveInfo = move_info
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
      local judgeData = {
        who = player,
        reason = "eight_diagram",
        pattern = ".|.|heart,diamond",
      }
      room:judge(judgeData)
      if judgeData.card.color == Card.Red then
        if event == fk.AskForCardUse then
          data.result = {
            from = player.id,
            card = Fk:cloneCard('jink'),
          }
          data.result.card.skillName = "eight_diagram"
          data.result.card.skillName = "ty__linglong"

          if data.eventData then
            data.result.toCard = data.eventData.toCard
            data.result.responseToEvent = data.eventData.responseToEvent
          end
        else
          data.result = Fk:cloneCard('jink')
          data.result.skillName = "eight_diagram"
          data.result.skillName = "ty__linglong"
        end
        return true
      end
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
local ty__linglong_targetmod = fk.CreateTargetModSkill{
  name = "#ty__linglong_targetmod",
  frequency = Skill.Compulsory,
  bypass_distances = function(self, player, skill, card)
    return player:hasSkill("ty__linglong") and player:getEquipment(Card.SubtypeTreasure) == nil
    and card and card.type == Card.TypeTrick
  end,
}
ty__linglong:addRelatedSkill(ty__linglong_maxcards)
ty__linglong:addRelatedSkill(ty__linglong_targetmod)
huangyueying:addSkill(ty__jiqiao)
huangyueying:addSkill(ty__linglong)
huangyueying:addRelatedSkill("ex__qicai")
Fk:loadTranslationTable{
  ["ty_ex__huangyueying"] = "界黄月英",
  ["#ty_ex__huangyueying"] = "闺中璞玉",
  ["illustrator:ty_ex__huangyueying"] = "匠人绘",
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

local taishici = General(extension, "ty_ex__taishici", "qun", 4)
local ty_ex__jixu = fk.CreateActiveSkill{
  name = "ty_ex__jixu",
  anim_type = "control",
  card_num = 0,
  min_target_num = 1,
  max_target_num = function()
    return Self.hp
  end,
  prompt = function()
    return "#ty_ex__jixu:::"..Self.hp
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected < Self.hp and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:sortPlayersByAction(effect.tos)
    local targets = table.map(effect.tos, function(id) return room:getPlayerById(id) end)
    for _, p in ipairs(targets) do
      local choices = {"yes", "no"}
      p.request_data = json.encode({choices, choices, self.name, "#ty_ex__jixu-choice:"..player.id})
    end
    room:notifyMoveFocus(room.alive_players, self.name)
    room:doBroadcastRequest("AskForChoice", targets)

    for _, p in ipairs(targets) do
      local choice
      if p.reply_ready then
        choice = p.client_reply
      else
        p.client_reply = "yes"
        choice = "yes"
      end
      room:sendLog{
        type = "#ty_ex__jixu-quest",
        from = p.id,
        arg = choice,
      }
    end
    local right = table.find(player:getCardIds("h"), function(id)
      return Fk:getCardById(id).trueName == "slash" end) and "yes" or "no"
    local n = 0
    for _, p in ipairs(targets) do
      if player.dead then return end
      local choice = p.client_reply
      if choice ~= right then
        n = n + 1
        if not p.dead then
          room:doIndicate(player.id, {p.id})
          if right == "yes" then
            room:setPlayerMark(p, "@@ty_ex__jixu-turn", 1)
          else
            if not p:isNude() then
              local id = room:askForCardChosen(player, p, "he", self.name)
              room:throwCard({id}, self.name, p, player)
            end
          end
        end
      end
    end
    if n > 0 and not player.dead then
      if right == "yes" then
        room:setPlayerMark(player, "ty_ex__jixu-turn", n)
      end
      player:drawCards(n, self.name)
    end
  end,
}
local ty_ex__jixu_trigger = fk.CreateTriggerSkill{
  name = "#ty_ex__jixu_trigger",
  mute = true,
  events = {fk.AfterCardTargetDeclared},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes("ty_ex__jixu", Player.HistoryTurn) > 0 and data.card.trueName == "slash" and
      table.find(player.room:getOtherPlayers(player), function(p)
        return p:getMark("@@ty_ex__jixu-turn") > 0 and table.contains(U.getUseExtraTargets(player.room, data, true), p.id) end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if room:askForSkillInvoke(player, "ty_ex__jixu", nil, "#ty_ex__jixu-invoke") then
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if p:getMark("@@ty_ex__jixu-turn") > 0 and table.contains(U.getUseExtraTargets(room, data, true), p.id) then
          room:doIndicate(player.id, {p.id})
          table.insertTable(data.tos, {{p.id}})
        end
      end
    end
  end,
}
local ty_ex__jixu_targetmod = fk.CreateTargetModSkill{
  name = "#ty_ex__jixu_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("ty_ex__jixu-turn") > 0 and scope == Player.HistoryPhase then
      return player:getMark("ty_ex__jixu-turn")
    end
  end,
}
ty_ex__jixu:addRelatedSkill(ty_ex__jixu_trigger)
ty_ex__jixu:addRelatedSkill(ty_ex__jixu_targetmod)
taishici:addSkill(ty_ex__jixu)
Fk:loadTranslationTable{
  ["ty_ex__taishici"] = "界太史慈",
  ["#ty_ex__taishici"] = "北海酬恩",
  ["illustrator:ty_ex__taishici"] = "匠人绘",
  ["ty_ex__jixu"] = "击虚",
  [":ty_ex__jixu"] = "出牌阶段限一次，你可以令至多你体力值数量的其他角色各猜测你的手牌中是否有【杀】。若你的手牌中：有【杀】，此阶段你使用【杀】"..
  "次数上限+X且可以额外指定所有猜错的角色为目标；没有【杀】，你弃置所有猜错的角色各一张牌。然后你摸X张牌（X为猜错的角色数）。",
  ["#ty_ex__jixu"] = "击虚：令至多%arg名角色猜测你手牌中是否有【杀】",
  ["#ty_ex__jixu-choice"] = "击虚：猜测 %src 的手牌中是否有【杀】",
  ["#ty_ex__jixu-quest"] = "%from 猜测 %arg",
  ["@@ty_ex__jixu-turn"] = "击虚",
  ["#ty_ex__jixu-invoke"] = "击虚：是否额外指定所有“击虚”猜错的角色为目标？",

  ["$ty_ex__jixu1"] = "辨坚识钝，可解充栋之牛！",
  ["$ty_ex__jixu2"] = "以锐欺虚，可击泰山之踵！",
  ["~ty_ex__taishici"] = "危而不救为怯，救而不得为庸。",
}

local wenpin = General(extension, "ty_ex__wenpin", "wei", 5)
local ty_ex__zhenwei = fk.CreateTriggerSkill{
  name = "ty_ex__zhenwei",
  anim_type = "defensive",
  events = {fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not player:isNude() and data.from ~= player.id and data.to ~= player.id and
      (data.card.trueName == "slash" or (data.card.type == Card.TypeTrick and data.card.color == Card.Black)) and
      U.isOnlyTarget (target, data, event) and player.room:getPlayerById(data.to).hp <= player.hp
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".",
    "#ty_ex__zhenwei-invoke:" .. data.from .. ":" .. data.to .. ":" .. data.card:toLogString(), true)
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    if player.dead then return false end
    local choice = room:askForChoice(player, {"ty_ex__zhenwei_transfer", "ty_ex__zhenwei_recycle"}, self.name)
    if choice == "ty_ex__zhenwei_transfer" then
      room:drawCards(player, 1, self.name)
      if player.dead then return false end
      if U.canTransferTarget(player, data) then
        local targets = {player.id}
        if type(data.subTargets) == "table" then
          table.insertTable(targets, data.subTargets)
        end
        AimGroup:addTargets(room, data, targets)
        AimGroup:cancelTarget(data, target.id)
        return true
      end
    else
      data.tos = AimGroup:initAimGroup({})
      data.targetGroup = {}
      local use_from = room:getPlayerById(data.from)
      if not use_from.dead and U.hasFullRealCard(room, data.card) then
        use_from:addToPile(self.name, data.card, true, self.name)
      end
      return true
    end
  end,
}
local ty_ex__zhenwei_delay = fk.CreateTriggerSkill{
  name = "#ty_ex__zhenwei_delay",
  mute = true,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return #player:getPile(ty_ex__zhenwei.name) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:moveCards({
      from = player.id,
      ids = player:getPile(ty_ex__zhenwei.name),
      to = player.id,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonPrey,
      skillName = ty_ex__zhenwei.name,
      proposer = player.id,
    })
  end,
}
ty_ex__zhenwei:addRelatedSkill(ty_ex__zhenwei_delay)
wenpin:addSkill(ty_ex__zhenwei)
Fk:loadTranslationTable{
  ["ty_ex__wenpin"] = "界文聘",
  ["#ty_ex__wenpin"] = "坚城宿将",
  ["illustrator:ty_ex__wenpin"] = "黯荧岛工作室",
  ["ty_ex__zhenwei"] = "镇卫",
  [":ty_ex__zhenwei"] = "当其他角色成为【杀】或黑色锦囊牌的唯一目标时，若该角色的体力值不大于你，你可以弃置一张牌并选择一项：1.摸一张牌，"..
  "然后将此牌转移给你；2.令此牌无效，然后当前回合结束后，使用者获得此牌。",
  ["#ty_ex__zhenwei-invoke"] = "镇卫：%src对%dest使用%arg，是否弃置一张牌发动“镇卫”？",
  ["ty_ex__zhenwei_transfer"] = "摸一张牌并将此牌转移给你",
  ["ty_ex__zhenwei_recycle"] = "取消此牌，回合结束时使用者将之收回",

  ["$ty_ex__zhenwei1"] = "想攻城，问过我没有？",
  ["$ty_ex__zhenwei2"] = "有我坐镇，我军焉能有失？",
  ["~ty_ex__wenpin"] = "没想到，敌军的攻势如此凌厉。",
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
  ["ty_ex__gongsunzan"] = "界公孙瓒",
  ["#ty_ex__gongsunzan"] = "白马将军",
  ["illustrator:ty_ex__gongsunzan"] = "匠人绘",
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

local ty_ex__zhugedan = General(extension, "ty_ex__zhugedan", "wei", 4)
local ty_ex__gongao = fk.CreateTriggerSkill{
  name = "ty_ex__gongao",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target ~= player then
      local dying_id = target:getMark(self.name)
      local cur_event = player.room.logic:getCurrentEvent()
      if dying_id ~= 0 then
        return cur_event.id == dying_id
      else
        local events = player.room.logic.event_recorder[GameEvent.Dying] or Util.DummyTable
        local canInvoke = true
        for i = #events, 1, -1 do
          local e = events[i]
          if e.data[1].who == target.id and e.id ~= cur_event.id then
            canInvoke = false
            break
          end
        end
        if canInvoke then
          player.room:setPlayerMark(target, self.name, cur_event.id)
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if not player.dead and player:isWounded() then
      room:recover { num = 1, skillName = self.name, who = player, recoverBy = player}
    end
  end,
}
local ty_ex__juyi = fk.CreateTriggerSkill{
  name = "ty_ex__juyi",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
     player.phase == Player.Start and
     player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:isWounded() and player.maxHp > #player.room.alive_players
  end,
  on_use = function(self, event, target, player, data)
    local n = player.maxHp - #player.player_cards[Player.Hand]
    if n > 0 then
      player:drawCards(n, self.name)
    end
    player.room:handleAddLoseSkills(player, "benghuai|ty_ex__weizhong", nil)
  end,
}
local ty_ex__weizhong = fk.CreateTriggerSkill{
  name = "ty_ex__weizhong",
  frequency = Skill.Compulsory,
  anim_type = "drawcard",
  events = {fk.MaxHpChanged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
  end,
}
ty_ex__zhugedan:addSkill(ty_ex__gongao)
ty_ex__zhugedan:addSkill(ty_ex__juyi)
ty_ex__zhugedan:addRelatedSkill("benghuai")
ty_ex__zhugedan:addRelatedSkill(ty_ex__weizhong)
Fk:loadTranslationTable{
  ["ty_ex__zhugedan"] = "界诸葛诞",
  ["#ty_ex__zhugedan"] = "薤露蒿里",
  ["ty_ex__gongao"] = "功獒",
  [":ty_ex__gongao"] = "锁定技，一名其他角色第一次进入濒死状态时，你加1点体力上限，然后回复1点体力。",
  ["ty_ex__juyi"] = "举义",
  [":ty_ex__juyi"] = "觉醒技，准备阶段开始时，若你已受伤且体力上限大于存活角色数，你将手牌摸至体力上限，然后获得技能〖崩坏〗和〖威重〗。",
  ["ty_ex__weizhong"] = "威重",
  [":ty_ex__weizhong"] = "锁定技，当你的体力上限变化时，你摸两张牌。",

  ["$ty_ex__gongao1"] = "待补充",
  ["$ty_ex__gongao2"] = "待补充",
  ["$ty_ex__juyi1"] = "待补充",
  ["$ty_ex__juyi2"] = "待补充",
  ["$ty_ex__weizhong"] = "待补充",
  ["$benghuai_ty_ex__zhugedan"] = "待补充",
  ["~ty_ex__zhugedan"] = "待补充",
}

local ty_ex__simalang = General(extension, "ty_ex__simalang", "wei", 3)
local ty_ex__junbing = fk.CreateTriggerSkill{
  name = "ty_ex__junbing",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.phase == Player.Finish and target:getHandcardNum() < target.hp
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(target, self.name, nil, "#ty_ex__junbing-invoke::"..player.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:drawCards(target, 1, self.name)
    if target == player or target.dead or player.dead or target:isKongcheng() then return false end
    local dummy1 = Fk:cloneCard("dilu")
    dummy1:addSubcards(target.player_cards[Player.Hand])
    room:obtainCard(player.id, dummy1, false, fk.ReasonGive)
    local n = #dummy1.subcards
    if target.dead or player.dead or #player:getCardIds("he") < n then return end
    local cards = room:askForCard(player, n, n, true, self.name, true, ".",
    "#ty_ex__junbing-give::"..target.id..":"..n)
    if #cards == n then
      local dummy2 = Fk:cloneCard("dilu")
      dummy2:addSubcards(cards)
      room:obtainCard(target.id, dummy2, false, fk.ReasonGive)
    end
  end,
}
ty_ex__simalang:addSkill(ty_ex__junbing)
local ty_ex__quji = fk.CreateActiveSkill{
  name = "ty_ex__quji",
  anim_type = "support",
  card_num = function ()
    return Self:getLostHp()
  end,
  min_target_num = 1,
  can_use = function(self, player)
    return player:isWounded() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected < Self:getLostHp() and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, to_select, selected, cards)
    return #selected < Self:getLostHp() and Fk:currentRoom():getPlayerById(to_select):isWounded()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local loseHp = table.find(effect.cards, function(id) return Fk:getCardById(id).color == Card.Black end)
    room:throwCard(effect.cards, self.name, player, player)
    local tos = effect.tos
    room:sortPlayersByAction(tos)
    for _, pid in ipairs(tos) do
      local to = room:getPlayerById(pid)
      if not to.dead and to:isWounded() then
        room:recover({
          who = to,
          num = 1,
          recoverBy = player,
          skillName = self.name
        })
      end
    end
    for _, pid in ipairs(tos) do
      local to = room:getPlayerById(pid)
      if not to.dead and to:isWounded() then
        to:drawCards(1, self.name)
      end
    end
    if loseHp and not player.dead then
      room:loseHp(player, 1, self.name)
    end
  end,
}
ty_ex__simalang:addSkill(ty_ex__quji)
Fk:loadTranslationTable{
  ["ty_ex__simalang"] = "界司马朗",
  ["#ty_ex__simalang"] = "再世神农",
  ["ty_ex__junbing"] = "郡兵",
  [":ty_ex__junbing"] = "一名角色的结束阶段，若其手牌数小于体力值，该角色可以摸一张牌并将所有手牌交给你，然后你可以将等量的牌交给该角色。",
  ["ty_ex__quji"] = "去疾",
  [":ty_ex__quji"] = "出牌阶段限一次，若你已受伤，你可以弃置X张牌，令至多X名已受伤的角色各回复1点体力（X为你已损失的体力值），然后其中仍受伤的角色各摸一张牌。若弃置的牌中包含黑色牌，你失去1点体力。",
  ["#ty_ex__junbing-give"] = "郡兵：可以将 %arg 张牌交给 %dest",
  ["#ty_ex__junbing-invoke"] = "郡兵：可以摸一张牌并将所有手牌交给 %dest",

  ["$ty_ex__junbing1"] = "待补充",
  ["$ty_ex__junbing2"] = "待补充",
  ["$ty_ex__quji1"] = "待补充",
  ["$ty_ex__quji2"] = "待补充",
  ["~ty_ex__simalang"] = "待补充",
}

return extension
