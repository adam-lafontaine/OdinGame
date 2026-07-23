package gen

import "core:os"
import "core:strings"
import "core:fmt"
import "core:path/slashpath"
import "core:image/png"
import "core:image"

// Avoids 'unused import' error: "core:image/png" needs to be imported in order
// to make `img.load_from_bytes` understand PNG format.
_ :: png


STRUCT_IMAGE_ASSET_INFO :: 
`ImageInfo :: struct
{
    //file_type: string,
    width: int,
	height: int,
	data: []u8,
}`

STRUCT_AUDIO_ASSET_INFO :: 
`AudioInfo :: struct
{
    file_type_string,
    data: []u8
}`


//ASSETS_DIR :: "../assets"
MASK_DIR :: "../assets/masks"
MUSIC_DIR :: "../assets/music"
SOUND_DIR :: "../assets/sfx"
OUTPUT_FILE :: "out/temp_asset_info.odin"


write_info_types :: proc(file: $F)
{
    fmt.fprintfln(file, "{}\n\n", STRUCT_IMAGE_ASSET_INFO)    
    fmt.fprintfln(file, "{}\n\n", STRUCT_AUDIO_ASSET_INFO)
}


write_image_info :: proc(out: $F, dir: string, name: string)
{
    d, d_err := os.open(dir)
    if d_err != nil
    {
        fmt.fprintfln(out, "ERR: {}", dir)
        return
    }

    defer os.close(d)

    input_files, _ := os.read_dir(d, -1, context.allocator)

    file_info: [dynamic]os.File_Info

    for i in input_files
    {
        if !strings.has_suffix(i.name, ".png")
        {
            continue
        }

        append(&file_info, i)
    }

    fmt.fprintfln(out, "{}_Name :: enum", name)
    fmt.fprintfln(out,"{{",)
    for i in file_info
    {
        fmt.fprintfln(out, "    %v,", slashpath.name(i.name))
    }

    fmt.fprintfln(out, "}\n\n")


    fmt.fprintfln(out, "@(rodata)")
    fmt.fprintfln(out, "{0}_Images := [{0}_Name]ImageInfo {{", name)
    for i in file_info
    {
        img, i_err := image.load_from_file(i.fullpath)
        if i_err == nil
        {
            id := slashpath.name(i.name)
            w := img.width
            h := img.height
            path := i.fullpath
            fmt.fprintfln(out, "	.%v = {{ width = %v, height = %v, data = #load(\"%v\") }},", id, w, h, path)
        }
        image.destroy(img)
    }

    fmt.fprintfln(out, "}\n\n")
}


main :: proc() 
{
    out, _ := os.open(OUTPUT_FILE, {.Write, .Create, .Trunc}, {.Write_User, .Read_Other, .Read_Group})
	defer os.close(out)

    fmt.fprintfln(out, "package res_temp\n\n")

    write_info_types(out)
    write_image_info(out, MASK_DIR, "Mask")


}