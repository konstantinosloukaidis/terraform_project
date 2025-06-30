from sqlmodel import SQLModel, Field
from typing import Optional

class Operator(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(index=True)
    age: Optional[int] = Field(default=None, index=True)
    height: Optional[float] = Field(default=None, index=True)
    full_name: Optional[str] = Field(default=None, index=True)
    coalition: Optional[str] = Field(default=None, index=True)