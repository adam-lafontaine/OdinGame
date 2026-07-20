#+private
package app

import "core:math"
import "core:thread"

import "../../res"
import img "../../../lib/image_view"
import mb "../../../lib/memory_buffer"
import "../../../lib/io/audio"


/* screen dimensions */

screen_dimensions_res :: proc() -> Vec2Du32
{
    /*
    | gpd1 gpd2 |
    | kbd   mse |
    */

    // Need screen dimensions before loading assets

    g := res.masks[.gamepad]
    k := res.masks[.keyboard]
    m := res.masks[.mouse]

    w := math.max(g.width * 2, k.width + m.width)
    h := math.max(g.height + k.height, g.height + m.height)

    dims := Vec2Du32 { w, h }

    return dims
}


screen_dimensions_masks :: proc(masks: MaskViewData) -> Vec2Du32
{
    g := masks.gamepad_view
    k := masks.keyboard_view    
    m := masks.mouse_view

    w := math.max(g.width * 2, k.width + m.width)
    h := math.max(g.height + k.height, g.height + m.height)

    dims := Vec2Du32 { w, h }

    return dims
}


screen_dimensions :: proc {
    screen_dimensions_res,
    screen_dimensions_masks
}


StateUpdateProc :: proc(state: ^AppState, input: Input)


/* state */

StateData :: struct
{
    masks: MaskViewData,
    // music
    // sounds
    asset_memory: AssetMemory,
    asset_thread: ^thread.Thread,
    asset_load_complete: bool,

    mask_views: MaskViewMapList,
    inputs: InputList,
    
    out_view: ImageView,

    buffer8: img.Buffer8,

    state_update: StateUpdateProc,
}


get_data :: proc(state: ^AppState) -> ^StateData
{
    return cast(^StateData)state.data
}


destroy_state_data ::proc(state: ^AppState)
{
    data := get_data(state)

    img.destroy_buffer8(&data.buffer8)

    free(state.data)
}


create_state_data :: proc(state: ^AppState) -> bool
{
    state_data, err := new(StateData)
    if err != nil
    {
        return false
    }

    state.data = cast(StateDataRef)state_data

    return true
}


/* assets */


process_asset_memory :: proc(data: ^StateData) -> AssetStatus
{
    am := &data.asset_memory
    buffer := &data.buffer8

    if am.status != .Process
    {
        return am.status
    }

    n_pixels := mask_view_pixel_count(am^)
    res := mb.create_buffer(buffer, n_pixels)
    if res != .OK
    {
        assert(false, "*** BUFFER ***")
        am.status = .Fail
        return am.status
    }

    data.masks = make_mask_view_data(am^, buffer)

    dim := screen_dimensions(data.masks)
    out := data.out_view
    if dim.x != out.width || dim.y != out.height
    {
        assert(false, "*** MASK DIMENSIONS ***")
        am.status = .Fail
        return am.status
    }

    set_mask_list_views(data.masks, out, &data.mask_views)
    
    // sounds
    // music

    am.status = .Ready
    return am.status
}


/* update modes */

update_mode_error :: proc(state: ^AppState, input: Input)
{
    img.fill(state.screen, COLOR_ERROR)
}


update_mode_ok :: proc(state: ^AppState, input: Input)
{
    data := get_data(state)

    map_input_list(input, &data.inputs)    
    
    img.fill(data.out_view, COLOR_BACKGROUND)

    draw_map_list(&data.mask_views, data.inputs)
}


update_mode_process_assets :: proc(state: ^AppState, input: Input)
{
    img.fill(state.screen, COLOR_BACKGROUND)

    data := get_data(state)
    status := process_asset_memory(data)

    if (status == .Ready)
    {
        data.state_update = update_mode_ok
    }
    else
    {
        data.state_update = update_mode_error
    }
}


update_mode_loading_assets :: proc(state: ^AppState, input: Input)
{
    img.fill(state.screen, COLOR_BACKGROUND)

    data := get_data(state)

    if thread.is_done(data.asset_thread)
    {
        thread.join(data.asset_thread)
        thread.destroy(data.asset_thread)

        data.state_update = update_mode_process_assets
    }

}



/* api */

app_init :: proc(state: ^AppState) -> AppResult
{
    res: AppResult
    res.success = false

    if !create_state_data(state)
    {
        return res
    }

    if !audio.init_audio()
    {
        return res
    }

    data := get_data(state)

    data.asset_thread = load_asset_memory_async(&data.asset_memory)
    data.asset_load_complete = false
    data.state_update = update_mode_loading_assets        

    res.screen_dimensions = screen_dimensions()
    res.success = true

    return res
}


app_set_screen_memory :: proc(state: ^AppState, screen: ImageView) -> bool
{
    state.screen = screen

    data := get_data(state)

    dim := screen_dimensions()
    if dim.x != screen.width || dim.y != screen.height
    {
        return false
    }

    data.out_view = screen

    return true
}


app_update :: proc(state: ^AppState, input: Input)
{
    data := get_data(state)

    data.state_update(state, input)
}


app_reset :: proc(state: ^AppState)
{
    img.fill(state.screen, img.BLACK)
}


app_close :: proc(state: ^AppState)
{
    audio.close_audio()
    destroy_state_data(state)
}