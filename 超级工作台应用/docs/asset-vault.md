# 资产管理

管理各平台账号：电商、社交、广告、主机、域名、邮箱等。档案（平台、分类、登录地址、用户名、备注、标签、公司和品牌）放在本机文件夹里，打开页面就会扫出来。密码、API 密钥、两步验证恢复码和验证器密钥只进 macOS 钥匙串。

仓库是公开的。不要提交真实账号、密码、令牌，也不要放看起来像真的样例。

## 档案放在哪

目录已在 `.gitignore` 里（`超级工作台应用/data/private/`，另外单独写了 `资产管理/`）：

```
超级工作台应用/data/private/资产管理/{分类}/{id}.json
```

分类可以用 `电商`、`社交`、`广告`、`主机`、`域名`、`邮箱`、`支付`、`其他`，也可以自己建文件夹。文件名是条目 id，例如 `8f3c1a2b4d5e6789.json`。第一次在 Mac 应用里保存时会自动建目录。

只写这些字段：

```json
{
  "id": "example-shop-001",
  "platform": "示例平台",
  "category": "电商",
  "loginURL": "https://example.com/login",
  "username": "shop-user",
  "email": "",
  "notes": "不要在这里写密码",
  "twoFactor": "none",
  "tags": ["店铺"],
  "company": "",
  "brand": "",
  "updatedAt": "2026-11-11T00:00:00Z"
}
```

`email` 可选。旧档案没有这一栏也能打开。若 `username` 看起来像邮箱、且 `email` 为空或相同，卡片合并成一行「账号/邮箱」，点击仍复制这个地址。两者不同时分成「账号」和「邮箱」两行。不要把真实邮箱写进会提交的示例。

`twoFactor` 只记类型：`none`、`totp`、`sms`、`email`、`hardware`、`other`。不要把验证器密钥写进这个文件。Mac 应用里默认不保存验证器密钥，除非你自己打开「我明确要保存验证器密钥」并填写。

如果 JSON 里出现 `password`、`apiKey`、`recoveryCodes`、`totpSecret`、`token` 这类字段：Mac 应用会把它们移进钥匙串并改写文件；局域网服务会直接删掉这些字段，不会另存。两种情况下明文都不会留在文件里。

## 钥匙串

- 服务名：`com.ky.superworkbench.assets`
- 账户名：`asset:` 加上条目 id
- 只有本机已解锁、并且通过 Touch ID 或开机密码之后，Mac 应用才会复制单条密码或 API 密钥
- 卡片上的密码和 API 一直显示成圆点。复制成功后短暂提示「已复制」，圆点不会变成明文
- 复制后大约 45 秒，如果剪贴板里还是这条密钥，会自动清掉。账号、邮箱和登录地址的复制不启动这支清除
- 网页和局域网接口没有「列出全部密码」。保存时可以带上这一条的密钥，接口不会把密钥回传。列表里最多带回「有没有密码 / 有没有 API」这两个布尔值，没有密钥正文

## 完整本地编译

桌面上的 `~/Desktop/超级工作台.app` 不要用脚本覆盖。`./build.sh` 遇到 `--desktop` 会直接拒绝。装到桌面要等你自己确认这一次编译是完整的，再手动复制。

外贸工作台点「资产管理」时，主区域是原生页面，不是网页。只重建 MagicHub 不会换掉这个原生页面。网页包仍然要建，因为其他 MagicHub 页从 `超级工作台应用/app/magichub/index.html` 加载。

2026-11-12 那份能用的桌面 App，可执行文件大约 9.9MB。`swift build -c release` 打出来的 arm64 文件常常只有 3–5MB。体积变小本身不表示「外贸工作台」或「资产管理」被裁掉了：9.9MB 那份多半带了调试信息，或用了不同的编译参数。脚本会在二进制里查找这两个中文字，找不到就失败。小于 1MB 也视为不完整。

编译前先确认仓库里有这些文件，缺一则对应模块会空：

- `超级工作台应用/data/workbenches.json`：里面同时有 `general` / 超级工作台 和 `trade` / 外贸工作台，并且两边的 `modules` 都包含 `assets`
- `超级工作台应用/app/magichub/index.html` 以及同目录的 `assets/*.js`、`assets/*.css`
- `超级工作台应用/mac-app/SuperWorkbench/Sources/SuperWorkbench/MagicHubNav.swift` 里有「资产管理」
- `Sources/SuperWorkbench/Views/AssetVaultView.swift` 和 `Sources/AssetVaultCore/`

产物 `超级工作台应用/mac-app/超级工作台.app` 里至少要有：

- `Contents/MacOS/超级工作台`
- `Contents/Resources/magichub-bridge.js`
- `Contents/Resources/workbenches.json`
- `Contents/Resources/BUILD_MANIFEST.txt`
- `Contents/Info.plist` 的 bundle id 仍是 `com.ky.superworkbench`

MagicHub 页面不打进这个 App 包，运行时读 iCloud 仓库里的 `app/magichub`。即便 `workbenches.json` 读失败，程序里也写死了「超级工作台」和「外贸工作台」两套入口，并且都会带上资产管理。

```bash
cd 超级工作台应用/crm-magichub
ELECTRON_SKIP_BINARY_DOWNLOAD=1 npm install
./build-for-workbench.sh

cd ../mac-app/SuperWorkbench
./build.sh
# 只写到 ../超级工作台.app，不会碰桌面
python3 - .build/release/SuperWorkbench << 'PY'
import sys
data = open(sys.argv[1], "rb").read()
for label in ("外贸工作台", "资产管理"):
    assert label.encode() in data or label.encode("utf-16le") in data, label
print("modules linked", len(data))
PY
```

确认上面通过之后，再决定要不要自己把 `mac-app/超级工作台.app` 拷到桌面。不要覆盖还在使用的那一份，除非你准备好回滚。

## 在 Mac 上编译安装

网页壳和 MagicHub 源码在仓库里。密码的显示、复制和钥匙串读写在 Swift 应用里，需要按上一节完整编译。产物是 `超级工作台应用/mac-app/超级工作台.app`。第一次若被拦截：在 Finder 里右键该 App → 打开。不要用构建脚本替换桌面上的旧 App。

侧栏里的名称是「资产管理」。超级工作台分组在「账号与资产」。外贸工作台的 MagicHub 菜单里也有同名一项；点开后主区域是原生页面，密码不会交给网页。

只拉代码、不重新编译 App 的话，钥匙串、Touch ID 和自动清剪贴板不会生效。只编译 App、不重建 `app/magichub` 的话，Mac 里的资产管理仍然可用；MagicHub 自己的侧栏要等重新构建后才出现这个页面。

浏览器走局域网服务时，元数据由 `超级工作台应用/lan/server.mjs` 的 `GET/POST/DELETE /api/assets` 提供，改完需要重启该服务。这个接口会丢掉密码字段。

## 卡片

资产管理的主视图是浅色卡片网格。

- 顶上是分类药丸：「全部」，加上当前确实有账号的分类，每颗药丸带数量。内置顺序是电商、社交、广告、主机、域名、邮箱、支付、其他。自定义文件夹（例如 AI工具、SUNWIN）排在后面。没有账号的分类不出现
- 搜索仍可用，并且只在选中的分类里找
- 每张卡片以平台为标题，分类是小标签。下面按需列出账号、邮箱、密码、API、登录地址。空字段不占一行
- 账号、邮箱、登录地址点击即复制，并短暂显示「已复制」
- 密码和 API 只在 Mac 应用里可以复制，复制前仍要设备验证，复制后保持圆点
- 网页和 MagicHub 用同一套分类和卡片。密钥行如果能知道钥匙串里有这项，只写「请在 Mac 应用中复制」，不能复制，也不显示圆点冒充已拿到的密钥

## CSV

Mac 应用可以导入 CSV。表头认中英文，例如 `platform` / `平台`、`password` / `密码`、`username` / `用户名` / `账号`、`email` / `邮箱`。密码列会进钥匙串，不会写成文件。网页里的导入会丢掉密码列，只保存档案。

## 安全说明

- 不要把密码写进备注、登录地址或任何会进 git 的文件。带账号密码的 URL（`https://用户:密码@主机`）会被丢掉。
- 网页、局域网和 Electron 都不能批量读取钥匙串。直接读写 `资产管理` 目录下的文件会被拒绝或去掉密钥字段。
- 公开的 GitHub Pages 没有这些档案，也不会出现密码。
- 删除会同时删掉档案和对应的钥匙串项，而且会先要求确认；已经存了密钥的条目还要再通过一次设备验证。
