/*
	ZSWin_Packet_WorldEventPacket.zs
	
	WorldEvent Packet

*/

class ZWorldEventPacket
{
    actor Thing;
    Line ActivatedLine;
    int ActivationType;
    bool ShouldActivate;

    ZWorldEventPacket Init(actor Thing, Line ActivatedLine, int ActivationType, bool ShouldActivate = true)
    {
        self.Thing = Thing;
        self.ActivatedLine = ActivatedLine;
        self.ActivationType = ActivationType;
        self.ShouldActivate = ShouldActivate;
        return self;
    }
}