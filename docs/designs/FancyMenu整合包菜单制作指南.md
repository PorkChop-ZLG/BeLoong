# FancyMenu 整合包菜单制作指南（化龙 · FancyMenu 3.9.12 / MC 1.21.1）

> 本文基于 **反编译源码** 与 **本实例实际配置** 写成，不是通用教程的转述。
> 反编译产物：`D:\Minecraft\闭源模组解压文件\fancymenu\decompiled`（CFR 0.152 反编译，1422 个 Java 文件）
> 调研笔记：同目录 `_research\` 下的 `ref-*.txt` / `01..07-*.md`
> 版本：FancyMenu `3.9.12`（`fancymenu_neoforge_3.9.12_MC_1.21.1.jar`），MC 1.21.1，NeoForge

---

## 1. 它是什么：FancyMenu 的三层模型

FancyMenu 用一句话概括：**把「某个界面上要画什么」写成一份纯文本布局文件，然后在渲染时注入进去。**

源码里对应三层结构：

| 层 | 类 / 目录 | 职责 |
|---|---|---|
| 界面识别 | `customization/screen/identifier/ScreenIdentifierHandler.java` | 给每个 `Screen` 算出唯一标识符 |
| 布局数据 | `customization/layout/Layout.java`、`LayoutHandler.java` | 一份 `.txt` = 一个 `Layout`，绑定到一个界面标识符 |
| 运行时渲染 | `customization/layer/ScreenCustomizationLayer.java`、`element/`、`background/`、`decorationoverlay/` | 把布局里的背景 / 装饰层 / 元素 / 原版控件改写画到界面上 |

一个由代码保证的关键点：**`config/fancymenu/customization/` 下的所有 `.txt` 都会被扫描并加载**（含子目录，但会跳过名为 `.disabled` 的目录），文件名与 `identifier` 无关：

```java
// LayoutHandler.java:47, 83-105
LAYOUT_DIR = new File(FancyMenu.MOD_DIR, "/customization");
// collectLayoutsInDirectory(): 递归; 只处理 .txt; skipDisabledDir 时跳过 ".disabled"
```

→ 所以 `beloong.txt` 可以叫任何名字；决定它管哪个界面的是文件里的 `identifier`。

---

## 2. 界面标识符：一个布局如何绑定到界面

`ScreenIdentifierHandler.getIdentifierOfScreen()`（`ScreenIdentifierHandler.java:41-52`）的解析顺序：

1. 若是 FancyMenu 自建 GUI（`CustomGuiBaseScreen`）→ 用它的 identifier
2. 否则取屏幕类名 → 查 `UniversalScreenIdentifierRegistry`
3. 查不到 → 直接返回类名

### 2.1 通用标识符（推荐）

`UniversalScreenIdentifierRegistry.java:313-435` 注册了 **121 个** 通用标识符。常用：

| 标识符 | 目标界面 |
|---|---|
| `title_screen` | 主菜单 `TitleScreen` |
| `join_multiplayer_screen` | 多人游戏 `JoinMultiplayerScreen` |
| `select_world_screen` | 选择世界 `SelectWorldScreen` |
| `create_world_screen` | 创建世界 `CreateWorldScreen` |
| `pause_screen` | 暂停菜单 `PauseScreen` |
| `options_screen` | 选项 `OptionsScreen` |
| `controls_screen` | 按键控制 `ControlsScreen` |
| `language_select_screen` | 语言选择 |
| `pack_selection_screen` | 资源包 |
| `death_screen` | 死亡界面 |
| `level_loading_screen` | 关卡加载 |
| `credits_and_attribution_screen` | 制作人员名单 |
| `advancements_screen` / `stats_screen` | 进度 / 统计 |

完整清单见 `_research\ref-screen-widget-identifiers.txt`。

### 2.2 类全限定名（兜底）

模组界面没有通用标识符，直接写类名，例如：

```
identifier = net.neoforged.neoforge.client.gui.ModListScreen
```

源码还内置了一份**跨版本类名映射表**（`ScreenIdentifierHandler.SCREEN_CLASSPATH_DATABASE`，第 34 行），能自动把旧版本类名（如 `net.minecraft.client.gui.screen.MainMenuScreen`）修正到当前版本，所以老整合包迁移过来的布局不会立刻失效。

### 2.3 通用布局

```
identifier = %fancymenu:universal_layout%
```

（常量见 `Layout.java:76`）通用布局**套用到所有界面**，可用 `universal_layout_whitelist` / `universal_layout_blacklist` 收窄范围（`Layout.java:141-154`）：

```
universal_layout_whitelist = title_screen;join_multiplayer_screen;
universal_layout_blacklist = options_screen;
```

> 本项目现状：`universal_layout.txt` 的 `identifier` 正是 `%fancymenu:universal_layout%`，只设了一张幻灯片背景，未设白/黑名单 → **所有界面**都会铺这层幻灯片背景。

### 2.4 由其他模组注册的标识符

有些布局的 `identifier` 既不是通用标识符、也不是原版屏幕类名，而是**别的模组自己的界面**。最典型的例子是本项目的加载界面：

```
identifier = drippy_loading_overlay
```

**这个标识符不在 FancyMenu 源码里**（全树检索零命中）。它由 **Drippy Loading Screen** 模组提供 —— 已验证该模组 jar 的 `de/keksuccino/drippyloadingscreen/customization/DrippyOverlayScreen.class` 中含此字符串，且它同时注册了 `mojang_logo`、`progress_bar` 等**加载界面专用控件标识符**。

→ 判断一个 `identifier` 属于谁的方法：在 FancyMenu 里查不到，就去 `mods/` 里找注册它的模组。**升级 Drippy 或 FancyMenu 后，这类标识符最可能变。**

### 2.5 文件名与标识符无关

`LayoutHandler` 会递归扫描 `customization/` 下**所有 `.txt`**，只要求文件里的 `type` 是 `menu` 或 `fancymenu_layout`，否则**静默跳过**。
文件名**不参与**匹配；编辑器保存时只是建议用 `<identifier>_layout.txt`。真正的绑定关系写在 `layout-meta.identifier`。
「布局名」（用于 `enable_layout` / `disable_layout` / `toggle_layout` 动作）则是**文件名去扩展名**（`Layout.java:566-572`），重名时会用它做替换判定 —— 所以文件重名会导致互相覆盖。

### 2.6 布局的叠加顺序

同索引时，**通用布局在下层**、后加载的在上层（最终排序由 `ScreenCustomizationLayer.java:281` 决定；`layout_index` 升序，同索引时通用布局在下）。

元素渲染分层顺序：
`vanilla_button 元素(pre)` → `背景 + 背景层元素` → `原版界面` → `背景元素 / 前景元素 / decoration_overlay(post)`。

> 这也解释了 `layout-meta.render_custom_elements_behind_vanilla` 的作用：把元素画到原版控件**之下**（做「按钮后面垫一张图」时用）。

---

## 3. 文件格式：PropertiesParser 的完整语法

解析器：`util/properties/PropertiesParser.java:39-87`（读）、`:112-129`（写）。
**这套格式不是 Java `.properties`，必须按下面的规则写。**

### 3.1 骨架

```
type = <集合类型>

<容器名> {
  key = value
}


<容器名> {
  key = value
}
```

规则（逐条对应源码）：

| 规则 | 源码依据 |
|---|---|
| 整个文件首行必须是 `type = xxx`（`fancymenu_layout` / `customizablemenus` / `slideshow` / `user_variables` …），且**必须在任何 `{` 之前** | `:48-51` |
| 一个 `容器名 {` 开始一个容器，`}` 结束 | `:52-66` |
| 判断 `{` / `}` 时用的是**去掉所有空白后的行**（`replaceAll("[\\p{Z}\\s]+","")`），所以 `  name {`、`name{`、`name {  ` 都合法 | `:47,52,62` |
| 容器名 = 该行 `{` 之前的部分（已去空白），**不能含空格和 `{`** | `:59` |
| `key = value`：**在第一个 `=` 处切分**，`=` 右边**只剥掉一个前导空格**，其余（包括后续空格和 `=`）原样保留 | `:68-72` |
| key 也是用去空白后的行切出来的 → **key 内不能有空格** | `:72` |
| 空行、缺少 `=` 的行、`{` 之外的内容一律忽略 | `:67` |
| 容器未闭合 `}` 时只记一条 warning，然后把它塞进列表 | `:56` |
| 读写编码：按行读写文本，无 BOM 依赖 | `:35,104` |

**实践推论**：

- 想表达「值以空格开头」很麻烦（只会被剥掉一个空格）；用 `%n%`（换行）或 `&`/`§` 格式码代替排版空格。
- 值里可以出现 `=`、`{`、`}`、`[`、`]`、`;`、`:`，解析不受影响 —— 这正是 `[executable_block:...][type:...] = [executables:...;]` 这类键能成立的原因。
- ⚠️ **值不能以 `{` 结尾**：`{` 结尾的判定（`:52`）**早于** `key = value` 判定（`:67`），所以以 `{` 结尾的值行会被误当成容器头。
- **多行值**：真换行无法直接写进「一行一个键值」的格式，源码用 token `%%!serialized_property_newline!%%` 表示换行（`util/properties/PropertyContainer.java:18, 74-81`）。手写含换行的文本（如 `write_file` 的内容）时用它。
- **无引号、无转义、无注释语法** —— 没有 `#` 注释，不要去「注释掉」某一行，会直接变成一条属性。
-（`PropertiesParser.stringifyFancyString` / `unstringify` 在本版本是**无人调用的死代码**，别照它设计格式。）
- 中文值直接 UTF-8 写入即可。

### 3.2 两种「伪嵌套」写法

FancyMenu 不用真正的嵌套，而是把结构压进 **key** 或 **value** 里：

**(a) 结构化 key**（用于可执行块 / 动作 / 条件容器）：

```
[executable_action_instance:99c74648-...][action_type:openlink] = https://example.com
[executable_block:8513838e-...][type:generic] = [executables:99c74648-...;]
[loading_requirement_container_meta:68551f0b-...] = [groups:][instances:]
```

**(b) 结构化 value**（用 `[前缀:` … `]` 包裹，`;` 分隔多项）：

```
[executables:a;b;c]       动作 UUID 列表
[executables:]            空列表
[groups:][instances:]     条件容器：组列表 + 实例列表（默认空）
[appended:<uuid>]         块链：把另一个块作为「子块」挂上来（if → else 就靠它）
```

值内以 `;` 分隔：`ExecutableBlockDeserializer.java:46-50`（`[executables:` 之后按 `;` 切分）。

---

## 4. `fancymenu_layout`：布局文件全字段

序列化在 `Layout.java:127-219`，反序列化在 `Layout.deserialize`。一个布局包含下列顶层块。

### 4.1 `layout-meta`（必需）

| 键 | 类型 | 默认 | 含义 |
|---|---|---|---|
| `identifier` | string | — | 目标界面标识符（见第 2 节） |
| `render_custom_elements_behind_vanilla` | bool | false | 元素画在原版控件**之下** |
| `last_edited_time` | long | -1 | 上次编辑时间戳（编辑器用） |
| `is_enabled` | bool | true | 关掉后整个布局不生效 |
| `randommode` | bool | false | 参与「随机布局」抽取（同一 identifier 的多份布局随机选一份） |
| `randomgroup` | string | `1` | 随机分组：同组内互斥抽取 |
| `randomonlyfirsttime` | bool | false | 每会话只随机一次 |
| `layout_index` | int | 0 | 编辑器里的排序 |
| `universal_layout_whitelist` | `a;b;c;` | — | **仅通用布局**：白名单（有值则只作用于这些界面） |
| `universal_layout_blacklist` | `a;b;c;` | — | **仅通用布局**：黑名单 |
| `custom_menu_title` | string | — | 替换该界面顶部标题文字 |

> `loading_1/2/3.txt` 三个文件 `identifier` 全是 `drippy_loading_overlay` 且 `randommode = true`，就是这个机制：加载界面每次随机挑一张。

### 4.2 `menu_background`

`customization/background/` 下有 9 种 `background_type`：

| `background_type` | 中文名 | 关键键 | 依赖 |
|---|---|---|---|
| `image` | 图片 | `image_path`、`slide`、`repeat_texture`、`parallax`、`parallax_intensity_x/y`、`fallback_path`、`restart_animated_on_menu_load` | — |
| `color_fancymenu` | 颜色 | `color`（`#AARRGGBB`） | — |
| `slideshow` | 幻灯片 | `slideshow_name` | — |
| `panorama` | 立方全景 | `panorama_name` | — |
| `glsl` | GLSL 着色器 | 39 个键：`inline_shader_source`、`buffer_a..d_inline_source`、`image_ichannel0..3_input`、`buffer_a..d_ichannel0..3_input`、`compile_mode`、`force_shadertoy_compatibility`、`freeze_time`、`time_scale`、`enable_blending`、`use_input`、`mouse_position_requires_hold`、`opacity_multiplier`、`show_compile_errors` | — |
| `video` | 视频 | `loop`、`volume`、`sound_source` | **watermedia（未装）** |
| `video_rinku` | 视频 [Rinku]（**已弃用**） | 同上 | **rinku（未装）** |
| `browser` | 浏览器 | `url`、`consume_*`、`process_*`、`hide_video_controls`、`loop_videos`、`mute_media`、`media_volume` | **rinku（未装）** |

（注册顺序见 `MenuBackgrounds.java:26-35`，共 8 种。语言文件里把 `color_fancymenu` 显示为「颜色」，别被键名差异误导。）

公共键：`instance_identifier`（随机 UUID）、`show_background`（bool）。

> ⚠️ **重大陷阱**：`show_background` **声明**默认 false，但源码里**该键完全缺失时会被强制置为 true**（`MenuBackgroundBuilder.java:58-60`）。
> → 手写布局时**必须显式写 `show_background = false`**，否则那些你没打算启用的背景块会全部生效。
> 同理，元素里 `stay_on_screen` 字段初值虽是 true，但**键缺失即被强制设为 false**（`ElementBuilder.java:153-155`）——两个默认值方向相反，都要显式写。

**依赖缺失时的表现**（不是静默失败）：`video` 缺 WaterMedia → 渲染**红屏**并给两个 CurseForge 下载链接；`video_rinku` / `browser` 缺 Rinku → **红屏**警告文字。

**反序列化会为全部 8 种类型补齐默认实例**（`Layout.java:420-431`）—— 这就是本项目 `beloong.txt` 里那 8 个背景块、10 个覆盖层块的来源。

### 4.3 `decoration_overlay`（装饰覆盖层）

10 种 `overlay_type`（注册顺序见 `DecorationOverlays.java`）：`browser`、`glsl`、`buddy`、`string_lights`、`fireworks`、`snowfall`、`rainfall`、`fireflies`、`leaves`、`confetti`。

> ⚠️ **三处「类名 ≠ identifier」**：`Rain` → **`rainfall`**、`Snow` → **`snowfall`**、`Firefly` → **`fireflies`**。
> `ref-decoration-overlays.txt` 是按**语言键**导出的（显示为 rain/snow），**不能照抄**。

公共键：`instance_identifier`、`show_decoration_overlay`（默认 false）。**每个布局每种类型最多 1 个实例**（`Layout.java:432-438` 只取第一个）。

渲染时机：在**前景元素之后**、按 `layout_index` 升序（`ScreenCustomizationLayer.java:425-429`）—— 即盖在原版界面之上。

元素是否受覆盖层影响由元素的 `should_be_affected_by_decoration_overlays` 决定（默认 false，`AbstractElement.java:168`）。它**只用于生成元素碰撞盒**（`AbstractDecorationOverlay.java:243-246`）；被**强制置 true** 的元素是：`checkbox`、`vanilla_button`、`custom_button`、`input_field`、`slider_v2`。

### 4.4 `customization`（布局级选项，可多个）

| `action` | 附带键 | 含义 |
|---|---|---|
| `backgroundoptions` | `keepaspectratio` | 背景是否保持宽高比（编辑器**总会**写这一块） |
| `setscale` | `scale` | 强制该界面 GUI 缩放 |
| `autoscale` | `basewidth`、`baseheight` | 自动缩放基准分辨率 |
| `setopenaudio` | `path` | 界面打开音效 |
| `setcloseaudio` | `path` | 界面关闭音效 |

（`Layout.java:158-193`）

### 4.5 `scroll_list_customization`

滚动列表（单人/多人/资源包等界面）的页眉页脚自定义：

| 键 | 含义 |
|---|---|
| `preserve_scroll_list_header_footer_aspect_ratio` | 保持页眉页脚宽高比 |
| `scroll_list_header_texture` / `scroll_list_footer_texture` | 页眉 / 页脚贴图（带 `[source:...]` 前缀） |
| `render_scroll_list_header_shadow` / `render_scroll_list_footer_shadow` | 页眉 / 页脚分隔线 |
| `show_scroll_list_header_footer_preview_in_editor` | 编辑器内预览 |
| `repeat_scroll_list_header_texture` / `repeat_scroll_list_footer_texture` | 重复铺贴 |
| `show_screen_background_overlay_on_custom_background` | 自定义背景上是否仍叠原版遮罩 |
| `apply_vanilla_background_blur` | 是否应用原版背景模糊 |

### 4.6 `layout_action_executable_blocks`（布局级动作）

| 键 | 含义 |
|---|---|
| `open_screen_executable_block_identifier` | 界面**打开**时执行的动作块 UUID |
| `close_screen_executable_block_identifier` | 界面**关闭**时执行的动作块 UUID |

对应的动作块定义就写在同一容器里（`Layout.java:210-218`）。

### 4.7 `element` / `vanilla_button`

见第 5 节。

---

## 5. 元素系统

### 5.1 全部元素类型

注册表 `customization/element/elements/Elements.java:62-91`，共 **27 种**：

| `element_type` | 中文名 | 备注 |
|---|---|---|
| `custom_button` | 按钮 | 整合包最常用 |
| `vanilla_button` | 原版控件改写 | 见 5.4 |
| `text_v2` | 文本 | |
| `image` | 图片 | |
| `item` | 物品 | 可自定义 NBT / 附魔光效 / 名称 / 描述 |
| `player_entity_v2` | 玩家实体 | 可摆姿势、跟随鼠标 |
| `player_entity_v1` | 玩家实体（旧） | |
| `slider_v2` | 滑块 | |
| `checkbox` | 复选框 | |
| `input_field` | 文本输入框 | 可绑定 FM 变量 |
| `progress_bar` | 进度条 | 加载界面用 |
| `splash_text` | 闪烁标语 | |
| `tooltip` | 提示框 | |
| `ticker` | 计时器 / 待办触发 | 可周期执行动作 |
| `dragger` | 拖拽器 | |
| `cursor` | 光标 | 自定义鼠标指针 |
| `audio_v2` | 音频 | 播放列表 + shuffle |
| `music_controller` | 音乐控制器 | 接管原版菜单/世界音乐 |
| `slideshow` | 幻灯片元素 | |
| `video` | 视频 | 需 watermedia |
| `video_rinku` | 视频 [Rinku] | 需 rinku |
| `browser` | 浏览器 | 需 rinku |
| `glsl_shader` | GLSL 着色器 | |
| `json_model` | 方块/物品 JSON 模型 | |
| `shape` | 矩形 | |
| `shape_circle` | 圆形 | |
| `animation_controller` | 元素动画器 | 关键帧驱动其他元素 |

### 5.2 所有元素的基础键

由 `ElementBuilder.serialize()` 与 `AbstractElement` 的属性表共同决定：

```
element_type                 元素类型（见 5.1）
instance_identifier          元素唯一 ID
                             · 自定义元素：随机 UUID + 时间戳，如 9ef23ca4-...-1790786982052
                             · vanilla_button：控件定位符（见 5.4）
anchor_point                 锚点：top-left / top-centered / top-right /
                             mid-left / mid-centered / mid-right /
                             bottom-left / bottom-centered / bottom-right /
                             vanilla（跟随原版控件原始位置）/ element（锚定另一元素）
x, y                         相对锚点的偏移（可为负）
width, height                尺寸
stay_on_screen               是否保持在屏幕内
sticky_anchor                滚动时是否吸附
auto_sizing / auto_sizing_base_*     自动缩放及其基准（屏幕宽高 / GUI 缩放 / GUI 宽高）
advanced_posx / advanced_posy / advanced_width / advanced_height
                             高级定位尺寸；默认 -2147483648（= Integer.MIN_VALUE，表示未启用）
stretch_x / stretch_y        拉伸
appearance_delay / appearance_delay_seconds     出现延迟
disappearance_delay / disappearance_delay_seconds  消失延迟
fade_in_v2 / fade_in_speed   淡入（no_fading / first_time / ...）
fade_out / fade_out_speed    淡出
base_opacity                 基础不透明度
enable_parallax / invert_parallax / parallax_intensity_x / parallax_intensity_y
animated_offset_x / animated_offset_y
load_once_per_session        每会话只加载一次
layer_hidden_in_editor       编辑器内隐藏
advanced_rotation_mode / rotation_degrees / advanced_rotation_degrees
advanced_vertical_tilt_mode / vertical_tilt_degrees / advanced_vertical_tilt_degrees
advanced_horizontal_tilt_mode / horizontal_tilt_degrees / advanced_horizontal_tilt_degrees
should_be_affected_by_decoration_overlays
in_editor_color              仅编辑器内显示的颜色
element_loading_requirement_container_identifier
                             → 该元素的显示条件容器 UUID
[loading_requirement_container_meta:<uuid>] = [groups:][instances:]
```

> **`advanced_posx` 的 `-2147483648` 不是坐标，是「未启用」哨兵值**（源码 `Integer.MIN_VALUE`，`AbstractElement.java:170-173`；`Property.isEmptyNumberValue` 视其为空，`Property.java:146-149`）。手写文件时照抄即可；只有四个 `advanced_*` 都是这个值时才回退到锚点计算（`AbstractElement.java:631-633`）。
>
> ⚠️ **`stay_on_screen` 有反直觉默认值**：字段初值是 `true`，但**键缺失时会被强制设为 `false`**（`ElementBuilder.java:153-155`）。要「保持在屏幕内」必须显式写 `stay_on_screen = true`。
>
> **`width = %guiwidth%` / `height = %guiheight%`** 会被自动转换成 `stretch_x` / `stretch_y`。

**实测枚举值**（手写时只能填这些）：

| 键 | 合法值 |
|---|---|
| `anchor_point` | `top-left` `top-centered` `top-right` `mid-left` `mid-centered` `mid-right` `bottom-left` `bottom-centered` `bottom-right` `vanilla` `element`（旧别名 `original` → `vanilla`；非法值回退 `top-left`） |
| `appearance_delay` / `disappearance_delay` | `no_delay` `first_time` `every_time` |
| `fade_in_v2` / `fade_out` | `no_fading` `first_time` `every_time` |
| `audio_v2` 的 `play_mode` | `normal` `shuffle` |
| `ticker` 的 `tick_mode` | `normal` `once_per_session` `on_menu_load` |
| `splash_text` 的 `source_mode` | `direct` `text_file` `vanilla` |
| `text_v2` / `tooltip` 的 `source_mode` | `direct` `resource`（旧值 `local`/`web` → `resource`） |
| `slider_v2` 的 `slider_type` | `list` `integer_range` `decimal_range` |
| `progress_bar` 的 `direction` / `value_mode` | `left` `right` `up` `down` / `percentage` `float` |
| `input_field` 的 `input_field_type` | `integer` `decimal` `url` `text` |
| `player_entity_v2` 的 `player_pose` | `standing` `crouching` `sleeping` `swimming` `dying` `spin_attack` |
| `glsl_shader` 的 `compile_mode` | `auto` `direct` `shadertoy` |
| `glsl_shader` 的通道输入 | `none` `resource0`~`resource3` `buffer_a`~`buffer_d` |
| `template_share_with` | `buttons` `sliders` |

其他要点：
- `load_once_per_session` 的实现是切屏时写一个记忆键 `hide_once_per_session_element`（`ScreenCustomization.java:322-326`），不是持久化开关。
- `layer_hidden_in_editor` **只影响编辑器**，不影响游戏内显示。
- **系统保留键**（不要自定义）：`action`、`element_type`、`actionid`、`instance_identifier`、`button_identifier`（`ElementBuilder.java:329-348`）。

### 5.3 类型专属键（摘要）

完整表见 `_research\ref-element-types.txt`。最常用的几类：

**`custom_button`** —— 整合包做菜单按钮的主力：

```
label                     按钮文字（支持占位符）
hoverlabel                悬停时替换文字
description               悬停提示（可放序列化占位符）
backgroundnormal          普通态背景贴图
backgroundhovered         悬停态背景贴图
background_texture_inactive  禁用态背景贴图
iconnormal / iconhovered / icon_texture_inactive  三态图标
clicksound / hoversound   音效
navigatable               可键盘导航
transparent_background    透明背景
underline_label_on_hover
restartbackgroundanimations
nine_slice_custom_background / nine_slice_border_x / nine_slice_border_y
is_template / template_share_with / template_apply_*
button_element_executable_block_identifier     ← 点击时执行的动作块 UUID
widget_active_state_requirement_container_identifier  ← 「按钮是否可用」的条件容器
```

**`image`**：

```
source                    例：[source:local]/config/fancymenu/assets/bg1.png
image_tint                例：#FFFFFF
repeat_texture
nine_slice_texture / nine_slice_texture_border_x / nine_slice_texture_border_y
restart_animated_on_menu_load
rounding_radius_top_left / top_right / bottom_right / bottom_left
```

**`audio_v2`**：

```
audio_instance_0..n       音频源列表
audio_instance_weight_0..n  权重
play_mode                 shuffle / ...
looping
sound_source              music / master / ...
volume                    0.0~1.0
```

**`music_controller`**：`play_menu_music`、`play_world_music`

**`item`**：`item_key`、`item_name`、`lore`、`enchanted`、`custom_nbt_data`、`show_tooltip`

**`input_field`**：`navigatable`、`input_field_type`、`linked_variable`

**`item` 之外的 `player_entity_v2`**：`playername`、`copy_client_player`、`showname`、`is_baby`、`slim`、`player_pose`、`body_movement`、`body_follows_mouse`、`head_follows_mouse`、`skinsource`/`skinpath`/`skinurl`、`capepath`/`capeurl`、`parrot`、`parrot_left_shoulder`，以及 `head_/body_/left_arm_/right_arm_/left_leg_/right_leg_` × `x/y/z_rot` 与其 `*_advanced_mode`

### 5.4 `vanilla_button`：改写原版控件（本整合包用得最多）

它不新建控件，而是**接管界面上已有的原版/模组控件**，然后可以改位置、改尺寸、改文字、隐藏、甚至自动点击。专属键只有：

```
instance_identifier      控件标识符（见下）
is_hidden                是否隐藏该控件
automated_button_clicks  自动点击次数
```

**控件标识符的两种来源**：

1. **语义化标识符（稳定，推荐）** —— 来自 `customization/widget/identification/identificationcontext/contexts/`：

   | 界面 | 标识符 | 对应原版控件 |
   |---|---|---|
   | `title_screen` | `mc_titlescreen_singleplayer_button` | `menu.singleplayer` |
   | | `mc_titlescreen_multiplayer_button` | `menu.multiplayer` |
   | | `mc_titlescreen_options_button` | `menu.options` |
   | | `mc_titlescreen_quit_button` | `menu.quit` |
   | | `mc_titlescreen_realms_button` | `menu.online` |
   | | `mc_titlescreen_language_button` / `_accessibility_button` | 左下角小按钮 |
   | | `forge_titlescreen_mods_button` | `fml.menu.mods` |
   | `pause_screen` | `mc_pausescreen_return_to_game_button` 等 | |
   | `death_screen` | `mc_deathscreen_respawn_button` / `mc_deathscreen_titlemenu_button` | |
   | 内建常量 | `minecraft_logo_widget` / `minecraft_splash_widget` / `minecraft_branding_widget` / `minecraft_realms_notification_icons_widget` / `title_screen_copyright_button` | |

   共 **45 个** 由 Mixin 显式注册的标识符 + 三套 `IdentificationContext` 的约 25 个 `mc_titlescreen_*` / `mc_pausescreen_*` / `mc_deathscreen_*`，另有选项界面自动生成的 `fancymenu_options_<翻译键>` / `options_<翻译键>`。完整表见 `_research\ref-screen-widget-identifiers.txt` 与 `02-elements.md`。

   > ⚠️ **`mojang_logo` 与 `progress_bar` 不在 FancyMenu 里注册**（源码全树无此标识符；旧名 `title_screen_logo` 现为 `minecraft_logo_widget`）。
   > 本项目 `loading_1/2.txt` 里用到的这两个，来自 **Drippy Loading Screen 模组自身的 `DrippyOverlayScreen`**（已验证：`de/keksuccino/drippyloadingscreen/customization/DrippyOverlayScreen.class` 内含这两个字符串）。
   > → 它们是**加载界面专用**的；在普通界面上写 `mojang_logo` 不会生效。

2. **数字型标识符（脆弱，别手写）** —— 由 `ScreenWidgetDiscoverer.generateBaseId()` 生成：

   ```java
   // ScreenWidgetDiscoverer.java:264-271
   String s = "" + Math.abs(widget.getX()) + Math.abs(widget.getY());
   return Long.parseLong(s);
   // 若冲突则末尾追加 '1' 再 parse（:273-282）
   ```

   → 即 **「|x| 拼 |y|」**。例：`instance_identifier = 580970` 表示 x=58, y=970。
   本项目里 `604388`、`376388`、`346970`、`502970` 等都是这么来的。

   **风险**：一旦该控件的位置或界面布局变了，数字就变了，绑定会失效（变成「改了个不存在的控件」，静默无效）。**手工改布局时一律优先用第 1 类语义化标识符。**

**`title_screen_copyright_button`** 有特殊保护：不允许隐藏（`VanillaWidgetElement.isHidden()` 强制返回 false），且不透明度下限 0.4（`VanillaWidgetElement.java:203-226`）。

### 5.5 元素模板

`custom_button` 支持模板化：勾选 `is_template` 后，配合 `template_share_with`（如 `buttons`）和 `template_apply_*` 系列开关，把该按钮的宽/高/位置/透明度/可见性/文字共享给其他按钮。改一处、全体跟随 —— 做「一排图标按钮」时很有用。

---

## 6. 动作脚本系统：整份 FancyMenu 里最强的功能

源码目录：`customization/action/`。核心概念：**可执行块（ExecutableBlock）** 里装 **动作实例（ActionInstance）**。

### 6.1 序列化语法（源码实测）

`ActionInstance.serialize()`（`ActionInstance.java:116-122`）：

```java
String key = "[executable_action_instance:" + identifier + "][action_type:" + action.getIdentifier() + "]";
c.putProperty(key, value);
```

`ExecutableBlockDeserializer.deserializeAll()`（`ExecutableBlockDeserializer.java:35-78`）解析块：

```java
// key 形如 [executable_block:<uuid>][type:<blockType>]
// value 形如 [executables:<uuid1>;<uuid2>;]     或   [executables:<uuid>][appended:<uuid>]
```

所以一个「加了 QQ 群按钮」的最小形态是：

```
element {
  ...
  element_type = custom_button
  instance_identifier = 9ef23ca4-5f78-4128-a6d9-dd261989c2b0-1790786982052
  backgroundnormal = [source:local]/config/fancymenu/assets/qq-normal.png
  backgroundhovered = [source:local]/config/fancymenu/assets/qq-hover.png
  label =
  button_element_executable_block_identifier = 8513838e-2cd9-426c-b4d7-51b73d048bb2-1790786982052
  [executable_action_instance:99c74648-d4fc-4476-80b0-3e3d829c619c-1790787242260][action_type:openlink] = https://pd.qq.com/g/beloong888
  [executable_block:8513838e-2cd9-426c-b4d7-51b73d048bb2-1790786982052][type:generic] = [executables:99c74648-d4fc-4476-80b0-3e3d829c619c-1790787242260;]
  ...
}
```

三处 UUID 的关系：
- `button_element_executable_block_identifier` = **块**的 UUID
- `[executable_block:<块UUID>][type:...]` 的 value 里 `[executables:...]` = 该块包含的**动作** UUID 列表
- `[executable_action_instance:<动作UUID>][action_type:...]` = 动作本体

UUID 格式为 `<随机 UUID>-<毫秒时间戳>`，**只要文件内唯一即可，手写时可以自己造**（保证同一文件不重复、被引用方与定义方一致就行）。

### 6.2 块类型（`[type:...]`）

| `type` | 类 | 作用 |
|---|---|---|
| `generic` | `GenericExecutableBlock` | 顺序执行内部动作（最常用） |
| `if` | `IfExecutableBlock` | 条件为真则执行 |
| `else-if` | `ElseIfExecutableBlock` | |
| `else` | `ElseExecutableBlock` | |
| `while` | `WhileExecutableBlock` | 条件循环 |
| `delay` | `DelayExecutableBlock` | 延时 |
| `execute-later` | `ExecuteLaterExecutableBlock` | 延后执行 |
| `folder` | `FolderExecutableBlock` | 折叠分组（组织用） |
| `comment` | `CommentExecutableBlock` | 注释 |

**条件分支靠 `[appended:<uuid>]` 串联**：`if` 块通过 `appended` 指向 `else-if`，`else-if` 再指向 `else`（`ExecutableBlockDeserializer.java:51-53, 69-75`）。

**这等于给了整合包作者一门可视化脚本语言**：可以做「第一次进主菜单弹提示」「按条件切换按钮」「延时切背景」等。

### 6.3 动作类型：63 个真实 `action_type`

⚠️ **重大陷阱**：`action_type` 的**真实标识符与语言键不同名**！
例如关闭界面是 **`closegui`**（不是 `close_screen`）、复制到剪贴板是 **`copytoclipboard`**（不是 `copy_to_clipboard`）、进世界是 **`loadworld`**、离开世界是 **`disconnect_server_or_world`**。
本目录下 `ref-actions.txt` 是按**语言键**导出的索引，**只能用来查中文说明，不能照抄成 action_type**。真实清单见 `_research\ref-actions-real-ids.txt`。

来源：`Actions.java:137-199` 注册顺序 + 各类 `getIdentifier()`。`hasValue` 列表示该动作是否需要 `= 值`。

**流程 / 界面**

| action_type | 有值 | 说明 |
|---|---|---|
| `opengui` | ✓ | 打开界面或自定义 GUI（值 = 界面标识符） |
| `closegui` | ✗ | 关闭当前界面（不在世界中则回标题界面） |
| `back_to_last_screen` | ✗ | 返回上一个界面 |
| `update_screen` | ✗ | 更新当前界面（等价于改窗口大小） |
| `reloadmenu` | ✗ | 重载 FancyMenu（全景、幻灯片等） |
| `quitgame` | ✗ | 退出游戏 |

**跳转 / 服务器**

| action_type | 有值 | 说明 |
|---|---|---|
| `joinserver` | ✓ | 加入服务器（值 = IP） |
| `loadworld` | ✓ | 进入世界（值 = 世界文件夹名） |
| `join_last_world` | ✗ | 进入/加入上一个世界或服务器 |
| `disconnect_server_or_world` | ✓ | 离开世界/服务器（值 = 之后要打开的界面标识符） |

**消息 / 命令 / 输入**

| action_type | 有值 | 说明 |
|---|---|---|
| `sendmessage` | ✓ | 发送聊天消息或命令 |
| `execute_command_as_integrated_server` | ✓ | 以集成服务器身份执行命令（单人下忽略权限；联机无效） |
| `display_in_chat_client_side` | ✓ | 仅本地聊天显示（支持 `&` 格式码与 JSON 组件） |
| `paste_to_chat` | ✓ | 粘贴文本到聊天输入框 |
| `set_text_input_field_value` | ✓ | 按元素标识符设置输入框的值（支持占位符） |
| `copytoclipboard` | ✓ | 复制文本到剪贴板 |
| `print_to_log` | ✓ | 打印到游戏日志 |

**系统 / 交互**

| action_type | 有值 | 说明 |
|---|---|---|
| `openlink` | ✓ | 用默认浏览器打开 URL |
| `open_file_folder_in_game_dir` | ✓ | 用系统默认程序打开文件/文件夹 |
| `show_toast` | ✓ | 显示 Toast（值 = **JSON**） |
| `play_audio` | ✓ | 播放一次音频（值 = **JSON**） |
| `stop_all_action_audios` | ✗ | 停止所有「播放音频」动作启动的音频 |
| `mimicbutton` | ✓ | 模仿原版/模组按钮点击（值 = 控件定位符） |
| `mimic_keybind` | ✓ | 模仿按键绑定 |
| `edit_minecraft_option` | ✓ | 修改 Minecraft 选项 |
| `manage_resource_pack` | ✓ | 按显示名启用/禁用/切换资源包 |
| `reload_resource_packs` | ✗ | 等价 F3+T（每 5 秒限一次） |

**文件（全部限定在游戏目录内；`.minecraft/` 前缀可访问 .minecraft 根）**

| action_type | 有值 | 说明 |
|---|---|---|
| `create_file_in_game_dir` | ✓ | 创建空文件 |
| `write_file_in_game_dir` | ✓ | 写入文件（内容里的换行要写字面 `\n`） |
| `copy_file_in_game_dir` | ✓ | 复制文件/文件夹（源路径末尾 `*` = 复制直接子项） |
| `move_file_in_game_dir` | ✓ | 移动 |
| `rename_file_in_game_dir` | ✓ | 重命名 |
| `delete_file_in_game_dir` | ✓ | 删除（末尾 `*` = 删直接子项但保留文件夹） |
| `download_file_to_game_dir` | ✓ | 异步下载到文件夹 |
| `extract_zip_file_in_game_dir` | ✓ | 异步解压 ZIP |
| `select_file_to_game_dir` | ✓ | 打开原生文件选择框并复制进来 |

**布局 / 元素动画器**

| action_type | 有值 | 说明 |
|---|---|---|
| `enable_layout` / `disable_layout` / `toggle_layout` | ✓ | 按**布局名**（= 文件名去扩展名）启用/禁用/切换 |
| `enable_element_animator` / `disable_element_animator` / `toggle_element_animator` / `reset_element_animator` | ✓ | 按动画器标识符操作 |

**音频元素 / 视频**

`audio_next_track`、`audio_previous_track`、`audio_toggle_play`、`set_audio_element_volume`（值 = `元素标识符:音量`）、
`set_video_element_volume` / `set_video_element_play_time` / `toggle_video_element_pause_state`、
`set_video_menu_background_volume` / `set_video_menu_background_play_time` / `toggle_video_menu_background_pause_state`（均带值）

**变量 / 调度器 / 网络**

| action_type | 有值 | 说明 |
|---|---|---|
| `set_variable` | ✓ | 值 = `变量名:变量值` |
| `clear_variables` | ✗ | 清空变量 |
| `start_scheduler` / `stop_scheduler` | ✓ | 按调度器标识符启动/停止 |
| `send_http_request` | ✓ | HTTP 请求（值 = **15 段**分隔串） |
| `send_fm_data_to_server` | ✓ | 经 FMData 通道发给已连接服务器 |
| `connect_to_remote_server` | ✓ | 建立远程 WebSocket 连接 |
| `send_data_to_remote_server` | ✓ | 复用/新建连接并发送文本 |
| `close_remote_server_connection` | ✓ | 按请求 ID 关闭连接 |
| `close_all_remote_server_connections` | ✗ | 关闭全部连接 |

### 6.4 动作的值（value）与分隔符

`=` 右侧就是该动作的参数。**分隔符不统一**：

| 分隔符 | 用于 |
|---|---|
| 单值 | `openlink`（URL）、`opengui`（界面标识符）、`sendmessage`、`joinserver`、`loadworld`、`print_to_log`、`copytoclipboard`、`display_in_chat_client_side` |
| `:`（2 段） | `set_variable`（`变量名:变量值`）、`set_audio_element_volume`（`元素:音量`） —— **注意这是历史写法** |
| `\|\|`（2 段） | 多数新式多参数动作 |
| `\|\|\|`（3~4 段） | 文件类等 3~4 参数动作 |
| 15 段 | `send_http_request` |
| **JSON** | `play_audio`、`show_toast` |
| 空 | `hasValue = false` 的动作（`quitgame`、`reloadmenu`、`clear_variables` 等） |

> ⚠️ **`canRunAsync`**：63 个动作里只有 `show_toast` 与 `stop_all_action_audios` 允许异步，其余**必须在游戏主线程执行**。所以放在 `Ticker` 元素的 Async 模式里会失败（源码会弹错误框）。

> ⚠️ **动作不能直接挂条件**：`ActionInstance` **没有** requirement 字段。动作要加条件，只能用 `if` / `else-if` / `while` 块包住它。

> ⚠️ **动作 UUID 的作用域是「单个容器」**：解析时只在本容器内查找，不跨 `element`。不同元素里出现相同的动作 UUID 是**正常现象**（本项目 `beloong.txt` 就把同一组 UUID 复用给了多个社交按钮）。

> ⚠️ **legacy 与新式不能混用**：同一容器里一旦出现 `buttonaction` / `tickeraction_*`，解析器就只走 legacy 分支（`ActionInstance.java:129-136` 命中即 `break`）。

完整值语法（含每个动作的段数与示例）见 `_research\03-actions.md` 第 3 节与第 6 节的可抄用示例。

### 6.5 谁能「拥有」动作块

| 载体 | 绑定键 |
|---|---|
| `custom_button` | `button_element_executable_block_identifier` |
| `vanilla_button` | `button_element_executable_block_identifier`（同一个键） |
| `ticker` | `ticker_element_executable_block_identifier` |
| `slider_v2` | `slider_element_executable_block_identifier` |
| `checkbox` | `checkbox_element_executable_block_identifier` |
| 界面打开/关闭 | `layout_action_executable_blocks` 里的 `open_screen_executable_block_identifier` / `close_screen_executable_block_identifier` |
| 全局事件 | `listener_instance_action_script_identifier`（见 6.6） |
| 定时器 | `scheduler_action_script_identifier` |

> **`audio_v2` / `music_controller` / `video` / `video_rinku` 不能拥有动作块** —— `ExecutableElement` 只有 `ButtonElement`、`CheckboxElement`、`TickerElement`、`SliderElement` 四个实现类。它们只能被动作按 `instance_identifier` 当作**目标**操作。

### 6.6 全局监听器与调度器（不止布局内部）

这两个是**独立于布局的全局文件**，做整合包级功能时非常有用。

**`config/fancymenu/listener_instances.txt`** —— 事件监听器：

```
type = listener_instances

listener_instance {
  listener_instance_identifier = <UUID-ms>
  listener_provider_identifier = screen_open
  listener_instance_action_script_identifier = <块UUID>
  listener_instance_display_name = 可选显示名
  [executable_action_instance:<动作UUID>][action_type:sendmessage] = /say hello
  [executable_block:<块UUID>][type:generic] = [executables:<动作UUID>;]
}
```

硬性要求（`ListenerInstance.deserialize()`，`:79-115`）：容器类型必须是 `listener_instance`；`listener_provider_identifier` 必须能命中 `ListenerRegistry`；动作脚本块**必须是 `GenericExecutableBlock`**（其它块类型会被丢弃）。

⚠️ **监听器标识符不带 `on_` 前缀**（带 `on_` 的是语言键）。真实标识符如 `screen_open`、`screen_close`、`keyboard_key_pressed`、`keyboard_key_released`、`keyboard_char_typed`、`element_spawned_via_action`、`world_entered`、`world_left`、`server_joined`、`server_left`、`block_broke`、`block_placed`、`chat_message_received`、`chat_message_sent`、`damage_taken`、`death`、`dimension_entered`、`enter_biome`、`leave_biome`、`enter_structure`、`leave_structure`、`entity_died`、`item_used`、`item_picked_up`、`item_dropped`、`jump`、`started_running`、`stopped_running`、`started_burning`、`started_freezing`、`start_swimming`、`weather_changed`、`variable_updated`、`quit_minecraft`、`file_downloaded`、`file_selected`、`zip_extracted`、`remote_server_connected`、`remote_server_data_received` 等，共 **85 个 + 3 个 legacy 别名**。全表见 `03-actions.md` 第 5 节。

**监听器能提供自定义变量**（注册为 `$$变量名` 供脚本读取）：

| 监听器 | 可用变量 |
|---|---|
| `screen_open` / `screen_close` | `screen_identifier` |
| `element_spawned_via_action` | `element_type`、`element_identifier`、`target_screen` |
| `keyboard_key_pressed` / `keyboard_key_released` | `key_name`、`key_keycode`、`key_scancode`、`key_modifiers` |
| `keyboard_char_typed` | `char` |

实例本身**没有条件字段** —— 要加条件就在脚本里用 `if` 块。

**`config/fancymenu/scheduler_instances.txt`** —— 调度器（按配置周期执行脚本），容器 `scheduler_instance { }`，动作脚本键 `scheduler_action_script_identifier`。

> 对本项目很实用：**「首次进主菜单弹提示」「玩家进天灾维度时弹标题」「玩家进入某结构时触发剧情」** 都可以用监听器实现，不必写 KubeJS。

---

### 6.7 幻灯片与立方全景：手工创建

**幻灯片**：目录 `config/fancymenu/slideshows/<名称>/`，需要 `properties.txt` + `images/`（可选 `overlay.png`）。

```
type = slideshow

slideshow-meta {
  name = beloong
  width = 1920
  height = 1080
  x = 0
  y = 0
  duration = 5.0
  fadespeed = 5.0
  randomize = true
}
```

键与默认值：`name`（必填）、`duration`（默认 10.0 秒）、`fadespeed`（默认 1.0）、`x`（0）、`y`（0）、`width`（50）、`height`（50）、`randomize`（false）。

规则：图片只接受 `.jpg` / `.png`，**不递归子目录**，按**文件名字典序**（大小写不敏感）播放；一轮的**首图时长减半**；淡出速率 = 每 25ms `opacity -= 0.005 * fadespeed` → 完整淡出约 **`5000 / fadespeed` 毫秒**。

**立方全景**：目录 `config/fancymenu/panoramas/<名称>/`，需要 `properties.txt` + `panorama/panorama_0.png` ~ `panorama_5.png`（**6 张全要，只认 .png**），可选根目录 `overlay.png`。

```
type = panorama

panorama-meta {
  name = my_panorama
  speed = 1.0
  fov = 85.0
  angle = 25.0
  start_rotation = 0.0
}
```

> 本项目已有幻灯片 `beloong`（12 张 1920×1080，`duration = 5.0`、`fadespeed = 5.0`、`randomize = true`），被 `universal_layout.txt` 用作全界面背景。

> 📌 **来源说明**：上面两段 `type = slideshow` / `type = panorama` 的头行值，取自**本项目已有的、由模组自己写出的 `slideshow/properties.txt`**（可确认可用）；其余键名与默认值来自源码。`panorama-meta` 的 `type` 头行值**未在源码中直接确认**，属同构推断 —— 手工新建全景时建议先由编辑器创建一个再改。

---

## 7. 占位符系统

### 7.1 语法

解析器 `customization/placeholder/PlaceholderParser.java`。判定「含占位符」的判据（`:180-188`）：

```java
in.length() >= 8 && in.contains("{\"placeholder\"")
```

→ **占位符不是 `%xxx%`，而是一段 JSON**：`{"placeholder":"<id>","values":{...}}`。

三种写法：

```
{"placeholder":"local","values":{"key":"ui.fancymenu.server1.desc"}}      ← 完整形式
{"placeholder":"playername"}                                              ← 无参数时 values 可省
$$变量名                                                                  ← FM 用户变量简写（前缀 "$$"）
%valueName%                                                               ← 仅动作 value 内的「值占位符」
```

其他相关常量（`:59-80`）：

| 常量 | 值 | 含义 |
|---|---|---|
| `PLACEHOLDER_PREFIX` | `{"placeholder":"` | 占位符前缀 |
| `SHORT_VARIABLE_PLACEHOLDER_PREFIX` | `$$` | 变量简写前缀 |
| `PERCENT_NEWLINE_CODE` | `%n%` | 换行 |
| `FORMATTING_PREFIX_AND` | `&` | 传统格式码前缀 |
| `FORMATTING_PREFIX_PARAGRAPH` | `§` | 原版格式码前缀 |

限制与缓存：

- **最长 17000 字符**，超了直接返回错误串（`:205-208`）
- 文本短于 **8 字符** 直接跳过解析（`:184`、`:224`）→ 短字符串里放占位符要留神
- 缓存时长由 `options.txt` 的 `placeholder_caching_duration_ms` 控制（本项目 30ms）
- 有「只能在主线程运行」的占位符；在 `Ticker` 元素的 Async 模式下会弹错误框（`Placeholder.checkAsync()`，`Placeholder.java:65-79`）

### 7.2 占位符全表（180 个）

`_research\placeholder_id_map.txt` 是「ID → 中文名」对照表；**中文说明**在 `_research\zh_cn.json` 里（键为 `fancymenu.placeholders.<snake_case 类名>.desc`）。

按类别速览：

| 类别 | 代表 ID |
|---|---|
| 玩家 | `playername` `playeruuid` `player_x_coordinate` `player_y_coordinate` `player_z_coordinate` `current_player_health` `current_player_health_percent` `current_player_hunger` `current_player_armor` `current_player_level` `current_player_exp` `player_gamemode` `player_view_direction` `active_hotbar_slot` `lastdeathmessage` `hovered_inventory_item` |
| 世界 | `current_biome` `current_dimension` `current_world_seed` `world_daytime` `world_daytime_hour` `world_difficulty` `current_title` `gamerule_value` `effects_count` `active_effect` `boss_name` `boss_count` `current_boss_health` |
| 服务器 | `servermotd` `serverping` `serverversion` `serverplayercount` `serverstatus` `current_server_ip` |
| 界面 / GUI | `screenid` `guiwidth` `guiheight` `guiscale` `elementwidth` `elementheight` `elementposx` `elementposy` `mouseposx` `mouseposy` `clicks_per_second` `text_input_field_value` `vanillabuttonlabel` |
| 时间 | `realtimeyear` `realtimemonth` `realtimeday` `realtimehour` `realtimeminute` `realtimesecond` `unix_time` `game_time` |
| 系统 | `os` `osname` `javaver` `jvmname` `jvmcpu` `oscpu` `cpuinfo` `gpuinfo` `glver` `fps` `uptime_duration` `percentram` `usedram` `maxram` |
| 字符串 / 数学 | `uppercase_text` `lowercase_text` `title_case_text` `sentence_case_text` `snake_case_text` `kebab_case_text` `toggle_case_text` `alternating_case_text` `crop_text` `trim_text` `split_text` `replace_text` `switch_case` `text_width` `text_character_count` `calc` `random_number` `maxnum` `minnum` `absnum` `negnum` `math_pi` `math_sin/cos/tan/sinh/cosh/tanh` `math_ceil/floor/round/sign` `number_base_convert` |
| 编码 / 数据 | `base64_encode` `base64_decode` `json` `stringify` `nbt_data_get` `nbt_data_get_server` |
| 文件 | `file_text` `file_size` `file_md5` `absolute_path` `webtext` |
| 变量 | `getvariable` `local`（=本地化翻译） |
| 模组 / 加载 | `mcversion` `loadername` `loaderver` `modversion` `loadedmods` `totalmods` `world_load_progress` |
| 音频 / 视频 | `audio_duration` `audio_playtime` `audio_element_vol` `audio_element_current_track` `audio_playing_state` `video_*` |

### 7.3 FM 用户变量

- 存储：`config/fancymenu/user_variables.db`，格式为 `type = user_variables` + 每个变量一个容器：
  ```
  variable {
    name = 变量名
    value = 值
    reset_on_launch = false
  }
  ```
  值里的换行用 `+*||<FM_NEWLINE>||*+` 存储；写盘是**原子写入**（临时文件 + 替换）。兼容旧格式 `type = cached_variables`。
- ⚠️ **变量只有字符串类型**（`Variable.java:22-23`），没有 integer/decimal/boolean 之分；管理界面只有「名字 / 值 / 是否启动时重置」三项。
- ⚠️ **变量是全局单例**，没有 per-requirement 作用域。
- 写入动作：`set_variable`（值 = `变量名:变量值`）、`clear_variables`
- 读取占位符：`getvariable`，或简写 `$$变量名`
- ⚠️ **`$$变量名` 有个致命坑**：只有当**同一个字符串里还含有 `{"placeholder"`** 且整串长度 **≥ 8** 时才会被替换（`PlaceholderParser.java:224-234` 会提前返回）。单独一个 `$$var` 是**不会**生效的。
- ⚠️ 名字互为前缀的变量（如 `a` 与 `ab`），替换结果取决于 HashMap 迭代顺序，**不要这么命名**。
- 变量变化可触发监听器 `variable_updated`
- 条件：`fancymenu_visibility_requirement_is_variable_value`

### 7.4 `custom_locals`（本地化覆盖）

目录 `config/fancymenu/custom_locals/`（本项目为空），文件名形如 `<locale>.json` / `<locale>.lang` / `<locale>.properties`。

加载规则：**先加载 `en_us`，再用当前语言覆盖**；JSON 嵌套用 `.` 连接键；键缺失时返回键本身。

⚠️ **它不能全局改界面文本** —— 全库只有 `local` 占位符会调用它，而 `local` 占位符**只在原版 `I18n` 取不到该键时才回退**到 custom_locals。所以它是「给**你自己造的键**提供翻译」，不是「覆盖原版字符串」。

本项目 `beloong_multiplayer.txt` 的用法正好印证这一点（键 `ui.fancymenu.server1.desc` 是自制键）：

```
description = {"placeholder":"local","values":{"key":"ui.fancymenu.server1.desc"}}
```

### 7.5 资源来源前缀与支持的格式

资源路径（图片 / 音频 / 视频 / 文本）前面可以带 **来源前缀**（`util/resource/ResourceSourceType.java:23-34`）：

| 前缀 | 含义 |
|---|---|
| `[source:local]` | 本地文件，路径相对**游戏目录** |
| `[source:web]` | 网络 URL |

**无前缀时的推断顺序**（`ResourceSourceType.java:56-74`）：
`[source:local]` → `[source:web]` → `[source:location]` → URL 校验通过则 WEB → 含 `:` 且 `ResourceLocation.tryParse` 成功则 LOCATION → 否则 LOCAL。

另有三个用于**预加载器**的标记（`util/resource/preload/ResourcePreLoader.java:36-37`）：`[cubic_panorama]`、`[slideshow]`。

**路径安全边界**（`util/file/ConfinedPathResolver.java` / `LocalSourcePathResolver.java`）：

- 裸相对路径 = 相对**游戏目录**（`:114`），不是 `config/`
- 想访问 `.minecraft` 根，路径要以 `.minecraft/` 开头（`:89-92`）
- 只有「游戏目录」与「默认 `.minecraft` 目录」两个允许根（`:162-165`）
- 含 `..`、盘符路径、UNC、越界绝对路径一律 `SecurityException`，并做词法 + 真实路径双重校验（`:86-110`）

**资源包内资源**：把文件放 `assets/<ns>/<path>/<file>.<ext>`，然后写 `[source:location]<ns>:<path>/<file>.<ext>`。

**支持的文件类型**（`util/file/type/types/FileTypes.java:60-91, 93-115`）：

| 类别 | 扩展名 |
|---|---|
| 静态图片 | `png`、`jpg` / `jpeg` |
| 动画图片 | `gif`、`apng`、`fma`、`afma` |
| 音频 | `ogg`、`wav` |
| 视频 | `mp4`（**也接受 YouTube 链接**，见 `:72,77`） |
| 文本 | `txt`、`md` / `markdown`、`json`、`log`、`lang`、`local`、`properties`、`xml`、`js`、`html`、`css`、`csv` |

→ 做整合包菜单时，**GIF / APNG 可以直接当背景或元素贴图**，不需要额外模组。

---

## 8. 条件（Requirement）系统

### 8.1 容器格式（源码实测）

序列化在 `RequirementContainer.serialize()`（`RequirementContainer.java:248-272`）：

```
<挂载键> = <容器UUID>
[loading_requirement_container_meta:<容器UUID>] = [groups:<组UUID>;<组UUID>;][instances:<实例UUID>;<实例UUID>;]
```

**每个条件是一条独立的「结构化 key」属性行**：

```
[loading_requirement:<条件类型ID>][requirement_mode:<模式>] = <参数值>
```

**每个条件组也是一条属性行**：

```
[loading_requirement_group:<组UUID>] = [group_mode:<AND|OR>]
```

组的成员关系由「组的 UUID 出现在某个容器的 `[groups:...]` 里」以及组自身的序列化决定（`RequirementGroup.serializeRequirementGroup`，`:121-127`）。

**判定语义（关键）**：`RequirementContainer._requirementsMet()`（`:67-89`）是

```java
for (RequirementGroup g : groups)    if (!g.requirementsMet()) return false;
for (RequirementInstance i : instances) if (!i.requirementMet()) return false;
return true;
```

→ **容器层是纯 AND**：容器里的每个组必须成立，且每个散装实例也必须成立。
组**内部**才由 `group_mode` 决定：`AND` = 全部成立才成立；`OR` = 任一成立即成立（`RequirementGroup.requirementsMet()`，`:40-49`）。

所以「A 或 B」要靠**建一个 `group_mode = OR` 的组**，不能靠在容器里并列两条实例。

`[loading_requirement_container_meta:...] = [groups:][instances:]`（两边都空）表示**无条件，永远成立**——编辑器对没有条件的元素就写这一行。

### 8.2 三个挂载点

| 挂载点 | 键 | 效果 |
|---|---|---|
| 元素是否显示 | `element_loading_requirement_container_identifier` | 条件不成立 → 元素不加载 |
| 按钮是否可用 | `widget_active_state_requirement_container_identifier` | 条件不成立 → 按钮变灰不可点（而非消失） |
| 布局是否生效 | `layout-meta` 的 `[loading_requirement_container_meta:...]` | 条件不成立 → 整个布局不生效 |

### 8.3 手写条件示例

真实 `requirement` 标识符有三种前缀形式（`fancymenu_loading_requirement_*` / `fancymenu_visibility_requirement_*` / 裸名），完整 92 个见 `_research\ref-requirements-real-ids.txt`。例如「模组是否已加载」的真实 ID 是 **`fancymenu_loading_requirement_is_mod_loaded`**，不是 `is_mod_loaded`。

「只有装了 Ice and Fire 时才显示这个按钮」：

```
element {
  element_type = custom_button
  instance_identifier = <元素UUID>
  label = 冰火专属
  ...
  element_loading_requirement_container_identifier = <容器UUID>
  [loading_requirement_container_meta:<容器UUID>] = [groups:][instances:<实例UUID>;]
  [loading_requirement:fancymenu_loading_requirement_is_mod_loaded][requirement_mode:if][req_id:<实例UUID>] = iceandfire
}
```

「装了 A 或装了 B 才显示」（**OR 必须建组**，容器层是纯 AND）：

```
  element_loading_requirement_container_identifier = <容器UUID>
  [loading_requirement_container_meta:<容器UUID>] = [groups:<组UUID>;][instances:]
  [loading_requirement_group:<组UUID>] = [group_mode:or]
  [loading_requirement:fancymenu_loading_requirement_is_mod_loaded][requirement_mode:if][group:<组UUID>][req_id:<实例UUID1>] = iceandfire
  [loading_requirement:fancymenu_loading_requirement_is_mod_loaded][requirement_mode:if][group:<组UUID>][req_id:<实例UUID2>] = dragonsurvival
```

要点：

- `requirement_mode` = **`if`**（条件成立时满足）或 **`if_not`**（取反）
- 每条实例要有自己的 `[req_id:<实例UUID>]`；挂在组里再加 `[group:<组UUID>]`
- ⚠️ 单人需求的真实 ID 有**源码拼写错误**：`fancymenu_loading_requirement_is_singpleplayer`（少一个 `l`）。照抄错误拼写才有效
- 值格式因需求而异（有的不需要值）；完整清单与逐条判定条件见 `_research\04-placeholders-variables-requirements.md`
- **最稳的做法是用编辑器搭一次条件，再照它写出来的 `.txt` 抄**

### 8.4 条件类型（92 个真实标识符）

⚠️ 真实标识符有三种前缀形式，与语言键**不同名**：

```
fancymenu_loading_requirement_is_mod_loaded
fancymenu_visibility_requirement_is_variable_value
is_any_screen_open                     ← 裸名形式（也真实存在）
```

完整对照表见 `_research\ref-requirements-real-ids.txt`（92 行，含中文名与判定说明）。
分类分布：`gui` 14 / `realtime` 7 / `system` 6 / `window` 5 / `world` 49 / 无分类 11。

常用（**注意前缀**）：

| 用途 | 真实标识符 |
|---|---|
| 模组已加载 | `fancymenu_loading_requirement_is_mod_loaded` |
| 文件存在 | `fancymenu_loading_requirement_file_exists` |
| 语言 | `fancymenu_loading_requirement_is_language` |
| 全屏 / GUI 缩放 | `fancymenu_loading_requirement_is_fullscreen` / `fancymenu_loading_requirement_is_gui_scale` |
| 窗口宽/高 | `fancymenu_loading_requirement_is_window_width` / `..._is_window_height`（及 `..._bigger_than` 变体） |
| 单人 / 多人 | `fancymenu_loading_requirement_is_singpleplayer`（**源码拼写错误，照抄**） / `fancymenu_loading_requirement_is_multiplayer` |
| 世界已加载 | `fancymenu_loading_requirement_is_world_loaded` |
| 操作系统 | `fancymenu_loading_requirement_is_os_windows` / `..._is_os_macos` / `..._is_os_linux` |
| 服务器在线 | `fancymenu_loading_requirement_is_server_online` |
| 玩家权限等级 | `fancymenu_loading_requirement_has_player_permission_level` |
| 布局是否启用 | `fancymenu_visibility_requirement_is_layout_enabled` |
| 游戏模式 | `fancymenu_visibility_requirement_is_survival` / `..._is_creative` / `..._is_adventure` / `..._is_spectator`（也有通用 `is_gamemode`） |
| 变量值 | `fancymenu_visibility_requirement_is_variable_value` |
| 文本 / 数字 / 服务器 IP | `fancymenu_visibility_requirement_is_text` / `..._is_number` / `..._is_server_ip` |
| 界面 / 元素悬停 | `is_any_screen_open`、`fancymenu_visibility_requirement_is_any_element_hovered`、`fancymenu_visibility_requirement_is_element_hovered`、`fancymenu_visibility_requirement_is_any_button_hovered`、`fancymenu_visibility_requirement_is_button_active` |
| 实时时间 | `fancymenu_visibility_requirement_is_realtime_year` / `_month` / `_day` / `_hour` / `_minute` / `_second` / `_week_day` |
| 调度器运行中 | `fancymenu_visibility_requirement_is_scheduler_running` |
| Rinku 已加载 | `is_rinku_loaded`（本实例未装，恒 false） |
| 天气 | `is_raining`、`is_snowing`、`is_thundering`、`is_clear_weather` |
| 玩家状态 | `is_player_in_dimension`、`is_player_in_biome`、`is_player_in_structure`、`is_player_swimming`、`is_player_running`、`is_player_sneaking`、`is_player_flying_with_elytra`、`is_player_fully_frozen`、`is_player_riding_entity`、`is_hotbar_slot_active`、`is_inventory_slot_filled`、`is_entity_nearby` 等 |

`_research\ref-requirements.txt` 是**语言键**清单 —— 只用来查中文说明。

**隐藏 vs 禁用**（两个键效果不同）：

| 需求 | 挂载点 | 效果 |
|---|---|---|
| 隐藏 | `element_loading_requirement_container_identifier` | 元素不渲染（`AbstractElement._shouldRender`） |
| 禁用 | `widget_active_state_requirement_container_identifier` | 按钮/滑块/复选框变灰不可点；**原版控件用空容器时会跳过判定** |

---

## 9. 实机编辑流程（推荐给整合包作者）

### 9.1 快捷键（源码 `customization/overlay/CustomizationOverlay.java:133-173`）

⚠️ **FancyMenu 3.9.12 没有注册任何按键绑定**（全库无 `RegisterKeyMappingsEvent` / `new KeyMapping`），原版「按键绑定」界面里**找不到** FancyMenu 条目。**入口是屏幕顶部的覆盖菜单栏**，靠硬编码组合键开：
（`guiShortcutModifierDown` 在 macOS 是 Cmd，其它平台是 Ctrl —— `util/input/InputUtils.java:16-17, 41-55`）

| 组合键 | 作用 |
|---|---|
| **Ctrl + Alt + C** | 开关「自定义菜单栏」（编辑器入口） |
| **Ctrl + Alt + D** | 开关调试覆盖层（调试层里右键控件可复制定位符） |
| **Ctrl + Alt + R** | 重载 FancyMenu（布局、全景、幻灯片、`customizablemenus.txt`、`custom_gui_screens.txt`、`custom_locals`） |
| **Ctrl + Alt + L** | 直接打开**上次编辑的布局**的编辑器 |

前提：`options.txt` 里 `modpack_mode = false`，否则这 4 个快捷键**全部失效**（见 9.5）。
本项目 `show_customization_overlay = false` —— 按 Ctrl+Alt+C 会把它切成 `true`。

> 另外**没有**主菜单按钮、**没有**模组列表配置界面、**没有** `/fancymenu` 命令。不要去找这些东西。

### 9.2 标准工作流（含一个必踩的坑）

> ⚠️ **全新安装时 `customizablemenus.txt` 是空文件**，所以**所有界面一开始都是「未启用自定义」**，「布局 → 新建 → 用于当前界面」是**灰的**。
> 必须先开开关登记类名。

1. 打开目标界面（如主菜单）
2. `Ctrl + Alt + C` 打开自定义菜单栏
3. 菜单栏 →「自定义」→「当前界面自定义」**打开开关**
   → 该屏幕的**类全限定名**被写进 `config/fancymenu/customizablemenus.txt`（`ScreenCustomization.java:142-161`）
4. 菜单栏 →「布局」→「新建」→ **用于当前界面** / **用于所有界面[通用]**
5. 进入布局编辑器：
   - 编辑器菜单栏：**布局**（新建/打开/保存/另存为/布局属性/关闭）、**编辑**（撤销/重做/复制/粘贴/全选）、**元素**（新建）、**窗口**（网格、锚点覆盖层、旋转倾斜把手）
   - 空白处**右键** → 元素将直接落在鼠标位置；也可「元素 → 新建」从元素选择器里挑
   - 拖拽或**方向键**移动；拖拽时把鼠标悬在九宫格区域**「充电」约 2 秒**即可改锚点（`AnchorPointOverlay.java:298-327`）；按住 **O** 临时显示锚点覆盖层
   - 右键**原版控件** → 把它变成 `vanilla_button`（本整合包大量使用的能力）；编辑器可直接**复制控件定位符**
   - `Ctrl+S` 保存、`Ctrl+G` 切网格、`Del` 删除
6. 保存 → 写入 `config/fancymenu/customization/<名称>.txt`，并立即 `LayoutHandler.reloadLayouts()`
7. 关闭编辑器会自动重建当前界面（`LayoutEditorScreen.java:1341-1359`），可立刻看到效果

### 9.3 手工把某个模组界面变成可自定义

1. 拿到屏幕类全限定名（编辑器里「自定义 → 复制当前界面标识符」给的是**标识符**；要类名就在菜单栏里看，或按 2.2 节写类名）
2. 在 `customizablemenus.txt` 追加：
   ```
   com.example.mymod.MyScreen {
   }
   ```
   ⚠️ 这里**只能写屏幕类全限定名**。写 `title_screen` 这类通用标识符会被判非法并**丢弃**（`ScreenCustomization.java:238-246`）。
3. 确认不在**内置黑名单**里（`ScreenCustomization.java:354-375`，19 条规则：`Create`、`OptiFine`、`twilightforest`、`appeng`、`xaero`、含 `.cobblemon.` 的类、`de.keksuccino.fancymenu.` 自身等）
4. `Ctrl + Alt + R` 重载

### 9.4 「菜单栏有，但布局不生效」——最常见困惑

两种状态要分清：

| 状态 | 表现 | 原因 |
|---|---|---|
| 白名单**未命中** | 菜单栏照常显示，但**布局完全不渲染** | 该屏幕没登记进 `customizablemenus.txt` |
| 黑名单**命中** | **连菜单栏都没有** | 命中内置黑名单规则 |

→ 排查顺序：先看 `customizablemenus.txt` 有没有这个类名，再看类名是否撞内置黑名单。

### 9.5 `modpack_mode` 的真实效果

设成 `true` 时（`options.txt` → `[customization] modpack_mode`）：

| 效果 | 说明 |
|---|---|
| 菜单栏**永不显示** | 玩家看不到编辑器入口 |
| `Ctrl+Alt+C/D/R/L` **全失效** | 无法自助进入编辑器 |
| 不弹欢迎窗口 | |
| 提供需求条件 `is_modpack_mode_enabled` | 可用它让某些元素只在整合包模式下出现 |

⚠️ 它**不会**禁用布局渲染、全局自定义，也**不会**禁用命令。它是「藏起编辑器」，不是「锁死功能」。

### 9.6 什么时候需要重启 / 什么时候按 Ctrl+Alt+R 就够

| 能用 `Ctrl+Alt+R`（或动作 `reloadmenu`） | 必须重启游戏 |
|---|---|
| 布局 `.txt`、`customizablemenus.txt`、`custom_gui_screens.txt` | `default_gui_scale`（只在 `fancymenu_data/default_scale_set.fm` 不存在时生效一次） |
| `assets/`、`slideshows/`、`panoramas/`、`ui_themes/`、`custom_locals/` | 开场动画（每次启动只播一次） |
| `listener_instances.txt`、`scheduler_instances.txt` | 窗口图标 |

> ⚠️ **Minecraft 自身的资源重载（F3+T）不会重载布局**。布局只在三处重载：启动、编辑器保存后、`Ctrl+Alt+R`。

### 9.7 服务端命令

FancyMenu 只注册**服务端**命令（经自定义包转发给装了 FancyMenu 的客户端；`commands/Commands.java:21-27`）：

```
/openguiscreen <屏幕标识符> [目标玩家]
/closeguiscreen [目标玩家]
/fmvariable get|set <名称> <是否反馈> <值>
/fmlayout <布局名> <true|false> [目标玩家]      # 启用/禁用布局
/fmdata send|listener|welcome_data ...
```

→ 对整合包运营有用：可以用 `/openguiscreen` 在服务器上**远程让玩家客户端打开某个自定义 GUI**（如公告板、规则页）。

---

## 10. 纯文本手写流程（批量 / 版本管理友好）

整合包作者常需要**可 diff、可脚本生成**的布局。可行，但必须遵守以下硬约束。

### 10.1 可以安全手写的部分

✅ `layout-meta` 全部字段
✅ `menu_background`（`image` / `color` / `slideshow` 三种无外部依赖）
✅ `customization` / `scroll_list_customization`
✅ `element`（`image` / `custom_button` / `text_v2` / `item` / `shape` 等）
✅ `layout_action_executable_blocks` + 动作脚本
✅ 条件容器（`[groups:][instances:]`）
✅ `slideshow` 的 `properties.txt`
✅ `ui_themes/*.json`

### 10.2 不要手写的部分

❌ **`vanilla_button` 的数字型 `instance_identifier`** —— 它是位置派生的（见 5.4），手写几乎不可能算对。要用就用语义化标识符。
❌ **`browser` / `video` / `video_rinku` / `glsl` 背景与元素** —— 本实例缺 rinku / watermedia，写了也不生效（见第 11 节）。
❌ **`layout_editor/widgets/*.lewidget`** —— 是编辑器面板状态，属于每用户数据。

### 10.3 手写模板

最小可用的主菜单布局骨架：

```
type = fancymenu_layout

layout-meta {
  identifier = title_screen
  render_custom_elements_behind_vanilla = false
  last_edited_time = 0
  is_enabled = true
  randommode = false
  randomgroup = 1
  randomonlyfirsttime = false
  layout_index = 0
  [loading_requirement_container_meta:<自造UUID>] = [groups:][instances:]
}

menu_background {
  instance_identifier = <自造UUID>
  background_type = image
  show_background = true
  image_path = [source:local]/config/fancymenu/assets/bg1.png
  slide = false
  repeat_texture = false
  parallax = false
  parallax_intensity_x = 0.02
  parallax_intensity_y = 0.02
  invert_parallax = false
  restart_animated_on_menu_load = false
}

customization {
  action = backgroundoptions
  keepaspectratio = false
}

element {
  element_type = custom_button
  instance_identifier = <自造UUID>
  anchor_point = mid-centered
  x = -100
  y = 40
  width = 200
  height = 20
  stay_on_screen = true
  label = &l开始游戏
  backgroundnormal = [source:local]/config/fancymenu/assets/button_0.png
  backgroundhovered = [source:local]/config/fancymenu/assets/button_1.png
  button_element_executable_block_identifier = <块UUID>
  [executable_action_instance:<动作UUID>][action_type:opengui] = select_world_screen
  [executable_block:<块UUID>][type:generic] = [executables:<动作UUID>;]
  widget_active_state_requirement_container_identifier = <条件UUID>
  [loading_requirement_container_meta:<条件UUID>] = [groups:][instances:]
}

layout_action_executable_blocks {
}
```

**UUID 生成规则**：`<任意 UUID v4>-<毫秒时间戳>`。手工时用在线 UUID 生成器或 PowerShell `[guid]::NewGuid()` 造，**同一文件内唯一、引用一致**即可。源码不校验时间戳真伪。

### 10.4 手写后必须做的一致性检查

1. **每个被引用的 UUID 都有定义**（`button_element_executable_block_identifier` → `[executable_block:...]` → `[executable_action_instance:...]`）
2. **每个 `element` 有 `element_type` 和 `instance_identifier`**
3. **每个 `[loading_requirement_container_meta:<uuid>]` 的 uuid 与引用它的 `*_requirement_container_identifier` 一致**
4. `type = fancymenu_layout` 在首行
5. 花括号配对；`}` 顶格或缩进都可以，但必须存在
6. **用编辑器打开一次**（Ctrl+Alt+L 或对应界面）确认能正常加载、元素位置正确 —— 这是唯一的实机验收手段

---

## 11. 『化龍』现状与具体建议

### 11.1 已有的三套菜单

| 界面 | 文件 | identifier | 效果 |
|---|---|---|---|
| 主菜单 | `beloong.txt` | `title_screen` | `bg1.png` 全屏背景 + 双 logo + 4 个社交按钮（QQ/Discord/GitHub/爱发电）+ 4 首 BGM 随机循环 + 13 个原版控件改写 |
| 多人游戏 | `beloong_multiplayer.txt` | `join_multiplayer_screen` | 幻灯片背景 + 2 个自定义按钮（started.ink / xyebbs） |
| 加载界面 | `loading_1/2/3.txt` | `drippy_loading_overlay`（`randommode = true`） | 三张 `loading_*.png` 随机 + logo + 进度条 |
| 所有界面 | `universal_layout.txt` | `%fancymenu:universal_layout%` | 幻灯片背景 |
| 创建/选择世界 | `create_world_screen_layout.txt` / `select_world_screen_layout.txt` | 对应界面 | — |

### 11.2 依赖缺口（必须先知道）

| modId | 状态 | 后果 |
|---|---|---|
| `konkrete` | ✅ 1.9.9 | 必需前置 |
| `melody` | ✅ 1.0.10 | 必需前置 |
| `drippyloadingscreen` | ✅ 3.1.5 | `drippy_loading_overlay` 加载界面 |
| `rinku` | ❌ **未装** | `background_type = browser` / `video_rinku`、`browser` 元素、`is_rinku_loaded` 条件全部**失效** |
| `watermedia` | ❌ **未装** | `background_type = video`、`video` 元素**失效** |
| `fancy_entity_renderer` | ❌ 未装 | 玩家实体渲染增强 |
| `findme` | ❌ 未装 | 可选 |

**结论**：布局文件里那些 browser / video / video_rinku 模板块**全部 `show_background = false` / `show_decoration_overlay = false` 是正确做法，不要启用**。

### 11.3 立即可做的具体改进

1. **`glsl` 背景可用且很有表现力** —— 它是 FancyMenu 原生的（不依赖 rinku/watermedia），可以直接写 Shadertoy 兼容着色器。`bg1.png` 是静态图，换成动态 GLSL 背景成本很低。
2. **把「加入服务器」做成一键按钮** —— 本项目有测试服务器。加 `custom_button` + `action_type = joinserver`，value 填服务器地址。
3. **用条件做「首次启动提示」** —— `once_per_session` 条件 + `show_toast` 或 `display_in_chat_client_side` 动作。
4. **`custom_locals` 目前是空的** —— 菜单文案若要多语言，用它比改资源包干净。
5. **`ui_themes` 可以自制主题** —— 9 个内置主题在 `config/fancymenu/ui_themes/`，照抄 `dark.json` 改色即可做整合包专属主题（注意 `identifier` 与文件名一致）。
6. **清理 `beloong.txt` 的模板块** —— 69KB 里有大量 `show_* = false` 的样板（8 个背景块 + 10 个装饰层块，其中 7+10 个是关的）。**但不要手删**：编辑器保存时会重新生成。真要精简，改成走纯手写路线并停止用编辑器编辑该文件。
7. **`layers` 与元素层** —— `AbstractElement` 有 `customElementLayerName` 字段，元素可以分层；做大改版时值得用。
8. **动作脚本被严重低估** —— 目前 4 个社交按钮都是单个 `openlink`。用 `folder` 块分组、用 `if` + `is_mod_loaded` 做条件按钮、用 `delay` 做入场序列，都是现成能力。

### 11.4 分发与版本管理（实测清单）

**必须随整合包分发**（否则菜单不生效或功能缺失）：

| 路径 | 原因 |
|---|---|
| `config/fancymenu/customization/` | 全部布局 |
| `config/fancymenu/customizablemenus.txt` | ⚠️ **不分发它，所有布局都不渲染！** 这是「布局生效白名单」 |
| `config/fancymenu/assets/` | 贴图与音乐 |
| `config/fancymenu/slideshows/`、`panoramas/` | 幻灯片 / 全景 |
| `config/fancymenu/custom_locals/` | 自制文案翻译 |
| `config/fancymenu/custom_gui_screens.txt` | 自定义 GUI 定义 + 屏幕覆盖表（本项目为空但应保留） |
| `config/fancymenu/ui_themes/` | **仅**你自己新增标识符的主题 |
| `config/fancymenu/listener_instances.txt`、`scheduler_instances.txt` | 全局监听器 / 调度器（若使用了） |
| `config/fancymenu/options.txt` | 可安全分发（缺失补默认、多余会删） |

**必须排除（每用户 / 每实例状态）**：

| 路径 | 原因 |
|---|---|
| `config/fancymenu/layout_editor/` | 编辑器面板位置等个人偏好 |
| `config/fancymenu/user_variables.db` | 游戏会写 |
| `config/fancymenu/*_element_controller_metas.json` | 音频/视频元素运行时状态 |
| `config/fancymenu/animation_controller_states.json` | 动画器状态 |
| `config/fancymenu/normalized_scroll_screens.json` | 运行时生成 |
| `config/fancymenu/dragger_metas.json` | 拖拽器状态 |
| `config/fancymenu/legacy_checklist.txt` | 旧版迁移标记 |
| `config/fancymenu/customguis/` | 旧版目录 |
| **整个 `<游戏目录>/fancymenu_data/`** | `last_world.fmdata`、`buddy/`、`cached_data/`、`video_thumbnails/`、`seamless_world_loading/`、`browser_*_settings.json`、`default_scale_set.fm`、`fancymenu_temp` |

⚠️ **一个反直觉的坑**：`ui_themes/` 里的 **9 个内置主题文件每次启动都会被 FancyMenu 重写**（`UIThemes.java:86-89`）。所以改内置主题（如 `dark.json`）**不会生效也无法分发** —— 必须新建一个 `identifier` 不重名的主题文件。

⚠️ `options.txt` 里纯用户偏好的键（`show_welcome_screen`、`ui_*`、`layout_editor`、`dev`、`default_gui_scale`）建议从分发包里删掉，让它按默认生成。

### 11.5 当前项目的一个待确认点

`create_world_screen_layout.txt` 与 `select_world_screen_layout.txt` 的 `identifier` 分别是 `create_world_screen` 与 `select_world_screen`（通用标识符，真实存在）。
而 `beloong_multiplayer.txt` 用的 `join_multiplayer_screen` 也在 121 个通用标识符之列。
→ 这 3 个都是**合法绑定**；但**它们对应的屏幕类必须已登记在 `customizablemenus.txt`**，否则布局不渲染（见 9.4）。本项目 `customizablemenus.txt` 已登记 `CreateWorldScreen`、`SelectWorldScreen`、`JoinMultiplayerScreen`，故均生效。

`loading_*.txt` 用的 `drippy_loading_overlay` 由 Drippy 模组提供（见 2.4），**不在** `customizablemenus.txt` 里也不需要 —— Drippy 自己就是 `CustomGuiBaseScreen` 一类的可自定义屏幕。

---

## 12. 参考文件索引

反编译源码根：`D:\Minecraft\闭源模组解压文件\fancymenu\decompiled\de\keksuccino\fancymenu\`

| 文件 | 内容 |
|---|---|
| `_research\01-layout-file-format.md` | 布局文件格式、`type` 全表、`layout-meta` 全键、标识符解析链（653 行） |
| `_research\02-elements.md` | 26 个元素类型 + `vanilla_button`、基础键全表、枚举实测值、香草控件标识符表（839 行） |
| `_research\03-actions.md` | 63 个动作 + 9 种块 + 条件容器 + 85 个监听器 + 可抄用示例（947 行） |
| `_research\04-placeholders-variables-requirements.md` | 180 个占位符 + 92 个需求 + 变量 + `custom_locals` + 12 个手写配方（939 行） |
| `_research\05-backgrounds-overlays-media.md` | 8 种背景 + 10 种覆盖层 + 资源系统 + 幻灯片/全景/主题/窗口（921 行） |
| `_research\06-editor-lifecycle-options.md` | 编辑器入口与工作流 + 命令 + 两个注册表 + 生命周期 + 分发清单（824 行） |
| `_research\07-beloong-current-state.md` | 本整合包 fancymenu 配置清点 |
| `_research\ref-actions-real-ids.txt` | **真实 `action_type` 标识符** 63 个（含 hasValue） ← 写动作时查这个 |
| `_research\ref-requirements-real-ids.txt` | **真实 requirement 标识符** 92 个（含中文名与判定说明） ← 写条件时查这个 |
| `_research\ref-actions.txt` | 动作的**语言键**中文名与说明 ← 只用来查中文含义 |
| `_research\ref-requirements.txt` | 条件的语言键中文名与说明 ← 只用来查中文含义 |
| `_research\ref-backgrounds.txt` / `ref-decoration-overlays.txt` | 背景 / 覆盖层的语言键清单（ID 名可能有出入，以正文为准） |
| `_research\ref-listeners.txt` | 87 个监听器的语言键 |
| `_research\ref-element-types.txt` | 元素类型与键位清单 |
| `_research\ref-screen-widget-identifiers.txt` | 121 个通用界面标识符 + 香草控件标识符 + 数字型标识符算法 |
| `_research\placeholder_id_map.txt` | 180 个占位符 ID → 中文名 |
| `_research\zh_cn.json` / `en_us.json` | 从 jar 提取的官方语言文件（3367 键，含全部类型的详细说明文字） |

> **注意区分「语言键」与「注册标识符」**：`ref-actions.txt`、`ref-requirements.txt`、`ref-listeners.txt`、`ref-backgrounds.txt`、`ref-decoration-overlays.txt` 是从 `zh_cn.json` 按语言键导出的，**同名不等于可用的注册 ID**（例：语言键 `close_screen` vs 真实 `closegui`；语言键 `rain` vs 真实 `rainfall`）。
> 写文件时一律查 `*-real-ids.txt` 或本指南正文。

**反编译方式**（如需重做）：

```powershell
java -jar "D:\Minecraft\闭源模组解压文件\以太龙\cfr.jar" `
  "D:\Minecraft\闭源模组解压文件\fancymenu\fancymenu_neoforge_3.9.12_MC_1.21.1.jar" `
  --outputdir "D:\Minecraft\闭源模组解压文件\fancymenu\decompiled" `
  --caseinsensitivefs true
```

> 注：FancyMenu 的**必需前置 konkrete** 未打进 jar（`de.keksuccino.konkrete.*` 在反编译输出里是 "Could not load" 注释），所以涉及 konkrete 的细节（如 `StringUtils.splitLines` 的精确行为、写盘编码）在本次逆向中无法确认。
