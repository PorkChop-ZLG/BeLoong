# GeneralFeedback × FancyMenu 集成提案

**收件人**：GeneralFeedback 模组作者（zhenshiz）
**仓库**：<https://github.com/Mafuyu404/GeneralFeedback> — 分支 `1.21neo`
**分析的版本**：`generalfeedback-1.0.2`（NeoForge，MC 1.21.1）
**提案方**：『化龍 / BeLoong』整合包维护
**日期**：2026-10-01

---

## 0. 一句话摘要

我们希望**在不修改 FancyMenu 任何代码**的前提下，让 FancyMenu 能：

- **(需求一)** 把「打开意见反馈界面」做成一个 `custom_button`，放进整合包的**主菜单**自定义布局；
- **(需求二)** 定位并**重新摆放**模组插进 ESC 菜单的那个反馈按钮。

当前版本这两件事都做不到。原因不在 FancyMenu，而在模组侧缺少两个很小的「可发现性」接口。**本提案请求模组提供三个小改动（B1、C、A1），每个都是几行到二十几行代码，且完全向后兼容。**

---

## 1. 背景：模组现状

先说明我们对模组的理解，便于你确认我们没有误解。

### 1.1 结构与功能

| 部分 | 说明 |
|---|---|
| Mixin（仅 client，3 个） | `PauseScreenMixin` / `InventoryScreenMixin` / `DeathScreenMixin`，往对应界面注入反馈按钮 |
| `FeedbackButton` / `ActionButton` | 都继承 `CustomButton extends Button`，九宫格贴图按钮 |
| `FeedbackScreen` | 反馈表单界面（评分、正文、联系方式、提交/取消） |
| `Entry` / `Form` | 反馈条目（来自 `config/GeneralFeedback/*.json`）与提交数据 |
| `FeedbackProvider` 实现 | `VikaFeedbackProvider` / `GitHubFeedbackProvider` / `GiteeFeedbackProvider` |
| 配置 | `displayFeedbackButtonOnPauseScreen` / `...OnInventoryScreen` / `...OnDeathScreen` |
| KubeJS | `SubmitEvent` + `SubmitEventJS`（提交时可监听/取消） |

**没有**客户端命令、**没有**按键绑定、**没有**网络包注册、**没有** TitleScreen mixin —— 这些都是我们实际检索源码确认的，不是推测。

### 1.2 与本次提案直接相关的四处现状

**(a) ESC 菜单按钮的位置是运行时算出来的**

```java
// PauseScreenMixin.java:25-27
var window = Minecraft.getInstance().getWindow();
int x = window.getGuiScaledWidth()  / 2 - 88 - 18 - 18;
int y = window.getGuiScaledHeight() / 2 + 13;
addRenderableWidget(new FeedbackButton(x, y, 18, 18, EntryCache.UnitMapCache.get("default")));
```

**(b) `FeedbackScreen` 只有一个带参构造函数**

```java
// FeedbackScreen.java:36
public FeedbackScreen(Entry entry) { ... }
```

**(c) 按钮的文字标签是空的**

```java
// FeedbackButton.java:15
super(x, y, width, height, Component.nullToEmpty(""), button -> { ... });
```

（这是合理的——图标按钮不需要文字。但下文会说明它带来一个副作用。）

**(d) 已经有现成的静态入口**

```java
// FeedbackUtils.java:120-124
public static void openFeedbackScreenOf(String id) {
    if (EntryCache.UnitMapCache.containsKey(id)) {
        Minecraft.getInstance().setScreen(new FeedbackScreen(EntryCache.UnitMapCache.get(id)));
    }
}
```

---

## 2. 为什么现在做不到

### 2.1 需求一：FancyMenu 无法打开 `FeedbackScreen`

FancyMenu 有一个动作 `opengui`，作用是以「界面标识符」打开界面。它的实现是**反射构造**：

```java
// ScreenInstanceFactory.tryConstruct(...) —— FancyMenu 3.9.12
// 1) 优先找无参构造函数
for (Constructor<?> c : constructors) {
    if (c.getParameterTypes().length != 0) continue;
    constructor = c; break;
}
// 2) 退而找「参数全部受支持」的构造函数
if (constructor == null) {
    for (Constructor<?> c : constructors) {
        if (!allParametersSupported(c.getParameterTypes())) continue;
        constructor = c; break;
    }
}
```

而「受支持的参数类型」只有三个：

```java
DEFAULT_PARAMETERS.put(Screen.class, context.parentScreen());
DEFAULT_PARAMETERS.put(Player.class, Minecraft.getInstance().player);
DEFAULT_PARAMETERS.put(ClientAdvancements.class, ...);
```

`FeedbackScreen` 的两个条件都不满足：

| 检查 | 结果 |
|---|---|
| 有无参构造函数？ | ❌ 只有 `FeedbackScreen(Entry)` |
| `Entry` 是受支持类型？ | ❌ 不在 `Screen` / `Player` / `ClientAdvancements` 之内 |

→ `constructor == null` → `tryConstruct` 返回 `null` → `opengui` 报错：

```
[FANCYMENU] Unable to construct screen instance for
'com.sighs.generalfeedback.client.FeedbackScreen'!
```

**这是本提案的核心阻塞点。** 其余路径也都走不通：

- 模组没注册客户端命令 → FancyMenu 的 `sendmessage`（发命令）无命令可发
- 主菜单上没有这个按钮 → FancyMenu 的 `mimicbutton`（模拟点击已有按钮）无从下手
- KubeJS 集成只有 `SubmitEvent`（提交时触发），**没有「打开界面」的入口**

### 2.2 需求二：FancyMenu 认不出这个按钮

FancyMenu 对界面控件的识别依赖一个**稳定的字符串标识符**。它的判定顺序是：

```java
// WidgetIdentifierHandler.isIdentifierOfWidget(...)
// 1) UniqueWidget 的显式标识符
// 2) 纯数字标识符（由位置派生）
// 3) universalIdentifier（由 WidgetIdentificationContext 提供）
```

当前 `FeedbackButton` 三条都落空或不可靠：

**(1) 显式标识符**：模组没有设置。
**(2) 数字型**：FancyMenu 的数字标识符算法是

```java
// ScreenWidgetDiscoverer.generateBaseId(...)
String s = "" + Math.abs(widget.getX()) + Math.abs(widget.getY());
```

而按 §1.2(a)，`x`/`y` 由 `getGuiScaledWidth()/Height()` 算出，**随窗口尺寸与 GUI 缩放变化**。

代入 `x = W/2 − 124`、`y = H/2 + 13`（`W`/`H` 为 GUI 缩放后的宽高），数字标识符就是：

```
|W/2 − 124| 拼接 |H/2 + 13|
```

`W` 和 `H` 是「物理分辨率 ÷ GUI 缩放」，所以换 GUI 缩放会让这两个数同时变。以 1920×1080 的窗口为例（假设窗口未最大化，仅示意量级）：

| GUI 缩放 | 缩放后 `W×H` | `x` | `y` | 数字标识符 |
|---|---|---|---|---|
| 2 | 960×540 | 356 | 283 | `356283` |
| 3 | 640×360 | 196 | 193 | `196193` |
| 4 | 480×270 | 116 | 148 | `116148` |

> 表中数值按上述公式与 1920×1080 窗口推导，用于说明**变化趋势**；实际值取决于你的窗口大小。我们在整合包实例（1920×1080 显示器、`guiScale:3`）上实测到 `x = -6`，对应缩放后宽度约 235、高度约 720 —— 说明**窗口实际尺寸会显著影响结果**，这也正是问题所在。

→ 标识符不稳定，换个窗口大小或 GUI 缩放就指向空气，绑定静默失效。**不可用。**

**【好消息 · 这是本提案最省事的一半】** 我们反编译 FancyMenu 后发现，它通过 Mixin **把 `UniqueWidget` 接口注入到了原版 `AbstractWidget` 上**：

```java
// FancyMenu 3.9.12 · MixinAbstractWidget.java:75-93
@Mixin(value = {AbstractWidget.class})
public abstract class MixinAbstractWidget
        implements CustomizableWidget, UniqueWidget {

    @Unique @Nullable
    private String widgetIdentifierFancyMenu;

    // :1379
    public AbstractWidget setWidgetIdentifierFancyMenu(@Nullable String identifier) {
        this.widgetIdentifierFancyMenu = identifier;
        return this;
    }

    // :1387
    public String getWidgetIdentifierFancyMenu() {
        return this.widgetIdentifierFancyMenu;
    }
}
```

**这意味着：任何继承 `AbstractWidget` 的控件（包括你的 `CustomButton`）在任何装了 FancyMenu 的客户端上，运行时都已经具备这两个方法。** 你只需要调用它一次，就能给按钮一个永久稳定的标识符。

### 2.3 需求二的附带问题

`FeedbackButton` 的 label 是空字符串（§1.2(c)）。这**不影响**上面的方案（因为我们会改用显式标识符），但请注意：如果你的按钮**有**文字，FancyMenu 可以按「翻译键」自动给原版控件起名；标签为空时该机制不适用。所以 A 方案我们**只用显式标识符**，不碰标签。

---

## 3. 请求的 API

下面三个改动相互独立，**每一个都可以单独采纳**。我们按「收益 / 成本」排序。

---

### 【B1】让 `FeedbackScreen` 可以被 FancyMenu 反射构造 —— **优先级最高**

**目标**：让下面这行 FancyMenu 动作生效：

```
[executable_action_instance:<uuid>][action_type:opengui] = com.sighs.generalfeedback.client.FeedbackScreen
```

**做法（二选一，推荐 B1-a）**

**B1-a：给 `FeedbackScreen` 加一个无参构造函数**

```java
// FeedbackScreen.java
/** 供外部（如 FancyMenu 的 opengui 动作）以默认条目打开反馈界面。 */
public FeedbackScreen() {
    this(EntryCache.UnitMapCache.get("default"));
}
```

并在构造时对 `entry == null` 做一次保护（即当前若 `"default"` 不存在，直接返回/关闭而不是 NPE）。这样 `ScreenInstanceFactory` 的第 1 条规则就命中了。

**B1-b：注册一个屏幕实例提供方（需要 FancyMenu 作为可选依赖）**

```java
// 仅当 FancyMenu 存在时注册
ScreenInstanceFactory.registerScreenProvider(
        FeedbackScreen.class.getName(),
        () -> new FeedbackScreen(EntryCache.UnitMapCache.get("default"))
);
```

> **注意**：FancyMenu 的 `ScreenInstanceFactory` 里，`registerScreenProvider` 是**非** `@Deprecated` 的公开方法，可以放心使用。但它需要 FancyMenu 的编译期类型，所以要走「可选依赖」路线（见 §4.3）。

**期望语义**

| 项 | 期望 |
|---|---|
| 标识符 | 用**类全限定名** `com.sighs.generalfeedback.client.FeedbackScreen` 即可，无需额外别名 |
| 条目 | 无参时使用 `EntryCache.UnitMapCache.get("default")` |
| `"default"` 不存在时 | 不要抛异常、不要崩；安静地不打开或退回原界面 |
| 客户端限定 | `FeedbackScreen` 本来就是 client-only，无需额外处理 |

**收益**：整合包可以在**任意** FancyMenu 布局（主菜单、暂停界面、自定义 GUI……）里放一个反馈按钮，指向任何 `Entry`（通过后续的 C 方案可指定条目）。

---

### 【C】注册客户端命令 —— **与 B1 配套，覆盖 B1 覆盖不到的场景**

**目标**：让 FancyMenu 的 `sendmessage` 动作可以直接唤起反馈界面：

```
[executable_action_instance:<uuid>][action_type:sendmessage] = /generalfeedback open default
```

**为什么 B1 之外还需要 C**：FancyMenu 的 `sendmessage` 实现是

```java
// SendMessageAction.java:41-47
if (Minecraft.getInstance().level != null && Minecraft.getInstance().player != null) {
    if (value.startsWith("/")) { ... LocalPlayerUtils.sendPlayerCommand(...); }
    ...
}
```

它以 `/` 开头会被当作**命令**，所以需要模组注册客户端命令；同时注意它**要求玩家已进入世界**。因此：

- **C 适合**：游戏内界面（暂停界面、自定义 GUI、死亡界面等）
- **B1 适合**：主菜单等**未进入世界**的场景
- 两者互补，这也是我们希望能同时提供的原因

**建议的命令设计**

```
/generalfeedback open [entryId]     # 打开指定条目的反馈界面，省略 entryId 时用 "default"
/generalfeedback list               # 列出当前已加载的条目 id（便于整合包配置）
/generalfeedback reload             # 重新加载 config/GeneralFeedback/*.json
```

**实现要点**

- **必须注册在「客户端命令」事件上**，不要注册成服务端命令：FancyMenu 的 `sendmessage` 走的是 `LocalPlayerUtils.sendPlayerCommand`（等效于玩家在聊天框输入 `/...`）。1.21.1 每条命令都带 `CommandSourceStack`，服务端命令在单人下虽也能跑，但在**联机服用整合包**时会被服务端拒绝；客户端命令则始终在本地执行。
- **不需要任何权限等级**。
- 命令名请**不要**加 `generalfeedback:` 命名空间前缀 —— 命令在聊天里按字面名字解析，用 `/generalfeedback ...` 最直观。
- `open` 建议走 `FeedbackUtils.openFeedbackScreenOf(entryId)`，即复用你已有的静态入口；同时对不存在的 `entryId` 给出友好提示（`sendFailure` 或 Toast），而不是静默无反应。

**兼容性**：新增命令是纯增量，不影响任何现有行为。

---

### 【A1】给 ESC 菜单的反馈按钮设置稳定标识符 —— **解决需求二**

**目标**：让 FancyMenu 能定位这个按钮，从而在 `pause_screen` 布局里重新摆放它。

**做法**：在 `PauseScreenMixin` 创建按钮后，调用一次标识符设置方法。

```java
// PauseScreenMixin.java（当前）
addRenderableWidget(new FeedbackButton(
        x, y, 18, 18,
        EntryCache.UnitMapCache.get("default")
));
```

```java
// 建议改为
var button = new FeedbackButton(x, y, 18, 18, EntryCache.UnitMapCache.get("default"));
addRenderableWidget(button);

// 给 FancyMenu 一个稳定标识符（FancyMenu 不在时此调用不会发生）
GeneralfeedbackIntegration.setWidgetIdentifier(button, "generalfeedback:feedback_button");
```

其中 `GeneralfeedbackIntegration` 是一个**隔离 FancyMenu 类型引用**的小工具类，用反射实现，**无需任何编译期依赖**（见 §4.2）：

```java
// 建议放 com.sighs.generalfeedback.compat.FancyMenuCompat
public final class FancyMenuCompat {

    private static final boolean LOADED = detect();

    private static boolean detect() {
        try {
            Class.forName("de.keksuccino.fancymenu.util.rendering.ui.widget.UniqueWidget",
                    false, FancyMenuCompat.class.getClassLoader());
            return true;
        } catch (Throwable t) {
            return false;
        }
    }

    /** 给控件设置 FancyMenu 的稳定标识符；未装 FancyMenu 时静默跳过。 */
    public static void setWidgetIdentifier(Object widget, String identifier) {
        if (!LOADED || widget == null) return;
        try {
            var m = widget.getClass().getMethod("setWidgetIdentifierFancyMenu", String.class);
            m.invoke(widget, identifier);
        } catch (Throwable t) {
            // 静默失败：FancyMenu 版本变化不应影响模组主流程
        }
    }
}
```

**关于标识符取值的建议**

- 用 `generalfeedback:feedback_button` 这类**带命名空间**、语义稳定、不随版本变化的常量。
- **不要**把坐标、索引或屏幕尺寸编进去。
- 如果以后物品栏/死亡界面的按钮也希望可被 FancyMenu 编排，建议分别用
  `generalfeedback:inventory_feedback_button`、`generalfeedback:death_feedback_button`，
  形成一致约定。

**编译期依赖的两种选择**

| 方式 | 优点 | 代价 |
|---|---|---|
| **反射**（上面示例，推荐） | 零编译期依赖，FancyMenu 缺席时零影响 | 没有编译期类型检查 |
| **`compileOnly` + 可选依赖** | 有类型检查，代码更短 | 需要 build.gradle 加依赖与元数据声明 |

若选后者，代码就是：

```java
((de.keksuccino.fancymenu.util.rendering.ui.widget.UniqueWidget) button)
        .setWidgetIdentifierFancyMenu("generalfeedback:feedback_button");
```

（这正是 FancyMenu 自己给原版控件设标识符的写法，例如 `MixinPauseScreen.java:65` 的
`u.setWidgetIdentifierFancyMenu("pause_return_to_game_button")`。）

**集成后整合包会怎么做**（供你理解收益）

在 `pause_screen` 布局里加一个 `vanilla_button` 元素：

```
vanilla_button {
  element_type = vanilla_button
  instance_identifier = generalfeedback:feedback_button
  anchor_point = bottom-right
  x = -30
  y = -30
  width = 18
  height = 18
  is_hidden = false
  stay_on_screen = true
  ...
}
```

→ 按钮从「ESC 菜单正中偏左」被搬到任意位置，且**跨分辨率、跨 GUI 缩放稳定**。

---

## 4. 重要提醒与实施细节

### 4.1 ⚠️ 请**不要**采用基于「位置派生数字标识符」的临时方案

我们注意到 FancyMenu 对未标记控件会退化成 `|x|+""+|y|` 的数字标识符。我们**不建议**模组去迎合这个算法（比如故意把坐标固定成常量）。那样会把按钮位置与 FancyMenu 的内部实现细节耦合，FancyMenu 一改算法就崩。**A1 是正解。**

### 4.2 ⚠️ 反射调用要做「静默失败」

`setWidgetIdentifierFancyMenu` 是 FancyMenu 通过 Mixin 注入的**注入了的方法**。如果：

- FancyMenu 未安装 → 方法不存在
- FancyMenu 未来改了方法名/签名 → 方法不存在

都应该**安静跳过**，绝不能影响反馈按钮本身的创建与点击。上面示例里的 `try/catch (Throwable)` 就是这个目的。

### 4.3 可选依赖声明（若采用 `compileOnly` 路线）

`neoforge.mods.toml` 里建议声明为**可选**，避免玩家被迫装 FancyMenu：

```toml
[[dependencies.generalfeedback]]
modId = "fancymenu"
type = "optional"
ordering = "AFTER"
versionRange = "[3.9.0,)"
side = "CLIENT"
```

**注意**：即使声明为 optional，也**必须**保证「FancyMenu 不在时类不会加载失败」——这就是为什么我们建议把 FancyMenu 类型引用**隔离在单独的 compat 类**里，并且只在检测到 FancyMenu 时才触发该类加载。直接把 `UniqueWidget` 写进 `CustomButton` 的 `implements` 列表会**破坏无 FancyMenu 环境的类加载**，请不要那样做。

### 4.4 关于 `WidgetIdentificationContext`（A 的另一种做法，我们不推荐）

FancyMenu 里还有一个注册点 `WidgetIdentificationContextRegistry.register(...)`，理论上可以让模组为 `PauseScreen` 注册一个上下文，给控件提供「通用标识符」。

但我们**不推荐**这条路，两个原因：

1. 该类在 FancyMenu 3.9.12 中已被标注 **`@Deprecated`**（`WidgetIdentificationContext.java:20`）——未来可能移除，依赖它有风险。
2. 它需要子类化 FancyMenu 的类型（编译期依赖更重），而 A1 只需一次方法调用。

如果出于某些原因你更倾向于 Context 方案，我们也可以适配；只是从长期可维护性看，**A1 更好**。

### 4.5 ⚠️ 重复按钮的坑（整合包侧会处理，但你应知晓）

`displayFeedbackButtonOnPauseScreen` 默认为 `true`。如果整合包**同时**用 FancyMenu 又加一个反馈按钮，ESC 菜单会出现**两个**。整合包侧的做法是：

- 若采用 A1 → 把配置项设为 `false`，**由 FancyMenu 接管**那个按钮（更灵活）
- 若暂不采用 A1 → 保留模组自带的，FancyMenu 只做展示不做添加

**这不是模组的问题**，只是提醒一下这个交互，避免你接到「ESC 菜单有两个反馈按钮」的 bug 报告时困惑。

### 4.6 【B2】为什么我们不走「让 FancyMenu 支持更多构造参数」

有一种更通用的思路：让 FancyMenu 的 `ScreenInstanceFactory` 支持更多参数类型（例如通过某种注册表让第三方类型可被注入）。

**但这条路我们主动放弃了**，因为前提是「**FancyMenu 侧一行代码都不能改**」——我们既不能给它的 `DEFAULT_PARAMETERS` 加类型，也不能给它加新的扩展点。所以只能由模组侧提供「无参构造」或「实例提供方」。这也是 B1 存在的唯一原因。

### 4.7 附加请求（可选，非必需）

如果方便，以下两点会让集成体验更好，但**不做也不影响本提案成立**：

1. **允许为按钮指定非 `"default"` 的条目**。目前 `PauseScreenMixin` 硬编码了 `"default"`。如果将来有多个反馈渠道（例如「反馈 BUG」和「提建议」指向不同仓库），FancyMenu 侧会希望用不同按钮打开不同条目——C 方案的 `/generalfeedback open <entryId>` 已经覆盖了这个需求，所以 B1 保持 `"default"` 即可。
2. **`EntryCache` 的访问时机**。`PauseScreenMixin` 里已经检查了 `UnitMapCache.containsKey("default")`，很好。B1 的无参构造函数也请在 `"default"` 缺失时保持这个防御性。

---

## 5. 汇总：请求清单

| 编号 | 请求 | 涉及文件 | 预估改动量 | 解决的问题 |
|---|---|---|---|---|
| **B1** | `FeedbackScreen` 增加无参构造函数（或注册屏幕提供方） | `FeedbackScreen.java` + 可选 compat 类 | ~10 行 | 让 FancyMenu 能在**任意布局**里打开反馈界面（需求一） |
| **C** | 注册客户端命令 `/generalfeedback open\|list\|reload` | 新增一个命令类 + 注册事件 | ~60–80 行 | 命令通道触发反馈界面；世界内场景与 B1 互补 |
| **A1** | 给 `PauseScreenMixin` 的按钮设置稳定标识符 | `PauseScreenMixin.java` + compat 工具类 | ~30 行 | 让 FancyMenu 能定位并重摆 ESC 按钮（需求二） |

三者**相互独立、均为纯增量、完全向后兼容**。任意一个单独采纳都有实际收益：

- 只做 **B1** → 整合包可以在主菜单放反馈按钮 ✅（需求一达成）
- 只做 **A1** → 整合包可以重摆 ESC 按钮 ✅（需求二达成）
- 只做 **C** → 游戏内可以用命令/FancyMenu 按钮唤起反馈 ✅（部分需求一）
- **B1 + A1 全做** → 两个需求都完整达成 🎯

---

## 6. 验收方法（供你自测）

### 6.1 B1 验收

1. 装 FancyMenu 3.9.12 + GeneralFeedback
2. 主菜单 `Ctrl+Alt+C` 打开自定义菜单栏 → 进入 `title_screen` 布局编辑器
3. 新建一个自定义按钮，给它挂一个动作：
   `[executable_action_instance:<自造UUID>][action_type:opengui] = com.sighs.generalfeedback.client.FeedbackScreen`
4. 保存，退出编辑器，点击该按钮
5. **预期**：反馈表单界面打开
   **当前实际**：弹错误框，日志出现 `Unable to construct screen instance for '...FeedbackScreen'`

### 6.2 A1 验收

1. `Ctrl+Alt+C` → 进入 `pause_screen` 布局编辑器
2. 查看控件列表，应能找到标识符为 `generalfeedback:feedback_button` 的控件
3. 拖动它、改坐标、保存
4. **预期**：ESC 菜单里按钮出现在新位置；**切换 GUI 缩放（视频设置）后位置依然正确**
   **当前实际**：控件列表里它只能以随分辨率变化的数字出现，换 GUI 缩放即失效

### 6.3 C 验收

1. 进入一个世界
2. 聊天框输入 `/generalfeedback open default`
3. **预期**：反馈表单界面打开
4. 聊天框输入 `/generalfeedback list` → **预期**：列出已加载的条目 id

---

## 7. 附：我们已确认的 FancyMenu 侧事实（供你参考，无需改动）

为免你怀疑「是不是 FancyMenu 那边本来就该支持」，这里列出我们反编译 FancyMenu 3.9.12 后确认的关键事实：

| 事实 | 出处 |
|---|---|
| `opengui` 动作按标识符反射构造界面 | `OpenScreenAction.java:59-77` |
| 构造只接受无参，或参数属于 `Screen`/`Player`/`ClientAdvancements` | `ScreenInstanceFactory.java:101-105, 110-132` |
| `UniqueWidget` 接口被 Mixin 注入到 `AbstractWidget` | `MixinAbstractWidget.java:75-93, 1379-1388` |
| 未标记控件的标识符由 `|x|+""+|y|` 派生 | `ScreenWidgetDiscoverer.java:264-271` |
| 控件标识符判定顺序：显式 → 数字 → 通用 | `WidgetIdentifierHandler.java:35-47` |
| `WidgetIdentificationContext` 已 `@Deprecated` | `WidgetIdentificationContext.java:20` |
| `sendmessage` 以 `/` 开头时按命令发送，且要求已进入世界 | `SendMessageAction.java:41-47` |
| FancyMenu 支持 `custom_gui_screens.txt` 注册自定义 GUI、以及屏幕覆盖表 | `CustomGuiHandler.java:43, 62-106` |

FancyMenu 侧**没有任何**给第三方模组用的「注册自定义动作」或「注册屏幕构造参数」的公开扩展点——这正是本提案必须由模组侧配合的原因。

---

## 8. 结语

三个改动都很小，但能把 GeneralFeedback 从「一个只能在自己注入的界面上出现的按钮」，变成**整合包可以自由编排的 UI 组件**。我们相信这对其他整合包作者同样有价值——任何用 FancyMenu 做菜单的整合包，都会希望能在主菜单放一个「意见反馈」入口。

如果你对某个方案的实现细节有不同偏好（例如 B1 用实例提供方而不是无参构造、或 A1 采用 `compileOnly` 而非反射），我们都可以配合调整。也欢迎你提出更合适的接口设计——我们提案的目标是**让模组提供稳定的可发现性**，具体形式由你决定。

感谢你做出这个模组，它在我们的整合包里已经在正常工作了。

---

*本文档由『化龍 / BeLoong』整合包维护方撰写。文中所有源码引用均来自 `GeneralFeedback` 1.21neo 分支与 FancyMenu 3.9.12 的反编译产物，行号可供核对。*
