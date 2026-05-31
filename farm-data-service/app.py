import os
import time
from contextlib import asynccontextmanager
from datetime import datetime, date, timedelta
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from sqlalchemy import create_engine, Column, Integer, Numeric, DateTime, Date
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy.sql import func

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:secret@postgres-postgresql.farm-db-svc.svc.cluster.local:5432/farming")
DB_INIT_RETRIES = int(os.getenv("DB_INIT_RETRIES", "30"))
DB_INIT_DELAY_SECONDS = float(os.getenv("DB_INIT_DELAY_SECONDS", "2"))

engine = create_engine(DATABASE_URL, pool_pre_ping=True)
SessionLocal = sessionmaker(bind=engine)
Base = declarative_base()

# Models
class SensorData(Base):
    __tablename__ = "sensor_data"
    id = Column(Integer, primary_key=True)
    timestamp = Column(DateTime, default=func.now())
    temperature_c = Column(Numeric(5,2))
    humidity_percent = Column(Numeric(5,2))
    light_lux = Column(Numeric(10,2))
    energy_kwh = Column(Numeric(10,2))

class CropConfig(Base):
    __tablename__ = "crop_config"
    id = Column(Integer, primary_key=True)
    planting_date = Column(Date)
    expected_harvest_days = Column(Integer)
    target_energy_kwh_per_day = Column(Numeric(10,2))


def _default_planting_date():
    planting_date = os.getenv("CROP_PLANTING_DATE")
    if planting_date:
        return datetime.strptime(planting_date, "%Y-%m-%d").date()
    days_since_planting = int(os.getenv("CROP_DAYS_SINCE_PLANTING", "0"))
    if days_since_planting > 0:
        return datetime.now().date() - timedelta(days=days_since_planting)
    return datetime.now().date()


def seed_crop_config():
    db = SessionLocal()
    try:
        if db.query(CropConfig).first():
            return
        config = CropConfig(
            planting_date=_default_planting_date(),
            expected_harvest_days=int(os.getenv("CROP_EXPECTED_HARVEST_DAYS", "90")),
            target_energy_kwh_per_day=float(os.getenv("CROP_TARGET_ENERGY_KWH_PER_DAY", "100"))
        )
        db.add(config)
        db.commit()
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


def init_database():
    last_error = None
    for attempt in range(1, DB_INIT_RETRIES + 1):
        try:
            Base.metadata.create_all(bind=engine)
            seed_crop_config()
            return
        except Exception as exc:
            last_error = exc
            if attempt == DB_INIT_RETRIES:
                break
            time.sleep(DB_INIT_DELAY_SECONDS)
    raise last_error


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_database()
    yield


app = FastAPI(title="Farm Data Service", lifespan=lifespan)

# Request/Response models
class TelemetryData(BaseModel):
    temperature_c: float
    humidity_percent: float
    light_lux: float
    energy_kwh: float

@app.post("/telemetry")
async def receive_telemetry(data: TelemetryData):
    db = SessionLocal()
    try:
        sensor = SensorData(
            temperature_c=data.temperature_c,
            humidity_percent=data.humidity_percent,
            light_lux=data.light_lux,
            energy_kwh=data.energy_kwh
        )
        db.add(sensor)
        db.commit()
        return {"status": "ok", "message": "Data saved"}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()

@app.get("/metrics/latest")
async def get_latest():
    db = SessionLocal()
    try:
        latest = db.query(SensorData).order_by(SensorData.timestamp.desc()).first()
        if not latest:
            return {}
        return {
            "temperature_c": float(latest.temperature_c),
            "humidity_percent": float(latest.humidity_percent),
            "light_lux": float(latest.light_lux),
            "energy_kwh": float(latest.energy_kwh),
            "timestamp": latest.timestamp.isoformat()
        }
    finally:
        db.close()

@app.get("/metrics/daily")
async def get_daily(date_str: str = None):
    """Grafik harian: data per 30 menit atau per jam. Parameter date: YYYY-MM-DD, default hari ini."""
    db = SessionLocal()
    try:
        if date_str:
            try:
                target_date = datetime.strptime(date_str, "%Y-%m-%d").date()
            except ValueError:
                raise HTTPException(status_code=400, detail="date_str must use YYYY-MM-DD format")
        else:
            target_date = datetime.now().date()
        
        start = datetime.combine(target_date, datetime.min.time())
        end = start + timedelta(days=1)
        # Ambil data per jam (atau per 30 menit bisa disesuaikan)
        results = db.query(SensorData).filter(
            SensorData.timestamp >= start,
            SensorData.timestamp < end
        ).order_by(SensorData.timestamp.asc()).all()
        
        data = []
        for row in results:
            data.append({
                "time": row.timestamp.isoformat(),
                "temperature": float(row.temperature_c),
                "humidity": float(row.humidity_percent),
                "light": float(row.light_lux),
                "energy": float(row.energy_kwh)
            })
        return data
    finally:
        db.close()

@app.get("/harvest-progress")
async def harvest_progress():
    db = SessionLocal()
    try:
        config = db.query(CropConfig).first()
        if not config:
            raise HTTPException(status_code=404, detail="Crop config not found")
        today = datetime.now().date()
        days_passed = (today - config.planting_date).days
        total_days = config.expected_harvest_days
        progress = min(100, max(0, int((days_passed / total_days) * 100))) if total_days > 0 else 0
        return {
            "planting_date": config.planting_date.isoformat(),
            "expected_harvest_days": total_days,
            "days_passed": days_passed,
            "progress_percent": progress,
            "status": "harvest_ready" if progress >= 100 else "growing"
        }
    finally:
        db.close()

@app.get("/energy-consumption")
async def energy_consumption():
    db = SessionLocal()
    try:
        config = db.query(CropConfig).first()
        if not config:
            raise HTTPException(status_code=404, detail="Crop config not found")
        # Total energi hari ini
        today = datetime.now().date()
        start = datetime.combine(today, datetime.min.time())
        end = start + timedelta(days=1)
        total_energy = db.query(func.sum(SensorData.energy_kwh)).filter(
            SensorData.timestamp >= start,
            SensorData.timestamp < end
        ).scalar() or 0.0
        target = float(config.target_energy_kwh_per_day)
        percent = min(100, int((total_energy / target) * 100)) if target > 0 else 0
        return {
            "today_energy_kwh": float(total_energy),
            "target_energy_kwh_per_day": target,
            "percentage_of_target": percent,
            "status": "exceeded" if total_energy > target else "ok"
        }
    finally:
        db.close()

@app.get("/health")
async def health():
    return {"status": "ok"}
