# Image Display Suite

[English](README.md) | **简体中文**

![图片显示测试素材介绍](docs/hero.png)

一套可扩展的图片测试素材及生成工具，用于验证应用、网页和图像加载组件的比例、裁切、缩放、透明度与解码行为。

图片可直接使用，无需运行脚本。覆盖正方形、横竖照片、手机单屏、长图、横向全景、奇数尺寸、像素边界，以及 JPEG / PNG 对照。

[查看测试图片总览](docs/preview.jpg)

## 使用

1. 从 [images/](images/) 选择原图导入待测应用，按[测试建议](docs/TESTING.md)执行。
2. 在[图片清单](docs/CATALOG.md)按尺寸与用途选择用例。
3. 比较编码前像素相同的 PT020 / PT021，区分 JPEG 压缩与显示算法的差异。

PT 表示 **PhotoTest**，后接稳定的测试编号。文件名：`PT编号_用途_宽x高_最简宽高比.格式`。例如 `PT001_reading_1080x24000_9x200.jpg`。

超长图在总览中会非常细，总览只用于索引；清晰度应查看原图并放大比较。PT014 为 2160×48000（约 1.04 亿像素），适合单独进行压力测试。

## 验证、生成与打包

在项目根目录执行：

```sh
# 仅验证现有图片：Python 3.9+，无需第三方库，可在 macOS / Linux / Windows 运行。
python3 scripts/verify.py

# 重新生成：需要 macOS、Python 3.9+ 和 Swift 命令行工具。
python3 scripts/build.py

# 验证并打包现有测试图片，无需 Swift。
python3 scripts/build.py --package-only
```

压缩包输出为 `dist/image-display-suite.zip`，只包含 `cases.json` 中列出的测试图片，直接放在 ZIP 根目录，方便解压后导入。源码、字体、文档、预览和介绍图保留在仓库。MIT 许可文本保存在 ZIP 注释中，不额外增加非图片文件。`--package` 可在重新生成后直接打包。

生成过程离线读取随包字体，不依赖相邻目录，也不会安装系统字体。实测生成环境：macOS 26.5.2、Swift 6.3.3、Python 3.9.6。图像编码和字体栅格化可能随 macOS / SDK 变化；`manifest.json` 的哈希用于核验随附文件，不承诺跨平台或跨系统版本逐字节重现。

## 目录

```text
images/                   原始测试图片
docs/                     图片清单、测试建议、预览
fonts/                    固定版本字体、上游来源与授权材料
scripts/                  生成、验证和打包入口
cases.json                用例定义，尺寸和用途的维护入口
manifest.json             文件尺寸、SHA-256、字体元信息与格式对照记录
LICENSE                   本项目 MIT 许可证
THIRD_PARTY_NOTICES.md     第三方字体声明
```

`.build/` 和 `dist/` 是本地生成目录，不纳入版本控制。本目录可直接作为独立仓库的根目录。

## 许可

本项目的生成脚本、测试图片及文档采用 [MIT](LICENSE)，允许商用、修改和再分发，需保留版权及许可声明。字体 **Noto Sans CJK SC Regular 2.004** 单独采用 SIL OFL 1.1，不受本项目 MIT 许可证替代；详见[第三方声明](THIRD_PARTY_NOTICES.md)。

README 顶部介绍图由图像生成模型创作；它是概念插画，不作为像素测量用例。测试图片由随包脚本生成。

本套素材是合成用例集，不覆盖所有照片编码、EXIF 方向、HDR、ICC 色彩配置、动画格式或真实设备性能；通过这些用例不等于完成图像兼容性认证。
