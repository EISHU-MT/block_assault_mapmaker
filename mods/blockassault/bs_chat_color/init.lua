local c = core.colorize

function SendError(pobj, text)
	core.chat_send_player(Name(pobj), c("red", "[MapMaker Error] "..text))
end

function SendAnnouce(pobj, text)
	core.chat_send_player(Name(pobj), c("blue", "[MapMaker] "..text))
end

function SendWarning(pobj, text)
	core.chat_send_player(Name(pobj), c("yellow", "[MapMaker Warning] "..text))
end

function Send(pobj, text, color)
	core.chat_send_player(Name(pobj), c(color or "white", text))
end