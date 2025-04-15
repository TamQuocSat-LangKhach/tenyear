local extension = Package:new("tenyear_test")
extension.extensionName = "tenyear"

extension:loadSkillSkelsByPath("./packages/tenyear/pkg/tenyear_test/skills")

Fk:loadTranslationTable{
  ["tenyear_test"] = "十周年-测试服",
}

General:new(extension, "mu__caiyong", "qun", 3):addSkills { "jiaowei", "ty__feibai" }
Fk:loadTranslationTable{
  ["mu__caiyong"] = "乐蔡邕",
  ["#mu__caiyong"] = "焦尾识音",

  --["~mu__caiyong"] = "",
}

General:new(extension, "chezhou", "wei", 4).hidden = true
Fk:loadTranslationTable{
  ["chezhou"] = "车胄",
  ["#chezhou"] = "当车螳臂",

  ["tmp_illustrate"] = "看画",
  [":tmp_illustrate"] = "这个武将还没上线，你可以看看插画。不会出现在选将框。",

  ["shefuc"] = "慑伏",
  [":shefuc"] = "锁定技，你的牌造成的伤害、其他角色的牌对你造成的伤害均改为X。（X为此牌在手牌中的轮次数）",
  ["pigua"] = "披挂",
  [":pigua"] = "当你对其他角色造成伤害后，若伤害值大于1，你可以获得其至多X张牌（X为轮次数），这些牌于当前回合内不计入手牌上限。",

  --["~chezhou"] = "",
}

General:new(extension, "matie", "qun", 4):addSkills { "sp__zhuiji", "quxian" }
Fk:loadTranslationTable{
  ["matie"] = "马铁",
  ["#matie"] = "继志伏波",

  --["~matie"] = "",
}

General:new(extension, "hansong", "qun", 3):addSkills { "yinbi", "shuaiyan" }
Fk:loadTranslationTable{
  ["hansong"] = "韩嵩",
  ["#hansong"] = "楚国之望",

  --["~hansong"] = "",
}

--local zhurong = General:new(extension, "ty_sp__zhurong", "qun", 4, 4, General.Female)
--zhurong:addSkills { "manhou" }
--zhurong:addRelatedSkill("tanluan")
Fk:loadTranslationTable{
  ["ty_sp__zhurong"] = "祝融",
  ["#ty_sp__zhurong"] = "诗惹喜莫",

  --["~ty_sp__zhurong"] = "",
}

General:new(extension, "mu__zhugeguo", "shu", 3, 3, General.Female):addSkills { "xidi", "chengyan" }
Fk:loadTranslationTable{
  ["mu__zhugeguo"] = "乐诸葛果",
  --["#mu__zhugeguo"] = "",

  --["~mu__zhugeguo"] = "",
}

General:new(extension, "tystar__wenchou", "qun", 4):addSkills { "lianzhan", "weimingw" }
Fk:loadTranslationTable{
  ["tystar__wenchou"] = "星文丑",
  ["#tystar__wenchou"] = "夔威天下",

  --["~tystar__wenchou"] = "",
}

--General:new(extension, "wm__lukang", "wu", 4):addSkills { "shenduanl", "kegou", "dixian" }
Fk:loadTranslationTable{
  ["wm__lukang"] = "武陆抗",
  ["#wm__lukang"] = "桢武熙朝",

  --["~wm__lukang"] = "",

  ["shenduanl"] = "审断",
  [":shenduanl"] = "当你拼点时，可以弃置一张牌，改为用牌堆中点数最大的一张牌拼点。当一次拼点结算后，你与本次用K拼点的角色各摸一张牌堆中点数最小的牌，然后将赢的角色的拼点牌置于牌堆底。",
  ["kegou"] = "克构",
  [":kegou"] = "出牌阶段限一次，或你使用或打出过牌的其他角色的回合结束时，你可以与一名其他角色拼点，若你赢，你获得牌堆中最小的X个点数的的牌各一张（X为双方拼点牌点数之差，最多为3）；若你没赢，其视为对你使用一张【杀】，然后你可以继续重复此流程。",
  ["dixian"] = "砥贤",
  [":dixian"] = "限定技，出牌阶段，你可以选择一个点数。若牌堆中所有牌均不小于此点数，你摸此点数张牌，你本局游戏使用不大于此点数的牌无距离次数限制；若牌堆中有小于此点数的牌，你获得牌堆和弃牌堆中所有点数为K的牌。",
}

--General:new(extension, "zhanghuai", "wu", 3, 3, General.Female):addSkills { "laoyan", "jueyanz" }
Fk:loadTranslationTable{
  ["zhanghuai"] = "张怀",
  ["#zhanghuai"] = "连理分枝",

  --["~zhanghuai"] = "",

  ["laoyan"] = "劳燕",
  [":laoyan"] = "锁定技，其他角色使用牌指定包括你在内的多个目标后，此牌对其他目标无效，你从牌堆获得点数小于此牌的牌每个点数各一张，"..
  "当前回合结束时弃置这些牌。",
  ["jueyanz"] = "诀言",
  [":jueyanz"] = "当你使用仅指定唯一目标的手牌结算结束后（每回合每种类别限一次），你可以选择一项："..
  "1.摸1张牌；2.随机获得弃牌堆1张牌；3.与一名角色拼点，赢的角色对没赢的角色造成1点伤害。"..
  "然后，此次选择的选项的数值改为1，其他选项的数值均+1。",
}

General:new(extension, "tymou__xunyu", "wei", 3):addSkills { "bizuo", "shimou" }
Fk:loadTranslationTable{
  ["tymou__xunyu"] = "谋荀彧",
  --["#tymou__xunyu"] = "",

  --["~tymou__xunyu"] = "",
}

General:new(extension, "tymou__dongcheng", "qun", 4):addSkills { "baojia", "douwei" }
Fk:loadTranslationTable{
  ["tymou__dongcheng"] = "谋董承",
  --["#tymou__dongcheng"] = "",

  --["~tymou__dongcheng"] = "",
}

General:new(extension, "tymou__caohong", "wei", 4):addSkills { "ty__yingjia", "xianju" }
Fk:loadTranslationTable{
  ["tymou__caohong"] = "谋曹洪",
  --["#tymou__caohong"] = "",

  --["~tymou__caohong"] = "",
}

return extension
