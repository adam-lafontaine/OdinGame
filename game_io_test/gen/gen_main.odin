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
    width: int,
	height: int,
	data: []u8,
    file_type: string,
}`

STRUCT_AUDIO_ASSET_INFO :: 
`AudioInfo :: struct
{    
    data: []u8,
    file_type: string,
}`


//ASSETS_DIR :: "../assets"
MASK_DIR :: "../assets/masks"
MUSIC_DIR :: "../assets/music"
SOUND_DIR :: "../assets/sfx"
OUTPUT_FILE :: "out/temp_asset_info.odin"


is_image_file :: proc(file_name: string) -> bool
{
    return strings.has_suffix(file_name, ".png")
}


is_audio_file :: proc(file_name: string) -> bool
{
    return strings.has_suffix(file_name, ".ogg")
}


write_file_info_types :: proc(file: $F)
{
    fmt.fprintfln(file, "{}\n\n", STRUCT_IMAGE_ASSET_INFO)    
    fmt.fprintfln(file, "{}\n\n", STRUCT_AUDIO_ASSET_INFO)
}


write_image_file_info :: proc(out: $F, dir: string, name: string)
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
    defer delete(file_info)

    for i in input_files
    {
        // filter file types
        if is_image_file(i.name)
        {
            append(&file_info, i)
        }
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

    fmt_str := "	.%v = {{ width = %v, height = %v, data = #load(\"%v\"), file_type = \"%v\" }},"

    for i in file_info
    {
        img, i_err := image.load_from_file(i.fullpath)
        if i_err == nil
        {
            id := slashpath.name(i.name)
            w := img.width
            h := img.height
            path := i.fullpath
            ft := slashpath.ext(i.name)
            fmt.fprintfln(out, fmt_str, id, w, h, path, ft)
        }
        image.destroy(img)
    }

    fmt.fprintfln(out, "}\n\n")
}


write_audio_file_info :: proc(out: $F, dir: string, name: string)
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
    defer delete(file_info)

    for i in input_files
    {
        // filter file types
        if is_audio_file(i.name)
        {
            append(&file_info, i)
        }
    }

    fmt.fprintfln(out, "{}_Name :: enum", name)
    fmt.fprintfln(out,"{{",)
    for i in file_info
    {
        fmt.fprintfln(out, "    %v,", slashpath.name(i.name))
    }

    fmt.fprintfln(out, "}\n\n")

    fmt.fprintfln(out, "@(rodata)")
    fmt.fprintfln(out, "{0}_Audio := [{0}_Name]AudioInfo {{", name)

    fmt_str := "	.%v = {{ data = #load(\"%v\"), file_type = \"%v\" }},"

    for i in file_info
    {
        id := slashpath.name(i.name)
        path := i.fullpath
        ft := slashpath.ext(i.name)
        fmt.fprintfln(out, fmt_str, id, path, ft)
    }

    fmt.fprintfln(out, "}\n\n")
}


main :: proc() 
{
    out, _ := os.open(OUTPUT_FILE, {.Write, .Create, .Trunc}, {.Write_User, .Read_Other, .Read_Group})
	defer os.close(out)

    fmt.fprintfln(out, "package res_temp\n\n")

    write_file_info_types(out)
    write_image_file_info(out, MASK_DIR, "MASK")
    write_audio_file_info(out, MUSIC_DIR, "MUSIC")
    write_audio_file_info(out, SOUND_DIR, "SOUND")


}