# استخدام نسخة أحدث ومستقرة (Bookworm) لضمان وجود مكتبة radare2
FROM python:3.11-slim-bookworm

# تحديث النظام وتثبيت أدوات الهندسة العكسية
RUN apt-get update && apt-get install -y \
    radare2 \
    binutils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# نسخ وتثبيت متطلبات بايثون
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# نسخ كود السيرفر
COPY main.py .

# تشغيل السيرفر
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "10000"]
