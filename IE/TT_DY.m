%{
DIAGRAMA: DELTA - ESTRELLA (Δ - Y)

         A o-------+-------------------+
                   |                   |
         B o-------|-------+           |
                   |       |           |
         C o-------|-------|-------+   |
                   |       |       |   |
                  ---     ---     ---  |
                 ( . )   ( . )   ( . ) |
             NP1 (   )   (   )   (   ) |
                 (   )NP2(   )NP3(   ) |
                  ---     ---     ---  |
                   |       |       |   |
                   +-------+       |   |
                           +-------+   |
                                   +---+
                 =====================

         n o-------+-------+-------+
                   |       |       |
                  ---     ---     ---
                 ( . )   ( . )   ( . )
             NS1 (   )   (   )   (   )
                 (   )NS2(   )NS3(   )
                  ---     ---     ---
                   |       |       |
         a o-------+       |       |
                           |       |
         b o---------------+       |
                                   |
         c o-----------------------+
%}

%% FÓRMULAS
syms V_LP V_LS V_phiP V_phiS a N_P N_S real

% Relación de transformación por fase
a = N_P / N_S;
a = V_phiP / V_phiS;

% Voltajes de línea y fase
V_LP = V_phiP;
V_LS = sqrt(sym(3)) * V_phiS;

% Relación de voltajes de línea
rel_V = V_LP / V_LS; % V_phiP/(sqrt(3)*V_phiS) = a/sqrt(3)
