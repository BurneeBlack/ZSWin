/*

    ZSWin_Control_Timer.zs

    A timer control in the same vein
    as a Windows Forms Timer Control.

*/

class ZTimer : ZControl abstract
{
    int Ticks;
    private int currentTick;
    int GetCurrentTick() { return currentTick; }

    bool CountOnce;

    private bool ticked;

    override void Tick()
    {
        if (Enabled && currentTick > 0)
            currentTick--;
        else if (Enabled && currentTick == -1)
        {
            currentTick = Ticks;
            ticked = false;
        }
        else if (!ticked)
        {
            ticked = true;
            if (CountOnce)
                Enabled = false;
            currentTick = -1;
            ZNetCommand(string.Format("zevsys_TimerTickOutEvent,%s", Name), consoleplayer);
        }

        super.Tick();
    }

    virtual void TimerEvent() {}

    ZTimer Init(ZObjectBase ControlParent, bool Enabled, string Name, int PlayerClient, bool UiToggle, int Ticks = 0, bool CountOnce = true)
    {
        self.Ticks = Ticks;
        self.CountOnce = CountOnce;
        self.currentTick = -1;
        self.ticked = false;
        return ZTimer(super.Init(ControlParent, Enabled, true, Name, PlayerClient, UiToggle));
    }
}