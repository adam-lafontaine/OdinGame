#+private
package game_io_test

import "../../lib/types"
import inp "../../lib/io/input"
import img "../../lib/image_view"
import mb "../../lib/memory_buffer"
import sv "../../lib/span_view"


Vec2Df32 :: types.Vec2Df32
Vec2Di32 :: types.Vec2Di32
Vec2Du32 :: types.Vec2Du32

BtnState :: inp.ButtonState
Input    :: inp.Input

p32    :: img.Pixel32
RectPx :: img.Rect2Du32

Buffer32 :: img.Buffer32
Buffer8  :: img.Buffer8

ImageView   :: img.ImageView
SubView     :: img.SubView
GrayView    :: img.GrayView
GraySubView :: img.GraySubView

MaskView :: img.GrayView
Mask     :: img.GraySubView

ByteBuffer :: mb.MemoryBuffer(byte)
ByteView :: sv.ByteView


COLOR_BLACK       :: img.BLACK
COLOR_TRANSPARENT :: p32{ 0, 0, 0, 0 }
COLOR_BACKGROUND  :: p32{ 200, 200, 200, 255 }
COLOR_ON          :: p32{ 50, 255, 50, 255 }
COLOR_OFF         :: p32{ 127, 127, 127, 255 }
COLOR_UNEXPECTED  :: p32{ 255, 0, 255, 255 }
COLOR_ERROR       :: p32{ 255, 50, 50, 255 }