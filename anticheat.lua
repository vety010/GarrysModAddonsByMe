/*
     ANTI-CHEAT by Okroshka#9292

     Shittiest shit ever however it works.
*/
if SERVER then
     print( "Starting anticheat session" )
     util.AddNetworkString("anticheat_request")
     util.AddNetworkString("anticheat_answer")
     NoxarAntiCheat = {
          Allowed = {
               --SIDS = { "" },
               --GROUPS = { "" }
          },
          Config = {
               Enabled = false, -- Is anti-cheat enabled?
               ScanRoot = false, -- Should anti-cheat punish root players
               ReScanDelay = 5, -- How often should anti-cheat scan players? [in seconds] [x>=1]
               TestMode = true, -- If true, anticheat will print in chat all of players that player is cheater, if false - it'll kick cheater
               fastMode = true, -- If true anticheat will scan only several hooks, otherwise it'll scan all hooks
               SendTime = 30, -- time that script gives to a player to send scan data
               ScanResults = true, -- should anti-cheat scan given data
               BanMode = true
          },
          cache = {
               scanstime = {},
               cresult = {},
               cplayer = {},
               sendtime = -1,
               nowscanning = false,
               lastscan = -1,
               avail = {}
          },
          hooks = {
               [ "HUDPaint" ] = {
                    "BankRS_DrawWarningText",
                    "DebuggerDrawHUD",
                    "DrawHUDIndicators",
                    "DrawHitOption",
                    "DrawNotifications",
                    "DrawRTTexture",
                    "DrawRecordingIcon",
                    "EGP_HUDPaint",
                    "FlashEffect",
                    "HUDPaint_DrawTrunkText",
                    "HUD_DRAW_HUD",
                    "HUD_ORIENTIR_F4",
                    "HudControl",
                    "MG2.HUDPaint.MODULE.NOTIFICATIONS",
                    "MG2.HUDPaint.MODULE.TERRITORIES",
                    "MG2.HUDPaint.PlayerInfo",
                    "PlayerOptionDraw",
                    "VC_HUDPaint",
                    "Wire_DataSocket_DrawLinkHelperLine",
                    "Wire_Socket_DrawLinkHelperLine",
                    "atmosHUDPaint",
                    "fus.hud",
                    "hdn_debugHUD",
                    "wire_draw_world_tips",
                    "wire_gpu_drawhud",
                    "wire_trigger_draw_all_triggers",
                    "Drawing_Crits"
               },
               [ "Think" ] = {
                    "AdminChat.Think",
                    "AdvancedDoorSystem_OpenMenuF2",
                    "DragNDropThink",
                    "E2Helper_KeyListener",
                    "MG2.Think.MODULE.ASSOCIATIONS",
                    "Model31_NEWSyncChanges",
                    "Model32_NEWSyncChanges",
                    "Model33_NEWSyncChanges",
                    "Model34_NEWSyncChanges",
                    "NotificationThink",
                    "RealFrameTime",
                    "SGM_Supra_Functions",
                    "SmartsnapThink",
                    "VC_Think",
                    "VC_Think_Driver",
                    "WireHUDIndicatorCVarCheck",
                    "WireMapInterface_Think",
                    "atmosStormThink",
                    "crsk_2107_SyncChanges",
                    "crsk_i8_SyncChanges",
                    "crsk_model_x_SyncChanges",
                    "delayAmmo",
                    "roadster1sgmSyncChanges",
                    "roadster2sgmSyncChanges",
                    "roadster3sgmSyncChanges",
                    "roadster4sgmSyncChanges",
                    "sandbox_queued_search",
                    "ss_should_draw_both_sides",
                    "supragr1sgmSyncChanges",
                    "supragr2sgmSyncChanges",
                    "supragr3sgmSyncChanges",
                    "DOFThink"
               },
               [ "ShouldDrawLocalPlayer" ] = {
                    "VC_ShouldDrawLocalPlayer"
               },
               [ "RenderScene" ] = {
                    "PeepholesRenderScene",
                    "RenderSuperDoF",
                    "RenderStereoscopy"
               },
               [ "OnEntityCreated" ] = {
                    "ENPC.OnEntityCreated.Jobs",
                    "VC_OnEntityCreated_States",
                    "wire_expression2_extension_player"
               },
               [ "PostDrawOpaqueRenderables" ] = {
                    "CrSkCifrovoiSpeedo",
                    "MG2.TTMarker.PostDrawOpaqueRenderables",
                    "PermaPropsViewer",
                    "WireMapInterface_Draw",
                    "sz_draw"
               },
               [ "player_disconnect" ] = {
                    "DarkRP_ChatIndicator"
               },
               [ "player_hurt" ] = {},
               [ "player_say" ] = {},
               [ "player_connect" ] = {},
               [ "PreDrawViewModel" ] = {},
               [ "PreDrawEffects" ] = {},
               [ "SetupWorldFog" ] = {},
               [ "player_changename" ] = {},
               [ "entity_killed" ] = {},
               [ "gay2" ] = {}
          }
     }
     function NoxarAntiCheat.PunishPlayer( ply, fails, kickonly )
          if not NoxarAntiCheat.Config.Enabled then return end
          fails = fails or 3
          if not IsValid( ply ) then return end
          if ply:IsRoot() then
               if NoxarAntiCheat.Config.ScanRoot == true then oam.ply.notify( ply, 3, 3, "Античит заметил у вас сторонний софт!" ) end
               return true
          end
          if not NoxarAntiCheat.Config.TestMode then
               if NoxarAntiCheat.Config.BanMode == false then 
                    ply:Kick( "Читы ("..fails..")" ) 
               else 
                    if kickonly then 
                         ply:Kick( "Читы ("..fails..")" ) 
                    else
                         ply:Ban(0, true) 
                    end
               end
               return ( not IsValid( ply ) )
          else
               //oam.ply.notify( ply, 3, 3, "Выключайте сторонний софт, если считаете что это ошибка - обратитесь в тех. поддержку" )
               oam.ply.sayStaffAll( ply:Nick().." читер!" )
               return true
          end
     end
     function NoxarAntiCheat.ThinkHook()
          if not NoxarAntiCheat.Config.Enabled then return end
          if ( ( CurTime() - ( NoxarAntiCheat.cache.lastscan or -1) ) >= NoxarAntiCheat.Config.ReScanDelay ) and not NoxarAntiCheat.cache.nowscanning then
               -- Create scan order
               local less = math.huge
               local lessa = {}
               for k,v in pairs( player.GetAll() ) do
                    if IsValid( v ) and NoxarAntiCheat.cache.avail[v:SteamID()] then
                         if not v:IsBot() then
                              if ( NoxarAntiCheat.cache.scanstime[v:SteamID()] or -1 ) <= less then
                                   less = ( NoxarAntiCheat.cache.scanstime[v:SteamID()] or 0 )
                                   lessa = v
                              end
                         end
                    end
               end
               if lessa.SteamID then
                    print( "Starting new ping! "..tostring(lessa.SteamID) )
                    NoxarAntiCheat.cache.cplayer = lessa
                    NoxarAntiCheat.cache.scanstime[lessa:SteamID()] = CurTime()
                    NoxarAntiCheat.cache.nowscanning = true
                    NoxarAntiCheat.cache.lastscan = CurTime()
                    net.Start( "anticheat_request" )
                    NoxarAntiCheat.cache.sendtime = CurTime()
                    net.Send( lessa )
               end
          end
          if NoxarAntiCheat.cache.nowscanning == true then
               if ( CurTime() - NoxarAntiCheat.cache.sendtime ) >= NoxarAntiCheat.Config.SendTime then
                    NoxarAntiCheat.cache.nowscanning = false
                    NoxarAntiCheat.PunishPlayer( NoxarAntiCheat.cache.cplayer, "disconnect", true )
               end
          end
     end

     function NoxarAntiCheat.ScanTable( hookname )
          local fails = 0
          if not NoxarAntiCheat.hooks[hookname] then
               return fails
          end
          local ggwp = false
          for k, v in pairs( NoxarAntiCheat.cache.cresult[hookname] ) do
               if not table.HasValue( NoxarAntiCheat.hooks[hookname], v) then 
                    fails = fails + 1
                    if fails > 0 and not ggwp then
                         print( "Scanning "..hookname..":" )
                         ggwp = true
                    end

                    print( "#"..fails.." - "..v )
                    print( "" )
               end
          end
          return fails
     end

     function NoxarAntiCheat.suicide(ply)
          oam.ply.notify( ply, 3, 3, "Суицид запрещён." )
          return false
     end

     function NoxarAntiCheat.GetAnswer()
          local table = NoxarAntiCheat.cache.cresult
          local ply = NoxarAntiCheat.cache.cplayer
          local fails = 0
          print("")
          print("-----")
          print("Now scanning: "..ply:SteamID())
          print("")
          for k, v in pairs( NoxarAntiCheat.cache.cresult ) do
               if fastMode == true then 
                    if ( table.HasValue( { "HUDPaint", "SetupWorldFog" }, k ) ) then
                         fails = fails + NoxarAntiCheat.ScanTable( k, v )
                    end
               else
                    fails = fails + NoxarAntiCheat.ScanTable( k, v )
               end
          end
          if fails > 0 then
               print( "Total fails of "..ply:SteamID().." are "..fails )
          else
               print( "No fails." )
          end
          if fails > 3 then NoxarAntiCheat.PunishPlayer( NoxarAntiCheat.cache.cplayer, fails ) end
     end
     net.Receive("anticheat_answer", function( len, ply ) 
          if not ( ply:SteamID() == NoxarAntiCheat.cache.cplayer:SteamID() ) then return end
          NoxarAntiCheat.cache.nowscanning = false
          NoxarAntiCheat.cache.cresult = net.ReadTable()
          NoxarAntiCheat.GetAnswer()
     end)
     hook.Add("Think", "anticheat_think_base", NoxarAntiCheat.ThinkHook)
     hook.Add("PlayerConnected", "identifier", function( ply )
          NoxarAntiCheat.cache.avail[ply:SteamID()] = false
          print( "removing avail!" )
     end)
     /*local NonScanNew = { 
          1001,
          1002,
          0
     }
     local NonScanOld = { 
          1001,
          1002,
          0
     }
     hook.Add("PlayerChangedTeam", "anticheat_addavail", function( ply, oldTeam, newTeam )
          if table.HasValue( NonScanNew, newTeam ) or table.HasValue( NonScanOld, oldTeam ) then
               return
          else
               NoxarAntiCheat.cache.avail[ply:SteamID()] = true
               print( "adding new avail!" )
          end
     end)*/
     hook.Add( "PlayerFullLoad", "anticheat_addNewClient", function(ply)
          NoxarAntiCheat.cache.avail[ply:SteamID()] = true
          print( "adding new avail!" )
     end)

     for k,v in pairs( player.GetAll() ) do
          NoxarAntiCheat.cache.avail[v:SteamID()] = true
          print( "adding new avail!" )
     end

     hook.Add("PlayerDisconnected", "anticheal_removeavail", function( ply )
          NoxarAntiCheat.cache.avail[ply:SteamID()] = false
          print( "removing avail!" )
     end)
     hook.Add("CanPlayerSuicide", "restrict_suicide", NoxarAntiCheat.suicide )
else
     function SendAntiCheatAnswer( hooks )
          net.Start( "anticheat_answer" )
               net.WriteTable( hooks )
          net.SendToServer()
     end
     net.Receive( "anticheat_request", function()
          local hooks = hook.GetTable()
          local endtable = {}
          for k, v in pairs( hooks ) do
               endtable[k] = {}
               local i = 0
               for l, b in pairs( v ) do
                    i = i + 1
                    endtable[k][i] = l
                    --if k == "HUDPaint" then print( l ) end
               end
          end
          SendAntiCheatAnswer( endtable )
     end)
end