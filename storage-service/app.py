import os
import time
from contextlib import asynccontextmanager
from urllib.parse import quote

import boto3
from botocore.config import Config
from botocore.exceptions import ClientError
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.responses import StreamingResponse

S3_ENDPOINT = os.getenv("S3_ENDPOINT", "http://minio.storage-svc.svc.cluster.local:9000")
S3_ACCESS_KEY = os.getenv("S3_ACCESS_KEY", "admin")
S3_SECRET_KEY = os.getenv("S3_SECRET_KEY", "minio123")
S3_BUCKET = os.getenv("S3_BUCKET", "reports")
S3_INIT_RETRIES = int(os.getenv("S3_INIT_RETRIES", "30"))
S3_INIT_DELAY_SECONDS = float(os.getenv("S3_INIT_DELAY_SECONDS", "2"))

s3_client = boto3.client(
    "s3",
    endpoint_url=S3_ENDPOINT,
    aws_access_key_id=S3_ACCESS_KEY,
    aws_secret_access_key=S3_SECRET_KEY,
    config=Config(signature_version="s3v4", s3={"addressing_style": "path"}),
    use_ssl=False,
    verify=False,
)


def ensure_bucket():
    last_error = None
    for attempt in range(1, S3_INIT_RETRIES + 1):
        try:
            s3_client.head_bucket(Bucket=S3_BUCKET)
            return
        except ClientError as exc:
            code = exc.response.get("Error", {}).get("Code")
            if code in ("404", "NoSuchBucket", "NotFound"):
                s3_client.create_bucket(Bucket=S3_BUCKET)
                return
            last_error = exc
        except Exception as exc:
            last_error = exc

        if attempt < S3_INIT_RETRIES:
            time.sleep(S3_INIT_DELAY_SECONDS)

    raise last_error


@asynccontextmanager
async def lifespan(app: FastAPI):
    ensure_bucket()
    yield


app = FastAPI(title="Storage Service", lifespan=lifespan)


@app.post("/upload")
async def upload_file(file: UploadFile = File(...)):
    try:
        s3_client.upload_fileobj(file.file, S3_BUCKET, file.filename)
        return {"message": f"File {file.filename} uploaded"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/files")
async def list_files():
    try:
        resp = s3_client.list_objects_v2(Bucket=S3_BUCKET)
        return [obj["Key"] for obj in resp.get("Contents", [])]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/files/{filename}")
async def download_file(filename: str):
    try:
        obj = s3_client.get_object(Bucket=S3_BUCKET, Key=filename)
        return StreamingResponse(
            obj["Body"].iter_chunks(),
            media_type=obj.get("ContentType", "application/octet-stream"),
            headers={
                "Content-Disposition": f"attachment; filename*=UTF-8''{quote(filename)}"
            },
        )
    except ClientError as e:
        code = e.response.get("Error", {}).get("Code")
        if code in ("NoSuchKey", "404", "NotFound"):
            raise HTTPException(status_code=404, detail="File not found")
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.delete("/files/{filename}")
async def delete_file(filename: str):
    try:
        s3_client.delete_object(Bucket=S3_BUCKET, Key=filename)
        return {"message": f"File {filename} deleted"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/health")
async def health():
    return {"status": "ok"}
