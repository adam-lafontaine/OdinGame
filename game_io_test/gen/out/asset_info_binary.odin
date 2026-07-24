package res_temp


ImageInfo :: struct
{    
    width: int,
	height: int,
    file_type: string,
	embed_data: []u8,
    bin_offset: int,
    bin_length: int,
}


AudioInfo :: struct
{        
    file_type: string,
	embed_data: []u8,
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


