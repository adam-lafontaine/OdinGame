#+private
package window

import rl "vendor:raylib"

import "core:math"


/* screen memory */

ScreenMemory :: struct
{
    window_title: cstring,
    target: rl.RenderTexture2D,
    screen_pixels: rl.Image,

    screen_rect: rl.Rectangle,
    render_rect: rl.Rectangle,
}


destroy_screen_texture :: proc(screen: ^ScreenMemory)
{
    rl.UnloadRenderTexture(screen.target)
    rl.UnloadImage(screen.screen_pixels)
}


destroy_screen_memory :: proc(screen: ^ScreenMemory)
{
    destroy_screen_texture(screen)
    rl.CloseWindow()
}


create_screen_window :: proc(screen: ^ScreenMemory, title: cstring, width: u32, height: u32) -> bool
{
    w := cast(i32)width
    h := cast(i32)height

    flags: rl.ConfigFlags
    flags = { .WINDOW_RESIZABLE, .VSYNC_HINT }

    rl.SetConfigFlags(flags)
    rl.InitWindow(w, h, title)

    screen.window_title = title

    ok := rl.IsWindowReady()

    assert(ok, "*** create_screen_window() ***")

    return ok
}


create_screen_window_fullscreen :: proc(screen: ^ScreenMemory, title: cstring) -> bool
{
    flags: rl.ConfigFlags
    flags = { .WINDOW_RESIZABLE, .VSYNC_HINT }

    rl.SetConfigFlags(flags)
    rl.InitWindow(0, 0, title)

    screen.window_title = title

    ok := rl.IsWindowReady()

    assert(ok, "*** create_screen_window_fullscreen() ***")

    return ok
}


create_screen_texture :: proc(screen: ^ScreenMemory, width: u32, height: u32) -> bool
{
    w := cast(i32)width
    h := cast(i32)height

    screen.target = rl.LoadRenderTexture(w, h)
    rl.SetTextureFilter(screen.target.texture, rl.TextureFilter.BILINEAR);

    ok := rl.IsRenderTextureValid(screen.target)

    assert(ok, "*** create_screen_texture() ***")

    if (!ok)
    {
        return false;
    }

    screen.screen_pixels = rl.GenImageColor(w, h, rl.BLACK)

    tx := &screen.target.texture
    px := & screen.screen_pixels

    ok &= px.data != nil
    ok &= px.width == tx.width
    ok &= px.height == tx.height
    ok &= px.format == rl.PixelFormat.UNCOMPRESSED_R8G8B8A8

    assert(ok, "*** create_screen_texture() ***")    

    return ok
}


create_screen_memory :: proc(screen: ^ScreenMemory, title: cstring, window_size: Vec2Du32, pixel_size: Vec2Du32) -> bool
{
    ok := true;

    ok &= create_screen_window(screen, title, window_size.x, window_size.y)
    ok &= create_screen_texture(screen, pixel_size.x, pixel_size.y)

    if (!ok)
    {
        destroy_screen_memory(screen);
    }

    return ok
}


create_screen_memory_fullscreen :: proc(screen: ^ScreenMemory, title: cstring, pixel_size: Vec2Du32) -> bool
{
    ok := true;

    ok &= create_screen_window_fullscreen(screen, title)
    ok &= create_screen_texture(screen, pixel_size.x, pixel_size.y)

    if (!ok)
    {
        destroy_screen_memory(screen);
    }

    return ok
}


/* stack data */


ScreenID :: distinct int

N_SCREEN_MEMORY :: ScreenID(2)

screen_data := [N_SCREEN_MEMORY]ScreenMemory{}

screen_data_id := ScreenID(0)


/* helpers */


allocate_screen_memory :: proc() -> ScreenID
{
    if (screen_data_id >= N_SCREEN_MEMORY)
    {
        return -1
    }

    screen_data_id += 1

    return screen_data_id
}


get_screen_by_id :: proc(id: ScreenID) -> ^ScreenMemory
{
    if (id < 0 || id >= N_SCREEN_MEMORY)
    {
        return nil
    }

    return &screen_data[id]
}


get_screen :: proc(window: ^Window) -> ^ScreenMemory
{
    id := cast(ScreenID)window.handle
    return get_screen_by_id(id)
}


set_window_pixels :: proc(screen: ^ScreenMemory, window: ^Window)
{
    pixels := screen.screen_pixels

    window.pixel_buffer = (^u32)(pixels.data)
    window.width_px = cast(u32)pixels.width
    window.height_px = cast(u32)pixels.height
}


set_screen_rect :: proc(screen: ^ScreenMemory, rotate: Rotate)
{
    screen.screen_rect = {
        x = 0.0,
        y = 0.0,
        width = cast(f32)screen.screen_pixels.width,
        height = cast(f32)screen.screen_pixels.height,
    }

    switch rotate
    {
    case .CounterClockwise_90:
        screen.screen_rect.height *= -1

    case .Clockwise_90, .None:
    }
}


resize_render_rect :: proc(screen: ^ScreenMemory, rotate: Rotate)
{
    set_screen_rect(screen, rotate)
    
    w_src := screen.screen_rect.width
    h_src := math.abs(screen.screen_rect.height)

    w_rot := w_src
    h_rot := h_src

    if rotate != .None
    {
        w_rot = h_src
        h_rot = w_src
    }

    w_out := cast(f32)rl.GetScreenWidth()
    h_out := cast(f32)rl.GetScreenHeight()

    w_scale := w_out / w_rot
    h_scale := h_out / h_rot
    scale := math.min(w_scale, h_scale)

    w_dst := scale * w_rot
    h_dst := scale * h_rot    

    r_dst: rl.Rectangle = {
        x = (w_out - w_dst) / 2,
        y = (h_out - h_dst) / 2,
        width = w_dst,
        height = h_dst
    }

    screen.render_rect = r_dst
}


render_screen_memory :: proc(screen: ^ScreenMemory)
{
    origin : rl.Vector2 = { 0, 0 }
    tint := rl.WHITE
    angle := cast(f32)0

    rl.UpdateTexture(screen.target.texture, screen.screen_pixels.data)

    rl.BeginDrawing()

    rl.ClearBackground(rl.BLACK)

    rl.DrawTexturePro(
        screen.target.texture,
        screen.screen_rect,
        screen.render_rect,
        origin,
        angle,
        tint
    )

    rl.EndDrawing()
}


/* api for the api */

api_create :: proc(window: ^Window, title: cstring, window_size: Vec2Du32, pixel_size: Vec2Du32) -> bool
{
    id := allocate_screen_memory()

    if (id < -1)
    {
        assert(false, "*** SCREEN NOT ALLOCATED ***")
        return false
    }

    screen := get_screen_by_id(id)
    if (screen == nil)
    {
        assert(false, "*** NO SCREEN ***")
        return false
    }

    if (!create_screen_memory(screen , title, window_size, pixel_size))
    {
        assert(false, "*** SCREEN MEMORY ***")
        return false
    }

    rotate := Rotate.None
    window.handle = cast(i32)id

    set_window_pixels(screen, window)
    resize_render_rect(screen, rotate)

    return true
}


api_create_rotated :: proc(window: ^Window, title: cstring, window_size: Vec2Du32, pixel_size: Vec2Du32, rotate: Rotate) -> bool
{
    id := allocate_screen_memory()

    if (id < -1)
    {
        assert(false, "*** SCREEN NOT ALLOCATED ***")
        return false
    }

    screen := get_screen_by_id(id)
    if (screen == nil)
    {
        return false
    }

    if (!create_screen_memory(screen , title, window_size, pixel_size))
    {
        return false
    }

    window.handle = cast(i32)id
    set_window_pixels(screen, window)
    resize_render_rect(screen, rotate)

    return true
}


api_create_fullscreen :: proc(window: ^Window, title: cstring, pixel_size: Vec2Du32) -> bool
{
    id := allocate_screen_memory()

    if (id < -1)
    {
        assert(false, "*** SCREEN NOT ALLOCATED ***")
        return false
    }

    screen := get_screen_by_id(id)
    if (screen == nil)
    {
        return false
    }

    if (!create_screen_memory_fullscreen(screen , title, pixel_size))
    {
        return false
    }

    rotate := Rotate.None
    window.handle = cast(i32)id
    
    set_window_pixels(screen, window)
    resize_render_rect(screen, rotate)

    return true
}


api_create_fullscreen_rotated :: proc(window: ^Window, title: cstring, pixel_size: Vec2Du32, rotate: Rotate) -> bool
{
    id := allocate_screen_memory()

    if (id < -1)
    {
        assert(false, "*** SCREEN NOT ALLOCATED ***")
        return false
    }

    screen := get_screen_by_id(id)
    if (screen == nil)
    {
        return false
    }

    if (!create_screen_memory_fullscreen(screen , title, pixel_size))
    {
        return false
    }

    window.handle = cast(i32)id
    set_window_pixels(screen, window)
    resize_render_rect(screen, rotate)

    return true
}


api_set_window_icon :: proc(window: ^Window)
{
    assert(false, "*** NOT IMPLEMENTED ***")
}


api_destroy :: proc(window: ^Window)
{
    screen := get_screen(window)
    destroy_screen_memory(screen)
    window.handle = -1
}


api_resize_pixel_buffer :: proc(window: ^Window, width: u32, height: u32) -> bool
{
    screen := get_screen(window)
    pixels := screen.screen_pixels

    w := cast(i32)width
    h := cast(i32)height

    if (w == pixels.width && h == pixels.height)
    {
        return true
    }

    destroy_screen_texture(screen)
    if (!create_screen_texture(screen, width, height))
    {
        return false
    }

    set_window_pixels(screen, window)

    return true
}


api_render :: proc(window: ^Window, size_changed: b32)
{
    screen := get_screen(window)
    rotate := Rotate.None

    if (size_changed)
    {
        resize_render_rect(screen, rotate)
    }

    render_screen_memory(screen)
}


api_render_rotated :: proc(window: ^Window, rotate: Rotate, size_changed: b32)
{
    screen := get_screen(window)

    if (size_changed)
    {
        resize_render_rect(screen, rotate)
    }

    render_screen_memory(screen)
}


api_hide_mouse_cursor :: proc()
{
    rl.HideCursor()
}


api_show_mouse_cursor :: proc()
{
    rl.ShowCursor()
}


api_set_white :: proc(window: ^Window)
{
    screen := get_screen(window)
    pixels := &screen.screen_pixels

    rl.ImageClearBackground(pixels, rl.RAYWHITE)
}


api_set_black :: proc(window: ^Window)
{
    screen := get_screen(window)
    pixels := &screen.screen_pixels

    rl.ImageClearBackground(pixels, rl.BLACK)
}

