// No-Classes HUD. All animation is UI-only: never changes combat state.
class TuinCombatHUD : DoomStatusBar
{
    double LastMS, Clock, HealthFill, ArmorFill, XPFill;
    double Pulse[6], Shown[6];
    int Previous[6];
    int Gains[6];
    double Visibility[6], RowPosition[6], NumberPhase[6];
    string OldNumber[6], NewNumber[6];
    Actor ViewedPawn;
    int PreviousLevelTime;
    bool Initialized;
    double InspectAlpha;
    Shape2DTransform BonusTransform;
    override void Init()
    {
        Super.Init();
        SetSize(TuinRPGHandler.CVInt('tuin_modern_hud',1) ? 0 : 32,320,200);
    }
    void Text(string value, int color, double x, double y, double scale, double alpha=1)
    {
        Screen.DrawText("TINYBABY",color,int(x),int(y),value,
            DTA_ScaleX,scale,DTA_ScaleY,scale,DTA_Alpha,alpha);
    }
    void Meter(double x,double y,double width,double height,double fraction,Color color,double alpha=1)
    {
        Screen.Dim(Color(18,29,41),alpha*.85,int(x),int(y),int(width),int(height));
        int filled=int(width*clamp(fraction,0.,1.));
        if(filled>0) Screen.Dim(color,alpha,int(x),int(y),filled,int(height));
    }
    // Same easing idea as FluidWeapons' menu offsets, measured in seconds so
    // the animation has the same duration at different rendering frame rates.
    double EaseBlend(double speed,double dt)
    {
        return 1-exp(-0.69314718056*speed*dt);
    }
    void BonusText(string value,int color,double x,double y,double scale,double alpha)
    {
        if(alpha<=0) return;
        Screen.DrawText(SmallFont,Font.CR_BLACK,x+scale,y+scale,value,
            DTA_ScaleX,scale,DTA_ScaleY,scale,DTA_Alpha,alpha*.75);
        Screen.DrawText(SmallFont,color,x,y,value,
            DTA_ScaleX,scale,DTA_ScaleY,scale,DTA_Alpha,alpha);
    }
    void AnimatedTitle(string value,int color,double x,double y,double scale,double pulse,double alpha)
    {
        Font font=SmallFont;
        double offset=0;
        for(int i=0;i<value.Length();i++)
        {
            string glyph=value.Mid(i,1);
            double lift=scale*1.3*pulse*sin((1-pulse)*540-i*24);
            BonusText(glyph,color,x+offset,y-lift,scale,alpha);
            offset+=font.StringWidth(glyph)*scale;
        }
    }
    override void Draw(int state,double TicFrac)
    {
        bool modern=TuinRPGHandler.CVInt('tuin_modern_hud',1)!=0;
        SetSize(modern?0:32,320,200);
        if(!modern || TuinRPGHandler.ClassesEnabled()) { Super.Draw(state,TicFrac); return; }
        // Keep the engine's base HUD services, without drawing the vanilla bar twice.
        Super.Draw(HUD_None,TicFrac);
        if(state==HUD_None || state==HUD_AltHud || !CPlayer || !CPlayer.mo) return;
        Actor pawn=CPlayer.mo;
        let data=TuinRPGHandler.GetPlayerData(pawn);
        if(!data) return;
        double now=MSTimeF();
        double dt=LastMS>0?clamp((now-LastMS)/1000.,0.,0.1):0;
        LastMS=now; Clock+=dt;
        bool reset=!Initialized || ViewedPawn!=pawn || level.Time<PreviousLevelTime;
        PreviousLevelTime=level.Time; ViewedPawn=pawn;
        int hp=max(0,pawn.Health);
        int maximum=max(1,pawn.GetMaxHealth(true)-data.AppliedLifeEssenceOverhealth);
        let armor=BasicArmor(pawn.FindInventory('BasicArmor'));
        int ar=armor?armor.Amount:0;
        double xp=double(data.CurrentXP)/max(1,TuinRPGHandler.XPRequired(data.PlayerLevel));
        if(reset) { HealthFill=hp; ArmorFill=ar; XPFill=xp; }
        double blend=min(1.,dt*9);
        HealthFill+=(hp-HealthFill)*blend; ArmorFill+=(ar-ArmorFill)*blend; XPFill+=(xp-XPFill)*blend;
        int sw=Screen.GetWidth(), sh=Screen.GetHeight();
        double s=min(double(sw)/1400.,double(sh)/900.)*
            clamp(TuinRPGHandler.CVFloat('tuin_hud_scale',1.5)/1.5,0.7,1.5);
        s=min(s,double(sw)/1000.);
        double x=14*s,y=sh-108*s;
        Screen.Dim(Color(3,10,19),.88,int(x),int(y),int(354*s),int(94*s));
        Screen.Dim(Color(59,182,211),.85,int(x),int(y),int(2*s),int(94*s));
        Screen.Dim(Color(12,29,43),.95,int(x+10*s),int(y+10*s),int(56*s),int(64*s));
        TextureID face=GetMugShot(5);
        if(face.IsValid()) Screen.DrawTexture(face,false,int(x+14*s),int(y+11*s),
            DTA_DestWidth,int(48*s),DTA_DestHeight,int(60*s),DTA_LeftOffset,0,DTA_TopOffset,0);
        double bx=x+78*s;
        int healthColor=hp<maximum*.3?Font.CR_RED:Font.CR_WHITE;
        Text(String.Format("%d",hp),healthColor,bx,y+10*s,2.6*s);
        Text("HEALTH",Font.CR_GRAY,bx+70*s,y+19*s,.95*s);
        Meter(bx,y+34*s,150*s,5*s,HealthFill/maximum,Color(235,82,67));
        Text(String.Format("%d",ar),Font.CR_LIGHTBLUE,bx+172*s,y+10*s,2.6*s);
        Text("ARMOR",Font.CR_GRAY,bx+172*s,y+34*s,.85*s);
        Meter(bx+172*s,y+46*s,88*s,4*s,ArmorFill/200.,Color(73,167,235));
        Text(String.Format("LEVEL %d",data.PlayerLevel),Font.CR_GOLD,bx,y+49*s,1.25*s);
        Text(String.Format("XP %d / %d",data.CurrentXP,TuinRPGHandler.XPRequired(data.PlayerLevel)),
            Font.CR_GRAY,bx,y+65*s,.9*s);
        Meter(x+10*s,y+84*s,334*s,3*s,XPFill,Color(226,184,74));
        Text(String.Format("LIVES %d",data.Lives),Font.CR_GOLD,x+10*s,y+76*s,.75*s);
        // Compact keys remain visible without replacing weapon-mod ammo logic.
        // Doom lock IDs are red/blue/yellow, while STKEYS is blue/yellow/red.
        // Use the engine's mapping, including combined card + skull icons.
        for(int key=0;key<3;key++)
        {
            int index=KeyIconIndex(pawn,key);
            if(index<0) continue;
            TextureID icon=TexMan.CheckForTexture(String.Format("STKEYS%d",index),TexMan.Type_Any);
            if(icon.IsValid()) Screen.DrawTexture(icon,false,int(bx+170*s+key*28*s),int(y+60*s),
                DTA_DestWidth,int(18*s),DTA_DestHeight,int(15*s),DTA_LeftOffset,0,DTA_TopOffset,0);
        }
        double ax=sw-224*s;
        Screen.Dim(Color(3,10,19),.88,int(ax),int(y+28*s),int(210*s),int(66*s));
        Screen.Dim(Color(226,184,74),.85,int(ax+208*s),int(y+28*s),int(2*s),int(66*s));
        Weapon weapon=CPlayer.ReadyWeapon;
        if(weapon)
        {
            string name=weapon.GetTag(weapon.GetClassName());
            TuinWeaponTraits.FluidText("TINYBABY",Font.CR_GOLD,int(ax+12*s),int(y+38*s),name,1.1*s,186*s,false,false);
            let ammo=weapon.AmmoType1?Ammo(pawn.FindInventory(weapon.AmmoType1)):null;
            Text(ammo?String.Format("%d",ammo.Amount):"--",Font.CR_WHITE,ax+12*s,y+56*s,2.6*s);
            Text(ammo?String.Format("/ %d",ammo.MaxAmount):"MELEE",Font.CR_GRAY,ax+82*s,y+67*s,1.1*s);
            if(weapon.AmmoType2 && weapon.AmmoType2!=weapon.AmmoType1)
            {
                let secondary=Ammo(pawn.FindInventory(weapon.AmmoType2));
                Text(String.Format("ALT %d",secondary?secondary.Amount:0),Font.CR_LIGHTBLUE,ax+136*s,y+67*s,.85*s);
            }
        }
        DrawInspection(data,pawn,s,dt,reset);
        if(InspectAlpha<.05) DrawBonuses(data,pawn,s,dt,reset);
        DrawMilestones(s,TicFrac);
        DrawWeaponDrop(s,TicFrac);
        DrawPlayerNotices(s,TicFrac);
        DrawKeyNotice(s,TicFrac);
        Initialized=true;
    }
    void InspectLine(string value,int color,double y,double s,double alpha,double size=1.35)
    {
        Font font=Font.GetFont("TINYBABY");
        double scale=min(size*s,310*s/max(1,font.StringWidth(value)));
        Text(value,color,12*s,y*s,scale,alpha);
    }
    void InspectDescription(string value,double y,double s,double alpha)
    {
        // Wrap at word boundaries instead of squeezing an entire description into one line.
        Font font="TINYBABY";
        double scale=1.18*s;
        string line="";
        Array<String> words;
        value.Split(words," ");
        for(int i=0;i<words.Size();i++)
        {
            string next=line.Length()?line.." "..words[i]:words[i];
            if(line.Length() && font.StringWidth(next)*scale>310*s)
            {
                Text(line,Font.CR_WHITE,12*s,y*s,scale,alpha);
                y+=14;
                line=words[i];
            }
            else line=next;
        }
        if(line.Length()) Text(line,Font.CR_WHITE,12*s,y*s,scale,alpha);
    }
    void DrawInspection(TuinPlayerData data,Actor pawn,double s,double dt,bool reset)
    {
        let handler=TuinRPGHandler(EventHandler.Find('TuinRPGHandler'));
        int viewer=pawn.PlayerNumber();
        if(!handler || viewer<0 || viewer>=8) return;
        Weapon weapon=CPlayer.ReadyWeapon;
        bool visible=handler.InspectWeapon[viewer] && pawn.Health>0 && weapon!=null;
        if(reset) InspectAlpha=0;
        InspectAlpha+=((visible?1.:0.)-InspectAlpha)*EaseBlend(14,dt);
        if(InspectAlpha<.005 || !weapon) return;
        double a=InspectAlpha;
        // A restrained, readable block, anchored to the middle-right at any aspect ratio.
        s=min(s,Screen.GetWidth()*.34/340.);
        int index=TuinRPGHandler.ActiveWeaponVariantIndex(viewer,data);
        int quality=index>=0?data.VariantQuality[index]:0;
        int itemLevel=index>=0?data.VariantItemLevel[index]:0;
        int flags=index>=0?data.VariantAffixFlags[index]:0;
        int color=TuinRPGHandler.WeaponQualityFontColor(quality);
        string title=index>=0?TuinWeaponTraits.DisplayName(data.VariantWeaponType[index],flags,
            quality,data.VariantID[index]):TuinRPGHandler.WeaponBaseName(weapon.GetClass());
        int traitCount=0;
        for(int k=0;k<3;k++) if(TuinWeaponTraits.Nth(flags,k)>=0) traitCount++;
        int family=TuinRPGHandler.WeaponFamily(weapon);
        bool perk=TuinRPGHandler.HasWeaponPerk(data,family);
        double height=257+traitCount*52+(perk?68:0);
        double angle=-2-(1-a)*5;
        if(!BonusTransform) BonusTransform=new('Shape2DTransform');
        BonusTransform.From2D(cos(angle),-sin(angle),sin(angle),cos(angle),
            Screen.GetWidth()*.61+(1-a)*35*s,Screen.GetHeight()*.48-height*s*.5);
        Screen.SetTransform(BonusTransform);
        Screen.Dim(Color(3,10,19),a*.93,0,0,int(334*s),int(height*s));
        Screen.DrawLineFrame(TuinWeaponDrop.QualityColor(quality),0,0,int(334*s),int(height*s),max(1,int(s)));
        InspectLine("CURRENT WEAPON  /  INSPECT",Font.CR_GRAY,12,s,a,1.05);
        TuinWeaponTraits.FluidText("TINYBABY",color,12*s,34*s,title,2.0*s,307*s,
            quality==6,quality>=2,quality==5,quality,a);
        InspectLine(String.Format("%s  |  ITEM LEVEL %d  |  SCORE %d",
            TuinRPGHandler.WeaponQualityName(quality),itemLevel,
            index>=0?TuinRPGHandler.StoredWeaponVariantScore(data,index):0),color,60,s,a,1.1);
        InspectLine("WEAPON BONUSES",Font.CR_GRAY,86,s,a,1.1);
        InspectLine(String.Format("ITEM-LEVEL DAMAGE   +%d%%",index>=0?
            TuinRPGHandler.WeaponItemLevelPowerPercent(itemLevel):0),Font.CR_GOLD,108,s,a);
        InspectLine(String.Format("POWER ROLL          +%d%%",index>=0?data.VariantPowerPercent[index]:0),Font.CR_WHITE,128,s,a);
        InspectLine(String.Format("FIRING SPEED        +%d%%",index>=0?data.VariantHastePercent[index]:0),Font.CR_WHITE,148,s,a);
        InspectLine(String.Format("CRITICAL CHANCE     +%d%%",index>=0?
            TuinRPGHandler.WeaponCriticalPercent(flags,quality,itemLevel):0),Font.CR_WHITE,168,s,a);
        InspectLine(String.Format("DAMAGE LEECH         %d%%",index>=0?data.VariantLeechPercent[index]:0),Font.CR_GREEN,188,s,a);
        InspectLine(String.Format("EXECUTION DAMAGE    +%d%%",index>=0?data.VariantExecutionPercent[index]:0),Font.CR_RED,208,s,a);
        InspectLine(String.Format("KILL XP             +%d%%",index>=0?data.VariantProsperityPercent[index]:0),Font.CR_GOLD,228,s,a);
        double row=257;
        for(int k=0;k<traitCount;k++)
        {
            int trait=TuinWeaponTraits.Nth(flags,k);
            InspectLine(TuinWeaponTraits.NameOf(trait)..(TuinWeaponTraits.Passive(trait)?
                "  [ALWAYS ACTIVE]":"  [EQUIPPED]"),color,row,s,a);
            InspectDescription(TuinWeaponTraits.Description(trait,quality),row+18,s,a);
            row+=52;
        }
        if(perk)
        {
            InspectLine(TuinRPGHandler.WeaponPerkName(family),Font.CR_PURPLE,row,s,a);
            InspectDescription(TuinRPGHandler.WeaponPerkSummary(family),row+18,s,a);
        }
        // Higher rarities add traveling sparks; Godly has the densest rainbow shimmer.
        if(quality>=2)
        {
            for(int spark=0;spark<quality-1;spark++)
            {
                double phase=(Clock*(.16+quality*.02)+spark/double(quality-1))%1.;
                double glow=sin(phase*180)*a*(.25+quality*.08);
                BonusText("+",quality==6?(spark%2?Font.CR_CYAN:Font.CR_GOLD):color,
                    (12+phase*307)*s,(23+sin(phase*360+spark*70)*5)*s,
                    (.4+quality*.045)*s,glow);
            }
        }
        Screen.ClearTransform();
    }
    clearscope static int KeyIconIndex(Actor pawn,int color)
    {
        if(!pawn || color<0 || color>2) return -1;
        int lock=color==0?2:color==1?3:1;
        bool card=pawn.CheckKeys(lock,false,true);
        bool skull=pawn.CheckKeys(lock+3,false,true);
        return card && skull?color+6:card?color:skull?color+3:-1;
    }
    void DrawKeyNotice(double s,double ticFrac)
    {
        if(!TuinRPGHandler.CVInt('tuin_combat_bonus_hud',1)) return;
        let handler=TuinRPGHandler(EventHandler.Find('TuinRPGHandler'));
        int viewer=CPlayer.mo.PlayerNumber();
        if(!handler || viewer<0 || viewer>=8) return;
        int start=handler.KeyBannerStart[viewer];
        double age=(level.Time+ticFrac-(start-1))/35.;
        if(start<=0 || age<0 || age>=3) return;
        double enter=clamp(age/.3,0.,1.);
        double ease=1-(1-enter)*(1-enter)*(1-enter);
        double leave=clamp((age-2.3)/.7,0.,1.);
        double fade=leave*leave*(3-2*leave);
        double alpha=ease*(1-fade);
        int mask=handler.KeyBannerMask[viewer];
        int count=0, last=0;
        for(int i=0;i<6;i++) if(mask & (1<<i)) { count++; last=i; }
        string keyColor=last%3==0?"RED":last%3==1?"BLUE":"YELLOW";
        string title=count==1?keyColor..(last<3?" KEYCARD ACQUIRED":" SKULL KEY ACQUIRED"):"KEYRING EXPANDED";
        string detail=count==1?"A NEW PATH OPENS":String.Format("%d NEW KEYS ACQUIRED",count);
        int color=count>1?Font.CR_GOLD:last%3==0?Font.CR_RED:last%3==1?Font.CR_LIGHTBLUE:Font.CR_YELLOW;
        Font font=SmallFont;
        double scale=min(2*s,Screen.GetWidth()*.52/max(1,font.StringWidth(title)));
        double angle=-8;
        if(!BonusTransform) BonusTransform=new('Shape2DTransform');
        BonusTransform.From2D(cos(angle),-sin(angle),sin(angle),cos(angle),
            Screen.GetWidth()*.5-30*s*(1-ease)+25*s*fade,Screen.GetHeight()*.65-8*s*fade);
        Screen.SetTransform(BonusTransform);
        AnimatedTitle(title,color,-font.StringWidth(title)*scale*.5,0,scale,max(0.,1-age/.85),alpha);
        BonusText(detail,Font.CR_WHITE,-font.StringWidth(detail)*s*.5,25*s,s,alpha*clamp((age-.15)/.3,0.,1.));
        Screen.ClearTransform();
    }
    void DrawPlayerNotices(double s,double ticFrac)
    {
        if(!TuinRPGHandler.CVInt('tuin_combat_bonus_hud',1)) return;
        let handler=TuinRPGHandler(EventHandler.Find('TuinRPGHandler'));
        int viewer=CPlayer.mo.PlayerNumber();
        if(!handler || viewer<0 || viewer>=8) return;
        double now=level.Time+ticFrac;
        if(!BonusTransform) BonusTransform=new('Shape2DTransform');
        int pointStart=handler.PointBannerStart[viewer];
        double age=(now-(pointStart-1))/35.;
        if(pointStart>0 && age>=0 && age<4)
        {
            double enter=clamp(age/.35,0.,1.);
            double ease=1-(1-enter)*(1-enter)*(1-enter);
            double leave=clamp((age-3.3)/.7,0.,1.);
            double fade=leave*leave*(3-2*leave);
            double alpha=ease*(1-fade);
            double angle=-8;
            BonusTransform.From2D(cos(angle),-sin(angle),sin(angle),cos(angle),
                Screen.GetWidth()*.08-25*s*(1-ease)+20*s*fade,Screen.GetHeight()*.43-8*s*fade);
            Screen.SetTransform(BonusTransform);
            Font font=SmallFont;
            double scale=min(1.7*s,Screen.GetWidth()*.36/max(1,font.StringWidth("WEAPON PERK POINT GAINED")));
            let data=TuinRPGHandler.GetPlayerData(CPlayer.mo);
            int counts[3]={data?data.UnspentStatPoints:0,data?data.UnspentSkillPoints:0,data?data.UnspentWeaponPerkPoints:0};
            int row=0;
            for(int i=0;i<3;i++) if(counts[i]>0)
            {
                string kind=i==0?"STAT":i==1?"PERK":"WEAPON PERK";
                string text=kind.." POINT GAINED";
                double reveal=clamp((age-.12-row*.12)/.25,0.,1.);
                int color=i==0?Font.CR_CYAN:i==1?Font.CR_GREEN:Font.CR_PURPLE;
                AnimatedTitle(text,color,8*s*(1-reveal),row*38*s,scale,
                    max(0.,1-age/.8),alpha*reveal);
                BonusText(String.Format("%d UNSPENT - CHOOSE YOUR UPGRADE",counts[i]),Font.CR_WHITE,
                    0,(row*38+17)*s,scale*.6,alpha*reveal);
                row++;
            }
            Screen.ClearTransform();
        }
        int poisonTick=handler.PoisonBannerTick[viewer];
        double since=(now-(poisonTick-1))/35.;
        if(poisonTick<=0 || since<0 || since>=2 || CPlayer.mo.Health<=0) return;
        double onset=(now-(handler.PoisonBannerStart[viewer]-1))/35.;
        double enter=clamp(onset/.25,0.,1.);
        double fade=clamp((since-1.25)/.75,0.,1.);
        fade=fade*fade*(3-2*fade);
        double alpha=enter*(1-fade);
        double kick=max(0.,1-since/.4);
        double angle=-8;
        BonusTransform.From2D(cos(angle),-sin(angle),sin(angle),cos(angle),
            Screen.GetWidth()*.12-18*s*(1-enter)+20*s*fade,Screen.GetHeight()*.72-6*s*fade);
        Screen.SetTransform(BonusTransform);
        AnimatedTitle("POISONED",Font.CR_GREEN,0,0,1.9*s,kick,alpha);
        BonusText(String.Format("-%d POISON DAMAGE",handler.PoisonBannerDamage[viewer]),
            Font.CR_GREEN,0,23*s,1.05*s,alpha);
        Screen.ClearTransform();
    }
    void DrawWeaponDrop(double s,double ticFrac)
    {
        if(!TuinRPGHandler.CVInt('tuin_combat_bonus_hud',1)) return;
        let handler=TuinRPGHandler(EventHandler.Find('TuinRPGHandler'));
        int viewer=CPlayer.mo.PlayerNumber();
        if(!handler || viewer<0 || viewer>=8) return;
        int start=handler.WeaponBannerStart[viewer];
        int quality=handler.WeaponBannerQuality[viewer];
        int tier=clamp(quality,1,6);
        double duration=(70+tier*12)/35.;
        double age=(level.Time+ticFrac-(start-1))/35.;
        if(start<=0 || age<0 || age>=duration) return;
        double enter=clamp(age/.35,0.,1.);
        double ease=1-(1-enter)*(1-enter)*(1-enter);
        double leave=clamp((age-duration+.65)/.65,0.,1.);
        double fade=leave*leave*(3-2*leave);
        double alpha=ease*(1-fade);
        double epic=(tier-1)/5.;
        string title=TuinRPGHandler.WeaponQualityName(quality).." WEAPON DROPPED";
        string detail=handler.WeaponBannerDetail[viewer];
        Font font=SmallFont;
        int color=TuinRPGHandler.WeaponQualityFontColor(quality);
        double scale=min((1.25+1.4*epic)*s,Screen.GetWidth()*.58/max(1,font.StringWidth(title)));
        scale*=1+sin(enter*180)*(.04+.13*epic)-.07*fade;
        double angle=-5-5*epic+(1-ease)*4;
        if(!BonusTransform) BonusTransform=new('Shape2DTransform');
        // Separate loot lane below milestone banners, clear of the crosshair.
        BonusTransform.From2D(cos(angle),-sin(angle),sin(angle),cos(angle),
            Screen.GetWidth()*.5-35*s*(1-ease)+35*s*fade,Screen.GetHeight()*.40-8*s*fade);
        Screen.SetTransform(BonusTransform);
        double x=-font.StringWidth(title)*scale*.5;
        if(tier>=3)
        {
            double burst=clamp(age/.8,0.,1.);
            int sparks=4+(tier-3)*2;
            for(int k=0;k<sparks;k++)
            {
                double direction=k*360./sparks;
                double reach=(18+burst*(24+epic*20))*s;
                BonusText("+",color,cos(direction)*reach*(2+epic),sin(direction)*reach,
                    (.55+epic*.4)*s,alpha*(1-burst)*.65);
            }
            // Rarity-scaled echo glow, confined to the lettering.
            for(int trail=1;trail<=tier-2;trail++)
                BonusText(title,color,x-trail*s*(1-ease),trail*s*.4,scale,
                    alpha*(.025+epic*.02)*(1-age/duration));
        }
        TuinWeaponTraits.FluidText(font,color,x,0,title,scale,Screen.GetWidth()*.58,
            quality==6,true,quality==5,quality,alpha);
        if(tier>=4 && age<.55)
            BonusText(title,Font.CR_WHITE,x,0,scale,alpha*(1-age/.55)*.35);
        double subScale=min(.95*s,Screen.GetWidth()*.58/max(1,font.StringWidth(detail)));
        double reveal=clamp((age-.18)/.25,0.,1.);
        BonusText(detail,Font.CR_WHITE,-font.StringWidth(detail)*subScale*.5,
            (18+8*epic+5*(1-reveal))*s,subScale,alpha*reveal);
        Screen.ClearTransform();
    }
    void DrawMilestones(double s,double ticFrac)
    {
        if(!TuinRPGHandler.CVInt('tuin_combat_bonus_hud',1)) return;
        let handler=TuinRPGHandler(EventHandler.Find('TuinRPGHandler'));
        if(!handler) return;
        for(int event=0;event<9;event++)
        {
            int viewer=CPlayer.mo.PlayerNumber();
            int start=event==0?handler.BossBannerStart:event==1?handler.JohnBannerStart:
                event==2?handler.BossArrivalBannerStart:event==3?handler.PromotionBannerStart:
                event==4?(viewer>=0 && viewer<8?handler.HeavyBannerStart[viewer]:0):
                event<8?handler.CompletionBannerStart[event-5]:
                viewer>=0 && viewer<8?handler.CoinBannerStart[viewer]:0;
            double age=(level.Time+ticFrac-(start-1))/35.;
            double duration=event>=2?4.8:3.2;
            if(start<=0 || age<0 || age>=duration) continue;
            double entrance=clamp(age/.4,0.,1.);
            double exit=clamp((age-(duration-.7))/.7,0.,1.);
            double ease=1-(1-entrance)*(1-entrance)*(1-entrance);
            double fade=exit*exit*(3-2*exit);
            double alpha=ease*(1-fade);
            string title=event==0?"BOSS DEFEATED":event==1?"JOHN ROMERO HAS ARRIVED":
                event==2?"BOSS HAS ARRIVED":event==3?handler.PromotionBannerTitle:event==4?"HELL SENDS ITS HEAVYWEIGHTS":
                event==5?"HELL HAS BEEN SILENCED":event==6?"NOTHING LEFT BEHIND":event==7?"NO SECRET STAYS HIDDEN":
                String.Format("%d COINS COLLECTED",handler.CoinBannerAmount[viewer]);
            int milestoneColor=event==0 || event==4?Font.CR_GOLD:event==1?Font.CR_CYAN:event==3?Font.CR_PURPLE:Font.CR_RED;
            if(event>=5) milestoneColor=event==5?Font.CR_RED:event==6?Font.CR_GREEN:event==7?Font.CR_CYAN:Font.CR_GOLD;
            Font font=SmallFont;
            double scale=min(2.8*s,Screen.GetWidth()*.66/max(1,font.StringWidth(title)));
            double bounce=sin(entrance*180)*.12;
            scale*=1+bounce-.08*fade;
            double angle=-8+5*(1-ease)-4*fade;
            if(!BonusTransform) BonusTransform=new('Shape2DTransform');
            BonusTransform.From2D(cos(angle),-sin(angle),sin(angle),cos(angle),
                Screen.GetWidth()*.5-65*s*(1-ease)+55*s*fade,
                Screen.GetHeight()*.29-14*s*fade);
            Screen.SetTransform(BonusTransform);
            double x=-font.StringWidth(title)*scale*.5;
            // Brief trailing echo on arrival, then settle into crisp lettering.
            BonusText(title,milestoneColor,x-7*s*(1-ease),4*s*(1-ease),scale,alpha*(1-ease)*.3);
            AnimatedTitle(title,milestoneColor,x,0,scale,max(0.,1-age/1.1),alpha);
            if(age<.55) BonusText(title,Font.CR_WHITE,x,0,scale,alpha*(1-age/.55)*.3);
            if(event==2)
            {
                string challenge="CAN YOU FIND IT?  REACH IT?  DEFEAT IT?";
                double subScale=min(1.15*s,Screen.GetWidth()*.64/max(1,font.StringWidth(challenge)));
                double cursor=-font.StringWidth(challenge)*subScale*.5;
                for(int part=0;part<3;part++)
                {
                    string phrase=part==0?"CAN YOU FIND IT?  ":part==1?"REACH IT?  ":"DEFEAT IT?";
                    double reveal=clamp((age-.55-part*.55)/.3,0.,1.);
                    double settle=1-(1-reveal)*(1-reveal)*(1-reveal);
                    BonusText(phrase,part==2?Font.CR_GOLD:Font.CR_WHITE,cursor,
                        32*s+9*s*(1-settle),subScale,settle*alpha);
                    cursor+=font.StringWidth(phrase)*subScale;
                }
            }
            else if(event>=3)
            {
                string detail=event==3?handler.PromotionBannerDetail:
                    event==4?"LEVEL 15 - STRONGER MONSTERS NOW TAKE PROMOTION PRIORITY":
                    event==5?"100% KILLS - ALL MONSTERS DEFEATED":event==6?"100% ITEMS - EVERY PICKUP FOUND":
                    event==7?"100% SECRETS - EVERY HIDDEN PLACE UNCOVERED":"YOUR FORTUNE GROWS";
                double subScale=min(1.15*s,Screen.GetWidth()*.68/max(1,font.StringWidth(detail)));
                double reveal=clamp((age-.5)/.4,0.,1.);
                double settle=1-(1-reveal)*(1-reveal)*(1-reveal);
                BonusText(detail,Font.CR_WHITE,-font.StringWidth(detail)*subScale*.5,
                    32*s+9*s*(1-settle),subScale,settle*alpha);
            }
            Screen.ClearTransform();
        }
    }
    void DrawBonuses(TuinPlayerData data,Actor pawn,double s,double dt,bool reset)
    {
        int values[6];
        values[0]=TuinWeaponTraits.Strength(data,13)?data.TraitMomentumStacks*2:0;
        values[1]=data.TraitWindTime;
        values[2]=TuinWeaponTraits.Strength(data,10)?data.TraitAvenger:0;
        // A lethal repeat hit still earned this bonus. Keep it readable briefly
        // instead of hiding it before the next rendered frame sees the stack.
        values[3]=TuinWeaponTraits.Strength(data,7) && data.TraitDuelTarget &&
            (data.TraitDuelTarget.Health>0 || level.Time-data.TraitDuelTime<28)?data.TraitDuelStacks*2:0;
        int last=TuinWeaponTraits.Strength(data,8);
        values[4]=last && pawn.Health>0 && pawn.Health*100<pawn.GetMaxHealth(true)*30?10+last*10:0;
        values[5]=data.TraitSurvivorUsed?1:0;
        for(int i=0;i<6;i++)
        {
            if(reset)
            {
                Previous[i]=values[i]; Pulse[i]=0; Shown[i]=values[i]; Gains[i]=0;
                Visibility[i]=0; RowPosition[i]=-1; NumberPhase[i]=1;
                OldNumber[i]=""; NewNumber[i]="";
            }
            else if(values[i]>Previous[i]) { Pulse[i]=1; Gains[i]=values[i]-Previous[i]; }
            Previous[i]=values[i]; Pulse[i]=max(0.,Pulse[i]-dt*1.4);
            bool active=i==5?Pulse[i]>0:values[i]>0;
            Visibility[i]+=((active?1.:0.)-Visibility[i])*EaseBlend(active?12:5,dt);
            if(!active && Visibility[i]<.005) { Visibility[i]=0; RowPosition[i]=-1; }
            Shown[i]+=(values[i]-Shown[i])*EaseBlend(16,dt);
            NumberPhase[i]=min(1.,NumberPhase[i]+dt/0.24);
        }
        if(!TuinRPGHandler.CVInt('tuin_combat_bonus_hud',1) || pawn.Health<=0) return;
        double fx=Screen.GetWidth()*.59;
        double fy=Screen.GetHeight()*.43;
        double width=min(185*s,Screen.GetWidth()-fx-12*s);
        int row=0;
        // Never silently discard an active bonus behind a three-row limit.
        int order[6]={0,3,5,1,2,4};
        for(int entry=0;entry<6;entry++)
        {
            int i=order[entry];
            if(Visibility[i]<=0) continue;
            if(RowPosition[i]<0) RowPosition[i]=row;
            RowPosition[i]+=(row-RowPosition[i])*EaseBlend(10,dt);
            double yy=fy+RowPosition[i]*36*s;
            double a=Visibility[i];
            string title=i==0?"MOMENTUM":i==1?"SECOND WIND":i==2?"AVENGER":i==3?"DUELIST":i==4?"LAST STAND":"SURVIVED!";
            int color=i==0?Font.CR_GOLD:i==1?Font.CR_GREEN:i==2?Font.CR_ORANGE:i==3?Font.CR_CYAN:Font.CR_RED;
            string number=i==0 || i==3 || i==4?String.Format("+%d%%",values[i]):
                i==1?String.Format("%.1fs",values[i]/35.):i==2?String.Format("+%d%%",20+TuinWeaponTraits.Strength(data,10)*10):"1HP";
            // Preserve the last meaningful value during the exit. Timers update
            // continuously; discrete percentage changes roll between totals.
            if(NewNumber[i]=="") NewNumber[i]=number;
            if(values[i]>0 && NewNumber[i]!=number)
            {
                OldNumber[i]=NewNumber[i]; NewNumber[i]=number;
                NumberPhase[i]=i==1?1:0;
            }
            // FluidWeapons' MR_DOOM graphic uses STCFN glyphs (Doom SmallFont),
            // enlarged and rotated, not the menu's BigFont.
            Font block=SmallFont;
            double fs=min(1.7*s,(width+60*s)/max(1,block.StringWidth("+100%  "..title)));
            double pop=1+.12*Pulse[i]*sin((1-Pulse[i])*450);
            double angle=-12+2*Pulse[i]*sin((1-Pulse[i])*540);
            bool leaving=i==5?Pulse[i]<=0:values[i]<=0;
            double drift=(1-a)*(leaving?26:-18)*s;
            if(!BonusTransform) BonusTransform=new('Shape2DTransform');
            BonusTransform.From2D(cos(angle),-sin(angle),sin(angle),cos(angle),fx+drift,yy-(leaving?8*(1-a)*s:0));
            Screen.SetTransform(BonusTransform);
            double phase=NumberPhase[i];
            double eased=phase*phase*(3-2*phase);
            double slot=block.StringWidth("+100%")*fs;
            double ns=fs*pop;
            if(phase<1 && OldNumber[i]!="")
                BonusText(OldNumber[i],color,slot-block.StringWidth(OldNumber[i])*fs,
                    -10*s*eased,fs,a*(1-eased));
            BonusText(NewNumber[i],color,slot-block.StringWidth(NewNumber[i])*ns,
                10*s*(1-eased),ns,a*eased);
            // Subtle bright accent on each gain, plus a traveling letter bounce.
            if(Pulse[i]>.65)
                BonusText(NewNumber[i],Font.CR_WHITE,slot-block.StringWidth(NewNumber[i])*ns,
                    10*s*(1-eased),ns,a*eased*(Pulse[i]-.65));
            AnimatedTitle(title,color,slot+10*s,0,fs,Pulse[i],a);
            Screen.ClearTransform();
            row++;
        }
    }
}
