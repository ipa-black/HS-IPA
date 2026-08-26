# استخدام نسخة بايثون الكاملة والمبنية على نظام دبيان المستقر
FROM python:3.11-bullseye

# تحديث النظام وتثبيت radare2 مع تجاهل الأخطاء الطفيفة إن وجدت
RUN apt-get update -y --fix-missing && \
    apt-get install -y radare2 binutils && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# نسخ الملفات وتثبيت المتطلبات
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# نسخ كود التطبيق
COPY main.py .

# التشغيل
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "10000"]
