--================================================--
-- Casino Royal
-- Version: 4.1.0
-- File: core/protocol.lua
-- Description: Shared network protocol definitions
--================================================--

local protocol = {}

--------------------------------------------------
-- Version
--------------------------------------------------

protocol.VERSION =
    "4.1.0"

--------------------------------------------------
-- Rednet
--------------------------------------------------

protocol.REDNET_PROTOCOL =
    "casino_royal"

protocol.SERVER_HOSTNAME =
    "casino_royal_server"

--------------------------------------------------
-- Machine messages
--------------------------------------------------

protocol.REGISTER =
    "register"

protocol.REGISTER_ACK =
    "register_ack"

protocol.HEARTBEAT =
    "heartbeat"

protocol.HEARTBEAT_ACK =
    "heartbeat_ack"

--------------------------------------------------
-- Connectivity
--------------------------------------------------

protocol.PING =
    "ping"

protocol.PONG =
    "pong"

--------------------------------------------------
-- Player
--------------------------------------------------

protocol.LOGIN =
    "login"

protocol.LOGIN_ACK =
    "login_ack"

protocol.LOGOUT =
    "logout"

protocol.LOGOUT_ACK =
    "logout_ack"

--------------------------------------------------
-- Bank
--------------------------------------------------

protocol.BALANCE =
    "balance"

protocol.BALANCE_REPLY =
    "balance_reply"

protocol.DEPOSIT =
    "deposit"

protocol.DEPOSIT_REPLY =
    "deposit_reply"

protocol.WITHDRAW =
    "withdraw"

protocol.WITHDRAW_REPLY =
    "withdraw_reply"

protocol.ACCOUNT =
    "account"

protocol.ACCOUNT_REPLY =
    "account_reply"

protocol.RECORD_GAME =
    "record_game"

protocol.RECORD_GAME_REPLY =
    "record_game_reply"

--------------------------------------------------
-- Transactions
--------------------------------------------------

protocol.BET =
    "bet"

protocol.PAYOUT =
    "payout"

protocol.TRANSACTION =
    "transaction"

--------------------------------------------------
-- Admin
--------------------------------------------------

protocol.MACHINE_LIST =
    "machine_list"

protocol.STATISTICS =
    "statistics"

protocol.RESTART =
    "restart"

protocol.SHUTDOWN =
    "shutdown"

--------------------------------------------------
-- Status
--------------------------------------------------

protocol.STATUS_IDLE =
    "idle"

protocol.STATUS_BUSY =
    "busy"

protocol.STATUS_OFFLINE =
    "offline"

--------------------------------------------------
-- Generic results
--------------------------------------------------

protocol.SUCCESS =
    "success"

protocol.ERROR =
    "error"

--------------------------------------------------
-- Return module
--------------------------------------------------

return protocol
