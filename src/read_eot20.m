function E = read_eot20(ncfile)
%READ_EOT20  读取 EOT20 潮汐模型 NetCDF 文件
%   E = READ_EOT20(NCFILE) 从 NetCDF 文件读取 EOT20 数据，返回结构体 E。
%
%   输入：
%       ncfile  - EOT20 NetCDF 文件路径（字符串）
%
%   输出：
%       E - 结构体，包含以下字段：
%           .lon    - 经度数组（度）
%           .lat    - 纬度数组（度）
%           .omega  - 分潮角频率（rad/hr）
%           .names  - 分潮名称（cell 字符串，大写）
%           .nCon   - 分潮数量
%           .hRe    - 复振幅实部（lat × lon × nCon）
%           .hIm    - 复振幅虚部（lat × lon × nCon）
%
%   注意事项：
%       自动处理 NetCDF 中的 scale_factor、add_offset 和 _FillValue。
%       支持多种分潮名称存储方式（属性或变量）。
%
%   作者: Aced Hu
%   日期: 2026-06-22
%
%   内部函数：
%       apply_nc_scale_and_missing(ncfile, varName, raw)
%           - 应用 NetCDF 缩放/偏移并标记缺失值为 NaN

% ==================== 读取基本维度 ====================
E.lon = double(ncread(ncfile, 'lon'));
E.lat = double(ncread(ncfile, 'lat'));
E.omega = double(ncread(ncfile, 'omega'));

% ==================== 读取分潮名称 ====================
E.names = {};

% 优先尝试从属性读取（EOT20 标准格式）
try
    orderAttr = ncreadatt(ncfile, 'constituents', 'constituent_order');
    E.names = upper(regexp(strtrim(orderAttr), '[A-Za-z0-9]+', 'match'));
catch
    % 备选：从变量读取
    try
        C = ncread(ncfile, 'constituents');
    catch
        try
            C = ncread(ncfile, 'const');
        catch
            error('无法读取分潮名称，请检查 EOT20 文件格式');
        end
    end
    
    if isstring(C) || iscell(C)
        E.names = upper(cellstr(C));
    elseif ischar(C)
        % 处理字符数组
        E.names = upper(strtrim(cellstr(C.')));
    else
        error('无法解析分潮名称，请检查 EOT20 文件格式');
    end
end

E.nCon = numel(E.names);
if E.nCon == 0
    error('未读取到任何分潮名称');
end

% ==================== 读取复振幅数据（带缩放） ====================
fprintf('      读取 hRe/hIm 数据（%d × %d × %d）...\n', ...
    length(E.lat), length(E.lon), E.nCon);

hReRaw = ncread(ncfile, 'hRe');
hImRaw = ncread(ncfile, 'hIm');

E.hRe = apply_nc_scale_and_missing(ncfile, 'hRe', hReRaw);
E.hIm = apply_nc_scale_and_missing(ncfile, 'hIm', hImRaw);

fprintf('      数据读取完成。\n');

end


% ==================== 内部辅助函数 ====================

function X = apply_nc_scale_and_missing(ncfile, varName, raw)
% APPLY_NC_SCALE_AND_MISSING  应用 NetCDF 缩放因子并处理缺失值
%
%   X = apply_nc_scale_and_missing(ncfile, varName, raw)
%
%   输入：
%       ncfile   - NetCDF 文件路径
%       varName  - 变量名（如 'hRe' 或 'hIm'）
%       raw      - 原始数据（ncread 输出）
%
%   输出：
%       X        - 处理后的数据（double，缺失值为 NaN）

X = double(raw);

% ---- 读取缺失值标记 ----
fillVals = [];
for att = {'_FillValue', 'missing_value'}
    try
        fillVals(end+1) = double(ncreadatt(ncfile, varName, att{1}));
    catch
        % 属性不存在，忽略
    end
end

% 标记缺失值
if ~isempty(fillVals)
    mask = false(size(raw));
    for i = 1:numel(fillVals)
        mask = mask | (double(raw) == fillVals(i));
    end
    X(mask) = NaN;
end

% ---- 读取缩放因子和偏移量 ----
scale = 1.0;
offset = 0.0;

try
    scale = double(ncreadatt(ncfile, varName, 'scale_factor'));
catch
    % 使用默认值 1.0
end

try
    offset = double(ncreadatt(ncfile, varName, 'add_offset'));
catch
    % 使用默认值 0.0
end

% 仅在数据看起来需要缩放时才应用（整数或数值较大）
if isinteger(raw) || max(abs(X(:)), [], 'omitnan') > 100
    X = X * scale + offset;
end

end