# 图片清单

尺寸按宽 × 高记录，比例为最简宽高比。PT 表示 PhotoTest，后接稳定的测试编号。

| 文件名 | 分组 | 测试目的 |
| --- | --- | --- |
| [PT001_reading_1080x24000_9x200.jpg](../images/PT001_reading_1080x24000_9x200.jpg) | 长图内容 | 不同字号文字、分段和底部 END |
| [PT002_sharpness_1080x24000_9x200.png](../images/PT002_sharpness_1080x24000_9x200.png) | 长图内容 | 无损 1 / 2 / 4 / 8 px 条纹及棋盘格 |
| [PT003_colors_1080x24000_9x200.jpg](../images/PT003_colors_1080x24000_9x200.jpg) | 长图内容 | 色带、灰阶和纵向位置 |
| [PT004_gallery_1080x24000_9x200.jpg](../images/PT004_gallery_1080x24000_9x200.jpg) | 长图内容 | 30 幅编号合成风景，检查连续浏览 |
| [PT005_square_1080x1080_1x1.png](../images/PT005_square_1080x1080_1x1.png) | 日常基准 | 检查完整显示与铺满裁切的基准 |
| [PT006_landscape_4032x3024_4x3.jpg](../images/PT006_landscape_4032x3024_4x3.jpg) | 日常基准 | 常见 4:3 横图，约 1220 万像素 |
| [PT007_portrait_3024x4032_3x4.jpg](../images/PT007_portrait_3024x4032_3x4.jpg) | 日常基准 | 与横图对应的 3:4 竖图 |
| [PT008_widescreen_3840x2160_16x9.jpg](../images/PT008_widescreen_3840x2160_16x9.jpg) | 日常基准 | 16:9 横图，约 829 万像素 |
| [PT009_phone_1080x2400_9x20.jpg](../images/PT009_phone_1080x2400_9x20.jpg) | 日常基准 | 9:20 手机屏幕基准，与 10 屏长图对照 |
| [PT010_long_1080x6000_9x50.jpg](../images/PT010_long_1080x6000_9x50.jpg) | 长宽比例 | 中等长度，检查缩放与到达底部 |
| [PT011_panorama_12000x1080_100x9.jpg](../images/PT011_panorama_12000x1080_100x9.jpg) | 长宽比例 | 向左向右的分段、首尾显示 |
| [PT012_panorama_24000x1080_200x9.jpg](../images/PT012_panorama_24000x1080_200x9.jpg) | 长宽比例 | 与 1080x24000 长图互换宽高，比较方向差异 |
| [PT013_lowres_360x8000_9x200.jpg](../images/PT013_lowres_360x8000_9x200.jpg) | 分辨率对照 | 同 9:200 比例，识别源图分辨率不足的正常模糊 |
| [PT014_highres_2160x48000_9x200.jpg](../images/PT014_highres_2160x48000_9x200.jpg) | 压力测试 | 同 9:200 比例，约 1.04 亿像素；单张压力测试 |
| [PT015_odd_1001x22223_1001x22223.png](../images/PT015_odd_1001x22223_1001x22223.png) | 边界测试 | 检查取整、边缘少一列及缩放偏移 |
| [PT016_edge_512x8191_512x8191.png](../images/PT016_edge_512x8191_512x8191.png) | 边界测试 | 最长边比 8192 少 1 像素，总像素低于 800 万 |
| [PT017_edge_512x8192_1x16.png](../images/PT017_edge_512x8192_1x16.png) | 边界测试 | 最长边恰好 8192 像素，总像素低于 800 万 |
| [PT018_edge_512x8193_512x8193.png](../images/PT018_edge_512x8193_512x8193.png) | 边界测试 | 最长边比 8192 多 1 像素，总像素低于 800 万 |
| [PT019_alpha_1080x6000_9x50.png](../images/PT019_alpha_1080x6000_9x50.png) | 格式对照 | 真实透明 / 半透明 / 不透明区域，检查底色与黑边 |
| [PT020_format_1080x6000_9x50.jpg](../images/PT020_format_1080x6000_9x50.jpg) | 格式对照 | 与 PT021 同一绘制内容，检查有损压缩差异 |
| [PT021_format_1080x6000_9x50.png](../images/PT021_format_1080x6000_9x50.png) | 格式对照 | 与 PT020 同一绘制内容，无损输出 |
| [PT022_pixels_2000x3999_2000x3999.png](../images/PT022_pixels_2000x3999_2000x3999.png) | 边界测试 | 799.8 万像素，最长边低于 8192 |
| [PT023_pixels_2000x4000_1x2.png](../images/PT023_pixels_2000x4000_1x2.png) | 边界测试 | 恰好 800 万像素，最长边低于 8192 |
| [PT024_pixels_2000x4001_2000x4001.png](../images/PT024_pixels_2000x4001_2000x4001.png) | 边界测试 | 800.2 万像素，最长边低于 8192 |
