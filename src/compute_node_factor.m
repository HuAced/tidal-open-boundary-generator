function [FF, FACE] = compute_node_factor(t_ref, constituentNames, FF_fallback, FACE_fallback)
%COMPUTE_NODE_FACTOR  计算指定分潮的节点因子和均衡引潮力
%   [FF, FACE] = COMPUTE_NODE_FACTOR(t_ref, constituentNames, FF_fallback, FACE_fallback)
%   基于参考时间计算各分潮的节点因子（Nodal Factor）和均衡引潮力（Equilibrium Argument）。
%
%   输入：
%       t_ref             - 参考时间（datetime 对象，UTC）
%       constituentNames  - 分潮名称列表（cell 字符串）
%       FF_fallback       - 未找到分潮时的默认 FF 值
%       FACE_fallback     - 未找到分潮时的默认 FACE 值
%
%   输出：
%       FF    - 节点因子，各分潮对应的数值向量
%       FACE  - 均衡引潮力（度），各分潮对应的数值向量
%
%   算法参考：
%       Schureman (1958) 潮汐调和分析理论
%       NOAA 天文参数计算方法
%
%   作者: Aced Hu
%   日期: 2026-06-22
%
%   内部函数：
%       orbit_noaa(t)     - 计算 NOAA 天文参数
%       compute_all_vuf(O)- 计算 37 个标准分潮的 FF 和 FACE
%       angle360(a)       - 将角度归一化到 0~360 度
%
%   分潮表包含 37 个常用分潮，未在表中的分潮会使用默认值并给出警告。

% ==================== 内部分潮表 ====================
% 顺序固定，与 Schureman 算法对应（共 37 个分潮）
internalNames = {'M2','S2','N2','K1','M4','O1','M6','MK3','S4','MN4', ...
                 'NU2','S6','MU2','2N2','OO1','LAMBDA2','S1','M1','J1', ...
                 'MM','SSA','SA','MSF','MF','RHO1','Q1','T2','R2','2Q1', ...
                 'P1','2SM2','M3','L2','2MK3','K2','M8','MS4'};

nInternal = length(internalNames);

% ==================== 计算天文参数 ====================
O = orbit_noaa(t_ref);

% 计算所有 37 个分潮的 FF 和 FACE
[FF_all, FACE_all] = compute_all_vuf(O);

% ==================== 匹配用户指定的分潮 ====================
nUser = length(constituentNames);
FF = zeros(1, nUser);
FACE = zeros(1, nUser);

for i = 1:nUser
    idx = find(strcmpi(constituentNames{i}, internalNames), 1);
    if ~isempty(idx)
        FF(i) = FF_all(idx);
        FACE(i) = FACE_all(idx);
    else
        % 未找到则使用默认值
        FF(i) = FF_fallback;
        FACE(i) = FACE_fallback;
        warning('分潮 %s 未在内部表中找到，使用默认值 FF=%.2f, FACE=%.2f', ...
            constituentNames{i}, FF_fallback, FACE_fallback);
    end
end

% 确保 FACE 在 0~360 范围内
FACE = mod(FACE, 360);

end


% ==================== 内部计算函数 ====================

function [FF_vec, FACE_vec] = compute_all_vuf(O)
% 计算所有 37 个分潮的节点因子和均衡引潮力

% 先计算天文参数
S = O.DS; H = O.DH; P = O.DP; P1 = O.DP1;
T = angle360(180 + O.HR * (360/24));
NU = O.DNU; XI = O.DXI; NUP = O.DNUP; NUP2 = O.DNUP2;
I = O.DI * pi/180;
PC = deg2rad(angle360(O.DP - O.DXI));

% ---- 均衡引潮力（37 个分潮） ----
FACE_vec = zeros(1, 37);

FACE_vec(1)  = angle360(2*(T - S + H) + 2*(XI - NU));                % M2
FACE_vec(2)  = angle360(2*T);                                         % S2
FACE_vec(3)  = angle360(2*(T + H) - 3*S + P + 2*(XI - NU));          % N2
FACE_vec(4)  = angle360(T + H - 90 - NUP);                            % K1
FACE_vec(5)  = angle360(4*(T - S + H) + 4*(XI - NU));                % M4
FACE_vec(6)  = angle360(T - 2*S + H + 90 + 2*XI - NU);               % O1
FACE_vec(7)  = angle360(6*(T - S + H) + 6*(XI - NU));                % M6
FACE_vec(8)  = angle360(3*(T + H) - 2*S - 90 + 2*(XI - NU) - NUP);   % MK3
FACE_vec(9)  = angle360(4*T);                                         % S4
FACE_vec(10) = angle360(4*(T + H) - 5*S + P + 4*(XI - NU));          % MN4
FACE_vec(11) = angle360(2*T - 3*S + 4*H - P + 2*(XI - NU));          % NU2
FACE_vec(12) = angle360(6*T);                                         % S6
FACE_vec(13) = angle360(2*(T + 2*(H - S)) + 2*(XI - NU));            % MU2
FACE_vec(14) = angle360(2*(T - 2*S + H + P) + 2*(XI - NU));          % 2N2
FACE_vec(15) = angle360(T + 2*S + H - 90 - 2*XI - NU);               % OO1
FACE_vec(16) = angle360(2*T - S + P + 180 + 2*(XI - NU));            % LAMBDA2
FACE_vec(17) = angle360(T);                                           % S1
FACE_vec(18) = angle360(T - S + H - 90 + XI - NU + ...
    atan2d((5*cos(I)-1)*sin(PC), (7*cos(I)+1)*cos(PC)));            % M1
FACE_vec(19) = angle360(T + S + H - P - 90 - NU);                    % J1
FACE_vec(20) = angle360(S - P);                                       % MM
FACE_vec(21) = angle360(2*H);                                         % SSA
FACE_vec(22) = angle360(H);                                           % SA
FACE_vec(23) = angle360(2*(S - H));                                   % MSF
FACE_vec(24) = angle360(2*S - 2*XI);                                  % MF
FACE_vec(25) = angle360(T + 3*(H - S) - P + 90 + 2*XI - NU);         % RHO1
FACE_vec(26) = angle360(T - 3*S + H + P + 90 + 2*XI - NU);           % Q1
FACE_vec(27) = angle360(2*T - H + P1);                                % T2
FACE_vec(28) = angle360(2*T + H - P1 + 180);                          % R2
FACE_vec(29) = angle360(T - 4*S + H + 2*P + 90 + 2*XI - NU);         % 2Q1
FACE_vec(30) = angle360(T - H + 90);                                  % P1
FACE_vec(31) = angle360(2*(T + S - H) + 2*(NU - XI));                % 2SM2
FACE_vec(32) = angle360(3*(T - S + H) + 3*(XI - NU));                % M3
% L2 特殊处理
R = atan2d(sin(2*PC), (1/6)*(1/tan(0.5*I))^2 - cos(2*PC));
FACE_vec(33) = angle360(2*(T + H) - S - P + 180 + 2*(XI - NU) - R);  % L2
FACE_vec(34) = angle360(3*(T + H) - 4*S + 90 + 4*(XI - NU) + NUP);   % 2MK3
FACE_vec(35) = angle360(2*(T + H) - 2*NUP2);                          % K2
FACE_vec(36) = angle360(8*(T - S + H) + 8*(XI - NU));                % M8
FACE_vec(37) = angle360(2*(2*T - S + H) + 2*(XI - NU));              % MS4

% ---- 节点因子（37 个分潮） ----
SINI = sin(I);
SINI2 = sin(I/2);
COSI2 = cos(I/2);

% 基础因子
EQ73  = (2/3 - SINI.^2) / 0.5021;      % MM
EQ74  = (SINI.^2) / 0.1578;            % MF
EQ75  = (SINI .* COSI2.^2) / 0.37988;  % O1
EQ76  = sin(2*I) / 0.7214;             % J1
EQ77  = (SINI .* SINI2.^2) / 0.0164;   % OO1
EQ78  = (COSI2.^4) / 0.91544;          % M2 等
EQ149 = (COSI2.^6) / 0.8758;           % M3
EQ227 = sqrt(0.8965*sin(2*I)^2 + 0.6001*sin(2*I)*cosd(O.DNU) + 0.1006);  % K1
EQ235 = 0.001 + sqrt(19.0444*SINI^4 + 2.7702*SINI^2*cosd(2*O.DNU) + 0.0981); % K2

% 按顺序分配
FF_vec = zeros(1, 37);
FF_vec(1)  = EQ78;    % M2
FF_vec(2)  = 1.0;     % S2
FF_vec(3)  = EQ78;    % N2
FF_vec(4)  = EQ227;   % K1
FF_vec(5)  = EQ78^2;  % M4
FF_vec(6)  = EQ75;    % O1
FF_vec(7)  = EQ78^3;  % M6
FF_vec(8)  = EQ78 * EQ227;     % MK3
FF_vec(9)  = 1.0;     % S4
FF_vec(10) = EQ78^2;  % MN4
FF_vec(11) = EQ78;    % NU2
FF_vec(12) = 1.0;     % S6
FF_vec(13) = EQ78;    % MU2
FF_vec(14) = EQ78;    % 2N2
FF_vec(15) = EQ77;    % OO1
FF_vec(16) = EQ78;    % LAMBDA2
FF_vec(17) = 1.0;     % S1
FF_vec(18) = 0.0;     % M1（特殊处理，一般为0）
FF_vec(19) = EQ76;    % J1
FF_vec(20) = EQ73;    % MM
FF_vec(21) = 1.0;     % SSA
FF_vec(22) = 1.0;     % SA
FF_vec(23) = EQ78;    % MSF
FF_vec(24) = EQ74;    % MF
FF_vec(25) = EQ75;    % RHO1
FF_vec(26) = EQ75;    % Q1
FF_vec(27) = 1.0;     % T2
FF_vec(28) = 1.0;     % R2
FF_vec(29) = EQ75;    % 2Q1
FF_vec(30) = 1.0;     % P1
FF_vec(31) = EQ78;    % 2SM2
FF_vec(32) = EQ149;   % M3
FF_vec(33) = 0.0;     % L2（特殊处理）
FF_vec(34) = EQ78^2 * EQ227;  % 2MK3
FF_vec(35) = EQ235;   % K2
FF_vec(36) = EQ78^4;  % M8
FF_vec(37) = EQ78;    % MS4

end


function O = orbit_noaa(t)
% ORBIT_NOAA  计算 NOAA 天文参数
%   基于参考时间计算日月轨道参数
%   参考：Schureman (1958), NOAA 潮汐分析方法

% 提取日期时间
y = year(t);
dayJ = day(t, 'dayofyear');
hr = hour(t) + minute(t)/60 + second(t)/3600;

% 计算儒略日相关参数
X = floor((y - 1901) / 4);
DYR = y - 1900;
DDAY = dayJ + X - 1;

% ---- 计算天文参数（度） ----
% N（月球升交点经度）
DN = 259.1560564 - 19.328185764*DYR - 0.0529539336*DDAY - 0.0022064139*hr;
DN = angle360(DN);

% P（月球近地点经度）
DP = 334.3837214 + 40.66246584*DYR + 0.111404016*DDAY + 0.004641834*hr;
DP = angle360(DP);

% I（月球轨道倾角）
Nrad = deg2rad(DN);
I = acos(0.9136949 - 0.0356926*cos(Nrad));
DI = rad2deg(I);

% NU（月球轨道摄动）
NU = asin(0.0897056*sin(Nrad) / sin(I));
DNU = rad2deg(NU);

% XI（月球平近点角摄动）
XI = Nrad - 2*atan(0.64412*tan(Nrad/2)) - NU;
DXI = rad2deg(XI);

% H（太阳平黄经）
DH = 280.1895014 - 0.238724988*DYR + 0.9856473288*DDAY + 0.0410686387*hr;
DH = angle360(DH);

% P1（太阳近地点经度）
DP1 = 281.2208569 + 0.01717836*DYR + 0.000047064*DDAY + 0.000001961*hr;
DP1 = angle360(DP1);

% S（月球平黄经）
DS = 277.0256206 + 129.38482032*DYR + 13.176396768*DDAY + 0.549016532*hr;
DS = angle360(DS);

% NUP（K1 分潮的摄动）
NUP = atan(sin(NU) / (cos(NU) + 0.334766/sin(2*I)));
DNUP = rad2deg(NUP);

% NUP2（K2 分潮的摄动）
NUP2 = 0.5 * atan(sin(2*NU) / (cos(2*NU) + 0.0726184/sin(I)^2));
DNUP2 = rad2deg(NUP2);

% 构造输出结构
O = struct();
O.DS = DS;
O.DP = DP;
O.DH = DH;
O.DP1 = DP1;
O.DN = DN;
O.DI = DI;
O.DNU = DNU;
O.DXI = DXI;
O.DNUP = DNUP;
O.DNUP2 = DNUP2;
O.HR = hr;

end


function a = angle360(a)
% ANGLE360  将角度归一化到 0~360 度
a = mod(a, 360);
if any(a(:) < 0)
    a(a < 0) = a(a < 0) + 360;
end
end