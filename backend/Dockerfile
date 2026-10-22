FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt && useradd --uid 10001 --create-home cineus
COPY cineus_commerce ./cineus_commerce
USER 10001:10001
EXPOSE 8000
CMD ["python","-m","cineus_commerce","--config","/run/secrets/commerce.json","serve","--host","0.0.0.0"]
