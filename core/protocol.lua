--================================================--
-- Casino Royal
-- Version: 4.0.0
-- File: core/protocol.lua
-- Description: Shared network protocol definitions
--================================================--

local protocol = {}

--------------------------------------------------
-- Version
--------------------------------------------------

protocol.VERSION =
    "4.0.0"

--------------------------------------------------
-- Rednet
--------------------------------------------------

protocol.REDNET_PROTOCOL =
    "casino_royal"

protocol.SERVER_HOSTNAME =
    "casino_royal_server"

--------------------------------------------------
-- Machine Messages
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

protocol.WITHDRAW =
    "withdraw"

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
-- Generic Replies
--------------------------------------------------

protocol.SUCCESS =
    "success"

protocol.ERROR =
    "error"

return protocol
