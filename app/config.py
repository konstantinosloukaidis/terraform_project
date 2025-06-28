import os
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

ENV = os.getenv("ENV", "dev")
env_file = f".env.{ENV}"
load_dotenv(env_file)

DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_NAME = os.getenv("DB_NAME")
DB_URL = os.getenv("DB_URL")
DB_PORT = os.getenv("DB_PORT")
APP_PORT = os.getenv("APP_PORT", "8000")

DATABASE_URL = f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_URL}:{DB_PORT}/{DB_NAME}"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)