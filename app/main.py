from typing import Annotated

from fastapi import Depends, FastAPI, HTTPException, Query
from sqlmodel import Session, SQLModel, create_engine, select
from app.model import Operator
from app.config import DATABASE_URL

print(f"Using database URL: {DATABASE_URL}")
engine = create_engine(DATABASE_URL)

def create_db_and_tables():
    SQLModel.metadata.create_all(engine)

def get_session():
    with Session(engine) as session:
        yield session

SessionDep = Annotated[Session, Depends(get_session)]
app = FastAPI()

@app.on_event("startup")
def on_startup():
    create_db_and_tables()


@app.get("/")
def read_root():
    return {"messsage": "A simple fast api project to test the deployment"}


@app.post("/operators")
def create_operator(operator: Operator, session: SessionDep) -> Operator:
    session.add(operator)
    session.commit()
    session.refresh(operator)
    return operator


@app.get("/operators")
def read_operators(
    session: SessionDep,
    offset: int = 0,
    limit: Annotated[int, Query(le=100)] = 100,
) -> list[Operator]:
    operators = session.exec(select(Operator).offset(offset).limit(limit)).all()
    return operators


@app.get("/operator/{operator_id}")
def read_operator(operator_id: int, session: SessionDep) -> Operator:
    operator = session.get(Operator, operator_id)
    if not operator:
        raise HTTPException(status_code=404, detail="Operator not found")
    return operator


@app.delete("/operators/{operator_id}")
def delete_operator(operator_id: int, session: SessionDep):
    operator = session.get(Operator, operator_id)
    if not operator:
        raise HTTPException(status_code=404, detail="Operator not found")
    session.delete(operator)
    session.commit()
    return {"ok": True}

@app.put("/operators/{operator_id}")
def update_operator(
    operator_id: int, operator: Operator, session: SessionDep
) -> Operator:
    db_operator = session.get(Operator, operator_id)
    if not db_operator:
        raise HTTPException(status_code=404, detail="Operator not found")

    operator_data = operator.dict(exclude_unset=True)
    for key, value in operator_data.items():
        setattr(db_operator, key, value)

    session.add(db_operator)
    session.commit()
    session.refresh(db_operator)
    return db_operator