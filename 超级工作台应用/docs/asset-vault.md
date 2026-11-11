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
  "username": "name@example.com",
  "notes": "不要在这里写密码",
  "twoFactor": "none",
  "tags": ["店铺"],
  "company": "",
  "brand": "",
  "updatedAt": "2026-11-11T00:00:00Z"
}
```

`twoFactor` 只记类型：`none`、`totp`、`sms`、`email`、`hardware`、`other`。不要把验证器密钥写进这个文件。Mac 应用里默认不保存验证器密钥，除非你自己打开「我明确要保存验证器密钥」并填写。

如果 JSON 里出现 `password`、`apiKey`、`recoveryCodes`、`totpSecret`、`token` 这类字段：Mac 应用会把它们移进钥匙串并改写文件；局域网服务会直接删掉这些字段，不会另存。两种情况下明文都不会留在文件里。

## 钥匙串

- 服务名：`com.ky.superworkbench.assets`
- 账户名：`asset:` 加上条目 id
- 只有本机已解锁、并且通过 Touch ID 或开机密码之后，Mac 应用才会把单条密码显示出来或复制出去
- 复制后大约 45 秒，如果剪贴板里还是这条密码，会自动清掉
- 网页和局域网接口没有「列出全部密码」。保存时可以带上这一条的密钥，接口不会把密钥回传

## 在 Mac 上编译安装

网页壳和 MagicHub 源码在仓库里。密码的显示、复制和钥匙串读写在 Swift 应用里，需要重新编译 App。

```bash
cd 超级工作台应用/crm-magichub
./build-for-workbench.sh

cd ../mac-app/SuperWorkbench
./build.sh
```

产物是 `超级工作台应用/mac-app/超级工作台.app`。第一次若被拦截：在 Finder 里右键该 App → 打开。不要用构建脚本替换桌面上的旧 App，确认可用之后再自己复制。

侧栏里的名称是「资产管理」。超级工作台分组在「账号与资产」。外贸工作台的 MagicHub 菜单里也有同名一项；点开后主区域是原生页面，密码不会交给网页。

只拉代码、不重新编译 App 的话，钥匙串、Touch ID 和自动清剪贴板不会生效。只编译 App、不重建 `app/magichub` 的话，Mac 里的资产管理仍然可用；MagicHub 自己的侧栏要等重新构建后才出现这个页面。

浏览器走局域网服务时，元数据由 `超级工作台应用/lan/server.mjs` 的 `GET/POST/DELETE /api/assets` 提供，改完需要重启该服务。这个接口会丢掉密码字段。

## CSV

Mac 应用可以导入 CSV。表头认中英文，例如 `platform` / `平台`、`password` / `密码`、`username` / `用户名`。密码列会进钥匙串，不会写成文件。网页里的导入会丢掉密码列，只保存档案。

## 安全说明

- 不要把密码写进备注、登录地址或任何会进 git 的文件。带账号密码的 URL（`https://用户:密码@主机`）会被丢掉。
- 网页、局域网和 Electron 都不能批量读取钥匙串。直接读写 `资产管理` 目录下的文件会被拒绝或去掉密钥字段。
- 公开的 GitHub Pages 没有这些档案，也不会出现密码。
- 删除会同时删掉档案和对应的钥匙串项，而且会先要求确认；已经存了密钥的条目还要再通过一次设备验证。
