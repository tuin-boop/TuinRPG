// Map-local, serialized director state. Reinforcements never advance kill checkpoints.
class TuinAmmoWaves : Object play
{
    int Baseline,Checkpoint,Wave,WaveCount,Owner,StartAt,Attempts;
    bool Spawning;
    Array<int> Pending,PendingOwners;
    Array<Actor> Members;
    Vector3 Trail[64];
    int TrailOwner[64],TrailCount,TrailHead;

    static bool Reached(int checkpoint,int killed,int total)
    {
        if(total<=0 || checkpoint<0 || checkpoint>=3)return false;
        int thresholds[3]={25,50,75};
        return killed*100>=total*thresholds[checkpoint];
    }

    static int FullPools(Actor pawn)
    {
        if(!pawn)return 0;
        Array<Inventory> counted;
        for(Inventory item=pawn.Inv;item;item=item.Inv)
        {
            let weapon=Weapon(item);
            if(!weapon || weapon.Amount<=0)continue;
            for(int slot=0;slot<2;slot++)
            {
                class<Ammo> kind=slot?weapon.AmmoType2:weapon.AmmoType1;
                if(!kind)continue;
                let ammo=pawn.FindInventory(kind);
                if(!ammo || ammo.MaxAmount<=0 || ammo.Amount<ammo.MaxAmount)continue;
                bool duplicate=false;
                for(int i=0;i<int(counted.Size());i++)if(counted[i]==ammo)duplicate=true;
                if(!duplicate)counted.Push(ammo);
            }
        }
        return min(5,int(counted.Size()));
    }
    void Announce(TuinRPGHandler h)
    {
        h.WaveBannerStart=h.NextBannerSlot();
        h.WaveBannerDetail=String.Format("WAVE %d / %d - CLEAR THE WAVE TO ADVANCE",Wave,WaveCount);
        StartAt=max(level.time+105,h.WaveBannerStart+105);
        Attempts=0;Spawning=true;Members.Clear();
    }
    bool SpawnMember(TuinRPGHandler h,Actor pawn)
    {
        if(TrailCount==0)return false;
        int index=Random[TuinAmmoWave](0,TrailCount-1);
        if(TrailOwner[index]!=Owner)return false;
        Vector3 pos=Trail[index];
        double angle=Random[TuinAmmoWave](0,359),radius=Random[TuinAmmoWave](0,96);
        pos.X+=cos(angle)*radius;pos.Y+=sin(angle)*radius;
        class<Actor> kinds[6]={'ZombieMan','ShotgunGuy','DoomImp','Demon','Spectre','Cacodemon'};
        Actor monster=Actor.Spawn(kinds[Random[TuinAmmoWave](0,5)],pos,ALLOW_REPLACE);
        if(!monster)return false;
        monster.ClearCounters();
        monster.SetOrigin((monster.Pos.X,monster.Pos.Y,monster.FloorZ),false);
        bool safe=monster.bISMONSTER && !monster.bFRIENDLY && monster.Health>0 &&
            monster.TestMobjLocation() && abs(monster.Pos.Z-pos.Z)<64 &&
            pawn.Distance3D(monster)<=1200 && pawn.CheckSight(monster);
        for(int p=0;p<8;p++)if(playerInGame[p] && players[p].mo && players[p].mo.Distance3D(monster)<256)safe=false;
        if(!safe){monster.Destroy();return false;}
        if(!h.GetMonsterData(monster))h.InitializeMonster(monster);
        monster.bDORMANT=false;monster.bAMBUSH=false;monster.Target=pawn;
        if(monster.SeeState)monster.SetState(monster.SeeState);
        Actor.Spawn('TeleportFog',monster.Pos,ALLOW_REPLACE);
        Members.Push(monster);
        return true;
    }
    void Tick(TuinRPGHandler h)
    {
        if(!h.CVInt('tuin_director_enabled',1))return;
        if(level.time<10)return;
        if(Baseline==0)
        {
            Baseline=level.total_monsters;
            // Loading a pre-feature save must not replay already-passed milestones.
            if(level.time>35 && Baseline>0)
            {
                while(Reached(Checkpoint,level.killed_monsters,Baseline))Checkpoint++;
            }
        }
        if(level.time%35==0)
            for(int p=0;p<8;p++)if(playerInGame[p] && players[p].mo && players[p].mo.Health>0)
            {
                // Standing still must not erase all the useful places behind you.
                int previous=(TrailHead+63)%64;
                if(TrailCount>0 && TrailOwner[previous]==p && (players[p].mo.Pos-Trail[previous]).Length()<96)continue;
                Trail[TrailHead]=players[p].mo.Pos;TrailOwner[TrailHead]=p;
                TrailHead=(TrailHead+1)%64;TrailCount=min(64,TrailCount+1);
            }
        while(Reached(Checkpoint,level.killed_monsters,Baseline))
        {
            Checkpoint++;
            int full=0,owner=0;
            for(int p=0;p<8;p++)if(playerInGame[p] && players[p].mo && players[p].mo.Health>0)
            {
                int pools=FullPools(players[p].mo);
                if(pools>full){full=pools;owner=p;}
            }
            if(full>0){Pending.Push(full);PendingOwners.Push(owner);}
        }
        if(WaveCount==0)
        {
            if(Pending.Size()==0)return;
            WaveCount=Pending[0];Owner=PendingOwners[0];Pending.Delete(0);PendingOwners.Delete(0);
            Wave=1;Announce(h);return;
        }
        Actor pawn=playerInGame[Owner]?players[Owner].mo:null;
        if(!pawn || pawn.Health<=0)return;
        if(level.time<StartAt)return;
        if(Spawning)
        {
            // Bounded work per tick; never force a spawn into a blocked room.
            for(int n=0;n<4 && Members.Size()<10 && Attempts<160;n++)
            {Attempts++;SpawnMember(h,pawn);}
            if(Members.Size()<10 && Attempts<160)return;
            Spawning=false;
            if(Members.Size()==0){WaveCount=0;return;}
        }
        for(int i=0;i<int(Members.Size());i++)if(Members[i] && Members[i].Health>0)return;
        if(Wave>=WaveCount){WaveCount=0;Members.Clear();return;}
        Wave++;Announce(h);
    }
}
