# ADCIRC 潮汐开边界生成器 (tidal-open-boundary-generator)
基于 EOT20 全球潮汐模型，自动生成 ADCIRC fort.15 所需的潮汐开边界强迫块。
## 功能
- 读取 ADCIRC 网格文件 (`fort.14`) 的开边界节点
- 从 EOT20 NetCDF 数据插值潮汐振幅和相位
- 计算节点因子 (FF) 和均衡引潮力 (FACE)
- 支持自定义分潮列表、振幅缩放、相位修正
- 输出符合 ADCIRC fort.15 格式的潮汐块
## 文件结构
- tideblock-generator/
    - README.md
    - LICENSE
    - docs/
        - usage.md
        - theory.md
    - generate_tide_block.m
    - read_eot20.m
    - compute_node_factor.m
    - read_fort14_boundary.m
    - example/
        - fort.14
        - EOT20.nc
    - output/ (运行时自动生成)
## 依赖
- MATLAB R2020b 或更高版本
- 必需工具箱：Mapping Toolbox（用于 `interp2`）
- 可选工具箱：Global Optimization Toolbox（非必需，仅用于高级调参）
## 快速开始
1. **准备数据**：
   - 将网格文件 `fort.14` 放入项目根目录
   - 下载 EOT20 潮汐数据（NetCDF 格式），放入根目录
2. **修改配置**：打开 `generate_tide_block.m`，在“用户配置区”设置：
   - 模型起始时间（UTC+8）
   - 分潮列表（默认 M2,S2,N2,K2,K1,O1,P1,Q1）
   - 输出文件名
3. **运行**：在 MATLAB 中直接执行 `generate_tide_block.m`。
4. **输出**：生成指定的潮汐块文本文件，可直接粘贴到 `fort.15` 中。
## 主要函数说明
| 函数 | 作用 |
|------|------|
| `read_fort14_boundary` | 提取开边界节点经纬度 |
| `read_eot20` | 读取 EOT20 NetCDF 数据 |
| `compute_node_factor` | 根据参考时间计算 FF/FACE |
| `generate_tide_block` | 主脚本（整合上述函数）|
## 许可证
本项目采用 [MIT 许可证](LICENSE)，可自由使用、修改和分发。
## 致谢
- EOT20 潮汐模型：来自 DGFI-TUM，数据通过 SEANOE 数据库提供（https://www.seanoe.org/data/00683/79489/），本项目使用的版本为复数形式单一 NetCDF 文件。
- 节点因子算法参考：Schureman (1958), NOAA 潮汐分析方法。
## 联系方式
如有问题或建议，请通过 [GitHub Issues](https://github.com/HuAced/tidal-open-boundary-generator/issues) 提交。
- 项目地址：https://github.com/HuAced/tidal-open-boundary-generator
