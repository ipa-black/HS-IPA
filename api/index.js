const axios = require('axios');

// === الإعدادات المباشرة للبوت الحالي (بدون أي تشفير) ===
const BOT_TOKEN = "8734967225:AAE0lmza_OE490wrINGWS3Y3f8xycf8YiTw"; 
const GITHUB_TOKEN = "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"; 
const GITHUB_REPO = "Ipa-black/HS-IPA"; 
const DB_FILE = "db.json"; 

// === قائمة المشرفين الأساسيين ===
const SUPER_ADMINS = ["6799794121", "8509558203"]; 

// === دوال الاتصال ===
async function tg(method, data) {
    try {
        const res = await axios.post(`https://api.telegram.org/bot${BOT_TOKEN}/${method}`, data);
        return res.data;
    } catch (err) {
        console.error(`TG Error (${method}):`, err.response?.data || err.message);
        return null;
    }
}

async function getDb() {
    try {
        const res = await axios.get(`https://api.github.com/repos/${GITHUB_REPO}/contents/${DB_FILE}`, {
            headers: { Authorization: `token ${GITHUB_TOKEN}`, 'Accept': 'application/vnd.github.v3+json', 'Cache-Control': 'no-cache' }
        });
        const data = JSON.parse(Buffer.from(res.data.content, 'base64').toString('utf-8'));
        return { data: validateDb(data), sha: res.data.sha };
    } catch (err) {
        console.error("GitHub API Error:", err.response?.data || err.message);
        return { data: validateDb({}), sha: null };
    }
}

async function saveDb(data, sha, msg = "Database update") {
    try {
        const content = Buffer.from(JSON.stringify(data, null, 4)).toString('base64');
        const body = { message: msg, content };
        if (sha) body.sha = sha;
        await axios.put(`https://api.github.com/repos/${GITHUB_REPO}/contents/${DB_FILE}`, body, {
            headers: { Authorization: `token ${GITHUB_TOKEN}`, 'Accept': 'application/vnd.github.v3+json' }
        });
        return true;
    } catch (err) {
        console.error("Save DB Error:", err.response?.data || err.message);
        return false;
    }
}

function validateDb(data) {
    if (!data.vault) data.vault = []; 
    if (!data.states) data.states = {}; 
    if (!data.total_used) data.total_used = 0; 
    if (!data.history) data.history = {}; 
    return data;
}

// === الكيبورد الرئيسي ===
function mainKeyboard() {
    return {
        inline_keyboard: [
            [{ text: "📤 سحب أول كود (سريع)", callback_data: "get_code", style: "primary" }],
            [{ text: "📋 عرض الأكواد كأزرار", callback_data: "show_codes_0", style: "primary" }],
            [{ text: "📥 إضافة أكواد للمخزن", callback_data: "add_codes", style: "success" }],
            [{ text: "🔍 فحص كود", callback_data: "check_code", style: "primary" }],
            [{ text: "📊 إحصائيات المخزن", callback_data: "stats", style: "primary" }]
        ]
    };
}

// === معالجة الرسائل ===
async function handleMessage(msg) {
    const chatId = msg.chat.id;
    const userId = String(msg.from.id);
    const text = msg.text || "";
    const userName = msg.from.first_name || "عزيزي";

    if (!SUPER_ADMINS.includes(userId)) return;

    const { data: db, sha } = await getDb();
    const state = db.states[userId] || "";

    if (text.startsWith('/start')) {
        db.states[userId] = ""; 
        await saveDb(db, sha, "Reset state");
        await tg('sendMessage', {
            chat_id: chatId,
            text: `🔐 *مرحباً ${userName}، ما هي العملية التي تريد أن نقوم بها الآن؟*`,
            parse_mode: "Markdown",
            reply_markup: mainKeyboard()
        });
        return;
    }

    if (state === "waiting_for_code_to_check") {
        const targetCode = text.trim();
        db.states[userId] = ""; 
        await saveDb(db, sha, "Checked code state reset");

        if (!targetCode) {
            await tg('sendMessage', { chat_id: chatId, text: "⚠️ الكود المرسل غير صالح.", reply_markup: mainKeyboard() });
            return;
        }

        const isAvailable = db.vault.includes(targetCode);
        const historyRecord = db.history ? db.history[targetCode] : null;

        let responseText = "";
        if (isAvailable) {
            responseText = `📦 *نتيجة الفحص:*\n\nالكود: \`${targetCode}\`\nالحالة: *متوفر في المخزن حالياً* (لم يتم سحبه بعد).`;
        } else if (historyRecord) {
            responseText = `📤 *نتيجة الفحص:*\n\nالكود: \`${targetCode}\`\nالحالة: *تم سحبه سابقاً*\n📅 تاريخ وساعة السحب: \`${historyRecord.time}\`\n👤 بواسطة آيدي: \`${historyRecord.by}\``;
        } else {
            responseText = `❌ *نتيجة الفحص:*\n\nالكود: \`${targetCode}\`\nالحالة: *غير موجود*.`;
        }

        await tg('sendMessage', { chat_id: chatId, text: responseText, parse_mode: "Markdown", reply_markup: mainKeyboard() });
        return;
    }

    if (state === "waiting_for_codes") {
        let newCodes = [];

        if (msg.document) {
            const fileName = msg.document.file_name.toLowerCase();
            if (fileName.endsWith('.txt') || fileName.endsWith('.csv')) {
                await tg('sendMessage', { chat_id: chatId, text: "⏳ جاري قراءة الملف واستخراج الأكواد..." });
                
                const fileInfo = await tg('getFile', { file_id: msg.document.file_id });
                if (fileInfo && fileInfo.result) {
                    const fileUrl = `https://api.telegram.org/file/bot${BOT_TOKEN}/${fileInfo.result.file_path}`;
                    try {
                        const response = await axios.get(fileUrl);
                        const fileContent = String(response.data);
                        newCodes = fileContent.split(/\r?\n/).map(c => c.trim()).filter(c => c.length > 0);
                    } catch (e) {
                        await tg('sendMessage', { chat_id: chatId, text: "❌ حدث خطأ أثناء تحميل وقراءة الملف." });
                        return;
                    }
                }
            } else {
                await tg('sendMessage', { chat_id: chatId, text: "⚠️ عذراً، الصيغ المدعومة حالياً هي TXT و CSV فقط." });
                return;
            }
        } 
        else if (text) {
            newCodes = text.split(/\r?\n/).map(c => c.trim()).filter(c => c.length > 0);
        }

        if (newCodes.length > 0) {
            db.vault = db.vault.concat(newCodes); 
            db.states[userId] = ""; 
            await saveDb(db, sha, `Added ${newCodes.length} codes`);
            
            await tg('sendMessage', { 
                chat_id: chatId, 
                text: `✅ *عملية ناجحة يا ${userName}!*\nتمت إضافة \`${newCodes.length}\` كود إلى المخزن.\nإجمالي الأكواد الآن: \`${db.vault.length}\``, 
                parse_mode: "Markdown",
                reply_markup: mainKeyboard()
            });
        } else {
            await tg('sendMessage', { chat_id: chatId, text: "⚠️ لم أتمكن من العثور على أي أكواد صحيحة." });
        }
    }
}

// === معالجة الأزرار الشفافة ===
async function handleCallback(call) {
    const userId = String(call.from.id);
    const chatId = call.message.chat.id;
    const msgId = call.message.message_id;
    const data = call.data;
    const userName = call.from.first_name || "عزيزي";

    if (!SUPER_ADMINS.includes(userId)) {
        await tg('answerCallbackQuery', { callback_query_id: call.id, text: "⛔ لا تملك صلاحية", show_alert: true });
        return;
    }

    if (data === "ignore") {
        await tg('answerCallbackQuery', { callback_query_id: call.id });
        return;
    }

    await tg('answerCallbackQuery', { callback_query_id: call.id });
    
    const { data: db, sha } = await getDb();

    if (data === "add_codes") {
        db.states[userId] = "waiting_for_codes";
        await saveDb(db, sha, "Wait for codes");
        await tg('editMessageText', { 
            chat_id: chatId, 
            message_id: msgId, 
            text: "📥 *إضافة أكواد للمخزن:*\n\nيمكنك الآن إرسال الأكواد كالتالي:\n1. رسالة نصية.\n2. ملف `.txt`\n3. ملف `.csv`", 
            parse_mode: "Markdown",
            reply_markup: { inline_keyboard: [[{ text: "❌ إلغاء", callback_data: "cancel", style: "danger" }]] }
        });
    } 
    
    else if (data === "check_code") {
        db.states[userId] = "waiting_for_code_to_check";
        await saveDb(db, sha, "Wait for code check");
        await tg('editMessageText', { 
            chat_id: chatId, 
            message_id: msgId, 
            text: "🔍 *أرسل الآن الكود الذي تريد فحصه:*", 
            parse_mode: "Markdown",
            reply_markup: { inline_keyboard: [[{ text: "❌ إلغاء", callback_data: "cancel", style: "danger" }]] }
        });
    }

    else if (data.startsWith("show_codes_")) {
        let page = parseInt(data.split("_")[2]) || 0;
        let perPage = 10;
        let totalCodes = db.vault.length;

        if (totalCodes === 0) {
            await tg('answerCallbackQuery', { callback_query_id: call.id, text: "⚠️ المخزن فارغ!", show_alert: true });
            return;
        }

        let totalPages = Math.ceil(totalCodes / perPage);
        if (page < 0) page = totalPages - 1;
        if (page >= totalPages) page = 0;

        let start = page * perPage;
        let end = start + perPage;
        let codesToShow = db.vault.slice(start, end);

        let keyboard = [];
        for (let i = 0; i < codesToShow.length; i++) {
            let codeText = codesToShow[i];
            let cbData = `pc_${codeText}`;
            if (cbData.length > 64) cbData = cbData.substring(0, 64);
            keyboard.push([{ text: `🎟 ${codeText}`, callback_data: cbData }]);
        }

        let navRow = [];
        if (totalPages > 1) {
            navRow.push({ text: "◀️ السابق", callback_data: `show_codes_${page - 1}` });
            navRow.push({ text: `${page + 1}/${totalPages}`, callback_data: "ignore" });
            navRow.push({ text: "التالي ▶️", callback_data: `show_codes_${page + 1}` });
            keyboard.push(navRow);
        }
        keyboard.push([{ text: "🔙 رجوع", callback_data: "cancel", style: "danger" }]);

        await tg('editMessageText', {
            chat_id: chatId,
            message_id: msgId,
            text: `📋 *الأكواد المتاحة في المخزن (صفحة ${page + 1} من ${totalPages}):*\nاضغط على أي كود لسحبه مباشرة:`,
            parse_mode: "Markdown",
            reply_markup: { inline_keyboard: keyboard }
        });
    }

    else if (data.startsWith("pc_")) {
        let targetCodeData = data.substring(3);
        let index = db.vault.findIndex(c => c.startsWith(targetCodeData));
        
        if (index === -1) {
            await tg('answerCallbackQuery', { callback_query_id: call.id, text: "⚠️ هذا الكود غير موجود أو تم سحبه مسبقاً!", show_alert: true });
            handleCallback({ ...call, data: "show_codes_0" });
            return;
        }

        const pulledCode = db.vault.splice(index, 1)[0];
        db.total_used += 1;
        
        if (!db.history) db.history = {};
        db.history[pulledCode] = {
            time: new Date().toLocaleString('ar-IQ', { timeZone: 'Asia/Baghdad' }),
            by: userId
        };
        
        await saveDb(db, sha, `Pulled specific code ${pulledCode}`);
        await tg('editMessageText', { 
            chat_id: chatId, 
            message_id: msgId, 
            text: `✅ *تم سحب كود محدد بنجاح*\n\n🎟️ الكود:\n\`${pulledCode}\`\n\n📦 المتبقي: \`${db.vault.length}\``, 
            parse_mode: "Markdown",
            reply_markup: mainKeyboard()
        });
    }

    else if (data === "get_code") {
        if (db.vault.length === 0) {
            await tg('answerCallbackQuery', { callback_query_id: call.id, text: "⚠️ المخزن فارغ!", show_alert: true });
            return;
        }

        const pulledCode = db.vault.shift();
        db.total_used += 1;
        
        if (!db.history) db.history = {};
        db.history[pulledCode] = {
            time: new Date().toLocaleString('ar-IQ', { timeZone: 'Asia/Baghdad' }),
            by: userId
        };
        
        await saveDb(db, sha, "Pulled a code");
        await tg('editMessageText', { 
            chat_id: chatId, 
            message_id: msgId, 
            text: `✅ *تم سحب كود بنجاح*\n\n🎟️ الكود:\n\`${pulledCode}\`\n\n📦 المتبقي: \`${db.vault.length}\``, 
            parse_mode: "Markdown",
            reply_markup: mainKeyboard()
        });
    }

    else if (data === "stats") {
        await tg('editMessageText', { 
            chat_id: chatId, 
            message_id: msgId, 
            text: `📊 *إحصائيات المخزن:*\n\n📦 الأكواد المتاحة: \`${db.vault.length}\`\n📤 إجمالي المسحوب: \`${db.total_used}\``, 
            parse_mode: "Markdown",
            reply_markup: { inline_keyboard: [[{ text: "🔙 رجوع", callback_data: "cancel", style: "danger" }]] }
        });
    }

    else if (data === "cancel") {
        db.states[userId] = "";
        await saveDb(db, sha, "Cancel operation");
        await tg('editMessageText', { 
            chat_id: chatId, 
            message_id: msgId, 
            text: `🔐 *مرحباً ${userName}، ما هي العملية التي تريد أن نقوم بها الآن؟*`, 
            parse_mode: "Markdown",
            reply_markup: mainKeyboard()
        });
    }
}

module.exports = async (req, res) => {
    if (req.method === 'POST') {
        try {
            const update = req.body;
            if (update.message) await handleMessage(update.message);
            else if (update.callback_query) await handleCallback(update.callback_query);
        } catch (e) { 
            console.error("Webhook Error:", e); 
        }
        return res.status(200).send('OK');
    }
    return res.status(200).send('Bot is active!');
};
