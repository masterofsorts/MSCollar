////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                          OpenCollar - AO Link (lite)                           //
//                                 version 3.980                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
//                    github.com/OpenCollar/OpenCollarUpdater                     //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

// Based on Medea Destiny's AO interface script for OpenCollar.

// HOW TO: This script is intended to be dropped into ZHAO-2, Vista and Oracul
// AOs that are not already compatible with OpenCollar's AO interface. Just rez
// your existing AO Hud, right-click to open it and drop this script inside!

// This is not a complete replacement of the Sub AO as it cannot allow as complete
// access to the AO as that does, but it should provide most of the functionality
// while being very easy to add to your pre-existing AOs.

// The lite variation of this script is complementary to AntiSlide technology.

integer type; 
//If left like this, script will try to determine AO type automatically.
//To force compatibility for a particular type of AO, change to:
// integer type=1; //for Oracul type AOs
// integer type=2; // for ZHAO-II type AOs
// integer type=3; // for Vista type AOs
// integer type=4; // for AKEYO type AOs
//----------------------------------------------------------------------
//Integer map for above
integer ORACUL=1; 
integer ZHAO=2;
integer VISTA=3;
integer AKEYO=4;

// OC channel listener for comms from collar
integer g_iAOChannel = -782690;
integer g_iAOListenHandle;

//Menu handler for script's own ZHAO menu
integer g_iMenuHandle; 
integer g_iMenuChannel=-23423456; //dummy channel, changed to unique on attach
list g_lMenuUsers; //list of menu users to allow for multiple users of menu 
integer g_iMenuTimeout=60;

string g_sOraculstring; //configuration string for Oracul power on/off, 0 prepended for off, 1 prepended for on

//We use these two so that we can return the AO to its previous state. If the AO was already off when the OC tries to switch it off, we shouldn't switch it back on again.
integer g_iAOSwitch=TRUE; //monitor on/off from the AO's own state.
integer g_iOCSwitch=TRUE; //monitor on/off due to collar pauses (FALSE=paused, TRUE=unpaused)


integer g_iSitOverride=TRUE; //monitor AO sit override




determineType() //function to determine AO type.
{
    llListenRemove(g_iAOListenHandle);
    type=0;
    integer x=llGetInventoryNumber(INVENTORY_SCRIPT);
    while(x)
    {
        --x;
        string t=llToLower(llGetInventoryName(INVENTORY_SCRIPT,x));
        if(~llSubStringIndex(t,"zhao")) //if we find a script with "zhao" in the name.
        {
            type=ZHAO;
            x=0;
            llOwnerSay("OC compatibility script configured for Zhao AO. Depending on your AO model, you may sometimes see your AO buttons get out of sync when the AO is accessed via the collar, just toggle a setting to restore it. NOTE! Toggling sit override now is highly recommended, but if you don't know what that means or don't have one, don't worry.");
            llMessageLinked(LINK_SET, 0, "ZHAO_AOON", "");
            
        }
        else if(~llSubStringIndex(t,"vista")) //if we find a script with "zhao" in the name.
        {
            type=VISTA;
            x=0;
            llOwnerSay("OC compatibility script configured for VISTA AO. Support is very experimental since it is unknown how much was changed from ZHAO.");
            llMessageLinked(LINK_SET, 0, "ZHAO_AOON", "");
            
        }
        else if(~llSubStringIndex(t,"oracul")) //if we find a script with "oracul" in the name.
        {
            type=ORACUL;
            x=0;
            llOwnerSay("OC compatibility script configured for Oracul AO. IMPORTANT: for proper functioning, you must now switch your AO on (switching it off first if necessary!)");
        }
    }
    if (llSubStringIndex(llGetObjectName(),"AKEYO") >=0) { //AKEYO is not a string in their script name, it is in animations but think the object name is a better test for this AO - Sumi Perl
        type = AKEYO;
        llOwnerSay("OC compatibility script configured for AKEYO AO.  This support is experimental.  Please let us know if you notice any problems.");
    }
    if(type==0) llOwnerSay("Cannot identify AO type. The script:"+llGetScriptName()+" is intended to be dropped into a Zhao2 or Oracul AO hud.");
    else 
    {
       g_iAOListenHandle=llListen(g_iAOChannel,"","",""); //We identified type, start script listening!
    }
}


AOPause()
{
    if(g_iAOSwitch)
    {
        if (type==ORACUL && g_sOraculstring!="") llMessageLinked(LINK_SET,0,"0"+g_sOraculstring,"ocpause");
        else if (type==AKEYO) llMessageLinked(LINK_ROOT, 0, "PAO_AOOFF", "ocpause");
        //Note: for ZHAO use LINK_THIS in pause functions, LINK_SET elsewhere. This is because ZHAOs which switch power on buttons by a script in the button reading the link messages are quite common. This avoids toggling the power switch when AO is only paused in those cases.
        else if(type>1) llMessageLinked(LINK_THIS, 0, "ZHAO_AOOFF", "ocpause");//we use "ocpause" as a dummy key to identify our own linked messages so we can tell when an on or off comes from the AO rather than from the collar standoff, to sync usage.

    }
    g_iOCSwitch=FALSE;

}

AOUnPause()
{
    if(g_iAOSwitch)
    {
        if (type==ORACUL && g_sOraculstring!="") llMessageLinked(LINK_SET,0,"1"+g_sOraculstring,"ocpause");
        else if(type==AKEYO ) llMessageLinked(LINK_ROOT, 0, "PAO_AOON", "ocpause"); 
        else if(type>1 ) llMessageLinked(LINK_THIS, 0, "ZHAO_AOON", "ocpause"); 

    }
    g_iOCSwitch=TRUE;

}

zhaoMenu(key kMenuTo)
{
    //script's own menu for some ZHAO features. 
    //Open listener if no menu users are registered in g_lMenuUsers already, and add 
    //menu user to list if not already present.
    if(!llGetListLength(g_lMenuUsers)) g_iMenuHandle=llListen(g_iMenuChannel,"","","");
    if(llListFindList(g_lMenuUsers,[kMenuTo])==-1) g_lMenuUsers+=kMenuTo;
    string sSit="AO Sits ON";
    if(g_iSitOverride) sSit="AO Sits OFF";
    list lButtons=[sSit,"Load Notecard","Done","AO on","AO off","Next Stand"];
    llSetTimerEvent(g_iMenuTimeout);
    llDialog(kMenuTo,"AO options. Depending on model of AO, some may not work. Use OC Sub AO for more comprehensive control!",lButtons,g_iMenuChannel);   
}
                                   
default
{
    state_entry()
    {
       if(type==0) determineType();
       g_iMenuChannel=-(integer)llFrand(999999)-10000; //randomise menu channel
    }
    
    attach(key avatar)
    {
        if(avatar) //on attach
        {
            if(type==0) determineType();
            g_iMenuChannel=-(integer)llFrand(999999)-10000; //randomise menu channel 
        }  
    }
    
    listen(integer iChannel, string sName, key kID, string sMsg)
    {

        if(iChannel==g_iMenuChannel) // this is for our own limited ZHAO menu.
        {
            if(sMsg=="Done"||sMsg=="Cancel")
            {
                integer i=llListFindList(g_lMenuUsers,[kID]);
                if(i>-1) g_lMenuUsers=llDeleteSubList(g_lMenuUsers,i,i); //remove user from menu users list.
                if(!llGetListLength(g_lMenuUsers)) //remove listener if no menu users left
                {
                    llListenRemove(g_iMenuHandle);
                    llSetTimerEvent(0);
                }
                return; // we're done here!
            }
            else if(sMsg=="Load Notecard") //scan for notecards and provide a dialog to user
            {
                list lButtons;
                integer x=llGetInventoryNumber(INVENTORY_NOTECARD);
                while(x)
                {
                    x--;
                    string t=llGetInventoryName(INVENTORY_NOTECARD,x);
                   if(llSubStringIndex(llToLower(t),"read me")==-1 && llSubStringIndex(llToLower(t),"help")==-1 && llStringLength(t)<23) lButtons+=t; //we only take notecards without "help" or "read me" in the title and with short enough names to fit on a button.
                }
                if(llGetListLength(lButtons)>11)
                {
                    llRegionSayTo(kID,0,"Too many notecards found, displaying the first 11"); //ZHAO doesn't bother multi pages, so we won't.
                    lButtons=llDeleteSubList(lButtons,11,-1);
                }
                llSetTimerEvent(g_iMenuTimeout);
                llDialog(kID,"Pick an AO settings notecard to load, or click Cancel",lButtons+["Cancel"],g_iMenuChannel);
                
            }
            else if(sMsg=="AO Sits ON")
            {
                g_iSitOverride=TRUE; //this will get set by the link message anyway, but set here just in case remenu happens before link message is read.
                llMessageLinked(LINK_SET,0,"ZHAO_SITON","");
            }
            else if(sMsg=="AO Sits OFF")
            {
                g_iSitOverride=FALSE;
                llMessageLinked(LINK_SET,0,"ZHAO_SITOFF","");
            }
            else if(sMsg=="AO on")
            {
                if(g_iOCSwitch) llMessageLinked(LINK_SET,0,"ZHAO_AOON",""); // don't switch on AO if we are paused

                g_iAOSwitch=TRUE;
            }
            else if(sMsg=="AO off")
            {
                llMessageLinked(LINK_SET,0,"ZHAO_AOOFF","");

            }
            else if(sMsg=="Next Stand")
            {
                if(type == 2) // ZHAO-II
                    llMessageLinked(LINK_SET,0,"ZHAO_NEXTSTAND","");
                else // VISTA                
                    llMessageLinked(LINK_SET,0,"ZHAO_NEXTPOSE","");
            }
            //check if sMsg is a notecard picked from Load Notecard menu, and send load command if so.
             else  if(llGetInventoryType(sMsg)==INVENTORY_NOTECARD) llMessageLinked(LINK_THIS,0,"ZHAO_LOAD|"+sMsg,"");
            //resend the menu where it makes sense.
            if(sMsg!="Done" && sMsg!="Cancel" && sMsg!="Load Notecard") zhaoMenu(kID);
            return;
        }
        else if(llGetOwnerKey(kID)!=llGetOwner()) return; //reject commands from other sources. 
        else if (iChannel==g_iAOChannel)
        {
            if(sMsg=="ZHAO_STANDON") AOUnPause();
            else if (sMsg=="ZHAO_STANDOFF") AOPause();
            else if (sMsg=="ZHAO_AOOFF")
            {
                if (type==ORACUL && g_sOraculstring!="") llMessageLinked(LINK_SET,0,"0"+g_sOraculstring,"ocpause");
                else if(type==AKEYO ) llMessageLinked(LINK_ROOT, 0, "PAO_AOOFF", "ocpause"); 
                else if(type>1 ) llMessageLinked(LINK_THIS, 0, "ZHAO_AOOFF", "ocpause"); 
               

            }
            else if (sMsg=="ZHAO_AOON")
            {
                if(g_iOCSwitch)// don't switch on AO if we are paused
                {
                    if (type==ORACUL && g_sOraculstring!="") llMessageLinked(LINK_SET,0,"1"+g_sOraculstring,"ocpause");
                    else if(type==AKEYO ) llMessageLinked(LINK_ROOT, 0, "PAO_AOON", "ocpause"); 
                    else if(type>1 ) llMessageLinked(LINK_SET, 0, "ZHAO_AOON", "ocpause"); 
                    
                }

                g_iAOSwitch=TRUE;
            } 
            else if (llGetSubString(sMsg,0,8)=="ZHAO_MENU")
            {
                key kMenuTo=(key)llGetSubString(sMsg,10,-1);
                if(type==ORACUL) llMessageLinked(LINK_SET,4,"",kMenuTo);
                else if (type>1) zhaoMenu(kMenuTo);
            }
        } 
    }
    
    link_message(integer iPrim, integer iNum, string sMsg, key kID)
    {
        if (type==ORACUL && iNum==0 && kID!="ocpause") //oracul power command
        {
                g_sOraculstring=llGetSubString(sMsg,1,-1); //store the config string for Oracul AO.
                g_iAOSwitch=(integer)llGetSubString(sMsg,0,1); //store the AO power state.

        }

        else if(type>1) 
        {
            if (sMsg=="ZHAO_SITON") g_iSitOverride=TRUE;
            else if (sMsg=="ZHAO_SITOFF") g_iSitOverride=FALSE;
            else if(kID!="ocpause") //ignore pause commands sent by this script, we want to know what the "correct" state is.
            {
                if(sMsg=="ZHAO_AOON") g_iAOSwitch=TRUE;
                else if(sMsg=="ZHAO_AOOFF")
                {
                    g_iAOSwitch=FALSE;

                }
            }          
        }
    }
    

    
    timer()
    {
        llSetTimerEvent(0);
        llListenRemove(g_iMenuHandle);
        //inform current menu users of listener timeout.
        integer x=llGetListLength(g_lMenuUsers);
        while(x)
        {
            x--;
            key tKey=llList2Key(g_lMenuUsers,x);
            if(llGetAgentSize(tKey)) llRegionSayTo(tKey,0,"AO Menu timed out, try again."); //avoid IM spam by only notifying those in sim.
        }
        g_lMenuUsers=[]; //clear list
    }
    
    changed(integer change)
    {
        if(change & CHANGED_OWNER) llResetScript();
    }  
}
