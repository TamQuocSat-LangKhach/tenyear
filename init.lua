local tenyear_xinghuo = require "packages/tenyear/tenyear_xinghuo"
local tenyear_sp1 = require "packages/tenyear/tenyear_sp1"
local tenyear_sp2 = require "packages/tenyear/tenyear_sp2"
local tenyear_sp3 = require "packages/tenyear/tenyear_sp3"
local tenyear_sp4 = require "packages/tenyear/tenyear_sp4"
local tenyear_activity = require "packages/tenyear/tenyear_activity"
local tenyear_liezhuan = require "packages/tenyear/tenyear_liezhuan"
local tenyear_huicui1 = require "packages/tenyear/tenyear_huicui1"
local tenyear_huicui2 = require "packages/tenyear/tenyear_huicui2"
local tenyear_huicui3 = require "packages/tenyear/tenyear_huicui3"
local tenyear_star = require "packages/tenyear/tenyear_star"
local tenyear_mou = require "packages/tenyear/tenyear_mou"
local tenyear_wei = require "packages/tenyear/tenyear_wei"
local tenyear_yj = require "packages/tenyear/tenyear_yj"
local tenyear_other = require "packages/tenyear/tenyear_other"
local tenyear_test = require "packages/tenyear/tenyear_test"
local tenyear_ex = require "packages/tenyear/tenyear_ex"
local tenyear_exxinghuo = require "packages/tenyear/tenyear_exxinghuo"
local tenyear_token = require "packages/tenyear/tenyear_token"

Fk:loadTranslationTable{ ["tenyear"] = "十周年" }
Fk:loadTranslationTable(require 'packages/tenyear/i18n/en_US', 'en_US')

return {
  tenyear_xinghuo,
  tenyear_sp1,
  tenyear_sp2,
  tenyear_sp3,
  tenyear_sp4,
  tenyear_activity,
  tenyear_liezhuan,
  tenyear_huicui1,
  tenyear_huicui2,
  tenyear_huicui3,
  tenyear_star,
  tenyear_mou,
  tenyear_wei,
  tenyear_yj,
  tenyear_other,
  tenyear_test,
  tenyear_ex,
  tenyear_exxinghuo,
  tenyear_token,
}
