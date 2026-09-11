% MACHOTE GENERAL - vibracion libre amortiguada
% m  = 0;   % kg
% c  = 0;   % N*s/m
% k  = 0;   % N/m
% x0 = 0;   % m
% v0 = 0;   % m/s
%
% [regimen, wn, ccr, z] = VM.clasifA('m',m, 'c',c, 'k',k)
% [r, caso] = VM.amortA('m',m, 'c',c, 'k',k, 'x0',x0, 'v0',v0);
%
% campos = fieldnames(r);
% for i = 1:numel(campos)
%     fprintf('%-6s = %.4f\n', campos{i}, double(r.(campos{i})));
% end
clear; clc;
%ejercicio 1
g = 9.81 %m/s^2
c1 = 230 %Ns/m
k1 = 1500 %N/m
m11 = 4 %kg
m12 = 9 %kg
M1= m11 + m12;
h1 = 0.8 %m
syms v1 v_12
v11 = double(solve(g*h1==0.5*M1*v1^2), v1)
v12 = double(m1*v11==M*v_12,v_12)

[regimen, wn, ccr, z] = VM.clasifA('m',M1, 'c',c1, 'k',k1)
[r, caso] = VM.amortA('m',M1, 'c',c1, 'k',k1, 'x0',0);

campos = fieldnames(r);
for i = 1:numel(campos)
    fprintf('%-6s = %.4f\n', campos{i}, double(r.(campos{i})));
end