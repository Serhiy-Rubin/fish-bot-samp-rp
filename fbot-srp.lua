script_author("Serhiy_Rubin")
script_properties("work-in-pause")
script_version("2101171")
local memory = require 'memory'
local sampev = require 'lib.samp.events'
local dlstatus = require("moonloader").download_status
local bot = { fish = false, cook = false, worm = false }
local timestamp = { fish = 0, cook = 0, worm = 0 }
local non_stop = { wait = 1000, anim = 0, time = 0 }
local true_send = true
local TextSearch = " Рыба сорвалась и оборвала снасти!\n Вы оснастили удочку!\n Вы наживили червя!\n Внимательно следите за поплавком, когда поплавок опустится, подсекайте!\n Рыба сорвалась!\n Вы ничего не поймали!" 
local TextFISHoff = " У вас нет червей. Червей можно накопать на ферме!\n У вас нет снастей. Купите снасти в магазине!"
local TextWORMoff = " Кажется, тут неудачное место для поиска!\n В транспорте нельзя"
local TextCOOKoff = " Требуется 20000 грамм рыбы\n С собой может быть максимум 100 пачек рыбы"
local red_fish = false
local antipause_status = false
local dialogFunc = {
	[1175] = { 
		[1] = function()
			bot.fish = not bot.fish
	    	timestamp.fish = os.clock() * 1000
	    	non_stop.wait = 0
	    	true_send = true
	    	antipause()
			printStringNow((bot.fish and '~G~Fish BOT - ON' or '~R~Fish Bot - OFF'), 1000)
		end,
		[2] = function()
			if not bot.cook then bot.worm = false end
			antipause()
			bot.cook = not bot.cook
			antipause()
			printStringNow((bot.fish and '~G~Fish COOK - ON' or '~R~Fish COOK - OFF'), 1000)
		end,
		[3] = function()
			if not bot.worm then bot.cook = false end
			bot.worm = not bot.worm
			antipause()
			printStringNow((bot.worm and '~G~Find Worm - ON' or '~R~Find Worm - OFF'), 1000)
		end,
		[4] = function()
			red_fish = not red_fish
			ShowDialog()
		end
	}
}

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	while not isSampAvailable() do wait(100) end
	check_version("https://raw.githubusercontent.com/Serhiy-Rubin/fish-bot-samp-rp/main/version")
	while true do
		wait(0)
		doNonStop()
		doDialogCheck()
		doFish()
		doCook()
		doFindWorm()
    end
end

function doNonStop()
	if not bot.fish then return end
	local _, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
	local animid = sampGetPlayerAnimationId(myId)
	if non_stop.animid == non_stop.anim then
	  	if (os.time() - non_stop.time) >= 3 then
	  		sendKey(1024)
	  		non_stop.time = os.time()
	  	end 
	else
		non_stop.time = os.time()
	  	non_stop.anim = animid
	end
end

function doDialogCheck()
	local result, button, list, input = sampHasDialogRespond(1175)
    if result and button == 1 and sampGetDialogCaption() == '{a1a1a1}Fish bot for SRP' then
    	dialogFunc[1175][list + 1]()
    end
end

function doFish()
	if not bot.fish then return end
	if true_send and (os.clock() * 1000) - timestamp.fish > non_stop.wait then
		timestamp.fish = os.clock() * 1000
		true_send = false
		sendKey(1024)
	end
end

function doCook()
	if not bot.cook then return end
	if (os.clock() * 1000) - timestamp.cook > 650 then
		timestamp.cook = os.clock() * 1000
		sampSendChat("/fish cook")
	end
end

function doFindWorm()
	if not bot.worm then return end
	if (os.clock() * 1000) - timestamp.worm > 650 then
		if worm_now ~= nil then
			if os.time() - worm_now > 6 then
				bot.worm = false
				printStringNow((bot.worm and '~G~Find Worm - ON' or '~R~Find Worm - OFF'), 1000)
			end
		end
		timestamp.worm = os.clock() * 1000
		sampSendChat("/fish findworm")
	end
end

function sampev.onSendCommand(cmd)
	if cmd:lower() == "/fbot" then 
		ShowDialog() 
		return false 
	end
end

function sampev.onDisplayGameText(style, time, text)
	if bot.fish then
		if text == "~b~!" or text == "~n~~g~!" then true_send = false end
    	if text ==  "~n~~n~~y~!" or ( red_fish and text == "~n~~n~~n~~r~!" ) then
    		non_stop.wait = math.random(50, 100)
    		true_send = true
    	end
  	end
end

function sampev.onServerMessage(color, text)
	if bot.fish then
	    if string.find(text, "Вы поймали") or string.find(TextSearch, text) then
	    	timestamp.fish = os.clock() * 1000
	    	non_stop.wait = math.random(2000, 2500)
	    	true_send = true
	    end
	    if string.find(TextFISHoff, text) then
	    	true_send = false
	    	bot.fish = false
	    	if sampIsDialogActive() and sampGetDialogCaption() == 'Fish BOT' then
	    		ShowDialog()
	    	end
	    end
	end
	if bot.cook then
	    if string.find(TextCOOKoff, text) then
	    	bot.cook = false
	    	if sampIsDialogActive() and sampGetDialogCaption() == 'Fish BOT' then
	    		ShowDialog()
	    	end
	    end
	end
	if bot.worm then
	    if text == ' Вы нашли 10 червей!' or text == ' Нужно поискать еще раз!' then
	    	worm_now = os.time()
	    end
	    if string.find(TextWORMoff, text) then
	    	bot.worm = false
	    	if sampIsDialogActive() and sampGetDialogCaption() == 'Fish BOT' then
	     		ShowDialog()
	    	end
	    end
	end
end

function ShowDialog()
	local dialog_text = {}
	dialog_text[#dialog_text + 1] = '[1] '..(bot.fish and 'Выключить бот рыбака' or 'Включить бот рыбака')
	dialog_text[#dialog_text + 1] = '[2] '..(bot.cook and 'Остановить приготовление рыбы' or 'Запустить приготовление рыбы')
	dialog_text[#dialog_text + 1] = '[3] '..(bot.worm and 'Остановить поиск червей' or 'Запустить поиск червей')
	dialog_text[#dialog_text + 1] = '[4] Ловить рыбу на '..(red_fish and 'желтый и красный поплавок' or 'желтый поплавок')
	dialog_text[#dialog_text + 1] = ' '
	dialog_text[#dialog_text + 1] = '\tАвтор скрипта: Serhiy_Rubin'
	dialog_text[#dialog_text + 1] = '\tГруппа со скриптами: vk.com/rubin.mods'
	local text = ''
	for k,v in pairs(dialog_text) do
		text = text..v..'\n'
	end
	sampShowDialog(1175, "{a1a1a1}Fish bot for SRP", text, "Выбрать", "Закрыть", 2)
end

function sendKey(key)
    local _, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
    local data = allocateMemory(68)
    sampStorePlayerOnfootData(myId, data)
    setStructElement(data, 4, 2, key, false)
    sampSendOnfootData(data)
    freeMemory(data)
end

function antipause()
	if (bot.fish or bot.worm or bot.cook) and not antipause_status then
		antipause_status = true
		memory.setuint8(7634870, 1) 
		memory.setuint8(7635034, 1)
		memory.fill(7623723, 144, 8)
		memory.fill(5499528, 144, 6)
		memory.fill(0x00531155, 0x90, 5, true)
	else
		antipause_status = false
		memory.setuint8(7634870, 0)
		memory.setuint8(7635034, 0)
		memory.hex2bin('5051FF1500838500', 7623723, 8)
		memory.hex2bin('0F847B010000', 5499528, 6)
	end 
end

function check_version(url)
    local response_path = os.tmpname()
    downloadUrlToFile(url, response_path, function(id, status, p1, p2)
        if status == dlstatus.STATUSEX_ENDDOWNLOAD then
			if doesFileExist(response_path) then
                local f = io.open(response_path, "r")
                if f then
                    local text = f:read("*a")
                    if text ~= nil then
                    	if not string.find(text, tostring(thisScript().version)) then
                    		sampAddChatMessage( "["..string.upper(thisScript().name).."]: Найдена новая версия. Найти её можно в группе автора. >> vk.com/rubin.mods", 0xca0147)
                    	end
                    end
                    f:close()
                    os.remove(response_path)
                end
            end
        end
    end)
end