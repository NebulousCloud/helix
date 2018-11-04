
NAME = "Español"

LANGUAGE = {
	helix = "Helix",

	introTextOne = "fist industries presenta",
	introTextTwo = "en colaboración con %s",
	introContinue = "pulsa espacio para continuar",

	helpIdle = "Selecciona una categoría",
	helpCommands = "Los parámetros de comando con <flechas> son requeridos, mientras que con [corchetes] son opcionales.",
	helpFlags = "Las Flags con un fondo verde son accesibles por este personaje.",

	creditSpecial = "Muchas Gracias",
	creditLeadDeveloper = "Desarrollador Principál",
	creditUIDesigner = "Diseñador de interfaz de Usuario",
	creditManager = "Gerente del Proyecto",
	creditTester = "Tester Principal",

	chatTyping = "Escribiendo...",
	chatTalking = "Hablando...",
	chatYelling = "Gritando...",
	chatWhispering = "Susurrando...",
	chatPerforming = "Actuando...",
	chatNewTab = "Nueva pestaña...",
	chatReset = "Reiniciar posición",
	chatResetTabs = "Reiniciar pestañas",
	chatCustomize = "Customizar...",
	chatCloseTab = "Cerrar Pestaña",
	chatTabName = "Nombre de Pestaña",
	chatAllowedClasses = "Clases de chat Permitidas",
	chatTabExists = "¡Una pestaña de chat con ese nombre ya existe!",
	chatMarkRead = "Marcar todos como leído",

	community = "Comunidad",
	checkAll = "Marcar Todos",
	uncheckAll = "Desmarcar Todos",
	color = "Color",
	type = "Tipo",
	display = "Mostrar",
	loading = "Cargando",
	dbError = "Fallo de conexión con la Base de Datos",
	unknown = "Desconocido",
	noDesc = "Descripción no disponible",
	create = "Crear",
	update = "Actualizar",
	load = "Cargar personaje",
	loadTitle = "Cargar un Personaje",
	-- loadTip = "Escoge un personaje previamente creado con el que jugar.",
	leave = "Abandonar",
	leaveTip = "Abandona el servidor actual.",
	["return"] = "Volver",
	returnTip = "Vuelve al menú anterior.",
	proceed = "Proceder",
	faction = "Facción",
	skills = "Habilidades",
	choose = "Escoger",
	chooseFaction = "Escoge una Faccion", -- Without an accent, due to the font not having the capitalized accent on the menu
	chooseDescription = "Define tu Narrativa",
	chooseSkills = "Afina tus Habilidades",
	name = "Nombre",
	description = "Descripcion", -- Without an accent, due to the font not having the capitalized accent on the menu
	model = "Modelo",
	attributes = "Atributos",
	attribPointsLeft = "Puntos restantes",
	charCreated = "Has creado tu personaje de forma satisfactoria.",
	charCreateTip = "Completa todos los campos obligatorios y haz clic en 'Finalizar' para crear a tu personaje.",
	invalid = "Has provisto un %s inválido.",
	nameMinLen = "Tu nombre debe de tener al menos %d caracteres.",
	nameMaxLen = "Tu nombre no puede tener mas de %d caracteres.",
	descMinLen = "Tu descripción debe tener al menos %d caracteres.",
	maxCharacters = "¡No puedes crear mas personajes!",
	player = "Jugador",
	finish = "Finalizar",
	finishTip = "Finaliza la creación de personaje.",
	needModel = "Necesitas escoger un modelo válido.",
	creating = "Tu personaje está siendo creado...",
	unknownError = "Ha ocurrido un error desconocido",
	areYouSure = "¿Estas seguro?",
	delete = "Borrar",
	deleteConfirm = "¡Este personaje será eliminado PERMANENTEMENTE!",
	deleteComplete = "%s ha sido eliminado.",
	no = "No",
	yes = "Sí",
	close = "Cerrar",
	save = "Guardar",
	itemInfo = "Nombre: %s\nDescripción: %s",
	itemCreated = "Objeto(s) creado(s) de forma satisfactoria.",
	cloud_no_repo = "El repositorio provisto no es válido.",
	cloud_no_plugin = "El plugin provisto no es válido.",
	inv = "Inventario",
	plugins = "Plugins",
	author = "Autor",
	version = "Versión",
	characters = "Personajes",
	business = "Negocios",
	settings = "Opciones",
	config = "Configuracion", -- Without an accent, due to the font not having the capitalized accent on the menu
	chat = "Chat",
	appearance = "Apariencia",
	misc = "Misceláneo",
	oocDelay = "Espera %s segundo(s) antes de usar el chat OOC de nuevo.",
	loocDelay = "Espera %s segundo(s) antes de usar el chat LOOC de nuevo.",
	usingChar = "Ya estás usando éste personaje.",
	notAllowed = "Lo siento, no tienes permitido hacer eso.",
	itemNoExist = "Lo siento, el objeto que solicitaste no existe.",
	cmdNoExist = "Lo siento, éste comando no existe.",
	charNoExist = "Lo siento, un personaje correspondiendo no ha podido ser encontrado.",
	plyNoExist = "Lo siento, el jugador correspondiente no ha podido ser encontrado.",
	cfgSet = "%s ha establecido \"%s\" a %s.",
	drop = "Tirar",
	dropTip = "Tira el objeto de tu inventario.",
	take = "Coger",
	takeTip = "Coge éste objeto y lo coloca en tu inventario.",
	dTitle = "Puerta sin propietario",
	dTitleOwned = "Puerta comprada",
	dIsNotOwnable = "Está puerta no puede se poseer.",
	dIsOwnable = "Puedes comprar ésta puerta pulsando F2.",
	dMadeUnownable = "Has hecho ésta puerta 'No poseíble'.",
	dMadeOwnable = "Has hecho ésta puerta 'Poseíble'.",
	dNotAllowedToOwn = "No tienes permiso a poseer ésta puerta.",
	dSetDisabled = "Has hecho ésta puerta 'Dehabilitada'.",
	dSetNotDisabled = "Has hecho ésta puerta 'Habilitada'.",
	dSetHidden = "Has hecho que ésta puerta esté oculta.",
	dSetNotHidden = "Has hecho que ésta puerta no esté oculta.",
	dSetParentDoor = "Has establecido ésta puerta como tu puerta madre.",
	dCanNotSetAsChild = "No puedes establecer la puerta madre como puerta hija.",
	dAddChildDoor = "Has añadido ésta puerta como puerta hija.",
	dRemoveChildren = "Has eliminado todas las puertas hijas de ésta puerta.",
	dRemoveChildDoor = "Has eliminado ésta puerta como puerta hija.",
	dNoParentDoor = "No tienes una puerta madre establecida.",
	dOwnedBy = "Ésta puerta está poseída por %s.",
	dConfigName = "Puertas",
	dSetFaction = "Ésta puerta ahora pertenece a la facción %s.",
	dRemoveFaction = "Ésta puerta ya no pertenece a ninguna facción.",
	dNotValid = "No estás mirando a una puerta válida.",
	canNotAfford = "No puedes permitirte el gasto para comprar esto.",
	dPurchased = "Has comprado ésta puerta por %s.",
	dSold = "Has vendido ésta puerta por %s.",
	notOwner = "No eres el propietario de esto.",
	invalidArg = "Has provisto un valor inválido para el argumento #%s.",
	invalidFaction = "La facción que has provisto es inválida.",
	flagGive = "%s ha dado a %s las flags '%s'.",
	flagGiveTitle = "Dar Flags",
	-- flagGiveDesc = "Da las siguientes flags al jugador.",
	flagTake = "%s ha quitado las flags '%s' de %s.",
	flagTakeTitle = "Quitar Flags",
	-- flagTakeDesc = "Quita las siguientes flags del jugador.",
	flagNoMatch = "Debes tener la(s) flag(s) \"%s\" para hacer ésta acción.",
	textAdded = "Has añadido un texto.",
	textRemoved = "Has borrado %s texto(s).",
	moneyTaken = "Has encontrado %s.",
	moneyGiven = "Te han dado %s.",
	insufficientMoney = "No tienes dinero suficiente para hacer esto.",
	businessPurchase = "Has comprado %s por %s.",
	businessSell = "Has vendido %s por %s.",
	businessTooFast = "Por favor, espera antes de comprar otro objeto.",
	cChangeModel = "%s ha cambiado el modelo de %s a %s.",
	cChangeName = "%s ha cambiado el nombre de %s a %s.",
	cChangeSkin = "%s ha cambiado el skin de %s a %s.",
	cChangeGroups = "%s ha cambiado el bodygroup \"%s\" de %s a %s.",
	cChangeFaction = "%s ha transferido a %s a la facción %s.",
	playerCharBelonging = "Éste objeto ya pertenece a otro de tus personajes.",
	spawnAdd = "Has añadido un spawn para %s.",
	spawnDeleted = "Has eliminado el spawn de %s.",
	someone = "Alguien",
	rgnLookingAt = "Permite a quien estás mirando que te reconozca.",
	rgnWhisper = "Permite a aquellos que te escuchen susurrar que te reconozcan.",
	rgnTalk = "Permite a aquellos que te escuchen hablar que te reconozcan.",
	rgnYell = "Permite a aquellos que te escuchen gritar que te reconozcan.",
	icFormat = "%s dice \"%s\"",
	rollFormat = "%s ha tirado los dados y ha sacado un %s.",
	wFormat = "%s susurra \"%s\"",
	yFormat = "%s grita \"%s\"",
	sbOptions = "Haz clic para ver las opciones de %s.",
	spawnAdded = "Has añadido punto de aparición de %s.",
	whitelist = "%s ha metido a %s en la 'whitelist' de la facción %s.",
	unwhitelist = "%s ha sacado a %s de la 'whitelist' de la facción %s.",
	noWhitelist = "No tienes la 'whitelist' para este personaje.",
	gettingUp = "Te estás levantando...",
	wakingUp = "Estás recuperando la consciencia...",
	Weapons = "Armas",
	checkout = "Ir a la cesta (%s)",
	purchase = "Comprar",
	purchasing = "Comprando...",
	success = "Éxito.",
	buyFailed = "Compra fallida.",
	buyGood = "Compra exitosa!",
	shipment = "Envío",
	shipmentDesc = "Éste envío pertenece a %s.",
	class = "Clase",
	classes = "Clases",
	illegalAccess = "Acceso ilegal.",
	becomeClassFail = "Fallo en convertirse en %s.",
	becomeClass = "Te has convertido en %s.",
	setClass = "Has establecido la clase de %s a %s.",
	attributeSet = "Has establecido el nivel de %s de %s a %s puntos.",
	attributeNotFound = "Has especificado un atributo invalido.",
	attributeUpdate = "Has añadido al nivel de %s de %s %s puntos.",
	noFit = "Éste objeto no cabe en tu inventario.",
	itemOwned = "No puedes interactuar con un objeto de tus otros personajes.",
	help = "Ayuda",
	commands = "Comandos",
	-- helpDefault = "Selecciona una categoría",
	doorSettings = "Configuración de puertas",
	sell = "Vender",
	access = "Acceso",
	locking = "Bloqueando ésta entidad...",
	unlocking = "Desbloqueando ésta entidad...",
	modelNoSeq = "Tu modelo no es compatible con éste acto.",
	notNow = "No tienes permiso para hacer esto ahora.",
	faceWall = "Debes estar mirando una pared para hacer esto.",
	faceWallBack = "Tu espalda tiene que estar mirando una pared para hacer esto.",
	descChanged = "Has cambiado la descripción de tu personaje.",
	-- charMoney = "Actualmente tienes %s.",
	-- charFaction = "Eres un miembro de %s.",
	-- charClass = "Eres %s de la facción.",
	noOwner = "El propietario no es válido.",
	-- invalidIndex = "El índice no es válido.",
	invalidItem = "El objeto no es válido.",
	invalidInventory = "El inventario no es válido.",
	home = "Inicio",
	charKick = "%s ha echado a %s.",
	charBan = "%s ha expulsado a %s.",
	charBanned = "Éste personaje está expulsado.",
	playerConnected = "%s se ha conectado al servidor.",
	playerDisconnected = "%s se ha desconectado del servidor.",
	setMoney = "Has establecido el dinero de %s a %s.",
	itemPriceInfo = "Puedes comprar éste objeto por %s.\nPuedes vender éste objeto por %s",
	free = "Gratis",
	vendorNoSellItems = "No hay objetos para vender.",
	vendorNoBuyItems = "No hay objetos para comprar.",
	vendorSettings = "Configuración del Vendedor",
	vendorUseMoney = "¿El vendedor debe usar dinero?",
	vendorNoBubble = "¿Esconder burbuja del vendedor?",
	mode = "Modo",
	price = "Precio",
	stock = "Stock",
	none = "Nada",
	vendorBoth = "Comprar y vender",
	vendorBuy = "Sólo comprar",
	vendorSell = "Sólo vender",
	maxStock = "Stock máximo",
	vendorFaction = "Editor de facción",
	buy = "Comprar",
	vendorWelcome = "Bienvenid@ a mi tienda, ¿Qué puedo hacer por usted?",
	vendorBye = "¡Vuelva pronto!",
	charSearching = "Ya te encuentras buscando a otro personaje, por favor espera.",
	charUnBan = "%s ha perdonado la expulsión a %s.",
	charNotBanned = "Éste personaje no está expulsado.",
	quickSettings = "Configuración rápida",
	vmSet = "Has establecido tu buzón de voz.",
	vmRem = "Has eliminado tu buzón de voz.",
	noPerm = "No tienes permiso para hacer esto.",
	youreDead = "Estás muerto.",
	injMajor = "Parece que está gravemente herido.",
	injLittle = "Parece que está herido.",
	-- toggleESP = "Activar/Desactivar Admin ESP",
	chgName = "Cambiar nombre",
	chgNameDesc = "Introduce abajo el nuevo nombre del personaje.",
	-- thirdpersonToggle = "Activar/Desactivar Tercera Persona",
	-- thirdpersonClassic = "Usar el sistema de Tercera Persona clásico",
	weaponSlotFilled = "No puedes usar otra arma %s!",
	equippedBag = "La bolsa que has movido tiene un objeto que te has equipado.",
	equippedWeapon = "¡No puedes mover un arma que tienes equipada actualmente!",
	nestedBags = "¡No puedes poner un inventario dentro de un inventario de almacenamiento!",
	outfitAlreadyEquipped = "¡Ya estas usando este tipo de ropa!",
	useTip = "Usa el objeto.",
	equipTip = "Equipa el objeto.",
	unequipTip = "Desequipa el objeto.",
	consumables = "Consumibles",
	plyNotValid = "No estás mirando a un jugador válido.",
	restricted = "Has sido atado.",
	salary = "Has recibido %s de tu salario.",
	noRecog = "No reconoces a ésta persona.",
	curTime = "La hora actual es %s.",
	vendorEditor = "Editor de vendedor",
	edit = "Editar",
	disable = "Deshabilitar",
	vendorPriceReq = "Introduce el nuevo precio del objeto.",
	vendorEditCurStock = "Editar Stock actual",
	you = "Tú",
	vendorSellScale = "Escala de precio de venta",
	vendorNoTrade = "¡No puedes intercambiar con este vendedor!",
	vendorNoMoney = "Este vendedor no puede permitirse comprar ese objeto.",
	vendorNoStock = "Este vendedor no tiene ese objeto en Stock.",
	contentTitle = "Falta el Contenido de Helix",
	contentWarning = "No tienes el contenido de Helix montado. Esto puede resultar en que falten ciertas características.\n¿Quieres abrir la pagina de Workshop del contenido de Helix?",
	flags = "Flags",
	mapRestarting = "¡El mapa se reiniciara en %d segundos!",
	chooseTip = "Escoge este personaje con el que jugar.",
	deleteTip = "Eliminar este personaje.",
	storageInUse = "¡Alguien ya esta usando esto!",
	storageSearching = "Buscando...",
	container = "Depósito",
	containerPassword = "Has establecido la contraseña de éste depósito como %s.",
	containerPasswordRemove = "Has eliminado la contraseña de éste depósito.",
	containerPasswordWrite = "Introduce la contraseña.",
	containerName = "Has cambiado el nombre de este depósitos a %s.",
	containerNameWrite = "Introduce el nombre.",
	containerNameRemove = "Has borrado el nombre de este depósito.",
	containerInvalid = "¡Necesitas estar mirando a un depósito para hacer esto!",
	wrongPassword = "Has introducido una contraseña errónea.",
	respawning = "Reapareciendo...",

	scoreboard = "Scoreboard",
	ping = "Ping: %d",
	viewProfile = "Ver el perfil de Steam.",
	copySteamID = "Copiar Steam ID",

	money = "Dinero",
	moneyLeft = "Tu Dinero: ",
	currentMoney = "Dinero Restante: ",

	invalidClass = "¡Esa no es una clase valida!",
	invalidClassFaction = "¡Esa no es una clase valida para la facción!",

	miscellaneous = "Misceláneo",
	general = "General",
	observer = "Observador",
	performance = "Rendimiento",
	thirdperson = "Tercera Persona",
	date = "Fecha",
	interaction = "Interacción",
	server = "Servidor",

	resetDefault = "Reestablecer a predeterminado",
	resetDefaultDescription = "Esto reestablecerá \"%s\" a su valor predeterminado de \"%s\".",
	optOpenBags = "Abrir bolsas con inventario",
	optdOpenBags = "Automáticamente ver todas las bolsas en tu inventario cuando el menú es abierto.",
	optShowIntro = "Mostrar la intro al entrar",
	optdShowIntro = "Muestra la introducción de Helix la siguiente vez que entres. Esta opción siempre es deshabilitada una vez la has visto.",
	optCheapBlur = "Deshabilitar difuminación",
	optdCheapBlur = "Remplaza la difuminación de la interfaz con un oscurecido simple.",
	optObserverTeleportBack = "Retornar a la posición anterior",
	optdObserverTeleportBack = "Te hace volver a la posición en la cual te encontrabas antes de ponerte en modo de Observador.",
	optObserverESP = "Mostrar admin ESP",
	optdObserverESP = "Muestra los nombres y las localizaciones de cada jugador en el servidor.",
	opt24hourTime = "Usar formato de 24-horas",
	optd24hourTime = "Muestra las marcas de tiempo en un formato de 24-horas, en vez de usar el formato de 12-horas (AM/PM).",
	optChatNotices = "Mostrar avisos en el chat",
	optdChatNotices = "Pone todas las noticias que aparecen en la esquina superior derecha en el chat.",
	optChatTimestamps = "Mostrar marcas de tiempo en el chat",
	optdChatTimestamps = "Prepone el tiempo a cada mensaje en el chat.",
	optAlwaysShowBars = "Mostrar siempre las barras de información",
	optdAlwaysShowBars = "Siempre muestra las barras de información en la esquina superior izquierda, sin importar si deberían de mostrarse o no.",
	optAltLower = "Ocultar las manos al estar bajadas", -- @todo remove me
	optdAltLower = "Oculta tus manos cuando están bajadas.", -- @todo remove me
	optThirdpersonEnabled = "Activar Tercera Persona",
	optdThirdpersonEnabled = "Pone la cámara detrás de ti. Esto también puede ser activado con el comando de consola \"ix_togglethirdperson\".",
	optThirdpersonClassic = "Activar la cámara clásica de tercera persona",
	optdThirdpersonClassic = "Mueve la vista de tu personaje con tu ratón.",
	optThirdpersonVertical = "Altura de Tercera Persona",
	optdThirdpersonVertical = "Como de alto debería de estar la cámara de tercera persona.",
	optThirdpersonHorizontal = "Horizontal de Tercera Persona",
	optdThirdpersonHorizontal = "Como de lejos a la izquierda o la derecha debería de estar la cámara.",
	optThirdpersonDistance = "Distancia de Tercera Persona",
	optdThirdpersonDistance = "Como de lejos debería de estar la cámara.",
	optDisableAnimations = "Desactivar animaciones",
	optdDisableAnimations = "Para las animaciones, haciendo que las transiciones sean instantáneas.",
	optAnimationScale = "Escala de animación",
	optdAnimationScale = "Como de rápido o lento deberían de reproducirse las animaciones.",
	optLanguage = "Idioma",
	optdLanguage = "El idioma mostrado en la Interfaz de Helix.",
	optNoticeDuration = "Duración de Avisos",
	optdNoticeDuration = "Cuanto tiempo duran los avisos (en segundos).",
	optNoticeMax = "Máximo de Avisos",
	optdNoticeMax = "La cantidad de avisos mostrados antes de que sean eliminados los anteriores.",
	optChatFontScale = "Escala de fuente de chat",
	optdChatFontScale = "Como de grande o pequeño debería de ser la fuente del chat.",
	optChatOutline = "Contorno en el texto de chat",
	optdChatOutline = "Dibuja un contorno al rededor del texto del chat, en vez de una sombra paralela. Activa esto si tienes problemas leyendo el texto.",

	cmdRoll = "Tira un numero entre 0 y el número especificado.",
	cmdPM = "Envía un mensaje privado a alguien.",
	cmdReply = "Envía un mensaje privado a la ultima persona de la cual recibiste un mensaje.",
	cmdSetVoicemail = "Establece o elimina el mensaje de respuesta automática cuando alguien te envía un mensaje privado.",
	cmdCharGiveFlag = "Da la(s) flag(s) especificadas a alguien.",
	cmdCharTakeFlag = "Elimina la(s) flag(s) especificada(s) de alguien si las tienen.",
	cmdToggleRaise = "Levanta o baja el arma que estas que estas sosteniendo.",
	cmdCharSetModel = "Establece el modelo del personaje de una persona.",
	cmdCharSetSkin = "Establece la skin a el modelo de un personaje.",
	cmdCharSetBodygroup = "Establece el bodygroup a el modelo de un personaje.",
	cmdCharSetAttribute = "Establece el nivel del atributo especificado para alguien.",
	cmdCharAddAttribute = "Añade un nivel al atributo especificado para alguien.",
	cmdCharSetName = "Cambia el nombre de un personaje al nombre especificado.",
	cmdCharGiveItem = "Da el objeto especificado a alguien.",
	cmdCharKick = "De forma forzada hace que alguien cierre la sesión de su personaje.",
	cmdCharBan = "Prohíbe a alguien usar su personaje actual en este servidor.",
	cmdCharUnban = "Permite que un personaje prohibido la habilidad de ser usado otra vez.",
	cmdGiveMoney = "Da una cantidad especifica de dinero a la persona a la que estas mirando.",
	cmdCharSetMoney = "Cambia la cantidad total de dinero de alguien a la cantidad especificada.",
	cmdDropMoney = "Tira una cantidad especifica de dinero en una pequeña caja en frente de ti.",
	cmdPlyWhitelist = "Permite a alguien crear un personaje en una facción especifica.",
	cmdCharGetUp = "Intenta levantarte después de haber caído.",
	cmdPlyUnwhitelist = "No permite a alguien crearse un personaje en la facción especificada.",
	cmdCharFallOver = "Hace que tus rodillas se debiliten y te caigas.",
	cmdBecomeClass = "Intenta formar parte de la clase especificada en tu facción actual.",
	cmdCharDesc = "Establece tu descripción física.",
	cmdCharDescTitle = "Descripción Física",
	cmdCharDescDescription = "Introduce la descripción física de tu personaje.",
	cmdPlyTransfer = "Transfiere a alguien a la facción especificada.",
	cmdCharSetClass = "Forzar a alguien formar parte de la clase especificada de su facción.",
	cmdMapRestart = "Reinicia el mapa después de la cantidad de tiempo especificada.",
	cmdPanelAdd = "Pone un panel web en el mundo.",
	cmdPanelRemove = "Elimina el panel web al que estas mirando.",
	cmdTextAdd = "Pone un bloque de texto en el mundo.",
	cmdTextRemove = "Elimina bloques de texto de donde estas mirando.",
	cmdMapSceneAdd = "Añade un punto de cámara cinemática la cual es mostrada en el menú de selección de personaje.",
	cmdMapSceneRemove = "Elimina un punto de cámara que es mostrado en el menú de selección de personaje.",
	cmdFixPAC = "Intenta arreglar errores de PAC3.",
	cmdSpawnAdd = "Añade un punto de aparición para la facción especificada.",
	cmdSpawnRemove = "Elimina cualquier punto de aparición a los cuales estés mirando.",
	cmdAct = "Realiza la animación %s.",
	cmdContainerSetPassword = "Establece la contraseña para el deposito al cual estas mirando.",
	cmdDoorSell = "Vende la puerta a la que estas mirando.",
	cmdDoorBuy = "Compra la puerta a la que estas mirando.",
	cmdDoorSetUnownable = "Hace que la puerta a la que estas mirando no pueda tener dueño.",
	cmdDoorSetOwnable = "Hace que la puerta a la que estas mirando pueda tener dueño.",
	cmdDoorSetFaction = "Hace que la puerta a la que estas mirando sea adueñada por una facción.",
	cmdDoorSetDisabled = "No permite que ningún comando sea ejecutado en la puerta a la cual estas mirando.",
	cmdDoorSetTitle = "Establece el titulo de la puerta a la cual estas mirando.",
	cmdDoorSetParent = "Establece el padre de una pareja de puertas.",
	cmdDoorSetChild = "Establece el hijo de una pareja de puertas.",
	cmdDoorRemoveChild = "Elimina el hijo de una pareja de puertas.",
	cmdDoorSetHidden = "Oculta la descripción de la puerta a la cual estas mirando, pero sigue permitiendo que pueda tener dueño.",
	cmdDoorSetClass = "Hace que la puerta a la que estas mirando sea adueñada por la clase especificada.",
	cmdMe = "Realiza una acción física.",
	cmdIt = "Haz algo a tu alrededor realizar una acción.",
	cmdW = "Susurra algo a las personas cerca de ti.",
	cmdY = "Grita algo a las personas cerca de ti.",
	cmdEvent = "Haz algo realizar una acción que todos pueden ver.",
	cmdOOC = "Envía un mensaje en el chat (global) fuera de personaje.",
	cmdLOOC = "Envía un mensaje en el chat (local) fuera de personaje."
}
