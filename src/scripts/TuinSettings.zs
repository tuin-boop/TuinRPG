class TuinSettingsRow : Object
{
    String Label, Key, Choices;
    int Kind;
    double Low, High, Step;
}
class TuinModernSettings : OptionMenu
{
    Array<TuinSettingsRow> Rows;
    int Selected, Page;
    String Heading, Password, Notice;
    bool PublicMenu, EnteringPassword;
    bool ConfirmingDifficulty;
    int PendingDifficulty;
    void ConfirmDifficulty(bool accepted)
    {
        if(!ConfirmingDifficulty) return;
        ConfirmingDifficulty=false;
        if(!accepted || TuinRun.Active()) return;
        CVar.FindCVar('tuin_difficulty').SetInt(PendingDifficulty);
        TuinRPGOptionsMenu.ApplyVisibleProfile(PendingDifficulty);
        TuinRPGOptionsMenu.MarkProfileApplied(PendingDifficulty);
    }
    virtual void Populate() {}
    void Add(int kind,String label,String key="",double low=0,double high=1,double step=1,String choices="")
    {
        let row=new('TuinSettingsRow');
        row.Kind=kind;row.Label=label;row.Key=key;row.Low=low;row.High=high;row.Step=step;row.Choices=choices;
        Rows.Push(row);
    }
    bool Authorized()
    { let cv=CVar.FindCVar('tuin_admin_session');return cv && cv.GetBool(); }
    override void Init(Menu parent,OptionMenuDescriptor desc)
    {
        Super.Init(parent,desc);DontDim=true;DontBlur=true;Populate();
        EnteringPassword=!PublicMenu && !Authorized();
    }
    void Adjust(int direction)
    {
        if(!PublicMenu && !Authorized()) {EnteringPassword=true;return;}
        let row=Rows[Selected];
        if(row.Kind==4)
        {
            if(Authorized()) Menu.SetMenu('TuinRPGAdvancedOptions');
            else EnteringPassword=true;
            return;
        }
        if(row.Kind==5) {CVar.FindCVar('tuin_admin_session').SetBool(false);Close();return;}
        if(row.Kind==2) {Menu.SetMenu(Name(row.Key));return;}
        if(row.Kind==3)
        {
            if(row.Key.Left(9)=="netevent ") EventHandler.SendNetworkEvent(row.Key.Mid(9));
            return;
        }
        let cv=CVar.FindCVar(Name(row.Key));if(!cv) return;
        double value=cv.GetFloat()+direction*row.Step;
        if(row.Kind==0) {if(value>row.High)value=row.Low;if(value<row.Low)value=row.High;}
        else value=clamp(value,row.Low,row.High);
        if(row.Key=="tuin_difficulty")
        {
            if(TuinRun.Active())return;
            PendingDifficulty=int(value);
            ConfirmingDifficulty=true;
            return;
        }
        cv.SetFloat(value);
    }
    void SubmitPassword()
    {
        if(Password=="johnromerogod")
        {
            CVar.FindCVar('tuin_admin_session').SetBool(true);
            EventHandler.SendNetworkEvent("tuin_locator_enable");
            Password="";EnteringPassword=false;Notice="";
            if(PublicMenu) Menu.SetMenu('TuinRPGAdvancedOptions');
        }
        else {Password="";Notice="INCORRECT PASSWORD";}
    }
    void CancelPassword()
    {
        Password="";Notice="";EnteringPassword=false;
        // A locked advanced menu has no public rows to return to.
        if(!PublicMenu) Close();
    }
    override bool OnUIEvent(UiEvent ev)
    {
        if(ConfirmingDifficulty)
        {
            if(ev.Type==UiEvent.Type_KeyDown && ev.KeyChar==27) ConfirmDifficulty(false);
            else if(ev.Type==UiEvent.Type_KeyDown && ev.KeyChar==13) ConfirmDifficulty(true);
            else if(ev.Type==UiEvent.Type_LButtonDown)
            {
                double w=Screen.GetWidth(),h=Screen.GetHeight();
                if(ev.MouseY>=h*.52 && ev.MouseY<=h*.60)
                {
                    if(ev.MouseX>=w*.20 && ev.MouseX<=w*.46) ConfirmDifficulty(true);
                    else if(ev.MouseX>=w*.53 && ev.MouseX<=w*.79) ConfirmDifficulty(false);
                }
            }
            return true;
        }
        if(EnteringPassword)
        {
            if(ev.Type==UiEvent.Type_Char && ev.KeyChar>=32 && ev.KeyChar<127 && Password.Length()<48)
                Password=Password..String.Format("%c",ev.KeyChar);
            if(ev.Type==UiEvent.Type_KeyDown && ev.KeyChar==8 && Password.Length()>0)
                Password=Password.Left(Password.Length()-1);
            if(ev.Type==UiEvent.Type_KeyDown && ev.KeyChar==13) SubmitPassword();
            if(ev.Type==UiEvent.Type_KeyDown && ev.KeyChar==27) CancelPassword();
            if(ev.Type==UiEvent.Type_LButtonDown)
            {
                double w=Screen.GetWidth(),h=Screen.GetHeight();
                if(ev.MouseX>=w*.18 && ev.MouseX<=w*.48 && ev.MouseY>=h*.64 && ev.MouseY<=h*.72)
                    CancelPassword();
            }
            return true;
        }
        if(ev.Type==UiEvent.Type_LButtonDown)
        {
            double w=Screen.GetWidth(),h=Screen.GetHeight();
            int hit=int((ev.MouseY-h*.26)/(h*.061));
            if(ev.MouseX>w*.17 && ev.MouseX<w*.83 && ev.MouseY>=h*.26 && hit>=0 && hit<8 && Page*8+hit<Rows.Size())
            {Selected=Page*8+hit;Adjust(ev.MouseX>w*.72?-1:1);}
            return true;
        }
        return Super.OnUIEvent(ev);
    }
    override bool MenuEvent(int key,bool fromcontroller)
    {
        if(ConfirmingDifficulty)
        {
            if(key==MKEY_Enter) ConfirmDifficulty(true);
            else if(key==MKEY_Back) ConfirmDifficulty(false);
            return true;
        }
        if(EnteringPassword)
        {
            if(key==MKEY_Back) CancelPassword();
            else if(key==MKEY_Enter)SubmitPassword();
            return true;
        }
        if(key==MKEY_Up || key==MKEY_Down)
        {Selected=(Selected+Rows.Size()+(key==MKEY_Up?-1:1))%Rows.Size();Page=Selected/8;return true;}
        if(key==MKEY_Left || key==MKEY_Right || key==MKEY_Enter)
        {Adjust(key==MKEY_Left?-1:1);return true;}
        return Super.MenuEvent(key,fromcontroller);
    }
    override void Drawer()
    {
        double w=Screen.GetWidth(),h=Screen.GetHeight(),s=min(w/1100.,h/750.);
        Font f=Font.GetFont('TinyBaby');
        Screen.Dim(Color(3,10,20),.96,int(w*.15),int(h*.14),int(w*.70),int(h*.69));
        Screen.DrawText(f,Font.CR_LIGHTBLUE,w*.18,h*.18,Heading,DTA_ScaleX,2*s,DTA_ScaleY,2*s);
        if(ConfirmingDifficulty)
        {
            String mode=PendingDifficulty==0?"EASY":PendingDifficulty==1?"NORMAL":PendingDifficulty==2?"HARD":"CRAZY";
            Screen.DrawText(f,Font.CR_GOLD,w*.20,h*.32,"CHANGE DIFFICULTY TO "..mode.."?",DTA_ScaleX,1.5*s,DTA_ScaleY,1.5*s);
            Screen.DrawText(f,Font.CR_WHITE,w*.20,h*.40,"LIVING MONSTERS WILL BE REROLLED.",DTA_ScaleX,1.2*s,DTA_ScaleY,1.2*s);
            Screen.Dim(Color(18,70,60),1,int(w*.20),int(h*.52),int(w*.26),int(h*.08));
            Screen.Dim(Color(60,30,40),1,int(w*.53),int(h*.52),int(w*.26),int(h*.08));
            Screen.DrawText(f,Font.CR_GREEN,w*.22,h*.55,"CONFIRM / ENTER",DTA_ScaleX,1.3*s,DTA_ScaleY,1.3*s);
            Screen.DrawText(f,Font.CR_WHITE,w*.55,h*.55,"CANCEL / ESC",DTA_ScaleX,1.3*s,DTA_ScaleY,1.3*s);
            return;
        }
        if(EnteringPassword || (!PublicMenu && !Authorized()))
        {
            String masked="";for(int i=0;i<Password.Length();i++)masked=masked.."*";
            Screen.DrawText(f,Font.CR_WHITE,w*.18,h*.32,"ADMIN PASSWORD / ENTER TO UNLOCK",DTA_ScaleX,1.4*s,DTA_ScaleY,1.4*s);
            Screen.DrawText(f,Font.CR_CYAN,w*.18,h*.42,masked.."_",DTA_ScaleX,2*s,DTA_ScaleY,2*s);
            Screen.DrawText(f,Font.CR_RED,w*.18,h*.53,Notice,DTA_ScaleX,s,DTA_ScaleY,s);
            Screen.Dim(Color(22,57,85),1,int(w*.18),int(h*.64),int(w*.30),int(h*.08));
            Screen.DrawText(f,Font.CR_WHITE,w*.20,h*.67,"CANCEL / ESC / BACK",DTA_ScaleX,1.3*s,DTA_ScaleY,1.3*s);
            return;
        }
        for(int i=Page*8;i<min(Rows.Size(),Page*8+8);i++)
        {
            let row=Rows[i];double y=h*(.26+(i%8)*.061);
            Screen.Dim(i==Selected?Color(22,57,85):Color(8,25,42),1,int(w*.17),int(y),int(w*.66),int(h*.052));
            String value="";
            if(row.Kind<2)
            {
                let cv=CVar.FindCVar(Name(row.Key));
                if(cv)
                {
                    value=String.Format("%.3g",cv.GetFloat());
                    if(row.Choices.Length()>0)
                    {
                        Array<String> names;row.Choices.Split(names,"|");
                        int index=cv.GetInt();
                        if(index>=0 && index<names.Size()) value=names[index];
                    }
                }
            }
            Screen.DrawText(f,Font.CR_WHITE,w*.185,y+10*s,row.Label,DTA_ScaleX,1.15*s,DTA_ScaleY,1.15*s);
            Screen.DrawText(f,Font.CR_CYAN,w*.66,y+10*s,value,DTA_ScaleX,1.15*s,DTA_ScaleY,1.15*s);
        }
        Screen.DrawText(f,Font.CR_GRAY,w*.18,h*.77,"UP / DOWN: SELECT   LEFT / RIGHT: CHANGE   ENTER: OPEN",DTA_ScaleX,s,DTA_ScaleY,s);
        Screen.DrawText(f,Font.CR_GRAY,w*.18,h*.80,PublicMenu?"CONFIRMED CHANGES REROLL LIVING MONSTERS":String.Format("ADMIN SETTINGS / PAGE %d OF %d",Page+1,(Rows.Size()+7)/8),DTA_ScaleX,s,DTA_ScaleY,s);
    }
}
class TuinDifficultySettings : TuinModernSettings
{
    override void Populate()
    {
        PublicMenu=true;Heading=TuinRun.Active()?"HELL'S GAMBIT / HARD LOCKED":"TUIN RPG / DIFFICULTY";
        Add(0,"DIFFICULTY","tuin_difficulty",0,3,1,"EASY|NORMAL|HARD|CRAZY");
        Add(4,"ADVANCED SETTINGS / PASSWORD");
    }
}
