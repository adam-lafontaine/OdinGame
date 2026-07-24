package gen

import fs "../../lib/files"

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
    file_type: string,
	embed_data: []u8,
    bin_offset: int,
    bin_length: int,
}`

STRUCT_AUDIO_ASSET_INFO :: 
`AudioInfo :: struct
{        
    file_type: string,
	embed_data: []u8,
    bin_offset: int,
    bin_length: int,
}`


//ASSETS_DIR :: "../assets"
MASK_DIR :: "../assets/masks"
MUSIC_DIR :: "../assets/music"
SOUND_DIR :: "../assets/sfx"

EMBED_OUTPUT_FILE :: "out/asset_info_embed.odin"

BINARY_OUTPUT_FILE :: "out/io_test_data.bin"
BINARY_INFO_OUTPUT_FILE :: "out/asset_info_binary.odin"


is_image_file :: proc(file_name: string) -> bool
{
    return strings.has_suffix(file_name, ".png")
}


is_audio_file :: proc(file_name: string) -> bool
{
    return strings.has_suffix(file_name, ".ogg")
}


write_file_info_types :: proc(file: ^os.File)
{
    fmt.fprintfln(file, "{}\n\n", STRUCT_IMAGE_ASSET_INFO)    
    fmt.fprintfln(file, "{}\n\n", STRUCT_AUDIO_ASSET_INFO)
}


write_image_file_info_embed :: proc(out: ^os.File, dir: string, name: string)
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

    fmt.fprintfln(out, "{}_ID :: enum", name)
    fmt.fprintfln(out,"{{",)
    for i in file_info
    {
        fmt.fprintfln(out, "    %v,", slashpath.name(i.name))
    }

    fmt.fprintfln(out, "}\n\n")

    fmt.fprintfln(out, "@(rodata)")
    fmt.fprintfln(out, "{0}_Images := [{0}_ID]ImageInfo {{", name)

    fmt_str := "	.%v = {{ width = %v, height = %v, file_type = \"%v\", embed_data = #load(\"%v\") }},"

    for i in file_info
    {
        img, i_err := image.load_from_file(i.fullpath)
        defer image.destroy(img)

        if i_err != nil
        {
            continue
        }

        id := slashpath.name(i.name)
        w := img.width
        h := img.height
        path := i.fullpath
        ft := slashpath.ext(i.name)
        fmt.fprintfln(out, fmt_str, id, w, h, ft, path)
    }

    fmt.fprintfln(out, "}\n\n")
}


write_audio_file_info_embed :: proc(out: ^os.File, dir: string, name: string)
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

    fmt.fprintfln(out, "{}_ID :: enum", name)
    fmt.fprintfln(out,"{{",)
    for i in file_info
    {
        fmt.fprintfln(out, "    %v,", slashpath.name(i.name))
    }

    fmt.fprintfln(out, "}\n\n")

    fmt.fprintfln(out, "@(rodata)")
    fmt.fprintfln(out, "{0}_Audio := [{0}_ID]AudioInfo {{", name)

    fmt_str := "	.%v = {{ file_type = \"%v\", embed_data = #load(\"%v\") }},"

    for i in file_info
    {
        id := slashpath.name(i.name)
        path := i.fullpath
        ft := slashpath.ext(i.name)
        fmt.fprintfln(out, fmt_str, id, ft, path)
    }

    fmt.fprintfln(out, "}\n\n")
}


write_image_file_info_binary :: proc(bin: ^fs.BinaryFile, out: ^os.File, dir: string, name: string)
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

    fmt.fprintfln(out, "{}_ID :: enum", name)
    fmt.fprintfln(out,"{{",)
    for i in file_info
    {
        fmt.fprintfln(out, "    %v,", slashpath.name(i.name))
    }

    fmt.fprintfln(out, "}\n\n")

    fmt.fprintfln(out, "@(rodata)")
    fmt.fprintfln(out, "{0}_Images := [{0}_ID]ImageInfo {{", name)

    fmt_str := "	.%v = {{ width = %v, height = %v, file_type = \"%v\", bin_offset = %v, bin_length = %v }},"

    for i in file_info
    {
        img, i_err := image.load_from_file(i.fullpath)
        defer image.destroy(img)

        byte_data, f_err := os.read_entire_file(i.fullpath, context.allocator)
        defer delete(byte_data)

        if i_err != nil || f_err != nil
        {
            continue
        }

        r, ok := fs.append_binary_file(bin, byte_data)
        if !ok
        {
            continue
        }

        id := slashpath.name(i.name)
        w := img.width
        h := img.height
        ft := slashpath.ext(i.name)
        bo := r.offset
        bl := r.length
        fmt.fprintfln(out, fmt_str, id, w, h, ft, bo, bl)
    }

    fmt.fprintfln(out, "}\n\n")
}


write_audio_file_info_binary :: proc(bin: ^fs.BinaryFile, out: ^os.File, dir: string, name: string)
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

    fmt.fprintfln(out, "{}_ID :: enum", name)
    fmt.fprintfln(out,"{{",)
    for i in file_info
    {
        fmt.fprintfln(out, "    %v,", slashpath.name(i.name))
    }

    fmt.fprintfln(out, "}\n\n")

    fmt.fprintfln(out, "@(rodata)")
    fmt.fprintfln(out, "{0}_Audio := [{0}_ID]AudioInfo {{", name)

    fmt_str := "	.%v = {{ file_type = \"%v\", bin_offset = %v, bin_length = %v }},"

    for i in file_info
    {
        byte_data, f_err := os.read_entire_file(i.fullpath, context.allocator)
        defer delete(byte_data)

        if f_err != nil
        {
            continue
        }

        r, ok := fs.append_binary_file(bin, byte_data)
        if !ok
        {
            continue
        }

        id := slashpath.name(i.name)
        ft := slashpath.ext(i.name)
        bo := r.offset
        bl := r.length
        fmt.fprintfln(out, fmt_str, id, ft, bo, bl)
    }

    fmt.fprintfln(out, "}\n\n")
}


gen_asset_info_embed :: proc()
{
    flags: os.File_Flags = {.Write, .Create, .Trunc}
    
    perm : os.Permissions = {
        .Read_User,
        .Write_User, 
        .Read_Other,
        .Write_Other,
        .Read_Group,
        .Write_Group
    }

    out, _ := os.open(EMBED_OUTPUT_FILE, flags, perm)
	defer os.close(out)

    fmt.fprintfln(out, "package res_temp\n\n")

    write_file_info_types(out)
    write_image_file_info_embed(out, MASK_DIR, "MASK")
    write_audio_file_info_embed(out, MUSIC_DIR, "MUSIC")
    write_audio_file_info_embed(out, SOUND_DIR, "SOUND")
}


gen_asset_info_binary :: proc()
{
    flags: os.File_Flags = {.Write, .Create, .Trunc}
    
    perm : os.Permissions = {
        .Read_User,
        .Write_User, 
        .Read_Other,
        .Write_Other,
        .Read_Group,
        .Write_Group
    }

    out, _ := os.open(BINARY_INFO_OUTPUT_FILE, flags, perm)
	defer os.close(out)

    bin := fs.create_binary_file(BINARY_OUTPUT_FILE)
    if !bin.ok
    {
        assert(false, "*** CREATE BINARY ***")
    }
    defer fs.close_binary_file(&bin)

    fmt.fprintfln(out, "package res_temp\n\n")

    write_file_info_types(out)
    write_image_file_info_binary(&bin, out, MASK_DIR, "MASK")
    write_audio_file_info_binary(&bin, out, MUSIC_DIR, "MUSIC")
    write_audio_file_info_binary(&bin, out, SOUND_DIR, "SOUND")
}


main :: proc() 
{
    //gen_asset_info_embed()
    gen_asset_info_binary()


}