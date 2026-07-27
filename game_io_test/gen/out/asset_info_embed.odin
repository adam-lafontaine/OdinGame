package res_embed

// generated asset info (embedded) 1784996785738280000


ImageInfo :: struct
{    
    width: int,
	height: int,
    file_type: string,
	embed_data: []u8,
}


AudioInfo :: struct
{        
    file_type: string,
	embed_data: []u8,
}


MASK_ID :: enum
{
    mouse,
    keyboard,
    controller,
    arrow,
}


@(rodata)
MASK_Images := [MASK_ID]ImageInfo {
	.mouse = { width = 80, height = 92, file_type = ".png", embed_data = #load("/home/adam/Repos/OdinGame/game_io_test/assets/masks/mouse.png") },
	.keyboard = { width = 272, height = 92, file_type = ".png", embed_data = #load("/home/adam/Repos/OdinGame/game_io_test/assets/masks/keyboard.png") },
	.controller = { width = 192, height = 92, file_type = ".png", embed_data = #load("/home/adam/Repos/OdinGame/game_io_test/assets/masks/controller.png") },
	.arrow = { width = 25, height = 25, file_type = ".png", embed_data = #load("/home/adam/Repos/OdinGame/game_io_test/assets/masks/arrow.png") },
}


MUSIC_ID :: enum
{
    game_03,
    game_02,
    game_01,
    game_00,
}


@(rodata)
MUSIC_Audio := [MUSIC_ID]AudioInfo {
	.game_03 = { file_type = ".ogg", embed_data = #load("/home/adam/Repos/OdinGame/game_io_test/assets/music/game_03.ogg") },
	.game_02 = { file_type = ".ogg", embed_data = #load("/home/adam/Repos/OdinGame/game_io_test/assets/music/game_02.ogg") },
	.game_01 = { file_type = ".ogg", embed_data = #load("/home/adam/Repos/OdinGame/game_io_test/assets/music/game_01.ogg") },
	.game_00 = { file_type = ".ogg", embed_data = #load("/home/adam/Repos/OdinGame/game_io_test/assets/music/game_00.ogg") },
}


SOUND_ID :: enum
{
    laserRetro_000,
    confirmation_002,
    explosionCrunch_003,
    open_001,
}


@(rodata)
SOUND_Audio := [SOUND_ID]AudioInfo {
	.laserRetro_000 = { file_type = ".ogg", embed_data = #load("/home/adam/Repos/OdinGame/game_io_test/assets/sfx/laserRetro_000.ogg") },
	.confirmation_002 = { file_type = ".ogg", embed_data = #load("/home/adam/Repos/OdinGame/game_io_test/assets/sfx/confirmation_002.ogg") },
	.explosionCrunch_003 = { file_type = ".ogg", embed_data = #load("/home/adam/Repos/OdinGame/game_io_test/assets/sfx/explosionCrunch_003.ogg") },
	.open_001 = { file_type = ".ogg", embed_data = #load("/home/adam/Repos/OdinGame/game_io_test/assets/sfx/open_001.ogg") },
}


get_MASK_bytes :: proc(id: MASK_ID) -> []u8
{
    return MASK_Images[id].embed_data
}


get_MUSIC_bytes :: proc(id: MUSIC_ID) -> []u8
{
    return MUSIC_Audio[id].embed_data
}


get_SOUND_bytes :: proc(id: SOUND_ID) -> []u8
{
    return SOUND_Audio[id].embed_data
}


