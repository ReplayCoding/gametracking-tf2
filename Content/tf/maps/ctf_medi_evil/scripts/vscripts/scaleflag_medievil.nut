function DoScaleSmall()
{
    self.SetModelScale(0.85, 0);
    NetProps.SetPropFloat(self, "m_flModelScale", 0.85);
}

function DoScaleNormal()
{
    self.SetModelScale(0.95, 0);
    NetProps.SetPropFloat(self, "m_flModelScale", 0.95);
}

function OnPickup()
{
    DoScaleSmall();
}

function OnDropOrCapture()
{
    DoScaleNormal();
}

self.ConnectOutput("OnPickup", "OnPickup");
self.ConnectOutput("OnDrop", "OnDropOrCapture");
self.ConnectOutput("OnCapture", "OnDropOrCapture");
self.ConnectOutput("OnReturn", "OnDropOrCapture");

self.ConnectOutput("OnPickup1", "OnPickup");
self.ConnectOutput("OnDrop1", "OnDropOrCapture");
self.ConnectOutput("OnCapture1", "OnDropOrCapture");