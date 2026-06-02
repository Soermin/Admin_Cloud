import os
import time
from contextlib import asynccontextmanager
from urllib.parse import quote

import boto3
from botocore.config import Config
from botocore.exceptions import ClientError
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.responses import StreamingResponse

AWS_REGION = os.getenv("AWS_REGION", "ap-southeast-1")
S3_BUCKET = os.getenv("S3_BUCKET")

S3_INIT_RETRIES = int(os.getenv("S3_INIT_RETRIES", "30"))
S3_INIT_DELAY_SECONDS = float(os.getenv("S3_INIT_DELAY_SECONDS", "2"))

if not S3_BUCKET:
    raise RuntimeError("S3_BUCKET environment variable is required")

# AWS S3 client.
# Credential tidak ditulis manual.
# Di EKS, boto3 akan mengambil temporary credentials dari IRSA.
s3_client = boto3.client(
    "s3",
    region_name=AWS_REGION,
    config=Config(signature_version="s3v4"),
)


def ensure_bucket():
    """
    Memastikan bucket S3 bisa diakses.

    Bucket tidak dibuat otomatis oleh aplikasi.
    Bucket harus dibuat oleh AWS CLI / Terraform / CDK supaya:
    - versioning bisa dikontrol,
    - public access block bisa dikontrol,
    - tagging bisa dikontrol,
    - lifecycle policy bisa dikontrol.
    """

    last_error = None

    for attempt in range(1, S3_INIT_RETRIES + 1):
        try:
            s3_client.head_bucket(Bucket=S3_BUCKET)
            return

        except ClientError as exc:
            last_error = exc
            code = exc.response.get("Error", {}).get("Code")

            if code in ("404", "NoSuchBucket", "NotFound"):
                raise RuntimeError(
                    f"S3 bucket '{S3_BUCKET}' does not exist or is not accessible"
                )

        except Exception as exc:
            last_error = exc

        if attempt < S3_INIT_RETRIES:
            time.sleep(S3_INIT_DELAY_SECONDS)

    raise last_error


@asynccontextmanager
async def lifespan(app: FastAPI):
    ensure_bucket()
    yield


app = FastAPI(title="Storage Service")


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
    return {
        "status": "ok",
        "storage": "aws-s3",
        "bucket": S3_BUCKET,
        "region": AWS_REGION,
    }
