%% ===================== 主程序 =====================
% 以下代码顺序执行，用户无需修改
% 步骤：
%   1. 时间处理（UTC+8 -> UTC）
%   2. 读取 fort.14 开边界节点
%   3. 读取 EOT20 潮汐数据
%   4. 根据用户白名单过滤分潮
%   5. 插值 EOT20 到开边界节点
%   6. 计算节点因子（FF）和均衡引潮力（FACE）
%   7. 写出 fort.15 潮汐块
% ===================================================

%% 本地辅助函数
% write_fort15_tide_block(outfile, names, omega, FF, FACE, Amp, Kappa)

% ----- 1. 时间设置 -----
% 模型参考起始时间（UTC+8），用于 FF/FACE 计算
% 示例：2006-12-26 00:00:00 UTC+8
modelStartUTC8 = datetime(2006, 12, 26, 0, 0, 0, 'TimeZone', 'Asia/Shanghai');

% ----- 2. 文件路径 -----
fort14File = 'input\fort.14';      % ADCIRC 网格文件
eot20File  = 'input\EOT20.nc';     % EOT20 潮汐数据（NetCDF）
outFile    = 'output\tide_block.txt'; % 输出文件

% ----- 3. 分潮选择 -----
% 默认8 个主要分潮（M2, S2, N2, K2, K1, O1, P1, Q1）；若某个分潮在 EOT20 中不存在，会给出警告并跳过。
useConstituents = {'M2', 'S2', 'N2', 'K2', 'K1', 'O1', 'P1', 'Q1'};

% ----- 4. 振幅缩放（可选） -----
% 格式：名称列表与数值列表一一对应。默认全部为 1.0（即不缩放）。
% 如需调整，例如：ampScaleNames = {'M2','K1'}; ampScaleValues = [1.05, 0.95];
ampScaleNames  = {'M2','S2','N2','K2','K1','O1','P1','Q1'};
ampScaleValues = [1.00, 1.00, 1.00, 1.00, 1.00, 1.00, 1.00, 1.00];

% ----- 5. 额外相位修正（可选） -----
% 格式：名称列表与数值列表一一对应（单位：度）。默认全部为 0°（即不修正）。
% 如需调整，例如：phaseShiftNames = {'M2','K1'}; phaseShiftValues = [5, -3];
phaseShiftNames  = {'M2','S2','N2','K2','K1','O1','P1','Q1'};
phaseShiftValues = [0,   0,   0,   0,   0,   0,   0,   0];

% ----- 6. 相位约定转换（EOT20 -> ADCIRC） -----
% EOT20 复数相位转 ADCIRC 边界相位时，M2/N2 需要 +180°。
% 一般保持默认开启。
useSemiDiurnal180Shift = true;
semiDiurnal180Constituents = {'M2','N2'};

% ----- 7. FF/FACE 计算失败时的默认值（一般不需要改） -----
FF_fallback   = 1.0;
FACE_fallback = 0.0;


%% ===================== 主程序 =====================
% 以下代码顺序执行，用户无需修改
% ===================================================

fprintf('========================================\n');
fprintf('  ADCIRC 潮汐开边界生成器\n');
fprintf('========================================\n');

% -------- 1. 时间处理（UTC+8 -> UTC） --------
tRefUTC = modelStartUTC8;
tRefUTC.TimeZone = 'UTC';
fprintf('模型参考起始时间 (UTC+8): %s\n', datestr(modelStartUTC8, 'yyyy-mm-dd HH:MM:SS'));
fprintf('FF/FACE 计算使用时间 (UTC): %s\n', datestr(tRefUTC, 'yyyy-mm-dd HH:MM:SS'));

% -------- 2. 读取 fort.14 开边界节点 --------
fprintf('\n[1/5] 读取网格开边界...\n');
[openNodes, lonOb, latOb] = read_fort14_boundary(fort14File);
nNode = length(openNodes);
fprintf('      开边界节点总数: %d\n', nNode);

% -------- 3. 读取 EOT20 --------
fprintf('\n[2/5] 读取 EOT20 潮汐数据...\n');
E = read_eot20(eot20File);
fprintf('      EOT20 包含分潮数: %d\n', E.nCon);

% -------- 4. 根据白名单过滤分潮（并检查是否存在） --------
fprintf('\n[3/5] 匹配用户指定的分潮...\n');

% 用户白名单统一转为大写
userNames = upper(useConstituents);
eotNames  = upper(E.names);

% 找出白名单中在 EOT20 里存在的分潮
[found, idxInUser, idxInEOT] = intersect(userNames, eotNames, 'stable');

% 检查哪些白名单分潮在 EOT20 中不存在
missing = setdiff(userNames, eotNames);
if ~isempty(missing)
    fprintf('      ⚠️  警告：以下分潮在 EOT20 中未找到，已被跳过：\n');
    for i = 1:length(missing)
        fprintf('          %s\n', missing{i});
    end
end

% 更新 EOT 数据为匹配到的分潮
E.names  = E.names(idxInEOT);
E.omega  = E.omega(idxInEOT);
E.hRe    = E.hRe(:,:,idxInEOT);
E.hIm    = E.hIm(:,:,idxInEOT);
E.nCon   = length(idxInEOT);

fprintf('      实际使用的分潮数: %d\n', E.nCon);
if E.nCon == 0
    error('错误：没有找到任何可用的分潮！请检查白名单设置。');
end

% 同时修正振幅缩放和相位修正列表（只保留实际使用的分潮）
% 重新构建映射表，以便在插值循环中快速查找
ampScaleMap = containers.Map(upper(ampScaleNames), ampScaleValues);
phaseShiftMap = containers.Map(upper(phaseShiftNames), phaseShiftValues);

% 打印实际使用分潮及其缩放/修正值（便于用户确认）
fprintf('      实际使用分潮列表：\n');
for k = 1:E.nCon
    cname = E.names{k};
    scale = 1.0;
    if isKey(ampScaleMap, upper(cname))
        scale = ampScaleMap(upper(cname));
    end
    shift = 0.0;
    if isKey(phaseShiftMap, upper(cname))
        shift = phaseShiftMap(upper(cname));
    end
    fprintf('          %s  (缩放=%.2f, 相位修正=%.1f°)\n', cname, scale, shift);
end

% -------- 5. 插值到开边界节点 --------
fprintf('\n[4/5] 插值 EOT20 到开边界节点...\n');

% 将节点经度转换为 EOT20 的经度约定
lonUse = lonOb;
if max(E.lon) > 180
    lonUse = mod(lonUse, 360);
else
    lonUse(lonUse > 180) = lonUse(lonUse > 180) - 360;
end

[LonGrid, LatGrid] = meshgrid(E.lon, E.lat);

% 预分配结果数组
Amp   = zeros(nNode, E.nCon);
Kappa = zeros(nNode, E.nCon);

% 主循环：对每个分潮进行插值
for k = 1:E.nCon
    cname = upper(E.names{k});
    
    % 取出该分潮的复振幅场（转置为 lon×lat）
    hRe = E.hRe(:,:,k).';
    hIm = E.hIm(:,:,k).';
    
    % 线性插值
    r = interp2(LonGrid, LatGrid, hRe, lonUse, latOb, 'linear', NaN);
    im = interp2(LonGrid, LatGrid, hIm, lonUse, latOb, 'linear', NaN);
    
    % 对插值失败的节点（NaN），用最近邻回填
    bad = isnan(r) | isnan(im);
    if any(bad)
        r(bad) = interp2(LonGrid, LatGrid, hRe, lonUse(bad), latOb(bad), 'nearest');
        im(bad) = interp2(LonGrid, LatGrid, hIm, lonUse(bad), latOb(bad), 'nearest');
    end
    
    % 复振幅 -> 振幅 & 相位
    H = r + 1i * im;
    amp = abs(H);
    phi = mod(atan2d(imag(H), real(H)), 360);
    
    % ---- 振幅缩放 ----
    if isKey(ampScaleMap, cname)
        scale = ampScaleMap(cname);
        if scale ~= 1.0
            amp = amp * scale;
        end
    end
    
    % ---- EOT20 -> ADCIRC 相位约定转换（M2/N2 +180°） ----
    if useSemiDiurnal180Shift && any(strcmpi(cname, semiDiurnal180Constituents))
        phi = mod(phi + 180, 360);
    end
    
    % ---- 额外相位修正 ----
    if isKey(phaseShiftMap, cname)
        shift = phaseShiftMap(cname);
        if shift ~= 0.0
            phi = mod(phi + shift, 360);
        end
    end
    
    Amp(:,k)   = amp;
    Kappa(:,k) = phi;
end
fprintf('      插值完成。\n');

% -------- 6. 计算节点因子（FF）和均衡引潮力（FACE） --------
fprintf('\n[5/5] 计算节点因子（FF）和均衡引潮力（FACE）...\n');
[FF, FACE] = compute_node_factor(tRefUTC, E.names, FF_fallback, FACE_fallback);
fprintf('      计算完成。\n');

% -------- 7. 写出 fort.15 潮汐块 --------
write_fort15_tide_block(outFile, E.names, E.omega, FF, FACE, Amp, Kappa);
fprintf('\n✅ 已写入: %s\n', outFile);

fprintf('\n========================================\n');
fprintf('  运行完成！\n');
fprintf('========================================\n');


%% ===================== 本地辅助函数 =====================
function write_fort15_tide_block(outfile, names, omega, FF, FACE, Amp, Kappa)
% 按 ADCIRC fort.15 格式输出潮汐块
fid = fopen(outfile, 'w');
if fid < 0, error('无法创建输出文件: %s', outfile); end
clean = onCleanup(@() fclose(fid));

nCon = numel(names);
nNode = size(Amp, 1);

fprintf(fid, '%d\t \t ! NBFR\n', nCon);
for k = 1:nCon
    fprintf(fid, '%s\t\t ! BOUNTAG, AMIG, FF, FACE\n', names{k});
    fprintf(fid, '%.10f %.6f  %.6f\n', omega(k), FF(k), FACE(k));
end
for k = 1:nCon
    fprintf(fid, '%s\n', names{k});
    for i = 1:nNode
        fprintf(fid, '    %10.6f   %11.6f\n', Amp(i,k), Kappa(i,k));
    end
end
fprintf(fid, '\n');
end