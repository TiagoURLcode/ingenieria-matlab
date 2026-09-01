classdef TT
    %{
    TT — Transformadores Trifásicos. Métodos estáticos: TT.nombre(d).
         Cada uno arma el sistema de su conexión y lo pasa por IE.despejar,
         así que se le da lo que se sabe y devuelve todo lo que se pueda.

      TT.YY(d)    Estrella - Estrella (Y-Y)
      TT.DD(d)    Delta - Delta (Δ-Δ)
      TT.YD(d)    Estrella - Delta (Y-Δ)
      TT.DY(d)    Delta - Estrella (Δ-Y)
      TT.mono(d)  Monofásico: mismos campos, sin sqrt(3)

    VARIABLES (todas opcionales en d, se usa lo que haya)
      V_LP  V_phiP  V_LS  V_phiS      tensiones de línea y de fase   [V]
      I_LP  I_phiP  I_LS  I_phiS      corrientes de línea y de fase  [A]
      ang_VLP ang_VphiP ang_VLS ang_VphiS    ángulos de las tensiones [grados]
      ang_ILP ang_IphiP ang_ILS ang_IphiS    ángulos de las corrientes[grados]
      a       relación de transformación POR FASE, a = V_phiP/V_phiS  [-]
      N_P N_S vueltas por fase de cada devanado                       [-]
      S       potencia aparente TRIFÁSICA, sqrt(3)*V_L*I_L           [VA]
      theta   ángulo del factor de potencia de la carga, + atrasado [grados]
      desf    desfase de la conexión, ang_VLP - ang_VLS             [grados]

    ÁNGULOS: si no se pasa ninguno, se toma ang_VphiP = 0 como referencia.
      Sin theta no salen los ángulos de las corrientes.

    DE DÓNDE SALE EL DESFASE (no está puesto a mano, cae solo)
      Y : V_L = sqrt(3)*V_phi, la línea ADELANTA 30° a la fase
          I_L = I_phi, mismo ángulo
      Δ : V_L = V_phi, mismo ángulo
          I_L = sqrt(3)*I_phi, la línea ATRASA 30° a la fase
      Las bobinas del mismo núcleo van en fase (punto con punto), o sea
      ang_VphiS = ang_VphiP. Combinando eso con las dos reglas de arriba:
          Y-Y y Δ-Δ  ->  desf = 0     (secundario en fase con el primario)
          Y-Δ        ->  desf = +30   (el secundario ATRASA 30°)
          Δ-Y        ->  desf = -30   (el secundario ADELANTA 30°)
      Si tu banco está marcado al revés (permutando dos fases) el signo se
      invierte: es la diferencia entre Dy11 y Dy1.
    %}

    methods(Static)

        %{
        YY — ESTRELLA - ESTRELLA (Y - Y)

                 A o-------+
                           |
                 B o-------|-------+
                           |       |
                 C o-------|-------|-------+
                           |       |       |
                          ---     ---     ---
                         ( . )   ( . )   ( . )
                     NP1 (   )   (   )   (   )
                         (   )NP2(   )NP3(   )
                          ---     ---     ---
                           |       |       |
                 N o-------+-------+-------+

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

          V_LP = sqrt(3)*V_phiP     V_LS = sqrt(3)*V_phiS
          V_LP/V_LS = a             desf = 0

        Ej: r = TT.YY(struct('V_LP',13800,'a',10))
        %}
        function res = YY(d)
            res = TT.resolver('Y', 'Y', d);
        end

        %{
        DD — DELTA - DELTA (Δ - Δ)

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
                           +-------+
                           |       +-------+
                           |               +---+
                          ---     ---     ---  |
                         ( . )   ( . )   ( . ) |
                     NS1 (   )   (   )   (   ) |
                         (   )NS2(   )NS3(   ) |
                          ---     ---     ---  |
                           |       |       |   |
                 a o-------+       |       |   |
                           |       |       |   |
                 b o---------------+       |   |
                           |       |       |   |
                 c o-----------------------+---+

          V_LP = V_phiP             V_LS = V_phiS
          V_LP/V_LS = a             desf = 0

        Ej: r = TT.DD(struct('V_LP',13800,'a',10))
        %}
        function res = DD(d)
            res = TT.resolver('D', 'D', d);
        end

        %{
        YD — ESTRELLA - DELTA (Y - Δ)

                 A o-------+
                           |
                 B o-------|-------+
                           |       |
                 C o-------|-------|-------+
                           |       |       |
                          ---     ---     ---
                         ( . )   ( . )   ( . )
                     NP1 (   )   (   )   (   )
                         (   )NP2(   )NP3(   )
                          ---     ---     ---
                           |       |       |
                 N o-------+-------+-------+

                         =====================

                           +-------+
                           |       +-------+
                           |               +---+
                          ---     ---     ---  |
                         ( . )   ( . )   ( . ) |
                     NS1 (   )   (   )   (   ) |
                         (   )NS2(   )NS3(   ) |
                          ---     ---     ---  |
                           |       |       |   |
                 a o-------+       |       |   |
                           |       |       |   |
                 b o---------------+       |   |
                           |       |       |   |
                 c o-----------------------+---+

          V_LP = sqrt(3)*V_phiP     V_LS = V_phiS
          V_LP/V_LS = sqrt(3)*a     desf = +30 (el secundario ATRASA)

        Ej: r = TT.YD(struct('V_LP',13800,'a',10,'theta',36.87))
        %}
        function res = YD(d)
            res = TT.resolver('Y', 'D', d);
        end

        %{
        DY — DELTA - ESTRELLA (Δ - Y)

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

          V_LP = V_phiP             V_LS = sqrt(3)*V_phiS
          V_LP/V_LS = a/sqrt(3)     desf = -30 (el secundario ADELANTA)

        Ej: r = TT.DY(struct('V_LP',13800,'a',10))
        %}
        function res = DY(d)
            res = TT.resolver('D', 'Y', d);
        end

        %{
        mono — MONOFÁSICO. Mismos campos que las trifásicas para poder
        intercambiarlas, pero sin sqrt(3): línea y fase son lo mismo de los
        dos lados, no hay desfase de conexión (desf = 0) y la potencia es
        S = V_L*I_L, no sqrt(3)*V_L*I_L.

                 L o-------+
                           |
                          ---
                         ( . )
                     N_P (   )
                         (   )
                          ---
                           |
                 N o-------+

                         =========

                 a o-------+
                           |
                          ---
                         ( . )
                     N_S (   )
                         (   )
                          ---
                           |
                 b o-------+

        Ej: r = TT.mono(struct('V_LP',2400,'a',10,'S',15e3,'theta',31.79))
        %}
        function res = mono(d)
            res = TT.resolver('1', '1', d);
        end

    end

    methods(Static, Access = private)

        %{
        resolver — Fija la referencia de ángulos si no se dio ninguno, pasa
        el sistema por IE.despejar y devuelve numérico lo que se pueda.
        %}
        function res = resolver(cP, cS, d)
            if nargin < 3 || isempty(d), d = struct(); end
            if ~any(startsWith(fieldnames(d), 'ang'))
                d.ang_VphiP = 0;        % referencia: fase A del primario
            end
            [eqs, Sy] = TT.modelo(cP, cS);
            sal = IE.despejar(eqs, Sy, d);

            %  despejar solo devuelve lo que DESPEJÓ, no lo que se le dio:
            %  se arranca de los datos y se le encima lo despejado.
            res = d;
            campos = fieldnames(sal);
            for k = 1:numel(campos)
                res.(campos{k}) = sal.(campos{k});
            end
            campos = fieldnames(res);
            for k = 1:numel(campos)
                try, res.(campos{k}) = double(res.(campos{k})); catch, end %#ok<NOCOM>
            end
        end

        %{
        modelo — Sistema simbólico de la conexión cP-cS.
          cP, cS : 'Y' (estrella), 'D' (delta) o '1' (monofásico)
        %}
        function [eqs, Sy] = modelo(cP, cS)
            nom = {'V_LP','V_phiP','V_LS','V_phiS', ...
                'ang_VLP','ang_VphiP','ang_VLS','ang_VphiS', ...
                'I_LP','I_phiP','I_LS','I_phiS', ...
                'ang_ILP','ang_IphiP','ang_ILS','ang_IphiS', ...
                'a','N_P','N_S','S','theta','desf'};
            Sy  = cell2struct(cellfun(@sym, nom, 'UniformOutput', false)', ...
                nom', 1);

            [kVP, dVP, kIP, dIP] = TT.factores(cP);
            [kVS, dVS, kIS, dIS] = TT.factores(cS);
            if cP == '1', kS = 1; else, kS = sqrt(sym(3)); end

            eqs = [ % ---- lado PRIMARIO: línea vs fase
                Sy.V_LP     == kVP*Sy.V_phiP
                Sy.ang_VLP  == Sy.ang_VphiP + dVP
                Sy.I_LP     == kIP*Sy.I_phiP
                Sy.ang_ILP  == Sy.ang_IphiP + dIP
                % ---- lado SECUNDARIO: línea vs fase
                Sy.V_LS     == kVS*Sy.V_phiS
                Sy.ang_VLS  == Sy.ang_VphiS + dVS
                Sy.I_LS     == kIS*Sy.I_phiS
                Sy.ang_ILS  == Sy.ang_IphiS + dIS
                % ---- enlace entre los dos lados (bobinas en fase)
                Sy.V_phiP   == Sy.a*Sy.V_phiS       % relación POR FASE
                Sy.I_phiS   == Sy.a*Sy.I_phiP       % N_P*I_P = N_S*I_S
                Sy.a        == Sy.N_P/Sy.N_S
                Sy.ang_VphiS == Sy.ang_VphiP        % punto con punto
                Sy.ang_IphiS == Sy.ang_IphiP
                % ---- carga y potencia
                Sy.ang_IphiS == Sy.ang_VphiS - Sy.theta
                Sy.S        == kS*Sy.V_LP*Sy.I_LP
                Sy.S        == kS*Sy.V_LS*Sy.I_LS
                % ---- desfase de la conexión
                Sy.desf     == Sy.ang_VLP - Sy.ang_VLS ];
        end

        %{
        factores — Los cuatro números que distinguen una conexión:
          kV, dV : V_L = kV*V_phi,  ang_VL = ang_Vphi + dV
          kI, dI : I_L = kI*I_phi,  ang_IL = ang_Iphi + dI
        %}
        function [kV, dV, kI, dI] = factores(c)
            r3 = sqrt(sym(3));
            switch c
                case 'Y', kV = r3; dV =  30;  kI = 1;   dI =   0;
                case 'D', kV = 1;  dV =   0;  kI = r3;  dI = -30;
                case '1', kV = 1;  dV =   0;  kI = 1;   dI =   0;
                otherwise
                    error('TT:conexion', 'Conexión "%s": usá Y, D o 1.', c);
            end
        end

    end
end
