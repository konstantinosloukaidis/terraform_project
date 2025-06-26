import os
from dotenv import load_dotenv

ENV = os.getenv("ENV", "dev")
env_file = f".env.{ENV}"
load_dotenv(env_file)

DATABASE_URL = os.getenv("DATABASE_URL")
