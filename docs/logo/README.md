Inkscape processing
================================

The image rasterization to small png pictures does not work well,
as it creates ugly white-ish boundary lines between the polygons.
Hence, instead, we first export the image to a ~8000px wide image,
and then scale this down for the final logo:
convert -resize 600 logo_large.png logo.png

Font
================================

Font Heorot: free for noncommercial use, see
https://www.1001freefonts.com/heorot.font
