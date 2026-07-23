package res_temp


ImageInfo :: struct
{    
    width: int,
	height: int,
	data: []u8,
    file_type: string,
}


AudioInfo :: struct
{    
    data: []u8,
    file_type: string,
}


MASK_Name :: enum
{
    mouse,
    keyboard,
    controller,
    arrow,
}


@(rodata)
MASK_Images := [MASK_Name]ImageInfo {
	.mouse = { width = 80, height = 92, data = #load("/home/adam/Repos/OdinGame/game_io_test/assets/masks/mouse.png"), file_type = ".png" },
	.keyboard = { width = 272, height = 92, data = #load("/home/adam/Repos/OdinGame/game_io_test/assets/masks/keyboard.png"), file_type = ".png" },
	.controller = { width = 192, height = 92, data = #load("/home/adam/Repos/OdinGame/game_io_test/assets/masks/controller.png"), file_type = ".png" },
	.arrow = { width = 25, height = 25, data = #load("/home/adam/Repos/OdinGame/game_io_test/assets/masks/arrow.png"), file_type = ".png" },
}


MUSIC_Name :: enum
{
    game_03,
    game_02,
    game_01,
    game_00,
}


@(rodata)
MUSIC_Audio := [MUSIC_Name]AudioInfo {
	.game_03 = { data = #load("/home/adam/Repos/OdinGame/game_io_test/assets/music/game_03.ogg"), file_type = ".ogg" },
	.game_02 = { data = #load("/home/adam/Repos/OdinGame/game_io_test/assets/music/game_02.ogg"), file_type = ".ogg" },
	.game_01 = { data = #load("/home/adam/Repos/OdinGame/game_io_test/assets/music/game_01.ogg"), file_type = ".ogg" },
	.game_00 = { data = #load("/home/adam/Repos/OdinGame/game_io_test/assets/music/game_00.ogg"), file_type = ".ogg" },
}


SOUND_Name :: enum
{
    laserRetro_000,
    confirmation_002,
    explosionCrunch_003,
    open_001,
}


@(rodata)
SOUND_Audio := [SOUND_Name]AudioInfo {
	.laserRetro_000 = { data = #load("/home/adam/Repos/OdinGame/game_io_test/assets/sfx/laserRetro_000.ogg"), file_type = ".ogg" },
	.confirmation_002 = { data = #load("/home/adam/Repos/OdinGame/game_io_test/assets/sfx/confirmation_002.ogg"), file_type = ".ogg" },
	.explosionCrunch_003 = { data = #load("/home/adam/Repos/OdinGame/game_io_test/assets/sfx/explosionCrunch_003.ogg"), file_type = ".ogg" },
	.open_001 = { data = #load("/home/adam/Repos/OdinGame/game_io_test/assets/sfx/open_001.ogg"), file_type = ".ogg" },
}


