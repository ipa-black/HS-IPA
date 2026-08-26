import os
import uuid
import base64
import requests
import zipfile
import io
import shutil
import subprocess
from fastapi import FastAPI, Form, UploadFile, File
from fastapi.responses import HTMLResponse, JSONResponse, Response, FileResponse

# إعدادات الاتصال بـ GitHub من متغيرات البيئة في Render
GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN")
GITHUB_OWNER = os.environ.get("GITHUB_OWNER") 
GITHUB_REPO = os.environ.get("GITHUB_REPO")
WORKFLOW_FILENAME = "ios_compiler.yml"

app = FastAPI(title="Ultimate iOS Toolchain")

# ---------------- الواجهة الأمامية (HTML/CSS/JS) ----------------
HTML_UI = """
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <title>Ultimate iOS Toolchain</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; background: #0d1117; color: #c9d1d9; margin: 0; padding: 20px; }
        .container { max-width: 900px; margin: auto; background: #161b22; padding: 30px; border-radius: 12px; box-shadow: 0 8px 24px rgba(0,0,0,0.8); border: 1px solid #30363d; }
        h1 { color: #58a6ff; text-align: center; font-size: 2.5em; margin-bottom: 30px; text-shadow: 0 0 10px rgba(88,166,255,0.3); }
        .tabs { display: flex; justify-content: center; margin-bottom: 20px; border-bottom: 2px solid #30363d; }
        .tab { padding: 15px 30px; cursor: pointer; font-size: 18px; font-weight: bold; color: #8b949e; transition: 0.3s; }
        .tab:hover { color: #c9d1d9; }
        .tab.active { color: #58a6ff; border-bottom: 3px solid #58a6ff; }
        .section { display: none; }
        .section.active { display: block; }
        textarea { width: 100%; height: 280px; background: #010409; color: #79c0ff; font-family: 'Courier New', monospace; font-size: 15px; padding: 15px; border: 1px solid #30363d; border-radius: 8px; direction: ltr; box-sizing: border-box; }
        input[type="text"] { width: 100%; padding: 12px; background: #010409; color: #79c0ff; border: 1px solid #30363d; border-radius: 8px; direction: ltr; box-sizing: border-box; margin-top: 5px; }
        button { width: 100%; padding: 15px; background: #238636; color: #ffffff; font-weight: bold; font-size: 18px; border: none; border-radius: 8px; cursor: pointer; margin-top: 15px; transition: 0.3s; }
        button:hover { background: #2ea043; }
        button:disabled { background: #21262d; color: #8b949e; cursor: not-allowed; }
        .file-upload { border: 2px dashed #30363d; padding: 40px; text-align: center; border-radius: 8px; margin-top: 20px; background: #010409; }
        input[type="file"] { display: none; }
        .file-label { cursor: pointer; color: #58a6ff; font-size: 18px; font-weight: bold; }
        .status { margin-top: 20px; padding: 15px; border-radius: 8px; text-align: center; font-weight: bold; display: none; }
        .download-btn { display: inline-block; background: #1f6feb; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; margin-top: 10px; }
        .download-btn:hover { background: #388bfd; }
    </style>
</head>
<body>
    <div class="container">
        <h1>⚙️ Ultimate iOS Toolchain</h1>
        
        <div class="tabs">
            <div class="tab active" onclick="switchTab('compiler')">📝 المترجم السحابي (Compile)</div>
            <div class="tab" onclick="switchTab('decompiler')">🔍 الهندسة العكسية (Decompile)</div>
        </div>

        <!-- قسم المترجم -->
        <div id="compiler" class="section active">
            <p>اكتب كود Objective-C وسيتم ترجمته سحابياً عبر أجهزة Mac:</p>
            <textarea id="code" spellcheck="false">
#import <Foundation/Foundation.h>
#import <substrate.h>

__attribute__((constructor))
static void custom_init() {
    NSLog(@"[+] Ultimate Dylib with Smart Cache Injected!");
}
            </textarea>
            
            <p style="margin-top: 15px; color: #8b949e; font-size: 14px;">📦 إضافة مكتبات خارجية (اختياري - سيتم حفظها في الكاش):</p>
            <input type="text" id="extraLibs" placeholder="رابط مباشر لملف .zip يحتوي على الهيدرز والمكتبات (مثل روابط Github Raw)">
            
            <button id="compileBtn" onclick="startCompile()">🚀 بدء الترجمة</button>
            <div id="compile-status" class="status"></div>
        </div>

        <!-- قسم الهندسة العكسية -->
        <div id="decompiler" class="section">
            <p>ارفع ملف dylib لاستخراج كود التجميع (Assembly)، النصوص، والرموز باستخدام Radare2:</p>
            <div class="file-upload">
                <label class="file-label">
                    📁 اضغط هنا لاختيار ملف dylib
                    <input type="file" id="dylibFile" accept=".dylib">
                </label>
                <p id="fileName" style="color: #79c0ff; margin-top: 10px;"></p>
            </div>
            <button id="decompileBtn" onclick="startDecompile()">🛠️ بدء التفكيك الشامل</button>
            <div id="decompile-status" class="status"></div>
        </div>
    </div>

    <script>
        function switchTab(tabId) {
            document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
            document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
            event.target.classList.add('active');
            document.getElementById(tabId).classList.add('active');
        }

        document.getElementById('dylibFile').addEventListener('change', function(e) {
            document.getElementById('fileName').innerText = e.target.files[0].name;
        });

        // دوال المترجم
        async function startCompile() {
            const btn = document.getElementById('compileBtn');
            const status = document.getElementById('compile-status');
            const code = document.getElementById('code').value;
            const extraLibs = document.getElementById('extraLibs').value;
            
            btn.disabled = true;
            status.style.display = 'block';
            status.style.background = '#1f6feb';
            status.innerHTML = '⏳ جاري إرسال الطلب لخوادم أبل...';

            let formData = new FormData();
            formData.append("objc_code", code);
            formData.append("extra_libs_url", extraLibs);
            
            let res = await fetch('/api/compile/start', { method: 'POST', body: formData });
            let result = await res.json();

            if(result.error) {
                status.style.background = '#da3633';
                status.innerHTML = '❌ ' + result.error;
                btn.disabled = false;
                return;
            }

            status.innerHTML = '⚙️ جاري بناء الملف على macOS... (يستغرق ~30 ثانية)';
            
            let interval = setInterval(async () => {
                let checkRes = await fetch('/api/compile/status/' + result.session_id);
                let checkData = await checkRes.json();

                if(checkData.status === 'ready') {
                    clearInterval(interval);
                    status.style.background = '#238636';
                    status.innerHTML = `✅ اكتملت الترجمة بنجاح!<br><a href="/api/compile/download/${result.session_id}" class="download-btn">📥 تحميل Dylib</a>`;
                    btn.disabled = false;
                }
            }, 5000);
        }

        // دوال الهندسة العكسية
        async function startDecompile() {
            const btn = document.getElementById('decompileBtn');
            const status = document.getElementById('decompile-status');
            const fileInput = document.getElementById('dylibFile');
            
            if(!fileInput.files[0]) {
                alert('الرجاء اختيار ملف أولاً');
                return;
            }

            btn.disabled = true;
            status.style.display = 'block';
            status.style.background = '#1f6feb';
            status.innerHTML = '🔍 يتم الآن تشريح الملف عبر Radare2... الرجاء الانتظار';

            let formData = new FormData();
            formData.append("file", fileInput.files[0]);

            let res = await fetch('/api/decompile', { method: 'POST', body: formData });

            if(res.ok) {
                const blob = await res.blob();
                const url = window.URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                a.download = fileInput.files[0].name + "_Decoded.zip";
                document.body.appendChild(a);
                a.click();
                a.remove();
                
                status.style.background = '#238636';
                status.innerHTML = '✅ تم فك التشفير وتحميل النتيجة بنجاح!';
            } else {
                status.style.background = '#da3633';
                status.innerHTML = '❌ حدث خطأ أثناء فك التشفير.';
            }
            btn.disabled = false;
        }
    </script>
</body>
</html>
"""

@app.get("/", response_class=HTMLResponse)
async def home():
    return HTML_UI

# ---------------- API المترجم ----------------
@app.post("/api/compile/start")
async def start_compilation(objc_code: str = Form(...), extra_libs_url: str = Form("")):
    if not GITHUB_TOKEN:
        return {"error": "تحذير: لم يتم ربط GitHub Token في إعدادات السيرفر!"}

    session_id = str(uuid.uuid4().hex)[:8]
    code_b64 = base64.b64encode(objc_code.encode("utf-8")).decode("utf-8")

    url = f"https://api.github.com/repos/{GITHUB_OWNER}/{GITHUB_REPO}/actions/workflows/{WORKFLOW_FILENAME}/dispatches"
    headers = {"Authorization": f"Bearer {GITHUB_TOKEN}", "Accept": "application/vnd.github.v3+json"}
    data = {
        "ref": "main", 
        "inputs": {
            "code_b64": code_b64, 
            "session_id": session_id,
            "extra_libs_url": extra_libs_url
        }
    }

    resp = requests.post(url, headers=headers, json=data)
    if resp.status_code == 204:
        return {"session_id": session_id}
    return {"error": f"فشل الاتصال بخوادم GitHub: {resp.text}"}

@app.get("/api/compile/status/{session_id}")
async def check_status(session_id: str):
    url = f"https://api.github.com/repos/{GITHUB_OWNER}/{GITHUB_REPO}/actions/artifacts"
    headers = {"Authorization": f"Bearer {GITHUB_TOKEN}"}
    resp = requests.get(url, headers=headers)
    if resp.status_code == 200:
        for artifact in resp.json().get("artifacts", []):
            if artifact["name"] == f"dylib-{session_id}":
                return {"status": "ready"}
    return {"status": "building"}

@app.get("/api/compile/download/{session_id}")
async def download_artifact(session_id: str):
    url = f"https://api.github.com/repos/{GITHUB_OWNER}/{GITHUB_REPO}/actions/artifacts"
    headers = {"Authorization": f"Bearer {GITHUB_TOKEN}"}
    resp = requests.get(url, headers=headers).json()
    
    artifact_id = next((a["id"] for a in resp.get("artifacts", []) if a["name"] == f"dylib-{session_id}"), None)
    if not artifact_id: return HTMLResponse("الملف غير موجود أو انتهت صلاحيته.")

    download_url = f"https://api.github.com/repos/{GITHUB_OWNER}/{GITHUB_REPO}/actions/artifacts/{artifact_id}/zip"
    zip_resp = requests.get(download_url, headers=headers, allow_redirects=True)
    
    with zipfile.ZipFile(io.BytesIO(zip_resp.content)) as z:
        dylib_filename = z.namelist()[0]
        dylib_data = z.read(dylib_filename)
        
    return Response(content=dylib_data, media_type="application/x-mach-binary", headers={"Content-Disposition": f"attachment; filename=Payload_{session_id}.dylib"})

# ---------------- API الهندسة العكسية ----------------
@app.post("/api/decompile")
async def decompile_dylib(file: UploadFile = File(...)):
    session_id = str(uuid.uuid4().hex)[:8]
    work_dir = f"/tmp/re_{session_id}"
    os.makedirs(work_dir, exist_ok=True)
    
    file_path = os.path.join(work_dir, file.filename)
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    out_dir = os.path.join(work_dir, "Decoded_Data")
    os.makedirs(out_dir, exist_ok=True)

    try:
        subprocess.run(f"rabin2 -I '{file_path}' > '{out_dir}/1_Binary_Info.txt'", shell=True, timeout=15)
        subprocess.run(f"rabin2 -i '{file_path}' > '{out_dir}/2_Imports.txt'", shell=True, timeout=15)
        subprocess.run(f"rabin2 -s '{file_path}' > '{out_dir}/3_Symbols.txt'", shell=True, timeout=15)
        subprocess.run(f"rabin2 -zz '{file_path}' > '{out_dir}/4_Deep_Strings.txt'", shell=True, timeout=15)
        subprocess.run(f"r2 -A -q -c 'pdf @@ f' '{file_path}' > '{out_dir}/5_Full_Assembly_Logic.asm'", shell=True, timeout=90)
    except subprocess.TimeoutExpired:
        pass 
        
    zip_path = os.path.join(work_dir, f"{file.filename}_Results")
    shutil.make_archive(zip_path, 'zip', out_dir)
    
    return FileResponse(f"{zip_path}.zip", media_type="application/zip", filename=f"{file.filename}_Ultimate_Decoded.zip")
