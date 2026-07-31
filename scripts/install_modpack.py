#!/usr/bin/env python3
"""落幕曲 1.6.5 整合包安装器 — CurseForge 格式
安装流程：MC 1.20.1 → Forge 47.3.22 → 265 mods → overrides
"""
import json, os, sys, zipfile, urllib.request, urllib.error, time, ssl, shutil

# 绕过代理
for k in list(os.environ):
    if 'proxy' in k.lower():
        del os.environ[k]

CF_API = "https://api.curseforge.com/v1"
CF_KEY = "$2a$10$wuAJuNZuted3NORVmpgUC.m8sI.pv1tOPKZyBgLFGjxFp/br0lZCC"
MOJANG_META = "https://piston-meta.mojang.com"
MOJANG_DATA = "https://piston-data.mojang.com"
FORGE_MAVEN = "https://maven.minecraftforge.net"

GAME_ROOT = os.path.expanduser("~/Library/Application Support/macraft")
MC_VERSION = "1.20.1"
FORGE_VERSION = "47.3.22"
INSTANCE_NAME = "落幕曲1.6.5"
INSTANCE_DIR = os.path.join(GAME_ROOT, "instances", INSTANCE_NAME)

ctx = ssl.create_default_context()

def download(url, dest=None, retries=3):
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Macraft/1.0"})
            with urllib.request.urlopen(req, timeout=60, context=ctx) as resp:
                data = resp.read()
                if dest:
                    os.makedirs(os.path.dirname(dest), exist_ok=True)
                    with open(dest, 'wb') as f:
                        f.write(data)
                return data
        except Exception as e:
            if attempt < retries - 1:
                time.sleep(1)
            else:
                raise e

def cf_get(endpoint):
    req = urllib.request.Request(f"{CF_API}{endpoint}", headers={
        "x-api-key": CF_KEY, "Accept": "application/json"
    })
    with urllib.request.urlopen(req, timeout=30, context=ctx) as resp:
        return json.loads(resp.read())

def install_vanilla():
    print(f"\n{'='*50}")
    print(f"[1/4] 安装 Minecraft {MC_VERSION} 原版")
    print(f"{'='*50}")
    ver_dir = os.path.join(GAME_ROOT, "versions", MC_VERSION)
    json_path = os.path.join(ver_dir, f"{MC_VERSION}.json")
    jar_path = os.path.join(ver_dir, f"{MC_VERSION}.jar")
    manifest = json.loads(download(f"{MOJANG_META}/mc/game/version_manifest_v2.json"))
    ver_info = next(v for v in manifest["versions"] if v["id"] == MC_VERSION)
    os.makedirs(ver_dir, exist_ok=True)
    if not os.path.exists(json_path):
        print(f"  下载 {MC_VERSION}.json ...")
        download(ver_info["url"], json_path)
    with open(json_path) as f:
        vjson = json.load(f)
    if not os.path.exists(jar_path):
        client_url = vjson["downloads"]["client"]["url"]
        size_mb = vjson["downloads"]["client"]["size"] / 1024 / 1024
        print(f"  下载 client.jar ({size_mb:.1f} MB) ...")
        download(client_url, jar_path)
    lib_root = os.path.join(GAME_ROOT, "libraries")
    done = 0
    for lib in vjson["libraries"]:
        rules = lib.get("rules")
        if rules:
            allowed = False
            for r in rules:
                if r["action"] == "allow":
                    if "os" in r:
                        if r["os"].get("name") == "osx": allowed = True
                    else: allowed = True
                elif r["action"] == "disallow":
                    if "os" in r:
                        if r["os"].get("name") == "osx": allowed = False
                    else: allowed = False
            if not allowed: continue
        dl = lib.get("downloads", {})
        art = dl.get("artifact", {})
        if art.get("path") and art.get("url"):
            dest = os.path.join(lib_root, art["path"])
            if not os.path.exists(dest):
                download(art["url"], dest)
                done += 1
        classifiers = dl.get("classifiers", {})
        natives_map = lib.get("natives", {})
        if "osx" in natives_map:
            key = natives_map["osx"].replace("${arch}", "x86_64")
            native_art = classifiers.get(key, {})
            if native_art.get("path") and native_art.get("url"):
                dest = os.path.join(lib_root, native_art["path"])
                if not os.path.exists(dest):
                    download(native_art["url"], dest)
    print(f"  下载了 {done} 个新 library")
    natives_dir = os.path.join(ver_dir, "natives")
    os.makedirs(natives_dir, exist_ok=True)
    for lib in vjson["libraries"]:
        natives_map = lib.get("natives", {})
        if "osx" not in natives_map: continue
        dl = lib.get("downloads", {})
        classifiers = dl.get("classifiers", {})
        key = natives_map["osx"].replace("${arch}", "x86_64")
        native_art = classifiers.get(key, {})
        if native_art.get("path"):
            jar_file = os.path.join(lib_root, native_art["path"])
            if os.path.exists(jar_file):
                with zipfile.ZipFile(jar_file) as zf:
                    for name in zf.namelist():
                        if name.endswith(('.dylib', '.jnilib')) and 'META-INF' not in name:
                            target = os.path.join(natives_dir, os.path.basename(name))
                            if not os.path.exists(target):
                                with zf.open(name) as src, open(target, 'wb') as dst:
                                    dst.write(src.read())
    asset_index = vjson.get("assetIndex", {})
    if asset_index:
        idx_id = asset_index["id"]
        idx_path = os.path.join(GAME_ROOT, "assets", "indexes", f"{idx_id}.json")
        if not os.path.exists(idx_path):
            print(f"  下载 asset index ({idx_id}) ...")
            download(asset_index["url"], idx_path)
        with open(idx_path) as f:
            aidx = json.load(f)
        objects = aidx.get("objects", {})
        obj_root = os.path.join(GAME_ROOT, "assets", "objects")
        missing = sum(1 for n, i in objects.items() if not os.path.exists(os.path.join(obj_root, i["hash"][:2], i["hash"])))
        if missing > 0:
            print(f"  缺失 {missing} 个 asset，开始下载...")
            batch = 0
            for name, info in objects.items():
                h = info["hash"]
                obj_path = os.path.join(obj_root, h[:2], h)
                if not os.path.exists(obj_path):
                    try:
                        download(f"https://resources.download.minecraft.net/{h[:2]}/{h}", obj_path)
                        batch += 1
                        if batch % 200 == 0:
                            print(f"    assets: {batch}/{missing}")
                    except: pass
    print(f"  ✓ Minecraft {MC_VERSION} 安装完成")

def install_forge():
    print(f"\n{'='*50}")
    print(f"[2/4] 安装 Forge {FORGE_VERSION}")
    print(f"{'='*50}")
    forge_id = f"{MC_VERSION}-forge-{FORGE_VERSION}"
    forge_dir = os.path.join(GAME_ROOT, "versions", forge_id)
    forge_json = os.path.join(forge_dir, f"{forge_id}.json")
    if os.path.exists(forge_json):
        print(f"  已存在，跳过")
        return
    installer_url = f"{FORGE_MAVEN}/net/minecraftforge/forge/{MC_VERSION}-{FORGE_VERSION}/forge-{MC_VERSION}-{FORGE_VERSION}-installer.jar"
    installer_path = os.path.join(GAME_ROOT, "forge_installer.jar")
    print(f"  下载 Forge installer ...")
    download(installer_url, installer_path)
    os.makedirs(forge_dir, exist_ok=True)
    with zipfile.ZipFile(installer_path) as zf:
        if "version.json" in zf.namelist():
            with zf.open("version.json") as f:
                forge_vjson = json.load(f)
        else:
            print("  ERROR: version.json not found in installer")
            return
    forge_vjson["id"] = forge_id
    forge_vjson["inheritsFrom"] = MC_VERSION
    with open(forge_json, 'w') as f:
        json.dump(forge_vjson, f, indent=2)
    lib_root = os.path.join(GAME_ROOT, "libraries")
    libs = forge_vjson.get("libraries", [])
    done = 0
    for lib in libs:
        rules = lib.get("rules")
        if rules:
            allowed = False
            for r in rules:
                if r["action"] == "allow":
                    if "os" in r:
                        if r["os"].get("name") == "osx": allowed = True
                    else: allowed = True
                elif r["action"] == "disallow":
                    if "os" in r:
                        if r["os"].get("name") == "osx": allowed = False
                    else: allowed = False
            if not allowed: continue
        dl = lib.get("downloads", {})
        art = dl.get("artifact", {})
        path = art.get("path", "")
        url = art.get("url", "")
        if not path:
            parts = lib.get("name", "").split(":")
            if len(parts) >= 3:
                group = parts[0].replace(".", "/")
                artifact = parts[1]
                version = parts[2]
                classifier = f"-{parts[3]}" if len(parts) > 3 else ""
                path = f"{group}/{artifact}/{version}/{artifact}-{version}{classifier}.jar"
        if not path: continue
        dest = os.path.join(lib_root, path)
        if os.path.exists(dest): continue
        if url:
            dl_url = url + path if url.endswith("/") else url
        else:
            dl_url = f"{FORGE_MAVEN}/{path}"
        try:
            download(dl_url, dest)
            done += 1
        except Exception as e:
            print(f"    WARN: {path}: {e}")
    print(f"  下载了 {done} 个 Forge libraries")
    print(f"  ✓ Forge {FORGE_VERSION} 安装完成")
    os.remove(installer_path)

def download_mods(manifest):
    print(f"\n{'='*50}")
    print(f"[3/4] 下载 {len(manifest['files'])} 个模组")
    print(f"{'='*50}")
    mods_dir = os.path.join(INSTANCE_DIR, "mods")
    os.makedirs(mods_dir, exist_ok=True)
    files = manifest["files"]
    total = len(files)
    success = 0
    failed = []
    batch_size = 50
    for i in range(0, total, batch_size):
        batch = files[i:i+batch_size]
        file_ids = [f["fileID"] for f in batch]
        try:
            req = urllib.request.Request(
                f"{CF_API}/mods/files",
                data=json.dumps({"fileIds": file_ids}).encode(),
                headers={"x-api-key": CF_KEY, "Accept": "application/json", "Content-Type": "application/json"}
            )
            with urllib.request.urlopen(req, timeout=60, context=ctx) as resp:
                result = json.loads(resp.read())
            file_map = {fd["id"]: fd for fd in result.get("data", [])}
            for f in batch:
                fid = f["fileID"]
                pid = f["projectID"]
                fd = file_map.get(fid)
                if not fd:
                    failed.append((pid, fid, "no info"))
                    continue
                filename = fd.get("fileName", f"{fid}.jar")
                dest = os.path.join(mods_dir, filename)
                if os.path.exists(dest):
                    success += 1
                    continue
                dl_url = fd.get("downloadUrl")
                if not dl_url:
                    failed.append((pid, fid, filename))
                    continue
                try:
                    download(dl_url, dest)
                    success += 1
                except Exception as e:
                    failed.append((pid, fid, str(e)[:50]))
        except Exception as e:
            print(f"  批次 {i//batch_size+1} 失败: {e}")
            for f in batch:
                failed.append((f["projectID"], f["fileID"], "batch error"))
        current = min(i + batch_size, total)
        print(f"  进度: {current}/{total} (成功 {success}, 失败 {len(failed)})")
        time.sleep(0.3)
    if failed:
        print(f"\n  ⚠ {len(failed)} 个模组下载失败:")
        for pid, fid, reason in failed[:10]:
            print(f"    project={pid} file={fid}: {reason}")
    print(f"  ✓ 模组下载完成: {success}/{total}")
    return failed

def extract_overrides(zip_path, manifest):
    print(f"\n{'='*50}")
    print(f"[4/4] 解压 overrides（配置文件）")
    print(f"{'='*50}")
    overrides_dir = manifest.get("overrides", "overrides")
    with zipfile.ZipFile(zip_path) as zf:
        count = 0
        for name in zf.namelist():
            if name.startswith(overrides_dir + "/"):
                rel = name[len(overrides_dir) + 1:]
                if not rel: continue
                dest = os.path.join(INSTANCE_DIR, rel)
                if name.endswith("/"):
                    os.makedirs(dest, exist_ok=True)
                else:
                    os.makedirs(os.path.dirname(dest), exist_ok=True)
                    with zf.open(name) as src, open(dest, 'wb') as dst:
                        dst.write(src.read())
                    count += 1
    print(f"  ✓ 解压了 {count} 个配置文件")

def main():
    zip_path = os.path.expanduser("~/Downloads/落幕曲1.6.5安装包（拖入启动器安装）.zip")
    if not os.path.exists(zip_path):
        print(f"ERROR: 找不到: {zip_path}")
        sys.exit(1)
    print(f"整合包: {zip_path}")
    print(f"安装到: {INSTANCE_DIR}")
    with zipfile.ZipFile(zip_path) as zf:
        with zf.open("manifest.json") as f:
            manifest = json.load(f)
    print(f"名称: {manifest['name']}")
    print(f"MC: {manifest['minecraft']['version']} | Forge: {manifest['minecraft']['modLoaders'][0]['id']}")
    print(f"模组: {len(manifest['files'])} 个")
    os.makedirs(INSTANCE_DIR, exist_ok=True)
    with open(os.path.join(INSTANCE_DIR, "modpack.json"), 'w') as f:
        json.dump({"name": manifest["name"], "version": manifest["version"],
                   "mcVersion": MC_VERSION, "forge": FORGE_VERSION,
                   "modCount": len(manifest["files"])}, f, ensure_ascii=False, indent=2)
    install_vanilla()
    install_forge()
    failed = download_mods(manifest)
    extract_overrides(zip_path, manifest)
    print(f"\n{'='*50}")
    print(f"🎉 安装完成！")
    print(f"  实例: {INSTANCE_DIR}")
    print(f"  版本: {MC_VERSION}-forge-{FORGE_VERSION}")
    if failed:
        print(f"  ⚠ {len(failed)} 个模组需手动处理")
    print(f"{'='*50}")

if __name__ == "__main__":
    main()
