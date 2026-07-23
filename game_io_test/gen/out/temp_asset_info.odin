package res_temp


ImageInfo :: struct
{
    //file_type: string,
    width: int,
	height: int,
	data: []u8,
}


AudioInfo :: struct
{
    file_type_string,
    data: []u8
}


Mask_Name :: enum
{
    mouse,
    keyboard,
    controller,
    arrow,
}


@(rodata)
Mask_Images := [Mask_Name]ImageInfo {
	.mouse = { width = 80, height = 92, data = #load("/home/adam/Repos/OdinGame/game_io_test/assets/masks/mouse.png") },
	.keyboard = { width = 272, height = 92, data = #load("/home/adam/Repos/OdinGame/game_io_test/assets/masks/keyboard.png") },
	.controller = { width = 192, height = 92, data = #load("/home/adam/Repos/OdinGame/game_io_test/assets/masks/controller.png") },
	.arrow = { width = 25, height = 25, data = #load("/home/adam/Repos/OdinGame/game_io_test/assets/masks/arrow.png") },
}


