# ADCIRC 潮汐开边界生成器 (tidal-open-boundary-generator)

基于 EOT20 全球潮汐模型，自动生成 ADCIRC fort.15 所需的潮汐开边界强迫块。

## 功能

* 读取 ADCIRC 网格文件 (`fort.14`) 的开边界节点
* 从 EOT20 NetCDF 数据插值潮汐振幅和相位
* 计算节点因子 (FF) 和均衡引潮力 (FACE)
* 支持自定义分潮列表、振幅缩放、相位修正
* 输出符合 ADCIRC fort.15 格式的潮汐块

## 文件结构

* tideblock-generator/

  * README.md
  * LICENSE
  * docs/

    * usage.md
    * theory.md
  * generate_tide_block.m
  * read_eot20.m
  * compute_node_factor.m
  * read_fort14_boundary.m
  * example/

    * fort.14
    * EOT20_ocean.nc
  * output/ (运行时自动生成)

## 依赖

* MATLAB R2020b 或更高版本
* 必需工具箱：Mapping Toolbox（用于 `interp2`）
* 可选工具箱：Global Optimization Toolbox（非必需，仅用于高级调参）

## 数据说明

本项目使用的数据源为 DGFI-TUM 发布的 EOT20 全球经验潮汐模型。

需要注意的是：

* EOT20 官方数据集通过 SEANOE 数据库发布；
* 官方发布格式为 `ocean_tides/` 和 `load_tides/` 两个目录，每个分潮对应一个独立 NetCDF 文件；
* 本项目使用的并非 SEANOE 原始文件，而是 Tide Model Driver (TMD) version 3.0 中提供的预转换数据文件：

```text
Tide Model Driver (TMD) version 3.0/
└── Model/
    └── EOT20/
        └── EOT20_ocean.nc
```

该文件将 EOT20 的 17 个分潮统一存储于单个 NetCDF 文件中，并采用复数谐波常数（Complex Harmonic Constants）表示：

```math
H = Re + i \cdot Im
```

这种格式便于潮汐插值和潮位重建，也是本项目读取的数据格式。

因此，若用户直接从 SEANOE 下载 EOT20 原始数据，需要先转换为 TMD 兼容格式后才能用于本项目。

## 快速开始

1. **准备数据**

   * 将网格文件 `fort.14` 放入项目根目录；
   * 获取 TMD 3.0 中的 `EOT20_ocean.nc` 文件，并放入项目根目录。

2. **修改配置**
   打开 `generate_tide_block.m`，在“用户配置区”设置：

   * 模型起始时间（UTC+8）
   * 分潮列表（默认 M2,S2,N2,K2,K1,O1,P1,Q1）
   * 输出文件名

3. **运行**
   在 MATLAB 中直接执行：

```matlab
generate_tide_block
```

4. **输出**
   生成指定的潮汐块文本文件，可直接粘贴到 ADCIRC 的 `fort.15` 中。

## 主要函数说明

| 函数                     | 作用                 |
| ---------------------- | ------------------ |
| `read_fort14_boundary` | 提取开边界节点经纬度         |
| `read_eot20`           | 读取 EOT20 NetCDF 数据 |
| `compute_node_factor`  | 根据参考时间计算 FF/FACE   |
| `generate_tide_block`  | 主脚本（整合上述函数）        |

## 许可证

本项目采用 MIT License，可自由使用、修改和分发。

## 数据引用

如果本项目用于科研工作，请同时引用以下数据源：

Hart-Davis, M., Piccioni, G., Dettmering, D., Schwatke, C., Passaro, M., & Seitz, F. (2021).

*EOT20 – A global Empirical Ocean Tide model from multi-mission satellite altimetry.*

DOI: https://doi.org/10.17882/79489

## 致谢

* EOT20 全球潮汐模型由 DGFI-TUM 开发，并通过 SEANOE 数据库发布。
* 本项目采用MATLAB社区工具包 Tide Model Driver (TMD) version 3.0 提供的 EOT20 转换文件 `EOT20_ocean.nc` 作为潮汐数据源，该数据可在工具包路径\Tide Model Driver (TMD) version 3.0\Model\EOT20下获取。
* TMD 项目对 EOT20 数据进行了统一格式转换，使其能够以复数谐波常数形式进行高效读取和插值。
* 节点因子算法参考 Schureman (1958) 及 NOAA 潮汐分析方法。

## 联系方式

如有问题或建议，请通过 GitHub Issues 提交。

项目地址：
https://github.com/HuAced/tidal-open-boundary-generator
