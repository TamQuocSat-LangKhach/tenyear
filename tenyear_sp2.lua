local extension = Package("tenyear_sp2")
extension.extensionName = "tenyear"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["tenyear_sp2"] = "十周年-限定专属2",
  ["ty_sp"] = "新服SP",
}

--计将安出：程昱 王允 蒋干 赵昂 刘晔 杨弘 郤正 桓范 刘琦
local ty__chengyu = General(extension, "ty__chengyu", "wei", 3)
Fk:addQmlMark{
  name = "ty__shefu",
  how_to_show = function(name, value, p)
    if type(value) ~= "table" then return " " end
    return tostring(#value)
  end,
  qml_path = function(name, value, p)
    if Self:isBuddy(p) then
      return "packages/tenyear/qml/ZixiBox"
    end
    return ""
  end,
}
local ty__shefu_active = fk.CreateActiveSkill{
  name = "ty__shefu_active",
  card_num = 1,
  target_num = 0,
  interaction = function(self)
    local mark = U.getMark(Self, "@[ty__shefu]")
    local all_names = U.getAllCardNames("btd", true)
    local names = table.filter(all_names, function(name)
      return table.every(mark, function(shefu_pair)
        return shefu_pair[2] ~= name
      end)
    end)
    if #names > 0 then
      return UI.ComboBox { choices = names, all_choices = all_names }
    end
  end,
  can_use = Util.FalseFunc,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and self.interaction.data
  end,
}
Fk:addSkill(ty__shefu_active)
local ty__shefu = fk.CreateTriggerSkill{
  name = "ty__shefu",
  anim_type = "control",
  derived_piles = "#ty__shefu_ambush",
  events ={fk.EventPhaseStart, fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Finish and not player:isNude()
      else
        return target ~= player and player.phase == Player.NotActive and
        table.find(U.getMark(player, "@[ty__shefu]"), function (shefu_pair)
          return shefu_pair[2] == data.card.trueName
        end)
         and U.IsUsingHandcard(target, data)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local success, dat = room:askForUseActiveSkill(player, "ty__shefu_active", "#ty__shefu-cost", true)
      if success then
        self.cost_data = dat
        return true
      end
    else
      if room:askForSkillInvoke(player, self.name, nil, "#ty__shefu-invoke::"..target.id..":"..data.card:toLogString()) then
        room:doIndicate(player.id, {target.id})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local cid = self.cost_data.cards[1]
      local name = self.cost_data.interaction
      player:addToPile("#ty__shefu_ambush", cid, true, self.name)
      if table.contains(player:getPile("#ty__shefu_ambush"), cid) then
        local mark = U.getMark(player, "@[ty__shefu]")
        table.insert(mark, {cid, name})
        room:setPlayerMark(player, "@[ty__shefu]", mark)
      end
    else
      local mark = U.getMark(player, "@[ty__shefu]")
      for i = 1, #mark, 1 do
        if mark[i][2] == data.card.trueName then
          local cid = mark[i][1]
          table.remove(mark, i)
          room:setPlayerMark(player, "@[ty__shefu]", #mark > 0 and mark or 0)
          if table.contains(player:getPile("#ty__shefu_ambush"), cid) then
            room:moveCardTo(cid, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name, nil, true, player.id)
          end
          break
        end
      end
      data.tos = {}
      room:sendLog{ type = "#CardNullifiedBySkill", from = target.id, arg = self.name, arg2 = data.card:toLogString() }
      if not target.dead and target.phase ~= Player.NotActive then
        room:setPlayerMark(target, "@@ty__shefu-turn", 1)
      end
    end
  end,

  refresh_events = {fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self and player:getMark("@[ty__shefu]") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@[ty__shefu]", 0)
  end,
}
local ty__shefu_invalidity = fk.CreateInvaliditySkill {
  name = "#ty__shefu_invalidity",
  invalidity_func = function(self, from, skill)
    return from:getMark("@@ty__shefu-turn") > 0 and skill:isPlayerSkill(from)
  end
}
ty__shefu:addRelatedSkill(ty__shefu_invalidity)
ty__chengyu:addSkill(ty__shefu)
local ty__benyu = fk.CreateTriggerSkill{
  name = "ty__benyu",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from and not data.from.dead
    and (player:getHandcardNum() < math.min(data.from:getHandcardNum(), 5) or #player:getCardIds("he") > data.from:getHandcardNum())
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askForUseActiveSkill(player, "ty__benyu_active", nil, true,
    {ty__benyu_data = {data.from.id, data.from:getHandcardNum()}})
    if success and dat then
      room:doIndicate(player.id, {data.from.id})
      self.cost_data = dat
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if self.cost_data.interaction == "ty__benyu_damage" then
      player.room:throwCard(self.cost_data.cards, self.name, player, player)
      player.room:damage{
        from = player,
        to = data.from,
        damage = 1,
        skillName = self.name,
      }
    else
      player:drawCards(math.min(5, data.from:getHandcardNum()) - player:getHandcardNum())
    end
  end,
}
ty__chengyu:addSkill(ty__benyu)
local ty__benyu_active = fk.CreateActiveSkill{
  name = "ty__benyu_active",
  prompt = function (self)
    local to = self.ty__benyu_data[1]
    local x = self.ty__benyu_data[2]
    if self.interaction.data == "ty__benyu_damage" then
      return "#ty__benyu-discard::"..to..":"..(x+1)
    else
      return "#ty__benyu-draw:::"..math.min(5, x)
    end
  end,
  interaction = function(self)
    local all_choices = {"ty__benyu_draw", "ty__benyu_damage"}
    local choices = {}
    if Self:getHandcardNum() < math.min(self.ty__benyu_data[2], 5) then
      table.insert(choices, all_choices[1])
    end
    if #Self:getCardIds("he") > self.ty__benyu_data[2] then
      table.insert(choices, all_choices[2])
    end
    if #choices > 0 then
      return UI.ComboBox { choices = choices, all_choices = all_choices }
    end
  end,
  target_num = 0,
  card_filter = function(self, to_select, selected)
    return self.interaction.data == "ty__benyu_damage" and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  feasible = function(self, selected, selected_cards)
    if self.interaction.data == "ty__benyu_damage" then
      return #selected_cards > self.ty__benyu_data[2]
    end
    return #selected_cards == 0
  end,
}
Fk:addSkill(ty__benyu_active)
Fk:loadTranslationTable{
  ["ty__chengyu"] = "程昱",
  ["#ty__chengyu"] = "泰山捧日",
  ["illustrator:ty__chengyu"] = "凝聚永恒",

  ["ty__shefu"] = "设伏",
  [":ty__shefu"] = "①结束阶段，你可以记录一个未被记录的基本牌或锦囊牌的牌名并扣置一张牌，称为“伏兵”；<br>"..
  "②当其他角色于你回合外使用手牌时，你可以移去一张记录牌名相同的“伏兵”，令此牌无效（若此牌有目标角色则改为取消所有目标），然后若此时是该角色的回合内，其本回合所有技能失效。",
  ["ty__benyu"] = "贲育",
  [":ty__benyu"] = "当你受到伤害后，你可以选择一项：1.将手牌摸至X张（最多摸至5张）；2.弃置至少X+1张牌，然后对伤害来源造成1点伤害（X为伤害来源的手牌数）。",

  ["ty__shefu_active"] = "设伏",
  ["#ty__shefu-cost"] = "设伏：你可以将一张牌扣置为“伏兵”",
  ["@[ty__shefu]"] = "伏兵",
  ["@@ty__shefu-turn"] = "设伏封技",
  ["#ty__shefu-invoke"] = "设伏：可以令 %dest 使用的 %arg 无效",
  ["#CardNullifiedBySkill"] = "由于 %arg 的效果，%from 使用的 %arg2 无效",
  ["ty__benyu_active"] = "贲育",
  ["#ty__benyu-discard"] = "贲育：你可以弃置至少%arg牌，对 %dest 造成1点伤害",
  ["#ty__benyu-draw"] = "贲育：你可以摸至 %arg 张牌",
  ["ty__benyu_draw"] = "摸牌",
  ["ty__benyu_damage"] = "弃牌并造成伤害",

  ["$ty__shefu1"] = "吾已埋下伏兵，敌兵一来，管教他瓮中捉鳖。",
  ["$ty__shefu2"] = "我已设下重重圈套，就等敌军入彀矣。",
  ["$ty__benyu1"] = "助曹公者昌，逆曹公者亡！",
  ["$ty__benyu2"] = "愚民不可共济大事，必当与智者为伍。",
  ["~ty__chengyu"] = "吾命休矣，何以仰报圣恩于万一……",
}

local wangyun = General(extension, "ty__wangyun", "qun", 4)
local ty__lianji = fk.CreateActiveSkill{
  name = "ty__lianji",
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  prompt= "#ty__lianji",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:throwCard(effect.cards, self.name, player, player)
    local cards = {}
    for i = 1, #room.draw_pile, 1 do
      local card = Fk:getCardById(room.draw_pile[i])
      if card.sub_type == Card.SubtypeWeapon then
        table.insertIfNeed(cards, room.draw_pile[i])
      end
    end
    if #cards > 0 then
      local card = Fk:getCardById(table.random(cards))
      if card.name == "qinggang_sword" then
        for _, id in ipairs(Fk:getAllCardIds()) do
          if Fk:getCardById(id).name == "seven_stars_sword" then
            card = Fk:getCardById(id)
            room:setCardMark(card, MarkEnum.DestructIntoDiscard, 1)
            break
          end
        end
      end
      if not target:isProhibited(target, card) then
        room:useCard({
          from = target.id,
          tos = {{target.id}},
          card = card,
        })
      end
    end
    if target.dead then return end
    local targets = table.map(room:getOtherPlayers(player), Util.IdMapper)
    local use = room:askForUseCard(target, "slash", "slash", "#ty__lianji-slash:"..player.id, true, {exclusive_targets = targets})
    if use then
      room:setPlayerMark(player, "ty__lianji1", 1)
      use.extraUse = true
      room:useCard(use)
      if not target.dead and target:getEquipment(Card.SubtypeWeapon) then
        local to = table.filter(TargetGroup:getRealTargets(use.tos), function(id) return not room:getPlayerById(id).dead end)
        if #to == 0 then return end
        if #to > 1 then
          to = room:askForChoosePlayers(target, to, 1, 1, "#ty__lianji-give", self.name, false)
        end
        to = room:getPlayerById(to[1])
        room:moveCardTo(Fk:getCardById(target:getEquipment(Card.SubtypeWeapon)),
          Card.PlayerHand, to, fk.ReasonGive, self.name, nil, true, target.id)
      end
    else
      room:setPlayerMark(player, "ty__lianji2", 1)
      room:useVirtualCard("slash", nil, player, target, self.name, true)
      if not player.dead and not target.dead and target:getEquipment(Card.SubtypeWeapon) then
        room:moveCardTo(Fk:getCardById(target:getEquipment(Card.SubtypeWeapon)),
          Card.PlayerHand, player, fk.ReasonGive, self.name, nil, true, target.id)
      end
    end
  end,
}
local ty__moucheng = fk.CreateTriggerSkill{
  name = "ty__moucheng",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:getMark("ty__lianji1") > 0 and player:getMark("ty__lianji2") > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:handleAddLoseSkills(player, "-ty__lianji|jingong", nil, true, false)
  end,
}
wangyun:addSkill(ty__lianji)
wangyun:addSkill(ty__moucheng)
wangyun:addRelatedSkill("jingong")
Fk:loadTranslationTable{
  ["ty__wangyun"] = "王允",
  ["#ty__wangyun"] = "忠魂不泯",
  ["illustrator:ty__wangyun"] = "Thinking",
  ["ty__lianji"] = "连计",
  [":ty__lianji"] = "出牌阶段限一次，你可以弃置一张手牌并选择一名其他角色，令其使用牌堆中的一张武器牌。然后该角色选择一项：1.对除你以外的一名角色"..
  "使用一张【杀】，并将武器牌交给其中一名目标角色；2.视为你对其使用一张【杀】，并将武器牌交给你。",
  ["ty__moucheng"] = "谋逞",
  [":ty__moucheng"] = "觉醒技，准备阶段，若你发动〖连计〗的两个选项都被选择过，则你失去〖连计〗，获得〖矜功〗。",
  ["#ty__lianji"] = "连计：弃置一张手牌，令一名角色使用牌堆中的一张武器牌并使用【杀】",
  ["#ty__lianji-slash"] = "连计：你需使用一张【杀】，否则 %src 视为对你使用【杀】",
  ["#ty__lianji-give"] = "连计：你需将武器交给其中一名目标角色",

  ["$ty__lianji1"] = "连环相扣，周密不失。",
  ["$ty__lianji2"] = "切记，此计连不可断。",
  ["$ty__moucheng1"] = "除贼安国，利于天下。",
  ["$ty__moucheng2"] = "董贼已擒，长安可兴。",
  ["$jingong_ty__wangyun1"] = "得民称赞，此功当邀。",
  ["$jingong_ty__wangyun2"] = "吾能擒董贼，又何惧怕？",
  ["~ty__wangyun"] = "奉先，你居然弃我而逃！",
}

local jianggan = General(extension, "jianggan", "wei", 3)
local weicheng = fk.CreateTriggerSkill{
  name = "weicheng",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) or player:getHandcardNum() >= player.hp then return false end
    for _, move in ipairs(data) do
      if move.from and move.from == player.id and move.to and move.to ~= player.id and move.toArea == Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,
}
local daoshu = fk.CreateActiveSkill{
  name = "daoshu",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local suits = {"log_spade", "log_club", "log_heart", "log_diamond"}
    local choice = room:askForChoice(player, suits, self.name)
    room:sendLog{
      type = "#DaoshuLog",
      from = player.id,
      to = effect.tos,
      arg = choice,
      arg2 = self.name,
      toast = true,
    }
    local card = room:askForCardChosen(player, target, "h", self.name)
    room:obtainCard(player, card, true, fk.ReasonPrey)
    if Fk:getCardById(card):getSuitString(true) == choice then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
      player:addSkillUseHistory(self.name, -1)
    else
      local suit = Fk:getCardById(card):getSuitString(true)
      table.removeOne(suits, suit)
      suits = table.map(suits, function(s) return s:sub(5) end)
      local others = table.filter(player:getCardIds(Player.Hand), function(id) return Fk:getCardById(id):getSuitString(true) ~= suit end)
      if #others > 0 then
        local cards = room:askForCard(player, 1, 1, false, self.name, false, ".|.|"..table.concat(suits, ","),
          "#daoshu-give::"..target.id..":"..suit)
        if #cards > 0 then
          cards = cards[1]
        else
          cards = table.random(others)
        end
        room:obtainCard(target, cards, true, fk.ReasonGive)
      else
        player:showCards(player:getCardIds(Player.Hand))
      end
    end
  end,
}
jianggan:addSkill(weicheng)
jianggan:addSkill(daoshu)
Fk:loadTranslationTable{
  ["jianggan"] = "蒋干",
  ["#jianggan"] = "锋谪悬信",
  ["designer:jianggan"] = "韩旭",
  ["illustrator:jianggan"] = "biou09",
  ["weicheng"] = "伪诚",
  [":weicheng"] = "你交给其他角色手牌，或你的手牌被其他角色获得后，若你的手牌数小于体力值，你可以摸一张牌。",
  ["daoshu"] = "盗书",
  [":daoshu"] = "出牌阶段限一次，你可以选择一名其他角色并选择一种花色，然后获得其一张手牌。若此牌与你选择的花色："..
  "相同，你对其造成1点伤害且此技能视为未发动过；不同，你交给其一张其他花色的手牌（若没有需展示所有手牌）。",
  ["#DaoshuLog"] = "%from 对 %to 发动了 “%arg2”，选择了 %arg",
  ["#daoshu-give"] = "盗书：交给 %dest 一张非%arg手牌",

  ["$weicheng1"] = "略施谋略，敌军便信以为真。",
  ["$weicheng2"] = "吾只观雅规，而非说客。",
  ["$daoshu1"] = "得此文书，丞相定可高枕无忧。",
  ["$daoshu2"] = "让我看看，这是什么机密。",
  ["~jianggan"] = "丞相，再给我一次机会啊！",
}

local zhaoang = General(extension, "zhaoang", "wei", 3, 4)
local zhongjie = fk.CreateTriggerSkill{
  name = "zhongjie",
  anim_type = "support",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryRound) == 0 and
    not data.damage and not target.dead and target.hp < 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askForSkillInvoke(player, self.name, data, "#zhongjie-invoke::"..target.id) then
      room:doIndicate(player.id, {target.id})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:recover{
      who = target,
      num = 1,
      recoverBy = player,
      skillName = self.name
    }
    if not target.dead then
      target:drawCards(1, self.name)
    end
  end,
}
local sushou = fk.CreateTriggerSkill{
  name = "sushou",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.phase == Player.Play and player.hp > 0 and not target.dead and
    table.every(player.room.alive_players, function (p)
      return p == target or p:getHandcardNum() < target:getHandcardNum()
    end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askForSkillInvoke(player, self.name, data, "#sushou-invoke::"..target.id) then
      room:doIndicate(player.id, {target.id})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, self.name)
    if player.dead then return false end
    local x = player:getLostHp()
    if x > 0 then
      room:drawCards(player, x, self.name)
    end
    if player == target then return false end
    local cards = target:getCardIds(Player.Hand)
    if #cards < 2 then return false end
    cards = table.random(cards, #cards // 2)
    local handcards = player:getCardIds(Player.Hand)
    cards = U.askForExchange(player, "needhand", "wordhand", cards, handcards, "#sushou-exchange::"..target.id .. ":" .. tostring(x), x)
    if #cards == 0 then return false end
    handcards = table.filter(cards, function (id)
      return table.contains(handcards, id)
    end)
    cards = table.filter(cards, function (id)
      return not table.contains(handcards, id)
    end)
    U.swapCards(room, player, player, target, handcards, cards, self.name)
  end,
}

zhaoang:addSkill(zhongjie)
zhaoang:addSkill(sushou)

Fk:loadTranslationTable{
  ["zhaoang"] = "赵昂",
  ["#zhaoang"] = "剜心筑城",
  ["designer:zhaoang"] = "残昼厄夜",
  ["illustrator:zhaoang"] = "君桓文化",
  ["zhongjie"] = "忠节",
  [":zhongjie"] = "每轮限一次，当一名角色因失去体力而进入濒死状态时，你可以令其回复1点体力并摸一张牌。",
  ["sushou"] = "夙守",
  [":sushou"] = "一名角色的出牌阶段开始时，若其手牌数是全场唯一最多的，你可以失去1点体力并摸X张牌。"..
  "若此时不是你的回合内，你观看当前回合角色一半数量的手牌（向下取整），你可以用至多X张手牌替换其中等量的牌。（X为你已损失的体力值）",

  ["#zhongjie-invoke"] = "你可以对%dest发动 忠节，令其回复1点体力并摸一张牌",
  ["#sushou-invoke"] = "你可以对%dest发动 夙守",
  ["#sushou-exchange"] = "夙守：选择要交换你与%dest的至多%arg张手牌",

  ["$zhongjie1"] = "气节之士，不可不救。",
  ["$zhongjie2"] = "志士遭祸，应施以援手。",
  ["$sushou1"] = "敌众我寡，怎可少谋？",
  ["$sushou2"] = "临城据守，当出奇计。",
  ["~zhaoang"] = "援军为何迟迟不至？",
}

local liuye = General(extension, "ty__liuye", "wei", 3)
local poyuan_catapult = {{"ty__catapult", Card.Diamond, 9}}
local poyuan = fk.CreateTriggerSkill{
  name = "poyuan",
  anim_type = "control",
  events = {fk.GameStart, fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and (event == fk.GameStart or (event == fk.TurnStart and target == player)) then
      if table.find(player:getEquipments(Card.SubtypeTreasure), function(id) return Fk:getCardById(id).name == "ty__catapult" end) then
        return table.find(player.room:getOtherPlayers(player), function(p) return not p:isNude() end)
      else
        local catapult = table.find(U.prepareDeriveCards(player.room, poyuan_catapult, "poyuan_catapult"), function (id)
          return player.room:getCardArea(id) == Card.Void
        end)
        return catapult and U.canMoveCardIntoEquip(player, catapult)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if table.find(player:getEquipments(Card.SubtypeTreasure), function(id) return Fk:getCardById(id).name == "ty__catapult" end) then
      local targets = table.filter(room:getOtherPlayers(player), function(p) return not p:isNude() end)
      if #targets == 0 then return end
      local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#poyuan-choose", self.name, true)
      if #tos > 0 then
        self.cost_data = tos[1]
        return true
      end
    else
      return room:askForSkillInvoke(player, self.name, nil, "#poyuan-invoke")
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if table.find(player:getEquipments(Card.SubtypeTreasure), function(id) return Fk:getCardById(id).name == "ty__catapult" end) then
      local to = room:getPlayerById(self.cost_data)
      local cards = room:askForCardsChosen(player, to, 1, 2, "he", self.name)
      room:throwCard(cards, self.name, to, player)
    else
      local catapult = table.find(U.prepareDeriveCards(room, poyuan_catapult, "poyuan_catapult"), function (id)
        return player.room:getCardArea(id) == Card.Void
      end)
      if catapult then
        room:setCardMark(Fk:getCardById(catapult), MarkEnum.DestructOutMyEquip, 1)
        U.moveCardIntoEquip (room, player, catapult, self.name, true, player)
      end
    end
  end,
}
local huace = fk.CreateViewAsSkill{
  name = "huace",
  interaction = function()
    local names = {}
    local mark = Self:getMark("huace2")
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id, true)
      if card:isCommonTrick() and card.trueName ~= "nullification" and card.name ~= "adaptation" and not card.is_derived then
        if mark == 0 or (not table.contains(mark, card.trueName)) then
          table.insertIfNeed(names, card.name)
        end
      end
    end
    return UI.ComboBox {choices = names}
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
}
local huace_record = fk.CreateTriggerSkill{
  name = "#huace_record",

  refresh_events = {fk.AfterCardUseDeclared, fk.RoundStart},
  can_refresh = function(self, event, target, player, data)
    return (event == fk.AfterCardUseDeclared and data.card:isCommonTrick()) or event == fk.RoundStart
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardUseDeclared then
      local mark = player:getMark("huace1")
      if mark == 0 then mark = {} end
      table.insertIfNeed(mark, data.card.trueName)
      room:setPlayerMark(player, "huace1", mark)
    else
      room:setPlayerMark(player, "huace2", player:getMark("huace1"))
      room:setPlayerMark(player, "huace1", 0)
    end
  end,
}
huace:addRelatedSkill(huace_record)
liuye:addSkill(poyuan)
liuye:addSkill(huace)
Fk:loadTranslationTable{
  ["ty__liuye"] = "刘晔",
  ["#ty__liuye"] = "佐世之才",
  ["cv:ty__liuye"] = "瀚涛",
  ["illustrator:ty__liuye"] = "一意动漫",
  ["poyuan"] = "破垣",
  [":poyuan"] = "游戏开始时或回合开始时，若你的装备区里没有【霹雳车】，你可以将【霹雳车】置于装备区；若有，你可以弃置一名其他角色至多两张牌。<br>"..
  "<font color='grey'>【霹雳车】<br>♦9 装备牌·宝物<br /><b>装备技能</b>：锁定技，你回合内使用基本牌的伤害和回复数值+1且无距离限制。"..
  "你回合外使用或打出基本牌时摸一张牌。离开你装备区时销毁。",
  ["huace"] = "画策",
  [":huace"] = "出牌阶段限一次，你可以将一张手牌当上一轮没有角色使用过的普通锦囊牌使用。",
  ["#poyuan-invoke"] = "破垣：你可以装备【霹雳车】",
  ["#poyuan-choose"] = "破垣：你可以弃置一名其他角色至多两张牌",

  ["$poyuan1"] = "砲石飞空，坚垣难存。",
  ["$poyuan2"] = "声若霹雳，人马俱摧。",
  ["$huace1"] = "筹画所料，无有不中。",
  ["$huace2"] = "献策破敌，所谋皆应。",
  ["~ty__liuye"] = "功名富贵，到头来，不过黄土一抔……",
}

local yanghong = General(extension, "yanghong", "qun", 3)
local ty__jianji = fk.CreateActiveSkill{
  name = "ty__jianji",
  anim_type = "control",
  card_num = 0,
  min_target_num = 1,
  max_target_num = function()
    return Self:getAttackRange()
  end,
  prompt = function ()
    return "#ty__jianji-prompt:::"..Self:getAttackRange()
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and player:getAttackRange() > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    if #selected < Self:getAttackRange() then
      if #selected == 0 then
        return true
      else
        for _, id in ipairs(selected) do
          local p = Fk:currentRoom():getPlayerById(id)
          if target:getNextAlive() == p or p:getNextAlive() == target then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local tos = effect.tos
    room:sortPlayersByAction(tos)
    tos = table.map(tos, Util.Id2PlayerMapper)
    for _, p in ipairs(tos) do
      room:askForDiscard(p, 1, 1, true, self.name, false)
    end
    tos = table.filter(tos, function(p) return not p.dead end)
    if #tos < 2 then return end
    local max_num = 0
    for _, p in ipairs(tos) do
      max_num = math.max(max_num, p:getHandcardNum())
    end
    local froms = table.filter(tos, function(p) return p:getHandcardNum() == max_num end)
    local from = (#froms == 1) and froms[1] or room:getPlayerById(
    room:askForChoosePlayers(player, table.map(froms, Util.IdMapper), 1, 1, "#ty__jianji-from", self.name, false)[1])
    local targets = table.filter(tos, function(p)
      return not p.dead and from:canUseTo(Fk:cloneCard("slash"), p, {bypass_times = true, bypass_distances = true})
    end)
    if #targets > 0 then
      local victim = room:askForChoosePlayers(from, table.map(targets, Util.IdMapper), 1, 1, "#ty__jianji-choose", self.name, true)
      if #victim > 0 then
        room:useVirtualCard("slash", nil, from, room:getPlayerById(victim[1]), self.name, true)
      end
    end
  end,
}
local yuanmo = fk.CreateTriggerSkill{
  name = "yuanmo",
  anim_type = "control",
  events = {fk.EventPhaseStart, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.EventPhaseStart then
        return player.phase == Player.Start or (player.phase == Player.Finish and
          table.every(player.room:getOtherPlayers(player), function(p) return not player:inMyAttackRange(p) end))
      else
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = "#yuanmo1-invoke"
    if event == fk.EventPhaseStart and player.phase == Player.Finish then
      prompt = "#yuanmo2-invoke"
    end
    return player.room:askForSkillInvoke(player, self.name, nil, prompt)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart and player.phase == Player.Finish then
      room:setPlayerMark(player, "@yuanmo", player:getMark("@yuanmo") + 1)  --此处不能用addMark
    else
      local choice = room:askForChoice(player, {"yuanmo_add", "yuanmo_minus"}, self.name)
      if choice == "yuanmo_add" then
        local nos = table.filter(room:getOtherPlayers(player), function(p) return player:inMyAttackRange(p) end)
        room:setPlayerMark(player, "@yuanmo", player:getMark("@yuanmo") + 1)
        local targets = {}
        for _, p in ipairs(room:getOtherPlayers(player)) do
          if player:inMyAttackRange(p) and not table.contains(nos, p) and not p:isNude() then
            table.insert(targets, p.id)
          end
        end
        local tos = room:askForChoosePlayers(player, targets, 1, #targets, "#yuanmo-choose", self.name, true)
        if #tos > 0 then
          room:sortPlayersByAction(tos)
          for _, id in ipairs(tos) do
            if player.dead then break end
            local p = room:getPlayerById(id)
            if not p.dead and not p:isNude() then
              local card = room:askForCardChosen(player, p, "he", self.name, "#yuanmo-prey:"..id)
              room:obtainCard(player.id, card, false, fk.ReasonPrey)
            end
          end
        end
      else
        room:setPlayerMark(player, "@yuanmo", player:getMark("@yuanmo") - 1)
        player:drawCards(2, self.name)
      end
    end
  end,
}
local yuanmo_attackrange = fk.CreateAttackRangeSkill{
  name = "#yuanmo_attackrange",
  correct_func = function (self, from, to)
    return from:getMark("@yuanmo")
  end,
}
yuanmo:addRelatedSkill(yuanmo_attackrange)
yanghong:addSkill(ty__jianji)
yanghong:addSkill(yuanmo)
Fk:loadTranslationTable{
  ["yanghong"] = "杨弘",
  ["#yanghong"] = "柔迩驭远",
  ["designer:yanghong"] = "黑寡妇无敌",
  ["illustrator:yanghong"] = "虫师网络",
  ["ty__jianji"] = "间计",
  [":ty__jianji"] = "出牌阶段限一次，你可以令至多X名相邻的角色各弃置一张牌（X为你的攻击范围），然后你令其中手牌数最多的一名角色选择是否视为对其中的另一名角色使用一张【杀】。",
  ["yuanmo"] = "远谟",
  [":yuanmo"] = "①准备阶段或你受到伤害后，你可以选择一项：1.令你的攻击范围+1，然后获得任意名因此进入你攻击范围内的角色各一张牌；"..
  "2.令你的攻击范围-1，然后摸两张牌。<br>②结束阶段，若你攻击范围内没有角色，你可以令你的攻击范围+1。",
  ["#ty__jianji-choose"] = "间计：你可以视为对其中一名角色使用【杀】",
  ["#ty__jianji-from"] = "间计：选择视为使用【杀】的角色",
  ["#ty__jianji-prompt"] = "间计:令至多 %arg 名相邻的角色各弃置一张牌",
  ["#yuanmo1-invoke"]= "远谟：你可以令攻击范围+1并获得进入你攻击范围的角色各一张牌，或攻击范围-1并摸两张牌",
  ["#yuanmo2-invoke"]= "远谟：你可以令攻击范围+1",
  ["@yuanmo"] = "远谟",
  ["yuanmo_add"] = "攻击范围+1，获得因此进入攻击范围的角色各一张牌",
  ["yuanmo_minus"] = "攻击范围-1，摸两张牌",
  ["#yuanmo-choose"] = "远谟：你可以获得任意名角色各一张牌",
  ["#yuanmo-prey"] = "远谟：选择 %src 的一张牌获得",

  ["$ty__jianji1"] = "备枭雄也，布虓虎也，当间之。",
  ["$ty__jianji2"] = "二虎和则我亡，二虎斗则我兴。",
  ["$yuanmo1"] = "强敌不可战，弱敌不可恕。",
  ["$yuanmo2"] = "孙伯符羽翼已丰，主公当图刘备。",
  ["~yanghong"] = "主公为何不听我一言？",
}

local xizheng = General(extension, "xizheng", "shu", 3)
local danyi = fk.CreateTriggerSkill{
  name = "danyi",
  anim_type = "drawcard",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.firstTarget then
      local room = player.room
      local targets = AimGroup:getAllTargets(data.tos)
      local use_event = room.logic:getCurrentEvent()
      local last_tos = {}
      U.getEventsByRule(room, GameEvent.UseCard, 1, function (e)
        if e.id < use_event.id then
          local use = e.data[1]
          if use.from == player.id then
            last_tos = TargetGroup:getRealTargets(use.tos)
            return true
          end
        end
      end, 0)
      if #last_tos == 0 then return false end
      local x = #table.filter(room.alive_players, function (p)
        return table.contains(targets, p.id) and table.contains(last_tos, p.id)
      end)
      if x > 0 then
        self.cost_data = x
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(self.cost_data, self.name)
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
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    if #selected > 1 or to_select == Self.id then return false end
    if #selected == 0 then
      return true
    elseif #selected == 1 then
      return Fk:currentRoom():getPlayerById(to_select).hp ~= Fk:currentRoom():getPlayerById(selected[1]).hp
    else
      return false
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:sortPlayersByAction(effect.tos)
    for _, id in ipairs(effect.tos) do
      local p = room:getPlayerById(id)
      if not p.dead then
        if not room:askForUseActiveSkill(p, "wencan_active", "#wencan-discard:"..player.id, true) then
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
local wencan_refresh = fk.CreateTriggerSkill{
  name = "#wencan_refresh",

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    if player == target and player:usedSkillTimes("wencan", Player.HistoryTurn) > 0 then
      return table.find(TargetGroup:getRealTargets(data.tos), function (pid)
        return player.room:getPlayerById(pid):getMark("@@wencan-turn") > 0
      end)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
}
local wencan_targetmod = fk.CreateTargetModSkill{
  name = "#wencan_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return player:usedSkillTimes("wencan", Player.HistoryTurn) > 0 and scope == Player.HistoryPhase and
    to and to:getMark("@@wencan-turn") > 0
  end,
  bypass_distances =  function(self, player, skill, card, to)
    return player:usedSkillTimes("wencan", Player.HistoryTurn) > 0 and to and to:getMark("@@wencan-turn") > 0
  end,
}
Fk:addSkill(wencan_active)
wencan:addRelatedSkill(wencan_refresh)
wencan:addRelatedSkill(wencan_targetmod)
xizheng:addSkill(danyi)
xizheng:addSkill(wencan)
Fk:loadTranslationTable{
  ["xizheng"] = "郤正",
  ["#xizheng"] = "君子有取",
  ["illustrator:xizheng"] = "黄宝",
  ["danyi"] = "耽意",
  [":danyi"] = "你使用牌指定目标后，若此牌目标与你使用的上一张牌有相同的目标，你可以摸X张牌（X为这些目标的数量）。",
  ["wencan"] = "文灿",
  [":wencan"] = "出牌阶段限一次，你可以选择至多两名体力值不同的角色，这些角色依次选择一项：1.弃置两张花色不同的牌；"..
  "2.本回合你对其使用牌无距离和次数限制。",
  ["#wencan"] = "文灿：选择至多两名体力值不同的角色，其弃牌或你对其使用牌无限制",
  ["@@wencan-turn"] = "文灿",
  ["wencan_active"] = "文灿",
  ["#wencan-discard"] = "文灿：弃置两张不同花色的牌，否则 %src 本回合对你使用牌无限制",

  ["$danyi1"] = "满城锦绣，何及笔下春秋？",
  ["$danyi2"] = "一心向学，不闻窗外风雨。",
  ["$wencan1"] = "宴友以文，书声喧哗，众宾欢也。",
  ["$wencan2"] = "众星灿于九天，犹雅文耀于万世。",
  ["~xizheng"] = "此生有涯，奈何学海无涯……",
}

local huanfan = General(extension, "huanfan", "wei", 3)
local jianzheng = fk.CreateActiveSkill{
  name = "jianzheng",
  anim_type = "control",
  target_num = 1,
  card_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cards = target.player_cards[Player.Hand]
    local availableCards = table.filter(cards, function(id)
      local card = Fk:getCardById(id)
      return U.getDefaultTargets(player, card, true, false)
    end)
    local get, _ = U.askforChooseCardsAndChoice(player, availableCards, {"OK"}, self.name, "#jianzheng-choose", {"Cancel"}, 1, 1, cards)
    local yes = false
    if #get > 0 then
      local id = get[1]
      room:obtainCard(player.id, id, false, fk.ReasonPrey)
      local card = Fk:getCardById(id)
      if not player.dead and table.contains(player:getCardIds("h"), id) and U.getDefaultTargets(player, card, true, false) then
        local use = U.askForUseRealCard(room, player, {id}, ".", self.name, "#jianzheng-use:::"..card:toLogString(), nil, false, false)
        if use then
          if table.contains(TargetGroup:getRealTargets(use.tos), target.id) then
            yes = true
          end
        end
      end
    end
    if yes then
      if not player.dead and not player.chained then
        player:setChainState(true)
      end
      if not target.dead and not target.chained then
        target:setChainState(true)
      end
      if not player.dead and not target.dead and not player:isKongcheng() then
        U.viewCards(target, player:getCardIds("h"), self.name, "$ViewCardsFrom:"..player.id)
      end
    end
  end,
}
local fumou = fk.CreateTriggerSkill{
  name = "fumou",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:isWounded()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(room.alive_players, Util.IdMapper)
    local tos = room:askForChoosePlayers(player, targets, 1, player:getLostHp(), "#fumou-choose:::"..player:getLostHp(), self.name, true)
    if #tos > 0 then
      room:sortPlayersByAction(tos)
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(self.cost_data) do
      local p = room:getPlayerById(id)
      if not p.dead then
        local choices = {}
        if #room:canMoveCardInBoard() > 0 then
          table.insert(choices, "fumou1")
        end
        if not p:isKongcheng() then
          table.insert(choices, "fumou2")
        end
        if #p:getCardIds("e") > 0 then
          table.insert(choices, "fumou3")
        end
        if #choices == 0 then
          --continue
        else
          local choice = room:askForChoice(p, choices, self.name)
          if choice == "fumou1" then
            local targets = room:askForChooseToMoveCardInBoard(p, "#fumou-move", self.name, false)
            room:askForMoveCardInBoard(p, room:getPlayerById(targets[1]), room:getPlayerById(targets[2]), self.name)
          elseif choice == "fumou2" then
            p:throwAllCards("h")
            if not p.dead then
              p:drawCards(2, self.name)
            end
          elseif choice == "fumou3" then
            p:throwAllCards("e")
            if p:isWounded() then
              room:recover({
                who = p,
                num = 1,
                recoverBy = player,
                skillName = self.name
              })
            end
          end
        end
      end
    end
  end,
}
huanfan:addSkill(jianzheng)
huanfan:addSkill(fumou)
Fk:loadTranslationTable{
  ["huanfan"] = "桓范",
  ["#huanfan"] = "雍国竝世",
  ["illustrator:huanfan"] = "虫师",
  ["jianzheng"] = "谏诤",
  [":jianzheng"] = "出牌阶段限一次，你可以观看一名其他角色的手牌，然后若其中有你可以使用的牌，你可以获得并使用其中一张。"..
  "若此牌指定了其为目标，则横置你与其武将牌，然后其观看你的手牌。",
  ["fumou"] = "腹谋",
  [":fumou"] = "当你受到伤害后，你可以令至多X名角色依次选择一项：1.移动场上一张牌；2.弃置所有手牌并摸两张牌；3.弃置装备区所有牌并回复1点体力。"..
  "（X为你已损失的体力值）",
  ["#jianzheng-choose"] = "谏诤：选择一张使用",
  ["#jianzheng-use"] = "谏诤：请使用%arg",
  ["#fumou-choose"] = "腹谋：你可以令至多%arg名角色依次选择执行一项",
  ["fumou1"] = "移动场上一张牌",
  ["fumou2"] = "弃置所有手牌，摸两张牌",
  ["fumou3"] = "弃置所有装备，回复1点体力",
  ["#fumou-move"] = "腹谋：请移动场上一张牌(选择两名角色)",

  ["$jianzheng1"] = "将军今出洛阳，恐难再回。",
  ["$jianzheng2"] = "贼示弱于外，必包藏祸心。",
  ["$fumou1"] = "某有良谋，可为将军所用。",
  ["$fumou2"] = "吾负十斗之囊，其盈一石之智。",
  ["~huanfan"] = "有良言而不用，君何愚哉……",
}

local ty__liuqi = General(extension, "ty__liuqi", "qun", 3)
ty__liuqi.subkingdom = "shu"
local ty__wenji = fk.CreateTriggerSkill{
  name = "ty__wenji",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and
    table.find(player.room:getOtherPlayers(player), function(p) return not p:isNude() end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isNude() end), Util.IdMapper), 1, 1, "#ty__wenji-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local card = room:askForCard(to, 1, 1, true, self.name, false, ".", "#ty__wenji-give::"..player.id)
    local mark = U.getMark(player, "@ty__wenji-turn")
    table.insertIfNeed(mark, Fk:getCardById(card[1]):getTypeString().."_char")
    room:setPlayerMark(player, "@ty__wenji-turn", mark)
    room:obtainCard(player, card[1], false, fk.ReasonGive, to.id)
  end,
}
local ty__wenji_record = fk.CreateTriggerSkill{
  name = "#ty__wenji_record",
  mute = true,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      local mark = U.getMark(player, "@ty__wenji-turn")
      return table.contains(mark, data.card:getTypeString().."_char")
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    for _, p in ipairs(player.room:getOtherPlayers(player)) do
      table.insertIfNeed(data.disresponsiveList, p.id)
    end
  end,
}
local ty__tunjiang = fk.CreateTriggerSkill{
  name = "ty__tunjiang",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Finish then
      local play_ids = {}
      player.room.logic:getEventsOfScope(GameEvent.Phase, 1, function (e)
        if e.data[2] == Player.Play and e.end_id then
          table.insert(play_ids, {e.id, e.end_id})
        end
        return false
      end, Player.HistoryTurn)
      if #play_ids == 0 then return true end
      local used = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local in_play = false
        for _, ids in ipairs(play_ids) do
          if e.id > ids[1] and e.id < ids[2] then
            in_play = true
            break
          end
        end
        if in_play then
          local use = e.data[1]
          if use.from == target.id and use.tos then
            if table.find(TargetGroup:getRealTargets(use.tos), function(pid) return pid ~= target.id end) then
              return true
            end
          end
        end
        return false
      end, Player.HistoryTurn)
      return #used == 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local kingdoms = {}
    for _, p in ipairs(player.room.alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    player:drawCards(#kingdoms)
  end,
}
ty__wenji:addRelatedSkill(ty__wenji_record)
ty__liuqi:addSkill(ty__wenji)
ty__liuqi:addSkill(ty__tunjiang)
Fk:loadTranslationTable{
  ["ty__liuqi"] = "刘琦",
  ["#ty__liuqi"] = "居外而安",
  ["illustrator:ty__liuqi"] = "黑羽",
  ["ty__wenji"] = "问计",
  [":ty__wenji"] = "出牌阶段开始时，你可以令一名其他角色交给你一张牌，你于本回合内使用与该牌类别相同的牌不能被其他角色响应。",
  ["ty__tunjiang"] = "屯江",
  [":ty__tunjiang"] = "结束阶段，若你于本回合出牌阶段内未使用牌指定过其他角色为目标，则你可以摸X张牌（X为全场势力数）。",
  ["#ty__wenji-choose"] = "问计：你可以令一名其他角色交给你一张牌",
  ["#ty__wenji-give"] = "问计：你需交给 %dest 一张牌",
  ["@ty__wenji-turn"] = "问计",

  ["$ty__wenji1"] = "琦，愿听先生教诲。",
  ["$ty__wenji2"] = "先生，此计可有破解之法？",
  ["$ty__tunjiang1"] = "这浑水，不蹚也罢。",
  ["$ty__tunjiang2"] = "荆州风云波澜动，唯守江夏避险峻。",
  ["~ty__liuqi"] = "这荆州，终究容不下我。",
}

--笔舌如椽：陈琳 杨修 骆统 王昶 程秉 杨彪 阮籍
local ty__chenlin = General(extension, "ty__chenlin", "wei", 3)
local ty__songci = fk.CreateActiveSkill{
  name = "ty__songci",
  anim_type = "control",
  mute = true,
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    local mark = U.getMark(player, self.name)
    return table.find(Fk:currentRoom().alive_players, function(p) return not table.contains(mark, p.id) end)
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    local mark = U.getMark(Self, self.name)
    return #selected == 0 and not table.contains(mark, to_select)
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local player = room:getPlayerById(effect.from)
    local mark = U.getMark(player, self.name)
    table.insert(mark, target.id)
    room:setPlayerMark(player, self.name, mark)
    if #target.player_cards[Player.Hand] <= target.hp then
      room:notifySkillInvoked(player, self.name, "support")
      player:broadcastSkillInvoke(self.name, 1)
      target:drawCards(2, self.name)
    else
      room:notifySkillInvoked(player, self.name, "control")
      player:broadcastSkillInvoke(self.name, 2)
      room:askForDiscard(target, 2, 2, true, self.name, false)
    end
  end,
}
local ty__songci_trigger = fk.CreateTriggerSkill{
  name = "#ty__songci_trigger",
  mute = true,
  main_skill = ty__songci,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    local mark = U.getMark(player, "ty__songci")
    return target == player and player:hasSkill(self) and player.phase == Player.Discard
    and table.every(player.room.alive_players, function (p) return table.contains(mark, p.id) end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, "ty__songci", "drawcard")
    player:broadcastSkillInvoke("ty__songci", 3)
    player:drawCards(1, "ty__songci")
  end,
}
ty__chenlin:addSkill("bifa")
ty__songci:addRelatedSkill(ty__songci_trigger)
ty__chenlin:addSkill(ty__songci)
Fk:loadTranslationTable{
  ["ty__chenlin"] = "陈琳",
  ["#ty__chenlin"] = "破竹之咒",
  ["illustrator:ty__chenlin"] = "Thinking", -- 破竹之咒 皮肤
  ["ty__songci"] = "颂词",
  [":ty__songci"] = "①出牌阶段，你可以选择一名角色（每名角色每局游戏限一次），若该角色的手牌数：不大于体力值，其摸两张牌；大于体力值，其弃置两张牌。②弃牌阶段结束时，若你对所有存活角色均发动过“颂词”，你摸一张牌。",
  ["#ty__songci_trigger"] = "颂词",

  ["$ty__songci1"] = "将军德才兼备，大汉之栋梁也！",
  ["$ty__songci2"] = "汝窃国奸贼，人人得而诛之！",
  ["$ty__songci3"] = "义军盟主，众望所归！",
  ["~ty__chenlin"] = "来人……我的笔呢……",
}

local yangxiu = General(extension, "ty__yangxiu", "wei", 3)
local ty__danlao = fk.CreateTriggerSkill{
  name = "ty__danlao",
  anim_type = "defensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (data.card.trueName == "slash" or data.card.type == Card.TypeTrick) and not U.isOnlyTarget(player, data, event)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#ty__danlao-invoke:::"..data.card:toLogString())
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
    table.insertIfNeed(data.nullifiedTargets, player.id)
  end,
}
local ty__jilei = fk.CreateTriggerSkill{
  name = "ty__jilei",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from and not data.from.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askForSkillInvoke(player, self.name, nil, "#ty__jilei-invoke::"..data.from.id) then
      room:doIndicate(player.id, {data.from.id})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(player, {"basic", "trick", "equip"}, self.name)
    local mark = U.getMark(data.from, "@ty__jilei")
    if table.insertIfNeed(mark, choice .. "_char") then
      room:setPlayerMark(data.from, "@ty__jilei", mark)
    end
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@ty__jilei") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@ty__jilei", 0)
  end,
}
local ty__jilei_prohibit = fk.CreateProhibitSkill{
  name = "#ty__jilei_prohibit",
  prohibit_use = function(self, player, card)
    if table.contains(U.getMark(player, "@ty__jilei"), card:getTypeString() .. "_char") then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds(Player.Hand), id)
      end)
    end
  end,
  prohibit_response = function(self, player, card)
    if table.contains(U.getMark(player, "@ty__jilei"), card:getTypeString() .. "_char") then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds(Player.Hand), id)
      end)
    end
  end,
  prohibit_discard = function(self, player, card)
    return table.contains(U.getMark(player, "@ty__jilei"), card:getTypeString() .. "_char")
  end,
}
ty__jilei:addRelatedSkill(ty__jilei_prohibit)
yangxiu:addSkill(ty__danlao)
yangxiu:addSkill(ty__jilei)
Fk:loadTranslationTable{
  ["ty__yangxiu"] = "杨修",
  ["#ty__yangxiu"] = "恃才放旷",
  ["illustrator:ty__yangxiu"] = "alien", -- 传说皮 度龙品酥
  ["ty__danlao"] = "啖酪",
  [":ty__danlao"] = "当你成为【杀】或锦囊牌的目标后，若你不是唯一目标，你可以摸一张牌，然后此牌对你无效。",
  ["ty__jilei"] = "鸡肋",
  [":ty__jilei"] = "当你受到伤害后，你可以声明一种牌的类别，伤害来源不能使用、打出或弃置你声明的此类手牌直到其下回合开始。",
  ["#ty__danlao-invoke"] = "啖酪：你可以摸一张牌，令 %arg 对你无效",
  ["#ty__jilei-invoke"] = "鸡肋：是否令 %dest 不能使用、打出、弃置一种类别的牌直到其下回合开始？",
  ["@ty__jilei"] = "鸡肋",

  ["$ty__danlao1"] = "此酪味美，诸君何不与我共食之？",
  ["$ty__danlao2"] = "来来来，丞相美意，不可辜负啊。",
  ["$ty__jilei1"] = "今进退两难，势若鸡肋，魏王必当罢兵而还。",
  ["$ty__jilei2"] = "汝可令士卒收拾行装，魏王明日必定退兵。",
  ["~ty__yangxiu"] = "自作聪明，作茧自缚，悔之晚矣……",
}

local luotong = General(extension, "ty__luotong", "wu", 3)
local renzheng = fk.CreateTriggerSkill{
  name = "renzheng",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.DamageFinished},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if not data.dealtRecorderId then return true end
      if data.extra_data and data.extra_data.renzheng_maxDamage then
        return data.damage < data.extra_data.renzheng_maxDamage
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
  end,

  refresh_events = {fk.AfterSkillEffect, fk.SkillEffect},
  can_refresh = function (self, event, target, player, data)
    return player == player.room.players[1]
  end,
  on_refresh = function(self, event, target, player, data)
    local e = player.room.logic:getCurrentEvent():findParent(GameEvent.Damage, true)
    if e then
      local dat = e.data[1]
      dat.extra_data = dat.extra_data or {}
      dat.extra_data.renzheng_maxDamage = dat.extra_data.renzheng_maxDamage or 0
      dat.extra_data.renzheng_maxDamage = math.max(dat.damage, dat.extra_data.renzheng_maxDamage)
    end
  end,
}
local jinjian = fk.CreateTriggerSkill{
  name = "jinjian",
  mute = true,
  events = {fk.DamageCaused, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.DamageCaused then
      return player:getMark("@@jinjian_plus-turn") > 0 or player.room:askForSkillInvoke(player, self.name, nil, "#jinjian1-invoke::"..data.to.id)
    else
      return player:getMark("@@jinjian_minus-turn") > 0 or player.room:askForSkillInvoke(player, self.name, nil, "#jinjian2-invoke")
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.DamageCaused then
      if player:getMark("@@jinjian_plus-turn") > 0 then
        room:notifySkillInvoked(player, self.name, "negative")
        room:setPlayerMark(player, "@@jinjian_plus-turn", 0)
        data.damage = data.damage - 1
      else
        room:notifySkillInvoked(player, self.name, "offensive")
        room:setPlayerMark(player, "@@jinjian_plus-turn", 1)
        data.damage = data.damage + 1
      end
    else
      if player:getMark("@@jinjian_minus-turn") > 0 then
        room:notifySkillInvoked(player, self.name, "negative")
        room:setPlayerMark(player, "@@jinjian_minus-turn", 0)
        data.damage = data.damage + 1
      else
        room:notifySkillInvoked(player, self.name, "defensive")
        room:setPlayerMark(player, "@@jinjian_minus-turn", 1)
        data.damage = data.damage - 1
      end
    end
  end,
}
luotong:addSkill(renzheng)
luotong:addSkill(jinjian)
Fk:loadTranslationTable{
  ["ty__luotong"] = "骆统",
  ["#ty__luotong"] = "蹇谔匪躬",
  ["illustrator:ty__luotong"] = "匠人绘",
  ["renzheng"] = "仁政",  --这两个烂大街的技能名大概率撞车叭……
  [":renzheng"] = "锁定技，当有伤害被减少或防止后，你摸两张牌。",
  ["jinjian"] = "进谏",
  [":jinjian"] = "当你造成伤害时，你可令此伤害+1，若如此做，你此回合下次造成的伤害-1且不能发动〖进谏〗；当你受到伤害时，你可令此伤害-1，"..
  "若如此做，你此回合下次受到的伤害+1且不能发动〖进谏〗。",
  ["#jinjian1-invoke"] = "进谏：你可以令对 %dest 造成的伤害+1",
  ["#jinjian2-invoke"] = "进谏：你可以令受到的伤害-1",
  ["@@jinjian_plus-turn"] = "进谏+",
  ["@@jinjian_minus-turn"] = "进谏-",


  ["$renzheng1"] = "仁政如水，可润万物。",
  ["$renzheng2"] = "为官一任，当造福一方。",
  ["$jinjian1"] = "臣代天子牧民，闻苛自当谏之。",
  ["$jinjian2"] = "为将者死战，为臣者死谏！",
  ["~ty__luotong"] = "而立之年，奈何早逝。",
}

local wangchang = General(extension, "ty__wangchang", "wei", 3)
local ty__kaiji = fk.CreateActiveSkill{
  name = "ty__kaiji",
  anim_type = "switch",
  switch_skill_name = "ty__kaiji",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if player:getSwitchSkillState(self.name, true) == fk.SwitchYang then
      player:drawCards(player.maxHp, self.name)
    else
      room:askForDiscard(player, 1, player.maxHp, true, self.name, false, ".", "#ty__kaiji-discard:::"..player.maxHp)
    end
  end,
}
local pingxi = fk.CreateTriggerSkill{
  name = "pingxi",
  anim_type = "control",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and player:getMark("pingxi-turn") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = player:getMark("pingxi-turn")
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p) return not p:isNude() end), Util.IdMapper)
    if #targets == 0 then return end
    local tos = room:askForChoosePlayers(player, targets, 1, n, "#pingxi-choose:::"..player:getMark("pingxi-turn"), self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(self.cost_data) do
      local p = room:getPlayerById(id)
      if not p:isNude() then
        local card = room:askForCardChosen(player, p, "he", self.name)
        room:throwCard({card}, self.name, p, player)
      end
    end
    for _, id in ipairs(self.cost_data) do
      if player.dead then return end
      local p = room:getPlayerById(id)
      if not p.dead then
        room:useVirtualCard("slash", nil, player, p, self.name, true)
      end
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player.phase ~= Player.NotActive
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.moveReason == fk.ReasonDiscard and move.toArea == Card.DiscardPile then
        player.room:addPlayerMark(player, "pingxi-turn", #move.moveInfo)
      end
    end
  end,
}
wangchang:addSkill(ty__kaiji)
wangchang:addSkill(pingxi)
Fk:loadTranslationTable{
  ["ty__wangchang"] = "王昶",
  ["#ty__wangchang"] = "攥策及江",
  ["designer:ty__wangchang"] = "韩旭",
  ["illustrator:ty__wangchang"] = "游漫美绘",
  ["ty__kaiji"] = "开济",
  [":ty__kaiji"] = "转换技，出牌阶段限一次，阳：你可以摸等于体力上限张数的牌；阴：你可以弃置至多等于体力上限张数的牌（至少一张）。",
  ["pingxi"] = "平袭",
  [":pingxi"] = "结束阶段，你可选择至多X名其他角色（X为本回合因弃置而进入弃牌堆的牌数），弃置这些角色各一张牌，然后视为对这些角色各使用一张【杀】。",
  ["#ty__kaiji-discard"] = "开济：你可以弃置至多%arg张牌",
  ["#pingxi-choose"] = "平袭：你可以选择至多%arg名角色，弃置这些角色各一张牌并视为对这些角色各使用一张【杀】",

  ["$ty__kaiji1"] = "谋虑渊深，料远若近。",
  ["$ty__kaiji2"] = "视昧而察，筹不虚运。",
  ["$pingxi1"] = "地有常险，守无常势。",
  ["$pingxi2"] = "国有常众，战无常胜。",
  ["~ty__wangchang"] = "志存开济，人亡政息……",
}

local chengbing = General(extension, "chengbing", "wu", 3)
local jingzao = fk.CreateActiveSkill{
  name = "jingzao",
  anim_type = "drawcard",
  prompt = function ()
    return "#jingzao-active:::" + tostring(3 + Self:getMark("jingzao-turn"))
  end,
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:getMark("jingzao-turn") > -3
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):getMark("jingzao-phase") == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(target, "jingzao-phase", 1)
    local n = 3 + player:getMark("jingzao-turn")
    if n < 1 then return false end
    local cards = room:getNCards(n)
    room:moveCards({
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
      proposer = player.id,
    })

    local pattern = table.concat(table.map(cards, function(id) return Fk:getCardById(id).trueName end), ",")
    if #room:askForDiscard(target, 1, 1, true, self.name, true, pattern, "#jingzao-discard:"..player.id) > 0 then
      room:addPlayerMark(player, "jingzao-turn", 1)
      room:moveCards({
        ids = cards,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
      })
      return
    end

    local to_get = {}
    while #cards > 0 do
      local id = table.random(cards)
      table.insert(to_get, id)
      local name = Fk:getCardById(id).trueName
      cards = table.filter(cards, function (id2)
        return Fk:getCardById(id2).trueName ~= name
      end)
    end
    room:setPlayerMark(player, "jingzao-turn", player:getMark("jingzao-turn") - #to_get)
    room:moveCardTo(to_get, Player.Hand, player, fk.ReasonJustMove, self.name, nil, true, player.id)
  end,
}
local enyu = fk.CreateTriggerSkill{
  name = "enyu",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from ~= player.id and (data.card:isCommonTrick() or
      data.card.trueName == "slash") and player:getMark("enyu-turn") ~= 0 and
      #table.filter(player:getMark("enyu-turn"), function(name) return name == data.card.trueName end) > 1
  end,
  on_use = function(self, event, target, player, data)
    table.insertIfNeed(data.nullifiedTargets, player.id)
  end,

  refresh_events = {fk.TargetConfirmed},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self, true)
    and (data.card:isCommonTrick() or data.card.trueName == "slash")
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = U.getMark(player, "enyu-turn")
    table.insert(mark, data.card.trueName)
    room:setPlayerMark(player, "enyu-turn", mark)
  end,
}
chengbing:addSkill(jingzao)
chengbing:addSkill(enyu)
Fk:loadTranslationTable{
  ["chengbing"] = "程秉",
  ["#chengbing"] = "通达五经",
  ["designer:chengbing"] = "韩旭",
  ["illustrator:chengbing"] = "匠人绘",
  ["jingzao"] = "经造",
  [":jingzao"] = "出牌阶段每名角色限一次，你可以选择一名其他角色并亮出牌堆顶三张牌，然后该角色选择一项："..
  "1.弃置一张与亮出牌同名的牌，然后此技能本回合亮出的牌数+1；"..
  "2.令你随机获得这些牌中牌名不同的牌各一张，每获得一张，此技能本回合亮出的牌数-1。",
  ["enyu"] = "恩遇",
  [":enyu"] = "锁定技，当你成为其他角色使用【杀】或普通锦囊牌的目标后，若你本回合已成为过同名牌的目标，此牌对你无效。",
  ["#jingzao-active"] = "发动 经造，选择一名其他角色，亮出牌堆顶的%arg张卡牌",
  ["#jingzao-discard"] = "经造：弃置一张同名牌使本回合“经造”亮出牌+1，或点“取消”令%src获得其中不同牌名各一张",

  ["$jingzao1"] = "闭门绝韦编，造经教世人。",
  ["$jingzao2"] = "著文成经，可教万世之人。",
  ["$enyu1"] = "君以国士待我，我必国士报之。",
  ["$enyu2"] = "吾本乡野腐儒，幸隆君之大恩。",
  ["~chengbing"] = "著经未成，此憾事也……",
}

local yangbiao = General(extension, "ty__yangbiao", "qun", 3)
local ty__zhaohan = fk.CreateTriggerSkill{
  name = "ty__zhaohan",
  anim_type = "drawcard",
  events = {fk.DrawNCards},
  on_use = function(self, event, target, player, data)
    data.n = data.n + 2
  end,
}
local ty__zhaohan_delay = fk.CreateTriggerSkill{
  name = "#ty__zhaohan_delay",
  events = {fk.EventPhaseEnd},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and player:usedSkillTimes(ty__zhaohan.name, Player.HistoryPhase) > 0 and not player:isKongcheng()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p)
      return p:isKongcheng() end), Util.IdMapper)
    if #targets > 0 then
      targets = room:askForChoosePlayers(player, targets, 1, 1, "#zhaohan-choose", self.name, true, true)
    end
    if #targets > 0 then
      local cards = player:getCardIds(Player.Hand)
      if #cards > 2 then
        cards = room:askForCard(player, 2, 2, false, self.name, false, ".", "#zhaohan-give::" .. targets[1])
      end
      if #cards > 0 then
        room:moveCardTo(cards, Player.Hand, room:getPlayerById(targets[1]), fk.ReasonGive, self.name, nil, false, player.id)
      end
    else
      room:askForDiscard(player, 2, 2, false, self.name, false, ".", "#zhaohan-discard")
    end
  end,
}
local jinjie = fk.CreateTriggerSkill{
  name = "jinjie",
  anim_type = "support",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not target.dead and player:usedSkillTimes(self.name, Player.HistoryRound) < 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(player, {"draw0", "draw1", "draw2", "draw3", "Cancel"},
    self.name, "#jinjie-invoke::"..target.id)
    if choice ~= "Cancel" then
      room:doIndicate(player.id, {target.id})
      self.cost_data = tonumber(string.sub(choice, 5, 5))
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = self.cost_data
    if x > 0 then
      room:drawCards(target, x, self.name)
      if player.dead or #player:getCardIds("he") < x or
      #room:askForDiscard(player, x, x, true, self.name, true, ".", "#jinjie-discard::"..target.id..":"..tostring(x)) == 0 or
      target.dead or not target:isWounded() then return false end
    end
    room:recover{
      who = target,
      num = 1,
      recoverBy = player,
      skillName = self.name
    }
  end,
}
local jue = fk.CreateTriggerSkill{
  name = "jue",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and not target.dead and target.phase == Player.Finish and
    player:usedSkillTimes(self.name, Player.HistoryRound) < 1 then
      local room = player.room
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, false)
      if turn_event == nil then return false end
      local end_id = turn_event.id
      local cards = {}
      U.getEventsByRule(room, GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              table.insertIfNeed(cards, info.cardId)
            end
          end
        end
        return false
      end, end_id)
      cards = table.filter(cards, function (id)
        return room:getCardArea(id) == Card.DiscardPile
      end)
      if #cards > 0 then
        self.cost_data = #cards
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local x = self.cost_data
    if target == player then
      local targets = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player, false), Util.IdMapper),
      1, 1, "#jue-choose:::" .. tostring(x), self.name, true)
      if #targets > 0 then
        self.cost_data = {targets[1], x}
        return true
      end
    else
      x = math.min(x, target.maxHp)
      if room:askForSkillInvoke(player, self.name, nil, "#jue-invoke::" .. target.id .. ":" .. tostring(x)) then
        room:doIndicate(player.id, {target.id})
        self.cost_data = {target.id, x}
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data[1])
    local x = math.min(self.cost_data[2], to.maxHp)
    for i = 1, x, 1 do
      local cards = {}
      for _, name in ipairs({"slash", "dismantlement", "amazing_grace"}) do
        local card = Fk:cloneCard(name)
        card.skillName = self.name
        if player:canUseTo(card, to, {bypass_distances = true, bypass_times = true}) then
          table.insert(cards, card)
        end
      end
      if #cards == 0 then break end
      local tos = {{to.id}}
      local card = table.random(cards)
      if card.trueName == "amazing_grace" and not player:isProhibited(player, card) then
        table.insert(tos, {player.id})
      end
      room:useCard{
        from = player.id,
        tos = tos,
        card = card,
        extraUse = true
      }
      if player.dead or to.dead then break end
    end
  end,
}
ty__zhaohan:addRelatedSkill(ty__zhaohan_delay)
yangbiao:addSkill(ty__zhaohan)
yangbiao:addSkill(jinjie)
yangbiao:addSkill(jue)
Fk:loadTranslationTable{
  ["ty__yangbiao"] = "杨彪",
  ["#ty__yangbiao"] = "德彰海内",
  ["cv:ty__yangbiao"] = "袁国庆",
  ["illustrator:ty__yangbiao"] = "DH", -- 忧心国事

  ["ty__zhaohan"] = "昭汉",
  [":ty__zhaohan"] = "摸牌阶段，你可以多摸两张牌，然后选择一项：1.交给一名没有手牌的角色两张手牌；2.弃置两张手牌。",
  ["jinjie"] = "尽节",
  [":jinjie"] = "一名角色进入濒死状态时，若你于此轮内未发动过此技能，你可以令其摸0-3张牌，"..
  "然后你可以弃置等量的牌令其回复1点体力。",
  ["jue"] = "举讹",
  [":jue"] = "一名角色的结束阶段，若你于此轮内未发动过此技能，你可以视为随机对其使用【过河拆桥】、【杀】或【五谷丰登】共计X次"..
  "（X为弃牌堆里于此回合内因弃置而移至此区域的牌数且至多为其体力上限，若其为你，改为你选择一名其他角色）。",

  ["#ty__zhaohan_delay"] = "昭汉",
  ["#zhaohan-choose"] = "昭汉：选择一名没有手牌的角色交给其两张手牌，或点“取消”则你弃置两张牌",
  ["#zhaohan-discard"] = "昭汉：弃置两张手牌",
  ["#zhaohan-give"] = "昭汉：选择两张手牌交给 %dest",
  ["draw0"] = "摸零张牌",
  ["draw3"] = "摸三张牌",
  ["#jinjie-invoke"] = "你可以发动 尽节，令 %dest 摸0-3张牌，然后你可以弃等量的牌令其回复体力",
  ["#jinjie-discard"] = "尽节：你可以弃置%arg张手牌，令 %dest 回复1点体力",
  ["#jue-choose"] = "你可以发动 举讹，选择一名其他角色，视为对其随机使用%arg张牌（【过河拆桥】、【杀】或【五谷丰登】）",
  ["#jue-invoke"] = "你可以发动 举讹，视为对 %dest 随机使用%arg张牌（【过河拆桥】、【杀】或【五谷丰登】）",

  ["$ty__zhaohan1"] = "此心昭昭，惟愿汉明。",
  ["$ty__zhaohan2"] = "天曰昭德！天曰昭汉！",
  ["$jinjie1"] = "大汉养士百载，今乃奉节之时。",
  ["$jinjie2"] = "尔等皆忘天地君亲师乎？",
  ["$jue1"] = "尔等一家之言，难堵天下悠悠之口。",
  ["$jue2"] = "区区黄门而敛财千万，可诛其九族。",
  ["~ty__yangbiao"] = "愧无日磾先见之明，犹怀老牛舐犊之爱……",
}

local ruanji = General(extension, "ruanji", "wei", 3)
local zhaowen = fk.CreateViewAsSkill{
  name = "zhaowen",
  pattern = ".|.|.|.|.|trick|.",
  prompt = "#zhaowen",
  interaction = function()
    local names = {}
    local mark = Self:getMark("zhaowen-turn")
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card:isCommonTrick() and not card.is_derived then
        local c = Fk:cloneCard(card.name)
        if ((Fk.currentResponsePattern == nil and card.skill:canUse(Self, c) and not Self:prohibitUse(c)) or
        (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(c))) then
          if mark == 0 or (not table.contains(mark, card.trueName)) then
            table.insertIfNeed(names, card.name)
          end
        end
      end
    end
    if #names == 0 then return false end
    return UI.ComboBox { choices = names }
  end,
  card_filter = function(self, to_select, selected)
    local card = Fk:getCardById(to_select)
    return #selected == 0 and card.color == Card.Black and card:getMark("@@zhaowen-turn") > 0
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return nil end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    local mark = player:getMark("zhaowen-turn")
    if mark == 0 then mark = {} end
    table.insert(mark, use.card.trueName)
    player.room:setPlayerMark(player, "zhaowen-turn", mark)
  end,
  enabled_at_play = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes("zhaowen", Player.HistoryTurn) > 0 and
      table.find(player:getCardIds("h"), function(id)
        return Fk:getCardById(id).color == Card.Black and Fk:getCardById(id):getMark("@@zhaowen-turn") > 0 end)
  end,
  enabled_at_response = function(self, player, response)
    return not response and Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):matchExp(self.pattern) and
      not player:isKongcheng() and player:usedSkillTimes("zhaowen", Player.HistoryTurn) > 0 and
      table.find(player:getCardIds("h"), function(id)
        return Fk:getCardById(id).color == Card.Black and Fk:getCardById(id):getMark("@@zhaowen-turn") > 0 end)
  end,
}
local zhaowen_trigger = fk.CreateTriggerSkill{
  name = "#zhaowen_trigger",
  main_skill = zhaowen,
  mute = true,
  events = {fk.EventPhaseStart, fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill("zhaowen") and player.phase == Player.Play then
      if event == fk.EventPhaseStart then
        return not player:isKongcheng()
      else
        return data.card.color == Card.Red and not data.card:isVirtual() and data.card:getMark("@@zhaowen-turn") > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return player.room:askForSkillInvoke(player, "zhaowen", nil, "#zhaowen-invoke")
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("zhaowen")
    if event == fk.EventPhaseStart then
      room:notifySkillInvoked(player, "zhaowen", "special")
      local cards = table.simpleClone(player:getCardIds("h"))
      player:showCards(cards)
      if not player.dead and not player:isKongcheng() then
        room:setPlayerMark(player, "zhaowen-turn", cards)
        for _, id in ipairs(cards) do
          room:setCardMark(Fk:getCardById(id, true), "@@zhaowen-turn", 1)
        end
      end
    else
      room:notifySkillInvoked(player, "zhaowen", "drawcard")
      player:drawCards(1, "zhaowen")
    end
  end,

  refresh_events = {fk.AfterCardsMove, fk.Death},
  can_refresh = function(self, event, target, player, data)
    if event == fk.Death and player ~= target then return end
    return player:getMark("zhaowen-turn") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("zhaowen-turn")
    if event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.toArea ~= Card.Processing then
          for _, info in ipairs(move.moveInfo) do
            table.removeOne(mark, info.cardId)
            room:setCardMark(Fk:getCardById(info.cardId), "@@zhaowen-turn", 0)
          end
        end
      end
      room:setPlayerMark(player, "zhaowen-turn", mark)
    elseif event == fk.Death then
      for _, id in ipairs(mark) do
        room:setCardMark(Fk:getCardById(id), "@@zhaowen-turn", 0)
      end
    end
  end,
}
local jiudun = fk.CreateTriggerSkill{
  name = "jiudun",
  anim_type = "defensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.color == Card.Black and data.from ~= player.id and
      (player.drank + player:getMark("@jiudun_drank") == 0 or not player:isKongcheng())
  end,
  on_cost = function(self, event, target, player, data)
    if player.drank + player:getMark("@jiudun_drank") == 0 then
      return player.room:askForSkillInvoke(player, self.name, nil, "#jiudun-invoke")
    else
      local card = player.room:askForDiscard(player, 1, 1, false, self.name, true, ".|.|.|hand", "#jiudun-card:::"..data.card:toLogString(), true)
      if #card > 0 then
        self.cost_data = card
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.drank + player:getMark("@jiudun_drank") == 0 then
      player:drawCards(1, self.name)
      room:useVirtualCard("analeptic", nil, player, player, self.name, false)
    else
      room:throwCard(self.cost_data, self.name, player, player)
      if data.card.sub_type == Card.SubtypeDelayedTrick then
        AimGroup:cancelTarget(data, player.id)
      else
        table.insertIfNeed(data.nullifiedTargets, player.id)
      end
    end
  end,
}

local jiudun__analepticSkill = fk.CreateActiveSkill{
  name = "jiudun__analepticSkill",
  prompt = "#analeptic_skill",
  max_turn_use_time = 1,
  mod_target_filter = function(self, to_select, _, _, card, _)
    return not table.find(Fk:currentRoom().alive_players, function(p)
      return p.dying
    end)
  end,
  can_use = function(self, player, card, extra_data)
    return ((extra_data and (extra_data.bypass_times or extra_data.analepticRecover)) or
      self:withinTimesLimit(player, Player.HistoryTurn, card, "analeptic", player))
  end,
  on_use = function(_, _, use)
    if not use.tos or #TargetGroup:getRealTargets(use.tos) == 0 then
      use.tos = { { use.from } }
    end

    if use.extra_data and use.extra_data.analepticRecover then
      use.extraUse = true
    end
  end,
  on_effect = function(_, room, effect)
    local to = room:getPlayerById(effect.to)
    if to.dead then return end
    if effect.extra_data and effect.extra_data.analepticRecover then
      room:recover({
        who = to,
        num = 1,
        recoverBy = room:getPlayerById(effect.from),
        card = effect.card,
      })
    else
      room:addPlayerMark(to, "@jiudun_drank", 1 + ((effect.extra_data or {}).additionalDrank or 0))
    end
  end,
}
Fk:addSkill(jiudun__analepticSkill)

local jiudun_rule = fk.CreateTriggerSkill{
  name = "#jiudun_rule",
  events = {fk.PreCardEffect},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jiudun) and data.to == player.id and data.card.trueName == "analeptic" and
    not (data.extra_data and data.extra_data.analepticRecover)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local card = data.card:clone()
    local c = table.simpleClone(data.card)
    for k, v in pairs(c) do
      card[k] = v
    end
    card.skill = jiudun__analepticSkill
    data.card = card
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function (self, event, target, player, data)
    return player == target and data.card.trueName == "slash" and player:getMark("@jiudun_drank") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + player:getMark("@jiudun_drank")
    data.extra_data = data.extra_data or {}
    data.extra_data.drankBuff = player:getMark("@jiudun_drank")
    player.room:setPlayerMark(player, "@jiudun_drank", 0)
  end,
}
zhaowen:addRelatedSkill(zhaowen_trigger)
jiudun:addRelatedSkill(jiudun_rule)
ruanji:addSkill(zhaowen)
ruanji:addSkill(jiudun)
Fk:loadTranslationTable{
  ["ruanji"] = "阮籍",
  ["#ruanji"] = "命世大贤",
  ["designer:ruanji"] = "韩旭",
  ["illustrator:ruanji"] = "匠人绘",
  ["zhaowen"] = "昭文",
  [":zhaowen"] = "出牌阶段开始时，你可以展示所有手牌。若如此做，本回合其中的黑色牌可以当任意一张普通锦囊牌使用（每回合每种牌名限一次），"..
  "其中的红色牌你使用时摸一张牌。",
  ["jiudun"] = "酒遁",
  [":jiudun"] = "以使用方法①使用的【酒】对你的作用效果改为：目标角色使用的下一张[杀]的伤害值基数+1。"..
  "当你成为其他角色使用黑色牌的目标后，若你未处于【酒】状态，你可以摸一张牌并视为使用一张【酒】；"..
  "若你处于【酒】状态，你可以弃置一张手牌令此牌对你无效。",

  ["#zhaowen"] = "昭文：将一张黑色“昭文”牌当任意普通锦囊牌使用（每回合每种牌名限一次）",
  ["#zhaowen_trigger"] = "昭文",
  ["#zhaowen-invoke"] = "昭文：你可以展示手牌，本回合其中黑色牌可以当任意锦囊牌使用，红色牌使用时摸一张牌",
  ["@@zhaowen-turn"] = "昭文",
  ["#jiudun-invoke"] = "酒遁：你可以摸一张牌，视为使用【酒】",
  ["#jiudun-card"] = "酒遁：你可以弃置一张手牌，令%arg对你无效",
  ["#jiudun_rule"] = "酒遁",
  ["@jiudun_drank"] = "酒",

  ["$zhaowen1"] = "我辈昭昭，正始之音浩荡。",
  ["$zhaowen2"] = "正文之昭，微言之绪，绝而复续。",
  ["$jiudun1"] = "籍不胜酒力，恐失言失仪。",
  ["$jiudun2"] = "秋月春风正好，不如大醉归去。",
  ["~ruanji"] = "诸君，欲与我同醉否？",
}

--豆蔻梢头：花鬘 辛宪英 薛灵芸 芮姬 段巧笑 田尚衣 柏灵筠 马伶俐
local huaman = General(extension, "ty__huaman", "shu", 3, 3, General.Female)
local manyi = fk.CreateTriggerSkill{
  name = "manyi",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.PreCardEffect},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.card.trueName == "savage_assault" and player.id == data.to
  end,
  on_use = Util.TrueFunc,
}
local mansi = fk.CreateViewAsSkill{
  name = "mansi",
  anim_type = "offensive",
  prompt = "#mansi",
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    local card = Fk:cloneCard("savage_assault")
    card:addSubcards(Self:getCardIds(Player.Hand))
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
}
local mansi_trigger = fk.CreateTriggerSkill{
  name = "#mansi_trigger",
  events = {fk.Damaged},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill("mansi") and data.card and data.card.trueName == "savage_assault"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, "@mansi")
    room:addPlayerMark(player, "@mansi", 1)
    player:broadcastSkillInvoke("mansi")
    room:notifySkillInvoked(player, "mansi", "drawcard")
  end,
}
local souying = fk.CreateTriggerSkill{
  name = "souying",
  mute = true,
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and not player:isNude() and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
    (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and #AimGroup:getAllTargets(data.tos) == 1 then
      local room = player.room
      local events = {}
      if target == player then
        if data.to == player.id or room:getCardArea(data.card) ~= Card.Processing then return false end
        events = room.logic:getEventsOfScope(GameEvent.UseCard, 2, function(e)
          local use = e.data[1]
          return use.from == player.id and table.contains(TargetGroup:getRealTargets(use.tos), data.to)
        end, Player.HistoryTurn)
      else
        if TargetGroup:getRealTargets(data.tos)[1] ~= player.id then return false end
        events = room.logic:getEventsOfScope(GameEvent.UseCard, 2, function(e)
          local use = e.data[1]
          return use.from == target.id and table.contains(TargetGroup:getRealTargets(use.tos), player.id)
        end, Player.HistoryTurn)
      end
      return #events > 1
    end
  end,
  on_cost = function(self, event, target, player, data)
    local prompt
    if target == player then
      prompt = "#souying1-invoke:::"..data.card:toLogString()
    else
      prompt = "#souying2-invoke:::"..data.card:toLogString()
    end
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", prompt, true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    player:broadcastSkillInvoke(self.name)
    if target == player then
      room:notifySkillInvoked(player, self.name, "drawcard")
      if not player.dead and room:getCardArea(data.card) == Card.Processing then
        room:obtainCard(player, data.card, true, fk.ReasonJustMove)
      end
    else
      room:notifySkillInvoked(player, self.name, "defensive")
      table.insertIfNeed(data.nullifiedTargets, player.id)
    end
  end,
}
local zhanyuan = fk.CreateTriggerSkill{
  name = "zhanyuan",
  anim_type = "special",
  events = {fk.EventPhaseStart},
  frequency = Skill.Wake,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:getMark("@mansi") > 6
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return p.gender == General.Male and not p:hasSkill("xili", true) end), Util.IdMapper)
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#zhanyuan-choose", self.name, true)
    if #to > 0 then
      room:handleAddLoseSkills(player, "xili|-mansi", nil, true, false)
      room:handleAddLoseSkills(room:getPlayerById(to[1]), "xili", nil, true, false)
    end
  end,
}
local xili = fk.CreateTriggerSkill{
  name = "xili",
  anim_type = "support",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.from and target ~= player and
      target:hasSkill(self, true, true) and target.phase ~= Player.NotActive and
      not data.to:hasSkill(self, true) and not player:isNude() and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#xili-invoke:"..data.from.id..":"..data.to.id, true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    data.damage = data.damage + 1
    if not player.dead then
      player:drawCards(2, self.name)
    end
    if not target.dead then
      target:drawCards(2, self.name)
    end
  end,
}
mansi:addRelatedSkill(mansi_trigger)
huaman:addSkill(manyi)
huaman:addSkill(mansi)
huaman:addSkill(souying)
huaman:addSkill(zhanyuan)
huaman:addRelatedSkill(xili)
Fk:loadTranslationTable{
  ["ty__huaman"] = "花鬘",
  ["#ty__huaman"] = "芳踪载馨",
  ["designer:ty__huaman"] = "梦魇狂朝",
  ["illustrator:ty__huaman"] = "木美人",
  ["manyi"] = "蛮裔",
  [":manyi"] = "锁定技，【南蛮入侵】对你无效。",
  ["mansi"] = "蛮嗣",
  [":mansi"] = "出牌阶段限一次，你可以将所有手牌当【南蛮入侵】使用；当一名角色受到【南蛮入侵】的伤害后，你摸一张牌。",
  ["souying"] = "薮影",
  [":souying"] = "每回合限一次，当你使用牌指定其他角色为唯一目标后，若此牌不是本回合你对其使用的第一张牌，你可以弃置一张牌获得之；"..
  "当其他角色使用牌指定你为唯一目标后，若此牌不是本回合其对你使用的第一张牌，你可以弃置一张牌令此牌对你无效。",
  ["zhanyuan"] = "战缘",
  [":zhanyuan"] = "觉醒技，准备阶段，若你发动〖蛮嗣〗获得不少于七张牌，你加1点体力上限并回复1点体力。然后你可以选择一名男性角色，"..
  "你与其获得技能〖系力〗，你失去技能〖蛮嗣〗。",
  ["xili"] = "系力",
  [":xili"] = "每回合限一次，其他拥有〖系力〗的角色于其回合内对没有〖系力〗的角色造成伤害时，你可以弃置一张牌令此伤害+1，然后你与其各摸两张牌。",
  ["#mansi"] = "蛮嗣：你可以将所有手牌当【南蛮入侵】使用",
  ["@mansi"] = "蛮嗣",
  ["#souying1-invoke"] = "薮影：你可以弃置一张牌，获得此%arg",
  ["#souying2-invoke"] = "薮影：你可以弃置一张牌，令此%arg对你无效",
  ["#zhanyuan-choose"] = "战缘：你可以与一名男性角色获得技能〖系力〗",
  ["#xili-invoke"] = "系力：你可以弃置一张牌，令 %src 对 %dest 造成的伤害+1，你与 %src 各摸两张牌",

  ["$manyi1"] = "南蛮女子，该当英勇善战！",
  ["$manyi2"] = "蛮族的力量，你可不要小瞧！",
  ["$mansi1"] = "承父母庇护，得此福气。",
  ["$mansi2"] = "多谢父母怜爱。",
  ["$souying1"] = "幽薮影单，只身勇斗！",
  ["$souying2"] = "真薮影移，险战不惧！",
  ["$zhanyuan1"] = "战中结缘，虽苦亦甜。",
  ["$zhanyuan2"] = "势不同，情相随。",
  ["$xili1"] = "系力而为，助君得胜。",
  ["$xili2"] = "有我在，将军此战必能一举拿下！",
  ["~ty__huaman"] = "南蛮之地的花，还在开吗……",
}

local xinxianying = General(extension, "ty__xinxianying", "wei", 3, 3, General.Female)
local ty__zhongjian = fk.CreateActiveSkill{
  name = "ty__zhongjian",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  card_filter = Util.FalseFunc,
  no_indicate = true,
  interaction = function(self)
    return UI.ComboBox { choices = {"ty__zhongjian_draw","ty__zhongjian_discard"} }
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and Fk:currentRoom():getPlayerById(to_select):getMark("ty__zhongjian_target-turn") == 0
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < (1 + player:getMark("ty__caishi_twice-turn"))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(to, "ty__zhongjian_target-turn", 1)
    local choice = self.interaction.data
    local mark = U.getMark(to, choice)
    table.insert(mark, player.id)
    room:setPlayerMark(to, choice, mark)
  end,
}
local ty__zhongjian_trigger = fk.CreateTriggerSkill{
  name = "#ty__zhongjian_trigger",
  mute = true,
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target ~= player then return false end
    if event == fk.Damage then
      return target and not target.dead and #U.getMark(target, "ty__zhongjian_discard") > 0
    else
      return not target.dead and #U.getMark(target, "ty__zhongjian_draw") > 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event == fk.Damage and "ty__zhongjian_discard" or "ty__zhongjian_draw"
    local mark = U.getMark(player, choice)
    room:setPlayerMark(player, choice, 0)
    room:sortPlayersByAction(mark)
    for _, pid in ipairs(mark) do
      if player.dead then break end
      local p = room:getPlayerById(pid)
      if event == fk.Damage then
        room:askForDiscard(target, 2, 2, true, "ty__zhongjian", false)
      else
        target:drawCards(2, "ty__zhongjian")
      end
      if not p.dead then
        p:drawCards(1, "ty__zhongjian")
      end
    end
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function (self, event, target, player, data)
    return table.contains(U.getMark(player, "ty__zhongjian_discard"), target.id)
    or table.contains(U.getMark(player, "ty__zhongjian_draw"), target.id)
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    for _, mark in ipairs({"ty__zhongjian_discard","ty__zhongjian_draw"}) do
      room:setPlayerMark(player, mark, table.filter(U.getMark(player, mark), function (pid)
        return pid ~= target.id
      end))
    end
  end,
}
ty__zhongjian:addRelatedSkill(ty__zhongjian_trigger)
xinxianying:addSkill(ty__zhongjian)
local ty__caishi = fk.CreateTriggerSkill{
  name = "ty__caishi",
  anim_type = "control",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player == target and player.phase == Player.Draw then
      return #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        local move = e.data[1]
        if move and move.to and player.id == move.to and move.toArea == Card.PlayerHand then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.DrawPile then
              return true
            end
          end
        end
      end, Player.HistoryPhase) > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local ids = {}
    player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      local move = e.data[1]
      if move and move.to and player.id == move.to and move.toArea == Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.DrawPile then
            table.insertIfNeed(ids, info.cardId)
          end
        end
      end
    end, Player.HistoryPhase)
    if #ids == 0 then return false end
    local different = table.find(ids, function(id) return Fk:getCardById(id).suit ~= Fk:getCardById(ids[1]).suit end)
    self.cost_data = different
    if different then
      return player:isWounded() and player.room:askForSkillInvoke(player, self.name, nil, "#ty__caishi-invoke")
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local different = self.cost_data
    if different then
      room:recover({ who = player,  num = 1, skillName = self.name })
      room:addPlayerMark(player, "@@ty__caishi_self-turn")
    else
      room:setPlayerMark(player, "ty__caishi_twice-turn", 1)
    end
  end,
}
local ty__caishi_prohibit = fk.CreateProhibitSkill{
  name = "#ty__caishi_prohibit",
  is_prohibited = function(self, from, to)
    return from:getMark("@@ty__caishi_self-turn") > 0 and from == to
  end,
}
ty__caishi:addRelatedSkill(ty__caishi_prohibit)
xinxianying:addSkill(ty__caishi)
Fk:loadTranslationTable{
  ["ty__xinxianying"] = "辛宪英",
  ["#ty__xinxianying"] = "忠鉴清识",
  ["illustrator:ty__xinxianying"] = "张晓溪", -- 战场绝版
  ["ty__zhongjian"] = "忠鉴",
  [":ty__zhongjian"] = "出牌阶段限一次，你可以秘密选择一名本回合未选择过的角色，并秘密选一项，直到你的下回合开始：1.当该角色下次造成伤害后，"..
  "其弃置两张牌；2.当该角色下次受到伤害后，其摸两张牌。当〖忠鉴〗被触发时，你摸一张牌。",
  ["ty__zhongjian_draw"] = "受到伤害后摸牌",
  ["ty__zhongjian_discard"] = "造成伤害后弃牌",
  ["#ty__zhongjian-choose"] = "忠鉴：选择一名角色，%arg",
  ["#ty__zhongjian_trigger"] = "忠鉴",
  ["ty__caishi"] = "才识",
  [":ty__caishi"] = "摸牌阶段结束时，若你本阶段摸的牌：花色相同，本回合〖忠鉴〗改为“出牌阶段限两次”；花色不同，你可以回复1点体力，然后本回合"..
  "你不能对自己使用牌。",
  ["#ty__caishi-invoke"] = "你可以回复1点体力，然后本回合你不能对自己使用牌",
  ["@@ty__caishi_self-turn"] = "才识",

  ["$ty__zhongjian1"] = "闻大忠似奸、大智若愚，不辨之难鉴之。",
  ["$ty__zhongjian2"] = "以眼为镜可正衣冠，以心为镜可鉴忠奸。",
  ["$ty__caishi1"] = "柔指弄弦商羽，缀符成乐，似落珠玉盘。",
  ["$ty__caishi2"] = "素手点墨二三，绘文成卷，集缤纷万千。",
  ["~ty__xinxianying"] = "百无一用是女子。",
}

local xuelingyun = General(extension, "xuelingyun", "wei", 3, 3, General.Female)
local xialei = fk.CreateTriggerSkill{
  name = "xialei",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) or player:getMark("xialei-turn") > 2 then return false end
    local room = player.room
    local move_event = room.logic:getCurrentEvent()
    local parent_event = move_event.parent
    local card_ids = {}
    if parent_event ~= nil then
      if parent_event.event == GameEvent.UseCard or parent_event.event == GameEvent.RespondCard then
        local parent_data = parent_event.data[1]
        if parent_data.from == player.id then
          card_ids = room:getSubcardsByRule(parent_data.card)
        end
      elseif parent_event.event == GameEvent.Pindian then
        local pindianData = parent_event.data[1]
        if pindianData.from == player then
          card_ids = room:getSubcardsByRule(pindianData.fromCard)
        else
          for toId, result in pairs(pindianData.results) do
            if player.id == toId then
              card_ids = room:getSubcardsByRule(result.toCard)
              break
            end
          end
        end
      end
    end
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
            Fk:getCardById(info.cardId).color == Card.Red then
              return true
            end
          end
        elseif #card_ids > 0 then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.Processing and table.contains(card_ids, info.cardId) and
            Fk:getCardById(info.cardId).color == Card.Red then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = room:getNCards(3 - player:getMark("xialei-turn"))
    if #ids == 1 then
      room:moveCards({
        ids = ids,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
    else
      local to_return, choice = U.askforChooseCardsAndChoice(player, ids, {"xialei_top", "xialei_bottom"}, self.name, "#xialei-chooose")
      local moveInfos = {
        ids = to_return,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      }
      table.removeOne(ids, to_return[1])
      if #ids > 0 then
        if choice == "xialei_top" then
          for i = #ids, 1, -1 do
            table.insert(room.draw_pile, 1, ids[i])
          end
        else
          for _, id in ipairs(ids) do
            table.insert(room.draw_pile, id)
          end
        end
      end
      room:moveCards(moveInfos)
    end
    room:addPlayerMark(player, "xialei-turn", 1)
  end,
}
local anzhi = fk.CreateActiveSkill{
  name = "anzhi",
  anim_type = "support",
  prompt = "#anzhi-active",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:getMark("anzhi-turn") == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".",
    }
    room:judge(judge)
    if judge.card.color == Card.Red then
      room:setPlayerMark(player, "xialei-turn", 0)
    elseif judge.card.color == Card.Black then
      room:addPlayerMark(player, "anzhi-turn", 1)
      local ids = {}
      room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              table.insertIfNeed(ids, info.cardId)
            end
          end
        end
        return false
      end, Player.HistoryTurn)
      ids = table.filter(ids, function (id) return room:getCardArea(id) == Card.DiscardPile end)
      if #ids == 0 then return end
      local to = room:askForChoosePlayers(player, table.map(table.filter(room:getAlivePlayers(), function(p)
        return p ~= room.current end), Util.IdMapper), 1, 1, "#anzhi-choose", self.name, true)
      if #to > 0 then
        local get = {}
        if #ids > 2 then
          get = room:askForCardsChosen(player, player, 2, 2, {
            card_data = {
              { "pile_discard", ids }
            }
          }, self.name, "#anzhi-cards::" .. to[1])
        else
          get = ids
        end
        if #get > 0 then
          room:moveCards({
            ids = get,
            to = to[1],
            toArea = Card.PlayerHand,
            moveReason = fk.ReasonJustMove,
            proposer = player.id,
            skillName = self.name,
            moveVisible = false,
            visiblePlayers = player.id,
          })
        end
      end
    end
  end,
}
local anzhi_trigger = fk.CreateTriggerSkill{
  name = "#anzhi_trigger",
  anim_type = "masochism",
  events = {fk.Damaged},
  main_skill = anzhi,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:getMark("anzhi-turn") == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#anzhi-invoke")
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(anzhi.name)
    anzhi:onUse(player.room, {
      from = player.id,
      cards = {},
      tos = {},
    })
  end,
}
anzhi:addRelatedSkill(anzhi_trigger)
xuelingyun:addSkill(xialei)
xuelingyun:addSkill(anzhi)
Fk:loadTranslationTable{
  ["xuelingyun"] = "薛灵芸",
  ["#xuelingyun"] = "霓裳缀红泪",
  ["designer:xuelingyun"] = "懵萌猛梦",
  ["illustrator:xuelingyun"] = "Jzeo",
  ["xialei"] = "霞泪",
  [":xialei"] = "当你的红色牌进入弃牌堆后，你可观看牌堆顶的三张牌，然后你获得一张并可将其他牌置于牌堆底，你本回合观看牌数-1。",
  ["anzhi"] = "暗织",
  ["#anzhi_trigger"] = "暗织",
  [":anzhi"] = "出牌阶段或当你受到伤害后，你可以进行一次判定，若结果为：红色，重置〖霞泪〗；"..
  "黑色，你可以令一名非当前回合角色获得本回合进入弃牌堆的两张牌，且你本回合不能再发动此技能。",
  ["#xialei-chooose"] = "霞泪：选择一张卡牌获得",
  ["xialei_top"] = "将剩余牌置于牌堆顶",
  ["xialei_bottom"] = "将剩余牌置于牌堆底",
  ["#anzhi-active"] = "发动暗织，进行判定",
  ["#anzhi-invoke"] = "是否使用暗织，进行判定",
  ["#anzhi-choose"] = "暗织：你可以令一名非当前回合角色获得本回合进入弃牌堆的两张牌",
  ["#anzhi-cards"] = "暗织：选择2张卡牌令%dest获得",

  ["$xialei1"] = "采霞揾晶泪，沾我青衫湿。",
  ["$xialei2"] = "登车入宫墙，垂泪凝如瑙。",
  ["$anzhi1"] = "深闱行彩线，唯手熟尔。",
  ["$anzhi2"] = "星月独照人，何谓之暗？",
  ["~xuelingyun"] = "寒月隐幕，难作衣裳。",
}

local ruiji = General(extension, "ty__ruiji", "wu", 4, 4, General.Female)
local wangyuan = fk.CreateTriggerSkill{
  name = "wangyuan",
  anim_type = "special",
  derived_piles = "ruiji_wang",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player.phase == Player.NotActive and #player:getPile("ruiji_wang") < #player.room.players then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#wangyuan-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local names = {}
    for _, id in ipairs(player:getPile("ruiji_wang")) do
      table.insertIfNeed(names, Fk:getCardById(id, true).trueName)
    end
    local cards = table.filter(room.draw_pile, function(id)
      local card = Fk:getCardById(id)
      return card.type ~= Card.TypeEquip and not table.contains(names, card.trueName)
    end)
    if #cards > 0 then
      player:addToPile("ruiji_wang", table.random(cards), true, self.name)
    end
  end,
}
local lingyin = fk.CreateViewAsSkill{
  name = "lingyin",
  anim_type = "offensive",
  prompt = "#lingyin-viewas",
  pattern = "duel",
  card_filter = function(self, to_select, selected)
    local card = Fk:getCardById(to_select)
    return #selected == 0 and (card.sub_type == Card.SubtypeWeapon or card.sub_type == Card.SubtypeArmor)
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("duel")
    card:addSubcard(cards[1])
    return card
  end,
  enabled_at_play = function(self, player)
    return player:getMark("@@lingyin-turn") > 0
  end,
}
local lingyin_trigger = fk.CreateTriggerSkill{
  name = "#lingyin_trigger",
  mute = true,
  expand_pile = "ruiji_wang",
  main_skill = lingyin,
  events = {fk.EventPhaseStart, fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.EventPhaseStart then
        return player.phase == Player.Play and #player:getPile("ruiji_wang") > 0
      else
        return player:getMark("@@lingyin-turn") > 0 and not data.chain and data.to ~= player
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local n = player.room:getTag("RoundCount")
      local cards = player.room:askForCard(player, 1, n, false, "liying", true,
        ".|.|.|ruiji_wang|.|.", "#lingyin-invoke:::"..tostring(n), "ruiji_wang")
      if #cards > 0 then
        self.cost_data = cards
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local room = player.room
      player:broadcastSkillInvoke("lingyin")
      room:notifySkillInvoked(player, "lingyin", "drawcard")
      local cards = table.simpleClone(self.cost_data)
      local colors = {}
      for _, id in ipairs(player:getPile("ruiji_wang")) do
        if not table.contains(cards, id) then
          table.insertIfNeed(colors, Fk:getCardById(id).color)
        end
      end
      if #colors < 2 then
        room:setPlayerMark(player, "@@lingyin-turn", 1)
      end
      room:obtainCard(player, cards, true, fk.ReasonJustMove)
    else
      data.damage = data.damage + 1
    end
  end,
}
local liying = fk.CreateTriggerSkill{
  name = "liying",
  anim_type = "support",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player.phase ~= Player.Draw and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Player.Hand then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local ids = {}
    for _, move in ipairs(data) do
      if move.to == player.id and move.toArea == Player.Hand then
        for _, info in ipairs(move.moveInfo) do
          table.insertIfNeed(ids, info.cardId)
        end
      end
    end
    local prompt = "#liying1-invoke"
    if player.phase ~= Player.NotActive and #player:getPile("ruiji_wang") < #room.players then
      prompt = "#liying2-invoke"
    end
    local tos, cards = U.askForChooseCardsAndPlayers(room, player, 1, 999,
    table.map(room:getOtherPlayers(player, false), Util.IdMapper), 1, 1, tostring(Exppattern{ id = ids }),
    prompt, self.name, true, false)
    if #tos > 0 and #cards > 0 then
      self.cost_data = {tos, cards}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ret = self.cost_data
    room:obtainCard(ret[1][1], ret[2], false, fk.ReasonGive, player.id)
    if not player.dead then
      player:drawCards(1, self.name)
      if not player.dead and player.phase ~= Player.NotActive and #player:getPile("ruiji_wang") < #room.players then
        local skill = Fk.skills["wangyuan"]
        skill:use(event, target, player, data)
      end
    end
  end,
}
lingyin:addRelatedSkill(lingyin_trigger)
ruiji:addSkill(wangyuan)
ruiji:addSkill(lingyin)
ruiji:addSkill(liying)
Fk:loadTranslationTable{
  ["ty__ruiji"] = "芮姬",
  ["#ty__ruiji"] = "柔荑弄钺",
  ["designer:ty__ruiji"] = "韩旭",
  ["illustrator:ty__ruiji"] = "匠人绘",
  ["wangyuan"] = "妄缘",
  [":wangyuan"] = "当你于回合外失去牌后，你可以随机将牌堆中一张基本牌或锦囊牌置于你的武将牌上，称为“妄”（“妄”的牌名不重复且至多为游戏人数）。",
  ["lingyin"] = "铃音",
  [":lingyin"] = "出牌阶段开始时，你可以获得至多X张“妄”（X为游戏轮数）。然后若“妄”颜色均相同，你本回合对其他角色造成的伤害+1且"..
  "可以将武器或防具牌当【决斗】使用。",
  ["liying"] = "俐影",
  [":liying"] = "每回合限一次，当你于摸牌阶段外获得牌后，你可以将其中任意张牌交给一名其他角色，然后你摸一张牌。若此时是你的回合内，再增加一张“妄”。",
  ["#wangyuan-invoke"] = "妄缘：是否增加一张“妄”？",
  ["ruiji_wang"] = "妄",
  ["#lingyin-invoke"] = "铃音：获得至多%arg张“妄”，然后若剩余“妄”颜色相同，你本回合伤害+1且可以将武器、防具当【决斗】使用",
  ["#lingyin-viewas"] = "发动 铃音，将一张武器牌或防具牌当【决斗】使用",
  ["@@lingyin-turn"] = "铃音",
  ["liying_active"] = "俐影",
  ["#liying1-invoke"] = "俐影：你可以将其中任意张牌交给一名其他角色，然后摸一张牌",
  ["#liying2-invoke"] = "俐影：你可以将其中任意张牌交给一名其他角色，然后摸一张牌并增加一张“妄”",

  ["$wangyuan1"] = "小女子不才，愿伴公子余生。",
  ["$wangyuan2"] = "纵有万钧之力，然不斩情丝。",
  ["$lingyin1"] = "环佩婉尔，心动情动铃儿动。",
  ["$lingyin2"] = "小鹿撞入我怀，银铃焉能不鸣？",
  ["$liying1"] = "飞影略白鹭，日暮栖君怀。",
  ["$liying2"] = "妾影婆娑，摇曳君心。",
  ["~ty__ruiji"] = "佳人芳华逝，空余孤铃鸣……",
}

local duanqiaoxiao = General(extension, "duanqiaoxiao", "wei", 3, 3, General.Female)
local caizhuang = fk.CreateActiveSkill{
  name = "caizhuang",
  anim_type = "drawcard",
  prompt = function (self, selected_cards, selected_targets)
    local suits = {}
    local suit = Card.NoSuit
    for _, id in ipairs(selected_cards) do
      suit = Fk:getCardById(id).suit
      if suit ~= Card.NoSuit then
        table.insertIfNeed(suits, suit)
      end
    end
    return "#caizhuang-active:::" .. tostring(#suits)
  end,
  min_card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local suits = {}
    local suit = Card.NoSuit
    for _, id in ipairs(effect.cards) do
      suit = Fk:getCardById(id).suit
      if suit ~= Card.NoSuit then
        table.insertIfNeed(suits, suit)
      end
    end
    room:throwCard(effect.cards, self.name, player, player)
    local x = #suits
    if x == 0 then return end
    while true do
      player:drawCards(1, self.name)
      suits = {}
      for _, id in ipairs(player:getCardIds("h")) do
        suit = Fk:getCardById(id).suit
        if suit ~= Card.NoSuit then
          table.insertIfNeed(suits, suit)
        end
      end
      if #suits >= x then return end
    end
  end,
}
local huayi = fk.CreateTriggerSkill{
  name = "huayi",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".|.|^nosuit",
    }
    room:judge(judge)
    if judge.card.color ~= Card.NoColor then
      room:setPlayerMark(player, "@huayi", judge.card:getColorString())
    end
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@huayi") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@huayi", 0)
  end,
}
local huayi_trigger = fk.CreateTriggerSkill{
  name = "#huayi_trigger",
  mute = true,
  events = {fk.TurnEnd, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if player:getMark("@huayi") ~= 0 then
      if event == fk.TurnEnd then
        return player:getMark("@huayi") == "red"
      elseif event == fk.Damaged then
        return target == player and player:getMark("@huayi") == "black"
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnEnd then
      player:broadcastSkillInvoke("huayi")
      room:notifySkillInvoked(player, "huayi", "drawcard")
      player:drawCards(1, "huayi")
    elseif event == fk.Damaged then
      player:broadcastSkillInvoke("huayi")
      room:notifySkillInvoked(player, "huayi", "drawcard")
      player:drawCards(2, "huayi")
    end
  end,
}
huayi:addRelatedSkill(huayi_trigger)
duanqiaoxiao:addSkill(caizhuang)
duanqiaoxiao:addSkill(huayi)
Fk:loadTranslationTable{
  ["duanqiaoxiao"] = "段巧笑",
  ["#duanqiaoxiao"] = "柔荑点绛唇",
  ["designer:duanqiaoxiao"] = "韩旭",
  ["illustrator:duanqiaoxiao"] = "Jzeo",

  ["caizhuang"] = "彩妆",
  [":caizhuang"] = "出牌阶段限一次，你可以弃置任意张牌，然后重复摸牌直到手牌中的花色数等同于弃牌花色数。",
  ["huayi"] = "华衣",
  [":huayi"] = "结束阶段，你可以判定，然后直到你的下回合开始时根据结果获得以下效果：红色，每个回合结束时摸一张牌；黑色，受到伤害后摸两张牌。",
  ["#caizhuang-active"] = "发动 彩妆，弃置任意张牌（包含的花色数：%arg）",
  ["@huayi"] = "华衣",

  ["$caizhuang1"] = "素手调脂粉，女子自有好颜色。",
  ["$caizhuang2"] = "为悦己者容，撷彩云为妆。",
  ["$huayi1"] = "皓腕凝霜雪，罗襦绣鹧鸪。",
  ["$huayi2"] = "绝色戴珠玉，佳人配华衣。",
  ["~duanqiaoxiao"] = "佳人时光少，君王总薄情……",
}

local tianshangyi = General(extension, "tianshangyi", "wei", 3, 3, General.Female)
local posuo = fk.CreateViewAsSkill{
  name = "posuo",
  prompt = "#posuo-viewas",
  interaction = function()
    local mark = U.getMark(Self, "@posuo-phase")
    local names = Self:getMark("posuo_names")
    if type(names) ~= "table" then
      names = {}
      for _, id in ipairs(Fk:getAllCardIds()) do
        local card = Fk:getCardById(id)
        if card.is_damage_card and not card.is_derived then
          names[card.name] = names[card.name] or {}
          table.insertIfNeed(names[card.name], card:getSuitString(true))
        end
      end
      Self:setMark("posuo_names", names)
    end
    local choices, all_choices = {}, {}
    for name, suits in pairs(names) do
      local _suits = {}
      for _, suit in ipairs(suits) do
        if not table.contains(mark, suit) then
          table.insert(_suits, U.ConvertSuit(suit, "sym", "icon"))
        end
      end
      local posuo_name = "posuo_name:::" .. name.. ":" .. table.concat(_suits, "")
      table.insert(all_choices, posuo_name)
      if #_suits > 0 then
        local to_use = Fk:cloneCard(name)
        if Self:canUse(to_use) and not Self:prohibitUse(to_use) then
          table.insert(choices, posuo_name)
        end
      end
    end
    if #choices == 0 then return false end
    return UI.ComboBox { choices = choices, all_choices = all_choices }
  end,
  enabled_at_play = function(self, player)
    local mark = player:getMark("@posuo-phase")
    return mark ~= "posuo_prohibit" and mark == 0 or (#mark < 4)
  end,
  card_filter = function(self, to_select, selected)
    if self.interaction.data == nil or #selected > 0 or
    Fk:currentRoom():getCardArea(to_select) == Player.Equip then return false end
    local card = Fk:getCardById(to_select)
    local posuo_name = string.split(self.interaction.data, ":")
    return string.find(posuo_name[#posuo_name], U.ConvertSuit(card.suit, "int", "icon"))
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return nil end
    local posuo_name = string.split(self.interaction.data, ":")
    local card = Fk:cloneCard(posuo_name[4])
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    local mark = U.getMark(Self, "@posuo-phase")
    table.insert(mark, use.card:getSuitString(true))
    player.room:setPlayerMark(player, "@posuo-phase", mark)
  end,
}
local posuo_refresh = fk.CreateTriggerSkill{
  name = "#posuo_refresh",

  refresh_events = {fk.EventAcquireSkill, fk.HpChanged},
  can_refresh = function(self, event, target, player, data)
    if not player:hasSkill(posuo, true) or player.phase ~= Player.Play or
    player:getMark("@posuo-phase") == "posuo_prohibit" then return false end
    if event == fk.HpChanged then
      return data.damageEvent and data.damageEvent.from == player
    elseif event == fk.EventAcquireSkill then
      return data == posuo and player == target
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.HpChanged then
      player.room:setPlayerMark(player, "@posuo-phase", "posuo_prohibit")
    elseif event == fk.EventAcquireSkill then
      local room = player.room
      U.getActualDamageEvents(room, 1, function (e)
        local damage = e.data[1]
        if damage.from == player then
          room:setPlayerMark(player, "@posuo-phase", "posuo_prohibit")
          return true
        end
      end, Player.HistoryPhase)
    end
  end,
}
local xiaoren = fk.CreateTriggerSkill{
  name = "xiaoren",
  anim_type = "offensive",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:getMark("xiaoren_break-turn") == 0 and
    (player:usedSkillTimes(self.name) == 0 or data.skillName == self.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".|.|^nosuit",
    }
    room:judge(judge)
    if player.dead then return false end
    if judge.card.color == Card.Red then
      local targets = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper)
      , 1, 1, "#xiaoren-recover", self.name, true)
      if #targets > 0 then
        local tar = room:getPlayerById(targets[1])
        if tar:isWounded() then
          room:recover({
            who = tar,
            num = 1,
            recoverBy = player,
            skillName = self.name,
          })
          if not (tar.dead or tar:isWounded()) then
            room:drawCards(tar, 1, self.name)
          end
        else
          room:drawCards(tar, 1, self.name)
        end
      end
    elseif judge.card.color == Card.Black then
      local tar = data.to
      if tar.dead then return false end
      local targets = table.map(table.filter(room.alive_players, function (p)
        return p:getNextAlive() == tar or tar:getNextAlive() == p
      end), Util.IdMapper)
      if #targets == 0 then return false end
      targets = room:askForChoosePlayers(player, targets, 1, 1, "#xiaoren-damage::" .. tar.id, self.name, false)
      tar = room:getPlayerById(targets[1])
      room:damage{
        from = player,
        to = tar,
        damage = 1,
        skillName = self.name,
      }
    end
  end,

  refresh_events = {fk.EnterDying},
  can_refresh = function (self, event, target, player, data)
    return not player.dead and player:getMark("xiaoren_break-turn") == 0 and player:usedSkillTimes(self.name) > 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "xiaoren_break-turn", 1)
  end,
}
posuo:addRelatedSkill(posuo_refresh)
tianshangyi:addSkill(posuo)
tianshangyi:addSkill(xiaoren)

Fk:loadTranslationTable{
  ["tianshangyi"] = "田尚衣",
  ["#tianshangyi"] = "婀娜盈珠袖",
  ["designer:tianshangyi"] = "韩旭",
  ["illustrator:tianshangyi"] = "alien",
  ["posuo"] = "婆娑",
  [":posuo"] = "出牌阶段每种花色限一次，若你本阶段未对其他角色造成过伤害，你可以将一张手牌当此花色有的一张伤害牌使用。",
  ["xiaoren"] = "绡刃",
  [":xiaoren"] = "每回合限一次，当你造成伤害后，你可以进行一次判定，"..
  "若结果为红色，你可令一名角色回复1点体力，然后若其满体力，其摸一张牌；"..
  "若结果为黑色，对受伤角色的上家或下家造成1点伤害，然后你可以再次进行判定并执行对应结果直到有角色进入濒死状态。",

  ["#posuo-viewas"] = "发动 婆娑，将一张手牌当此花色有的一张伤害牌来使用",
  ["posuo_name"] = "%arg [%arg2]",
  ["@posuo-phase"] = "婆娑",
  ["posuo_prohibit"] = "失效",
  ["#xiaoren-recover"] = "绡刃：可令一名角色回复1点体力，然后若其满体力，其摸一张牌",
  ["#xiaoren-damage"] = "绡刃：对%dest的上家或下家造成1点伤害，未濒死可继续发动此技能",

  ["$posuo1"] = "绯纱婆娑起，佳人笑靥红。",
  ["$posuo2"] = "红烛映俏影，一舞影斑斓。",
  ["$xiaoren1"] = "红绡举腕重，明眸最溺人。",
  ["$xiaoren2"] = "飘然回雪轻，言然游龙惊。",
  ["~tianshangyi"] = "红梅待百花，魏宫无春风……",
}

local bailingyun = General(extension, "bailingyun", "wei", 3, 3, General.Female)
local linghui = fk.CreateTriggerSkill{
  name = "linghui",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target.phase == Player.Finish then
      if player == target then return true end
      local logic = player.room.logic
      local dyingevents = logic.event_recorder[GameEvent.Dying] or Util.DummyTable
      local turnevents = logic.event_recorder[GameEvent.Turn] or Util.DummyTable
      return #dyingevents > 0 and #turnevents > 0 and dyingevents[#dyingevents].id > turnevents[#turnevents].id
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = room:getNCards(3)
    local use = U.askForUseRealCard(room, player, ids, ".", self.name, "#linghui-use",
    {expand_pile = ids, bypass_times = true}, false, true)
    if use then
      table.removeOne(ids, use.card:getEffectiveId())
    end
    for i = #ids, 1, -1 do
      table.insert(room.draw_pile, 1, ids[i])
    end
    if not player.dead and use then
      room:moveCards{
        ids = table.random(ids, 1),
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      }
    end
  end,
}
local xiace = fk.CreateTriggerSkill{
  name = "xiace",
  anim_type = "masochism",
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.Damage then
        return player:getMark("xiace_damage-turn") == 0 and not player:isNude()
      else
        return player:getMark("xiace_damaged-turn") == 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.Damage then
      local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#xiace-recover", true)
      if #card > 0 then
        self.cost_data = card
        return true
      end
    else
      local room = player.room
      local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
      targets = room:askForChoosePlayers(player, targets, 1, 1, "#xiace-control", self.name, true)
      if #targets > 0 then
        self.cost_data = targets[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damage then
      room:setPlayerMark(player, "xiace_damage-turn", 1)
      room:throwCard(self.cost_data, self.name, player)
      if not player.dead and player:isWounded() then
        room:recover {
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name,
        }
      end
    else
      room:setPlayerMark(player, "xiace_damaged-turn", 1)
      local tar = room:getPlayerById(self.cost_data)
      room:addPlayerMark(tar, "@@xiace-turn")
      room:addPlayerMark(tar, MarkEnum.UncompulsoryInvalidity .. "-turn")
    end
  end
}
local yuxin = fk.CreateTriggerSkill{
  name = "yuxin",
  frequency = Skill.Limited,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askForSkillInvoke(player, self.name, nil, "#yuxin-invoke::"..target.id) then
      room:doIndicate(player.id, {target.id})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:recover {
      who = target,
      num = math.max(1, player.hp) - target.hp,
      recoverBy = player,
      skillName = self.name,
    }
  end,
}
bailingyun:addSkill(linghui)
bailingyun:addSkill(xiace)
bailingyun:addSkill(yuxin)

Fk:loadTranslationTable{
  ["bailingyun"] = "柏灵筠",
  ["#bailingyun"] = "玲珑心窍",
  ["designer:bailingyun"] = "残昼厄夜",
  ["illustrator:bailingyun"] = "君桓文化",
  ["linghui"] = "灵慧",
  [":linghui"] = "一名角色的结束阶段，若其为你或有角色于本回合内进入过濒死状态，"..
  "你可以观看牌堆顶的三张牌，你可以使用其中一张牌，然后随机获得剩余牌中的一张。",
  ["xiace"] = "黠策",
  [":xiace"] = "每回合各限一次，当你受到伤害后，你可令一名其他角色的所有非锁定技于本回合内失效；"..
  "当你造成伤害后，你可以弃置一张牌并回复1点体力。",
  ["yuxin"] = "御心",
  [":yuxin"] = "限定技，当一名角色进入濒死状态时，你可以令其回复体力至X点（X为你的体力值且至少为1）。",

  ["#linghui-use"] = "灵慧：你可以使用其中的一张牌，然后获得剩余的随机一张",
  ["#xiace-recover"] = "是否发动 黠策，弃置一张牌来回复1点体力",
  ["#xiace-control"] = "是否发动 黠策，选择一名其他角色，令其本回合所有非锁定技失效",
  ["@@xiace-turn"] = "黠策",
  ["#yuxin-invoke"] = "是否对 %dest 发动 御心",

  ["$linghui1"] = "福兮祸所依，祸兮福所伏。",
  ["$linghui2"] = "枯桑知风，沧海知寒。",
  ["$xiace1"] = "风之积非厚，其负大翼也无力。",
  ["$xiace2"] = "人情同于抔土，岂穷达而异心。",
  ["$yuxin1"] = "得一人知情识趣，何妨同甘共苦。",
  ["$yuxin2"] = "临千军而不改其静，御心无波尔。",
  ["~bailingyun"] = "世人皆惧司马，独我痴情仲达……",
}

local malingli = General(extension, "malingli", "shu", 3, 3, General.Female)
local lima = fk.CreateDistanceSkill{
  name = "lima",
  correct_func = function(self, from, to)
    if from:hasSkill(self) then
      local n = 0
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        for _, id in ipairs(p:getCardIds("e")) do
          local card_type = Fk:getCardById(id).sub_type
          if card_type == Card.SubtypeOffensiveRide or card_type == Card.SubtypeDefensiveRide then
            n = n + 1
          end
        end
      end
      return -math.max(1, n)
    end
    return 0
  end,
}
local xiaoyin = fk.CreateTriggerSkill{
  name = "xiaoyin",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = #table.filter(room.alive_players, function(p)
      return player == p or player:distanceTo(p) == 1
    end)
    local ids = room:getNCards(n)
    room:moveCards{
      ids = ids,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
      proposer = player.id,
    }
    room:delay(2000)
    local to_get = {}
    for i = #ids, 1, -1 do
      if Fk:getCardById(ids[i]).color == Card.Red then
        table.insert(to_get, ids[i])
        table.remove(ids, i)
      end
    end
    if #to_get > 0 then
      room:obtainCard(player.id, to_get, true, fk.ReasonJustMove)
    end
    local targets = {}
    while #ids > 0 and not player.dead do
      room:setPlayerMark(player, "xiaoyin_cards", ids)
      room:setPlayerMark(player, "xiaoyin_targets", targets)
      local success, dat = room:askForUseActiveSkill(player, "xiaoyin_active", "#xiaoyin-give", true)
      room:setPlayerMark(player, "xiaoyin_cards", 0)
      room:setPlayerMark(player, "xiaoyin_targets", 0)
      if not success then break end
      table.insert(targets, dat.targets[1])
      table.removeOne(ids, dat.cards[1])
      room:getPlayerById(dat.targets[1]):addToPile("xiaoyin", dat.cards[1], true, self.name)
    end
    if #ids > 0 then
      room:moveCards{
        ids = ids,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
      }
    end
  end,
}
local xiaoyin_active = fk.CreateActiveSkill{
  name = "xiaoyin_active",
  mute = true,
  card_num = 1,
  target_num = 1,
  expand_pile = function (self)
    return U.getMark(Self, "xiaoyin_cards")
  end,
  card_filter = function(self, to_select, selected, targets)
    return #selected == 0 and table.contains(U.getMark(Self, "xiaoyin_cards"), to_select)
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected == 0 and to_select ~= Self.id then
      local targets = U.getMark(Self, "xiaoyin_targets")
      if #targets == 0 then return true end
      if table.contains(targets, to_select) then return false end
      local target = Fk:currentRoom():getPlayerById(to_select)
      if table.contains(targets, target:getNextAlive().id) then return true end
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        if p:getNextAlive() == target then
          return table.contains(targets, p.id)
        end
      end
    end
  end,
}
local xiaoyin_trigger = fk.CreateTriggerSkill{
  name = "#xiaoyin_trigger",
  mute = true,
  events = {fk.DamageInflicted},
  can_trigger = function (self, event, target, player, data)
    if target == player and #player:getPile("xiaoyin") > 0 and data.from and not data.from.dead then
      if data.damageType == fk.FireDamage then
        return not data.from:isNude()
      else
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    if data.damageType == fk.FireDamage then
      local types = {}
      for _, id in ipairs(target:getPile("xiaoyin")) do
        table.insertIfNeed(types, Fk:getCardById(id):getTypeString())
      end
      local card = player.room:askForDiscard(data.from, 1, 1, true, self.name, true,
      ".|.|.|.|.|"..table.concat(types, ","), "#xiaoyin-damage::"..target.id, true)
      if #card > 0 then
        self.cost_data = card
        return true
      end
    else
      return player.room:askForSkillInvoke(data.from, "xiaoyin", nil, "#xiaoyin-fire::"..target.id)
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if data.from:hasSkill(xiaoyin, true) then
      data.from:broadcastSkillInvoke("xiaoyin")
      room:notifySkillInvoked(data.from, "xiaoyin", "offensive")
    end
    room:doIndicate(data.from.id, {target.id})
    if data.damageType == fk.FireDamage then
      local card_type = Fk:getCardById(self.cost_data[1]).type
      room:throwCard(self.cost_data, "xiaoyin", data.from, data.from)
      local ids = table.filter(target:getPile("xiaoyin"), function(id)
        return Fk:getCardById(id).type == card_type end)
      if #ids > 0 then
        room:moveCards({
          from = target.id,
          ids = table.random(ids, 1),
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonPutIntoDiscardPile,
          skillName = "xiaoyin",
          specialName = "xiaoyin",
        })
        data.damage = data.damage + 1
      end
    else
      local id = room:askForCardChosen(data.from, target, {
        card_data = {
          { "xiaoyin", target:getPile("xiaoyin") }
        }
      }, "xiaoyin", "#xiaoyin-fire::" .. target.id)
      room:moveCardTo(id, Card.PlayerHand, data.from, fk.ReasonJustMove, self.name, nil, true, data.from.id)
      data.damageType = fk.FireDamage
    end
  end,
}
local huahuo = fk.CreateViewAsSkill{
  name = "huahuo",
  anim_type = "offensive",
  pattern = "fire__slash",
  prompt = "#huahuo",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Red and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("fire__slash")
    card.skillName = self.name
    card:addSubcard(cards[1])
    return card
  end,
  before_use = function(self, player, use)
    use.extraUse = true
    local room = player.room
    local tos = TargetGroup:getRealTargets(use.tos)
    if table.find(tos, function(id) return #room:getPlayerById(id):getPile("xiaoyin") > 0 end) and
      table.find(room:getOtherPlayers(player), function(p) return not table.contains(tos, p.id) and #p:getPile("xiaoyin") > 0 end) then
      if room:askForSkillInvoke(player, self.name, nil, "#huahuo-invoke") then
        for _, p in ipairs(room:getOtherPlayers(player)) do
          if not table.contains(tos, p.id) and #p:getPile("xiaoyin") > 0 and not player:isProhibited(p, use.card) then
            TargetGroup:pushTargets(use.tos, p.id)
          end
        end
      end
    end
  end,
  enabled_at_play = function (self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  enabled_at_response = function(self, player, response)
    return false
  end,
}
Fk:addSkill(xiaoyin_active)
xiaoyin:addRelatedSkill(xiaoyin_trigger)
malingli:addSkill(lima)
malingli:addSkill(xiaoyin)
malingli:addSkill(huahuo)
Fk:loadTranslationTable{
  ["malingli"] = "马伶俐",
  ["#malingli"] = "火树银花",
  ["designer:malingli"] = "星移",
  ["illustrator:malingli"] = "匠人绘",
  
  ["lima"] = "骊马",
  [":lima"] = "锁定技，场上每有一张坐骑牌，你计算与其他角色的距离-1（至少为1）。",
  ["xiaoyin"] = "硝引",
  [":xiaoyin"] = "准备阶段，你可以亮出牌堆顶X张牌（X为你距离1以内的角色数），获得其中红色牌，将任意张黑色牌作为“硝引”放置在等量名连续其他角色的"..
  "武将牌上。有“硝引”牌的角色受到伤害时：若为火焰伤害，伤害来源可以弃置一张与“硝引”同类别的牌并随机移去一张此类别的“硝引”牌令此伤害+1；"..
  "不为火焰伤害，伤害来源可以获得其一张“硝引”牌并将此伤害改为火焰伤害。",
  ["huahuo"] = "花火",
  [":huahuo"] = "出牌阶段限一次，你可以将一张红色手牌当做不计次数的火【杀】使用。若目标有“硝引”牌，此【杀】可改为指定所有有“硝引”牌的角色为目标。",
  ["xiaoyin_active"] = "硝引",
  ["#xiaoyin_trigger"] = "硝引",
  ["#xiaoyin-give"] = "硝引：将黑色牌作为“硝引”放置在连续的其他角色武将牌上",
  ["#xiaoyin-damage"] = "硝引：你可以弃置一张与 %dest “硝引”同类别的牌，令其受到伤害+1",
  ["#xiaoyin-fire"] = "硝引：你可以获得 %dest 的一张“硝引”，令此伤害改为火焰伤害",
  ["#huahuo"] = "花火：你可以将一张红色手牌当不计次的火【杀】使用，目标可以改为所有有“硝引”的角色",
  ["#huahuo-invoke"] = "花火：是否将目标改为所有有“硝引”的角色？",

  ["$xiaoyin1"] = "鹿栖于野，必能奔光而来。",
  ["$xiaoyin2"] = "磨硝作引，可点心中灵犀。",
  ["$huahuo1"] = "馏石漆取上清，可为胜爆竹之花火。",
  ["$huahuo2"] = "莫道繁花好颜色，此火犹胜二月黄。",
  ["~malingli"] = "花无百日好，人无再少年……",
}

--皇家贵胄：孙皓 士燮 曹髦 刘辩 刘虞 全惠解 丁尚涴 袁姬 谢灵毓 孙瑜 甘夫人糜夫人 曹芳
local ty__sunhao = General(extension, "ty__sunhao", "wu", 5)
local ty__canshi = fk.CreateTriggerSkill{
  name = "ty__canshi",
  anim_type = "drawcard",
  events = {fk.DrawNCards},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and table.find(player.room.alive_players, function (p)
      return p:isWounded() or (player:hasSkill("guiming") and p.kingdom == "wu" and p ~= player)
    end)
  end,
  on_cost = function (self, event, target, player, data)
    local n = 0
    for _, p in ipairs(player.room.alive_players) do
      if p:isWounded() or (player:hasSkill("guiming") and p.kingdom == "wu" and p ~= player) then
        n = n + 1
      end
    end
    if player.room:askForSkillInvoke(player, self.name, nil, "#ty__canshi-invoke:::"..n) then
      self.cost_data = n
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data.n = data.n + self.cost_data
  end,
}
local ty__canshi_delay = fk.CreateTriggerSkill{
  name = "#ty__canshi_delay",
  anim_type = "negative",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      player:usedSkillTimes(ty__canshi.name) > 0 and not player:isNude()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:askForDiscard(player, 1, 1, true, self.name, false)
  end,
}
local ty__chouhai = fk.CreateTriggerSkill{
  name = "ty__chouhai",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events ={fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:isKongcheng() and data.card and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
ty__canshi:addRelatedSkill(ty__canshi_delay)
ty__sunhao:addSkill(ty__canshi)
ty__sunhao:addSkill(ty__chouhai)
ty__sunhao:addSkill("guiming")
Fk:loadTranslationTable{
  ["ty__sunhao"] = "孙皓",
  ["#ty__sunhao"] = "时日曷丧",
  ["designer:ty__sunhao"] = "韩旭",
  ["illustrator:ty__sunhao"] = "君桓文化",--传说皮
  ["ty__canshi"] = "残蚀",
  [":ty__canshi"] = "摸牌阶段，你可以多摸X张牌（X为已受伤的角色数），若如此做，当你于此回合内使用【杀】或普通锦囊牌时，你弃置一张牌。",
  ["#ty__canshi_delay"] = "残蚀",
  ["ty__chouhai"] = "仇海",
  [":ty__chouhai"] = "锁定技，当你受到【杀】造成的伤害时，若你没有手牌，此伤害+1。",
  ["#ty__canshi-invoke"] = "残蚀：你可以多摸 %arg 张牌",

  ["$ty__canshi1"] = "天地不仁，当视苍生为刍狗！",
  ["$ty__canshi2"] = "真龙天子，焉能不择人而噬！",
  ["$ty__chouhai1"] = "大好头颅，谁当斫之？哈哈哈！",
  ["$ty__chouhai2"] = "来来来！且试吾颈硬否！",
  ["$guiming_ty__sunhao1"] = "朕奉天承运，谁敢不从！",
  ["$guiming_ty__sunhao2"] = "朕一日为吴皇，则终生为吴皇！",
  ["~ty__sunhao"] = "八十万人齐卸甲，一片降幡出石头。",
}

local ty__shixie = General(extension, "ty__shixie", "qun", 3)
local ty__biluan = fk.CreateTriggerSkill{
  name = "ty__biluan",
  anim_type = "defensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Finish then
      return table.find(player.room:getOtherPlayers(player), function(p) return p:distanceTo(player) == 1 end)
    end
  end,
  on_cost = function (self, event, target, player, data)
    local x = math.min(4, #player.room.alive_players)
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#ty__biluan-invoke:::"..x, true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    local x = math.min(4, #player.room.alive_players)
    local num = tonumber(player:getMark("@ty__shixie_distance"))+x
    room:setPlayerMark(player,"@ty__shixie_distance",num > 0 and "+"..num or num)
  end,
}
local ty__biluan_distance = fk.CreateDistanceSkill{
  name = "#ty__biluan_distance",
  correct_func = function(self, from, to)
    local num = tonumber(to:getMark("@ty__shixie_distance"))
    if num > 0 then
      return num
    end
  end,
}
ty__biluan:addRelatedSkill(ty__biluan_distance)
ty__shixie:addSkill(ty__biluan)
local ty__lixia = fk.CreateTriggerSkill{
  name = "ty__lixia",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self) and target.phase == Player.Finish and not target:inMyAttackRange(player)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(player, {"draw1", "ty__lixia_draw:"..target.id}, self.name)
    if choice == "draw1" then
      player:drawCards(1, self.name)
    else
      target:drawCards(2, self.name)
    end
    local num = tonumber(player:getMark("@ty__shixie_distance"))-1
    room:setPlayerMark(player,"@ty__shixie_distance",num > 0 and "+"..num or num)
  end,
}
local ty__lixia_distance = fk.CreateDistanceSkill{
  name = "#ty__lixia_distance",
  correct_func = function(self, from, to)
    local num = tonumber(to:getMark("@ty__shixie_distance"))
    if num < 0 then
      return num
    end
  end,
}
ty__lixia:addRelatedSkill(ty__lixia_distance)
ty__shixie:addSkill(ty__lixia)
Fk:loadTranslationTable{
  ["ty__shixie"] = "士燮",
  ["#ty__shixie"] = "雄长百越",
  ["illustrator:ty__shixie"] = "陈龙",--史诗皮
  ["ty__biluan"] = "避乱",
  [":ty__biluan"] = "结束阶段，若有其他角色计算与你的距离为1，你可以弃置一张牌，令其他角色计算与你的距离+X（X为全场角色数且至多为4）。",
  ["ty__lixia"] = "礼下",
  [":ty__lixia"] = "锁定技，其他角色的结束阶段，若你不在其攻击范围内，你选择一项：1.摸一张牌；2.令其摸两张牌。选择完成后，其他角色计算与你的距离-1。",
  ["#ty__biluan-invoke"] = "避乱：你可弃一张牌，令其他角色计算与你距离+%arg",
  ["@ty__shixie_distance"] = "距离",
  ["ty__lixia_draw"] = "令%src摸两张牌",

  ["$ty__biluan1"] = "天下攘攘，难觅避乱之地。",
  ["$ty__biluan2"] = "乱世纷扰，唯避居，方为良策。",
  ["$ty__lixia1"] = "得人才者，得天下。",
  ["$ty__lixia2"] = "礼贤下士，方得民心。",
  ["~ty__shixie"] = "老夫此生，了无遗憾。",
}

local caomao = General(extension, "caomao", "wei", 3, 4)
local qianlong = fk.CreateTriggerSkill{
  name = "qianlong",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and target:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(3)
    room:moveCards({
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
      proposer = player.id,
    })
    local result = U.askForGuanxing(player, cards, {0, 3}, {0, player:getLostHp()}, self.name, nil, true, {"Bottom", "toObtain"})
    if #result.bottom > 0 then
      room:moveCardTo(result.bottom, Player.Hand, player, fk.ReasonJustMove, self.name, "", true, player.id)
    end
    if #result.top > 0 then
      room:moveCards{
        ids = result.top,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
        drawPilePosition = -1,
        moveVisible = true,
      }
    end
  end,
}
local fensi = fk.CreateTriggerSkill{
  name = "fensi",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room:getAlivePlayers(), function(p)
      return p.hp >= player.hp end), Util.IdMapper), 1, 1, "#fensi-choose", self.name, false)
    if #to > 0 then
      to = room:getPlayerById(to[1])
    else
      to = player
    end
    room:damage{
      from = player,
      to = to,
      damage = 1,
      skillName = self.name,
    }
    if not to.dead and to ~= player then
      room:useVirtualCard("slash", nil, to, player, self.name, true)
    end
  end,
}
local juetao = fk.CreateTriggerSkill{
  name = "juetao",
  anim_type = "offensive",
  frequency = Skill.Limited,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
    and player.hp == 1 and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), Util.IdMapper), 1, 1, "#juetao-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    while true do
      if player.dead or to.dead then return end
      local id = room:getNCards(1, "bottom")[1]
      room:moveCards({
        ids = {id},
        toArea = Card.Processing,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
        proposer = player.id,
      })
      local card = Fk:getCardById(id, true)
      room:setPlayerMark(player, MarkEnum.BypassTimesLimit.."-tmp", 1)
      local canUse = player:canUse(card) and not player:prohibitUse(card)
      room:setPlayerMark(player, MarkEnum.BypassTimesLimit.."-tmp", 0)
      local tos
      if canUse then
        local targets = {}
        for _, p in ipairs({player, to}) do
          if not player:isProhibited(p, card) then
            if card.skill:modTargetFilter(p.id, {}, player.id, card, false) then
              table.insert(targets, p.id)
            end
          end
        end
        if #targets > 0 then
          if card.skill:getMinTargetNum() == 0 then
            if not card.multiple_targets then
              if table.contains(targets, player.id) then
                tos = {player.id}
              end
            else
              tos = targets
            end
            if not room:askForSkillInvoke(player, self.name, data, "#juetao-ask:::"..card:toLogString()) then
              tos = nil
            end
          elseif card.skill:getMinTargetNum() == 2 then
            if table.contains(targets, to.id) then
              local seconds = {}
              Self = player -- for targetFilter check
              for _, second in ipairs(room:getOtherPlayers(to)) do
                if card.skill:targetFilter(second.id, {to.id}, {}, card) then
                  table.insert(seconds, second.id)
                end
              end
              if #seconds > 0 then
                local temp = room:askForChoosePlayers(player, seconds, 1, 1, "#juetao-second:::"..card:toLogString(), self.name, true)
                if #temp > 0 then
                  tos = {to.id, temp[1]}
                end
              end
            end
          else
            if #targets == 1 then
              if room:askForSkillInvoke(player, self.name, data, "#juetao-use::"..targets[1]..":"..card:toLogString()) then
                tos = targets
              end
            else
              local temp = room:askForChoosePlayers(player, targets, 1, #targets, "#juetao-target:::"..card:toLogString(), self.name, true)
              if #temp > 0 then
                tos = temp
              end
            end
          end
        end
      end
      if tos then
        room:useCard({
          card = card,
          from = player.id,
          tos = table.map(tos, function(p) return {p} end) ,
          skillName = self.name,
          extraUse = true,
        })
      else
        room:delay(800)
        room:moveCards({
          ids = {id},
          fromArea = Card.Processing,
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonPutIntoDiscardPile,
        })
        return
      end
    end
  end,
}
local zhushi = fk.CreateTriggerSkill{
  name = "zhushi$",
  anim_type = "drawcard",
  events = {fk.HpRecover},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and target.phase ~= Player.NotActive and target.kingdom == "wei" and
      player:usedSkillTimes(self.name) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(target, {"zhushi_draw", "Cancel"}, self.name, "#zhushi-invoke:"..player.id)
    if choice == "zhushi_draw" then
      player:drawCards(1, self.name)
    end
  end,
}
caomao:addSkill(qianlong)
caomao:addSkill(fensi)
caomao:addSkill(juetao)
caomao:addSkill(zhushi)
Fk:loadTranslationTable{
  ["caomao"] = "曹髦",
  ["#caomao"] = "霸业的终耀",
  ["illustrator:caomao"] = "游漫美绘",
  ["qianlong"] = "潜龙",
  [":qianlong"] = "当你受到伤害后，你可以展示牌堆顶的三张牌并获得其中至多X张牌（X为你已损失的体力值），然后将剩余的牌置于牌堆底。",
  ["fensi"] = "忿肆",
  [":fensi"] = "锁定技，准备阶段，你对一名体力值不小于你的角色造成1点伤害；若受伤角色不为你，则其视为对你使用一张【杀】。",
  ["juetao"] = "决讨",
  [":juetao"] = "限定技，出牌阶段开始时，若你的体力值为1，你可以选择一名角色并依次使用牌堆底的牌直到你无法使用，这些牌不能指定除你和该角色以外的角色为目标。",
  ["zhushi"] = "助势",
  [":zhushi"] = "主公技，其他魏势力角色每回合限一次，该角色回复体力时，你可以令其选择是否令你摸一张牌。",
  ["#qianlong-guanxing"] = "潜龙：获得其中至多%arg张牌（获得上方的牌，下方的牌置于牌堆底）",
  ["qianlong_get"] = "获得",
  ["qianlong_bottom"] = "置于牌堆底",
  ["#fensi-choose"] = "忿肆：你须对一名体力值不小于你的角色造成1点伤害，若不为你，视为其对你使用【杀】",
  ["#juetao-choose"] = "决讨：你可以指定一名其他角色，连续对你或其使用牌堆底牌直到不能使用！",
  ["#juetao-use"] = "决讨：是否对 %dest 使用%arg",
  ["#juetao-ask"] = "决讨：是否使用%arg",
  ["#juetao-target"] = "决讨：选择你使用%arg的目标",
  ["#juetao-second"] = "决讨：选择你使用%arg的副目标",
  ["#zhushi-invoke"] = "助势：你可以令 %src 摸一张牌",
  ["zhushi_draw"] = "其摸一张牌",
  
  ["$qianlong1"] = "鸟栖于林，龙潜于渊。",
  ["$qianlong2"] = "游鱼惊钓，潜龙飞天。",
  ["$fensi1"] = "此贼之心，路人皆知！",
  ["$fensi2"] = "孤君烈忿，怒愈秋霜。",
  ["$juetao1"] = "登车拔剑起，奋跃搏乱臣！",
  ["$juetao2"] = "陵云决心意，登辇讨不臣！",
  ["$zhushi1"] = "可有爱卿愿助朕讨贼？",
  ["$zhushi2"] = "泱泱大魏，忠臣俱亡乎？",
  ["~caomao"] = "宁作高贵乡公死，不作汉献帝生……",
}

local liubian = General(extension, "liubian", "qun", 3)
local shiyuan = fk.CreateTriggerSkill{
  name = "shiyuan",
  anim_type = "drawcard",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.from ~= player.id then
      local from = player.room:getPlayerById(data.from)
      local n = 1
      if player:hasSkill("yuwei") and player.room.current.kingdom == "qun" then
        n = 2
      end
      return (from.hp > player.hp and player:getMark("shiyuan1-turn") < n) or
      (from.hp == player.hp and player:getMark("shiyuan2-turn") < n) or
      (from.hp < player.hp and player:getMark("shiyuan3-turn") < n)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = room:getPlayerById(data.from)
    if from.hp > player.hp then
      player:drawCards(3, self.name)
      room:addPlayerMark(player, "shiyuan1-turn", 1)
    elseif from.hp == player.hp then
      player:drawCards(2, self.name)
      room:addPlayerMark(player, "shiyuan2-turn", 1)
    elseif from.hp < player.hp then
      player:drawCards(1, self.name)
      room:addPlayerMark(player, "shiyuan3-turn", 1)
    end
  end,
}
local dushi = fk.CreateTriggerSkill{
  name = "dushi",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self, false, true)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getAlivePlayers(), function(p)
      return not p:hasSkill(self) end), Util.IdMapper)
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#dushi-choose", self.name, false)
    if #to > 0 then
      to = to[1]
    else
      to = table.random(targets)
    end
    room:handleAddLoseSkills(room:getPlayerById(to), self.name, nil, true, false)
  end,

  refresh_events = {fk.EnterDying},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_refresh = function(self, event, target, player, data)
    player:broadcastSkillInvoke(self.name)
    player.room:notifySkillInvoked(player, self.name)
  end,
}
local dushi_prohibit = fk.CreateProhibitSkill{
  name = "#dushi_prohibit",
  prohibit_use = function(self, player, card)
    if card.name == "peach" and not player.dying then
      return table.find(Fk:currentRoom().alive_players, function(p) return p.dying and p:hasSkill("dushi") and p ~= player end)
    end
  end,
}
local yuwei = fk.CreateTriggerSkill{
  name = "yuwei$",
  frequency = Skill.Compulsory,
}
dushi:addRelatedSkill(dushi_prohibit)
liubian:addSkill(shiyuan)
liubian:addSkill(dushi)
liubian:addSkill(yuwei)
Fk:loadTranslationTable{
  ["liubian"] = "刘辩",
  ["#liubian"] = "弘农怀王",
  ["designer:liubian"] = "韩旭",
  ["illustrator:liubian"] = "zoo",
  ["shiyuan"] = "诗怨",
  [":shiyuan"] = "每回合每项限一次，当你成为其他角色使用牌的目标后：1.若其体力值比你多，你摸三张牌；2.若其体力值与你相同，你摸两张牌；"..
  "3.若其体力值比你少，你摸一张牌。",
  ["dushi"] = "毒逝",
  [":dushi"] = "锁定技，你处于濒死状态时，其他角色不能对你使用【桃】。你死亡时，你选择一名其他角色获得〖毒逝〗。",
  ["yuwei"] = "余威",
  [":yuwei"] = "主公技，锁定技，其他群雄角色的回合内，〖诗怨〗改为“每回合每项限两次”。",
  ["#dushi-choose"] = "毒逝：令一名其他角色获得〖毒逝〗",
  
  ["$shiyuan1"] = "感怀诗于前，绝怨赋于后。",
  ["$shiyuan2"] = "汉宫楚歌起，四面无援矣。",
  ["$dushi1"] = "孤无病，此药无需服。",
  ["$dushi2"] = "辟恶之毒，为最毒。",
  ["~liubian"] = "侯非侯，王非王……",
}

local liuyu = General(extension, "ty__liuyu", "qun", 3)
local suifu = fk.CreateTriggerSkill{
  name = "suifu",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and target.phase == Player.Finish and player:getMark("suifu-turn") > 1 and
      not target:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#suifu-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.reverse(target.player_cards[Player.Hand])
    room:moveCards({
      ids = cards,
      from = target.id,
      fromArea = Card.PlayerHand,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    })
    room:useVirtualCard("amazing_grace", nil, player, table.filter(room:getAlivePlayers(), function (p)
      return not player:isProhibited(p, Fk:cloneCard("amazing_grace")) end), self.name, false)
  end,

  refresh_events = {fk.Damaged},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self, true) and (target == player or target.seat == 1)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "suifu-turn", data.damage)
  end,
}
local pijing = fk.CreateTriggerSkill{
  name = "pijing",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local tos = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), Util.IdMapper), 1, 10, "#pijing-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      if p:hasSkill("zimu", true) then
        room:handleAddLoseSkills(p, "-zimu", nil, true, false)
      end
    end
    if not table.contains(self.cost_data, player.id) then
      table.insert(self.cost_data, 1, player.id)
    end
    for _, id in ipairs(self.cost_data) do
      room:handleAddLoseSkills(room:getPlayerById(id), "zimu", nil, true, false)
    end
  end,
}
local zimu = fk.CreateTriggerSkill{
  name = "zimu",
  anim_type = "masochism",
  frequency = Skill.Compulsory,
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      if p:hasSkill("zimu", true) then
        p:drawCards(1, self.name)
      end
    end
    room:handleAddLoseSkills(player, "-zimu", nil, true, false)
  end,
}
liuyu:addSkill(suifu)
liuyu:addSkill(pijing)
liuyu:addRelatedSkill(zimu)
Fk:loadTranslationTable{
  ["ty__liuyu"] = "刘虞",
  ["#ty__liuyu"] = "维城燕北",
  ["designer:ty__liuyu"] = "七哀",
  ["illustrator:ty__liuyu"] = "君桓文化",
  ["suifu"] = "绥抚",
  [":suifu"] = "其他角色的结束阶段，若本回合你和一号位共计至少受到两点伤害，你可将当前回合角色的所有手牌置于牌堆顶，视为使用一张【五谷丰登】。",
  ["pijing"] = "辟境",
  [":pijing"] = "结束阶段，你可选择包含你的任意名角色，这些角色获得〖自牧〗直到下次发动〖辟境〗。",
  ["zimu"] = "自牧",
  [":zimu"] = "锁定技，当你受到伤害后，有〖自牧〗的角色各摸一张牌，然后你失去〖自牧〗。",
  ["#suifu-invoke"] = "绥抚：你可以将 %dest 所有手牌置于牌堆顶，你视为使用【五谷丰登】",
  ["#pijing-choose"] = "辟境：你可以令包括你的任意名角色获得技能〖自牧〗直到下次发动〖辟境〗<br>"..
  "（锁定技，当你受到伤害后，有〖自牧〗的角色各摸一张牌，然后你失去〖自牧〗）",

  ["$suifu1"] = "以柔克刚，方是良策。",
  ["$suifu2"] = "镇抚边疆，为国家计。",
  ["$pijing1"] = "群寇来袭，愿和将军同御外侮。",
  ["$pijing2"] = "天下不宁，愿与阁下共守此州。",
  ["$zimu"] = "既为汉吏，当遵汉律。",
  ["~ty__liuyu"] = "公孙瓒谋逆，人人可诛！",
}

local quanhuijie = General(extension, "quanhuijie", "wu", 3, 3, General.Female)
local huishu = fk.CreateTriggerSkill{
  name = "huishu",
  anim_type = "drawcard",
  events = {fk.EventPhaseEnd, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.EventPhaseEnd then
      return target == player and player.phase == Player.Draw
    elseif player:usedSkillTimes(self.name) > 0 and player:getMark("_huishu-turn") == 0 then
      local room = player.room
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
              if turn_event == nil then return false end
              local end_id = turn_event.id
              local x = 0
              U.getEventsByRule(room, GameEvent.MoveCards, 1, function (e)
                for _, move2 in ipairs(e.data) do
                  if move2.from == player.id and move2.moveReason == fk.ReasonDiscard then
                    for _, info2 in ipairs(move2.moveInfo) do
                      if info2.fromArea == Card.PlayerHand or info2.fromArea == Card.PlayerEquip then
                        x = x + 1
                      end
                    end
                  end
                end
                return false
              end, end_id)
              return x > player:getMark("huishu3") + 2 and table.find(room.discard_pile, function (id)
                return Fk:getCardById(id) ~= Card.TypeBasic
              end)
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseEnd then
      return player.room:askForSkillInvoke(player, self.name)
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.EventPhaseEnd then
      player:drawCards(player:getMark("huishu1") + 3, self.name)
      if player.dead then return false end
      local x = player:getMark("huishu2") + 1
      player.room:askForDiscard(player, x, x, false, self.name, false)
    else
      local room = player.room
      local cards = room:getCardsFromPileByRule(".|.|.|.|.|^basic", player:getMark("huishu3") + 2, "discardPile")
      if #cards > 0 then
        room:setPlayerMark(player, "_huishu-turn", 1)
        room:obtainCard(player, cards, false, fk.ReasonJustMove, player.id, self.name)
      end
    end
  end,

  refresh_events = {fk.EventLoseSkill, fk.EventAcquireSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "huishu1", 0)
    room:setPlayerMark(player, "huishu2", 0)
    room:setPlayerMark(player, "huishu3", 0)
    if event == fk.EventAcquireSkill then
      room:setPlayerMark(player, "@" .. self.name, {3, 1, 2})
    else
      room:setPlayerMark(player, "@" .. self.name, 0)
    end
  end,
}
local yishu = fk.CreateTriggerSkill{
  name = "yishu",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:hasSkill(huishu, true) and player.phase ~= Player.Play and
      not huishu:triggerable(event, target, player, data) then
      for _, move in ipairs(data) do
        if move.from == player.id then
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
    local yishu_nums = {
      player:getMark("huishu1") + 3,
      player:getMark("huishu2") + 1,
      player:getMark("huishu3") + 2
    }

    local max_c = math.max(yishu_nums[1], yishu_nums[2], yishu_nums[3])
    local min_c = math.min(yishu_nums[1], yishu_nums[2], yishu_nums[3])

    local to_change = {}
    for i = 1, 3, 1 do
      if yishu_nums[i] == max_c then
        table.insert(to_change, "huishu" .. tostring(i))
      end
    end

    local choice = room:askForChoice(player, to_change, self.name, "#yishu-lose")
    local index = tonumber(string.sub(choice, 7))
    yishu_nums[index] = yishu_nums[index] - 1

    room:setPlayerMark(player, "@huishu", yishu_nums)

    to_change = {}
    for i = 1, 3, 1 do
      if yishu_nums[i] == min_c and i ~= index then
        table.insert(to_change, "huishu" .. tostring(i))
      end
    end

    choice = room:askForChoice(player, to_change, self.name, "#yishu-add")
    index = tonumber(string.sub(choice, 7))
    yishu_nums[index] = yishu_nums[index] + 2

    room:setPlayerMark(player, "@huishu", yishu_nums)

    room:setPlayerMark(player, "huishu1", yishu_nums[1] - 3)
    room:setPlayerMark(player, "huishu2", yishu_nums[2] - 1)
    room:setPlayerMark(player, "huishu3", yishu_nums[3] - 2)
  end,
}
local ligong = fk.CreateTriggerSkill{
  name = "ligong",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:hasSkill(huishu, true) and
    (player:getMark("huishu1") > 1 or player:getMark("huishu2") > 3 or player:getMark("huishu3") > 2)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    room:recover({
      who = player,
      num = 1,
      recoverBy = player,
      skillName = self.name
    })
    room:handleAddLoseSkills(player, "-yishu", nil)

    local generals, same_g = {}, {}
    for _, general_name in ipairs(room.general_pile) do
      same_g = Fk:getSameGenerals(general_name)
      table.insert(same_g, general_name)
      same_g = table.filter(same_g, function (g_name)
        local general = Fk.generals[g_name]
        return (general.kingdom == "wu" or general.subkingdom == "wu") and general.gender == General.Female
      end)
      if #same_g > 0 then
        table.insert(generals, table.random(same_g))
      end
    end
    if #generals == 0 then return false end
    generals = table.random(generals, 4)

    local skills = {}
    for _, general_name in ipairs(generals) do
      local general = Fk.generals[general_name]
      local g_skills = {}
      for _, skill in ipairs(general.skills) do
        if not (table.contains({Skill.Limited, Skill.Wake, Skill.Quest}, skill.frequency) or skill.lordSkill) and
        (#skill.attachedKingdom == 0 or (table.contains(skill.attachedKingdom, "wu") and player.kingdom == "wu")) then
          table.insertIfNeed(g_skills, skill.name)
        end
      end
      for _, s_name in ipairs(general.other_skills) do
        local skill = Fk.skills[s_name]
        if not (table.contains({Skill.Limited, Skill.Wake, Skill.Quest}, skill.frequency) or skill.lordSkill) and
        (#skill.attachedKingdom == 0 or (table.contains(skill.attachedKingdom, "wu") and player.kingdom == "wu")) then
          table.insertIfNeed(g_skills, skill.name)
        end
      end
      table.insertIfNeed(skills, g_skills)
    end
    local result = player.room:askForCustomDialog(player, self.name,
    "packages/tenyear/qml/ChooseGeneralSkillsBox.qml", {
      generals, skills, 1, 2, "#ligong-choice", true
    })
    local choices = {}
    if result ~= "" then
      choices = json.decode(result)
    end
    if #choices == 0 then
      player:drawCards(3, self.name)
    else
      room:handleAddLoseSkills(player, "-huishu|"..table.concat(choices, "|"), nil)
    end
  end,
}
quanhuijie:addSkill(huishu)
quanhuijie:addSkill(yishu)
quanhuijie:addSkill(ligong)
Fk:loadTranslationTable{
  ["quanhuijie"] = "全惠解",
  ["#quanhuijie"] = "春宫早深",
  ["illustrator:quanhuijie"] = "游漫美绘",
  ["huishu"] = "慧淑",
  [":huishu"] = "摸牌阶段结束时，你可以摸3张牌然后弃置1张手牌。"..
  "若如此做，你本回合弃置超过2张牌时，从弃牌堆中随机获得等量的非基本牌。",
  ["yishu"] = "易数",
  [":yishu"] = "锁定技，当你于出牌阶段外失去牌后，〖慧淑〗中最小的一个数字+2且最大的一个数字-1。",
  ["ligong"] = "离宫",
  [":ligong"] = "觉醒技，准备阶段，若〖慧淑〗有数字达到5，你加1点体力上限并回复1点体力，失去〖易数〗，"..
  "然后从随机四个吴国女性武将中选择至多两个技能获得并失去〖慧淑〗（如果不获得技能则改为摸三张牌）。",
  ["@huishu"] = "慧淑",
  ["huishu1"] = "摸牌数",
  ["huishu2"] = "摸牌后弃牌数",
  ["huishu3"] = "获得锦囊所需弃牌数",
  ["#yishu-add"] = "易数：请选择增加的一项",
  ["#yishu-lose"] = "易数：请选择减少的一项",
  ["#ligong-choice"] = "离宫：选择至多2个武将技能",

  ["$huishu1"] = "心有慧镜，善解百般人意。",
  ["$huishu2"] = "袖着静淑，可揾夜阑之泪。",
  ["$yishu1"] = "此命由我，如织之数可易。",
  ["$yishu2"] = "易天定之数，结人定之缘。",
  ["$ligong1"] = "伴君离高墙，日暮江湖远。",
  ["$ligong2"] = "巍巍宫门开，自此不复来。",
  ["~quanhuijie"] = "妾有愧于陛下。",
}

local dingfuren = General(extension, "dingfuren", "wei", 3, 3, General.Female)
local fengyan = fk.CreateActiveSkill{
  name = "fengyan",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  interaction = function(self)
    local choices = {}
    if Self:getMark("fengyan1-phase") == 0 then
      table.insert(choices, "fengyan1-phase")
    end
    if Self:getMark("fengyan2-phase") == 0 then
      table.insert(choices, "fengyan2-phase")
    end
    return UI.ComboBox { choices = choices }
  end,
  can_use = function(self, player)
    return player:getMark("fengyan1-phase") == 0 or player:getMark("fengyan2-phase") == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected == 0 and to_select ~= Self.id then
      local target = Fk:currentRoom():getPlayerById(to_select)
      if self.interaction.data == "fengyan1-phase" then
        return target.hp <= Self.hp and not target:isKongcheng()
      elseif self.interaction.data == "fengyan2-phase" then
        return target:getHandcardNum() <= Self:getHandcardNum() and not Self:isProhibited(target, Fk:cloneCard("slash"))
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(player, self.interaction.data, 1)
    if self.interaction.data == "fengyan1-phase" then
      local card = room:askForCard(target, 1, 1, false, self.name, false, ".|.|.|hand", "#fengyan-give:"..player.id)
      room:obtainCard(player.id, card[1], false, fk.ReasonGive, target.id)
    elseif self.interaction.data == "fengyan2-phase" then
      room:useVirtualCard("slash", nil, player, target, self.name, true)
    end
  end,
}
local fudao = fk.CreateTriggerSkill{
  name = "fudao",
  anim_type = "support",
  mute = true,
  events = {fk.GameStart, fk.TargetSpecified, fk.Death, fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    if event == fk.Death then
      if player:hasSkill(self, false, (player == target)) then
        local to = player.room:getPlayerById(player:getMark(self.name))
        return to ~= nil and ((player == target and not to.dead) or to == target) and data.damage and data.damage.from and
          not data.damage.from.dead and data.damage.from ~= player and data.damage.from ~= to
      end
      return false
    end
    if player:hasSkill(self) then
      if event == fk.GameStart then
        return true
      elseif event == fk.TargetSpecified then
        local to = player.room:getPlayerById(data.to)
        return ((player == target and player:getMark(self.name) == to.id) or (player == to and player:getMark(self.name) == target.id)) and
          player:getMark("fudao_specified-turn") == 0
      elseif event == fk.TargetConfirmed then
        return target == player and data.from ~= player.id and player.room:getPlayerById(data.from):getMark("@@juelie") > 0 and
          data.card.color == Card.Black
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      room:notifySkillInvoked(player, self.name)
      local targets = table.map(room:getOtherPlayers(player), Util.IdMapper)
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#fudao-choose", self.name, false, true)
      if #tos > 0 then
        room:setPlayerMark(player, self.name, tos[1])
        room:setPlayerMark(player, "@@fudao", 1)
        room:setPlayerMark(room:getPlayerById(tos[1]), "@@fudao", 1)
      end
    elseif event == fk.TargetSpecified then
      room:notifySkillInvoked(player, self.name)
      room:addPlayerMark(player, "fudao_specified-turn")
      local targets = {player.id, player:getMark(self.name)}
      room:sortPlayersByAction(targets)
      room:doIndicate(player.id, targets)
      for _, pid in ipairs(targets) do
        local p = room:getPlayerById(pid)
        if p and not p.dead then
          room:drawCards(p, 2, self.name)
        end
      end
    elseif event == fk.Death then
      room:notifySkillInvoked(player, self.name, "offensive")
      player:broadcastSkillInvoke(self.name)
      room:setPlayerMark(data.damage.from, "@@juelie", 1)
    elseif event == fk.TargetConfirmed then
      room:notifySkillInvoked(player, self.name, "control")
      player:broadcastSkillInvoke(self.name)
      room:setPlayerMark(room:getPlayerById(data.from), "@@fudao-turn", 1)
    end
  end,
}
local fudao_delay = fk.CreateTriggerSkill{
  name = "#fudao_delay",
  mute = true,
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return player == target and player:getMark("@@fudao") > 0 and data.to:getMark("@@juelie") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, fudao.name, "offensive")
    if player:hasSkill(fudao.name, true) then
      player:broadcastSkillInvoke(fudao.name)
    end
    data.damage = data.damage + 1
  end,
}
local fudao_prohibit = fk.CreateProhibitSkill{
  name = "#fudao_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("@@fudao-turn") > 0
  end,
}
fudao:addRelatedSkill(fudao_delay)
fudao:addRelatedSkill(fudao_prohibit)
dingfuren:addSkill(fengyan)
dingfuren:addSkill(fudao)
Fk:loadTranslationTable{
  ["dingfuren"] = "丁尚涴",
  ["#dingfuren"] = "与君不载",
  ["illustrator:dingfuren"] = "匠人绘",
  ["fengyan"] = "讽言",
  [":fengyan"] = "出牌阶段每项限一次，你可以选择一名其他角色，若其体力值小于等于你，你令其交给你一张手牌；"..
  "若其手牌数小于等于你，你视为对其使用【杀】（无距离限制）。",
  ["fudao"] = "抚悼",
  ["#fudao_delay"] = "抚悼",
  [":fudao"] = "游戏开始时，你选择一名其他角色，你与其每回合首次使用牌指定对方为目标后，各摸两张牌。杀死你或该角色的其他角色获得“决裂”标记，"..
  "你或该角色对有“决裂”的角色造成的伤害+1；“决裂”角色使用黑色牌指定你为目标后，其本回合不能再使用牌。",
  ["fengyan1-phase"] = "令一名体力值不大于你的角色交给你一张手牌",
  ["fengyan2-phase"] = "视为对一名手牌数不大于你的角色使用【杀】",
  ["#fengyan-give"] = "讽言：你须交给 %src 一张手牌",
  ["@@fudao"] = "抚悼",
  ["#fudao-choose"] = "抚悼：请选择要“抚悼”的角色",
  ["@@juelie"] = "决裂",
  ["@@fudao-turn"] = "抚悼 不能出牌",

  ["$fengyan1"] = "既将我儿杀之，何复念之！",
  ["$fengyan2"] = "乞问曹公，吾儿何时归还？",
  ["$fudao1"] = "弑子之仇，不共戴天！",
  ["$fudao2"] = "眼中泪绝，尽付仇怆。",
  ["~dingfuren"] = "吾儿既丧，天地无光……",
}

local yuanji = General(extension, "yuanji", "wu", 3, 3, General.Female)
local fangdu = fk.CreateTriggerSkill{
  name = "fangdu",
  anim_type = "masochism",
  events = {fk.Damaged},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player ~= target or not player:hasSkill(self) or player.phase ~= Player.NotActive then return false end
    local room = player.room
    local damage_event = room.logic:getCurrentEvent()
    if not damage_event then return false end
    local mark_name = "fangdu1_record-turn"
    if data.damageType == fk.NormalDamage then
      if not player:isWounded() then return false end
    else
      if data.from == nil or data.from == player or data.from:isKongcheng() then return false end
      mark_name = "fangdu2_record-turn"
    end
    local x = player:getMark(mark_name)
    if x == 0 then
      room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
        local reason = e.data[3]
        if e.data[1] == player and reason == "damage" then
          local first_damage_event = e:findParent(GameEvent.Damage)
          if first_damage_event then
            local damage = first_damage_event.data[1]
            if damage.damageType == data.damageType then
              x = first_damage_event.id
              room:setPlayerMark(player, mark_name, x)
              return true
            end
          end
        end
      end, Player.HistoryTurn)
    end
    return damage_event.id == x
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.damageType == fk.NormalDamage then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      }
    else
      local id = table.random(data.from.player_cards[Player.Hand])
      room:obtainCard(player.id, id, false, fk.ReasonPrey)
    end
  end
}
local jiexing = fk.CreateTriggerSkill{
  name = "jiexing",
  anim_type = "drawcard",
  events = {fk.HpChanged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name, nil, "@@jiexing-inhand-turn")
  end,
}
local jiexing_maxcards = fk.CreateMaxCardsSkill{
  name = "#jiexing_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@jiexing-inhand-turn") > 0
  end,
}
jiexing:addRelatedSkill(jiexing_maxcards)
yuanji:addSkill(fangdu)
yuanji:addSkill(jiexing)
Fk:loadTranslationTable{
  ["yuanji"] = "袁姬",
  ["#yuanji"] = "袁门贵女",
  ["designer:yuanji"] = "韩旭",
  ["illustrator:yuanji"] = "匠人绘",
  ["fangdu"] = "芳妒",
  [":fangdu"] = "锁定技，你的回合外，你每回合第一次受到普通伤害后回复1点体力，你每回合第一次受到属性伤害后随机获得伤害来源一张手牌。",
  ["jiexing"] = "节行",
  [":jiexing"] = "当你的体力值变化后，你可以摸一张牌，此牌于本回合内不计入手牌上限。",

  ["#jiexing-invoke"] = "节行：你可以摸一张牌，此牌本回合不计入手牌上限",
  ["@@jiexing-inhand-turn"] = "节行",

  ["$fangdu1"] = "浮萍却红尘，何意染是非？",
  ["$fangdu2"] = "我本无意争春，奈何群芳相妒。",
  ["$jiexing1"] = "女子有节，安能贰其行？",
  ["$jiexing2"] = "坐受雨露，皆为君恩。",
  ["~yuanji"] = "妾本蒲柳，幸荣君恩……",
}

local xielingyu = General(extension, "xielingyu", "wu", 3, 3, General.Female)
local yuandi = fk.CreateTriggerSkill{
  name = "yuandi",
  anim_type = "control",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target ~= player and target.phase == Player.Play and target:getMark("yuandi-phase") == 0 then
      player.room:addPlayerMark(target, "yuandi-phase", 1)
      if data.tos then
        for _, id in ipairs(TargetGroup:getRealTargets(data.tos)) do
          if id ~= target.id then
            return
          end
        end
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#yuandi-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"yuandi_draw"}
    if not target:isKongcheng() then
      table.insert(choices, 1, "yuandi_discard")
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "yuandi_discard" then
      local id = room:askForCardChosen(player, target, "h", self.name)
      room:throwCard({id}, self.name, target, player)
    else
      player:drawCards(1, self.name)
      target:drawCards(1, self.name)
    end
  end,
}
local xinyou = fk.CreateActiveSkill{
  name = "xinyou",
  anim_type = "drawcard",
  can_use = function(self, player)
    return (player:isWounded() or player:getHandcardNum() < player.maxHp) and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if player:isWounded() then
      room:recover({
        who = player,
        num = player:getLostHp(),
        recoverBy = player,
        skillName = self.name
      })
      room:addPlayerMark(player, "xinyou_recover-turn", 1)
    end
    local n = player.maxHp - player:getHandcardNum()
    if n > 0 then
      player:drawCards(n, self.name)
      if n > 2 then
        room:addPlayerMark(player, "xinyou_draw-turn", 1)
      end
    end
  end
}
local xinyou_record = fk.CreateTriggerSkill{
  name = "#xinyou_record",
  anim_type = "negative",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and
      ((player:getMark("xinyou_recover-turn") > 0 and not player:isNude()) or player:getMark("xinyou_draw-turn") > 0)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("xinyou_recover-turn") > 0 then
      room:askForDiscard(player, 1, 1, true, "xinyou", false)
    end
    if player:getMark("xinyou_draw-turn") > 0 then
      room:loseHp(player, 1, "xinyou")
    end
  end,
}
xinyou:addRelatedSkill(xinyou_record)
xielingyu:addSkill(yuandi)
xielingyu:addSkill(xinyou)
Fk:loadTranslationTable{
  ["xielingyu"] = "谢灵毓",
  ["#xielingyu"] = "淑静才媛",
  ["designer:xielingyu"] = "韩旭",
  ["illustrator:xielingyu"] = "游漫美绘",
  ["yuandi"] = "元嫡",
  [":yuandi"] = "其他角色于其出牌阶段使用第一张牌时，若此牌没有指定除其以外的角色为目标，你可以选择一项：1.弃置其一张手牌；2.你与其各摸一张牌。",
  ["xinyou"] = "心幽",
  [":xinyou"] = "出牌阶段限一次，你可以回复体力至体力上限并将手牌摸至体力上限。若你因此摸超过两张牌，结束阶段你失去1点体力；"..
  "若你因此回复体力，结束阶段你弃置一张牌。",
  ["#yuandi-invoke"] = "元嫡：你可以弃置 %dest 的一张手牌或与其各摸一张牌",
  ["yuandi_discard"] = "弃置其一张手牌",
  ["yuandi_draw"] = "你与其各摸一张牌",
  ["#xinyou_record"] = "心幽",

  ["$yuandi1"] = "此生与君为好，共结连理。",
  ["$yuandi2"] = "结发元嫡，其情唯衷孙郎。",
  ["$xinyou1"] = "我有幽月一斛，可醉十里春风。",
  ["$xinyou2"] = "心在方外，故而不闻市井之声。",
  ["~xielingyu"] = "翠瓦红墙处，最折意中人。",
}

local sunyu = General(extension, "sunyu", "wu", 3)
local quanshou = fk.CreateTriggerSkill{
  name = "quanshou",
  anim_type = "support",
  events = {fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target:getHandcardNum() <= target.maxHp
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askForSkillInvoke(player, self.name, nil, "#quanshou-invoke::"..target.id) then
      room:doIndicate(player.id, {target.id})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(target, {"quanshou1", "quanshou2:"..player.id}, self.name, "#quanshou-choice:"..player.id)
    if choice == "quanshou1" then
      room:setPlayerMark(target, "quanshou1-turn", 1)
      local n = math.min(target.maxHp, 5) - target:getHandcardNum()
      if n > 0 then
        target:drawCards(n, self.name)
      end
    else
      room:setPlayerMark(player, "quanshou2-turn", target.id)
    end
  end,
}
local quanshou_trigger = fk.CreateTriggerSkill{
  name = "#quanshou_trigger",
  mute = true,
  events = {fk.CardEffectCancelledOut},
  can_trigger = function(self, event, target, player, data)
    return player:getMark("quanshou2-turn") ~= 0 and data.from and data.from == player:getMark("quanshou2-turn")
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, "quanshou")
  end,
}
local quanshou_targetmod = fk.CreateTargetModSkill{
  name = "#quanshou_targetmod",
  residue_func = function(self, player, skill, scope, card)
    if card and card.trueName == "slash" and player:getMark("quanshou1-turn") > 0 and scope == Player.HistoryPhase then
      return -1
    end
  end,
}
local shexue = fk.CreateTriggerSkill{
  name = "shexue",
  anim_type = "special",
  events = {fk.EventPhaseStart, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target.phase == Player.Play and player:hasSkill(self) then
      if event == fk.EventPhaseStart then
        if target:isNude() then return false end
        local room = player.room
        if player == target then
          local all_names = player:getMark("shexue_last-turn")
          if type(all_names) ~= "table" then
            all_names = {}
            local logic = room.logic
            local turn_event = logic:getCurrentEvent():findParent(GameEvent.Turn)
            if turn_event == nil then return false end
            local all_turn_events = logic.event_recorder[GameEvent.Turn]
            if type(all_turn_events) == "table" then
              local index = #all_turn_events
              if index > 1 then
                turn_event = all_turn_events[index - 1]
                local last_player = turn_event.data[1]
                local all_phase_events = logic.event_recorder[GameEvent.Phase]
                if type(all_phase_events) == "table" then
                  local play_ids = {}
                  for i = #all_phase_events, 1, -1 do
                    local e = all_phase_events[i]
                    if e.id < turn_event.id then
                      break
                    end
                    if e.id < turn_event.end_id and e.data[2] == Player.Play then
                      table.insert(play_ids, {e.id, e.end_id})
                    end
                  end
                  if #play_ids > 0 then
                    U.getEventsByRule(room, GameEvent.UseCard, 1, function (e)
                      local in_play = false
                      for _, ids in ipairs(play_ids) do
                        if #ids == 2 and e.id > ids[1] and e.id < ids[2] then
                          in_play = true
                          break
                        end
                      end
                      if in_play then
                        local use = e.data[1]
                        if use.from == last_player.id and (use.card.type == Card.TypeBasic or use.card:isCommonTrick()) then
                          table.insertIfNeed(all_names, use.card.name)
                        end
                      end
                    end, turn_event.id)
                  end
                end
              end
            end
            room:setPlayerMark(player, "shexue_last-turn", all_names)
          end
          local extra_data = {bypass_times = true, bypass_distances = true}
          local names = table.filter(all_names, function (n)
            local card = Fk:cloneCard(n)
            card.skillName = "shexue"
            return card.skill:canUse(player, card, extra_data) and not player:prohibitUse(card)
            and table.find(room.alive_players, function (p)
              return not player:isProhibited(p, card) and card.skill:modTargetFilter(p.id, {}, player.id, card, false)
            end)
          end)
          if #names > 0 then
            extra_data.virtualuse_allnames = all_names
            extra_data.virtualuse_names = names
            self.cost_data = extra_data
            return true
          end
        elseif not target.dead then
          local all_names = U.getMark(player, "shexue_invoking-turn")
          if #all_names == 0 then return false end
          local extra_data = {bypass_times = true, bypass_distances = true}
          local names = table.filter(all_names, function (n)
            local card = Fk:cloneCard(n)
            card.skillName = "shexue"
            return card.skill:canUse(target, card, extra_data) and not target:prohibitUse(card)
            and table.find(room.alive_players, function (p)
              return not target:isProhibited(p, card) and card.skill:modTargetFilter(p.id, {}, target.id, card, not bypass_distances)
            end)
          end)
          if #names > 0 then
            extra_data.virtualuse_allnames = all_names
            extra_data.virtualuse_names = names
            self.cost_data = extra_data
            return true
          end
        end
      elseif event == fk.EventPhaseEnd and player == target then
        local room = player.room
        local names = {}
        room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
          local use = e.data[1]
          if use.from == player.id and (use.card.type == Card.TypeBasic or use.card:isCommonTrick()) then
            table.insertIfNeed(names, use.card.name)
          end
        end, Player.HistoryPhase)
        if #names > 0 then
          self.cost_data = names
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      if player == target then
        local success, dat = room:askForUseActiveSkill(player, "shexue_viewas", "#shexue-use", true, self.cost_data)
        if success then
          self.cost_data = dat
          return true
        end
      else
        room:doIndicate(player.id, {target.id})
        return true
      end
    else
      return room:askForSkillInvoke(player, self.name, nil, "#shexue-invoke")
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local dat = table.simpleClone(self.cost_data)
      if player == target then
        local card = Fk:cloneCard(dat.interaction)
        card:addSubcards(dat.cards)
        card.skillName = "shexue"
        room:useCard{
          from = player.id,
          tos = table.map(dat.targets, function(id) return {id} end),
          card = card,
          extraUse = true,
        }
        if player.dead or player ~= target then return false end
        local all_names = U.getMark(player, "shexue_invoking-turn")
        if #all_names == 0 then return false end
        local extra_data = {bypass_times = true, bypass_distances = true}
        local names = table.filter(all_names, function (n)
          local card = Fk:cloneCard(n)
          card.skillName = "shexue"
          return card.skill:canUse(player, card, extra_data) and not player:prohibitUse(card)
          and table.find(room.alive_players, function (p)
            return not player:isProhibited(p, card) and card.skill:modTargetFilter(p.id, {}, player.id, card, not bypass_distances)
          end)
        end)
        if #names == 0 then return false end
        extra_data.virtualuse_allnames = all_names
        extra_data.virtualuse_names = names
        dat = extra_data
      end
      local success, dat2 = room:askForUseActiveSkill(target, "shexue_viewas", "#shexue-use", true, dat)
      if success and dat2 then
        local card = Fk:cloneCard(dat2.interaction)
        card:addSubcards(dat2.cards)
        card.skillName = "shexue"
        room:useCard{
          from = target.id,
          tos = table.map(dat2.targets, function(id) return {id} end),
          card = card,
          extraUse = true,
        }
      end
    else
      room:setPlayerMark(player, "shexue_invoking", table.simpleClone(self.cost_data))
    end
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return player:getMark("shexue_invoking") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "shexue_invoking-turn", player:getMark("shexue_invoking"))
    room:setPlayerMark(player, "shexue_invoking", 0)
  end,
}

local shexue_viewas = fk.CreateViewAsSkill{
  name = "shexue_viewas",
  interaction = function(self)
    return UI.ComboBox {choices = self.virtualuse_names, all_choices = self.virtualuse_allnames }
  end,
  card_filter = function (self, to_select, selected)
    return #selected == 0
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(cards)
    card.skillName = "shexue"
    return card
  end,
}

quanshou:addRelatedSkill(quanshou_trigger)
quanshou:addRelatedSkill(quanshou_targetmod)
Fk:addSkill(shexue_viewas)
sunyu:addSkill(quanshou)
sunyu:addSkill(shexue)
Fk:loadTranslationTable{
  ["sunyu"] = "孙瑜",
  ["#sunyu"] = "镇据边陲",
  ["designer:sunyu"] = "胜天半子ying",
  ["illustrator:sunyu"] = "CatJade玉猫",
  ["quanshou"] = "劝守",
  [":quanshou"] = "一名角色回合开始时，若其手牌数不大于体力上限，你可以令其选择："..
  "1.将手牌摸至体力上限（至多摸五张），其于此回合的出牌阶段内使用【杀】的次数上限-1；"..
  "2.其于此回合内使用牌被抵消后，你摸一张牌。",
  ["shexue"] = "设学",
  [":shexue"] = "出牌阶段开始时，你可以将一张牌当上个回合角色出牌阶段内使用过的一张基本牌或普通锦囊牌使用（无距离限制）；"..
  "出牌阶段结束时，你可以令下个回合角色于其出牌阶段开始时可以将一张牌当你本阶段使用过的一张基本牌或普通锦囊牌使用（无距离限制）。",
  ["#quanshou-invoke"] = "劝守：是否对 %dest 发动“劝守”？",
  ["#quanshou-choice"] = "劝守：选择 %src 令你执行的一项",
  ["quanshou1"] = "摸牌至体力上限，本回合使用【杀】次数-1",
  ["quanshou2"] = "你本回合使用牌被抵消后，%src摸一张牌",
  ["#shexue-invoke"] = "是否使用 设学，令下回合角色出牌阶段开始时可以将一张牌当你本阶段使用过的牌使用",
  ["shexue_viewas"] = "设学",
  ["#shexue-use"] = "是否使用 设学，将一张牌当上个回合角色出牌阶段内使用过的牌使用",

  ["$quanshou1"] = "曹军势大，不可刚其锋。",
  ["$quanshou2"] = "持重待守，不战而胜十万雄兵。",
  ["$shexue1"] = "虽为武夫，亦需极目汗青。",
  ["$shexue2"] = "武可靖天下，然不能定天下。",
  ["~sunyu"] = "孙氏始得江东，奈何魂归黄泉……",
}

local ganfurenmifuren = General(extension, "ganfurenmifuren", "shu", 3, 3, General.Female)
local chanjuan = fk.CreateTriggerSkill{
  name = "chanjuan",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (data.card:isCommonTrick() or data.card.type == Card.TypeBasic) and
      data.tos and #TargetGroup:getRealTargets(data.tos) == 1 and U.IsUsingHandcard(player, data) and 
      #table.filter(U.getMark(player, "@$chanjuan"), function(s) return s == data.card.trueName end) < 2
  end,
  on_cost = function(self, event, target, player, data)
    local use = U.askForUseVirtualCard(player.room, player, data.card.trueName, nil, self.name, "#chanjuan-use::"..TargetGroup:getRealTargets(data.tos)[1]..":"..data.card.trueName, true, true, false, true, {}, true)
    if use then
      self.cost_data = use
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local use = self.cost_data
    local mark = U.getMark(player, "@$chanjuan")
    table.insert(mark, data.card.trueName)
    room:setPlayerMark(player, "@$chanjuan", mark)
    room:useCard(use)
    if not player.dead and #TargetGroup:getRealTargets(use.tos) == 1 and TargetGroup:getRealTargets(data.tos)[1] == TargetGroup:getRealTargets(use.tos)[1] then
      player:drawCards(1, self.name)
    end
  end,
  
  refresh_events = {fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self and player:getMark("@$chanjuan") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@$chanjuan", 0)
  end,
}
local xunbie = fk.CreateTriggerSkill{
  name = "xunbie",
  anim_type = "defensive",
  frequency = Skill.Limited,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.dying and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local generals = {}
    if not table.find(room.alive_players, function(p) return p.general == "ty__ganfuren" or p.deputyGeneral == "ty__ganfuren" end) then
      table.insert(generals, "ty__ganfuren")
    end
    if not table.find(room.alive_players, function(p) return p.general == "ty__mifuren" or p.deputyGeneral == "ty__mifuren" end) then
      table.insert(generals, "ty__mifuren")
    end
    if #generals > 0 then
      local general = room:askForGeneral(player, generals, 1, true)
      U.changeHero(player, general, false)
      if player.dead then return end
    end
    room:setPlayerMark(player, "@@xunbie-turn", 1)
    if player:isWounded() then
      room:recover({
        who = player,
        num = 1 - player.hp,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
local xunbie_trigger = fk.CreateTriggerSkill{
  name = "#xunbie_trigger",
  events = {fk.DamageInflicted},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@xunbie-turn") > 0
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke("xunbie")
    return true
  end,
}
xunbie:addRelatedSkill(xunbie_trigger)
ganfurenmifuren:addSkill(chanjuan)
ganfurenmifuren:addSkill(xunbie)
Fk:loadTranslationTable{
  ["ganfurenmifuren"] = "甘夫人糜夫人",
  ["#ganfurenmifuren"] = "千里婵娟",
  ["designer:ganfurenmifuren"] = "星移",
  ["illustrator:ganfurenmifuren"] = "七兜豆",

  ["chanjuan"] = "婵娟",
  [":chanjuan"] = "每种牌名限两次，你使用指定唯一目标的基本牌或普通锦囊牌结算完毕后，你可以视为使用一张同名牌，若目标完全相同，你摸一张牌。",
  ["xunbie"] = "殉别",
  [":xunbie"] = "限定技，当你进入濒死状态时，你可以将武将牌改为甘夫人或糜夫人，然后回复体力至1并防止你受到的伤害直到回合结束。",
  ["@$chanjuan"] = "婵娟",
  ["#chanjuan-use"] = "婵娟：你可以视为使用【%arg】，若目标为 %dest ，你摸一张牌",
  ["chanjuan_viewas"] = "婵娟",
  ["#xunbie_trigger"] = "殉别",
  ["@@xunbie-turn"] = "殉别",

  ["$chanjuan1"] = "姐妹一心，共侍玄德无忧。",
  ["$chanjuan2"] = "双姝从龙，姊妹宠荣与共。",
  ["$xunbie1"] = "既为君之妇，何惧为君之鬼。",
  ["$xunbie2"] = "今临难将罹，唯求不负皇叔。",
  ["~ganfurenmifuren"] = "人生百年，奈何于我十不存一……",
}

local ganfuren = General(extension, "ty__ganfuren", "shu", 3, 3, General.Female)
local ty__shushen = fk.CreateTriggerSkill{
  name = "ty__shushen",
  anim_type = "support",
  events = {fk.HpRecover},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_trigger = function(self, event, target, player, data)
    self.cancel_cost = false
    for i = 1, data.num do
      if self.cancel_cost then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#ty__shushen-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local choices = {"ty__shushen_draw"}
    if to:isWounded() then
      table.insert(choices, "recover")
    end
    local choice = room:askForChoice(player, choices, self.name, "#ty__shushen-choice::"..to.id)
    if choice == "ty__shushen_draw" then
      player:drawCards(1, self.name)
      to:drawCards(1, self.name)
    else
      room:recover({
        who = to,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
local ty__shenzhi = fk.CreateTriggerSkill{
  name = "ty__shenzhi",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and
      player:getHandcardNum() > player.hp and player:isWounded()
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForDiscard(player, 1, 1, false, self.name, true, ".", "#ty__shenzhi-invoke", true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    if not player.dead and player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
ganfuren:addSkill(ty__shushen)
ganfuren:addSkill(ty__shenzhi)
Fk:loadTranslationTable{
  ["ty__ganfuren"] = "甘夫人",
  ["#ty__ganfuren"] = "昭烈皇后",
  ["illustrator:ty__ganfuren"] = "胖虎饭票",

  ["ty__shushen"] = "淑慎",
  [":ty__shushen"] = "当你回复1点体力后，你可以选择一名其他角色，令其回复1点体力或与其各摸一张牌。",
  ["ty__shenzhi"] = "神智",
  [":ty__shenzhi"] = "准备阶段，若你手牌数大于体力值，你可以弃置一张手牌并回复1点体力。",
  ["#ty__shushen-choose"] = "淑慎：你可以令一名其他角色回复1点体力或与其各摸一张牌",
  ["#ty__shushen-choice"] = "淑慎：选择令 %dest 执行的一项",
  ["ty__shushen_draw"] = "各摸一张牌",
  ["#ty__shenzhi-invoke"] = "神智：你可以弃置一张手牌，回复1点体力",

  ["$ty__shushen1"] = "妾身无恙，相公请安心征战。",
  ["$ty__shushen2"] = "船到桥头自然直。",
  ["$ty__shenzhi1"] = "子龙将军，一切都托付给你了。",
  ["$ty__shenzhi2"] = "阿斗，相信妈妈，没事的。",
  ["~ty__ganfuren"] = "请替我照顾好阿斗……",
}

local mifuren = General(extension, "ty__mifuren", "shu", 3, 3, General.Female)
local ty__guixiu = fk.CreateTriggerSkill{
  name = "ty__guixiu",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.TurnStart, fk.AfterSkillEffect},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.TurnStart then
        return player:getMark(self.name) == 0
      else
        return data.name == "ty__cunsi" and player:isWounded()
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnStart then
      player:drawCards(2, self.name)
      room:setPlayerMark(player, self.name, 1)
    else
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
local ty__cunsi = fk.CreateActiveSkill{
  name = "ty__cunsi",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  frequency = Skill.Limited,
  prompt = "#ty__cunsi",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:handleAddLoseSkills(target, "ty__yongjue", nil, true, false)
    if target ~= player then
      player:drawCards(2, self.name)
    end
  end,
}
local ty__yongjue = fk.CreateTriggerSkill{
  name = "ty__yongjue",
  anim_type = "support",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and data.card.trueName == "slash" and
      player:usedCardTimes("slash", Player.HistoryPhase) == 1 and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#ty__yongjue-invoke:::"..data.card:toLogString())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"ty__yongjue_time"}
    if room:getCardArea(data.card) == Card.Processing then
      table.insert(choices, "ty__yongjue_obtain")
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "ty__yongjue_time" then
      player:addCardUseHistory(data.card.trueName, -1)
    else
      room:obtainCard(player, data.card, true, fk.ReasonJustMove)
    end
  end,
}
mifuren:addSkill(ty__guixiu)
mifuren:addSkill(ty__cunsi)
mifuren:addRelatedSkill(ty__yongjue)
Fk:loadTranslationTable{
  ["ty__mifuren"] = "糜夫人",
  ["#ty__mifuren"] = "乱世沉香",
  ["illustrator:ty__mifuren"] = "鲨鱼嚼嚼",
  ["ty__guixiu"] = "闺秀",
  [":ty__guixiu"] = "锁定技，你获得此技能后的第一个回合开始时，你摸两张牌；当你发动〖存嗣〗后，你回复1点体力。",
  ["ty__cunsi"] = "存嗣",
  [":ty__cunsi"] = "限定技，出牌阶段，你可以令一名角色获得〖勇决〗；若不为你，你摸两张牌。",
  ["ty__yongjue"] = "勇决",
  [":ty__yongjue"] = "当你于出牌阶段内使用第一张【杀】时，你可以令其不计入使用次数或获得之。",
  ["#ty__cunsi"] = "存嗣：你可以令一名角色获得〖勇决〗，若不为你，你摸两张牌",
  ["#ty__yongjue-invoke"] = "勇决：你可以令此%arg不计入使用次数，或获得之",
  ["ty__yongjue_time"] = "不计入次数",
  ["ty__yongjue_obtain"] = "获得之",

  ["$ty__guixiu1"] = "闺楼独看花月，倚窗顾影自怜。",
  ["$ty__guixiu2"] = "闺中女子，亦可秀气英拔。",
  ["$ty__cunsi1"] = "存汉室之嗣，留汉室之本。",
  ["$ty__cunsi2"] = "一切，便托付将军了！",
  ["$ty__yongjue1"] = "能救一个是一个！",
  ["$ty__yongjue2"] = "扶幼主，成霸业！",
  ["~ty__mifuren"] = "阿斗被救，妾身……再无牵挂……",
}

local caofang = General(extension, "caofang", "wei", 4)
local zhimin = fk.CreateTriggerSkill{
  name = "zhimin",
  events = {fk.RoundStart, fk.AfterCardsMove},
  frequency = Skill.Compulsory,
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.AfterCardsMove then
      local cards1, cards2 = {}, {}
      local handcards = player:getCardIds(Player.Hand)
      local mark = U.getMark(player, "zhimin_record")
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Player.Hand then
          if player.phase == Player.NotActive then
            for _, info in ipairs(move.moveInfo) do
              local id = info.cardId
              if table.contains(handcards, id) then
                table.insert(cards1, id)
              end
            end
          end
        elseif move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            local id = info.cardId
            if info.fromArea == Player.Hand and table.contains(mark, id) then
              table.insert(cards2, id)
            end
          end
        end
      end
      if #cards1 > 0 or #cards2 > 0 then
        self.cost_data = {cards1, cards2}
        return true
      end
      return false
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      local zhimin_data = table.simpleClone(self.cost_data)
      local mark = U.getMark(player, "zhimin_record")
      if #zhimin_data[1] > 0 then
        table.insertTableIfNeed(mark, zhimin_data[1])
        for _, id in ipairs(zhimin_data[1]) do
          room:setCardMark(Fk:getCardById(id), "@@zhimin-inhand", 1)
        end
      end
      for _, id in ipairs(zhimin_data[2]) do
        table.removeOne(mark, id)
      end
      room:setPlayerMark(player, "zhimin_record", mark)
      if #zhimin_data[2] > 0 then
        local num = player.maxHp - player:getHandcardNum()
        if num > 0 then
          player:drawCards(num, self.name)
        end
      end
    elseif event == fk.RoundStart then
      local targets = table.filter(room.alive_players, function (p)
        return p ~= player and not p:isKongcheng()
      end)
      if #targets == 0 then return false end
      targets = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, player.hp,
      "#zhimin-choose:::" .. tostring(player.hp), self.name, false)
      local to, card, n
      local toObtain = {}
      for _, pid in ipairs(targets) do
        to = room:getPlayerById(pid)
        local cards = {}
        for _, id in ipairs(to:getCardIds(Player.Hand)) do
          card = Fk:getCardById(id)
          if #cards == 0 then
            table.insert(cards, id)
            n = card.number
          else
            if n > card.number then
              n = card.number
              cards = {id}
            elseif n == card.number then
              table.insert(cards, id)
            end
          end
        end
        if #cards > 0 then
          table.insert(toObtain, table.random(cards))
        end
      end
      if #toObtain > 0 then
        room:moveCardTo(toObtain, Player.Hand, player, fk.ReasonPrey, self.name, "", false, player.id)
      end
    end
  end,
}
local jujianc = fk.CreateActiveSkill{
  name = "jujianc$",
  anim_type = "support",
  prompt = "#jujianc-active",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function() return false end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select).kingdom == "wei"
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:drawCards(target, 1, self.name)
    if player.dead or target.dead then return end
    local mark = U.getMark(target, "@@jujianc-round")
    table.insert(mark, player.id)
    room:setPlayerMark(target, "@@jujianc-round", mark)
  end,
}
local jujianc_delay = fk.CreateTriggerSkill{
  name = "#jujianc_delay",
  events = {fk.PreCardEffect},
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return not player.dead and player.id == data.to and data.card:isCommonTrick() and target and
    table.contains(U.getMark(target, "@@jujianc-round"), player.id)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(jujianc.name)
    return true
  end,
}
jujianc:addRelatedSkill(jujianc_delay)
caofang:addSkill(zhimin)
caofang:addSkill(jujianc)

Fk:loadTranslationTable{
  ["caofang"] = "曹芳",
  ["#caofang"] = "迷瞑终觉",
  ["cv:caofang"] = "陆泊云",
  ["illustrator:caofang"] = "鬼画府",

  ["zhimin"] = "置民",
  [":zhimin"] = "锁定技，每轮开始时，你选择至多X名其他角色（x为你的体力值），获得这些角色点数最小的一张手牌。"..
  "你于回合外得到牌后，这些牌称为“民”。当你失去“民”后，你将手牌补至体力上限。",
  ["jujianc"] = "拒谏",
  [":jujianc"] = "主公技，出牌阶段限一次，你可以令一名其他魏势力角色摸一张牌，直到本轮结束，其使用的普通锦囊牌对你无效。",
  ["#jujianc-active"] = "发动 拒谏，令一名其他魏势力角色摸一张牌，其本轮内使用普通锦囊牌对你无效",
  ["#zhimin-choose"] = "置民：选择1-%arg名角色，获得这些角色手牌中点数最小的牌",
  ["@@zhimin-inhand"] = "民",
  ["@@jujianc-round"] = "拒谏",
  ["#jujianc_delay"] = "拒谏",

  ["$zhimin1"] = "渤海虽阔，亦不及朕胸腹之广。",
  ["$zhimin2"] = "民众渡海而来，当筑梧居相待。",
  ["$jujianc1"] = "尔等眼中，只见到朕的昏庸吗？",
  ["$jujianc2"] = "我做天子，不得自在邪？",
  ["~caofang"] = "匹夫无罪，怀璧其罪……",
}

local zhupeilan = General(extension, "zhupeilan", "wu", 3, 3, General.Female)
local cilv = fk.CreateTriggerSkill{
  name = "cilv",
  anim_type = "defensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card:isCommonTrick() and not table.every({1,2,3}, function (i)
      return player:getMark("cilv" .. tostring(i)) > 0
    end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local nums = table.filter({1,2,3}, function (i)
      return player:getMark("cilv" .. tostring(i)) == 0
    end)
    player:drawCards(#nums, self.name)
    if player.dead or player:getHandcardNum() <= player.maxHp then return false end
    local all_choices = {"cilv1", "cilv2", "cilv3"}
    local choices = table.filter(all_choices, function (choice)
      return player:getMark(choice) == 0
    end)
    if #choices == 0 then return false end
    local choice = room:askForChoice(player, choices, self.name, "#cilv-choose:::"..data.card:toLogString(), false, all_choices)
    room:setPlayerMark(player, choice, 1)
    if choice == "cilv1" then
      table.insertIfNeed(data.nullifiedTargets, player.id)
    elseif choice == "cilv2" then
      data.extra_data = data.extra_data or {}
      data.extra_data.cilv_defensive = data.extra_data.cilv_defensive or {}
      table.insert(data.extra_data.cilv_defensive, player.id)
    elseif choice == "cilv3" then
      data.extra_data = data.extra_data or {}
      data.extra_data.cilv_recycle = data.extra_data.cilv_recycle or {}
      table.insert(data.extra_data.cilv_recycle, player.id)
    end
  end,

  refresh_events = {fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "cilv1", 0)
    room:setPlayerMark(player, "cilv2", 0)
    room:setPlayerMark(player, "cilv3", 0)
  end,
}
local cilv_delay = fk.CreateTriggerSkill{
  name = "#cilv_delay",
  mute = true,
  events = {fk.CardUseFinished, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if player.dead then return false end
    if event == fk.CardUseFinished then
      return data.extra_data and data.extra_data.cilv_recycle and table.contains(data.extra_data.cilv_recycle, player.id) and
      player.room:getCardArea(data.card) == Card.Processing
    elseif event == fk.DamageInflicted then
      if player == target and data.card then
        local card_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
        if not card_event then return false end
        local use = card_event.data[1]
        return use.extra_data and use.extra_data.cilv_defensive and table.contains(use.extra_data.cilv_defensive, player.id)
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    if event == fk.CardUseFinished then
      player.room:obtainCard(player.id, data.card, true, fk.ReasonJustMove)
    else
      return true
    end
  end,
}
local tongdao = fk.CreateTriggerSkill{
  name = "tongdao",
  anim_type = "support",
  events = {fk.AskForPeaches},
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(self) and
      data.who == player.id and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room.alive_players, function (p)
      return p.id end), 1, 1, "#tongdao-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    --“愚蠢技能” —— by Ho-spair
    --FIXME:先伪实现一下
    local skills = {}
    for _, s in ipairs(to.player_skills) do
      if s:isPlayerSkill(to) then
        table.insertIfNeed(skills, s.name)
      end
    end
    if room.settings.gameMode == "m_1v2_mode" and to.role == "lord" then
      table.removeOne(skills, "m_feiyang")
      table.removeOne(skills, "m_bahu")
    end
    if #skills > 0 then
      room:handleAddLoseSkills(to, "-"..table.concat(skills, "|-"), nil, true, false)
    end
    skills = Fk.generals[to.general]:getSkillNameList(true)
    if to.deputyGeneral ~= "" then
      table.insertTableIfNeed(skills, Fk.generals[to.deputyGeneral]:getSkillNameList(true))
    end
    --FIXME:需要排除主公技，懒得写
    if #skills > 0 then
      --需要重置限定技、觉醒技、转换技、使命技
      local skill
      for _, skill_name in ipairs(skills) do
        skill = Fk.skills[skill_name]
        if skill.frequency == Skill.Quest then
          room:setPlayerMark(to, MarkEnum.QuestSkillPreName .. skill_name, 0)
        end
        if skill.switchSkillName then
          room:setPlayerMark(to, MarkEnum.SwithSkillPreName .. skill_name, fk.SwitchYang)
        end
        to:setSkillUseHistory(skill_name, 0, Player.HistoryGame)
      end
      room:handleAddLoseSkills(to, table.concat(skills, "|"), nil, true, false)
    end
    if not (player.dead or target.dead) and player:isWounded() and player.hp < to.hp then
      room:recover {
        who = player,
        num = to.hp - player.hp,
        recoverBy = player,
        skillName = self.name,
      }
    end
  end,
}
cilv:addRelatedSkill(cilv_delay)
zhupeilan:addSkill(cilv)
zhupeilan:addSkill(tongdao)
Fk:loadTranslationTable{
  ["zhupeilan"] = "朱佩兰",
  --["#zhupeilan"] = "",
  --["illustrator:zhupeilan"] = "",

  ["cilv"] = "辞虑",
  [":cilv"] = "当你成为普通锦囊牌的目标后，你可以摸X张牌（X为此技能的剩余选项数），"..
  "若你的手牌数大于你的体力上限，你选择并移除一项："..
  "1.此牌对你无效；2.此牌对你造成伤害时防止之；3.此牌结算结束后你获得之。",
  ["tongdao"] = "痛悼",
  [":tongdao"] = "限定技，当你处于濒死状态时，你可以选择一名角色，其失去所有技能，获得其武将牌上的所有技能,"..
  "你回复体力至X点（X为其体力值）。",

  ["#tongdao-choose"] = "是否发动 痛悼，选择一名角色，令其技能还原为初始状态，并回复体力至与该角色相同",
  ["#cilv-choose"] = "辞虑：选择一项对%arg执行，然后移除此项",
  ["cilv1"] = "此牌对你无效",
  ["cilv2"] = "防止此牌对你造成的伤害",
  ["cilv3"] = "此牌结算后你获得之",
  ["#cilv_delay"] = "辞虑",
}

--往者可谏：大乔小乔 SP马超 SP赵云 SP甄姬
local zhenji = General(extension, "ty_sp__zhenji", "qun", 3, 3, General.Female)
local jijiez = fk.CreateTriggerSkill{
  name = "jijiez",
  events = {fk.AfterCardsMove, fk.HpRecover},
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.AfterCardsMove then
        if player:getMark("jijiez_draw-turn") > 0 then return false end
        local ban_players = {player.id}
        if player.room.current.phase ~= Player.NotActive then
          table.insert(ban_players, player.room.current.id)
        end
        local x = 0
        for _, move in ipairs(data) do
          if move.to and not table.contains(ban_players, move.to) and move.toArea == Card.PlayerHand then
            x = x + #move.moveInfo
          end
        end
        if x > 0 then
          self.cost_data = x
          return true
        end
      elseif event == fk.HpRecover then
        return player:getMark("jijiez_recover-turn") == 0 and player:isWounded() and
        target ~= player and target.phase == Player.NotActive
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.AfterCardsMove then
      room:notifySkillInvoked(player, self.name, "drawcard")
      room:setPlayerMark(player, "jijiez_draw-turn", 1)
      player:drawCards(self.cost_data, self.name)
    elseif event == fk.HpRecover then
      room:notifySkillInvoked(player, self.name, "support")
      room:setPlayerMark(player, "jijiez_recover-turn", 1)
      room:recover{
        who = player,
        num = data.num,
        recoverBy = player,
        skillName = self.name,
      }
    end
  end,
}
local huiji__amazingGraceSkill = fk.CreateActiveSkill{
  name = "huiji__amazing_grace_skill",
  prompt = "#amazing_grace_skill",
  can_use = Util.GlobalCanUse,
  on_use = Util.GlobalOnUse,
  mod_target_filter = Util.TrueFunc,
  on_action = function(self, room, use, finished)
    local player = room:getPlayerById(use.from)
    if not finished then
      local toDisplay = player:getCardIds(Player.Hand)
      room:moveCardTo(toDisplay, Card.Processing, nil, fk.ReasonJustMove, "amazing_grace_skill", "", true, player.id)

      table.forEach(room.players, function(p)
        room:fillAG(p, toDisplay)
      end)

      use.extra_data = use.extra_data or {}
      use.extra_data.AGFilled = toDisplay
    else
      if use.extra_data and use.extra_data.AGFilled then
        table.forEach(room.players, function(p)
          room:closeAG(p)
        end)

        local toDiscard = table.filter(use.extra_data.AGFilled, function(id)
          return room:getCardArea(id) == Card.Processing
        end)

        if #toDiscard > 0 then
          if player.dead then
            room:moveCards({
              ids = toDiscard,
              toArea = Card.DiscardPile,
              moveReason = fk.ReasonPutIntoDiscardPile,
            })
          else
            room:moveCardTo(toDiscard, Card.PlayerHand, player, fk.ReasonJustMove, "amazing_grace_skill", "", true, player.id)
          end
        end
      end

      use.extra_data.AGFilled = nil
    end
  end,
  on_effect = function(self, room, effect)
    local to = room:getPlayerById(effect.to)
    if not (effect.extra_data and effect.extra_data.AGFilled and #effect.extra_data.AGFilled > 0) then
      return
    end

    local chosen = room:askForAG(to, effect.extra_data.AGFilled, false, "amazing_grace_skill")
    room:takeAG(to, chosen, room.players)
    room:obtainCard(effect.to, chosen, true, fk.ReasonPrey)
    table.removeOne(effect.extra_data.AGFilled, chosen)
  end,
}
Fk:addSkill(huiji__amazingGraceSkill)
local huiji = fk.CreateActiveSkill{
  name = "huiji",
  target_num = 1,
  card_num = 0,
  prompt = "#huiji-active",
  anim_type = "control",
  interaction = function()
    return UI.ComboBox {
      choices = {"draw2", "huiji_equip"}
    }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    if self.interaction.data == "draw2" then
      target:drawCards(2, self.name)
    else
      local cards = {}
      for i = 1, #room.draw_pile, 1 do
        local card = Fk:getCardById(room.draw_pile[i])
        if card.type == Card.TypeEquip and target:canUseTo(card, target) then
          table.insertIfNeed(cards, card)
        end
      end
      if #cards > 0 then
        room:useCard{
          from = target.id,
          card = cards[math.random(1, #cards)],
          tos = {{target.id}},
        }
      end
    end
    if target.dead or target:getHandcardNum() < #room.alive_players then return end
    local amazing_grace = Fk:cloneCard("amazing_grace")
    amazing_grace.skillName = self.name
    if target:prohibitUse(amazing_grace) or table.every(room.alive_players, function (p)
      return target:isProhibited(p, amazing_grace)
    end) then return end
    amazing_grace.skill = huiji__amazingGraceSkill
    room:useCard{
      from = target.id,
      card = amazing_grace
    }
  end,
}
zhenji:addSkill(jijiez)
zhenji:addSkill(huiji)
Fk:loadTranslationTable{
  ["ty_sp__zhenji"] = "甄姬",
  ["#ty_sp__zhenji"] = "善言贤女",
  ["illustrator:ty_sp__zhenji"] = "匠人绘",

  ["jijiez"] = "己诫",
  [":jijiez"] = "锁定技，当其他角色于其回合外得到牌后/回复体力后，你摸等量的牌/回复等量的体力（每回合各限一次）。",
  ["huiji"] = "惠济",
  [":huiji"] = "出牌阶段限一次，你可以令一名角色摸两张牌或使用牌堆中的一张随机装备牌。若其手牌数不小于存活角色数，"..
  "其视为使用【五谷丰登】（改为从该角色的手牌中挑选）。",

  ["#huiji-active"] = "发动 惠济，选择一名角色",
  ["huiji_equip"] = "使用装备",

  ["$jijiez1"] = "闻古贤女，未有不学前世成败者。",
  ["$jijiez2"] = "不知书，何由见之。",
  ["$huiji1"] = "云鬓释远，彩衣婀娜。",
  ["$huiji2"] = "明眸善睐，瑰姿艳逸。",
  ["~ty_sp__zhenji"] = "自古英雄迟暮，谁见佳人白头？",
}

--章台春望：郭照 樊玉凤 阮瑀 杨婉 潘淑
local guozhao = General(extension, "guozhao", "wei", 3, 3, General.Female)
local pianchong = fk.CreateTriggerSkill{
  name = "pianchong",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Draw
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    local color = Card.NoColor
    for _, id in ipairs(room.draw_pile) do
      local _color = Fk:getCardById(id).color
      if _color ~= color and _color ~= Card.NoColor then
        color = _color
        table.insert(cards, id)
        if #cards == 2 then break end
      end
    end
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = self.name,
        moveVisible = true,
      })
    end
    local choice = room:askForChoice(player, {"red", "black"}, self.name, "#pianchong-choice")
    local mark = U.getMark(player, "@pianchong")
    table.insertIfNeed(mark, choice)
    room:setPlayerMark(player, "@pianchong", mark)
    return true
  end,
  
  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@pianchong") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@pianchong", 0)
  end,
}
local pianchong_delay = fk.CreateTriggerSkill{
  name = "#pianchong_delay",
  mute = true,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player.dead then return false end
    local colors = U.getMark(player, "@pianchong")
    if #colors == 0 then return false end
    local x, y = 0, 0
    local color
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            color = Fk:getCardById(info.cardId).color
            if color == Card.Red then
              x = x + 1
            elseif color == Card.Black then
              y = y + 1
            end
          end
        end
      end
    end
    if not table.contains(colors, "red") then
      x = 0
    end
    if not table.contains(colors, "black") then
      y = 0
    end
    if x > 0 or y > 0 then
      self.cost_data = {x, y}
      return true
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x, y = table.unpack(self.cost_data)
    local color
    local cards = {}
    for _, id in ipairs(room.draw_pile) do
      color = Fk:getCardById(id).color
      if color == Card.Black then
        if x > 0 then
          x = x - 1
          table.insert(cards, id)
        end
      elseif color == Card.Red then
        if y > 0 then
          y = y - 1
          table.insert(cards, id)
        end
      end
      if x == 0 and y == 0 then break end
    end
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = pianchong.name,
        moveVisible = true,
      })
    end
  end,
}
local zunwei = fk.CreateActiveSkill{
  name = "zunwei",
  prompt = "#zunwei-active",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  interaction = function()
    local choices, all_choices = {}, {}
    for i = 1, 3 do
      local choice = "zunwei"..tostring(i)
      table.insert(all_choices, choice)
      if Self:getMark(choice) == 0 then
        table.insert(choices, choice)
      end
    end
    return UI.ComboBox {choices = choices, all_choices = all_choices}
  end,
  can_use = function(self, player)
    if player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 then
      for i = 1, 3, 1 do
        if player:getMark(self.name .. tostring(i)) == 0 then
          return true
        end
      end
    end
    return false
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return self.interaction.data and #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local choice = self.interaction.data
    if choice == "zunwei1" then
      local x = math.min(target:getHandcardNum() - player:getHandcardNum(), 5)
      if x > 0 then
        room:drawCards(player, x, self.name)
      end
    elseif choice == "zunwei2" then
      local subtypes = {
        Card.SubtypeWeapon,
        Card.SubtypeArmor,
        Card.SubtypeDefensiveRide,
        Card.SubtypeOffensiveRide,
        Card.SubtypeTreasure
      }
      local subtype
      local cards = {}
      local card
      while not (player.dead or target.dead) and
      #player.player_cards[Player.Equip] < #target.player_cards[Player.Equip] do
        while #subtypes > 0 do
          subtype = table.remove(subtypes, 1)
          if player:hasEmptyEquipSlot(subtype) then
            cards = table.filter(room.draw_pile, function (id)
              card = Fk:getCardById(id)
              return card.sub_type == subtype and U.canUseCardTo(room, player, player, card)
            end)
            if #cards > 0 then
              room:useCard{
                from = player.id,
                card = Fk:getCardById(cards[math.random(1, #cards)]),
              }
              break
            end
          end
        end
        if #subtypes == 0 then break end
      end
    elseif choice == "zunwei3" and player:isWounded() then
      local x = target.hp - player.hp
      if x > 0 then
      room:recover{
        who = player,
        num = math.min(player:getLostHp(), x),
        recoverBy = player,
        skillName = self.name}
      end
    end
    room:setPlayerMark(player, choice, 1)
  end,
}
pianchong:addRelatedSkill(pianchong_delay)
guozhao:addSkill(pianchong)
guozhao:addSkill(zunwei)
Fk:loadTranslationTable{
  ["guozhao"] = "郭照",
  ["#guozhao"] = "碧海青天",
  ["designer:guozhao"] = "世外高v狼",
  ["illustrator:guozhao"] = "杨杨和夏季",
  ["pianchong"] = "偏宠",
  [":pianchong"] = "摸牌阶段，你可以改为从牌堆获得红牌和黑牌各一张，然后选择一项直到你的下回合开始：1.你每失去一张红色牌时摸一张黑色牌，"..
  "2.你每失去一张黑色牌时摸一张红色牌。",
  ["zunwei"] = "尊位",
  [":zunwei"] = "出牌阶段限一次，你可以选择一名其他角色，并选择执行以下一项，然后移除该选项：1.将手牌数摸至与该角色相同（最多摸五张）；"..
  "2.随机使用牌堆中的装备牌至与该角色相同；3.将体力回复至与该角色相同。",
  ["#pianchong_delay"] = "偏宠",
  ["@pianchong"] = "偏宠",
  ["#pianchong-choice"] = "偏宠：选择一种颜色，失去此颜色的牌时，摸另一种颜色的牌",
  ["#zunwei-active"] = "发动 尊位，选择一名其他角色并执行一项效果",
  ["zunwei1"] = "将手牌摸至与其相同（最多摸五张）",
  ["zunwei2"] = "使用装备至与其相同",
  ["zunwei3"] = "回复体力至与其相同",

  ["$pianchong1"] = "得陛下怜爱，恩宠不衰。",
  ["$pianchong2"] = "谬蒙圣恩，光授殊宠。",
  ["$zunwei1"] = "处尊居显，位极椒房。",
  ["$zunwei2"] = "自在东宫，及即尊位。",
  ["~guozhao"] = "我的出身，不配为后？",
}

local fanyufeng = General(extension, "fanyufeng", "qun", 3, 3, General.Female)
local bazhan = fk.CreateActiveSkill{
  name = "bazhan",
  anim_type = "switch",
  switch_skill_name = "bazhan",
  prompt = function ()
    return Self:getSwitchSkillState("bazhan", false) == fk.SwitchYang and "#bazhan-Yang" or "#bazhan-Yin"
  end,
  target_num = 1,
  max_card_num = function ()
    return (Self:getSwitchSkillState("bazhan", false) == fk.SwitchYang) and 2 or 0
  end,
  min_card_num = function ()
    return (Self:getSwitchSkillState("bazhan", false) == fk.SwitchYang) and 1 or 0
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_filter = function(self, to_select, selected)
    return #selected < self:getMaxCardNum() and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected_cards >= self:getMinCardNum() and #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local isYang = player:getSwitchSkillState(self.name, true) == fk.SwitchYang

    local to_check = {}
    if isYang and #effect.cards > 0 then
      table.insertTable(to_check, effect.cards)
      room:obtainCard(target.id, to_check, false, fk.ReasonGive, player.id)
    elseif not isYang and not target:isKongcheng() then
      to_check = room:askForCardsChosen(player, target, 1, 2, "h", self.name)
      room:obtainCard(player, to_check, false, fk.ReasonPrey)
      target = player
    end
    if not player.dead and not target.dead and table.find(to_check, function (id)
    return Fk:getCardById(id).name == "analeptic" or Fk:getCardById(id).suit == Card.Heart end) then
      local choices = {"cancel"}
      if not target.faceup or target.chained then
        table.insert(choices, 1, "bazhan_reset")
      end
      if target:isWounded() then
        table.insert(choices, 1, "recover")
      end
      if #choices > 1 then
        local choice = room:askForChoice(player, choices, self.name, "#bazhan-support::" .. target.id)
        if choice == "recover" then
          room:recover{ who = target, num = 1, recoverBy = player, skillName = self.name }
        elseif choice == "bazhan_reset" then
          if not target.faceup then
            target:turnOver()
          end
          if target.chained then
            target:setChainState(false)
          end
        end
      end
    end
  end,
}
local jiaoying = fk.CreateTriggerSkill{
  name = "jiaoying",
  events = {fk.AfterCardsMove},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      for _, move in ipairs(data) do
        if move.from == player.id and move.to and move.to ~= player.id and move.toArea == Card.PlayerHand then
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
    local room = player.room
    local jiaoying_targets = type(player:getMark("jiaoying_targets-turn")) == "table" and player:getMark("jiaoying_targets-turn") or {}
    for _, move in ipairs(data) do
      if move.from == player.id and move.to and move.to ~= player.id and move.toArea == Card.PlayerHand then
        local to = room:getPlayerById(move.to)
        local jiaoying_colors = type(to:getMark("jiaoying_colors-turn")) == "table" and to:getMark("jiaoying_colors-turn") or {}
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            local color = Fk:getCardById(info.cardId).color
            if color ~= Card.NoColor then
              table.insertIfNeed(jiaoying_colors, color)
              table.insertIfNeed(jiaoying_targets, to.id)
              if to:getMark("@jiaoying-turn") == 0 then
                room:setPlayerMark(to, "@jiaoying-turn", {})
              end
            end
          end
        end
        room:setPlayerMark(to, "jiaoying_colors-turn", jiaoying_colors)
      end
    end
    room:setPlayerMark(player, "jiaoying_targets-turn", jiaoying_targets)
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    local jiaoying_targets = type(player:getMark("jiaoying_targets-turn")) == "table" and player:getMark("jiaoying_targets-turn") or {}
    local jiaoying_ignores = type(player:getMark("jiaoying_ignores-turn")) == "table" and player:getMark("jiaoying_ignores-turn") or {}
    return table.contains(jiaoying_targets, target.id) and not table.contains(jiaoying_ignores, target.id)
  end,
  on_refresh = function(self, event, target, player, data)
    local jiaoying_ignores = type(player:getMark("jiaoying_ignores-turn")) == "table" and player:getMark("jiaoying_ignores-turn") or {}
    table.insert(jiaoying_ignores, target.id)
    player.room:setPlayerMark(player, "jiaoying_ignores-turn", jiaoying_ignores)
    player.room:setPlayerMark(target, "@jiaoying-turn", {"jiaoying_usedcard"})
  end,
}
local jiaoying_delay = fk.CreateTriggerSkill{
  name = "#jiaoying_delay",
  events = {fk.EventPhaseStart},
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target.phase == Player.Finish then
      local jiaoying_targets = type(player:getMark("jiaoying_targets-turn")) == "table" and player:getMark("jiaoying_targets-turn") or {}
      local jiaoying_ignores = type(player:getMark("jiaoying_ignores-turn")) == "table" and player:getMark("jiaoying_ignores-turn") or {}
      self.cost_data = #jiaoying_targets - #jiaoying_ignores
      if self.cost_data > 0 then
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = self.cost_data
    local targets = player.room:askForChoosePlayers(player, table.map(table.filter(room.alive_players, function (p)
      return p:getHandcardNum() < 5 end), Util.IdMapper), 1, x, "#jiaoying-choose:::" .. x, self.name, true)
    if #targets > 0 then
      room:sortPlayersByAction(targets)
      for _, pid in ipairs(targets) do
        local to = room:getPlayerById(pid)
        if not to.dead and to:getHandcardNum() < 5 then
          to:drawCards(5-to:getHandcardNum(), self.name)
        end
      end
    end
  end,
}
local jiaoying_prohibit = fk.CreateProhibitSkill{
  name = "#jiaoying_prohibit",
  prohibit_use = function(self, player, card)
    local jiaoying_colors = player:getMark("jiaoying_colors-turn")
    return type(jiaoying_colors) == "table" and table.contains(jiaoying_colors, card.color)
  end,
  prohibit_response = function(self, player, card)
    local jiaoying_colors = player:getMark("jiaoying_colors-turn")
    return type(jiaoying_colors) == "table" and table.contains(jiaoying_colors, card.color)
  end,
}
jiaoying:addRelatedSkill(jiaoying_delay)
jiaoying:addRelatedSkill(jiaoying_prohibit)
fanyufeng:addSkill(bazhan)
fanyufeng:addSkill(jiaoying)
Fk:loadTranslationTable{
  ["fanyufeng"] = "樊玉凤",
  ["#fanyufeng"] = "红鸾寡宿",
  ["cv:fanyufeng"] = "杨子怡",
  ["illustrator:fanyufeng"] = "匠人绘",
  ["bazhan"] = "把盏",
  [":bazhan"] = "转换技，出牌阶段限一次，阳：你可以交给一名其他角色至多两张手牌；阴：你可以获得一名其他角色至多两张手牌。"..
  "然后若这些牌里包括【酒】或<font color='red'>♥</font>牌，你可令获得此牌的角色回复1点体力或复原武将牌。",
  ["jiaoying"] = "醮影",
  ["#jiaoying_delay"] = "醮影",
  [":jiaoying"] = "锁定技，其他角色获得你的手牌后，该角色本回合不能使用或打出与此牌颜色相同的牌。然后此回合结束阶段，"..
  "若其本回合没有再使用牌，你令一名角色将手牌摸至五张。",
  ["#bazhan-Yang"] = "把盏（阳）：选择一至两张手牌，交给一名其他角色",
  ["#bazhan-Yin"] = "把盏（阴）：选择一名有手牌的其他角色，获得其一至两张手牌",
  ["#bazhan-support"] = "把盏：可以选择令 %dest 回复1点体力或复原武将牌",
  ["#jiaoying-choose"] = "醮影：可选择至多%arg名角色将手牌补至5张",
  ["@jiaoying-turn"] = "醮影",
  ["jiaoying_usedcard"] = "使用过牌",

  ["$bazhan1"] = "此酒，当配将军。",
  ["$bazhan2"] = "这杯酒，敬于将军。",
  ["$jiaoying1"] = "独酌清醮，霓裳自舞。",
  ["$jiaoying2"] = "醮影倩丽，何人爱怜。",
  ["~fanyufeng"] = "醮妇再遇良人难……",
}

local ruanyu = General(extension, "ruanyu", "wei", 3)
local xingzuo = fk.CreateTriggerSkill{
  name = "xingzuo",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(3, "bottom")
    local handcards = player:getCardIds(Player.Hand)
    local cardmap = U.askForArrangeCards(player, self.name,
    {cards, handcards, "Bottom", "$Hand"}, "#xingzuo-invoke")
    U.swapCardsWithPile(player, cardmap[1], cardmap[2], self.name, "Bottom")
  end,
}
local xingzuo_delay = fk.CreateTriggerSkill{
  name = "#xingzuo_delay",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and player.phase == Player.Finish and
    player:usedSkillTimes(xingzuo.name, Player.HistoryTurn) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p)
      return not p:isKongcheng() end), Util.IdMapper)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#xingzuo-choose", xingzuo.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(xingzuo.name)
    local to = room:getPlayerById(self.cost_data)
    local cards = to:getCardIds(Player.Hand)
    local n = #cards
    U.swapCardsWithPile(to, cards, room:getNCards(3, "bottom"), self.name, "Bottom")
    if n > 3 and not player.dead then
      room:loseHp(player, 1, xingzuo.name)
    end
  end,
}

local miaoxian = fk.CreateViewAsSkill{
  name = "miaoxian",
  pattern = ".|.|.|.|.|trick|.",
  prompt = "#miaoxian",
  interaction = function()
    local blackcards = table.filter(Self.player_cards[Player.Hand], function(id) return Fk:getCardById(id).color == Card.Black end)
    if #blackcards ~= 1 then return false end
    local names, all_names = {} , {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card:isCommonTrick() and not card.is_derived and not table.contains(all_names, card.name) then
        table.insert(all_names, card.name)
        local to_use = Fk:cloneCard(card.name)
        to_use:addSubcard(blackcards[1])
        if ((Fk.currentResponsePattern == nil and card.skill:canUse(Self, to_use) and not Self:prohibitUse(to_use)) or
        (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(to_use))) then
          table.insert(names, card.name)
        end
      end
    end
    if #names == 0 then return false end
    return UI.ComboBox { choices = names, all_choices = all_names }
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    if not self.interaction.data then return nil end
    local blackcards = table.filter(Self.player_cards[Player.Hand], function(id) return Fk:getCardById(id).color == Card.Black end)
    if #blackcards ~= 1 then return nil end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(blackcards[1])
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    return not player:isKongcheng() and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
      #table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id).color == Card.Black end) == 1
  end,
  enabled_at_response = function(self, player, response)
    return not response and Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):matchExp(self.pattern) and
      not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
      #table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id).color == Card.Black end) == 1
  end,
}
local miaoxian_trigger = fk.CreateTriggerSkill{
  name = "#miaoxian_trigger",
  anim_type = "drawcard",
  events = {fk.CardUsing},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and table.every(player:getCardIds("h"), function(id)
      return Fk:getCardById(id).color ~= Card.Red end) and data.card.color == Card.Red and
      not (data.card:isVirtual() and #data.card.subcards ~= 1)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, miaoxian.name, self.anim_type)
    player:broadcastSkillInvoke(miaoxian.name)
    player:drawCards(1, "miaoxian")
  end,
}
xingzuo:addRelatedSkill(xingzuo_delay)
miaoxian:addRelatedSkill(miaoxian_trigger)
ruanyu:addSkill(xingzuo)
ruanyu:addSkill(miaoxian)
Fk:loadTranslationTable{
  ["ruanyu"] = "阮瑀",
  ["#ruanyu"] = "斐章雅律",
  ["designer:ruanyu"] = "步穗",
  ["illustrator:ruanyu"] = "alien",
  ["xingzuo"] = "兴作",
  [":xingzuo"] = "出牌阶段开始时，你可观看牌堆底的三张牌并用任意张手牌替换其中等量的牌。若如此做，结束阶段，"..
  "你可以令一名有手牌的角色用所有手牌替换牌堆底的三张牌，然后若交换前该角色的手牌数大于3，你失去1点体力。",
  ["miaoxian"] = "妙弦",
  [":miaoxian"] = "每回合限一次，你可以将手牌中的唯一黑色牌当任意一张普通锦囊牌使用；当你使用手牌中的唯一红色牌时，你摸一张牌。",
  ["#xingzuo-invoke"] = "兴作：你可观看牌堆底的三张牌，并用任意张手牌替换其中等量的牌",
  ["#xingzuo_delay"] = "兴作",
  ["#xingzuo-choose"] = "兴作：你可以令一名角色用所有手牌替换牌堆底的三张牌，若交换前其手牌数大于3，你失去1点体力",
  ["#miaoxian_trigger"] = "妙弦",
  ["#miaoxian"] = "妙弦：将手牌中的黑色牌当任意锦囊牌使用",

  ["$xingzuo1"] = "顺人之情，时之势，兴作可成。",
  ["$xingzuo2"] = "兴作从心，相继不绝。",
  ["$miaoxian1"] = "女为悦者容，士为知己死。",
  ["$miaoxian2"] = "与君高歌，请君侧耳。",
  ["~ruanyu"] = "良时忽过，身为土灰。",
}

local yangwan = General(extension, "ty__yangwan", "shu", 3, 3, General.Female)
local youyan = fk.CreateTriggerSkill{
  name = "youyan",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and (player.phase == Player.Play or player.phase == Player.Discard) and
      player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 then
      local suits = {"spade", "club", "heart", "diamond"}
      local can_invoked = false
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and move.moveReason ~= fk.ReasonUse and move.moveReason ~= fk.ReasonResonpse then
          if move.from == player.id then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                table.removeOne(suits, Fk:getCardById(info.cardId):getSuitString())
                can_invoked = true
              end
            end
          else
            local room = player.room
            local parentPindianEvent = player.room.logic:getCurrentEvent():findParent(GameEvent.Pindian, true)
            if parentPindianEvent then
              local pindianData = parentPindianEvent.data[1]
              if pindianData.from == player then
                local leftFromCardIds = room:getSubcardsByRule(pindianData.fromCard)
                for _, info in ipairs(move.moveInfo) do
                  if info.fromArea == Card.Processing and table.contains(leftFromCardIds, info.cardId) then
                    table.removeOne(suits, Fk:getCardById(info.cardId):getSuitString())
                    can_invoked = true
                  end
                end
              end
              for toId, result in pairs(pindianData.results) do
                if player.id == toId then
                  local leftToCardIds = room:getSubcardsByRule(result.toCard)
                  for _, info in ipairs(move.moveInfo) do
                    if info.fromArea == Card.Processing and table.contains(leftToCardIds, info.cardId) then
                      table.removeOne(suits, Fk:getCardById(info.cardId):getSuitString())
                      can_invoked = true
                    end
                  end
                end
              end
            end
          end
        end
      end
      if can_invoked and #suits > 0 then
        self.cost_data = suits
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suits = self.cost_data
    local cards = {}
    while #suits > 0 do
      local pattern = table.random(suits)
      table.removeOne(suits, pattern)
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|"..pattern))
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
}
local zhuihuan = fk.CreateTriggerSkill{
  name = "zhuihuan",
  anim_type = "defensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room.alive_players, Util.IdMapper), 1, 1, "#zhuihuan-choose", self.name, true, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player.room:getPlayerById(self.cost_data), self.name, 1)
  end,
}
local zhuihuan_delay = fk.CreateTriggerSkill{
  name = "#zhuihuan_delay",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Start and player:getMark("zhuihuan") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "zhuihuan", 0)
    local mark = U.getMark(player, "zhuihuan_record")
    local targets = table.filter(room:getAlivePlayers(), function (p)
      return table.contains(mark, p.id)
    end)
    room:setPlayerMark(player, "zhuihuan_record", 0)
    for _, p in ipairs(targets) do
      if player.dead then break end
      if not p.dead then
        if p.hp > player.hp then
          room:damage({
            from = player,
            to = p,
            damage = 2,
            damageType = fk.NormalDamage,
            skillName = "zhuihuan"
          })
        else
          local cards = table.filter(p:getCardIds(Player.Hand), function (id)
            return not p:prohibitDiscard(Fk:getCardById(id))
          end)
          cards = table.random(cards, 2)
          if #cards > 0 then
            room:throwCard(cards, "zhuihuan", p, p)
          end
        end
      end
    end
  end,

  refresh_events = {fk.Damaged},
  can_refresh = function(self, event, target, player, data)
    return player == target and player:getMark("zhuihuan") ~= 0 and data.from
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = U.getMark(player, "zhuihuan_record")
    table.insert(mark, data.from.id)
    room:setPlayerMark(player, "zhuihuan_record", mark)
  end,
}
zhuihuan:addRelatedSkill(zhuihuan_delay)
yangwan:addSkill(youyan)
yangwan:addSkill(zhuihuan)
Fk:loadTranslationTable{
  ["ty__yangwan"] = "杨婉",
  ["#ty__yangwan"] = "融沫之鲡",
  ["illustrator:ty__yangwan"] = "木美人",
  ["youyan"] = "诱言",
  [":youyan"] = "你的回合内，当你的牌因使用或打出之外的方式进入弃牌堆后，你可以从牌堆中获得本次弃牌中没有的花色的牌各一张（出牌阶段、弃牌阶段各限一次）。",
  ["zhuihuan"] = "追还",
  [":zhuihuan"] = "结束阶段，你可以秘密选择一名角色。直到该角色的下个准备阶段，此期间内对其造成过伤害的角色："..
  "若体力值大于该角色，则受到其造成的2点伤害；若体力值小于等于该角色，则随机弃置两张手牌。",
  ["#zhuihuan-choose"] = "追还：选择一名角色，直到其准备阶段，对此期间对其造成过伤害的角色造成伤害或弃牌",
  ["#zhuihuan_delay"] = "追还",

  ["$youyan1"] = "诱言者，为人所不齿。",
  ["$youyan2"] = "诱言之弊，不可不慎。",
  ["$zhuihuan1"] = "伤人者，追而还之！",
  ["$zhuihuan2"] = "追而还击，皆为因果。",
  ["~ty__yangwan"] = "遇人不淑……",
}

local panshu = General(extension, "ty__panshu", "wu", 3, 3, General.Female)
local zhiren = fk.CreateTriggerSkill{
  name = "zhiren",
  anim_type = "control",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and not data.card:isVirtual() and
    (player.phase ~= Player.NotActive or player:getMark("@@yaner") > 0) then
      local room = player.room
      local logic = room.logic
      local use_event = logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if use_event == nil then return false end
      local mark = player:getMark("zhiren_record-turn")
      if mark == 0 then
        logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
          local last_use = e.data[1]
          if last_use.from == player.id and not last_use.card:isVirtual() then
            mark = e.id
            room:setPlayerMark(player, "zhiren_record-turn", mark)
            return true
          end
          return false
        end, Player.HistoryTurn)
      end
      return mark == use_event.id
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = Fk:translate(data.card.trueName, "zh_CN"):len()
    room:askForGuanxing(player, room:getNCards(n), nil, nil, "", false)
    if n > 1 then
      local targets = table.map(table.filter(room.alive_players, function(p)
        return #p.player_cards[Player.Equip] > 0 end), Util.IdMapper)
      if #targets > 0 then
        local to = room:askForChoosePlayers(player, targets, 1, 1, "#zhiren1-choose", self.name, true)
        if #to > 0 then
          to = room:getPlayerById(to[1])
          local id = room:askForCardChosen(player, to, "e", self.name)
          room:throwCard({id}, self.name, to, player)
          if player.dead then return false end
        end
      end
      targets = table.map(table.filter(room.alive_players, function(p)
        return #p.player_cards[Player.Judge] > 0 end), Util.IdMapper)
      if #targets > 0 then
        local to = room:askForChoosePlayers(player, targets, 1, 1, "#zhiren2-choose", self.name, true)
        if #to > 0 then
          to = room:getPlayerById(to[1])
          local id = room:askForCardChosen(player, to, "j", self.name)
          room:throwCard({id}, self.name, to, player)
          if player.dead then return false end
        end
      end
    end
    if n > 2 then
      if player:isWounded() then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name
        }
        if player.dead then return false end
      end
    end
    if n > 3 then
      room:drawCards(player, 3, self.name)
    end
  end,
}
local yaner = fk.CreateTriggerSkill{
  name = "yaner",
  anim_type = "support",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
      local current = player.room.current
      if current == player or current.dead or current.phase ~= Player.Play or not current:isKongcheng() then
        return false
      end
      for _, move in ipairs(data) do
        if move.from == current.id then
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
    return player.room:askForSkillInvoke(player, self.name, nil, "#yaner-invoke::"..player.room.current.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room.current
    room:doIndicate(player.id, {to.id})
    local cards = player:drawCards(2, self.name)
    if #cards == 2 and Fk:getCardById(cards[1]).type == Fk:getCardById(cards[2]).type then
      room:setPlayerMark(player, "@@yaner", 1)
    end
    if to.dead then return false end
    cards = to:drawCards(2, self.name)
    if not to.dead and to:isWounded()
    and #cards == 2 and Fk:getCardById(cards[1]).type == Fk:getCardById(cards[2]).type then
      room:recover{
        who = to,
        num = 1,
        recoverBy = player,
        skillName = self.name
      }
    end
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@yaner") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@yaner", 0)
  end,
}
panshu:addSkill(zhiren)
panshu:addSkill(yaner)
Fk:loadTranslationTable{
  ["ty__panshu"] = "潘淑",
  ["#ty__panshu"] = "神女",
  ["designer:ty__panshu"] = "韩旭",
  ["illustrator:ty__panshu"] = "杨杨和夏季",
  ["zhiren"] = "织纴",
  [":zhiren"] = "你的回合内，当你使用本回合的第一张非转化牌时，若X：不小于1，你观看牌堆顶X张牌并以任意顺序放回牌堆顶或牌堆底；"..
  "不小于2，你可以弃置场上一张装备牌和一张延时锦囊牌；不小于3，你回复1点体力；不小于4，你摸三张牌（X为此牌名称字数）。",
  ["yaner"] = "燕尔",
  [":yaner"] = "每回合限一次，当其他角色于其出牌阶段内失去最后的手牌后，你可以与其各摸两张牌，然后若因此摸到相同类型的两张牌的角色为："..
  "你，〖织纴〗改为回合外也可以发动直到你的下个回合开始；其，其回复1点体力。",
  ["#zhiren1-choose"] = "织纴：你可以弃置场上一张装备牌",
  ["#zhiren2-choose"] = "织纴：你可以弃置场上一张延时锦囊牌",
  ["#yaner-invoke"] = "燕尔：你可以与 %dest 各摸两张牌，若摸到的牌类型形同则获得额外效果",
  ["@@yaner"] = "燕尔",

  ["$zhiren1"] = "穿针引线，栩栩如生。",
  ["$zhiren2"] = "纺绩织纴，布帛可成。",
  ["$yaner1"] = "如胶似漆，白首相随。",
  ["$yaner2"] = "新婚燕尔，亲睦和美。",
  ["~ty__panshu"] = "有喜必忧，以为深戒！",
}

return extension
