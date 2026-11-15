# Map Artwork Resolution

## Fact or rule

The previous painted Maintenance source was a 1536 x 1024 sheet containing all fifteen rooms. Each room occupies only a few hundred source pixels across. Enlarging those room regions to gameplay size cannot reveal additional original detail. The shared map sampling shader reduces filtering softness; it is not a higher-resolution replacement asset.

## Why

The user reported blurry zoomed maps after the painted sheet became the active room source. Room canvas size and source artwork resolution are different: a large world-space room can still display a small source image.

## How to apply

The active underground source is now `rooms/ALL_4_BIOMES_120_UNIQUE_BLOCKOUTS`, with individual images and matching collision geometry. For further detail improvements, use higher-resolution individual versions of the same rooms and verify their alignment. Do not claim that changing filtering, sharpening, or merely resizing a file restores missing image detail. Check both close and distant views with the renderer.
