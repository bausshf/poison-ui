/**
* Module for picture manipulation.
*
* Authors:
*   Jacob Jensen
* License:
*   https://github.com/PoisonEngine/poison-ui/blob/master/LICENSE
*/
module poison.ui.picture;

import dsfml.graphics : Image, Texture, RenderWindow;

import poison.ui.paint;
import poison.ui.sprite;
import poison.core : Size, Point;

/// Paint graphics for a picture.
private class PictureGraphics {
  /// The position.
  Point _position;
  /// The size.
  Size _size;
  /// The paint.
  Paint _paint;

  /**
  * Creates a new picture graphic.
  * Params:
  *   position =  The position of the graphic.
  *   size =      The size of the graphic.
  *   paint =     The paint of the graphic.
  */
  this(Point position, Size size, Paint paint) {
    _position = position;
    _size = size;
    _paint = paint;
  }

  @property {
    /// Gets the position of the graphic.
    Point position() { return _position; }

    /// Gets the size of the graphic.
    Size size() { return _size; }

    /// Gets the paint of the graphic.
    Paint paint() { return _paint; }
  }
}

/// A picture for image manipulation.
final class Picture {
  private:
  /// The background sprite.
  TextureSprite _backgroundSprite;

  /// The drawing sprite.
  TextureSprite _drawingSprite;

  /// The original filename.
  string _fileName;

  /// The size.
  Size _size;

  /// The fill paint.
  Paint _fillPaint;

  /// The image buffer.
  ubyte[] _imageBuffer;

  /// The graphics to render onto it.
  PictureGraphics[] _graphics;

  /// The position.
  Point _position;

  /// Renders the picture.
  void render() {
    assert(_fileName || _imageBuffer || _size);

    Image backgroundImage;
    auto drawingImage = new Image();

    if (_fileName || _imageBuffer) {
      backgroundImage = new Image();

      if (_fileName) {
        backgroundImage.loadFromFile(_fileName);
      }
      else {
        backgroundImage.loadFromMemory(_imageBuffer);
      }

      auto imgSize = backgroundImage.getSize();
      _size = new Size(cast(size_t)imgSize.x, cast(size_t)imgSize.y);

      drawingImage.create(_size.width, _size.height, transparent.sfmlColor);
    }
    else if (_size) {
      drawingImage.create(_size.width, _size.height, _fillPaint.sfmlColor);
    }

    if (_graphics) {
      foreach (graphic; _graphics) {
        auto xFrom = graphic.position.x;
        auto xTo = graphic.position.x + graphic.size.width;
        auto yFrom = graphic.position.y;
        auto yTo = graphic.position.y + graphic.size.height;
        auto color = graphic.paint.sfmlColor;

        foreach (x; xFrom .. xTo) {
          foreach (y; yFrom .. yTo) {
            drawingImage.setPixel(cast(uint)x, cast(uint)y, color);
          }
        }
      }
    }

    if (backgroundImage) {
      auto texture = new Texture();
  		texture.loadFromImage(backgroundImage);
  		texture.setSmooth(true);

  		_backgroundSprite = new TextureSprite(texture);
    }

    if (drawingImage) {
      auto texture = new Texture();
  		texture.loadFromImage(drawingImage);
  		texture.setSmooth(true);

  		_drawingSprite = new TextureSprite(texture);
    }

    position = _position;
  }

  public:
  final:
  /**
  * Creates a new picture.
  * Params:
  *   imageFile = The file for an image to load onto the picture.
  */
  this(string imageFile) {
    _fileName = imageFile;
  }

  /**
  * Creates a new picture.
  * Params:
  *   size =      The size of the picture.
  *   fillPaint = The initialization paint.
  */
  this(Size size, Paint fillPaint) {
    _size = size;
    _fillPaint = fillPaint;
  }

  /**
  * Creates a new picture.
  * Params:
  *   imageBuffer = The buffer to load the picture from.
  */
  this(ubyte[] imageBuffer) {
    _imageBuffer = imageBuffer;
  }

  /**
  * Creates a new picture, copied from another.
  * Params:
  *   copyImage = The image to copy.
  */
  this(Picture copyImage) {
    if (copyImage._imageBuffer) {
      this(copyImage._imageBuffer.dup);
    }
    else if (copyImage._fileName) {
      this(copyImage._fileName.dup);
    }
    else {
      this(new Size(copyImage._size.width, copyImage._size.height), copyImage._fillPaint);
    }

    if (copyImage._graphics) {
      _graphics = copyImage._graphics.dup;
    }
  }

  /// Clears the graphics.
  void clearGraphics() {
    _graphics = null;
  }

  /**
  * Draws paint onto the picture.
  * Params:
  *   position =  The position within the picture to draw the paint.
  *   size =      The size of the paint.
  *   paint =     The paint to draw with.
  */
  void draw(Point position, Size size, Paint paint) {
    _graphics ~= new PictureGraphics(position, size, paint);
  }

  /**
  * Paints a horizontal gradient on the picture.
  * Params:
  *   position =  The position within the picture to paint the gradient.
  *   size =      The size of the gradient.
  *   from =      The paint to gradient from.
  *   to =        The paint to gradient to.
  *   a =         The alpha channel of the gradient.
  */
  void gradientHorizontal(Point position, Size size, Paint from, Paint to, ubyte a = 0xff) {
    bool decreaseR = from.r > to.r;
    bool decreaseG = from.g > to.g;
    bool decreaseB = from.b > to.b;

    auto block = new Size(1, size.height);

    ubyte rInc = cast(ubyte)(cast(float)(decreaseR ? from.r - to.r : to.r - from.r) / (cast(float)size.width / 1.5));
    ubyte gInc = cast(ubyte)(cast(float)(decreaseG ? from.g - to.g : to.g - from.g) / (cast(float)size.width / 1.5));
    ubyte bInc = cast(ubyte)(cast(float)(decreaseB ? from.b - to.b : to.b - from.b) / (cast(float)size.width / 1.5));

    for (auto x = position.x; x < (position.x + size.width); x++) {
      draw(new Point(x, position.y), block, paintFromRGBA(from.r, from.g, from.b, a));

      if (decreaseR && from.r > (to.r + rInc)) {
        from.r -= rInc;
      }
      else if (!decreaseR && from.r < (to.r - rInc)) {
        from.r += rInc;
      }

      if (decreaseG && from.g > (to.g + gInc)) {
        from.g -= gInc;
      }
      else if (!decreaseG && from.g < (to.g - gInc)) {
        from.g += gInc;
      }

      if (decreaseB && from.b > (to.b + bInc)) {
        from.b -= bInc;
      }
      else if (!decreaseB && from.b < (to.b - bInc)) {
        from.b += bInc;
      }
    }
  }

  /**
  * Paints a vertical gradient on the picture.
  * Params:
  *   position =  The position within the picture to paint the gradient.
  *   size =      The size of the gradient.
  *   from =      The paint to gradient from.
  *   to =        The paint to gradient to.
  *   a =         The alpha channel of the gradient.
  */
  void gradientVertical(Point position, Size size, Paint from, Paint to, ubyte a = 0xff) {
    bool decreaseR = from.r > to.r;
    bool decreaseG = from.g > to.g;
    bool decreaseB = from.b > to.b;

    auto block = new Size(size.width, 1);

    ubyte rInc = cast(ubyte)(cast(float)(decreaseR ? from.r - to.r : to.r - from.r) / (cast(float)size.height / 1.5));
    ubyte gInc = cast(ubyte)(cast(float)(decreaseG ? from.g - to.g : to.g - from.g) / (cast(float)size.height / 1.5));
    ubyte bInc = cast(ubyte)(cast(float)(decreaseB ? from.b - to.b : to.b - from.b) / (cast(float)size.height / 1.5));

    for (auto y = position.y; y < (position.y + size.height); y++) {
      draw(new Point(position.x, y), block, paintFromRGBA(from.r, from.g, from.b, a));

      if (decreaseR && from.r > (to.r + rInc)) {
        from.r -= rInc;
      }
      else if (!decreaseR && from.r < (to.r - rInc)) {
        from.r += rInc;
      }

      if (decreaseG && from.g > (to.g + gInc)) {
        from.g -= gInc;
      }
      else if (!decreaseG && from.g < (to.g - gInc)) {
        from.g += gInc;
      }

      if (decreaseB && from.b > (to.b + bInc)) {
        from.b -= bInc;
      }
      else if (!decreaseB && from.b < (to.b - bInc)) {
        from.b += bInc;
      }
    }
  }

  /**
  * Resizes the picture.
  * Params:
  *   newSize = Resizes the picture.
  * Bug:
  *   Currently only work for pictures with no image file.
  *   The fix is to use scale().
  */
  void resize(Size newSize) {
    _size = newSize;
  }

  /// Finalizes the picture and its graphics.
  void finalize() {
    render();
  }

  @property {
    /// Gets the size of the picture.
    Size size() { return _size; }

    /// Gets the file name.
    string fileName() { return _fileName; }

    /// Sets the file name.
    void fileName(string newFileName) {
      _fileName = newFileName;
    }

    /// Gets the image buffer.
    ubyte[] imageBuffer() { return _imageBuffer; }

    /// Sets the image buffer.
    void imageBuffer(ubyte[] imageBuffer) {
      _imageBuffer = imageBuffer;
    }
  }

  package(poison):
  @property {
    /// Gets the background sprite of the picture.
    TextureSprite backgroundSprite() { return _backgroundSprite; }

    /// Gets the drawing sprite of the picture.
    TextureSprite drawingSprite() { return _drawingSprite; }

    /// Sets the position of the picture's sprite.
    void position(Point newPosition) {
      _position = newPosition;

      if (_position) {
        if (_backgroundSprite) {
          _backgroundSprite.position = _position;
        }

        if (_drawingSprite) {
          _drawingSprite.position = _position;
        }
      }
    }
  }
}
