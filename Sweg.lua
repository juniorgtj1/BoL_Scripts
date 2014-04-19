function OnLoad()
	_HANDLER = {}
	_HANDLER.LaughBot = _LaughBot()
	
	PrintChat('<b><font color="#CCCCCC">Sweg by PQ loaded</b></font>')
end

class('_LaughBot') -- Credits to Honda7 for the packet

	function _LaughBot:__init()
		AddRecvPacketCallback(function(p) self:OnRecvPacket(p) end)
		AddSendPacketCallback(function(p) self:OnSendPacket(p) end)
	end

	function _LaughBot:OnSendPacket(p)
		if p.header == Packet.headers.S_MOVE and (_LAST == nil or os.clock() - _LAST > 1) then
			_LAST = os.clock()
			self:SendLaughPacket()
		end
	end

	function _LaughBot:OnRecvPacket(p)
		if p.header == 65 then
			p.pos = 1

			if p:DecodeF() == myHero.networkID then
				p:Replace1(255,5)
			end
		end
	end

	function _LaughBot:SendLaughPacket()
		 local p = CLoLPacket(71)
		 p.pos = 1
		 p:EncodeF(myHero.networkID)
		 p:Encode1(2)
		 p:Encode1(0)
		 SendPacket(p)
	end