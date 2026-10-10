package com.mammon.app.ui

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.animateContentSize
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowBackIosNew
import androidx.compose.material.icons.filled.Book
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Code
import androidx.compose.material.icons.filled.Folder
import androidx.compose.material.icons.filled.GridView
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.KeyboardVoice
import androidx.compose.material.icons.filled.Memory
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Psychology
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Security
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Tune
import androidx.compose.material.icons.filled.VolumeUp
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Divider
import androidx.compose.material3.DrawerValue
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.ModalDrawerSheet
import androidx.compose.material3.ModalNavigationDrawer
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.rememberDrawerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.mammon.app.R
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

private val Black = Color.Black
private val Card = Color(0xFF1D1D1F)
private val Card2 = Color(0xFF252527)
private val Muted = Color(0xFF9B9BA1)
private val Rule = Color(0xFF3A3A3D)

enum class MammonScreen { CHAT, SETTINGS, USAGE, PLUGINS, PROFILE }
enum class MammonMode { CHAT, WORK }

data class ChatMessage(
    val id: Long,
    val text: String,
    val fromUser: Boolean,
    val thought: String? = null
)

@Composable
fun MammonApp() {
    val drawer = rememberDrawerState(DrawerValue.Closed)
    val scope = rememberCoroutineScope()
    var screen by remember { mutableStateOf(MammonScreen.CHAT) }
    var mode by remember { mutableStateOf(MammonMode.CHAT) }

    ModalNavigationDrawer(
        drawerState = drawer,
        gesturesEnabled = screen == MammonScreen.CHAT,
        drawerContent = {
            ModalDrawerSheet(
                modifier = Modifier.fillMaxHeight().width(330.dp),
                drawerContainerColor = Black,
                drawerShape = RoundedCornerShape(topEnd = 30.dp, bottomEnd = 30.dp)
            ) {
                DrawerContent(
                    onChat = {
                        screen = MammonScreen.CHAT
                        scope.launch { drawer.close() }
                    },
                    onPlugins = {
                        screen = MammonScreen.PLUGINS
                        scope.launch { drawer.close() }
                    },
                    onSettings = {
                        screen = MammonScreen.SETTINGS
                        scope.launch { drawer.close() }
                    }
                )
            }
        }
    ) {
        AnimatedContent(targetState = screen, label = "screen") { current ->
            when (current) {
                MammonScreen.CHAT -> ChatScreen(
                    mode = mode,
                    onMode = { mode = it },
                    onDrawer = { scope.launch { drawer.open() } },
                    onProfile = { screen = MammonScreen.SETTINGS }
                )
                MammonScreen.SETTINGS -> SettingsScreen(
                    onBack = { screen = MammonScreen.CHAT },
                    onUsage = { screen = MammonScreen.USAGE },
                    onPlugins = { screen = MammonScreen.PLUGINS },
                    onProfile = { screen = MammonScreen.PROFILE }
                )
                MammonScreen.USAGE -> UsageScreen { screen = MammonScreen.SETTINGS }
                MammonScreen.PLUGINS -> PluginsScreen { screen = MammonScreen.SETTINGS }
                MammonScreen.PROFILE -> ProfileScreen { screen = MammonScreen.SETTINGS }
            }
        }
    }
}

@Composable
private fun DrawerContent(
    onChat: () -> Unit,
    onPlugins: () -> Unit,
    onSettings: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .statusBarsPadding()
            .navigationBarsPadding()
            .padding(horizontal = 24.dp, vertical = 18.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Image(
                painter = painterResource(R.drawable.mammon_logo),
                contentDescription = "Mammon",
                modifier = Modifier.size(42.dp)
            )
            Spacer(Modifier.width(12.dp))
            Text("Mammon", fontSize = 29.sp, fontWeight = FontWeight.SemiBold)
            Spacer(Modifier.weight(1f))
            Icon(Icons.Default.Search, "Pesquisar", modifier = Modifier.size(28.dp))
        }

        Spacer(Modifier.height(26.dp))
        DrawerItem(Icons.Default.Book, "Biblioteca") {}
        DrawerItem(Icons.Default.Folder, "Projetos") {}
        DrawerItem(Icons.Default.GridView, "Plugins", onPlugins)
        DrawerItem(Icons.Default.Schedule, "Agendado") {}
        DrawerItem(Icons.Default.Code, "Código") {}
        DrawerItem(Icons.Default.GridView, "Explorar") {}

        Spacer(Modifier.height(25.dp))
        Text("Fixado", fontSize = 21.sp, fontWeight = FontWeight.Bold)
        Spacer(Modifier.height(6.dp))
        DrawerItem(Icons.Default.Psychology, "Mammon", onChat)

        Spacer(Modifier.height(24.dp))
        Text("Recentes", fontSize = 21.sp, fontWeight = FontWeight.Bold)
        Spacer(Modifier.height(8.dp))
        listOf("Novo chat", "Projeto Android", "Ideias do Mammon").forEach { title ->
            Text(
                title,
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .clickable(onClick = onChat)
                    .padding(horizontal = 8.dp, vertical = 13.dp),
                fontSize = 17.sp
            )
        }

        Spacer(Modifier.weight(1f))
        Surface(
            shape = CircleShape,
            color = Card,
            modifier = Modifier.size(60.dp).clickable(onClick = onSettings)
        ) {
            Box(contentAlignment = Alignment.Center) {
                Icon(Icons.Default.Settings, "Configurações", modifier = Modifier.size(30.dp))
            }
        }
    }
}

@Composable
private fun DrawerItem(icon: ImageVector, title: String, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(15.dp))
            .clickable(onClick = onClick)
            .padding(vertical = 12.dp, horizontal = 4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(icon, null, modifier = Modifier.size(26.dp))
        Spacer(Modifier.width(18.dp))
        Text(title, fontSize = 18.sp, fontWeight = FontWeight.Medium)
    }
}

@Composable
private fun ChatScreen(
    mode: MammonMode,
    onMode: (MammonMode) -> Unit,
    onDrawer: () -> Unit,
    onProfile: () -> Unit
) {
    val messages = remember { mutableStateListOf<ChatMessage>() }
    var input by remember { mutableStateOf("") }
    var thinking by remember { mutableStateOf(false) }
    var expanded by remember { mutableStateOf(false) }
    var counter by remember { mutableStateOf(0L) }

    LaunchedEffect(thinking) {
        if (thinking) {
            delay(850)
            val last = messages.lastOrNull { it.fromUser }?.text.orEmpty()
            counter += 1
            messages += ChatMessage(
                id = counter,
                text = if (mode == MammonMode.WORK) {
                    "Organizei seu pedido como uma tarefa de trabalho. Esta versão já tem o fluxo visual pronto para receber um backend real."
                } else {
                    "Entendi: “${last.take(120)}”. O Mammon está funcionando em modo de demonstração e já pode ser conectado ao modelo de IA que você escolher."
                },
                fromUser = false,
                thought = "Identifiquei a intenção principal, separei o pedido em etapas e preparei uma resposta curta."
            )
            thinking = false
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Black)
            .statusBarsPadding()
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onDrawer) {
                Icon(Icons.Default.Menu, "Menu", modifier = Modifier.size(29.dp))
            }
            Spacer(Modifier.weight(1f))
            ModeSwitcher(mode, onMode)
            Spacer(Modifier.weight(1f))
            IconButton(onClick = onProfile) {
                Icon(Icons.Default.Person, "Perfil", modifier = Modifier.size(28.dp))
            }
        }

        LazyColumn(
            modifier = Modifier.weight(1f).fillMaxWidth(),
            contentPadding = PaddingValues(horizontal = 18.dp, vertical = 20.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp)
        ) {
            if (messages.isEmpty()) {
                item {
                    Box(
                        modifier = Modifier.fillMaxWidth().height(480.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Image(
                                painter = painterResource(R.drawable.mammon_logo),
                                contentDescription = null,
                                modifier = Modifier.size(62.dp),
                                contentScale = ContentScale.Fit
                            )
                            Spacer(Modifier.height(14.dp))
                            Text("Mammon", fontSize = 25.sp, fontWeight = FontWeight.SemiBold)
                        }
                    }
                }
            }
            items(messages, key = { it.id }) { message ->
                MessageBubble(message)
            }
            if (thinking) {
                item {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(17.dp),
                            strokeWidth = 2.dp,
                            color = Muted
                        )
                        Spacer(Modifier.width(10.dp))
                        Text("Pensando", color = Muted, fontSize = 18.sp)
                    }
                }
            }
        }

        Composer(
            value = input,
            expanded = expanded,
            thinking = thinking,
            onValue = {
                input = it
                if (it.length > 34 || it.contains("\n")) expanded = true
            },
            onExpand = { expanded = !expanded },
            onSend = {
                val text = input.trim()
                if (text.isNotEmpty() && !thinking) {
                    counter += 1
                    messages += ChatMessage(counter, text, true)
                    input = ""
                    expanded = false
                    thinking = true
                }
            }
        )
    }
}

@Composable
private fun ModeSwitcher(mode: MammonMode, onMode: (MammonMode) -> Unit) {
    Surface(
        color = Card,
        shape = RoundedCornerShape(12.dp),
        modifier = Modifier.width(210.dp)
    ) {
        Row(Modifier.padding(3.dp)) {
            ModeButton("Chat", mode == MammonMode.CHAT, Modifier.weight(1f)) {
                onMode(MammonMode.CHAT)
            }
            ModeButton("Work", mode == MammonMode.WORK, Modifier.weight(1f)) {
                onMode(MammonMode.WORK)
            }
        }
    }
}

@Composable
private fun ModeButton(
    title: String,
    selected: Boolean,
    modifier: Modifier,
    onClick: () -> Unit
) {
    Surface(
        color = if (selected) Color(0xFF64646B) else Color.Transparent,
        shape = RoundedCornerShape(10.dp),
        modifier = modifier.clickable(onClick = onClick)
    ) {
        Box(Modifier.padding(vertical = 10.dp), contentAlignment = Alignment.Center) {
            Text(
                title,
                fontSize = 16.sp,
                fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal
            )
        }
    }
}

@Composable
private fun MessageBubble(message: ChatMessage) {
    var thoughtOpen by remember { mutableStateOf(false) }

    if (message.fromUser) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
            Surface(color = Card2, shape = RoundedCornerShape(22.dp)) {
                Text(
                    message.text,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
                    fontSize = 17.sp,
                    lineHeight = 23.sp
                )
            }
        }
    } else {
        Column(Modifier.fillMaxWidth().padding(end = 26.dp)) {
            message.thought?.let { thought ->
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier
                        .clip(RoundedCornerShape(10.dp))
                        .clickable { thoughtOpen = !thoughtOpen }
                        .padding(vertical = 5.dp)
                ) {
                    Image(
                        painterResource(R.drawable.mammon_logo),
                        null,
                        modifier = Modifier.size(22.dp)
                    )
                    Spacer(Modifier.width(8.dp))
                    Text(
                        "Pensamento",
                        color = Muted,
                        fontSize = 15.sp,
                        fontWeight = FontWeight.Medium
                    )
                    Spacer(Modifier.width(8.dp))
                    Text(
                        if (thoughtOpen) "ocultar" else "mostrar",
                        color = Color(0xFF727278),
                        fontSize = 13.sp
                    )
                }
                if (thoughtOpen) {
                    Surface(
                        color = Card,
                        shape = RoundedCornerShape(16.dp),
                        modifier = Modifier.padding(vertical = 7.dp)
                    ) {
                        Text(
                            thought,
                            modifier = Modifier.padding(14.dp),
                            color = Color(0xFFC7C7CB),
                            fontSize = 14.sp,
                            lineHeight = 20.sp
                        )
                    }
                }
            }
            Text(message.text, fontSize = 17.sp, lineHeight = 25.sp)
        }
    }
}

@Composable
private fun Composer(
    value: String,
    expanded: Boolean,
    thinking: Boolean,
    onValue: (String) -> Unit,
    onExpand: () -> Unit,
    onSend: () -> Unit
) {
    Surface(
        color = Card,
        shape = RoundedCornerShape(34.dp),
        modifier = Modifier
            .fillMaxWidth()
            .navigationBarsPadding()
            .padding(horizontal = 14.dp, vertical = 10.dp)
            .heightIn(min = if (expanded) 145.dp else 74.dp)
            .animateContentSize()
    ) {
        Column(Modifier.padding(horizontal = 12.dp, vertical = 9.dp)) {
            androidx.compose.foundation.text.BasicTextField(
                value = value,
                onValueChange = onValue,
                modifier = Modifier.fillMaxWidth().heightIn(min = 34.dp, max = 96.dp),
                textStyle = TextStyle(
                    color = Color.White,
                    fontSize = 18.sp,
                    lineHeight = 24.sp
                ),
                cursorBrush = SolidColor(Color(0xFF4E7CFF)),
                decorationBox = { inner ->
                    Box {
                        if (value.isEmpty()) {
                            Text(
                                "Perguntar ao Mammon",
                                color = Color(0xFF7C7C82),
                                fontSize = 18.sp
                            )
                        }
                        inner()
                    }
                }
            )

            Spacer(Modifier.height(if (expanded) 12.dp else 4.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                IconButton(onClick = onExpand) {
                    Icon(Icons.Default.Add, "Adicionar", modifier = Modifier.size(32.dp))
                }
                Spacer(Modifier.weight(1f))
                IconButton(onClick = {}) { Icon(Icons.Default.Search, "Pesquisar") }
                IconButton(onClick = {}) { Icon(Icons.Default.Mic, "Microfone") }
                Surface(
                    shape = CircleShape,
                    color = Color.White,
                    modifier = Modifier
                        .size(46.dp)
                        .clickable(enabled = value.isNotBlank() && !thinking, onClick = onSend)
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(
                            if (thinking) Icons.Default.Psychology else Icons.Default.KeyboardVoice,
                            null,
                            tint = Color.Black,
                            modifier = Modifier.size(25.dp)
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun SettingsScreen(
    onBack: () -> Unit,
    onUsage: () -> Unit,
    onPlugins: () -> Unit,
    onProfile: () -> Unit
) {
    ScreenFrame(onBack = onBack) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 18.dp, vertical = 12.dp)
        ) {
            ProfileHeader(onProfile)
            Spacer(Modifier.height(22.dp))
            UpgradeCard()

            Spacer(Modifier.height(27.dp))
            SectionTitle("Personalizar o Mammon")
            SettingsGroup {
                SettingRow(Icons.Default.Tune, "Personalização")
                SettingRow(Icons.Default.Memory, "Memória")
                SettingRow(Icons.Default.GridView, "Plugins", onClick = onPlugins)
            }

            Spacer(Modifier.height(25.dp))
            SectionTitle("Conta")
            SettingsGroup {
                SettingRow(Icons.Default.Person, "Conta", "Não conectado", onProfile)
                SettingRow(Icons.Default.Bolt, "Assinatura", "Mammon")
                SettingRow(Icons.Default.Tune, "Uso e limites", onClick = onUsage)
            }

            Spacer(Modifier.height(25.dp))
            SectionTitle("Tema")
            SettingsGroup {
                SettingRow(Icons.Default.Settings, "Aparência", "Sistema")
                SettingRow(Icons.Default.Tune, "Cor de ênfase", "Branco")
            }

            Spacer(Modifier.height(25.dp))
            SectionTitle("Configurações do app")
            SettingsGroup {
                SettingRow(Icons.Default.Settings, "Geral")
                SettingRow(Icons.Default.Notifications, "Notificações")
                SettingRow(Icons.Default.VolumeUp, "Voz")
                SettingRow(Icons.Default.Security, "Segurança e bem-estar")
            }

            Spacer(Modifier.height(25.dp))
            SectionTitle("Ajuda")
            SettingsGroup {
                SettingRow(Icons.Default.Info, "Central de ajuda")
                SettingRow(Icons.Default.Security, "Privacidade")
                SettingRow(Icons.Default.Info, "Sobre")
            }

            Spacer(Modifier.height(30.dp))
        }
    }
}

@Composable
private fun ProfileHeader(onClick: () -> Unit) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.fillMaxWidth().clickable(onClick = onClick)
    ) {
        Surface(shape = CircleShape, color = Card2, modifier = Modifier.size(112.dp)) {
            Box(contentAlignment = Alignment.Center) {
                Image(
                    painterResource(R.drawable.mammon_logo),
                    "Logo Mammon",
                    modifier = Modifier.size(70.dp),
                    contentScale = ContentScale.Fit
                )
            }
        }
        Spacer(Modifier.height(12.dp))
        Text(
            "MAMMON",
            fontSize = 25.sp,
            fontWeight = FontWeight.Bold,
            letterSpacing = 1.2.sp
        )
    }
}

@Composable
private fun UpgradeCard() {
    Surface(shape = RoundedCornerShape(30.dp), color = Card2) {
        Column(Modifier.padding(24.dp)) {
            Text("Faça mais com o Mammon", fontSize = 24.sp, fontWeight = FontWeight.Medium)
            Spacer(Modifier.height(6.dp))
            Text(
                "Tenha limites maiores e acesso a recursos avançados.",
                color = Color(0xFFC5C5C8),
                fontSize = 17.sp,
                lineHeight = 23.sp
            )
            Spacer(Modifier.height(22.dp))
            Button(
                onClick = {},
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color.White,
                    contentColor = Color.Black
                ),
                shape = RoundedCornerShape(24.dp)
            ) {
                Text("Fazer upgrade", fontSize = 17.sp)
            }
        }
    }
}

@Composable
private fun UsageScreen(onBack: () -> Unit) {
    ScreenFrame(onBack, "Uso e limites") {
        Column(
            Modifier
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(18.dp)
        ) {
            Text(
                "LIMITE DE USO DOS AGENTES",
                color = Muted,
                fontSize = 14.sp,
                letterSpacing = 0.6.sp
            )
            Spacer(Modifier.height(12.dp))

            Surface(shape = RoundedCornerShape(24.dp), color = Card) {
                Column(Modifier.padding(22.dp)) {
                    UsageLine("Limite de uso de\n5 horas", "100% restantes", 1f)
                    Divider(color = Rule, modifier = Modifier.padding(vertical = 20.dp))
                    UsageLine("Limite de uso semanal", "0% restantes", 0f)
                    Spacer(Modifier.height(12.dp))
                    Text("Redefine sex., 10:13", color = Muted, fontSize = 15.sp)
                }
            }

            Spacer(Modifier.height(34.dp))
            Text("CRÉDITOS", color = Muted, fontSize = 14.sp, letterSpacing = 0.6.sp)
            Spacer(Modifier.height(12.dp))

            Surface(shape = RoundedCornerShape(18.dp), color = Card) {
                Row(
                    Modifier.fillMaxWidth().padding(20.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text("Créditos restantes", fontSize = 19.sp)
                    Spacer(Modifier.weight(1f))
                    Text("0 créditos", color = Muted, fontSize = 19.sp)
                }
            }

            Spacer(Modifier.height(10.dp))
            Text(
                "Os créditos ampliam o uso além dos limites do seu plano.",
                color = Muted,
                fontSize = 15.sp,
                lineHeight = 21.sp
            )
            Spacer(Modifier.height(12.dp))
            Text(
                "Valores de demonstração para reproduzir o visual da referência.",
                color = Color(0xFF6E6E73),
                fontSize = 12.sp
            )
        }
    }
}

@Composable
private fun UsageLine(label: String, value: String, progress: Float) {
    Column {
        Row(verticalAlignment = Alignment.Top) {
            Text(label, fontSize = 20.sp, lineHeight = 24.sp)
            Spacer(Modifier.weight(1f))
            Text(value, color = Color(0xFFC8C8CC), fontSize = 18.sp)
        }
        Spacer(Modifier.height(18.dp))
        LinearProgressIndicator(
            progress = progress,
            modifier = Modifier.fillMaxWidth().height(8.dp).clip(CircleShape),
            color = Color(0xFF3EA6FF),
            trackColor = Color(0xFF17314A)
        )
    }
}

@Composable
private fun PluginsScreen(onBack: () -> Unit) {
    ScreenFrame(onBack, "Plugins") {
        Column(Modifier.padding(18.dp)) {
            Text("Conecte serviços ao Mammon", fontSize = 23.sp, fontWeight = FontWeight.SemiBold)
            Spacer(Modifier.height(8.dp))
            Text(
                "A interface já está pronta; as conexões reais dependem das APIs escolhidas.",
                color = Muted,
                fontSize = 15.sp
            )
            Spacer(Modifier.height(22.dp))

            listOf("GitHub", "Google Drive", "Calendário", "E-mail").forEach { name ->
                Surface(
                    shape = RoundedCornerShape(18.dp),
                    color = Card,
                    modifier = Modifier.fillMaxWidth().padding(bottom = 10.dp)
                ) {
                    Row(Modifier.padding(18.dp), verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.GridView, null)
                        Spacer(Modifier.width(14.dp))
                        Text(name, fontSize = 18.sp)
                        Spacer(Modifier.weight(1f))
                        Text("Conectar", color = Muted, fontSize = 14.sp)
                    }
                }
            }
        }
    }
}

@Composable
private fun ProfileScreen(onBack: () -> Unit) {
    ScreenFrame(onBack, "Perfil") {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.fillMaxWidth().padding(24.dp)
        ) {
            Surface(shape = CircleShape, color = Card, modifier = Modifier.size(130.dp)) {
                Box(contentAlignment = Alignment.Center) {
                    Image(
                        painterResource(R.drawable.mammon_logo),
                        null,
                        modifier = Modifier.size(78.dp)
                    )
                }
            }
            Spacer(Modifier.height(16.dp))
            Text("Mammon", fontSize = 27.sp, fontWeight = FontWeight.Bold)
            Text("Perfil local", color = Muted, fontSize = 15.sp)
        }
    }
}

@Composable
private fun ScreenFrame(
    onBack: () -> Unit,
    title: String? = null,
    content: @Composable ColumnScope.() -> Unit
) {
    Column(
        Modifier
            .fillMaxSize()
            .background(Black)
            .statusBarsPadding()
            .navigationBarsPadding()
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().height(64.dp).padding(horizontal = 10.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onBack) {
                Icon(Icons.Default.ArrowBackIosNew, "Voltar")
            }
            if (title != null) {
                Text(title, fontSize = 20.sp, fontWeight = FontWeight.SemiBold)
            }
        }
        Divider(color = Rule)
        content()
    }
}

@Composable
private fun SectionTitle(text: String) {
    Text(
        text,
        color = Color(0xFFB9B9BD),
        fontSize = 20.sp,
        fontWeight = FontWeight.Bold,
        modifier = Modifier.padding(start = 16.dp, bottom = 10.dp)
    )
}

@Composable
private fun SettingsGroup(content: @Composable ColumnScope.() -> Unit) {
    Surface(shape = RoundedCornerShape(18.dp), color = Card) {
        Column { content() }
    }
}

@Composable
private fun SettingRow(
    icon: ImageVector,
    label: String,
    trailing: String? = null,
    onClick: () -> Unit = {}
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 18.dp, vertical = 16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(icon, null, modifier = Modifier.size(25.dp))
        Spacer(Modifier.width(16.dp))
        Text(
            label,
            fontSize = 18.sp,
            modifier = Modifier.weight(1f),
            maxLines = 2,
            overflow = TextOverflow.Ellipsis
        )
        if (trailing != null) {
            Text(trailing, color = Muted, fontSize = 17.sp)
            Spacer(Modifier.width(4.dp))
        }
        Icon(Icons.Default.ChevronRight, null, tint = Color(0xFF737378))
    }
    Divider(color = Rule, modifier = Modifier.padding(start = 58.dp))
}
