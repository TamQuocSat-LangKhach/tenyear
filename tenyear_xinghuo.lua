local extension = Package("tenyear_xinghuo")
extension.extensionName = "tenyear"

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
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
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
    return target == player and player:hasSkill(self.name) and player.room:getCardArea(data.card) == Card.Processing and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return (#p.player_cards[Player.Hand] > #player.player_cards[Player.Hand] or p.hp > player.hp) end), function(p) return p.id end)
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#xunxian-choose:::"..data.card:toLogString(), self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(self.cost_data, data.card, true, fk.ReasonGive)
  end,
}
yanjun:addSkill(guanchao)
yanjun:addSkill(xunxian)
Fk:loadTranslationTable{
  ["yanjun"] = "严畯",
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
  ["~yanjun"] = "著作，还，没完成。",
}

Fk:loadTranslationTable{
  ["duji"] = "杜畿",
  ["andong"] = "安东",
  [":andong"] = "当你受到其他角色造成的伤害时，你可令伤害来源选择一项：1.防止此伤害，本回合弃牌阶段红桃牌不计入手牌上限；"..
  "2.观看其手牌，若其中有红桃牌则你获得这些红桃牌。",
  ["yingshi"] = "应势",
  [":yingshi"] = "出牌阶段开始时，若没有武将牌旁有“酬”的角色，你可将所有红桃牌置于一名其他角色的武将牌旁，称为“酬”。"..
  "若如此做，当一名角色使用【杀】对武将牌旁有“酬”的角色造成伤害后，其可以获得一张“酬”。当武将牌旁有“酬”的角色死亡时，你获得所有“酬”。",

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
    return target == player and player:hasSkill(self.name) and data.card.type ~= Card.TypeEquip and data.firstTarget and
      not table.find(player:getCardIds(Player.Hand), function(id) return Fk:getCardById(id).type == Card.TypeBasic end) and
      #AimGroup:getAllTargets(data.tos) > 0
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(#AimGroup:getAllTargets(data.tos), self.name)
  end,
}
local limu_targetmod = fk.CreateTargetModSkill{
  name = "#limu_targetmod",
  residue_func = function(self, player, skill)
    return player:hasSkill(self.name) and #player:getCardIds(Player.Judge) > 0 and 999 or 0
  end,
  distance_limit_func = function(self, player, skill)
    return player:hasSkill(self.name) and #player:getCardIds(Player.Judge) > 0 and 999 or 0
  end,
}
local limu = fk.CreateActiveSkill{
  name = "limu",
  anim_type = "control",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player) return not player:hasDelayedTrick("indulgence") end,
  target_filter = function() return false end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).suit == Card.Diamond
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
limu:addRelatedSkill(limu_targetmod)
liuyan:addSkill(tushe)
liuyan:addSkill(limu)
Fk:loadTranslationTable{
  ["liuyan"] = "刘焉",
  ["tushe"] = "图射",
  [":tushe"] = "当你使用非装备牌指定目标后，若你没有基本牌，则你可以摸X张牌（X为此牌指定的目标数）。",
  ["limu"] = "立牧",
  [":limu"] = "出牌阶段，你可以将一张方块牌当【乐不思蜀】对自己使用，然后回复1点体力；你的判定区有牌时，你使用牌没有次数和距离限制。",

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
    if player:hasSkill(self.name) and target.phase == Player.Play and target.tag[self.name] and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and not player:isNude() then
      local tag = target.tag[self.name]
      return #tag > 1 and table.every(tag, function (suit) return suit == tag[1] end) and not table.contains(tag, Card.NoSuit)
    end
  end,
  on_cost = function(self, event, target, player, data)
    return #player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#guanwei-invoke::"..target.id) > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(target, "guanwei-turn", 1)
  end,

  refresh_events = {fk.AfterCardUseDeclared, fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    if event == fk.AfterCardUseDeclared then
      return player:hasSkill(self.name, true) and target.phase == Player.Play
    else
      return target == player and data.from == Player.Play
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.AfterCardUseDeclared then
      target.tag[self.name] = target.tag[self.name] or {}
      table.insert(target.tag[self.name], data.card.suit)
    else
      if player:getMark("guanwei-turn") > 0 then
        player.room:setPlayerMark(player, "guanwei-turn", 0)
        player:drawCards(2, self.name)
        player:gainAnExtraPhase(Player.Play)
      end
      player.tag[self.name] = {}
    end
  end,
}
local gongqing = fk.CreateTriggerSkill{
  name = "gongqing",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and data.from then
      return (data.from:getAttackRange() < 3 and data.damage > 1) or data.from:getAttackRange() > 3
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.from:getAttackRange() < 3 then
      data.damage = 1
      room:broadcastSkillInvoke(self.name, 1)
      room:notifySkillInvoked(player, self.name, "defensive")
    elseif data.from:getAttackRange() > 3 then
      data.damage = data.damage + 1
      room:broadcastSkillInvoke(self.name, 2)
      room:notifySkillInvoked(player, self.name, "negative")
    end
  end,
}
panjun:addSkill(guanwei)
panjun:addSkill(gongqing)
Fk:loadTranslationTable{
  ["panjun"] = "潘濬",
  ["guanwei"] = "观微",
  [":guanwei"] = "一名角色的出牌阶段结束时，若其于此回合内使用过的牌数大于1，且其于此回合内使用过的牌花色均相同，且你于此回合未发动过此技能，"..
  "你可弃置一张牌。若如此做，其摸两张牌，然后其获得一个额外的出牌阶段。",
  ["gongqing"] = "公清",
  [":gongqing"] = "锁定技，当你受到伤害时，若伤害来源攻击范围小于3，则你只受到1点伤害；若伤害来源攻击范围大于3，则此伤害+1。",
  ["#guanwei-invoke"] = "观微：你可以弃置一张牌，令 %dest 摸两张牌并执行一个额外的出牌阶段",

  ["$guanwei1"] = "今日宴请诸位，有要事相商。",
  ["$guanwei2"] = "天下未定，请主公以大局为重。",
  ["$gongqing1"] = "尔辈何故与降虏交善。",
  ["$gongqing2"] = "豪将在外，增兵必成祸患啊！",
  ["~panjun"] = "耻失荆州，耻失荆州啊！",
}

Fk:loadTranslationTable{
  ["ty__wangcan"] = "王粲",
  ["sanwen"] = "散文",
  [":sanwen"] = "每回合限一次，当你获得牌时，若你手中有与这些牌牌名相同的牌，你可以展示之，并弃置获得的同名牌，然后摸弃牌数两倍数量的牌。",
  ["qiai"] = "七哀",
  [":qiai"] = "限定技，当你进入濒死状态时，你可令其他每名角色交给你一张牌。",
  ["denglou"] = "登楼",
  [":denglou"] = "限定技，结束阶段开始时，若你没有手牌，你可以观看牌堆顶的四张牌，然后获得其中的非基本牌，并使用其中的基本牌（不能使用则弃置）。",

  ["$sanwen1"] = "文若春华，思若泉涌。",
  ["$sanwen2"] = "独步汉南，散文天下。",
  ["$qiai1"] = "未知身死处，何能两相完？",
  ["$qiai2"] = "悟彼下泉人，喟然伤心肝。",
  ["$denglou1"] = "登兹楼以四望兮，聊暇日以销忧。",
  ["$denglou2"] = "惟日月之逾迈兮，俟河清其未极。",
  ["~ty__wangcan"] = "一作驴鸣悲，万古送葬别。",
}

Fk:loadTranslationTable{
  ["sp__pangtong"] = "庞统",
  ["guolun"] = "过论",
  [":guolun"] = "出牌阶段限一次，你可展示一名其他角色的一张手牌。然后你可选择你的一张牌。若其选择的牌点数小，你与其交换这两张牌，其摸一张牌；"..
  "若你选择的牌点数小，你与其交换这两张牌，你摸一张牌。",
  ["songsang"] = "送丧",
  [":songsang"] = "限定技，当其他角色死亡时，若你已受伤，你可回复1点体力；若你未受伤，你可加1点体力上限。若如此做，你获得〖展骥〗。",
  ["zhanji"] = "展骥",
  [":zhanji"] = "锁定技，当你于出牌阶段内因摸牌且并非因发动此技能而得到牌时，你摸一张牌。",

  ["$guolun1"] = "品过是非，讨评好坏。",
  ["$guolun2"] = "若有天下太平时，必讨四海之内才。",
  ["$songsang1"] = "送丧至东吴，使命已完。",
  ["$songsang2"] = "送丧虽至，吾与孝则得相交。",
  ["$zhanji1"] = "公瑾安全至吴，心安之。",
  ["$zhanji2"] = "功曹之恩，吾必有展骥之机。",  
  ["~sp__pangtong"] = "我终究……不得东吴赏识。",
}

Fk:loadTranslationTable{
  ["sp__taishici"] = "太史慈",
  ["jixu"] = "击虚",
  [":jixu"] = "出牌阶段限一次，你可令体力值相同的至少一名其他角色各猜测你的手牌区里是否有【杀】。系统公布这些角色各自的选择和猜测结果。"..
  "若你的手牌区里：有【杀】，当你于此阶段内使用【杀】选择目标后，你令所有选择“否”的角色也成为此【杀】的目标；没有【杀】，你弃置所有选择“是”的角色的各一张牌。"..
  "你摸X张牌（X为猜错的角色数）。若没有猜错的角色，你结束此阶段。",
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
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), function(p)
      return p.id end), 1, 1, "#sp__youdi-choose", self.name, true)
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
    if player:hasSkill(self.name) then
      if event == fk.CardUseFinished then
        return target == player and data.card.type == Card.TypeEquip
      else
        local equipnum = #player.player_cards[Player.Equip]
        for _, move in ipairs(data) do
          for _, info in ipairs(move.moveInfo) do
            if move.from == player.id and info.fromArea == Card.PlayerEquip then
              equipnum = equipnum + 1
            elseif move.to == player.id and move.toArea == Card.PlayerEquip then
              equipnum = equipnum - 1
            end
          end
        end
        return #player.player_cards[Player.Equip] ~= equipnum and #player.player_cards[Player.Equip] == player.hp and player:isWounded()
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.CardUseFinished then
      local room = player.room
      local card = Fk:cloneCard("slash")
      local targets = table.map(
        table.filter(room:getOtherPlayers(player), function(p)
          return (not player:isProhibited(p, card)) and player:inMyAttackRange(p)  --FIXME: 改为使用viewasskill
        end), function(p) return p.id end )
      if #targets == 0 then return false end
      local target = room:askForChoosePlayers(player, targets, 1, 1, "#qinguo-ask", self.name, true)
      if #target > 0 then
        self.cost_data = target[1]
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastSkillInvoke(self.name)
    if event == fk.CardUseFinished then
      room:notifySkillInvoked(player, self.name, "offensive")
      room:useVirtualCard("slash", nil, player, player.room:getPlayerById(self.cost_data), self.name, true)
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
lvdai:addSkill(qinguo)
Fk:loadTranslationTable{
  ["lvdai"] = "吕岱",
  ["qinguo"] = "勤国",
  [":qinguo"] = "当你于回合内使用装备牌结算结束后，你可视为使用一张不计入次数限制的【杀】；当你的装备区里的牌数变化后，"..
  "若你装备区里的牌数与你的体力值相等，你回复1点体力。",
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
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and to_select ~= Self.id and target:getMark("kannan-phase") == 0 and not target:isKongcheng()
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
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + player:getMark("@kannan")
    player.room:setPlayerMark(player, "@kannan", 0)
  end,
}
kannan:addRelatedSkill(kannan_record)
liuyao:addSkill(kannan)
Fk:loadTranslationTable{
  ["liuyao"] = "刘繇",
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
    return target == player and player:hasSkill(self.name) and data.from and not data.from.dead and data.from ~= player
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(data.from, "@@weilu", 1)
  end,
  refresh_events = {fk.EventPhaseStart},
  can_refresh = function(self, event, target, player, data)
    local room = player.room
    if target == player and player:hasSkill(self.name) then
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
  target_num = 1,
  min_card_num = 1,
  can_use = function(self, player)
    return #player.player_cards[Player.Equip] > 0
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
    target:addToPile(self.name, cards, false, self.name)
  end,
}
local zengdao_trig = fk.CreateTriggerSkill{
  name = "#zengdao_trig",
  refresh_events = {fk.DamageCaused},
  can_refresh = function(self, event, target, player, data)
    return target == player and #player:getPile("zengdao") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askForCard(player, 1, 1, false, "zengdao", true, ".|.|.|zengdao|.|.|.", "#zengdao-invoke", "zengdao")
    if #cards == 0 then cards = {player:getPile("zengdao")[math.random(1, #player:getPile("zengdao"))]} end
    player:removeCards(Player.Special, cards, "zengdao")
    data.damage = data.damage + 1
  end
}
zengdao:addRelatedSkill(zengdao_trig)
lvqian:addSkill(weilu)
lvqian:addSkill(zengdao)
Fk:loadTranslationTable{
  ["lvqian"] = "吕虔",
  ["weilu"] = "威虏",
  [":weilu"] = "锁定技，当你受到其他角色造成的伤害后，伤害来源在你的下回合出牌阶段开始时失去体力至1，回合结束时其回复以此法失去的体力值。",
  ["zengdao"] = "赠刀",
  [":zengdao"] = "限定技，出牌阶段，你可以将装备区内任意数量的牌置于一名其他角色的武将牌旁，该角色造成伤害时，移去一张“赠刀”牌，然后此伤害+1。",
  ["@@weilu"] = "威虏",
  ["#zengdao-invoke"] = "赠刀：你需移去一张“赠刀”牌（点“取消”则随机移去一张）",

  ["$weilu1"] = "贼人势大，需从长计议。",
  ["$weilu2"] = "时机未到，先行撤退。",
  ["$zengdao1"] = "有功赏之，有过罚之。",
  ["$zengdao2"] = "治军之道，功过分明。",
  ["~lvqian"] = "我自泰山郡以来，百姓获安，镇军伐贼，此生已无憾！",
}
Fk:loadTranslationTable{
  ["zhangliang"] = "张梁",
  ["jijun"] = "集军",
  [":jijun"] = "当武器牌或不为装备牌的牌于你的出牌阶段内指定第一个目标后，若此牌的使用者为你且你是此牌的目标之一，你可判定。"..
  "当此次判定的判定牌移至弃牌堆后，你可将此判定牌置于武将牌上（称为“方”）。",
  [":fangtong"] = "结束阶段开始时，若有“方”，你可弃置一张牌，若如此做，你将至少一张“方”置入弃牌堆。"..
  "若此牌与你以此法置入弃牌堆的所有“方”的点数之和为36，你对一名其他角色造成3点雷电伤害。",

  ["$jijun1"] = "集民力万千，亦可为军！",
  ["$jijun2"] = "集万千义军，定天下大局！",
  ["$fangtong1"] = "统领方队，为民意所举！",
  ["$fangtong2"] = "三十六方，必为大统！",
  ["~zhangliang"] = "人公也难逃被人所杀……",
}

return extension
