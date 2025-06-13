version "4.6.0"

class JGP_RaiseEventHandler : EventHandler
{
    void ResurrectAllEnemies()
    {
        ThinkerIterator ti = ThinkerIterator.Create("Actor", Thinker.STAT_DEFAULT);
        actor mo;
        while (mo = Actor(ti.Next()))
        {
            if (mo.bISMONSTER && mo.health <= 0)
            {
                mo.RaiseActor(mo);
            }
        }
    }

    override void NetworkProcess(consoleEvent e)
    {
        if (e.name ~== "raiseallmonsters" && e.isManual)
        {
            ResurrectAllEnemies();
        }
    }
}