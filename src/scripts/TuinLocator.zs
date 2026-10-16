// Opt-in single-player debugging aid. No map discovery or inventory is changed.
class TuinLocatorPoint : Object
{
    Vector3 Pos;
    int LineIndex;
}
class TuinLocatorHandler : EventHandler
{
    bool Unlocked;
    bool TrackConnections;
    Array<bool> ActivatedLines;
    bool LineHistoryInitialized, PartialLineHistory;
    void RecordActivatedLine(Line ln)
    {
        if(!ln) return;
        if(ActivatedLines.Size()<level.Lines.Size()) ActivatedLines.Resize(level.Lines.Size());
        ActivatedLines[ln.Index()]=true;
        if(Category==8) Scan();
    }
    bool UnusedTrigger(Line ln)
    {
        if(ln.special==0 || !(ln.activation & SPAC_PlayerActivate)) return false;
        return ln.Index()>=ActivatedLines.Size() || !ActivatedLines[ln.Index()];
    }
    clearscope static bool TrackingCategory(int category)
    { return category>=0 && category<=8 && category!=7; }
    int Category, TargetIndex;
    Array<TuinLocatorPoint> Targets;
    Array<TuinLocatorPoint> Connections;
    int AimedLine;
    String ConnectionInfo;
    bool SectorAction(Line ln)
    {
        return ln.special==Door_Open || ln.special==Door_Close || ln.special==Door_Raise ||
            ln.special==Door_LockedRaise || ln.special==Generic_Door ||
            ln.special==Floor_LowerToLowest || ln.special==Floor_RaiseToNearest ||
            ln.special==Floor_RaiseByValue || ln.special==Floor_LowerByValue ||
            ln.special==Generic_Floor || ln.special==Generic_Ceiling ||
            ln.special==Plat_DownWaitUpStay || ln.special==Generic_Lift ||
            ln.special==Stairs_BuildUp || ln.special==Generic_Stairs;
    }
    void AddConnection(Vector3 pos)
    {
        for(int i=0;i<Connections.Size();i++) if((Connections[i].Pos-pos).Length()<32) return;
        let point=new('TuinLocatorPoint');point.Pos=pos;Connections.Push(point);
    }
    void InspectLine()
    {
        Connections.Clear(); AimedLine=-1; ConnectionInfo="";
        Actor pawn=players[consoleplayer].mo;
        if(!pawn) return;
        FLineTraceData trace;
        pawn.LineTrace(pawn.Angle,2048,pawn.Pitch,0,pawn.player.ViewHeight-pawn.Height*.5,0,0,trace);
        Line hit=trace.HitLine;
        if(!hit) return;
        ResolveConnections(hit);
    }
    void ResolveConnections(Line hit)
    {
        Connections.Clear();
        if(!hit) {AimedLine=-1;return;}
        AimedLine=hit.Index();
        if(SectorAction(hit))
        {
            int tag=hit.args[0];
            if(tag>0)
            {
                let it=level.CreateSectorTagIterator(tag);
                int index;
                while((index=it.Next())>=0)
                {
                    let sec=level.Sectors[index];
                    AddConnection((sec.centerspot.x,sec.centerspot.y,sec.floorplane.ZatPoint(sec.centerspot)+40));
                }
            }
            else if(hit.backsector)
            {
                let sec=hit.backsector;
                AddConnection((sec.centerspot.x,sec.centerspot.y,sec.floorplane.ZatPoint(sec.centerspot)+40));
            }
        }
        // Reverse lookup: switches affecting either side of the aimed wall.
        foreach(ln:level.Lines)
        {
            if(ln==hit || !SectorAction(ln) || ln.args[0]<=0) continue;
            bool matches=false;
            for(int side=0;side<2;side++)
            {
                let sec=side==0?hit.frontsector:hit.backsector;
                if(!sec) continue;
                for(int t=0;t<sec.CountTags();t++) if(sec.GetTag(t)==ln.args[0]) matches=true;
            }
            if(matches)
            {
                Vector2 mid=(ln.v1.p+ln.v2.p)*.5;
                AddConnection((mid.x,mid.y,ln.frontsector.floorplane.ZatPoint(mid)+40));
            }
        }
        ConnectionInfo=String.Format("LINE %d / %d LINKED TARGETS",AimedLine,Connections.Size());
        if(Connections.Size()==0) ConnectionInfo="NO DIRECT TAG LINK / SCRIPTED LINKS MAY BE HIDDEN";
    }
    void AddTarget(Vector3 pos,int lineIndex=-1)
    {
        let point=new('TuinLocatorPoint'); point.Pos=pos; point.LineIndex=lineIndex; Targets.Push(point);
    }

    clearscope static TuinLocatorHandler Get()
    {
        let rpg=TuinRPGHandler(EventHandler.Find('TuinRPGHandler'));
        return rpg ? rpg.Locator : null;
    }

    clearscope static String Label(int category)
    {
        switch(category)
        {
        case 0: return "RED KEYS"; case 1: return "BLUE KEYS";
        case 2: return "YELLOW KEYS"; case 3: return "RED DOORS";
        case 4: return "BLUE DOORS"; case 5: return "YELLOW DOORS";
        case 6: return "SECRETS"; case 8: return "UNUSED TRIGGERS"; default: return "STOP TRACKING";
        }
    }
    clearscope static int Ink(int category)
    { return category==6?Font.CR_PURPLE:category%3==0?Font.CR_RED:category%3==1?Font.CR_LIGHTBLUE:Font.CR_GOLD; }
    clearscope static Color Tint(int category)
    { return category==6?Color(195,100,255):category%3==0?Color(255,80,70):category%3==1?Color(65,185,255):Color(255,220,70); }

    clearscope static bool MatchesLock(int number,int col)
    { return number==col+1 || number==col+4 || number==col+129 || number==col+132 ||
        number==100 || number==101 || number==228 || number==229; }

    void Scan()
    {
        Targets.Clear();
        if(!Unlocked || netgame || !TrackingCategory(Category)) return;
        if(Category<3)
        {
            let it=ThinkerIterator.Create('Key');
            Key key;
            while((key=Key(it.Next())))
            {
                if(key.Owner || !key.bSPECIAL) continue;
                bool match=Category==0?(key is 'RedCard' || key is 'RedSkull'):
                    Category==1?(key is 'BlueCard' || key is 'BlueSkull'):
                    (key is 'YellowCard' || key is 'YellowSkull');
                if(match) AddTarget(key.Pos+(0,0,16));
            }
        }
        else if(Category<6)
        {
            foreach(ln:level.Lines)
            {
                int lock=ln.locknumber;
                // Classic Doom maps are translated to argument-based specials;
                // their UDMF locknumber remains zero.
                if(lock==0 && ln.special==Door_LockedRaise) lock=ln.args[3];
                if(lock==0 && (ln.special==Generic_Door || ln.special==ACS_LockedExecute ||
                    ln.special==ACS_LockedExecuteDoor)) lock=ln.args[4];
                if(!MatchesLock(lock,Category-3)) continue;
                Vector2 mid=(ln.v1.p+ln.v2.p)*.5;
                Vector3 pos=(mid.x,mid.y,ln.frontsector.floorplane.ZatPoint(mid)+40);
                // Opposite faces of a normal door should be a single target.
                bool duplicate=false;
                for(int j=0;j<Targets.Size();j++) if((Targets[j].Pos-pos).Length()<64) duplicate=true;
                if(!duplicate) AddTarget(pos);
            }
        }
        else if(Category==6)
        {
            foreach(sec:level.Sectors)
                if(sec.isSecret())
                    AddTarget((sec.centerspot.x,sec.centerspot.y,sec.floorplane.ZatPoint(sec.centerspot)+24));
        }
        else if(Category==8)
        {
            foreach(ln:level.Lines)
            {
                if(!UnusedTrigger(ln)) continue;
                Vector2 mid=(ln.v1.p+ln.v2.p)*.5;
                AddTarget((mid.x,mid.y,ln.frontsector.floorplane.ZatPoint(mid)+32),ln.Index());
            }
        }
        TargetIndex=Targets.Size()>0?TargetIndex%Targets.Size():0;
    }
    void Loaded(WorldEvent e)
    {
        if(!e.IsSaveGame) { ActivatedLines.Clear(); PartialLineHistory=false; }
        else if(!LineHistoryInitialized) PartialLineHistory=true;
        LineHistoryInitialized=true;
        if(!e.IsSaveGame) { Category=-1; TargetIndex=0; Targets.Clear(); }
        else Scan();
    }
    void TickLocator()
    {
        if(netgame) { Unlocked=false; Targets.Clear(); return; }
        if(Unlocked && TrackConnections && level.time%4==0) InspectLine();
        if(Unlocked && level.time%18==0) Scan();
    }
    void ProcessRequest(String request,int argument,int pnum)
    {
        if(netgame || TuinRPGHandler.ClassesEnabled() || pnum!=consoleplayer) return;
        if(request=="tuin_locator_enable")
        {
            // Password unlock is an enable operation, never a toggle.
            Unlocked=true;
            return;
        }
        if(request=="tuin_locator_cheat")
        {
            Unlocked=!Unlocked; Category=-1; Targets.Clear();
            Console.Printf(Unlocked?"Locator cheat ENABLED. Open the locator menu to choose or cycle targets.":"Locator cheat DISABLED.");
            return;
        }
        if(request!="tuin_locator_menu" && request!="tuin_locator_next" && request!="tuin_locator_select" &&
            request!="tuin_locator_links") return;
        if(!Unlocked) { Console.Printf("Locator locked: cheat required."); return; }
        if(request=="tuin_locator_links")
        {
            TrackConnections=!TrackConnections;
            Connections.Clear(); AimedLine=-1; ConnectionInfo="";
            return;
        }
        if(request=="tuin_locator_menu") EventHandler.SendInterfaceEvent(pnum,"tuin_locator_open");
        else if(request=="tuin_locator_select")
        {
            if(argument<0 || argument>8) return;
            if(argument==7)
            {
                TrackConnections=false;
                Connections.Clear(); AimedLine=-1; ConnectionInfo="";
            }
            // Re-selecting the current tracker is also a next-target action.
            if(Category==argument && TrackingCategory(argument))
            {
                CycleTarget(1);
                return;
            }
            TargetIndex=0;
            Category=argument; Scan();
        }
        else CycleTarget(argument<0?-1:1);
    }
    void CycleTarget(int direction)
    {
        if(!TrackingCategory(Category)) return;
        Scan();
        if(Targets.Size()>0) TargetIndex=(TargetIndex+Targets.Size()+(direction<0?-1:1))%Targets.Size();
    }
    ui void HandleInterface(ConsoleEvent e)
    {
        if(e.Name=="tuin_locator_open" && Unlocked && !netgame) Menu.SetMenu('TuinRPGLocator');
    }
    ui void DrawLocator(RenderEvent e)
    {
        if(Unlocked && TrackConnections && !netgame && !menuactive) DrawConnections(e);
        if(!Unlocked || netgame || menuactive || !TrackingCategory(Category) || !players[consoleplayer].mo) return;
        double w=Screen.GetWidth(),h=Screen.GetHeight(),s=min(w/1100.,h/750.);
        Font f=Font.GetFont('TinyBaby');
        double x=w*.60,y=h*.63;
        Screen.Dim(Color(4,12,23),.85,int(x-12*s),int(y-12*s),int(310*s),int(76*s));
        Screen.DrawText(f,Ink(Category),x,y,Label(Category),DTA_ScaleX,1.5*s,DTA_ScaleY,1.5*s);
        if(Targets.Size()==0)
        {
            Screen.DrawText(f,Font.CR_WHITE,x,y+23*s,"NO REMAINING TARGETS",DTA_ScaleX,s,DTA_ScaleY,s);
            return;
        }
        Vector3 pos=Targets[TargetIndex].Pos;
        double distance=(pos-players[consoleplayer].mo.Pos).Length();
        String targetInfo=Category==8?
            String.Format("%d/%d  LINE %d  %d U",TargetIndex+1,Targets.Size(),Targets[TargetIndex].LineIndex,int(distance)):
            String.Format("%d / %d    %d MAP UNITS",TargetIndex+1,Targets.Size(),int(distance));
        Screen.DrawText(f,Font.CR_WHITE,x,y+23*s,targetInfo,DTA_ScaleX,s,DTA_ScaleY,s);
        Screen.DrawText(f,Font.CR_GRAY,x,y+43*s,Category==8 && PartialLineHistory?
            "OLD SAVE: PRIOR REPEAT USE UNKNOWN":"DIRECT BEARING / O: LOCATOR MENU",DTA_ScaleX,s,DTA_ScaleY,s);
        Vector2 end;
        bool visible;
        [visible,end]=TuinRPGHandler.ProjectOverheadPoint(pos,e.ViewPos,e.ViewAngle,e.ViewPitch,players[consoleplayer].FOV,int(w),int(h));
        if(!visible)
        {
            Vector3 delta=pos-e.ViewPos;
            double bearing=atan2(delta.y,delta.x)-e.ViewAngle;
            end=(w*.5-sin(bearing)*w*.40,h*.45-cos(bearing)*h*.32);
        }
        end.x=clamp(end.x,w*.08,w*.92); end.y=clamp(end.y,h*.12,h*.79);
        Vector2 start=(w*.5,h*.58);
        Color tint=Tint(Category);
        double clock=MSTimeF()/1000.;
        Screen.DrawThickLine(start.x,start.y,end.x,end.y,4*s,Color(12,30,44));
        for(int i=0;i<24;i++)
        {
            double t=(i/24.+clock*.25)%1.;
            Vector2 a=start+(end-start)*t;
            Vector2 b=start+(end-start)*min(1.,t+.018);
            Screen.DrawThickLine(a.x,a.y,b.x,b.y,2*s,tint);
        }
        double radius=(9+2*sin(clock*180))*s;
        for(int k=0;k<4;k++)
        {
            double a=k*90+clock*35;
            Screen.DrawThickLine(end.x+cos(a)*radius,end.y+sin(a)*radius,
                end.x+cos(a+90)*radius,end.y+sin(a+90)*radius,2*s,tint);
        }
    }
    ui void DrawConnections(RenderEvent e)
    {
        if(AimedLine<0) return;
        double w=Screen.GetWidth(),h=Screen.GetHeight(),s=min(w/1100.,h/750.);
        Font f=Font.GetFont('TinyBaby');
        Screen.Dim(Color(3,14,23),.8,int(w*.32),int(h*.72),int(w*.55),int(40*s));
        Screen.DrawText(f,Font.CR_CYAN,w*.33,h*.72+10*s,ConnectionInfo,DTA_ScaleX,s,DTA_ScaleY,s);
        for(int i=0;i<min(Connections.Size(),16);i++)
        {
            Vector2 end;bool visible;
            [visible,end]=TuinRPGHandler.ProjectOverheadPoint(Connections[i].Pos,e.ViewPos,e.ViewAngle,e.ViewPitch,players[consoleplayer].FOV,int(w),int(h));
            if(!visible)
            {
                Vector3 d=Connections[i].Pos-e.ViewPos;
                double a=atan2(d.y,d.x)-e.ViewAngle;
                end=(w*.5-sin(a)*w*.40,h*.45-cos(a)*h*.32);
            }
            end.x=clamp(end.x,w*.08,w*.92);end.y=clamp(end.y,h*.12,h*.68);
            for(int j=0;j<16;j++)
            {
                double t=(j/16.+MSTimeF()/4000.)%1.;
                Vector2 a=(w*.5,h*.5)+(end-(w*.5,h*.5))*t;
                Vector2 b=(w*.5,h*.5)+(end-(w*.5,h*.5))*min(1.,t+.025);
                Screen.DrawThickLine(a.x,a.y,b.x,b.y,2*s,Color(80,240,220));
            }
            Screen.DrawText(f,Font.CR_CYAN,end.x,end.y,String.Format("LINK %d / %d U",i+1,int((Connections[i].Pos-e.ViewPos).Length())),DTA_ScaleX,s,DTA_ScaleY,s);
        }
    }
}

// Shared compact card layout for the cheat locator and the main RPG hub.
class TuinLocatorMenu : OptionMenu
{
    int Selected;
    double OpenMS;
    virtual bool Hub() { return false; }
    override void Init(Menu parent,OptionMenuDescriptor desc)
    { Super.Init(parent,desc); DontDim=true; DontBlur=true; OpenMS=MSTimeF(); }
    bool Allowed()
    {
        let handler=TuinLocatorHandler.Get();
        return Hub() || (handler && handler.Unlocked && !netgame);
    }
    int Count() { return Hub()?8:12; }
    String Card(int i)
    {
        if(!Hub())
        {
            if(i==11) return TuinLocatorHandler.Label(8);
            if(i==10)
            {
                let handler=TuinLocatorHandler.Get();
                return handler && handler.TrackConnections?"SWITCH LINKS: ON":"SWITCH LINKS: OFF";
            }
            return i==8?"NEXT TARGET":i==9?"PREVIOUS TARGET":TuinLocatorHandler.Label(i);
        }
        switch(i) {
        case 0:return "CHARACTER"; case 1:return "ARSENAL"; case 2:return "WEAPON PERKS";
        case 3:return "HUD / MINIMAP"; case 4:return "SETTINGS"; case 5:return "HELP / GUIDE";
        case 6:return "NEW GAME / MODES"; default:return "GAMBIT HIGH SCORES";
        }
    }
    int Hit(double x,double y)
    {
        double w=Screen.GetWidth(),h=Screen.GetHeight();
        for(int i=0;i<Count();i++)
        {
            double step=Hub()?.115:.075;
            double left=w*.19+(i%2)*w*.32,top=h*.27+(i/2)*h*step;
            if(x>=left && x<left+w*.30 && y>=top && y<top+h*(step-.02)) return i;
        }
        return -1;
    }
    void Choose()
    {
        if(!Allowed()) return;
        if(!Hub())
        {
            if(Selected==11) EventHandler.SendNetworkEvent("tuin_locator_select",8);
            else if(Selected==10) EventHandler.SendNetworkEvent("tuin_locator_links");
            else if(Selected>=8) EventHandler.SendNetworkEvent("tuin_locator_next",Selected==9?-1:1);
            else EventHandler.SendNetworkEvent("tuin_locator_select",Selected);
            Close(); return;
        }
        switch(Selected) {
        case 0:Menu.SetMenu('TuinRPGCharacter');break;
        case 1:Menu.SetMenu('TuinRPGArsenal');break;
        case 2:Menu.SetMenu('TuinRPGWeaponPerks');break;
        case 3:Menu.SetMenu('TuinRPGDisplayOptions');break;
        case 4:Menu.SetMenu('TuinRPGDifficulty');break;
        case 5:Menu.SetMenu('TuinRPGHelp');break;
        case 6:Menu.SetMenu('TuinRunStart');break;
        case 7:Menu.SetMenu('TuinRunScores');break;
        }
    }
    override bool OnUIEvent(UiEvent ev)
    {
        if(ev.Type==UiEvent.Type_MouseMove || ev.Type==UiEvent.Type_LButtonDown)
        {
            int hit=Hit(ev.MouseX,ev.MouseY);
            if(hit>=0) Selected=hit;
            if(hit>=0 && ev.Type==UiEvent.Type_LButtonDown) Choose();
            return true;
        }
        return Super.OnUIEvent(ev);
    }
    override bool MenuEvent(int mkey,bool fromcontroller)
    {
        if(mkey==MKEY_Enter) {Choose();return true;}
        if(mkey==MKEY_Left || mkey==MKEY_Right || mkey==MKEY_Up || mkey==MKEY_Down)
        {
            Selected=(Selected+Count()+(mkey==MKEY_Left?-1:mkey==MKEY_Right?1:mkey==MKEY_Up?-2:2))%Count();
            return true;
        }
        return Super.MenuEvent(mkey,fromcontroller);
    }
    override void Drawer()
    {
        double w=Screen.GetWidth(),h=Screen.GetHeight(),s=min(w/1100.,h/750.);
        double ease=1-exp(-max(0.,MSTimeF()-OpenMS)/120.);
        Font f=Font.GetFont('TinyBaby');
        Screen.Dim(Color(2,8,18),.92,int(w*.16),int(h*.13),int(w*.68),int(h*.70));
        Screen.DrawText(f,Font.CR_LIGHTBLUE,w*.19,h*.18,Hub()?"TUIN RPG":"HELL'S COMPASS",DTA_ScaleX,2.3*s,DTA_ScaleY,2.3*s);
        if(!Allowed()) {
            Screen.DrawText(f,Font.CR_GRAY,w*.19,h*.30,"LOCKED / SINGLE-PLAYER CHEAT REQUIRED",DTA_ScaleX,s,DTA_ScaleY,s);return;
        }
        for(int i=0;i<Count();i++)
        {
            double step=Hub()?.115:.075;
            double x=w*.19+(i%2)*w*.32,y=h*.27+(i/2)*h*step+(1-ease)*15*s;
            Screen.Dim(i==Selected?Color(22,57,85):Color(8,25,42),ease,int(x),int(y),int(w*.30),int(h*(step-.02)));
            Color tint=Hub()?Color(75,190,255):TuinLocatorHandler.Tint(i);
            Screen.DrawThickLine(x,y,x,y+h*(step-.02),(i==Selected?4:2)*s,tint);
            Screen.DrawText(f,Hub()?Font.CR_WHITE:TuinLocatorHandler.Ink(i),x+14*s,y+16*s,Card(i),DTA_ScaleX,1.55*s,DTA_ScaleY,1.55*s,DTA_Alpha,ease);
        }
        if(!Hub())
        {
            let handler=TuinLocatorHandler.Get();
            String status=handler && TuinLocatorHandler.TrackingCategory(handler.Category)?
                TuinLocatorHandler.Label(handler.Category)..String.Format("  %d / %d",handler.Targets.Size()>0?handler.TargetIndex+1:0,handler.Targets.Size()):"NO TARGET SELECTED";
            Screen.DrawText(f,Font.CR_WHITE,w*.19,h*.735,status,DTA_ScaleX,s,DTA_ScaleY,s);
        }
        Screen.DrawText(f,Font.CR_GRAY,w*.19,h*.79,Hub()?"CLICK / ENTER: OPEN     ESC: BACK":"CLICK / ENTER: TRACK OR CYCLE     ESC: BACK",DTA_ScaleX,s,DTA_ScaleY,s);
    }
}
class TuinRPGHubMenu : TuinLocatorMenu
{
    override bool Hub() { return true; }
}
