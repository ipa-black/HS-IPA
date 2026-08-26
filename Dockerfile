# استخدام نظام أوبونتو 22.04 الكامل كبيئة أساسية
FROM ubuntu:22.04

# منع النظام من طلب أي تدخل يدوي أثناء التثبيت
ENV DEBIAN_FRONTEND=noninteractive

# تحديث النظام وتثبيت بايثون وأدوات الهندسة العكسية
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    radare2 \
    binutils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# نسخ وتثبيت متطلبات بايثون
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# نسخ كود السيرفر
COPY main.py .

# تشغيل السيرفر باستخدام أوامر أوبونتو
CMD ["python3", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "10000"]
