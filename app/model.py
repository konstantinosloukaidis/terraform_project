from sqlmodel import Field, SQLModel

class Operator(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    name: str = Field(index=True)
    age: int | None = Field(default=None, index=True)
    height: float | None = Field(default=None, index=True)
    full_name: str | None = Field(default=None, index=True)
    coalition: str | None = Field(default=None, index=True)
