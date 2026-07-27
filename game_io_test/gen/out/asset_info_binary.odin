package res_binary

// generated asset info (binary) 1784996785738280000
// expected file: io_test_data.bin 


ImageInfo :: struct
{    
    width: int,
	height: int,
    file_type: string,
    bin_offset: int,
    bin_length: int,
}


AudioInfo :: struct
{        
    file_type: string,
    bin_offset: int,
    bin_length: int,
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
	.mouse = { width = 80, height = 92, file_type = ".png", bin_offset = 0, bin_length = 807 },
	.keyboard = { width = 272, height = 92, file_type = ".png", bin_offset = 807, bin_length = 2588 },
	.controller = { width = 192, height = 92, file_type = ".png", bin_offset = 3395, bin_length = 2094 },
	.arrow = { width = 25, height = 25, file_type = ".png", bin_offset = 5489, bin_length = 169 },
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
	.game_03 = { file_type = ".ogg", bin_offset = 5658, bin_length = 2214212 },
	.game_02 = { file_type = ".ogg", bin_offset = 2219870, bin_length = 924117 },
	.game_01 = { file_type = ".ogg", bin_offset = 3143987, bin_length = 609497 },
	.game_00 = { file_type = ".ogg", bin_offset = 3753484, bin_length = 2923535 },
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
	.laserRetro_000 = { file_type = ".ogg", bin_offset = 6677019, bin_length = 12588 },
	.confirmation_002 = { file_type = ".ogg", bin_offset = 6689607, bin_length = 14169 },
	.explosionCrunch_003 = { file_type = ".ogg", bin_offset = 6703776, bin_length = 54824 },
	.open_001 = { file_type = ".ogg", bin_offset = 6758600, bin_length = 9834 },
}


get_MASK_bytes :: proc(bin_data: []u8, id: MASK_ID) -> []u8
{
    info := MASK_Images[id]
    begin := info.bin_offset
    end := begin + info.bin_length
    return bin_data[begin:end]
}


get_MUSIC_bytes :: proc(bin_data: []u8, id: MUSIC_ID) -> []u8
{
    info := MUSIC_Audio[id]
    begin := info.bin_offset
    end := begin + info.bin_length
    return bin_data[begin:end]
}


get_SOUND_bytes :: proc(bin_data: []u8, id: SOUND_ID) -> []u8
{
    info := SOUND_Audio[id]
    begin := info.bin_offset
    end := begin + info.bin_length
    return bin_data[begin:end]
}


