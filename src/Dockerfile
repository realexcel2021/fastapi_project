FROM python:3.12.3-slim

WORKDIR /app

COPY . /app/

RUN pip install -r requirements.txt  --no-cache-dir 

EXPOSE 8000

CMD [ "uvicorn", "main:app", "--reload", "--host", "0.0.0.0" ]