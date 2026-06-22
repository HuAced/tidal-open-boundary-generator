# 使用说明
## 输入文件
- 将 `fort.14` 和 `EOT20.nc` 放入 `src/input/` 目录。
## 运行前设置
打开 `src/main.m`，设置以下参数：
- **目标分潮**
- **开边界起始时刻**
## 运行
在 MATLAB 中将工作目录设为项目根目录，然后在命令窗口运行：
```matlab
>> main
或在 MATLAB 主界面直接运行主程序
## 输出
程序自动在 src/output/ 下生成 tide_block.txt ，将此文件中的内容复制粘贴到 fort.15 对应位置即可。

