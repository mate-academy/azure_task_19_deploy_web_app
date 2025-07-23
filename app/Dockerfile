ARG PYTHON_VERSION=3.10
FROM python:${PYTHON_VERSION}-slim AS app

WORKDIR /app
ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1


COPY requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt


COPY . .


COPY entrypoint.sh /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint

EXPOSE 8000

ENTRYPOINT ["entrypoint"]
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]  
