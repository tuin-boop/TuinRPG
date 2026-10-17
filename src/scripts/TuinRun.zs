// The run token travels with the player; normal games never receive its rules.
class TuinRun : Object play
{
    bool Bootstrapping, ResolvingReplacement, EndScreenShown;
    int StartSettleTicks;
    bool FreshCampaignStart;
    clearscope static int StartRequest()
    { return TuinRPGHandler.CVInt('tuin_run_request',0); }
    clearscope static bool Active()
    { return !TuinRPGHandler.ClassesEnabled() && !netgame && (StartRequest()!=0?StartRequest()==1:TuinRPGHandler.CVInt('tuin_run_active',0)!=0); }
    clearscope static int Stage()
    { return Active() && StartRequest()==0?max(0,TuinRPGHandler.CVInt('tuin_run_stage',0)):0; }
    void Loaded(WorldEvent e)
    {
        if(e.IsSaveGame){CVar.FindCVar('tuin_run_request').SetInt(0);return;}
        FreshCampaignStart=StartRequest()==2;
        if(StartRequest()==0)return;
        bool run=StartRequest()==1;
        // Server CVars are queued: do not apply the previous run's death flag
        // to the fresh pawn while the new-game transaction is settling.
        StartSettleTicks=3;
        CVar.FindCVar('tuin_run_active').SetBool(run);
        CVar.FindCVar('tuin_run_pending').SetBool(run);
        CVar.FindCVar('tuin_run_ended').SetBool(false);
        CVar.FindCVar('tuin_run_stage').SetInt(0);
        CVar.FindCVar('tuin_run_request').SetInt(0);
        EndScreenShown=false;Bootstrapping=false;
    }
    static int RarityForRoll(int stage,double roll)
    {
        double mythic=min(35.,2.+stage*.8);
        double legendary=min(25.,4.+stage*.6);
        double elite=min(20.,8.+stage*.4);
        double rare=min(20.,12.+stage*.3);
        double uncommon=min(20.,18.+stage*.2);
        if(roll<mythic)return 5;roll-=mythic;
        if(roll<legendary)return 4;roll-=legendary;
        if(roll<elite)return 3;roll-=elite;
        if(roll<rare)return 2;roll-=rare;
        return roll<uncommon?1:0;
    }
    String PickMap(TuinPlayerData data,bool first=false)
    {
        Array<int> maps;
        for(int pass=0;pass<2;pass++)
        {
            for(int i=1;i<=29;i++)
            {
                String name=String.Format("MAP%02d",i);
                if(!LevelInfo.MapExists(name) || (!first && name~==level.MapName)) continue;
                if(pass==0 && (data.RunVisited&(1<<(i-1))))continue;
                maps.Push(i);
            }
            if(maps.Size()>0) break;
            data.RunVisited=0;
        }
        if(maps.Size()==0) return "";
        int chosen=maps[Random[TuinRunMap](0,maps.Size()-1)];
        data.RunVisited|=1<<(chosen-1);
        return String.Format("MAP%02d",chosen);
    }
    static int MonsterPool(class<Actor> type)
    {
        if(type=='ZombieMan' || type=='ShotgunGuy' || type=='ChaingunGuy')return 1;
        if(type=='Demon' || type=='Spectre')return 2;
        if(type=='Cacodemon' || type=='PainElemental')return 3;
        return 0;
    }
    void Replace(ReplaceEvent e)
    {
        if(!Active() || level.time>1 || ResolvingReplacement || e.IsFinal)return;
        int pool=MonsterPool(e.Replacee);
        if(pool==0)return;
        class<Actor> choices[3];
        int count;
        if(pool==1) {choices[0]='ZombieMan';choices[1]='ShotgunGuy';choices[2]='ChaingunGuy';count=3;}
        else if(pool==2) {choices[0]='Demon';choices[1]='Spectre';count=2;}
        else {choices[0]='Cacodemon';choices[1]='PainElemental';count=2;}
        class<Actor> pick=choices[Random[TuinRunRoster](0,count-1)];
        ResolvingReplacement=true;
        class<Actor> replacement=Actor.GetReplacement(pick);
        class<Actor> original=Actor.GetReplacement(e.Replacee);
        ResolvingReplacement=false;
        if(!replacement || !original)return;
        let from=GetDefaultByType(original);let to=GetDefaultByType(replacement);
        if(!from || !to || from.bBOSS || from.bBOSSDEATH || to.bBOSS || to.bBOSSDEATH ||
            to.Radius>from.Radius || to.Height>from.Height || from.bFLOAT!=to.bFLOAT)return;
        e.Replacement=replacement;e.IsFinal=true;
    }
    void GiveLoadout(TuinRPGHandler h,Actor pawn,TuinPlayerData d)
    {
        class<Weapon> bases[9]={'Pistol','Shotgun','SuperShotgun','Chaingun','RocketLauncher','PlasmaRifle','BFG9000','ID24Incinerator','ID24CalamityBlade'};
        Array<class<Weapon> > pool;
        for(int i=0;i<9;i++)
        {
            if(i>=7 && !TuinRustSupport.Available(i+2)) continue;
            class<Weapon> type=(class<Weapon>)(Actor.GetReplacement(bases[i]));
            if(!type || GetDefaultByType(type).bPowered_Up)continue;
            bool duplicate=false;for(int j=0;j<pool.Size();j++)if(pool[j]==type)duplicate=true;
            if(!duplicate)pool.Push(type);
        }
        d.ClearWeaponVariants();
        // Keep fists as a fallback, but do not add a fourth starting firearm.
        for(Inventory item=pawn.Inv;item;)
        {
            Inventory next=item.Inv;
            if(item is 'Weapon' && !(item is 'Fist'))item.Destroy();
            item=next;
        }
        for(int n=0;n<3 && pool.Size()>0;n++)
        {
            int index=Random[TuinRunLoot](0,pool.Size()-1);
            class<Weapon> type=pool[index];pool.Delete(index);
            let weapon=Weapon(pawn.GiveInventoryType(type));
            if(!weapon)continue;
            let roll=TuinWeaponDrop(Actor.Spawn('TuinWeaponDrop',pawn.Pos,NO_REPLACE));
            if(!roll)continue;
            roll.VariantID=++h.NextLootID;
            int quality=Random[TuinRunLoot](0,99)<20?6:5;
            // RollWeaponAffixes uses the weapon family for compatible traits.
            roll.WeaponType=type;
            h.RollWeaponAffixes(roll,1,quality);
            d.AddWeaponVariant(roll.VariantID,type,1,quality,roll.AffixFlags,roll.HastePercent,
                roll.PowerPercent,roll.LeechPercent,roll.ExecutionPercent,roll.ProsperityPercent);
            d.EquipWeaponVariant(roll.VariantID);
            if(weapon.Ammo1)weapon.Ammo1.Amount=weapon.Ammo1.MaxAmount;
            if(weapon.Ammo2)weapon.Ammo2.Amount=weapon.Ammo2.MaxAmount;
            if(n==0)players[pawn.PlayerNumber()].PendingWeapon=weapon;
            roll.Destroy();
        }
        h.ApplyAmmoCapacity(pawn,d);
        for(Inventory ammo=pawn.Inv;ammo;ammo=ammo.Inv)
            if(ammo is 'Ammo')ammo.Amount=ammo.MaxAmount;
        d.RunLoadoutGiven=true;
    }
    bool Tick(TuinRPGHandler h)
    {
        // Menu requests belong to the new world, never the dying world's token.
        if(StartRequest()!=0)return true;
        if(StartSettleTicks>0){StartSettleTicks--;return true;}
        if(!Active())return false;
        Actor pawn=players[consoleplayer].mo;
        if(!pawn)return false;
        let d=h.EnsurePlayerData(consoleplayer);if(!d)return false;
        if(d.RunActive && TuinRPGHandler.CVInt('tuin_run_ended',0) && !TuinRPGHandler.CVInt('tuin_run_pending',0))
        {
            d.RunActive=true;d.RunEnded=true;d.Lives=0;d.LifeRevivePending=false;
            if(pawn.Health>0)pawn.A_Die();
            if(!EndScreenShown)
            {
                EndScreenShown=true;
                EventHandler.SendInterfaceEvent(consoleplayer,"tuin_run_finished");
            }
            return true;
        }
        if(TuinRPGHandler.CVInt('tuin_run_pending',0))
        {
            CVar.FindCVar('tuin_run_pending').SetBool(false);
            CVar.FindCVar('tuin_run_ended').SetBool(false);
            d.RunActive=true;d.RunID=Random[TuinRunID](1,2147480000);
            d.RunStages=0;d.RunScore=0;d.RunTicks=0;d.RunVisited=0;d.RunEnded=false;
            d.RunLoadoutGiven=false;d.RunNextMap="";d.RunClearTics=0;
            d.Lives=1;d.LivesInitialized=true;d.LifeRevivePending=false;
            d.SuppressNextMapCatchup=true;
            String first=PickMap(d,true);
            if(first.Length()==0)
            {
                pawn.A_Log("HELL'S GAMBIT NEEDS MAP01-MAP29 MAPS.");
                CVar.FindCVar('tuin_run_active').SetBool(false);d.RunActive=false;return false;
            }
            Bootstrapping=true;
            level.ChangeLevel(first,0,CHANGELEVEL_NOINTERMISSION,3);
            return true;
        }
        if(!d.RunActive)return false;
        if(d.RunEnded) return false;
        if(pawn.Health<=0) { Finish(d);return false; }
        if(!d.RunLoadoutGiven)GiveLoadout(h,pawn,d);
        if(d.RunClearTics>0)d.RunClearTics--;
        d.Lives=1;d.RunTicks++;
        if(d.RunNextMap.Length()==0)d.RunNextMap=PickMap(d);
        if(d.RunNextMap.Length()>0) {level.NextMap=d.RunNextMap;level.NextSecretMap=d.RunNextMap;}
        return false;
    }
    void Unloaded(WorldEvent e)
    {
        if(StartRequest()!=0 || !Active() || Bootstrapping || e.NextMap.Length()==0)return;
        let d=TuinRPGHandler.GetPlayerData(players[consoleplayer].mo);
        if(!d || !d.RunActive || d.RunEnded || !d.RunLoadoutGiven)return;
        d.RunStages++;d.RunScore+=1000;d.RunNextMap="";
        d.RunClearTics=245;
        d.SuppressNextMapCatchup=true;
        CVar.FindCVar('tuin_run_stage').SetInt(d.RunStages);
    }
    void Finish(TuinPlayerData d)
    {
        if(StartRequest()!=0 || !d || !d.RunActive || d.RunEnded)return;
        d.RunEnded=true;d.Lives=0;d.LifeRevivePending=false;
        CVar.FindCVar('tuin_run_ended').SetBool(true);
        EndScreenShown=true;
        EventHandler.SendInterfaceEvent(consoleplayer,"tuin_run_score",d.RunScore,d.RunStages,d.RunID);
    }
    ui static void SaveScore(int score,int stages,int id)
    {
        let cv=CVar.FindCVar('tuin_run_scores');
        Array<String> entries;cv.GetString().Split(entries,";");
        Array<int> scores,levels,ids;
        for(int i=0;i<entries.Size();i++)
        {
            Array<String> fields;entries[i].Split(fields,",");
            if(fields.Size()!=3)continue;
            int oldid=fields[2].ToInt();
            if(oldid==id)return;
            scores.Push(fields[0].ToInt());levels.Push(fields[1].ToInt());ids.Push(oldid);
        }
        scores.Push(max(0,score));levels.Push(max(0,stages));ids.Push(id);
        for(int i=1;i<scores.Size();i++)for(int j=i;j>0 && scores[j]>scores[j-1];j--)
        {
            int tmp=scores[j];scores[j]=scores[j-1];scores[j-1]=tmp;
            tmp=levels[j];levels[j]=levels[j-1];levels[j-1]=tmp;
            tmp=ids[j];ids[j]=ids[j-1];ids[j-1]=tmp;
        }
        String result="";
        for(int i=0;i<min(10,scores.Size());i++)
            result.AppendFormat("%s%d,%d,%d",i?";":"",scores[i],levels[i],ids[i]);
        cv.SetString(result);
    }
}
// Patch the existing entry instead of redefining a mod's menu descriptor.
class TuinRunMenuRouter : StaticEventHandler
{
    ui bool Routed;
    override void UiTick()
    {
        if(Routed)return;
        let desc=ListMenuDescriptor(MenuDescriptor.GetDescriptor('MainMenu'));
        if(!desc)return;
        Route(desc);
        Route(ListMenuDescriptor(MenuDescriptor.GetDescriptor('MainMenuTextOnly')));
        Routed=true;
    }
    ui void Route(ListMenuDescriptor desc)
    {
        if(!desc)return;
        for(int i=0;i<desc.mItems.Size();i++)
        {
            let item=desc.mItems[i];
            Name target=item.GetAction();
            if(target=='PlayerclassMenu' || target=='EpisodeMenu' || target=='SkillMenu')
                MenuItemBase(item).Init(item.GetX(),item.GetY(),'TuinRunStart');
        }
    }
}
class TuinRunScoresMenu : TuinRunMenu
{
    override void Init(Menu parent,OptionMenuDescriptor desc)
    {Super.Init(parent,desc);Scores=true;}
}

class TuinRunMenu : OptionMenu
{
    int Selected;
    bool Scores;
    bool Episodes;
    int SelectedEpisode;
    String Notice;
    double OpenMS,FrameMS,Focus[3];
    override void Init(Menu parent,OptionMenuDescriptor desc)
    {Super.Init(parent,desc);DontDim=true;DontBlur=true;OpenMS=FrameMS=MSTimeF();}
    void Choose()
    {
        if(Scores){Scores=false;return;}
        if(Selected==2){Scores=true;return;}
        if(netgame){Notice="START A SINGLE-PLAYER GAME FIRST";return;}
        bool run=Selected==1;
        if(!run && !Episodes && AllEpisodes.Size()>1)
        {Episodes=true;SelectedEpisode=0;return;}
        CVar.FindCVar('tuin_run_request').SetInt(run?1:2);
        int difficulty=run?2:1;
        CVar.FindCVar('tuin_difficulty').SetInt(difficulty);
        TuinRPGOptionsMenu.ApplyVisibleProfile(difficulty);
        TuinRPGOptionsMenu.MarkProfileApplied(difficulty);
        if(run)
        {
            CVar.FindCVar('tuin_enabled').SetBool(true);
        }
        Menu.StartGameDirect(false,false,null,Episodes?SelectedEpisode:0,3);
    }
    override bool MenuEvent(int key,bool fromcontroller)
    {
        if(Episodes)
        {
            if(key==MKEY_Back){Episodes=false;return true;}
            if(key==MKEY_Up || key==MKEY_Down)
            {SelectedEpisode=(SelectedEpisode+int(AllEpisodes.Size())+(key==MKEY_Up?-1:1))%int(AllEpisodes.Size());return true;}
            if(key==MKEY_Enter){Choose();return true;}
            return Super.MenuEvent(key,fromcontroller);
        }
        if(key==MKEY_Back && Scores){Scores=false;return true;}
        if(key==MKEY_Up || key==MKEY_Down){Selected=(Selected+3+(key==MKEY_Up?-1:1))%3;return true;}
        if(key==MKEY_Enter){Choose();return true;}
        return Super.MenuEvent(key,fromcontroller);
    }
    override bool OnUIEvent(UiEvent ev)
    {
        if(ev.Type==UiEvent.Type_LButtonDown)
        {
            if(Scores){Scores=false;return true;}
            double w=Screen.GetWidth(),h=Screen.GetHeight();
            if(Episodes)
            {
                double step=h*min(.11,.46/max(1,int(AllEpisodes.Size())));
                int episode=int((ev.MouseY-h*.30)/step);
                if(ev.MouseX>=w*.21 && ev.MouseX<=w*.79 && ev.MouseY>=h*.30 && episode>=0 && episode<int(AllEpisodes.Size()))
                {SelectedEpisode=episode;Choose();}
                return true;
            }
            int hit=int((ev.MouseY-h*.30)/(h*.13));
            if(ev.MouseX>=w*.21 && ev.MouseX<=w*.79 && ev.MouseY>=h*.30 && hit>=0 && hit<3)
            {Selected=hit;Choose();}
            return true;
        }
        return Super.OnUIEvent(ev);
    }
    override void Drawer()
    {
        double w=Screen.GetWidth(),h=Screen.GetHeight(),s=min(w/1100.,h/750.);
        double now=MSTimeF(),t=(now-OpenMS)/1000.,dt=clamp((now-FrameMS)/1000.,0.,.1);
        FrameMS=now;
        double remaining=1-clamp(t/.5,0.,1.);
        double enter=1-remaining*remaining*remaining;
        Font f=Font.GetFont('TinyBaby');
        Screen.Dim(Color(3,10,20),.97*enter,int(w*.17),int(h*.15),int(w*.66),int(h*.72));
        Screen.DrawLineFrame(Color(36,128,210),w*.17,h*.15,w*.66,h*.72,max(1,int(s)));
        for(int spark=0;spark<28;spark++)
        {
            double sx=w*(.18+.64*((spark*37%101)/101.));
            double sy=h*(.85-((t*.025+spark*.037)% .68));
            Screen.Dim(Color(75,160+spark%70,255),(.15+.18*sin(t*90+spark*53))*enter,int(sx+sin(t*45+spark*33)*7*s),int(sy),max(1,int(2*s)),max(1,int(3*s)));
        }
        TuinRunArt.Title(Episodes?"CHOOSE YOUR EPISODE":Scores?"THE FALLEN / HIGH SCORES":"CHOOSE YOUR FATE",Font.CR_RED,w*.21+(1-enter)*35*s,h*.205,2.2*s,-4,enter,t);
        if(Episodes)
        {
            double step=h*min(.11,.46/max(1,int(AllEpisodes.Size())));
            for(int i=0;i<int(AllEpisodes.Size());i++)
            {
                double y=h*.30+i*step;
                Screen.Dim(i==SelectedEpisode?Color(22,57,85):Color(8,25,42),enter,int(w*.21),int(y),int(w*.58),int(step*.9));
                String title=Stringtable.Localize(AllEpisodes[i].mEpisodeName);
                if(title.Length()==0)title=AllEpisodes[i].mEpisodeMap;
                Screen.DrawText(SmallFont,i==SelectedEpisode?Font.CR_GOLD:Font.CR_WHITE,w*.23,y+step*.22,title,DTA_ScaleX,s,DTA_ScaleY,s,DTA_Alpha,enter);
            }
            Screen.DrawText(f,Font.CR_TAN,w*.21,h*.80,"ULTRA-VIOLENCE / ENTER OR CLICK: START / ESC: BACK",DTA_ScaleX,s,DTA_ScaleY,s);
            return;
        }
        if(Scores)
        {
            Array<String> entries;CVar.FindCVar('tuin_run_scores').GetString().Split(entries,";");
            int row=0;
            for(int i=0;i<entries.Size() && row<10;i++)
            {
                Array<String> fields;entries[i].Split(fields,",");if(fields.Size()!=3)continue;
                Screen.DrawText(f,Font.CR_WHITE,w*.21,h*(.29+row*.042),
                    String.Format("%d.   %s POINTS    %s MAPS CLEARED",row+1,fields[0],fields[1]),DTA_ScaleX,1.8*s,DTA_ScaleY,1.8*s);
                row++;
            }
            if(row==0)Screen.DrawText(f,Font.CR_GRAY,w*.21,h*.35,"NO FINISHED RUNS YET",DTA_ScaleX,s,DTA_ScaleY,s);
            Screen.DrawText(f,Font.CR_TAN,w*.21,h*.80,"ESC / CLICK: BACK",DTA_ScaleX,1.4*s,DTA_ScaleY,1.4*s);return;
        }
        for(int i=0;i<3;i++)
        {
            double y=h*(.30+i*.13);
            Focus[i]+=((i==Selected?1.:0.)-Focus[i])*(1-exp(-12*dt));
            double glow=Focus[i];
            Screen.Dim(Color(8+int(14*glow),25+int(32*glow),42+int(43*glow)),enter,int(w*.21),int(y),int(w*.58),int(h*.11));
            Screen.DrawLineFrame(Color(26+int(49*glow),68+int(122*glow),105+int(150*glow)),w*.21,y,w*.58,h*.11,max(1,int(s)));
            Screen.Dim(Color(75,190,255),(.3+.65*glow)*enter,int(w*.21),int(y),max(2,int(3*s)),int(h*.11));
            String title=i==0?"TUINRPG":i==1?"HELL'S GAMBIT":"HIGH SCORES";
            String detail=i==0?"NORMAL CAMPAIGN / ULTRA-VIOLENCE":i==1?
                "RANDOM MAPS / HARD RPG / ONE LIFE / 3 MYTHIC+ WEAPONS":"YOUR TOP 10 FINISHED RUNS";
            TuinRunArt.Title(title,i==Selected?Font.CR_GOLD:Font.CR_RED,w*.23+glow*8*s,y+16*s,1.8*s,-2-2*glow,enter,t);
            Screen.DrawText(f,Font.CR_TAN,w*.23,y+48*s,detail,DTA_ScaleX,1.35*s,DTA_ScaleY,1.35*s,DTA_Alpha,enter);
        }
        Screen.DrawText(f,Font.CR_TAN,w*.21,h*.75,"ONE LIFE. NO MERCY. MAKE HELL REMEMBER.",DTA_ScaleX,1.5*s,DTA_ScaleY,1.5*s);
        Screen.DrawText(f,Font.CR_GRAY,w*.21,h*.82,"GAMBIT: LOADED MAP01-MAP29 / 1000 POINTS PER CLEAR",DTA_ScaleX,s,DTA_ScaleY,s);
        Screen.DrawText(f,Font.CR_RED,w*.21,h*.79,Notice,DTA_ScaleX,s,DTA_ScaleY,s);
    }
}

// STCFN/SmallFont is the same block lettering used by the Interpolated effect.
class TuinRunArt : Object ui
{
    static void Title(String text,int ink,double x,double y,double scale,double angle,double alpha,double clock)
    {
        let transform=new('Shape2DTransform');
        transform.From2D(cos(angle),-sin(angle),sin(angle),cos(angle),x,y);
        Screen.SetTransform(transform);
        Screen.DrawText(SmallFont,Font.CR_BLACK,2*scale,2*scale,text,DTA_ScaleX,scale,DTA_ScaleY,scale,DTA_Alpha,alpha);
        Screen.DrawText(SmallFont,ink,0,0,text,DTA_ScaleX,scale,DTA_ScaleY,scale,DTA_Alpha,alpha);
        // Moving bright glyph accent, without burying the readable letter face.
        double off=0;
        for(int i=0;i<text.Length();i++)
        {
            String ch=text.Mid(i,1);
            double shine=max(0.,sin(clock*110-i*24));
            if(shine>.8)Screen.DrawText(SmallFont,Font.CR_ORANGE,off,0,ch,DTA_ScaleX,scale,DTA_ScaleY,scale,DTA_Alpha,alpha*(shine-.8)*2);
            off+=SmallFont.StringWidth(ch)*scale;
        }
        Screen.ClearTransform();
    }
    static void ClearPopup(int score,int cleared,double age,bool report=false)
    {
        double w=Screen.GetWidth(),h=Screen.GetHeight(),s=min(w/1100.,h/750.);
        double remaining=1-clamp(age/.55,0.,1.);
        double entry=1-remaining*remaining*remaining;
        double fade=report?1:clamp((7-age),0.,1.);
        double alpha=entry*fade;
        if(alpha<=0)return;
        double x=w*(report?.24:.48)+(1-entry)*55*s+(1-fade)*35*s,y=h*(report?.33:.23);
        double width=w*(report?.52:.48);
        Screen.Dim(Color(3,10,20),alpha*.94,int(x-15*s),int(y-20*s),int(width),int(205*s));
        Screen.DrawLineFrame(Color(36,128,210),x-15*s,y-20*s,width,205*s,max(1,int(s)));
        Title("HELL DEMANDS MORE",Font.CR_RED,x,y,1.75*s,-5,alpha,age);
        Font f=Font.GetFont('TinyBaby');
        String lines[5];
        lines[0]=String.Format("STAGE %d CLEARED / +1000 POINTS",cleared);
        lines[1]=String.Format("RUN SCORE %d / NEXT STAGE %d",int(score*entry),cleared+1);
        double hp=100*((1+cleared*.08)/(1+max(0,cleared-1)*.08)-1);
        double dmg=100*((1+cleared*.04)/(1+max(0,cleared-1)*.04)-1);
        lines[2]=String.Format("NEXT: HEALTH x%.2f / DAMAGE x%.2f",1+cleared*.08,1+cleared*.04);
        lines[3]=String.Format("+%.1f%% HP / +%.1f%% DAMAGE / MORE RARE FOES",hp,dmg);
        lines[4]="DIRECTOR BASE LEVEL +2 / RARITY ODDS RISE";
        for(int i=0;i<5;i++)Screen.DrawText(f,i<2?Font.CR_GOLD:Font.CR_TAN,x,y+(38+i*25)*s,lines[i],DTA_ScaleX,1.5*s,DTA_ScaleY,1.5*s,DTA_Alpha,alpha);
    }
}
