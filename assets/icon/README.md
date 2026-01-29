# App Icon Requirements

Place your source icon here as `app_icon.png`.

## Requirements
- **Format**: PNG (with transparency if desired, though Android Adaptive icons work best with a solid background).
- **Dimensions**: 1024x1024 px.
- **Safety Zone**: Keep important logos/text within the central circle (66% of the canvas) to avoid cropping on some Android shapes (Circle/Squircle).

## Generating Icons
Once `app_icon.png` is in this folder, run:
```bash
dart run flutter_launcher_icons
```
This will automatically generate all necessary sizes for Android (mipmap) and iOS (Assets.xcassets).
