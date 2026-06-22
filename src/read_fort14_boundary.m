function [openNodes, lonOb, latOb, NOPE] = read_fort14_boundary(f14File)
%READ_FORT14_BOUNDARY  从 ADCIRC fort.14 文件提取开边界节点信息
%   [openNodes, lonOb, latOb, NOPE] = READ_FORT14_BOUNDARY(f14File)
%   读取 fort.14 网格文件，返回开边界节点的全局编号、经纬度坐标和开边界段数。
%
%   输入：
%       f14File  - fort.14 文件路径（字符串）
%
%   输出：
%       openNodes - 开边界节点全局编号（列向量）
%       lonOb     - 对应经度（列向量）
%       latOb     - 对应纬度（列向量）
%       NOPE      - 开边界段数
%
%   注意事项：
%       函数会自动识别 fort.14 第二行的格式（NE NP 或 NP NE），
%       并跳过单元连接表，定位到 “Number of open boundaries” 部分。
%       不支持包含潮位测站的 fort.14 文件。
%
%   作者: Aced Hu
%   日期: 2026-06-22

fid = fopen(f14File, 'r');
assert(fid > 0, '无法打开 fort.14：%s', f14File);
cleanObj = onCleanup(@() fclose(fid));

fgetl(fid);                           % 跳过标题行
line2 = fgetl(fid);
nums = sscanf(line2, '%d %d');

while numel(nums) ~= 2
    line2 = fgetl(fid);
    if ~ischar(line2)
        error('fort.14 开头未找到节点/单元数量行。');
    end
    nums = sscanf(line2, '%d %d');
end

% 探测第二行格式：NE NP 还是 NP NE？
pos = ftell(fid);
probe = textscan(fid, '%f %f %f %f', 1);
fseek(fid, pos, 'bof');

if isempty(probe{1})
    NP = nums(2);
    NE = nums(1);
else
    NE = nums(1);
    NP = nums(2);
end

% 读取所有节点坐标
nodeData = textscan(fid, '%f %f %f %f', NP);
% nodeId = nodeData{1};   % 节点编号，一般没用
lonAll = nodeData{2};
latAll = nodeData{3};

% 跳过单元连接表
for i = 1:NE
    fgetl(fid);
end

% 寻找 "Number of open boundaries"
line = '';
while ischar(line)
    line = fgetl(fid);
    if ~ischar(line)
        error('未找到 Number of open boundaries。');
    end
    if contains(lower(line), 'number of open boundaries')
        break;
    end
end

NOPE = sscanf(line, '%d', 1);

% "Total number of open boundary nodes"
line = fgetl(fid);
assert(contains(lower(line), 'total number of open boundary nodes'), ...
    '未找到 Total number of open boundary nodes 行。');

openNodes = [];

for ib = 1:NOPE
    hdr = fgetl(fid);
    assert(contains(lower(hdr), 'number of nodes for open boundary'), ...
        '缺少 open boundary 节点数量行。');
    
    nThis = sscanf(hdr, '%d', 1);
    list = [];
    
    while numel(list) < nThis
        L = strtrim(fgetl(fid));
        if isempty(L)
            continue;
        end
        list = [list; sscanf(L, '%d')];
    end
    
    openNodes = [openNodes; list(1:nThis)];
end

lonOb = lonAll(openNodes);
latOb = latAll(openNodes);
end