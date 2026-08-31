Locales = Locales or {}

Locales['pt-br'] = {
    ui = {
        vehicle = 'Veículo',
        noVehicle = 'SEM VEÍCULO',
        smartKey = 'CHAVE INTELIGENTE',
        sanAndreas = 'San Andreas',
        closeControls = 'Fechar controles',
        vehicleControlAria = 'Tela de controle do veículo',
        vehicleTabsAria = 'Categorias de controle do veículo',
        keyFobAria = 'Chave remota do veículo',
        fuel = '{value}% COMBUSTÍVEL',
        engineHealth = '{value}% MOTOR',

        tabs = {
            vehicle = 'VEÍCULO',
            doors = 'PORTAS',
            windows = 'JANELAS',
            seats = 'BANCOS',
            utility = 'FUNÇÕES',
            settings = 'AJUSTES'
        },

        settings = {
            accent = 'Destaque',
            custom = 'Personalizada',
            brightness = 'Brilho',
            uiBrightness = 'Interface',
            photoOverlay = 'Foto',
            position = 'Posição',
            size = 'Tamanho',
            move = 'Mover',
            reset = 'Redefinir',
            customAccentAria = 'Cor de destaque personalizada',
            brightnessAria = 'Brilho da interface',
            photoOverlayAria = 'Escurecimento da foto',
            sizeAria = 'Tamanho do controle do veículo',
            swatches = {
                cyan = 'Ciano',
                amber = 'Âmbar',
                emerald = 'Esmeralda',
                red = 'Vermelho',
                violet = 'Violeta',
                white = 'Branco'
            }
        },

        controls = {
            engineOn = 'Motor ligado',
            engineOff = 'Motor desligado',
            locked = 'Trancado',
            unlocked = 'Destrancado',
            radioOn = 'Rádio ligado',
            radioOff = 'Rádio desligado',
            hazards = 'Pisca-alerta',
            interiorLight = 'Luz interna',
            cruiseSet = 'Definir piloto',
            cruiseActive = 'Piloto {speed}',
            autopilotStart = 'Iniciar piloto auto',
            autopilotEnRoute = 'Piloto auto em rota',
            autopilotHolding = 'Piloto auto em espera',
            hoverStart = 'Iniciar voo pairado',
            hoverActive = 'Voo pairado',
            closeAll = 'Fechar tudo',
            allDown = 'Baixar tudo',
            allUp = 'Subir tudo',
            detach = 'Desacoplar',
            anchorDown = 'Âncora baixada',
            anchorUp = 'Âncora levantada',
            gearDown = 'Trem baixado',
            gearUp = 'Trem recolhido',
            gearBroken = 'Trem avariado',
            roof = 'Teto',
            extra = 'Extra {number}',
            noVehicleControls = 'Controles do veículo desativados',
            noDoorControls = 'Sem controles de portas',
            noWindowControls = 'Controles das janelas desativados',
            noSeatControls = 'Sem controles de bancos',
            noUtilityControls = 'Sem controles adicionais'
        },

        fob = {
            ready = 'PRONTO',
            noSignal = 'SEM SINAL',
            lock = 'TRANCAR',
            unlock = 'DESTRANCAR',
            start = 'LIGAR',
            stop = 'DESLIGAR',
            trunk = 'PORTA-MALAS',
            closeAction = 'FECHAR',
            windows = 'JANELAS',
            panic = 'PÂNICO',
            move = 'Mover a chave',
            drag = 'Arrastar a chave',
            resize = 'Redimensionar a chave',
            resizeWithScale = 'Redimensionar a chave ({scale}%)',
            closeKeyFob = 'Fechar a chave',
            brandTitle = 'Chave {make}',
            customBrandTitle = 'Chave de veículo personalizada'
        }
    },

    notifications = {
        vehicleControlsUnavailable = 'Os controles só estão disponíveis dentro de veículos compatíveis.',
        keyFobDisabled = 'Os controles da chave estão desativados.',
        useTouchscreenInside = 'Use a tela de controle enquanto estiver no veículo.',
        noRecentVehicle = 'Nenhum veículo dirigido recentemente foi encontrado.',
        vehicleLockChanged = 'Veículo {plate} {state}.',
        locked = 'trancado',
        unlocked = 'destrancado',
        seatOccupied = 'Esse banco está ocupado.',
        cannotAnchorHere = 'Não é possível ancorar aqui.',
        anchorTooFast = 'Reduza para menos de {speed} MPH antes de baixar a âncora.',
        anchorMoveBlocked = 'Recolha a âncora antes de tentar mover o barco.',
        cruiseUnavailable = 'O piloto automático só está disponível ao dirigir para frente com o motor ligado.',
        cruiseSpeedRange = 'O piloto automático está disponível entre {min} e {max} MPH.',
        autopilotNoWaypoint = 'Defina um destino no mapa antes de iniciar o piloto automático.',
        autopilotUnavailable = 'Para usar o piloto automático, você precisa estar em voo, no assento do piloto e com o motor ligado.',
        autopilotWaypointTooClose = 'Escolha um destino a pelo menos {distance} metros de distância.',
        autopilotPlaneTooSlow = 'Atinja pelo menos {speed} MPH antes de iniciar o piloto automático do avião.',
        hoverReleasedByInput = 'O modo de pairar foi desativado ao detectar uma ação do piloto.'
    },

    fobMessages = {
        ready = 'PRONTO',
        disabled = 'DESATIVADO',
        exitVehicle = 'SAIA DO VEÍCULO',
        noVehicle = 'SEM VEÍCULO',
        unsupported = 'NÃO COMPATÍVEL',
        tooFar = 'MUITO LONGE',
        noKey = 'SEM CHAVE',
        noSignal = 'SEM SINAL',
        locked = 'TRANCADO',
        unlocked = 'DESTRANCADO',
        engineOn = 'MOTOR LIGADO',
        engineOff = 'MOTOR DESLIGADO',
        trunkOpen = 'PORTA-MALAS ABERTO',
        trunkClosed = 'PORTA-MALAS FECHADO',
        noTrunk = 'SEM PORTA-MALAS',
        windowsDown = 'JANELAS ABAIXADAS',
        windowsUp = 'JANELAS LEVANTADAS',
        panic = 'PÂNICO',
        panicOff = 'PÂNICO DESLIGADO'
    },

    keyMappings = {
        touchscreen = 'Alternar controles da tela do veículo',
        keyFob = 'Alternar chave remota do veículo'
    },

    vehicleClasses = {
        [0] = 'Compactos',
        [1] = 'Sedãs',
        [2] = 'SUVs',
        [3] = 'Cupês',
        [4] = 'Muscle',
        [5] = 'Clássicos esportivos',
        [6] = 'Esportivos',
        [7] = 'Supercarros',
        [8] = 'Motocicletas',
        [9] = 'Off-road',
        [10] = 'Industriais',
        [11] = 'Utilitários',
        [12] = 'Vans',
        [13] = 'Bicicletas',
        [14] = 'Barcos',
        [15] = 'Helicópteros',
        [16] = 'Aviões',
        [17] = 'Serviço',
        [18] = 'Emergência',
        [19] = 'Militares',
        [20] = 'Comerciais',
        [21] = 'Trens',
        [22] = 'Fórmula'
    },

    doors = {
        [0] = 'Motorista',
        [1] = 'Passageiro',
        [2] = 'Traseira esquerda',
        [3] = 'Traseira direita',
        [4] = 'Capô',
        [5] = 'Porta-malas'
    },

    seats = {
        [-1] = 'Motorista',
        [0] = 'Passageiro',
        [1] = 'Traseiro esquerdo',
        [2] = 'Traseiro direito',
        [3] = 'Banco 5',
        [4] = 'Banco 6'
    },

    generic = {
        door = 'Porta {number}',
        window = 'Janela {number}',
        seat = 'Banco {number}'
    }
}
